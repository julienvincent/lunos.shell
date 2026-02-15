 import Quickshell.Hyprland
 import QtQuick
import "../themes/theme.js" as Theme

Row {
  spacing: 6

  Repeater {
    model: Hyprland.workspaces

    delegate: Rectangle {
      required property var modelData // HyprlandWorkspace

      property bool isSpecial: !!modelData && typeof modelData.name === "string" && modelData.name.indexOf("special:") === 0
      property bool isActive: !!modelData && modelData.focused

      visible: !isSpecial

      radius: 6
      height: 20
      width: Math.max(24, labelItem.implicitWidth + 12)

      // Lifted tile on top of the bar background
      color: Theme.colors.bg1

      Text {
        id: labelItem
        anchors.centerIn: parent
        text: modelData ? modelData.name : ""
        font.pixelSize: 12
        font.family: Theme.fonts.text
        font.bold: true
        color: Theme.colors.fg0
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        radius: 1
        color: Theme.colors.yellow
        visible: isActive
      }

      Rectangle {
        width: 6
        height: 6
        radius: 3
        anchors.right: parent.right
        anchors.rightMargin: 3
        anchors.top: parent.top
        anchors.topMargin: 3
        color: Theme.colors.red
        visible: !!modelData && modelData.urgent
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (modelData) {
            modelData.activate();
          }
        }
      }
    }
  }
}
