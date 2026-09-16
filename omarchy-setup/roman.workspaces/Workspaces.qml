import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  // Workspace 11 (bound to SUPER+Z) shows "Z" instead of its number, to
  // match the rest of the row's plain-letter/number style.
  readonly property var icons: ({ 11: "Z" })

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5, 11]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  // Shared desktop-entry/icon lookup, so app icons resolve the same way the
  // launcher and menu do.
  readonly property var appLibrary: root.bar && root.bar.shell ? root.bar.shell.appLibrary : null

  readonly property int maxIconsPerWorkspace: 2

  // Distinct app icons for the windows on a workspace, most-recent first,
  // capped so a busy workspace never blows up the bar's width. wm class
  // ("appId") is matched to a desktop entry via Quickshell's own heuristic
  // (the same fuzzy match backing icon lookups elsewhere in the shell).
  function workspaceIcons(workspace) {
    var result = []
    if (!workspace || root.vertical) return result

    var seen = {}
    var values = workspace.toplevels.values
    for (var i = 0; i < values.length && result.length < root.maxIconsPerWorkspace; i++) {
      var appId = values[i].wayland ? values[i].wayland.appId : ""
      if (!appId || seen[appId]) continue
      seen[appId] = true

      var entry = DesktopEntries.heuristicLookup(appId)
      if (!entry) continue

      var source = root.appLibrary ? root.appLibrary.iconSource(entry.icon) : Quickshell.iconPath(entry.icon, true)
      if (source) result.push(source)
    }
    return result
  }

  // Tooltip lists every distinct app on the workspace by name, even beyond
  // the icons actually drawn.
  function workspaceTooltip(workspace, id) {
    if (!workspace || workspace.toplevels.values.length === 0) return "Workspace " + id

    var seen = {}
    var names = []
    var values = workspace.toplevels.values
    for (var i = 0; i < values.length; i++) {
      var appId = values[i].wayland ? values[i].wayland.appId : ""
      if (!appId || seen[appId]) continue
      seen[appId] = true

      var entry = DesktopEntries.heuristicLookup(appId)
      names.push(entry ? entry.name : appId)
    }
    return "Workspace " + id + ": " + names.join(", ")
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        id: wsButton
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property var icon: root.icons[modelData]
        readonly property var appIcons: root.workspaceIcons(workspace)

        bar: root.bar
        text: focused ? "󱓻" : (icon !== undefined ? icon : (modelData === 10 ? "0" : String(modelData)))
        labelVisible: false
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Math.max(Style.space(20), content.implicitWidth + Style.space(12))
        fixedHeight: root.barSize
        tooltipText: root.workspaceTooltip(workspace, modelData)
        onPressed: function() { root.focusWorkspace(modelData) }

        Behavior on fixedWidth {
          NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Row {
          id: content
          anchors.centerIn: parent
          spacing: Style.space(3)

          Text {
            textFormat: Text.PlainText
            text: wsButton.text
            color: wsButton.active ? wsButton.activeColor : wsButton.foreground
            font.family: wsButton.fontFamily
            font.pixelSize: wsButton.fontSize
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
          }

          Repeater {
            model: wsButton.appIcons

            Item {
              id: iconSlot
              required property string modelData

              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(11)
              height: Style.space(11)

              Image {
                id: iconImg
                anchors.fill: parent
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                source: iconSlot.modelData
                // Hidden; only rendered through the desaturating effect below.
                visible: false
                layer.enabled: true
              }

              // Grayscale so unfocused workspaces stay visually quiet — color
              // is reserved for drawing the eye to the focused one.
              MultiEffect {
                anchors.fill: iconImg
                source: iconImg
                saturation: wsButton.focused ? 0 : -1
              }
            }
          }
        }
      }
    }
  }
}
