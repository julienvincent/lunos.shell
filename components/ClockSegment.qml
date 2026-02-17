import Quickshell
import QtQuick
import "../themes/theme.js" as Theme

Row {
  spacing: 8

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Text {
    id: clockDate
    color: Theme.colors.fg0
    font.family: Theme.fonts.text
    font.pixelSize: 12
    font.bold: true
    text: Qt.formatDateTime(clock.date, "ddd dd")
  }

  Text {
    id: clockTime
    color: Theme.colors.fg0
    font.family: Theme.fonts.text
    font.pixelSize: 12
    font.bold: true
    text: Qt.formatDateTime(clock.date, "HH:mm")
  }
}
