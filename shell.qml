import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import "components"

ShellRoot {
  id: root

  property string focusedScreenName: ""

  function updateFocusedScreenName() {
    var name = "";
    for (var i = 0; i < Hyprland.monitors.length; i++) {
      var m = Hyprland.monitors[i];
      if (m && m.focused) {
        name = m.name;
      }
    }
    if (name.length === 0 && Quickshell.screens.length > 0) {
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

    onNotification: function(notification) {
      if (!notification) {
        return;
      }

      // Prevent the server from immediately discarding the notification.
      notification.tracked = true;
    }
  }

  Variants {
    model: Quickshell.screens

    Scope {
      required property var modelData

      // Avoid name shadowing with Bar.modelData
      property var screenModel: modelData

      Bar {
        id: bar
        modelData: screenModel
      }

      NotificationToasts {
        anchorWindow: bar
        model: notifServer.trackedNotifications
        fontFamily: bar.uiFontFamily
        enabled: root.focusedScreenName.length === 0 || screenModel.name === root.focusedScreenName
      }
    }
  }
}
