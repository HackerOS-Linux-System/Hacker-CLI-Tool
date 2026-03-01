package hackeros

import "core:fmt"
import "core:os"
import "core:strings"

handle_unpack :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 || args[0] == "help" {
		show_unpack_help(lang)
		os.exit(0)
	}
	sub := args[0]
	rest := args[1:]
	switch sub {
		case "install":
			fmt.printfln("%s%s HackerLand...%s", Colors.yellow, trans["unpack_downloading"], Colors.reset)
			safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/HackerLand/main/install.hl -o /tmp/install.hl")
			safe_run("hl run /tmp/install.hl")
			safe_run("rm -f /tmp/install.hl")
			fmt.printfln("%s%s%s", Colors.green, trans["unpack_done"], Colors.reset)
		case "add-ons":
			safe_run("sudo apt install -y wine winetricks")
			safe_run("flatpak install -y --noninteractive flathub io.github.dvlv.boxbuddyrs")
			safe_run("flatpak install -y --noninteractive flathub it.mijorus.winezgui")
			safe_run("flatpak install -y --noninteractive flathub it.mijorus.gearlever")
		case "gs":
			handle_unpack([]string{"gaming"}, lang)
			handle_unpack([]string{"cybersecurity"}, lang)
		case "devtools":
			safe_run("flatpak install -y --noninteractive flathub io.atom.Atom")
			safe_run("sudo apt install -y crystal shards")
			safe_run("sudo apt install -y npm nodejs")
			safe_run("flatpak install -y --noninteractive flathub com.visualstudio.code")
			safe_run("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y")
			safe_run("sudo apt install -y golang-go")
			safe_run("sudo apt install -y lua5.4")
			safe_run("sudo snap install zig --beta --classic")
		case "emulators":
			safe_run("flatpak install -y --noninteractive flathub org.shadps4.shadPS4")
			safe_run("flatpak install -y --noninteractive flathub io.ryujinx.Ryujinx")
			safe_run("flatpak install -y --noninteractive flathub com.dosbox_x.DOSBox-X")
			safe_run("sudo snap install rpcs3-emu")
		case "cybersecurity":
			safe_run("distrobox create --name blackarch --image docker.io/blackarchlinux/blackarch:latest --additional-flags \"--privileged\" || true")
			fmt.printfln("%s%s%s", Colors.yellow, trans["unpack_blackarch_info1"], Colors.reset)
			fmt.printfln("%s%s%s", Colors.yellow, trans["unpack_blackarch_info2"], Colors.reset)
		case "select":
			safe_run("~/.hackeros/hacker/hacker-select")
		case "gaming":
			safe_run("flatpak install -y --noninteractive flathub com.valvesoftware.Steam")
			safe_run("flatpak install -y --noninteractive flathub com.github.Matoking.protontricks")
			safe_run("flatpak install -y --noninteractive flathub com.heroicgameslauncher.hgl")
			safe_run("flatpak install -y --noninteractive flathub com.vysp3r.ProtonPlus")
			safe_run("flatpak install -y --noninteractive flathub io.github.giantpinkrobots.varia")
			if len(rest) > 0 && strings.to_lower(rest[0]) == "with-roblox" {
				safe_run("flatpak install -y --noninteractive flathub org.vinegarhq.Sober")
				safe_run("flatpak install -y --noninteractive flathub org.vinegarhq.Vinegar")
				fmt.printfln("%s%s%s", Colors.green, trans["unpack_roblox_done"], Colors.reset)
			}
		case "hacker-mode":
			safe_run("git clone https://github.com/HackerOS-Linux-System/Hacker-Mode.git /tmp/Hacker-Mode || true")
			safe_run("hl run /tmp/Hacker-Mode/unpack.hl")
			safe_run("rm -rf /tmp/Hacker-Mode")
		case "gamescope-session-steam":
			safe_run("flatpak install -y --noninteractive flathub com.valvesoftware.Steam")
			safe_run("flatpak install -y --noninteractive flathub org.freedesktop.Platform.VulkanLayer.gamescope")
			safe_run("git clone https://github.com/HackerOS-Linux-System/gamescope-session-steam.git /tmp/gamescope-session-steam || true")
			safe_run("hl run /tmp/gamescope-session-steam/unpack.hl")
			safe_run("rm -rf /tmp/gamescope-session-steam")
		case "xanmod":
			safe_run("/usr/share/HackerOS/Scripts/Bin/unpack-xanmod.sh")
		case "liquorix":
			safe_run("/usr/share/HackerOS/Scripts/Bin/unpack-liquorix.sh")
		case "automatic-updates":
			safe_run("sudo cp /usr/share/HackerOS/Archived/Services/hup.service /etc/systemd/system/hup.service")
			safe_run("sudo systemctl daemon-reload")
			safe_run("sudo systemctl enable --now hup.service")
		case "alacritty-config":
			safe_run("mkdir -p ~/.config/alacritty")
			safe_run("cp /usr/share/HackerOS/Archived/alacritty.toml ~/.config/alacritty/alacritty.toml")
			fmt.printfln("%s%s%s", Colors.green, trans["unpack_alacritty_done"], Colors.reset)
		case "hackeros-tv":
			safe_run("git clone https://github.com/HackerOS-Linux-System/HackerOS-TV.git /tmp/HackerOS-TV || true")
			safe_run("hl run /tmp/HackerOS-TV/unpack.hl")
			safe_run("rm -rf /tmp/HackerOS-TV")
		case "security-mode":
			safe_run("git clone https://github.com/HackerOS-Linux-System/Security-Mode.git /tmp/Security-Mode || true")
			safe_run("hl run /tmp/Security-Mode/unpack.hl")
			safe_run("rm -rf /tmp/Security-Mode")
		case "winboat":
			safe_run("wget https://github.com/TibixDev/winboat/releases/download/v0.9.0/winboat-0.9.0-amd64.deb -O /tmp/winboat.deb")
			safe_run("sudo apt install -y /tmp/winboat.deb")
			safe_run("rm -f /tmp/winboat.deb")
		case "nvidia-drivers":
			safe_run("/usr/share/HackerOS/Scripts/Bin/unpack-nvidia-drivers.sh")
		case "hl-utils":
			safe_run("wget https://github.com/Bytes-Repository/Bytes-CLI-Tool/releases/download/v0.7/bytes -O /tmp/bytes")
			safe_run("sudo mv /tmp/bytes /usr/bin/bytes")
			safe_run("sudo chmod +x /usr/bin/bytes")
			safe_run("wget https://github.com/HackerOS-Linux-System/Hacker-Lang/releases/download/v1.6.3/hli -O /tmp/hli")
			safe_run("sudo mv /tmp/hli /usr/bin/hli")
			safe_run("sudo chmod +x /usr/bin/hli")
			safe_run("wget https://github.com/virus-repo/Virus-CLI-Tool/releases/download/v0.1/virus -O /tmp/virus")
			safe_run("sudo mv /tmp/virus /usr/bin/virus")
			safe_run("sudo chmod +x /usr/bin/virus")
		case "flox":
			safe_run("wget https://downloads.flox.dev/by-env/stable/deb/flox.x86_64-linux.deb -O /tmp/flox.deb")
			safe_run("sudo apt install -y /tmp/flox.deb")
			safe_run("rm -f /tmp/flox.deb")
		case "hackeros-builder":
			safe_run("wget https://raw.githubusercontent.com/HackerOS-Linux-System/HackerOS-Builder/main/install.hl -O /tmp/install-builder.hl")
			safe_run("hl run /tmp/install-builder.hl")
			safe_run("rm -f /tmp/install-builder.hl")
		case "isolator":
			safe_run("wget https://raw.githubusercontent.com/HackerOS-Linux-System/Isolator/main/install.hl -O /tmp/install-isolator.hl")
			safe_run("hl run /tmp/install-isolator.hl")
			safe_run("rm -f /tmp/install-isolator.hl")
		case "hydra":
			fmt.printfln("%s%s hydra-look-and-feel...%s", Colors.yellow, trans["unpack_downloading"], Colors.reset)
			safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/hydra-look-and-feel/main/unpack.hl -o /tmp/unpack.hl")
			safe_run("hl run /tmp/unpack.hl")
			fmt.printfln("%s%s%s", Colors.yellow, trans["unpack_hydra_warning"], Colors.reset)
			fmt.printfln("%s%s%s", Colors.green, trans["unpack_done"], Colors.reset)
		case "hammer":
			fmt.printfln("%s%s hammer...%s", Colors.yellow, trans["unpack_downloading"], Colors.reset)
			safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/hammer/main/install.hl -o /tmp/install.hl")
			safe_run("hl run /tmp/install.hl")
			safe_run("rm -f /tmp/install.hl")
			fmt.printfln("%s%s%s", Colors.green, trans["unpack_done"], Colors.reset)
		case "hackerland":
			fmt.printfln("%s%s HackerLand...%s", Colors.yellow, trans["unpack_downloading"], Colors.reset)
			safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/HackerLand/main/install.hl -o /tmp/install.hl")
			safe_run("hl run /tmp/install.hl")
			safe_run("rm -f /tmp/install.hl")
			fmt.printfln("%s%s%s", Colors.green, trans["unpack_done"], Colors.reset)
		case "H#":
			fmt.printfln("%s%s H#...%s", Colors.yellow, trans["unpack_downloading"], Colors.reset)
			safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/H-Sharp/main/install.hl -o /tmp/install.hl")
			safe_run("hl run /tmp/install.hl")
			safe_run("rm -f /tmp/install.hl")
			fmt.printfln("%s%s%s", Colors.green, trans["unpack_done"], Colors.reset)
		case "hackeros-games-addons":
			fmt.printfln("%sPobieranie i instalacja hackeros-games-addons...%s", Colors.yellow, trans["unpack_downloading"], Colors.reset)
			safe_run("curl -L https://github.com/HackerOS-Linux-System/HackerOS-Games/raw/main/addons.hl -o /tmp/addons.hl")
			safe_run("hl run /tmp/addons.hl")
			safe_run("rm -f /tmp/addons.hl")
			fmt.printfln("%sDodatki do gier HackerOS zainstalowane pomyślnie.%s", Colors.green, trans["unpack_done"], Colors.reset)
		case:
			fmt.printfln("%s%s %s%s", Colors.red, trans["unpack_unknown"], sub, Colors.reset)
			show_unpack_help(lang)
			os.exit(1)
	}
}

show_unpack_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["unpack_title"], Colors.reset)
	cmds := [][2]string{
		{"install", trans["unpack_install"]},
		{"add-ons", trans["unpack_add_ons"]},
		{"gs", trans["unpack_gs"]},
		{"devtools", trans["unpack_devtools"]},
		{"emulators", trans["unpack_emulators"]},
		{"cybersecurity", trans["unpack_cybersecurity"]},
		{"select", trans["unpack_select"]},
		{"gaming", trans["unpack_gaming"]},
		{"gaming with-roblox", trans["unpack_gaming_roblox"]},
		{"hacker-mode", trans["unpack_hacker_mode"]},
		{"gamescope-session-steam", trans["unpack_gamescope"]},
		{"xanmod", trans["unpack_xanmod"]},
		{"liquorix", trans["unpack_liquorix"]},
		{"automatic-updates", trans["unpack_auto_updates"]},
		{"alacritty-config", trans["unpack_alacritty"]},
		{"hackeros-tv", trans["unpack_hackeros_tv"]},
		{"security-mode", trans["unpack_security_mode"]},
		{"winboat", trans["unpack_winboat"]},
		{"nvidia-drivers", trans["unpack_nvidia"]},
		{"hl-utils", trans["unpack_hl_utils"]},
		{"flox", trans["unpack_flox"]},
		{"hackeros-builder", trans["unpack_builder"]},
		{"isolator", trans["unpack_isolator"]},
		{"hydra", trans["unpack_hydra"]},
		{"hammer", trans["unpack_hammer"]},
		{"hackerland", trans["unpack_hackerland"]},
		{"H#", trans["unpack_hsharp"]},
		{"hackeros-games-addons", "Zainstaluj dodatki do gier HackerOS (addons.hl)"},
	}
	for c in cmds {
		fmt.printfln(" %s%-28s %s- %s", Colors.gray, c[0], Colors.reset, c[1])
	}
}
