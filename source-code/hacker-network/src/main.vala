using Gtk;
using GLib;

// ─── Modele danych ────────────────────────────────────────────────────────────

public class WifiNetwork : Object {
    public string ssid      { get; set; default = ""; }
    public string bssid     { get; set; default = ""; }
    public string signal    { get; set; default = ""; }
    public string security  { get; set; default = ""; }
    public bool   connected { get; set; default = false; }
    public int    bars      { get; set; default = 0; }

    public string signal_icon {
        get {
            if (bars >= 75) return "network-wireless-signal-excellent-symbolic";
            if (bars >= 50) return "network-wireless-signal-good-symbolic";
            if (bars >= 25) return "network-wireless-signal-ok-symbolic";
            return "network-wireless-signal-weak-symbolic";
        }
    }
}

public class WiredConnection : Object {
    public string name    { get; set; default = ""; }
    public string device  { get; set; default = ""; }
    public string state   { get; set; default = ""; }
    public string ip4     { get; set; default = ""; }
    public bool   active  { get; set; default = false; }
}

// ─── Główne okno aplikacji ─────────────────────────────────────────────────────

public class HackerNetworkWindow : Gtk.ApplicationWindow {

    // Widgety — pasek nagłówkowy
    private Gtk.HeaderBar    header_bar;
    private Gtk.Button       scan_button;
    private Gtk.Spinner      scan_spinner;
    private Gtk.Label        status_label;
    private Gtk.ToggleButton wifi_toggle;

    // Widgety — zakładki
    private Gtk.Notebook     notebook;

    // Wi-Fi
    private Gtk.ListBox      wifi_list;
    private Gtk.ScrolledWindow wifi_scroll;
    private Gtk.Box          wifi_box;

    // Przewodowe
    private Gtk.ListBox      wired_list;
    private Gtk.ScrolledWindow wired_scroll;

    // Panel informacyjny
    private Gtk.Box          info_box;
    private Gtk.Label        ip_label;
    private Gtk.Label        gateway_label;
    private Gtk.Label        dns_label;
    private Gtk.Label        hostname_label;

    // Dane
    private List<WifiNetwork>     wifi_networks;
    private List<WiredConnection> wired_connections;
    private bool wifi_enabled = true;
    private uint refresh_timer = 0;

    public HackerNetworkWindow (Gtk.Application app) {
        Object (application: app,
                title: "HackerOS Network",
                default_width: 700,
                default_height: 540);
    }

    construct {
        build_ui ();
        apply_css ();
        load_data ();
        // Auto-odświeżanie co 10 sekund
        refresh_timer = GLib.Timeout.add_seconds (10, () => {
            load_data ();
            return true;
        });
    }

    // ─── Budowanie UI ──────────────────────────────────────────────────────────

    private void build_ui () {
        // Header bar
        header_bar = new Gtk.HeaderBar ();
        header_bar.set_show_title_buttons (true);
        this.set_titlebar (header_bar);

        // Przycisk skanowania
        scan_spinner = new Gtk.Spinner ();
        scan_spinner.set_size_request (16, 16);

        var scan_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
        var scan_icon = new Gtk.Image.from_icon_name ("view-refresh-symbolic");
        scan_box.append (scan_icon);
        scan_box.append (new Gtk.Label ("Odśwież"));

        scan_button = new Gtk.Button ();
        scan_button.set_child (scan_box);
        scan_button.add_css_class ("suggested-action");
        scan_button.set_tooltip_text ("Skanuj sieci Wi-Fi");
        scan_button.clicked.connect (on_scan_clicked);
        header_bar.pack_end (scan_button);

        // Toggle Wi-Fi
        wifi_toggle = new Gtk.ToggleButton ();
        var wifi_icon = new Gtk.Image.from_icon_name ("network-wireless-symbolic");
        wifi_toggle.set_child (wifi_icon);
        wifi_toggle.set_tooltip_text ("Włącz/Wyłącz Wi-Fi");
        wifi_toggle.toggled.connect (on_wifi_toggled);
        header_bar.pack_end (wifi_toggle);

        // Status label
        status_label = new Gtk.Label ("");
        status_label.add_css_class ("status-label");
        header_bar.pack_start (status_label);

        // Notebook (zakładki)
        notebook = new Gtk.Notebook ();
        notebook.set_margin_top (0);

        // Zakładka Wi-Fi
        wifi_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        wifi_scroll = new Gtk.ScrolledWindow ();
        wifi_scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        wifi_scroll.set_vexpand (true);
        wifi_list = new Gtk.ListBox ();
        wifi_list.set_selection_mode (Gtk.SelectionMode.SINGLE);
        wifi_list.add_css_class ("wifi-list");
        wifi_list.set_activate_on_single_click (false);
        wifi_list.row_activated.connect (on_wifi_row_activated);
        wifi_scroll.set_child (wifi_list);
        wifi_box.append (wifi_scroll);

        var wifi_label = new Gtk.Label ("Wi-Fi");
        wifi_label.set_xalign (0);
        notebook.append_page (wifi_box, wifi_label);

        // Zakładka przewodowa
        wired_scroll = new Gtk.ScrolledWindow ();
        wired_scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        wired_scroll.set_vexpand (true);
        wired_list = new Gtk.ListBox ();
        wired_list.set_selection_mode (Gtk.SelectionMode.NONE);
        wired_list.add_css_class ("wired-list");
        wired_scroll.set_child (wired_list);

        var wired_label = new Gtk.Label ("Ethernet");
        notebook.append_page (wired_scroll, wired_label);

        // Zakładka informacje
        var info_scroll = new Gtk.ScrolledWindow ();
        info_scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        info_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        info_box.set_margin_start (16);
        info_box.set_margin_end (16);
        info_box.set_margin_top (16);
        info_box.set_margin_bottom (16);

        hostname_label = new Gtk.Label ("");
        hostname_label.set_xalign (0);
        ip_label      = new Gtk.Label ("");
        ip_label.set_xalign (0);
        gateway_label = new Gtk.Label ("");
        gateway_label.set_xalign (0);
        dns_label     = new Gtk.Label ("");
        dns_label.set_xalign (0);

        info_box.append (build_info_row ("Hostname",   hostname_label, "computer-symbolic"));
        info_box.append (build_info_row ("Adres IP",   ip_label,       "network-wired-symbolic"));
        info_box.append (build_info_row ("Brama",      gateway_label,  "network-server-symbolic"));
        info_box.append (build_info_row ("DNS",        dns_label,      "system-search-symbolic"));

        info_scroll.set_child (info_box);
        var info_label = new Gtk.Label ("Info");
        notebook.append_page (info_scroll, info_label);

        this.set_child (notebook);
    }

    private Gtk.Box build_info_row (string title, Gtk.Label value_label, string icon_name) {
        var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        row.add_css_class ("info-row");

        var icon = new Gtk.Image.from_icon_name (icon_name);
        icon.set_pixel_size (20);
        icon.add_css_class ("info-icon");

        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        var title_label = new Gtk.Label (title);
        title_label.set_xalign (0);
        title_label.add_css_class ("info-title");
        value_label.add_css_class ("info-value");
        value_label.set_selectable (true);
        vbox.append (title_label);
        vbox.append (value_label);

        row.append (icon);
        row.append (vbox);
        return row;
    }

    // ─── CSS ──────────────────────────────────────────────────────────────────

    private void apply_css () {
        var css = new Gtk.CssProvider ();
        css.load_from_data ("""
            window {
                background-color: #0d0d0f;
                color: #e2e8f0;
            }
            headerbar {
                background-color: #13131a;
                color: #e2e8f0;
                border-bottom: 1px solid #2a2a3a;
            }
            headerbar button {
                color: #e2e8f0;
            }
            headerbar button.suggested-action {
                background-color: #7c3aed;
                color: #ffffff;
                border-radius: 6px;
            }
            headerbar button.suggested-action:hover {
                background-color: #6d28d9;
            }
            notebook {
                background-color: #0d0d0f;
            }
            notebook header {
                background-color: #13131a;
                border-bottom: 1px solid #2a2a3a;
            }
            notebook tab {
                color: #64748b;
                padding: 6px 16px;
            }
            notebook tab:checked {
                color: #c026d3;
                border-bottom: 2px solid #c026d3;
            }
            .wifi-list row,
            .wired-list row {
                padding: 10px 14px;
                border-bottom: 1px solid #1a1a24;
                background-color: #0d0d0f;
                color: #e2e8f0;
                transition: background-color 150ms;
            }
            .wifi-list row:hover,
            .wired-list row:hover {
                background-color: #13131a;
            }
            .wifi-list row:selected {
                background-color: #1e1b4b;
            }
            .ssid-label {
                font-weight: bold;
                font-size: 14px;
                color: #e2e8f0;
            }
            .ssid-connected {
                color: #22c55e;
            }
            .signal-label {
                font-size: 12px;
                color: #64748b;
            }
            .security-badge {
                font-size: 11px;
                color: #06b6d4;
                border: 1px solid #1e3a5f;
                border-radius: 4px;
                padding: 1px 5px;
                background-color: #0c1a2e;
            }
            .connected-badge {
                font-size: 11px;
                color: #22c55e;
                border: 1px solid #14532d;
                border-radius: 4px;
                padding: 1px 5px;
                background-color: #052e16;
            }
            .info-row {
                padding: 12px 8px;
                border-bottom: 1px solid #1a1a24;
            }
            .info-icon {
                color: #c026d3;
            }
            .info-title {
                font-size: 11px;
                color: #64748b;
                text-transform: uppercase;
            }
            .info-value {
                font-size: 14px;
                color: #e2e8f0;
                font-family: monospace;
            }
            .status-label {
                font-size: 12px;
                color: #64748b;
            }
            scrolledwindow {
                background-color: #0d0d0f;
            }
            .password-dialog entry {
                background-color: #13131a;
                color: #e2e8f0;
                border: 1px solid #2a2a3a;
                border-radius: 6px;
                padding: 6px 10px;
            }
        """.data);

        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    // ─── Ładowanie danych ──────────────────────────────────────────────────────

    private void load_data () {
        check_wifi_state ();
        load_wifi_networks ();
        load_wired_connections ();
        load_network_info ();
    }

    private void check_wifi_state () {
        string output;
        try {
            GLib.Process.spawn_command_line_sync (
                "nmcli radio wifi",
                out output, null, null
            );
            wifi_enabled = output.strip () == "enabled";
            wifi_toggle.set_active (wifi_enabled);
        } catch (GLib.Error e) {
            warning ("Błąd sprawdzania stanu Wi-Fi: %s", e.message);
        }
    }

    private void load_wifi_networks () {
        // Usuń stare wpisy
        while (true) {
            var child = wifi_list.get_first_child ();
            if (child == null) break;
            wifi_list.remove (child);
        }

        wifi_networks = new List<WifiNetwork> ();

        if (!wifi_enabled) {
            var disabled_label = new Gtk.Label ("Wi-Fi jest wyłączone");
            disabled_label.add_css_class ("dim-label");
            disabled_label.set_margin_top (40);
            wifi_list.append (disabled_label);
            return;
        }

        string output;
        try {
            GLib.Process.spawn_command_line_sync (
                "nmcli -t -f SSID,BSSID,SIGNAL,SECURITY,ACTIVE device wifi list",
                out output, null, null
            );
        } catch (GLib.Error e) {
            warning ("Błąd pobierania sieci Wi-Fi: %s", e.message);
            return;
        }

        var lines = output.split ("\n");
        foreach (var line in lines) {
            if (line.strip () == "") continue;
            var parts = line.split (":");
            if (parts.length < 5) continue;

            var net = new WifiNetwork ();
            net.ssid      = parts[0].strip ();
            net.bssid     = parts[1].strip ();
            net.signal    = parts[2].strip ();
            net.security  = parts[3].strip ();
            net.connected = parts[4].strip () == "yes";
            net.bars      = int.parse (net.signal);

            if (net.ssid == "" || net.ssid == "--") continue;

            wifi_networks.append (net);
            wifi_list.append (build_wifi_row (net));
        }

        if (wifi_networks.length () == 0) {
            var empty_label = new Gtk.Label ("Nie znaleziono sieci Wi-Fi");
            empty_label.set_margin_top (40);
            wifi_list.append (empty_label);
        }
    }

    private Gtk.Widget build_wifi_row (WifiNetwork net) {
        var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        row.set_margin_start (4);
        row.set_margin_end (4);

        // Ikona sygnału
        var signal_image = new Gtk.Image.from_icon_name (net.signal_icon);
        signal_image.set_pixel_size (22);

        // SSID + badges
        var text_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        text_box.set_hexpand (true);

        var ssid_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        var ssid_label = new Gtk.Label (net.ssid);
        ssid_label.set_xalign (0);
        ssid_label.add_css_class ("ssid-label");
        if (net.connected) {
            ssid_label.add_css_class ("ssid-connected");
        }
        ssid_row.append (ssid_label);

        if (net.connected) {
            var badge = new Gtk.Label ("Połączona");
            badge.add_css_class ("connected-badge");
            ssid_row.append (badge);
        }
        if (net.security != "" && net.security != "--") {
            var sec_badge = new Gtk.Label (net.security.split (" ")[0]);
            sec_badge.add_css_class ("security-badge");
            ssid_row.append (sec_badge);
        }

        text_box.append (ssid_row);

        var signal_label = new Gtk.Label ("Sygnał: %s%%".printf (net.signal));
        signal_label.set_xalign (0);
        signal_label.add_css_class ("signal-label");
        text_box.append (signal_label);

        // Przycisk połącz/rozłącz
        var action_button = new Gtk.Button ();
        if (net.connected) {
            action_button.set_label ("Rozłącz");
            action_button.add_css_class ("destructive-action");
            action_button.clicked.connect (() => {
                disconnect_wifi ();
            });
        } else {
            action_button.set_label ("Połącz");
            action_button.add_css_class ("suggested-action");
            string ssid_copy = net.ssid;
            string security_copy = net.security;
            action_button.clicked.connect (() => {
                connect_to_wifi (ssid_copy, security_copy);
            });
        }

        row.append (signal_image);
        row.append (text_box);
        row.append (action_button);
        return row;
    }

    private void load_wired_connections () {
        while (true) {
            var child = wired_list.get_first_child ();
            if (child == null) break;
            wired_list.remove (child);
        }

        wired_connections = new List<WiredConnection> ();

        string output;
        try {
            GLib.Process.spawn_command_line_sync (
                "nmcli -t -f NAME,DEVICE,TYPE,STATE connection show",
                out output, null, null
            );
        } catch (GLib.Error e) {
            warning ("Błąd pobierania połączeń: %s", e.message);
            return;
        }

        var lines = output.split ("\n");
        foreach (var line in lines) {
            if (line.strip () == "") continue;
            var parts = line.split (":");
            if (parts.length < 4) continue;
            if (parts[2] != "802-3-ethernet") continue;

            var conn = new WiredConnection ();
            conn.name   = parts[0].strip ();
            conn.device = parts[1].strip ();
            conn.state  = parts[3].strip ();
            conn.active = parts[3].strip () == "activated";

            wired_connections.append (conn);
            wired_list.append (build_wired_row (conn));
        }

        if (wired_connections.length () == 0) {
            var empty_label = new Gtk.Label ("Brak połączeń Ethernet");
            empty_label.set_margin_top (40);
            wired_list.append (empty_label);
        }
    }

    private Gtk.Widget build_wired_row (WiredConnection conn) {
        var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        row.set_margin_start (4);
        row.set_margin_end (4);

        var icon_name = conn.active
            ? "network-wired-symbolic"
            : "network-wired-disconnected-symbolic";
        var icon = new Gtk.Image.from_icon_name (icon_name);
        icon.set_pixel_size (22);

        var text_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        text_box.set_hexpand (true);

        var name_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        var name_label = new Gtk.Label (conn.name);
        name_label.set_xalign (0);
        name_label.add_css_class ("ssid-label");
        if (conn.active) name_label.add_css_class ("ssid-connected");
        name_row.append (name_label);

        if (conn.active) {
            var badge = new Gtk.Label ("Aktywna");
            badge.add_css_class ("connected-badge");
            name_row.append (badge);
        }

        text_box.append (name_row);

        var dev_label = new Gtk.Label ("Urządzenie: %s".printf (
            conn.device == "" ? "brak" : conn.device));
        dev_label.set_xalign (0);
        dev_label.add_css_class ("signal-label");
        text_box.append (dev_label);

        // Przyciski
        var btn_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
        if (conn.active) {
            var disc_btn = new Gtk.Button.with_label ("Rozłącz");
            disc_btn.add_css_class ("destructive-action");
            string name_copy = conn.name;
            disc_btn.clicked.connect (() => {
                run_nmcli ({ "connection", "down", name_copy });
                GLib.Timeout.add (1200, () => { load_data (); return false; });
            });
            btn_box.append (disc_btn);
        } else {
            var conn_btn = new Gtk.Button.with_label ("Połącz");
            conn_btn.add_css_class ("suggested-action");
            string name_copy = conn.name;
            conn_btn.clicked.connect (() => {
                run_nmcli ({ "connection", "up", name_copy });
                GLib.Timeout.add (1200, () => { load_data (); return false; });
            });
            btn_box.append (conn_btn);
        }

        row.append (icon);
        row.append (text_box);
        row.append (btn_box);
        return row;
    }

    private void load_network_info () {
        // Hostname
        try {
            string hn;
            GLib.Process.spawn_command_line_sync ("hostname", out hn, null, null);
            hostname_label.set_text (hn.strip ());
        } catch {}

        // IP (pierwsza aktywna)
        try {
            string ip_out;
            GLib.Process.spawn_command_line_sync (
                "nmcli -t -f IP4.ADDRESS device show",
                out ip_out, null, null
            );
            var ips = new GLib.StringBuilder ();
            foreach (var line in ip_out.split ("\n")) {
                if (line.has_prefix ("IP4.ADDRESS")) {
                    var parts = line.split (":");
                    if (parts.length >= 2 && parts[1].strip () != "") {
                        ips.append (parts[1].strip ());
                        ips.append ("  ");
                    }
                }
            }
            ip_label.set_text (ips.str.strip () == "" ? "brak" : ips.str.strip ());
        } catch {}

        // Gateway
        try {
            string gw_out;
            GLib.Process.spawn_command_line_sync (
                "nmcli -t -f IP4.GATEWAY device show",
                out gw_out, null, null
            );
            var gw = "";
            foreach (var line in gw_out.split ("\n")) {
                if (line.has_prefix ("IP4.GATEWAY")) {
                    var parts = line.split (":");
                    if (parts.length >= 2 && parts[1].strip () != "") {
                        gw = parts[1].strip ();
                        break;
                    }
                }
            }
            gateway_label.set_text (gw == "" ? "brak" : gw);
        } catch {}

        // DNS
        try {
            string dns_out;
            GLib.Process.spawn_command_line_sync (
                "nmcli -t -f IP4.DNS device show",
                out dns_out, null, null
            );
            var dns_list = new GLib.StringBuilder ();
            foreach (var line in dns_out.split ("\n")) {
                if (line.has_prefix ("IP4.DNS")) {
                    var parts = line.split (":");
                    if (parts.length >= 2 && parts[1].strip () != "") {
                        dns_list.append (parts[1].strip ());
                        dns_list.append ("  ");
                    }
                }
            }
            dns_label.set_text (dns_list.str.strip () == "" ? "brak" : dns_list.str.strip ());
        } catch {}
    }

    // ─── Akcje ────────────────────────────────────────────────────────────────

    private void on_scan_clicked () {
        scan_button.set_sensitive (false);
        status_label.set_text ("Skanowanie…");

        GLib.Thread<void> thread = new GLib.Thread<void> ("scan", () => {
            try {
                GLib.Process.spawn_command_line_sync (
                    "nmcli device wifi rescan", null, null, null
                );
            } catch {}

            GLib.Idle.add (() => {
                load_data ();
                scan_button.set_sensitive (true);
                status_label.set_text ("");
                return false;
            });
        });
        thread.join ();
    }

    private void on_wifi_toggled () {
        var enable = wifi_toggle.get_active ();
        var cmd = enable ? "nmcli radio wifi on" : "nmcli radio wifi off";
        try {
            GLib.Process.spawn_command_line_sync (cmd, null, null, null);
        } catch {}
        GLib.Timeout.add (800, () => { load_data (); return false; });
    }

    private void on_wifi_row_activated (Gtk.ListBoxRow row) {
        // Aktywacja rzędu otwiera dialog połączenia — obsługiwane przez przyciski
    }

    private void connect_to_wifi (string ssid, string security) {
        // Sprawdź czy sieć wymaga hasła
        bool needs_password = security != "" && security != "--" && security != "none";

        if (!needs_password) {
            // Otwarta sieć
            run_nmcli ({ "device", "wifi", "connect", ssid });
            GLib.Timeout.add (2000, () => { load_data (); return false; });
            return;
        }

        // Dialog z hasłem
        var dialog = new Gtk.Dialog ();
        dialog.set_title ("Połącz z siecią %s".printf (ssid));
        dialog.set_transient_for (this);
        dialog.set_modal (true);

        var content = dialog.get_content_area ();
        content.set_spacing (12);
        content.set_margin_start (16);
        content.set_margin_end (16);
        content.set_margin_top (12);
        content.set_margin_bottom (12);

        var info = new Gtk.Label ("Podaj hasło do sieci:");
        info.set_xalign (0);
        content.append (info);

        var password_entry = new Gtk.Entry ();
        password_entry.set_visibility (false);
        password_entry.set_input_purpose (Gtk.InputPurpose.PASSWORD);
        password_entry.set_placeholder_text ("Hasło Wi-Fi");
        password_entry.add_css_class ("password-dialog");
        content.append (password_entry);

        var show_pass = new Gtk.CheckButton.with_label ("Pokaż hasło");
        show_pass.toggled.connect (() => {
            password_entry.set_visibility (show_pass.get_active ());
        });
        content.append (show_pass);

        dialog.add_button ("Anuluj", Gtk.ResponseType.CANCEL);
        var connect_btn = dialog.add_button ("Połącz", Gtk.ResponseType.OK) as Gtk.Button;
        if (connect_btn != null) {
            connect_btn.add_css_class ("suggested-action");
        }

        password_entry.activate.connect (() => {
            dialog.response (Gtk.ResponseType.OK);
        });

        dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.OK) {
                var password = password_entry.get_text ();
                if (password.length > 0) {
                    status_label.set_text ("Łączenie z %s…".printf (ssid));
                    run_nmcli ({
                        "device", "wifi", "connect", ssid,
                        "password", password
                    });
                    GLib.Timeout.add (3000, () => {
                        load_data ();
                        status_label.set_text ("");
                        return false;
                    });
                }
            }
            dialog.destroy ();
        });

        dialog.present ();
    }

    private void disconnect_wifi () {
        try {
            GLib.Process.spawn_command_line_sync (
                "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE device | grep wireless | cut -d: -f1 | head -1)",
                null, null, null
            );
        } catch {}
        GLib.Timeout.add (1200, () => { load_data (); return false; });
    }

    private void run_nmcli (string[] args) {
        string[] argv = new string[args.length + 1];
        argv[0] = "nmcli";
        for (int i = 0; i < args.length; i++) {
            argv[i + 1] = args[i];
        }
        try {
            GLib.Process.spawn_sync (
                null, argv, null,
                GLib.SpawnFlags.SEARCH_PATH,
                null, null, null, null
            );
        } catch (GLib.Error e) {
            warning ("Błąd nmcli: %s", e.message);
        }
    }

    // ─── Destruktor ───────────────────────────────────────────────────────────

    ~HackerNetworkWindow () {
        if (refresh_timer > 0) {
            GLib.Source.remove (refresh_timer);
        }
    }
}

// ─── Aplikacja GTK ────────────────────────────────────────────────────────────

public class HackerNetworkApp : Gtk.Application {

    public HackerNetworkApp () {
        Object (
            application_id: "io.hackeros.network",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var win = new HackerNetworkWindow (this);
        win.present ();
    }
}

// ─── Entry point ─────────────────────────────────────────────────────────────

public static int main (string[] args) {
    return new HackerNetworkApp ().run (args);
}
