import Quickshell.Io
import QtQuick

Row {
  property string fontFamily: ""

  spacing: 6

  Text {
    text: "CPU"
    color: "#928374" // subtle
    font.family: fontFamily
    font.pixelSize: 12
  }

  Text {
    id: cpuValue
    text: "-"
    color: "#ebdbb2" // fg0
    font.family: fontFamily
    font.pixelSize: 12
    font.bold: true
  }

  Process {
    id: cpuProc
    running: true
    command: [
      "sh",
      "-lc",
      "read cpu u n s i iw irq sirq st g gn < /proc/stat; " +
        "pi=$((i+iw)); pn=$((u+n+s+irq+sirq+st)); pt=$((pi+pn)); " +
        "sleep 0.2; " +
        "read cpu u n s i iw irq sirq st g gn < /proc/stat; " +
        "ci=$((i+iw)); cn=$((u+n+s+irq+sirq+st)); ct=$((ci+cn)); " +
        "td=$((ct-pt)); id=$((ci-pi)); " +
        "cpu=$(( (100*(td-id) + td/2) / td )); " +
        "printf '%s%%\n' \"$cpu\""
    ]

    stdout: StdioCollector {
      onStreamFinished: cpuValue.text = (this.text || "").trim()
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: cpuProc.running = true
  }
}
