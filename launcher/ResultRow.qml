import QtQuick
import QtQuick.Layouts

import "../themes/theme.js" as Theme

Rectangle {
  id: row

  required property var entry
  property bool selected: false

  signal clicked

  height: 44
  radius: 10
  color: selected ? Theme.colors.bg_current_word : "transparent"

  MouseArea {
    anchors.fill: parent
    onClicked: row.clicked()
  }

  RowLayout {
    anchors.fill: parent
    anchors.topMargin: 3
    anchors.bottomMargin: 3
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    spacing: 10

    EntryIcon {
      Layout.preferredWidth: 20
      Layout.preferredHeight: 20
      entry: row.entry
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      Text {
        text: row.entry ? (row.entry.name || "") : ""
        color: Theme.colors.fg0
        font.family: Theme.fonts.text
        font.pixelSize: 14
        font.bold: true
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        visible: !!(row.entry && row.entry.genericName
                    && row.entry.genericName.length > 0)
        text: row.entry ? (row.entry.genericName || "") : ""
        color: Theme.colors.grey2
        font.family: Theme.fonts.text
        font.pixelSize: 12
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }

    Text {
      text: row.entry ? (row.entry.id || "") : ""
      color: Theme.colors.grey0
      font.family: Theme.fonts.text
      font.pixelSize: 10
      elide: Text.ElideLeft
      horizontalAlignment: Text.AlignRight
      Layout.preferredWidth: 160
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
