import QtQuick
import "../themes/theme.js" as Theme

Rectangle {
  id: header
  signal clearAllRequested

  width: parent ? parent.width : 0
  height: 42
  color: "transparent"

  Text {
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    text: "Notifications"
    color: Theme.colors.fg0
    font.family: Theme.fonts.text
    font.pixelSize: 12
    font.bold: true
  }

  Rectangle {
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: 70
    height: 24
    radius: 5
    color: clearAllHover.containsMouse ? Theme.colors.bg2 : Theme.colors.bg1
    border.width: 1
    border.color: Theme.colors.bg3

    Text {
      anchors.centerIn: parent
      text: "Clear all"
      color: Theme.colors.fg0
      font.family: Theme.fonts.text
      font.pixelSize: 11
      font.bold: true
    }

    MouseArea {
      id: clearAllHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        header.clearAllRequested();
      }
    }
  }
}
