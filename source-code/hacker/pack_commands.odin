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
		case "add-ons":
			safe_run("sudo apt remove -y wine winetricks")
			safe_run("flatpak uninstall -y flathub io.github.dvlv.boxbuddyrs")
			safe_run("flatpak uninstall -y flathub it.mijorus.winezgui")
			safe_run("flatpak uninstall -y flathub it.mijorus.gearlever")
		case "gs":
			handle_pack([]string{"gaming"}, lang)
			handle_pack([]string{"cybersecurity"}, lang)
		case "devtools":
			safe_run("flatpak uninstall -y flathub com.visualstudio.code")
			safe_run("sudo apt remove -y crystal shards")
			safe_run("sudo apt remove -y npm nodejs")
			safe_run("rustup self uninstall -y || true")
			// Zamiast golang-go usuwamy golang (co spowoduje usunięcie golang-go)
			safe_run("sudo apt remove -y golang")
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
		case "winboat":
			safe_run("sudo apt remove -y winboat || true")
		case "nvidia-drivers":
			safe_run("/usr/share/HackerOS/Scripts/Bin/remove-nvidia-drivers.sh")
		case "hl-utils":
			// Nowa implementacja: pobiera i uruchamia remove-utils.hl
			fmt.printfln("%s%s hl-utils...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
			safe_run("curl -L https://github.com/HackerOS-Linux-System/Hacker-Lang/blob/main/remove-utils.hl -o /tmp/remove-utils.hl")
			safe_run("hl run /tmp/remove-utils.hl")
			safe_run("rm -f /tmp/remove-utils.hl")
			fmt.printfln("%s%s%s", Colors.green, trans["pack_done"], Colors.reset)
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
		case "lpm":
			fmt.printfln("%s%s lpm...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
			safe_run("curl -L https://github.com/HackerOS-Linux-System/lpm/blob/main/remove.hl -o /tmp/remove.hl")
			safe_run("hl run /tmp/remove.hl")
			safe_run("rm -f /tmp/remove.hl")
			fmt.printfln("%s%s%s", Colors.green, trans["pack_done"], Colors.reset)
		case "HackerScript":
			fmt.printfln("%s%s HackerScript...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
			safe_run("curl -L https://github.com/HackerOS-Linux-System/HackerScript/blob/main/remove.hl -o /tmp/remove.hl")
			safe_run("hl run /tmp/remove.hl")
			safe_run("rm -f /tmp/remove.hl")
			fmt.printfln("%s%s%s", Colors.green, trans["pack_done"], Colors.reset)
		case "hackeros-games-addons":
			fmt.printfln("%sUsuwanie hackeros-games-addons...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
			safe_run("curl -L https://github.com/HackerOS-Linux-System/HackerOS-Games/raw/main/addons-remove.hl -o /tmp/addons-remove.hl")
			safe_run("hl run /tmp/addons-remove.hl")
			safe_run("rm -f /tmp/addons-remove.hl")
			fmt.printfln("%sDodatki do gier HackerOS usunięte pomyślnie.%s", Colors.green, trans["pack_done"], Colors.reset)
			// Nowe komendy
		case "hexai":
			fmt.printfln("%s%s HexAi...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
			safe_run("curl -L https://github.com/HackerOS-Linux-System/HexAi/blob/main/remove.hl -o /tmp/hexai-remove.hl")
			safe_run("hl run /tmp/hexai-remove.hl")
			safe_run("rm -f /tmp/hexai-remove.hl")
			fmt.printfln("%s%s%s", Colors.green, trans["pack_done"], Colors.reset)
		case "hackerscript-utils":
			fmt.printfln("%s%s HackerScript Utils...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
			safe_run("curl -L https://github.com/HackerOS-Linux-System/HackerScript/blob/main/remove-utils.hl -o /tmp/hackerscript-utils-remove.hl")
			safe_run("hl run /tmp/hackerscript-utils-remove.hl")
			safe_run("rm -f /tmp/hackerscript-utils-remove.hl")
			fmt.printfln("%s%s%s", Colors.green, trans["pack_done"], Colors.reset)
		case "hackerdeck":
			fmt.printfln("%s%s HackerDeck...%s", Colors.yellow, trans["pack_downloading"], Colors.reset)
			safe_run("curl -L https://github.com/HackerOS-Linux-System/HackerDeck/blob/main/remove.hl -o /tmp/hackerdeck-remove.hl")
			safe_run("hl run /tmp/hackerdeck-remove.hl")
			safe_run("rm -f /tmp/hackerdeck-remove.hl")
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
		{"add-ons", trans["pack_add_ons"]},
		{"gs", trans["pack_gs"]},
		{"devtools", trans["pack_devtools"]},
		{"emulators", trans["pack_emulators"]},
		{"cybersecurity", trans["pack_cybersecurity"]},
		{"select", trans["pack_select"]},
		{"gaming", trans["pack_gaming"]},
		{"hacker-mode", trans["pack_hacker_mode"]},
		{"gamescope-session-steam", trans["pack_gamescope"]},
		{"automatic-updates", trans["pack_auto_updates"]},
		{"alacritty-config", trans["pack_alacritty"]},
		{"hackeros-tv", trans["pack_hackeros_tv"]},
		{"winboat", trans["pack_winboat"]},
		{"nvidia-drivers", trans["pack_nvidia"]},
		{"hl-utils", trans["pack_hl_utils"]},
		{"flox", trans["pack_flox"]},
		{"hackeros-builder", trans["pack_builder"]},
		{"isolator", trans["pack_isolator"]},
		{"hammer", trans["pack_hammer"]},
		{"lpm", trans["pack_lpm"]},
		{"hackeros-games-addons", trans["pack_hackeros-games"]},
		{"HackerScript", trans["pack_hackerscript"]},
		// Nowe
		{"hexai", trans["pack_hexai"]},
		{"hackerscript-utils", trans["pack_hackerscript_utils"]},
		{"hackerdeck", trans["pack_hackerdeck"]},
	}
	for c in cmds {
		fmt.printfln(" %s%-28s %s- %s", Colors.gray, c[0], Colors.reset, c[1])
	}
}
