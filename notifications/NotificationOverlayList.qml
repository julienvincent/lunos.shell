import QtQuick
import "../themes/theme.js" as Theme

Item {
  id: listRoot
  required property var model
  required property var hiddenNotifications

  function isHidden(notif) {
    if (!notif || !hiddenNotifications) {
      return false;
    }
    return hiddenNotifications.indexOf(notif) !== -1;
  }

  function notifFromModelData(data) {
    if (typeof data === "object" && data && data.summary !== undefined) {
      return data;
    }
    if (typeof data === "object" && data && data.modelData) {
      return data.modelData;
    }
    return null;
  }

  function invokePrimaryAction(notif) {
    if (!notif) {
      return;
    }

    var actions = notif.actions;
    if (actions && actions.length > 0) {
      for (var i = 0; i < actions.length; i++) {
        var a = actions[i];
        if (a && a.identifier === "default") {
          a.invoke();
          return;
        }
      }

      actions[0].invoke();
      return;
    }

    notif.dismiss();
  }

  property int hiddenCount: hiddenNotifications ? hiddenNotifications.length : 0

  Flickable {
    id: scroll
    anchors.fill: parent
    anchors.margins: 8
    contentWidth: width
    contentHeight: listColumn.implicitHeight
    clip: true

    Column {
      id: listColumn
      width: scroll.width
      spacing: 10
    }
  }

  Text {
    anchors.centerIn: parent
    visible: listRoot.hiddenCount === 0
    text: "No hidden notifications"
    color: Theme.colors.grey1
    font.family: Theme.fonts.text
    font.pixelSize: 12
  }

  Instantiator {
    id: inst
    active: listRoot.visible
    model: listRoot.model

    delegate: Item {
      width: listColumn.width

      property var notif: listRoot.notifFromModelData(modelData)
      property bool showItem: listRoot.isHidden(notif)

      visible: showItem
      height: showItem ? toast.implicitHeight : 0

      NotificationToast {
        id: toast
        anchors.left: parent.left
        anchors.right: parent.right
        notification: notif

        onClicked: {
          if (notif) {
            listRoot.invokePrimaryAction(notif);
          }
        }

        onDismissClicked: {
          if (notif) {
            notif.dismiss();
          }
        }
      }
    }

    onObjectAdded: function (index, object) {
      object.parent = listColumn;
    }

    onObjectRemoved: function (index, object) {
      if (object) {
        object.parent = null;
      }
    }
  }
}
