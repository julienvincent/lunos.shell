import Quickshell.Services.UPower
import QtQuick

Item {
  property string iconFontFamily: "Symbols Nerd Font"
  property string fontFamily: ""

  // Base "normal" color (used when >= 70%).
  property color iconColor: "#ebdbb2"

  property color chargingColor: "#b8bb26"

  property int iconPixelSize: 16
  property bool showPercent: true
  property int percentPixelSize: 12
  property int contentSpacing: 6

  readonly property var dev: UPower.displayDevice
  visible: !!dev && dev.ready && dev.isLaptopBattery && dev.isPresent

  property real percentage: {
    if (!visible) {
      return 0;
    }

    var p = dev.percentage;
    if (typeof p !== "number" || isNaN(p)) {
      return 0;
    }
    // Some backends report 0..1 instead of 0..100.
    if (p > 0 && p <= 1) {
      p = p * 100;
    }
    return p;
  }

  property bool isCharging: {
    if (!visible) {
      return false;
    }

    return !UPower.onBattery && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge);
  }

  property bool isPlugged: !UPower.onBattery
  property bool isLow: percentage < 10 && !isPlugged && !isCharging
  property bool flashOn: true

  Timer {
    interval: 450
    running: visible && isLow
    repeat: true
    onTriggered: {
      flashOn = !flashOn;
    }
  }

  property color effectiveColor: {
    if (!visible) {
      return iconColor;
    }

    if (isCharging) {
      return chargingColor;
    }

    if (isLow) {
      return flashOn ? "#fb4934" : iconColor;
    }
    if (percentage >= 70) {
      return iconColor;
    }
    if (percentage >= 40) {
      return "#d79921"; // yellow
    }
    if (percentage >= 20) {
      return "#fe8019"; // orange
    }
    return "#fb4934"; // red
  }

  // Take the parent Row height so centering works.
  height: parent ? parent.height : contentRow.implicitHeight
  width: contentRow.implicitWidth

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: contentSpacing

    Text {
      id: powerText
      anchors.verticalCenter: parent.verticalCenter

      visible: isPlugged || isCharging
      color: isCharging ? effectiveColor : "#928374" // dim when just plugged
      font.family: iconFontFamily
      font.pixelSize: iconPixelSize

      text: {
        if (!visible) {
          return "";
        }

        if (isCharging) {
          return "";
        }

        return "";
      }
    }

    Text {
      id: iconText
      anchors.verticalCenter: parent.verticalCenter

      color: effectiveColor
      font.family: iconFontFamily
      font.pixelSize: iconPixelSize

      text: {
        if (!parent.parent.visible) {
          return "";
        }

        if (percentage >= 90) {
          return "";
        }
        if (percentage >= 70) {
          return "";
        }
        if (percentage >= 40) {
          return "";
        }
        if (percentage >= 15) {
          return "";
        }
        return "";
      }
    }

    Text {
      id: percentText
      anchors.verticalCenter: parent.verticalCenter
      visible: parent.parent.visible && showPercent

      color: percentage >= 70 ? "#928374" : effectiveColor
      font.family: fontFamily.length ? fontFamily : iconFontFamily
      font.pixelSize: percentPixelSize
      font.bold: true

      text: {
        if (!visible) {
          return "";
        }
        return String(Math.round(percentage));
      }
    }
  }
}
