import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import "components"

ShellRoot {
  id: root

  property string focusedScreenName: ""

  function isFocusedScreen(screen) {
    if (focusedScreenName.length === 0) {
      return true;
    }
    if (!screen) {
      return false;
    }
    return screen.name === focusedScreenName;
  }

  function updateFocusedScreenName() {
    var name = "";
    var m = Hyprland.focusedMonitor;
    if (m && m.name) {
      name = m.name;
    } else if (Hyprland.activeToplevel && Hyprland.activeToplevel.monitor && Hyprland.activeToplevel.monitor.name) {
      // Fall back to the monitor the active window is on.
      name = Hyprland.activeToplevel.monitor.name;
    }
    if (name.length === 0 && Quickshell.screens.length > 0 && Quickshell.screens[0]) {
      name = Quickshell.screens[0].name;
    }
    focusedScreenName = name;
  }

  function refreshFocusedMonitor() {
    Hyprland.refreshMonitors();
    Qt.callLater(function() {
      updateFocusedScreenName();
    });
  }

  Component.onCompleted: {
    Hyprland.refreshWorkspaces();
    refreshFocusedMonitor();
  }

  // Give Hyprland IPC a moment to come up.
  Timer {
    interval: 300
    running: true
    repeat: false
    onTriggered: Hyprland.refreshWorkspaces()
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      refreshFocusedMonitor();
    }
  }

  NotificationServer {
    id: notifServer

    // Advertise all notification capabilities Quickshell supports.
    // (Most are disabled by default per the spec integration.)
    actionsSupported: true
    actionIconsSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: true
    imageSupported: true
    inlineReplySupported: true
    persistenceSupported: true
    keepOnReload: true

    onNotification: function(notification) {
      if (!notification) {
        return;
      }
      console.log(
        "Got Notification:",
        JSON.stringify({
          appIcon: notification.appIcon,
          desktopEntry: notification.desktopEntry,
          summary: notification.summary,
          appName: notification.appName,
          body: notification.body,
          hints: notification.hints,
        }, null, 2)
      );

      // Prevent the server from immediately discarding the notification.
      notification.tracked = true;
    }
  }

  Variants {
    model: Quickshell.screens

    Scope {
      required property var modelData

      Loader {
        id: screenUi
        active: modelData !== null && modelData !== undefined
        sourceComponent: screenUiComponent

        // Pass the current screen to the loaded component.
        property var screenModelData: modelData
      }

      Component {
        id: screenUiComponent

        Item {
          Bar {
            id: bar
            modelData: screenUi.screenModelData
          }

          VolumeOsd {
            anchorWindow: bar
            fontFamily: bar.uiFontFamily
            enabled: root.isFocusedScreen(screenUi.screenModelData)
          }

          NotificationToasts {
            anchorWindow: bar
            model: notifServer.trackedNotifications
            fontFamily: bar.uiFontFamily
            enabled: root.isFocusedScreen(screenUi.screenModelData)
          }
        }
      }
    }
  }
}
