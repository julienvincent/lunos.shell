import Quickshell.Io
import QtQuick

Row {
  property string fontFamily: ""

  spacing: 6

  Text {
    text: "MEM"
    color: "#928374" // subtle
    font.family: fontFamily
    font.pixelSize: 12
  }

  Text {
    id: memValue
    text: "-"
    color: "#ebdbb2" // fg0
    font.family: fontFamily
    font.pixelSize: 12
    font.bold: true
  }

  Process {
    id: memProc
    running: true
    command: [
      "sh",
      "-lc",
      "awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {used=(t-a)/1024/1024; total=t/1024/1024; printf \"%.1f/%.0fG\\n\", used, total}' /proc/meminfo"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        var s = (this.text || "").trim();
        var parts = s.split("/");
        var used = (parts[0] || "").trim();
        var total = (parts[1] || "").trim();
        if (used.length) {
          memValue.text = used.endsWith("G") ? used : (used + "G");
        } else {
          memValue.text = "-";
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: memProc.running = true
  }
}
