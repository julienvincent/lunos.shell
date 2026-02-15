 import QtQuick
import "../themes/theme.js" as Theme

Text {
  property string fontFamily: ""
  property color sepColor: Theme.colors.grey1

  text: "/"
  color: sepColor
  font.family: fontFamily
  font.pixelSize: 12
}
