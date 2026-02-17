import QtQuick
import "../themes/theme.js" as Theme

Rectangle {
  id: backdrop

  property real dim_opacity: 0.6

  signal clicked

  anchors.fill: parent
  color: Theme.colors.bg_dark
  opacity: dim_opacity

  MouseArea {
    anchors.fill: parent
    onClicked: backdrop.clicked()
  }
}
