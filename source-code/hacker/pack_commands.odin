package hackeros

import "core:fmt"
import "core:os"

handle_pack :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 || args[0] == "help" {
		show_pack_help(lang)
		os.exit(0)
	}
	sub := args[0]
	switch sub {
	case "install":
		fmt.printfln("%s%s HackerLand...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
		safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/HackerLand/main/remove.hl -o /tmp/remove.hl")
		safe_run("hl run /tmp/remove.hl")
		safe_run("rm -f /tmp/remove.hl")
		fmt.printfln("%s%s%s", Colors.green, trans["pack_full_done"], Colors.reset)

	case "add-ons":
		safe_run("sudo apt remove -y wine winetricks")
		safe_run("flatpak uninstall -y flathub io.github.dvlv.boxbuddyrs")
		safe_run("flatpak uninstall -y flathub it.mijorus.winezgui")
		safe_run("flatpak uninstall -y flathub it.mijorus.gearlever")

	case "gs":
		handle_pack([]string{"gaming"}, lang)
		handle_pack([]string{"cybersecurity"}, lang)

	case "devtools":
		safe_run("flatpak uninstall -y flathub io.atom.Atom")
		safe_run("sudo apt remove -y crystal shards")
		safe_run("sudo apt remove -y npm nodejs")
		safe_run("flatpak uninstall -y flathub com.visualstudio.code")
		safe_run("rustup self uninstall -y || true")
		safe_run("sudo apt remove -y golang-go")
		safe_run("sudo apt remove -y lua5.4")
		safe_run("sudo snap remove zig")

	case "emulators":
		safe_run("flatpak uninstall -y flathub org.shadps4.shadPS4")
		safe_run("flatpak uninstall -y flathub io.ryujinx.Ryujinx")
		safe_run("flatpak uninstall -y flathub com.dosbox_x.DOSBox-X")
		safe_run("sudo snap remove rpcs3-emu")

	case "cybersecurity":
		safe_run("distrobox rm -f blackarch")

	case "select":
		safe_run("~/.hackeros/hacker/hacker-select --pack")

	case "gaming":
		safe_run("flatpak uninstall -y flathub com.valvesoftware.Steam")
		safe_run("flatpak uninstall -y flathub com.github.Matoking.protontricks")
		safe_run("flatpak uninstall -y flathub com.heroicgameslauncher.hgl")
		safe_run("flatpak uninstall -y flathub com.vysp3r.ProtonPlus")
		safe_run("flatpak uninstall -y flathub io.github.giantpinkrobots.varia")
		safe_run("flatpak uninstall -y flathub org.vinegarhq.Sober")
		safe_run("flatpak uninstall -y flathub org.vinegarhq.Vinegar")

	case "hacker-mode":
		safe_run("git clone https://github.com/HackerOS-Linux-System/Hacker-Mode.git /tmp/Hacker-Mode || true")
		safe_run("hl run /tmp/Hacker-Mode/remove.hl")
		safe_run("rm -rf /tmp/Hacker-Mode")

	case "gamescope-session-steam":
		safe_run("flatpak uninstall -y flathub com.valvesoftware.Steam")
		safe_run("flatpak uninstall -y flathub org.freedesktop.Platform.VulkanLayer.gamescope")
		safe_run("git clone https://github.com/HackerOS-Linux-System/gamescope-session-steam.git /tmp/gamescope-session-steam || true")
		safe_run("hl run /tmp/gamescope-session-steam/remove.hl")
		safe_run("rm -rf /tmp/gamescope-session-steam")

	case "xanmod":
		safe_run("/usr/share/HackerOS/Scripts/Bin/remove-xanmod.sh")

	case "liquorix":
		safe_run("/usr/share/HackerOS/Scripts/Bin/remove-liquorix.sh")

	case "automatic-updates":
		safe_run("sudo systemctl disable --now hup.service || true")
		safe_run("sudo rm -f /etc/systemd/system/hup.service")
		safe_run("sudo systemctl daemon-reload")

	case "alacritty-config":
		safe_run("rm -f ~/.config/alacritty/alacritty.toml")
		fmt.printfln("%s%s%s", Colors.green, trans["pack_alacritty_done"], Colors.reset)

	case "hackeros-tv":
		safe_run("git clone https://github.com/HackerOS-Linux-System/HackerOS-TV.git /tmp/HackerOS-TV || true")
		safe_run("hl run /tmp/HackerOS-TV/remove.hl")
		safe_run("rm -rf /tmp/HackerOS-TV")

	case "security-mode":
		safe_run("git clone https://github.com/HackerOS-Linux-System/Security-Mode.git /tmp/Security-Mode || true")
		safe_run("hl run /tmp/Security-Mode/remove.hl")
		safe_run("rm -rf /tmp/Security-Mode")

	case "winboat":
		safe_run("sudo apt remove -y winboat || true")

	case "nvidia-drivers":
		safe_run("/usr/share/HackerOS/Scripts/Bin/remove-nvidia-drivers.sh")

	case "hl-utils":
		safe_run("sudo rm -f /usr/bin/bytes /usr/bin/hli")

	case "flox":
		safe_run("sudo apt remove -y flox || true")

	case "hackeros-builder":
		safe_run("sudo rm -f /usr/bin/hackeros-builder")

	case "isolator":
		safe_run("sudo rm -f /usr/bin/isolator")

	case "hammer":
		fmt.printfln("%s%s hammer...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
		safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/hammer/main/remove.hl -o /tmp/remove.hl")
		safe_run("hl run /tmp/remove.hl")
		safe_run("rm -f /tmp/remove.hl")
		fmt.printfln("%s%s%s", Colors.green, trans["pack_done"], Colors.reset)

	case "hackerland":
		fmt.printfln("%s%s HackerLand...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
		safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/HackerLand/main/remove.hl -o /tmp/remove.hl")
		safe_run("hl run /tmp/remove.hl")
		safe_run("rm -f /tmp/remove.hl")
		fmt.printfln("%s%s%s", Colors.green, trans["pack_done"], Colors.reset)

	case "H#":
		fmt.printfln("%s%s H#...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
		safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/H-Sharp/main/remove.hl -o /tmp/remove.hl")
		safe_run("hl run /tmp/remove.hl")
		safe_run("rm -f /tmp/remove.hl")
		fmt.printfln("%s%s%s", Colors.green, trans["pack_done"], Colors.reset)

	case:
		fmt.printfln("%s%s %s%s", Colors.red, trans["pack_unknown"], sub, Colors.reset)
		show_pack_help(lang)
		os.exit(1)
	}
}

show_pack_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["pack_title"], Colors.reset)
	cmds := [][2]string{
		{"install",                   trans["pack_install"]},
		{"add-ons",                   trans["pack_add_ons"]},
		{"gs",                        trans["pack_gs"]},
		{"devtools",                  trans["pack_devtools"]},
		{"emulators",                 trans["pack_emulators"]},
		{"cybersecurity",             trans["pack_cybersecurity"]},
		{"select",                    trans["pack_select"]},
		{"gaming",                    trans["pack_gaming"]},
		{"hacker-mode",               trans["pack_hacker_mode"]},
		{"gamescope-session-steam",   trans["pack_gamescope"]},
		{"xanmod",                    trans["pack_xanmod"]},
		{"liquorix",                  trans["pack_liquorix"]},
		{"automatic-updates",         trans["pack_auto_updates"]},
		{"alacritty-config",          trans["pack_alacritty"]},
		{"hackeros-tv",               trans["pack_hackeros_tv"]},
		{"security-mode",             trans["pack_security_mode"]},
		{"winboat",                   trans["pack_winboat"]},
		{"nvidia-drivers",            trans["pack_nvidia"]},
		{"hl-utils",                  trans["pack_hl_utils"]},
		{"flox",                      trans["pack_flox"]},
		{"hackeros-builder",          trans["pack_builder"]},
		{"isolator",                  trans["pack_isolator"]},
		{"hammer",                    trans["pack_hammer"]},
		{"hackerland",                trans["pack_hackerland"]},
		{"H#",                        trans["pack_hsharp"]},
	}
	for c in cmds {
		fmt.printfln(" %s%-28s %s- %s", Colors.gray, c[0], Colors.reset, c[1])
	}
}
