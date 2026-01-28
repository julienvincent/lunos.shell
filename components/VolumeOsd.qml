import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

PopupWindow {
  id: osd
  required property var anchorWindow
  property string fontFamily: ""
  property bool enabled: true
  property int hideAfterMs: 1200

  // PopupWindow does not expose an `opacity` property, so fade the contents.
  property real contentOpacity: 0

  property var sink: Pipewire.defaultAudioSink
  property var audio: sink ? sink.audio : null

  onEnabledChanged: {
    if (!enabled) {
      contentOpacity = 0;
    }
  }

  onAudioChanged: {
    if (!audio) {
      contentOpacity = 0;
    }
  }

  // Bind the default sink so audio.volume/muted are valid.
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  property bool _hasLastVolume: false
  property real _lastVolume: 0
  property bool _hasLastMuted: false
  property bool _lastMuted: false

  function bump() {
    if (!enabled || !audio) {
      return;
    }
    contentOpacity = 1;
    hideTimer.restart();
  }

  onSinkChanged: {
    _hasLastVolume = false;
    _hasLastMuted = false;
    _lastVolume = 0;
    _lastMuted = false;
  }

  Connections {
    target: audio

    function onVolumeChanged() {
      if (!osd.audio) {
        return;
      }

      if (!osd._hasLastVolume) {
        osd._lastVolume = osd.audio.volume;
        osd._hasLastVolume = true;
        return;
      }

      if (Math.abs(osd.audio.volume - osd._lastVolume) > 0.0001) {
        osd._lastVolume = osd.audio.volume;
        osd.bump();
      }
    }

    function onMutedChanged() {
      if (!osd.audio) {
        return;
      }

      if (!osd._hasLastMuted) {
        osd._lastMuted = osd.audio.muted;
        osd._hasLastMuted = true;
        return;
      }

      if (osd.audio.muted !== osd._lastMuted) {
        osd._lastMuted = osd.audio.muted;
        osd.bump();
      }
    }
  }

  Timer {
    id: hideTimer
    interval: hideAfterMs
    running: false
    repeat: false
    onTriggered: osd.contentOpacity = 0
  }

  anchor.window: anchorWindow
  // Centered under the top bar.
  anchor.rect.x: (anchorWindow.width - implicitWidth) / 2
  anchor.rect.y: anchorWindow.implicitHeight + 10
  anchor.rect.w: 1
  anchor.rect.h: 1
  anchor.edges: Edges.Top | Edges.Left
  anchor.gravity: Edges.Bottom | Edges.Right

  implicitWidth: 280
  implicitHeight: 44

  visible: enabled && audio && contentOpacity > 0.05

  // QsWindow defaults to an opaque (white) background.
  color: "transparent"
  surfaceFormat.opaque: false

  Behavior on contentOpacity {
    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
  }

  onVisibleChanged: {
    if (visible) {
      anchor.updateAnchor();
    }
  }

  Connections {
    target: anchorWindow
    function onWidthChanged() { if (osd.visible) osd.anchor.updateAnchor(); }
  }

  Rectangle {
    anchors.fill: parent
    radius: 7
    opacity: osd.contentOpacity
    color: "#282828"
    border.color: "#928374"
    border.width: 2

    RowLayout {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 6

      Text {
        text: (osd.audio && osd.audio.muted) ? "MUT" : "VOL"
        color: "#ebdbb2"
        font.family: osd.fontFamily
        font.pixelSize: 12
        font.bold: true
        Layout.preferredWidth: 28
        Layout.alignment: Qt.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }

      Rectangle {
        id: track
        color: "#3c3836"
        radius: 6
        border.color: "#504945"
        border.width: 1
        height: 12
        Layout.fillWidth: true
        Layout.minimumWidth: 140
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          radius: 6
          color: (osd.audio && osd.audio.muted) ? "#928374" : "#b8bb26"
          width: {
            if (!osd.audio) {
              return 0;
            }
            var v = Math.max(0, Math.min(1, osd.audio.volume));
            return Math.round(v * track.width);
          }
        }
      }

      Text {
        text: {
          if (!osd.audio) {
            return "--%";
          }
          var p = Math.round(Math.max(0, osd.audio.volume) * 100);
          return String(p) + "%";
        }
        color: "#ebdbb2"
        font.family: osd.fontFamily
        font.pixelSize: 12
        font.bold: true
        Layout.alignment: Qt.AlignVCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }
}
