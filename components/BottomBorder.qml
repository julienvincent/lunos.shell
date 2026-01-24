import QtQuick
import QtQuick.Shapes

Shape {
  property color borderColor: "#928374"
  property real borderWidth: 2
  property real dashOn: 6
  property real dashOff: 4

  height: borderWidth

  ShapePath {
    strokeColor: borderColor
    strokeWidth: borderWidth
    fillColor: "transparent"

    strokeStyle: ShapePath.DashLine
    dashPattern: [dashOn, dashOff]

    startX: 0
    startY: parent.height / 2
    PathLine { x: parent.width; y: parent.height / 2 }
  }
}
