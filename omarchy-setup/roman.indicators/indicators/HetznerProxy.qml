import QtQuick
import Quickshell.Io
import qs.Ui

// Firefox through hetzner-1 (setup.md step 57). The state is the service's, polled,
// so the icon also follows a tunnel that drops. "activating" is ssh retrying: the
// tunnel is wanted but down, and Firefox is going direct meanwhile.
BarIndicator {
  id: root

  property string serviceState: "inactive"

  active: serviceState === "active" || serviceState === "activating"
  useActiveColor: true
  activeText: "󰖂"
  inactiveText: "󰖂"
  activeTooltipText: serviceState === "active" ? "Firefox through Hetzner: on" : "Firefox through Hetzner: connecting (going direct until then)"
  inactiveTooltipText: "Firefox through Hetzner: off"

  function refresh() {
    if (!probe.running) probe.running = true
  }

  onPressed: function() {
    if (writer.running) return
    writer.command = ["systemctl", "--user", root.active ? "stop" : "start", "--no-block", "hetzner-socks"]
    writer.running = true
  }

  Process {
    id: probe
    command: ["systemctl", "--user", "is-active", "hetzner-socks"]
    stdout: SplitParser {
      onRead: function(line) { root.serviceState = String(line).trim() }
    }
  }

  Process {
    id: writer
    onExited: root.refresh()
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()
}
