import Quickshell
import QtQuick

PopupWindow {
  id: toasts
  required property var anchorWindow
  required property var model
  property bool enabled: true
  property var hiddenNotifications: []

  // Toast lifetime behavior
  property int defaultTimeoutMs: 6000
  property int maxTimeoutMs: 3600000

  property int hiddenCount: hiddenNotifications ? hiddenNotifications.length : 0
  property int visibleToastCount: Math.max(0, inst.count - hiddenCount)

  function isHidden(notif) {
    if (!notif || !hiddenNotifications) {
      return false;
    }
    return hiddenNotifications.indexOf(notif) !== -1;
  }

  function hideNotification(notif) {
    if (!notif) {
      return;
    }
    if (isHidden(notif)) {
      return;
    }
    var next = hiddenNotifications ? hiddenNotifications.slice(0) : [];
    next.push(notif);
    hiddenNotifications = next;
  }

  function unhideNotification(notif) {
    if (!notif || !hiddenNotifications || hiddenNotifications.length === 0) {
      return;
    }

    var idx = hiddenNotifications.indexOf(notif);
    if (idx === -1) {
      return;
    }

    var next = hiddenNotifications.slice(0);
    next.splice(idx, 1);
    hiddenNotifications = next;
  }

  function hasExplicitTtl(notif) {
    if (!notif) {
      return false;
    }

    var ms = notif.expireTimeout;
    return typeof ms === "number" && !isNaN(ms) && ms > 0;
  }

  function timeoutMs(notif) {
    if (!hasExplicitTtl(notif)) {
      return defaultTimeoutMs;
    }

    return Math.min(Math.round(notif.expireTimeout), maxTimeoutMs);
  }

  anchor.window: anchorWindow
  anchor.rect.x: anchorWindow.width - implicitWidth - 10
  anchor.rect.y: anchorWindow.implicitHeight + 10
  anchor.rect.w: 1
  anchor.rect.h: 1
  anchor.edges: Edges.Top | Edges.Left
  anchor.gravity: Edges.Bottom | Edges.Right

  implicitWidth: 360
  implicitHeight: Math.max(1, stack.implicitHeight + 12)
  visible: enabled && visibleToastCount > 0

  // QsWindow defaults to an opaque (white) background.
  color: "transparent"
  surfaceFormat.opaque: false

  onVisibleChanged: {
    if (visible) {
      anchor.updateAnchor();
    }
  }

  function invokePrimaryAction(notif) {
    if (!notif) {
      return;
    }

    var actions = notif.actions;
    if (actions && actions.length > 0) {
      // Prefer the default action when present.
      for (var i = 0; i < actions.length; i++) {
        var a = actions[i];
        if (a && a.identifier === "default") {
          a.invoke();
          return;
        }
      }

      // Some clients / servers may treat the identifier differently when action
      // icons are in use. Fall back to the first action.
      actions[0].invoke();
      return;
    }

    // No action: behave like a normal toast (dismiss).
    notif.dismiss();
  }

  Item {
    anchors.fill: parent

    Column {
      id: stack
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 6
      spacing: 10
    }

    Instantiator {
      id: inst
      active: toasts.enabled
      model: toasts.model

      delegate: Item {
        id: toastItem
        width: stack.width
        property bool isHiddenToast: toasts.isHidden(notif)
        visible: !isHiddenToast
        height: isHiddenToast ? 0 : toast.implicitHeight

        // ObjectModel exposes a single role named `modelData`.
        // For QAbstractItemModels, roles are exposed as properties.
        property var notif: (typeof modelData === "object" && modelData
                             && modelData.summary !== undefined) ? modelData : ((
                                                                                  typeof modelData
                                                                                  === "object"
                                                                                  && modelData
                                                                                  && modelData.modelData)
                                                                                ? modelData.modelData :
                                                                                  null)

        NotificationToast {
          id: toast
          anchors.left: parent.left
          anchors.right: parent.right
          notification: notif

          onClicked: {
            if (notif) {
              toasts.invokePrimaryAction(notif);
            }
          }

          onDismissClicked: {
            if (notif) {
              toasts.unhideNotification(notif);
              notif.dismiss();
            }
          }
        }

        Timer {
          interval: {
            return toasts.timeoutMs(notif);
          }
          running: true
          repeat: false
          onTriggered: {
            if (notif) {
              if (toasts.hasExplicitTtl(notif)) {
                notif.expire();
              } else {
                toasts.hideNotification(notif);
              }
            }
          }
        }
      }

      onObjectAdded: function (index, object) {
        object.parent = stack;
        if (toasts.visible) {
          toasts.anchor.updateAnchor();
        }
      }

      onObjectRemoved: function (index, object) {
        // Instantiator manages object lifetime; don't manually destroy.
        if (object) {
          toasts.unhideNotification(object.notif);
          object.parent = null;
        }
        if (toasts.visible) {
          toasts.anchor.updateAnchor();
        }
      }
    }
  }
}
