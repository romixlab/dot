import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// The idle service proxy only exposes stayAwake, so this talks to roman.idle
// through the keep-running state file it watches.
BarIndicator {
  id: root

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/indicators/keep-running"

  active: false
  // Theme red (urgent) while on, so a laptop that won't sleep is hard to miss.
  useActiveColor: true
  activeText: "󰒲"
  inactiveText: "󰒲"
  activeTooltipText: "Allow Lid Sleep"
  inactiveTooltipText: "Keep Running (lid close doesn't sleep)"

  function refresh() {
    if (!probe.running) probe.running = true
  }

  onPressed: function() {
    if (writer.running) return
    writer.command = ["bash", "-c", root.active
      ? "rm -f \"$1\""
      : "mkdir -p \"$(dirname \"$1\")\" && touch \"$1\"", "_", root.statePath]
    writer.running = true
  }

  Process {
    id: probe
    command: ["bash", "-c", "[[ -f $1 ]] && echo yes || echo no", "_", root.statePath]
    stdout: SplitParser {
      onRead: function(line) { root.active = String(line).trim() === "yes" }
    }
  }

  Process {
    id: writer
    onExited: root.refresh()
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/indicators"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  Component.onCompleted: refresh()
}
