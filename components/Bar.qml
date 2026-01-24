import Quickshell
import QtQuick

PanelWindow {
  id: barWindow
  required property var modelData
  screen: modelData

  anchors {
    top: true
    left: true
    right: true
  }

  implicitHeight: 30

  property string uiFontFamily: "MonoLisa"
  property color sepTextColor: "#928374" // subtle

  // Reserve space so tiled windows start below the bar.
  exclusiveZone: implicitHeight

  Rectangle {
    anchors.fill: parent
    color: "#282828" // bg0
  }

  WorkspaceSegment {
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    fontFamily: uiFontFamily
  }

  Row {
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    spacing: 12

    NetworkSegment { fontFamily: uiFontFamily }
    Separator { fontFamily: uiFontFamily; sepColor: sepTextColor }
    CpuSegment { fontFamily: uiFontFamily }
    Separator { fontFamily: uiFontFamily; sepColor: sepTextColor }
    MemSegment { fontFamily: uiFontFamily }
    Separator { fontFamily: uiFontFamily; sepColor: sepTextColor }
    BatteryIcon { iconColor: "#ebdbb2"; fontFamily: uiFontFamily }
    Separator { fontFamily: uiFontFamily; sepColor: sepTextColor }
    ClockSegment { fontFamily: uiFontFamily }
  }

  BottomBorder {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    borderColor: "#928374" // subtle
  }

}
