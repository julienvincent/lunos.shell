import Quickshell
import QtQuick
import "../themes/theme.js" as Theme

Item {
  id: clockSegment
  signal clicked
  property bool hovered: clockHitArea.containsMouse

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: 4
    color: Theme.colors.bg1
    opacity: clockSegment.hovered ? 0.95 : 0
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Row {
    id: content
    spacing: 8

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

  MouseArea {
    id: clockHitArea
    x: 0
    y: 0
    width: clockSegment.width
    height: clockSegment.height
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      clockSegment.clicked();
    }
  }
}
