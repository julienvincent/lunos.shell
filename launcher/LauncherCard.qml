import QtQuick
import QtQuick.Layouts

import "../themes/theme.js" as Theme

Rectangle {
  id: card

  property color accent_color: Theme.colors.yellow

  signal clicked()

  radius: 8
  color: Theme.colors.bg0
  border.width: 2
  border.color: Theme.colors.aqua

  MouseArea {
    anchors.fill: parent
    onClicked: card.clicked()
  }
}
