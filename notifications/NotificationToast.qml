import Quickshell
import QtQuick
import "../themes/theme.js" as Theme

Item {
  id: toastRoot
  property var notification: null
  property string toastAppName: ""
  property string toastSummary: ""
  property string toastBody: ""
  property string toastImage: ""

  function parseChromiumBody(notif) {
    if (!notif || notif.desktopEntry !== "chromium-browser") {
      return null;
    }

    var body = notif.body || "";
    var match = body.match(/^<a\b[^>]*>([\s\S]*?)<\/a>\s*/i);
    if (!match) {
      return null;
    }

    return {
      appName: match[1].trim(),
      body: body.slice(match[0].length)
    };
  }

  property var chromiumTransformers: ({
                                        ".*app\\.slack\\.com.*": {
                                          summary: function (s) {
                                            return s.replace(
                                                  /^new message (?:from|in) /i,
                                                  "");
                                          }
                                        }
                                      })

  function applyChromiumTransformers(appName, field, value) {
    if (!appName || !value) {
      return value;
    }
    for (var pattern in chromiumTransformers) {
      var regex = new RegExp(pattern, "i");
      if (regex.test(appName)) {
        var transformer = chromiumTransformers[pattern][field];
        if (typeof transformer === "function") {
          return transformer(value);
        }
      }
    }
    return value;
  }

  function resolveImage(src) {
    if (!src) {
      return "";
    }
    if (src.startsWith("file:") || src.startsWith("data:") || src.startsWith(
          "image:") || src.startsWith("qrc:")) {
      return src;
    }
    if (src.startsWith("/")) {
      return "file://" + src;
    }
    if (src.indexOf("/") !== -1) {
      return src;
    }

    var p = Quickshell.iconPath(src, true);
    if (p && p.length > 0) {
      return p;
    }
    p = Quickshell.iconPath(src);
    return p || "";
  }

  property var parsedChromium: parseChromiumBody(notification)
  property string computedAppName: {
    if (toastAppName.length > 0) {
      return toastAppName;
    }
    if (!notification) {
      return "";
    }
    if (parsedChromium) {
      return parsedChromium.appName;
    }
    return notification.appName || "";
  }
  property string computedSummary: {
    if (toastSummary.length > 0) {
      return toastSummary;
    }
    if (!notification) {
      return "";
    }
    if (parsedChromium) {
      return applyChromiumTransformers(parsedChromium.appName, "summary",
                                       notification.summary || "");
    }
    return notification.summary || "";
  }
  property string computedBody: {
    if (toastBody.length > 0) {
      return toastBody;
    }
    if (!notification) {
      return "";
    }
    if (parsedChromium) {
      return parsedChromium.body;
    }
    return notification.body || "";
  }
  property string computedImage: {
    if (toastImage.length > 0) {
      return toastImage;
    }
    if (!notification) {
      return "";
    }
    return resolveImage(notification.image || notification.appIcon || "");
  }

  function tintLinks(richText) {
    if (!richText || typeof richText !== "string") {
      return richText;
    }

    // Force link coloring even if Qt ignores `linkColor`.
    // This assumes well-formed <a>...</a> markup from clients.
    var s = richText;
    s = s.replace(/<a\b([^>]*)>/gi, '<a$1><font color="' + Theme.colors.blue
                  + '">');
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

  signal clicked
  signal dismissClicked

  implicitWidth: 360
  implicitHeight: contentRow.implicitHeight + padding * 2

  // Ensure we actually render; implicitHeight doesn't affect height by itself.
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: 6
    color: Theme.colors.bg0
    border.width: 1.5
    border.color: Theme.colors.aqua
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
      font.family: Theme.fonts.text
      font.pixelSize: 12
      font.bold: true
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: function (mouse) {
        mouse.accepted = true;
        parent.parent.dismissClicked();
      }
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
        visible: computedImage.length > 0
        width: 44
        height: 44
        anchors.verticalCenter: parent.verticalCenter
        radius: 8
        color: Theme.colors.bg1
        clip: true

        Image {
          anchors.fill: parent
          anchors.margins: 4
          source: computedImage
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
        }
      }

      Column {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, contentRow.width - (imageWrap.visible ? (
                                                                     imageWrap.width
                                                                     + contentRow.spacing) :
                                                                   0))
        spacing: 4

        Text {
          visible: computedAppName.length > 0
          text: computedAppName
          width: parent.width
          color: Theme.colors.grey1
          font.family: Theme.fonts.text
          font.pixelSize: 11
          elide: Text.ElideRight
        }

        Text {
          text: tintLinks(computedSummary)
          width: parent.width
          color: Theme.colors.fg0
          font.family: Theme.fonts.text
          font.pixelSize: 12
          font.bold: true
          wrapMode: Text.WordWrap

          textFormat: Text.RichText
          linkColor: Theme.colors.blue
          onLinkActivated: function (link) {
            toastRoot.openLink(link);
          }
        }

        Text {
          visible: computedBody.length > 0
          text: tintLinks(computedBody)
          width: parent.width
          color: Theme.colors.fg0
          opacity: 0.9
          font.family: Theme.fonts.text
          font.pixelSize: 12
          wrapMode: Text.WordWrap
          maximumLineCount: 3
          elide: Text.ElideRight

          // When the server advertises markup/hyperlinks, allow rendering them.
          textFormat: Text.RichText
          linkColor: Theme.colors.blue
          onLinkActivated: function (link) {
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
            onClicked: function (mouse) {
              replyInput.forceActiveFocus();
              mouse.accepted = true;
            }
          }

          TextInput {
            id: replyInput
            anchors.fill: parent
            anchors.margins: 6
            font.family: Theme.fonts.text
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
            text: notification ? (notification.inlineReplyPlaceholder
                                  || "Reply") : "Reply"
            color: Theme.colors.grey1
            font.family: Theme.fonts.text
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
