import QtQuick
import "../themes/theme.js" as Theme

Text {
  property color sepColor: Theme.colors.grey1

  text: "/"
  color: sepColor
  font.family: Theme.fonts.text
  font.pixelSize: 12
}
