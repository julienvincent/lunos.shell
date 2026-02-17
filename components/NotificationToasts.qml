import Quickshell
import QtQuick

PopupWindow {
  id: toasts
  required property var anchorWindow
  required property var model
  property bool enabled: true

  // Chromium notifications include the page origin as a leading <a> tag in the body.
  // Extract it to use as the app name and strip it from the body.
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

  // Transformers for specific Chromium notification sources.
  // Keys are regex patterns matched against the extracted app name (from the <a> tag).
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

  // Toast lifetime behavior
  property int defaultTimeoutMs: 6000
  property int maxTimeoutMs: 3600000

  property int toastCount: 0

  anchor.window: anchorWindow
  anchor.rect.x: anchorWindow.width - implicitWidth - 10
  anchor.rect.y: anchorWindow.implicitHeight + 10
  anchor.rect.w: 1
  anchor.rect.h: 1
  anchor.edges: Edges.Top | Edges.Left
  anchor.gravity: Edges.Bottom | Edges.Right

  implicitWidth: 360
  implicitHeight: Math.max(1, stack.implicitHeight + 12)
  visible: enabled && toastCount > 0

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
      model: toasts.model

      onModelChanged: {
        // Reset count; objects will be re-added.
        toastCount = 0;
      }

      delegate: Item {
        width: stack.width
        height: toast.implicitHeight

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
          toastAppName: {
            if (!notif) {
              return "";
            }
            var parsed = toasts.parseChromiumBody(notif);
            if (parsed) {
              return parsed.appName;
            }
            return notif.appName || "";
          }
          toastSummary: {
            if (!notif) {
              return "";
            }
            var parsed = toasts.parseChromiumBody(notif);
            if (parsed) {
              return toasts.applyChromiumTransformers(parsed.appName, "summary",
                                                      notif.summary || "");
            }
            return notif.summary || "";
          }
          toastBody: {
            if (!notif) {
              return "";
            }
            var parsed = toasts.parseChromiumBody(notif);
            if (parsed) {
              return parsed.body;
            }
            return notif.body || "";
          }
          toastImage: {
            function resolveImage(src) {
              if (!src) {
                return "";
              }
              if (src.startsWith("file:") || src.startsWith("data:")
                  || src.startsWith("image:") || src.startsWith("qrc:")) {
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

            if (!notif) {
              return "";
            }

            // Prefer notification image; fallback to app icon.
            return resolveImage(notif.image || notif.appIcon || "");
          }

          onClicked: {
            if (notif) {
              toasts.invokePrimaryAction(notif);
            }
          }

          onDismissClicked: {
            if (notif) {
              notif.dismiss();
            }
          }
        }

        Timer {
          interval: {
            if (!notif) {
              return toasts.defaultTimeoutMs;
            }

            var ms = notif.expireTimeout;
            if (typeof ms !== "number" || isNaN(ms) || ms <= 0) {
              return toasts.defaultTimeoutMs;
            }

            return Math.min(Math.round(ms), toasts.maxTimeoutMs);
          }
          running: true
          repeat: false
          onTriggered: {
            if (notif) {
              notif.expire();
            }
          }
        }
      }

      onObjectAdded: function (index, object) {
        object.parent = stack;
        toastCount = toastCount + 1;
        if (toasts.visible) {
          toasts.anchor.updateAnchor();
        }
      }

      onObjectRemoved: function (index, object) {
        toastCount = Math.max(0, toastCount - 1);
        // Instantiator manages object lifetime; don't manually destroy.
        if (object) {
          object.parent = null;
        }
        if (toasts.visible) {
          toasts.anchor.updateAnchor();
        }
      }
    }
  }
}
