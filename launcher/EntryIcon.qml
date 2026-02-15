import Quickshell
import QtQuick

import "../themes/theme.js" as Theme

Item {
  id: entry_icon

  property var entry: null

  implicitWidth: 20
  implicitHeight: 20

  property string icon_source: {
    if (!entry || !entry.icon) {
      return "";
    }

    var p = Quickshell.iconPath(entry.icon, true);
    if (p && p.length > 0) {
      return p;
    }
    return Quickshell.iconPath(entry.icon);
  }

  Image {
    anchors.fill: parent
    visible: entry_icon.icon_source.length > 0
    source: entry_icon.icon_source
    fillMode: Image.PreserveAspectFit
    smooth: true
  }

  Text {
    anchors.centerIn: parent
    visible: entry_icon.icon_source.length === 0
    text: "\uf1b2" // cube
    color: Theme.colors.grey2
    font.family: Theme.fonts.icon
    font.pixelSize: 16
  }
}
