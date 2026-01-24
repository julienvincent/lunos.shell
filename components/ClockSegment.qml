import Quickshell.Io
import QtQuick

Row {
  property string fontFamily: ""

  spacing: 8

  Text {
    id: clockDate
    color: "#ebdbb2" // fg0
    font.family: fontFamily
    font.pixelSize: 12
    font.bold: true
  }

  Text {
    id: clockTime
    color: "#ebdbb2" // fg0
    font.family: fontFamily
    font.pixelSize: 12
    font.bold: true
  }

  Process {
    id: dateProc
    command: ["sh", "-lc", "date '+%a %d|%H:%M'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        var s = (this.text || "").trim();
        var parts = s.split("|");
        clockDate.text = parts[0] || "";
        clockTime.text = parts[1] || "";
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: dateProc.running = true
  }
}
