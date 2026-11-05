import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Draws the pie menu and reports the slice under the mouse. spacemouse-menu.py
// opens it on a button press and asks for the key to send on release.
ShellRoot {
  id: root

  readonly property real outerRadius: 180
  readonly property real centerRadius: 64

  property var menu: null
  // The last menu stays in place when closing, so the closing window's bindings keep their data.
  property bool shown: false
  // Index of the ring slice under the mouse, -1 while the mouse is in the centre.
  property int hot: -1

  readonly property var centerItem: menu ? menu.center[menu.side] : null

  function trackMouse(x, y) {
    if (!shown) return
    var dx = x - menu.x
    var dy = y - menu.y
    var distance = Math.hypot(dx, dy)
    if (distance <= centerRadius) {
      hot = -1
      return
    }
    // Clockwise from the top, with slice 0 centred on the top.
    var step = 2 * Math.PI / menu.ring.length
    var angle = Math.atan2(dx, -dy) + 2 * Math.PI + step / 2
    hot = Math.floor(angle / step) % menu.ring.length
    // Crossing the outer circle fires the slice at once, without waiting for the release.
    if (distance >= outerRadius) {
      var key = menu.ring[hot].key
      console.info("fired on crossing:", key)
      shown = false
      Quickshell.execDetached([menu.script, "fire", key, String(menu.home[0]), String(menu.home[1])])
    }
  }

  IpcHandler {
    target: "pie"

    function open(payload: string): void {
      root.hot = -1
      root.menu = JSON.parse(payload)
      root.shown = true
    }

    function release(): string {
      if (!root.shown) return "closed"
      // Only the centre fires on release: ring slices fire on crossing, so releasing in the ring cancels.
      var key = root.hot < 0 && root.centerItem ? root.centerItem.key : ""
      root.shown = false
      return key
    }
  }

  LazyLoader {
    active: root.shown

    PanelWindow {
      screen: Quickshell.screens.find(s => s.name === root.menu.screen) || null
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "spacemouse-menu"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onPositionChanged: mouse => root.trackMouse(mouse.x, mouse.y)
        // A mouse click cancels, and frees the screen if a button release ever gets lost.
        onPressed: root.shown = false
      }

      // A short press fires the centre slot without the menu flashing up.
      Item {
        id: pie
        x: root.menu.x
        y: root.menu.y
        opacity: 0

        Timer {
          interval: 120
          running: true
          onTriggered: pie.opacity = 1
        }

        Repeater {
          model: root.menu.ring

          Item {
            id: slice

            required property var modelData
            required property int index

            readonly property real step: 360 / root.menu.ring.length
            readonly property real middle: -90 + index * step
            readonly property real labelRadius: (root.outerRadius + root.centerRadius) / 2
            readonly property bool lit: root.hot === index

            Shape {
              preferredRendererType: Shape.CurveRenderer

              ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Qt.alpha(slice.lit ? root.menu.colors.accent : root.menu.colors.background, 0.94)

                PathAngleArc {
                  radiusX: root.outerRadius
                  radiusY: root.outerRadius
                  startAngle: slice.middle - slice.step / 2 + 0.6
                  sweepAngle: slice.step - 1.2
                }
                PathAngleArc {
                  radiusX: root.centerRadius + 6
                  radiusY: root.centerRadius + 6
                  startAngle: slice.middle + slice.step / 2 - 1.5
                  sweepAngle: 3 - slice.step
                  moveToStart: false
                }
              }
            }

            Text {
              x: slice.labelRadius * Math.cos(slice.middle * Math.PI / 180) - width / 2
              y: slice.labelRadius * Math.sin(slice.middle * Math.PI / 180) - height / 2
              width: 96
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
              text: slice.modelData.label
              font.pixelSize: 14
              color: slice.lit ? root.menu.colors.background : root.menu.colors.foreground
            }
          }
        }

        Repeater {
          model: ["left", "right"]

          Item {
            id: half

            required property string modelData

            readonly property var item: root.menu.center[modelData]
            readonly property real direction: modelData === "left" ? -1 : 1
            readonly property bool lit: root.hot < 0 && root.menu.side === modelData

            Shape {
              preferredRendererType: Shape.CurveRenderer

              ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Qt.alpha(half.lit && half.item ? root.menu.colors.accent : root.menu.colors.background, 0.94)

                PathAngleArc {
                  centerX: half.direction * 1.5
                  radiusX: root.centerRadius
                  radiusY: root.centerRadius
                  startAngle: half.direction < 0 ? 90 : -90
                  sweepAngle: 180
                }
              }
            }

            Text {
              x: half.direction * root.centerRadius / 2 - width / 2
              y: -height / 2
              width: root.centerRadius - 8
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
              text: half.item ? half.item.label : "Free"
              font.pixelSize: 12
              font.italic: !half.item
              opacity: half.item ? 1 : 0.6
              color: half.lit && half.item ? root.menu.colors.background : root.menu.colors.foreground
            }
          }
        }

        // The free centre slot is shown, and says why nothing happens on release.
        Rectangle {
          visible: root.hot < 0 && !root.centerItem
          x: -width / 2
          y: root.outerRadius + 10
          width: reason.implicitWidth + 20
          height: reason.implicitHeight + 10
          radius: 6
          color: Qt.alpha(root.menu.colors.background, 0.94)

          Text {
            id: reason
            anchors.centerIn: parent
            text: "Nothing assigned to this button yet: set it in menu.json"
            font.pixelSize: 12
            color: root.menu.colors.foreground
          }
        }
      }
    }
  }
}
