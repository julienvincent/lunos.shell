import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "../themes/theme.js" as Theme

PanelWindow {
  id: overlay
  required property var anchorWindow
  required property var model
  required property var hiddenNotifications
  property bool enabled: true
  property bool open: false
  property int drawerWidth: 380
  property int cardMargin: 12
  property real revealProgress: open ? 1 : 0
  signal closeRequested

  function notifFromModelData(data) {
    if (typeof data === "object" && data && data.summary !== undefined) {
      return data;
    }
    if (typeof data === "object" && data && data.modelData) {
      return data.modelData;
    }
    return null;
  }

  function dismissAllNotifications() {
    var items = [];

    function addNotif(candidate) {
      var notif = notifFromModelData(candidate);
      if (!notif) {
        return;
      }
      if (items.indexOf(notif) !== -1) {
        return;
      }
      items.push(notif);
    }

    if (hiddenNotifications && hiddenNotifications.length > 0) {
      for (var i = 0; i < hiddenNotifications.length; i++) {
        addNotif(hiddenNotifications[i]);
      }
    }

    if (model) {
      if (typeof model.length === "number") {
        for (var j = 0; j < model.length; j++) {
          addNotif(model[j]);
        }
      } else if (typeof model.count === "number" && typeof model.get
                 === "function") {
        for (var k = 0; k < model.count; k++) {
          addNotif(model.get(k));
        }
      } else if (model.values && typeof model.values.length === "number") {
        for (var m = 0; m < model.values.length; m++) {
          addNotif(model.values[m]);
        }
      }
    }

    for (var n = 0; n < items.length; n++) {
      var notif = items[n];
      if (notif && typeof notif.dismiss === "function") {
        notif.dismiss();
      }
    }
  }

  screen: anchorWindow.screen
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  focusable: true

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  WlrLayershell.namespace: "lunos-notifications"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  implicitWidth: {
    if (!anchorWindow || !anchorWindow.screen) {
      return drawerWidth;
    }
    return Math.max(drawerWidth, anchorWindow.screen.width);
  }
  implicitHeight: {
    if (!anchorWindow || !anchorWindow.screen) {
      return 1;
    }
    return Math.max(1, anchorWindow.screen.height);
  }

  visible: enabled && (open || revealProgress > 0)

  Behavior on revealProgress {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  onVisibleChanged: {
    if (visible) {
      Qt.callLater(function () {
        keyCatcher.forceActiveFocus();
      });
    }
  }

  color: "transparent"
  surfaceFormat.opaque: false

  Shortcut {
    sequence: StandardKey.Cancel
    context: Qt.ApplicationShortcut
    enabled: overlay.visible
    onActivated: {
      if (overlay.visible) {
        overlay.closeRequested();
      }
    }
  }

  FocusScope {
    id: keyCatcher
    anchors.fill: parent
    focus: overlay.visible

    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_Escape) {
        event.accepted = true;
        overlay.closeRequested();
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    color: "#7a000000"
    opacity: revealProgress
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    enabled: revealProgress > 0.01
    onClicked: function (mouse) {
      var inside_card = mouse.x >= drawer.x && mouse.x <= (drawer.x
                                                           + drawer.width)
          && mouse.y >= drawer.y && mouse.y <= (drawer.y + drawer.height);
      if (!inside_card) {
        overlay.closeRequested();
      }
    }
  }

  Rectangle {
    id: drawer
    x: overlay.width - cardMargin - width + (1 - revealProgress) * (width + cardMargin
                                                                    + 24)
    y: cardMargin
    width: overlay.drawerWidth
    height: Math.max(1, overlay.height - cardMargin * 2)
    color: Theme.colors.bg_dark
    opacity: 1
    radius: 8
    clip: true

    border.width: 1.5
    border.color: Theme.colors.yellow

    Column {
      anchors.fill: parent

      NotificationOverlayHeader {
        onClearAllRequested: {
          overlay.dismissAllNotifications();
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Theme.colors.bg3
      }

      NotificationOverlayList {
        width: parent.width
        height: Math.max(0, parent.height - 43)
        model: overlay.model
        hiddenNotifications: overlay.hiddenNotifications
      }
    }
  }
}
