 import Quickshell
 import QtQuick
import "../themes/theme.js" as Theme

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
  property color sepTextColor: Theme.colors.grey1 // subtle

  // Reserve space so tiled windows start below the bar.
  exclusiveZone: implicitHeight

  Rectangle {
    anchors.fill: parent
    color: Theme.colors.bg0
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
    BatteryIcon { iconColor: Theme.colors.fg0; fontFamily: uiFontFamily }
    Separator { fontFamily: uiFontFamily; sepColor: sepTextColor }
    ClockSegment { fontFamily: uiFontFamily }
  }

  BottomBorder {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    borderColor: Theme.colors.grey1 // subtle
  }

}
