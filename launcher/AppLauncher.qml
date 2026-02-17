import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../themes/theme.js" as Theme
import "fuzzy.js" as Fuzzy

PanelWindow {
  id: launcher

  required property var anchorWindow
  property bool enabled: true
  property bool open: false
  property int open_seq: 0
  property int max_results: 10

  signal closeRequested

  // If set, we focus this address after the launcher surface is actually unmapped.
  // This avoids the layer-shell surface immediately stealing focus back.
  property string _pending_focus_address: ""

  visible: enabled && open

  screen: anchorWindow.screen
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  focusable: true

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  WlrLayershell.namespace: "lunos-launcher"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  // QsWindow defaults to an opaque (white) background.
  color: "transparent"
  surfaceFormat.opaque: false

  onVisibleChanged: {
    if (visible) {
      Qt.callLater(function () {
        focus_scope.forceActiveFocus();
      });
    }
  }

  // ---- Data ----

  property string query: ""
  property var indexed_entries: []
  property var filtered_entries: []
  property int selected_index: 0

  function rebuildIndex() {
    var values = DesktopEntries.applications.values || [];
    var out = [];

    for (var i = 0; i < values.length; i++) {
      var entry = values[i];
      if (!entry) {
        continue;
      }

      var keywords = entry.keywords || [];
      var keywords_join = "";
      if (keywords.length > 0) {
        keywords_join = keywords.join(" ");
      }

      var search_text = ((entry.name || "") + " " + (entry.genericName || "")
                         + " " + keywords_join).toLowerCase();

      out.push({
                 entry: entry,
                 name_lc: String(entry.name || "").toLowerCase(),
                 search_text: search_text
               });
    }

    out.sort(function (a, b) {
      return a.name_lc.localeCompare(b.name_lc);
    });

    indexed_entries = out;
    updateFilter();
  }

  function updateFilter() {
    var q = String(query || "").trim().toLowerCase();
    var results = [];

    if (indexed_entries.length === 0) {
      filtered_entries = [];
      selected_index = 0;
      return;
    }

    if (q.length === 0) {
      for (var i = 0; i < indexed_entries.length && results.length
           < max_results; i++) {
        results.push(indexed_entries[i].entry);
      }
      filtered_entries = results;
      selected_index = 0;
      return;
    }

    for (var j = 0; j < indexed_entries.length; j++) {
      var item = indexed_entries[j];
      var s = Fuzzy.score(q, item.search_text);
      if (s > 0) {
        results.push({
                       entry: item.entry,
                       score: s
                     });
      }
    }

    results.sort(function (a, b) {
      if (b.score !== a.score) {
        return b.score - a.score;
      }
      var an = String(a.entry.name || "");
      var bn = String(b.entry.name || "");
      return an.localeCompare(bn);
    });

    var out = [];
    for (var k = 0; k < results.length && out.length < max_results; k++) {
      out.push(results[k].entry);
    }

    filtered_entries = out;
    selected_index = 0;
  }

  function resetState() {
    query = "";
    search_bar.text = "";
    updateFilter();
  }

  function requestClose() {
    closeRequested();
  }

  function selectedEntry() {
    if (!filtered_entries || filtered_entries.length === 0) {
      return null;
    }
    var idx = selected_index;
    if (idx < 0 || idx >= filtered_entries.length) {
      return null;
    }
    return filtered_entries[idx];
  }

  function _norm(s) {
    if (!s) {
      return "";
    }
    return String(s).trim().toLowerCase();
  }

  function classCandidates(entry) {
    if (!entry) {
      return [];
    }

    var out = [];
    function add(val) {
      var v = _norm(val);
      if (!v || v.length === 0) {
        return;
      }
      if (out.indexOf(v) === -1) {
        out.push(v);
      }
    }

    // Primary, explicit hint for matching to running windows.
    add(entry.startupClass);

    // Fallbacks (still exact match): often useful when startupClass is missing.
    add(entry.id);

    try {
      var cmd0 = (entry.command && entry.command.length > 0) ? entry.command[0] :
                                                               "";
      if (cmd0 && typeof cmd0 === "string") {
        var base = cmd0.split("/").pop();
        add(base);
      }
    } catch (e)
      // ignore
    {}

    return out;
  }

  function findMatchingToplevelNow(entry) {
    var candidates = classCandidates(entry);
    if (candidates.length === 0) {
      return null;
    }

    var tops = (Hyprland.toplevels && Hyprland.toplevels.values)
        ? Hyprland.toplevels.values : [];
    var best = null;

    for (var i = 0; i < tops.length; i++) {
      var t = tops[i];
      if (!t) {
        continue;
      }

      var ipc = t.lastIpcObject || {};
      var cls = _norm(ipc.class || "");
      var initial_cls = _norm(ipc.initialClass || "");
      var appid = "";
      try {
        appid = _norm(t.wayland && t.wayland.appId ? t.wayland.appId : "");
      } catch (e) {
        appid = "";
      }

      var match = false;
      for (var j = 0; j < candidates.length; j++) {
        var c = candidates[j];
        if (appid === c || cls === c || initial_cls === c) {
          match = true;
          break;
        }
      }
      if (!match) {
        continue;
      }

      if (!best) {
        best = t;
        continue;
      }

      // Prefer already-activated windows when multiple match.
      if (t.activated && !best.activated) {
        best = t;
        continue;
      }
    }

    return best;
  }

  function focusAddressForToplevel(toplevel) {
    if (!toplevel) {
      return "";
    }

    var addr = _norm(toplevel.address);
    if (!addr || addr.length === 0) {
      return "";
    }

    // Hyprland expects window addresses to be prefixed with 0x.
    if (addr.indexOf("0x") !== 0) {
      addr = "0x" + addr;
    }

    return addr;
  }

  function queueFocusAddress(addr) {
    var a = _norm(addr);
    if (!a || a.length === 0) {
      return false;
    }

    if (a.indexOf("0x") !== 0) {
      a = "0x" + a;
    }

    _pending_focus_address = a;
    requestClose();
    return true;
  }

  property var _pending_entry: null

  Timer {
    id: _deferred_run
    interval: 75
    repeat: false
    onTriggered: {
      if (!launcher.open || !launcher._pending_entry) {
        launcher._pending_entry = null;
        return;
      }

      var entry = launcher._pending_entry;
      launcher._pending_entry = null;

      var t = launcher.findMatchingToplevelNow(entry);
      if (t) {
        var addr = launcher.focusAddressForToplevel(t);
        if (addr.length > 0) {
          launcher.queueFocusAddress(addr);
          return;
        }
      }

      if (!launcher.open) {
        return;
      }

      entry.execute();
      launcher.requestClose();
    }
  }

  function runSelected(force_exec) {
    var entry = selectedEntry();
    if (!entry) {
      return;
    }

    if (!force_exec) {
      Hyprland.refreshToplevels();

      var t = findMatchingToplevelNow(entry);
      if (t) {
        var addr = focusAddressForToplevel(t);
        if (addr.length > 0) {
          _pending_entry = null;
          _deferred_run.stop();
          queueFocusAddress(addr);
          return;
        }
      }

      // Give Hyprland a moment to deliver refreshed toplevel metadata (startupClass/class).
      _pending_entry = entry;
      _deferred_run.restart();
      return;
    }

    entry.execute();
    requestClose();
  }

  Component.onCompleted: rebuildIndex()

  Connections {
    target: DesktopEntries
    function onApplicationsChanged() {
      launcher.rebuildIndex();
    }
  }

  onOpenChanged: {
    if (open) {
      Hyprland.refreshToplevels();
      resetState();
      _pending_focus_address = "";
      return;
    }

    _pending_entry = null;
    _deferred_run.stop();
  }

  onBackingWindowVisibleChanged: {
    if (backingWindowVisible) {
      return;
    }

    if (_pending_focus_address.length === 0) {
      return;
    }

    var addr = _pending_focus_address;
    _pending_focus_address = "";

    Qt.callLater(function () {
      Hyprland.dispatch("focuswindow address:" + addr);
    });
  }

  onOpen_seqChanged: {
    if (open) {
      Hyprland.refreshToplevels();
      resetState();
      return;
    }
  }

  onQueryChanged: updateFilter()

  FocusScope {
    id: focus_scope
    anchors.fill: parent

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_Escape) {
        if ((search_bar.text || "").length > 0) {
          search_bar.text = "";
        } else {
          launcher.requestClose();
        }
        event.accepted = true;
        return;
      }

      // Let TextInput handle text entry; only intercept navigation/launch keys.
      if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        var force_exec = (event.modifiers & Qt.ShiftModifier) !== 0;
        launcher.runSelected(force_exec);
        event.accepted = true;
        return;
      }

      if (event.key === Qt.Key_Up) {
        launcher.selected_index = Math.max(0, launcher.selected_index - 1);
        event.accepted = true;
        return;
      }

      if (event.key === Qt.Key_Down) {
        launcher.selected_index = Math.min(Math.max(0,
                                                    launcher.filtered_entries.length
                                                    - 1), launcher.selected_index
                                           + 1);
        event.accepted = true;
        return;
      }
    }

    Backdrop {
      onClicked: launcher.requestClose()
    }

    LauncherCard {
      id: card

      property int card_width: Math.min(820, Math.max(520, Math.round(
                                                        launcher.width * 0.56)))
      property int card_height: Math.min(560, Math.max(300, Math.round(
                                                         launcher.height
                                                         * 0.62)))

      width: card_width
      height: card_height
      anchors.centerIn: parent
      accent_color: Theme.colors.yellow

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        SearchBar {
          id: search_bar
          Layout.fillWidth: true
          accent_color: Theme.colors.yellow
          onTextEdited: function (text) {
            launcher.query = text;
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Theme.colors.bg3
          opacity: 0.9
        }

        ResultsView {
          id: results_view
          Layout.fillWidth: true
          Layout.fillHeight: true
          entries: launcher.filtered_entries
          selected_index: launcher.selected_index

          onActivated: function (idx) {
            launcher.selected_index = idx;
            launcher.runSelected(false);
          }
        }
      }
    }
  }
}
