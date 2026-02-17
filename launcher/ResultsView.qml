import QtQuick

Flickable {
  id: results_view

  property var entries: []
  property int selected_index: 0

  signal activated(int index)

  clip: true
  contentWidth: width
  contentHeight: results_col.implicitHeight
  boundsBehavior: Flickable.StopAtBounds

  Column {
    id: results_col
    width: results_view.width
    spacing: 4

    Repeater {
      model: results_view.entries

      delegate: Item {
        required property var modelData

        width: results_col.width
        height: row.height
        implicitHeight: row.height

        property int row_index: results_view.entries
                                ? results_view.entries.indexOf(modelData) : -1

        ResultRow {
          id: row
          width: parent.width

          entry: parent.modelData
          selected: parent.row_index === results_view.selected_index

          onClicked: results_view.activated(parent.row_index)
        }
      }
    }
  }
}
