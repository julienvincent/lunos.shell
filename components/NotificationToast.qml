import QtQuick
import QtQuick.Shapes
import "../themes/theme.js" as Theme

Item {
  id: toastRoot
  property string fontFamily: ""
  property var notification: null
  property string toastAppName: ""
  property string toastSummary: ""
  property string toastBody: ""
  property string toastImage: ""

  function tintLinks(richText) {
    if (!richText || typeof richText !== "string") {
      return richText;
    }

    // Force link coloring even if Qt ignores `linkColor`.
    // This assumes well-formed <a>...</a> markup from clients.
    var s = richText;
    s = s.replace(/<a\b([^>]*)>/gi, '<a$1><font color="' + Theme.colors.blue + '">');
    s = s.replace(/<\/(a)>/gi, '</font></$1>');
    return s;
  }

  function openLink(link) {
    if (link && link.length > 0) {
      Qt.openUrlExternally(link);
    }

    // Link activation is an explicit user action; close the toast.
    if (toastRoot.notification) {
      toastRoot.notification.dismiss();
    }
  }

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
    color: Theme.colors.bg0
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
    color: Theme.colors.bg1
    border.width: 1
    border.color: Theme.colors.bg3
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 8
    anchors.rightMargin: 8
    z: 5

      Text {
      anchors.centerIn: parent
      text: "x"
        color: Theme.colors.fg0
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
      strokeColor: Theme.colors.yellow
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
        color: Theme.colors.bg1
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
          color: Theme.colors.grey1
          font.family: fontFamily
          font.pixelSize: 11
          elide: Text.ElideRight
        }

        Text {
          text: tintLinks(toastSummary)
          width: parent.width
          color: Theme.colors.fg0
          font.family: fontFamily
          font.pixelSize: 12
          font.bold: true
          wrapMode: Text.WordWrap

          textFormat: Text.RichText
          linkColor: Theme.colors.blue
          onLinkActivated: function(link) {
            toastRoot.openLink(link);
          }
        }

        Text {
          visible: toastBody.length > 0
          text: tintLinks(toastBody)
          width: parent.width
          color: Theme.colors.fg0
          opacity: 0.9
          font.family: fontFamily
          font.pixelSize: 12
          wrapMode: Text.WordWrap
          maximumLineCount: 3
          elide: Text.ElideRight

          // When the server advertises markup/hyperlinks, allow rendering them.
          textFormat: Text.RichText
          linkColor: Theme.colors.blue
          onLinkActivated: function(link) {
            toastRoot.openLink(link);
          }
        }

        Rectangle {
          visible: notification && notification.hasInlineReply
          width: parent.width
          height: 26
          radius: 6
          color: Theme.colors.bg1
          border.width: 1
          border.color: Theme.colors.bg3

          MouseArea {
            anchors.fill: parent
            onClicked: {
              replyInput.forceActiveFocus();
              mouse.accepted = true;
            }
          }

          TextInput {
            id: replyInput
            anchors.fill: parent
            anchors.margins: 6
            font.family: fontFamily
            font.pixelSize: 12
            color: Theme.colors.fg0
            selectionColor: Theme.colors.bg3
            selectedTextColor: Theme.colors.fg1
            clip: true

            Keys.onReturnPressed: {
              if (!notification) {
                return;
              }

              var reply = replyInput.text;
              if (reply.length === 0) {
                return;
              }

              notification.sendInlineReply(reply);
              notification.dismiss();
            }
          }

          Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 6
            text: notification ? (notification.inlineReplyPlaceholder || "Reply") : "Reply"
            color: Theme.colors.grey1
            font.family: fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            visible: replyInput.text.length === 0 && !replyInput.activeFocus
            z: -1
          }
        }
      }
    }
  }
}
