 import Quickshell.Io
 import QtQuick
import "../themes/theme.js" as Theme

Row {
  spacing: 0

  Text {
    text: "NET"
    color: Theme.colors.grey1
    font.family: Theme.fonts.text
    font.pixelSize: 12
  }

  Item { width: 6; height: 1 }

  Text {
    id: netDown
    text: "-"
    color: Theme.colors.fg0
    font.family: Theme.fonts.text
    font.pixelSize: 12
    font.bold: true
  }

  Text {
    text: "↓"
    color: Theme.colors.blue
    font.family: Theme.fonts.text
    font.pixelSize: 12
  }

  Text {
    text: "↑"
    color: Theme.colors.purple
    font.family: Theme.fonts.text
    font.pixelSize: 12
  }

  Text {
    id: netUp
    text: "-"
    color: Theme.colors.fg0
    font.family: Theme.fonts.text
    font.pixelSize: 12
    font.bold: true
  }

  Process {
    id: netProc
    running: true
    command: [
      "sh",
      "-lc",
      "iface=$(ip route show default 2>/dev/null | awk 'NR==1{for(i=1;i<=NF;i++) if($i==\"dev\"){print $(i+1); exit}}'); " +
        "[ -z \"$iface\" ] && iface=$(awk -F: 'NR>2{gsub(/ /,\"\",$1); if($1!=\"lo\"){print $1; exit}}' /proc/net/dev); " +
        "read _ rx1 _ _ _ _ _ _ tx1 _ < <(awk -v d=\"$iface\" -F'[: ]+' '$1==d{print $1,$2,$10; exit}' /proc/net/dev); " +
        "sleep 0.3; " +
        "read _ rx2 _ _ _ _ _ _ tx2 _ < <(awk -v d=\"$iface\" -F'[: ]+' '$1==d{print $1,$2,$10; exit}' /proc/net/dev); " +
        "rxps=$(( (rx2-rx1) * 3 )); txps=$(( (tx2-tx1) * 3 )); " +
        "fmt(){ b=$1; if [ $b -ge 1048576 ]; then awk -v b=$b 'BEGIN{printf \"%.1fM\", b/1048576}'; " +
          "elif [ $b -ge 1024 ]; then awk -v b=$b 'BEGIN{printf \"%.0fK\", b/1024}'; " +
          "else printf '%dB' $b; fi; }; " +
        "down=$(fmt $rxps); up=$(fmt $txps); " +
        "printf '%s|%s\n' \"$down\" \"$up\""
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        var s = (this.text || "").trim();
        var parts = s.split("|");
        netDown.text = parts[0] || "-";
        netUp.text = parts[1] || "-";
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: netProc.running = true
  }
}
