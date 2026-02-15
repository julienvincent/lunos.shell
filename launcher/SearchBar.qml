import QtQuick
import QtQuick.Layouts

import "../themes/theme.js" as Theme

Item {
  id: search_bar

  property color accent_color: Theme.colors.yellow
  property alias text: search_input.text

  signal textEdited(string text)

  implicitHeight: 38

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    spacing: 8

    Text {
      text: "❯"
      color: accent_color
      font.family: Theme.fonts.icon
      font.pixelSize: 20
      font.bold: true
      Layout.alignment: Qt.AlignVCenter
    }

    TextInput {
      id: search_input
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      verticalAlignment: Text.AlignVCenter

      color: Theme.colors.fg0
      font.family: Theme.fonts.text
      font.pixelSize: 15
      font.bold: true
      selectionColor: Theme.colors.bg_current_word
      selectedTextColor: Theme.colors.fg1
      activeFocusOnTab: true
      focus: true

      onTextChanged: search_bar.textEdited(text)

      cursorDelegate: Rectangle {
        width: 2
        color: Theme.colors.grey2
        radius: 1
      }
    }
  }
}
