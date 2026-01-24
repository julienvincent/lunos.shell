import QtQuick
import QtQuick.Shapes

Item {
  property string fontFamily: ""
  property string toastAppName: ""
  property string toastSummary: ""
  property string toastBody: ""
  property string toastImage: ""

  property int padding: 10

  signal clicked()
  signal dismissClicked()

  implicitWidth: 360
  implicitHeight: contentRow.implicitHeight + padding * 2

  // Ensure we actually render; implicitHeight doesn't affect height by itself.
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: 10
    color: "#282828" // bg0
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      parent.clicked();
    }
  }

  Rectangle {
    id: dismissButton
    width: 22
    height: 22
    radius: 11
    color: "#3c3836" // bg1
    border.width: 1
    border.color: "#504945" // bg3
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 8
    anchors.rightMargin: 8
    z: 5

    Text {
      anchors.centerIn: parent
      text: "x"
      color: "#ebdbb2" // fg0
      font.family: fontFamily
      font.pixelSize: 12
      font.bold: true
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        mouse.accepted = true;
        parent.parent.dismissClicked();
      }
    }
  }

  Shape {
    anchors.fill: parent

    ShapePath {
      strokeColor: "#d79921" // yellow
      strokeWidth: 2
      fillColor: "transparent"
      strokeStyle: ShapePath.DashLine
      dashPattern: [6, 4]

      startX: 1
      startY: 1
      PathLine { x: parent.width - 1; y: 1 }
      PathLine { x: parent.width - 1; y: parent.height - 1 }
      PathLine { x: 1; y: parent.height - 1 }
      PathLine { x: 1; y: 1 }
    }
  }

  Item {
    id: padded
    anchors.fill: parent
    anchors.margins: padding

    Row {
      id: contentRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 10

      Rectangle {
        id: imageWrap
        visible: toastImage.length > 0
        width: 44
        height: 44
        anchors.verticalCenter: parent.verticalCenter
        radius: 8
        color: "#3c3836" // bg1
        clip: true

        Image {
          anchors.fill: parent
          anchors.margins: 4
          source: toastImage
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
        }
      }

      Column {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, contentRow.width - (imageWrap.visible ? (imageWrap.width + contentRow.spacing) : 0))
        spacing: 4

        Text {
          visible: toastAppName.length > 0
          text: toastAppName
          width: parent.width
          color: "#928374" // dim
          font.family: fontFamily
          font.pixelSize: 11
          elide: Text.ElideRight
        }

        Text {
          text: toastSummary
          width: parent.width
          color: "#ebdbb2" // fg0
          font.family: fontFamily
          font.pixelSize: 12
          font.bold: true
          wrapMode: Text.WordWrap
        }

        Text {
          visible: toastBody.length > 0
          text: toastBody
          width: parent.width
          color: "#ebdbb2" // fg0
          opacity: 0.9
          font.family: fontFamily
          font.pixelSize: 12
          wrapMode: Text.WordWrap
          maximumLineCount: 3
          elide: Text.ElideRight
        }
      }
    }
  }
}
