package main

import (
	"fmt"
	"os"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/viewport"
	"github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type Command struct {
	Name        string
	Description string
	Details     string
}

var commands = []Command{
	// ====================== UNPACK SUBCOMMANDS ======================
	{
		Name:        "hacker unpack add-ons",
		Description: "Install Wine, BoxBuddy, Winezgui, Gearlever",
		Details:     "Installs Wine for running Windows applications, BoxBuddy for Flatpak management, Winezgui for a Wine GUI, and Gearlever for additional utilities.",
	},
	{
		Name:        "hacker unpack gs",
		Description: "Install gaming and cybersecurity tools",
		Details:     "Installs both gaming (Steam, Lutris, etc.) and cybersecurity tools (BlackArch container).",
	},
	{
		Name:        "hacker unpack devtools",
		Description: "Install development tools",
		Details:     "Installs Visual Studio Code (Flatpak), Crystal, Shards, Node.js, npm, Rust, Go, Lua, and Zig.",
	},
	{
		Name:        "hacker unpack emulators",
		Description: "Install PlayStation, Nintendo, DOSBox, PS3 emulators",
		Details:     "Installs shadPS4, Ryujinx, DOSBox-X, and RPCS3 via Flatpak and Snap.",
	},
	{
		Name:        "hacker unpack cybersecurity",
		Description: "Set up BlackArch container",
		Details:     "Creates a distrobox container named 'blackarch' with the latest BlackArch image and adds multilib support.",
	},
	{
		Name:        "hacker unpack select",
		Description: "Interactive package selection with TUI",
		Details:     "Runs hacker-select to interactively choose categories or individual applications to install.",
	},
	{
		Name:        "hacker unpack gaming",
		Description: "Install gaming tools (Steam, Heroic, ProtonPlus, etc.)",
		Details:     "Installs Steam, Protontricks, Heroic Games Launcher, ProtonPlus, Varia, and optionally Roblox support.",
	},
	{
		Name:        "hacker unpack gaming with-roblox",
		Description: "Install gaming tools with Roblox support",
		Details:     "Same as 'gaming' but also installs Sober and Vinegar Flatpaks for Roblox.",
	},
	{
		Name:        "hacker unpack hacker-mode",
		Description: "Install Hacker Mode (gamescope session)",
		Details:     "Clones the Hacker-Mode repository and runs the unpack script to set up a custom gaming session.",
	},
	{
		Name:        "hacker unpack gamescope-session-steam",
		Description: "Install gamescope session for Steam",
		Details:     "Installs Steam Flatpak, gamescope Vulkan layer, and sets up the gamescope-session-steam environment.",
	},
	{
		Name:        "hacker unpack automatic-updates",
		Description: "Enable automatic updates via hup service",
		Details:     "Copies the hup.service file and enables it to run automatic updates.",
	},
	{
		Name:        "hacker unpack alacritty-config",
		Description: "Install Alacritty configuration",
		Details:     "Copies the HackerOS Alacritty configuration to ~/.config/alacritty/alacritty.toml.",
	},
	{
		Name:        "hacker unpack hackeros-tv",
		Description: "Install HackerOS TV",
		Details:     "Clones the HackerOS-TV repository and runs its unpack script.",
	},
	{
		Name:        "hacker unpack winboat",
		Description: "Install Winboat (Windows compatibility tool)",
		Details:     "Downloads and installs the Winboat .deb package.",
	},
	{
		Name:        "hacker unpack nvidia-drivers",
		Description: "Install NVIDIA drivers",
		Details:     "Runs the unpack-nvidia-drivers.sh script to install proprietary NVIDIA drivers.",
	},
	{
		Name:        "hacker unpack hl-utils",
		Description: "Install Hacker Lang utilities",
		Details:     "Downloads and runs the install-utils.hl script from the Hacker-Lang repository.",
	},
	{
		Name:        "hacker unpack flox",
		Description: "Install Flox (environment manager)",
		Details:     "Downloads and installs the Flox .deb package.",
	},
	{
		Name:        "hacker unpack hackeros-builder",
		Description: "Install HackerOS Builder",
		Details:     "Downloads and runs the install.hl script from the HackerOS-Builder repository.",
	},
	{
		Name:        "hacker unpack isolator",
		Description: "Install Isolator (package manager)",
		Details:     "Downloads and runs the install.hl script from the Isolator repository.",
	},
	{
		Name:        "hacker unpack hydra",
		Description: "Install Hydra look-and-feel",
		Details:     "Downloads and runs the unpack.hl script from the hydra-look-and-feel repository.",
	},
	{
		Name:        "hacker unpack hammer",
		Description: "Install Hammer (package manager)",
		Details:     "Downloads and runs the install.hl script from the hammer repository.",
	},
	{
		Name:        "hacker unpack hackeros-games-addons",
		Description: "Install HackerOS game add-ons",
		Details:     "Downloads and runs the addons.hl script from the HackerOS-Games repository.",
	},
	{
		Name:        "hacker unpack lpm",
		Description: "Install LPM (package manager)",
		Details:     "Downloads and runs the install.hl script from the lpm repository.",
	},
	{
		Name:        "hacker unpack HackerScript",
		Description: "Install HackerScript",
		Details:     "Downloads and runs the install.hl script from the HackerScript repository.",
	},
	{
		Name:        "hacker unpack hexai",
		Description: "Install HexAi (AI tool)",
		Details:     "Downloads and runs the install.hl script from the HexAi repository.",
	},
	{
		Name:        "hacker unpack hackerscript-utils",
		Description: "Install HackerScript utilities",
		Details:     "Downloads and runs the install-utils.hl script from the HackerScript repository.",
	},
	{
		Name:        "hacker unpack hackerdeck",
		Description: "Install HackerDeck (Waydroid overlay)",
		Details:     "Downloads and runs the install.hl script from the HackerDeck repository.",
	},

	// ====================== PACK SUBCOMMANDS ======================
	{
		Name:        "hacker pack add-ons",
		Description: "Remove Wine and related tools",
		Details:     "Uninstalls Wine, BoxBuddy, Winezgui, and Gearlever.",
	},
	{
		Name:        "hacker pack gs",
		Description: "Remove gaming and cybersecurity tools",
		Details:     "Removes both gaming and cybersecurity packages.",
	},
	{
		Name:        "hacker pack devtools",
		Description: "Remove development tools",
		Details:     "Uninstalls Visual Studio Code, Crystal, Node.js, Rust, Go, Lua, and Zig.",
	},
	{
		Name:        "hacker pack emulators",
		Description: "Remove emulators",
		Details:     "Uninstalls shadPS4, Ryujinx, DOSBox-X, and RPCS3.",
	},
	{
		Name:        "hacker pack cybersecurity",
		Description: "Remove BlackArch container",
		Details:     "Removes the 'blackarch' distrobox container.",
	},
	{
		Name:        "hacker pack select",
		Description: "Run hacker-select in pack mode",
		Details:     "Runs hacker-select with the --pack flag to interactively select items to remove.",
	},
	{
		Name:        "hacker pack gaming",
		Description: "Remove gaming tools",
		Details:     "Uninstalls Steam, Protontricks, Heroic Games Launcher, ProtonPlus, Varia, and Roblox support.",
	},
	{
		Name:        "hacker pack hacker-mode",
		Description: "Remove Hacker Mode",
		Details:     "Clones the Hacker-Mode repository and runs the remove script.",
	},
	{
		Name:        "hacker pack gamescope-session-steam",
		Description: "Remove gamescope session for Steam",
		Details:     "Uninstalls Steam Flatpak, gamescope Vulkan layer, and removes the gamescope-session-steam files.",
	},
	{
		Name:        "hacker pack automatic-updates",
		Description: "Disable automatic updates",
		Details:     "Disables and removes the hup service.",
	},
	{
		Name:        "hacker pack alacritty-config",
		Description: "Remove Alacritty configuration",
		Details:     "Removes the Alacritty configuration file from ~/.config/alacritty/.",
	},
	{
		Name:        "hacker pack hackeros-tv",
		Description: "Remove HackerOS TV",
		Details:     "Clones the HackerOS-TV repository and runs the remove script.",
	},
	{
		Name:        "hacker pack winboat",
		Description: "Remove Winboat",
		Details:     "Uninstalls the Winboat package.",
	},
	{
		Name:        "hacker pack nvidia-drivers",
		Description: "Remove NVIDIA drivers",
		Details:     "Runs the remove-nvidia-drivers.sh script.",
	},
	{
		Name:        "hacker pack hl-utils",
		Description: "Remove Hacker Lang utilities",
		Details:     "Downloads and runs the remove-utils.hl script from the Hacker-Lang repository.",
	},
	{
		Name:        "hacker pack flox",
		Description: "Remove Flox",
		Details:     "Uninstalls the Flox package.",
	},
	{
		Name:        "hacker pack hackeros-builder",
		Description: "Remove HackerOS Builder",
		Details:     "Removes the /usr/bin/hackeros-builder binary.",
	},
	{
		Name:        "hacker pack isolator",
		Description: "Remove Isolator",
		Details:     "Removes the /usr/bin/isolator binary.",
	},
	{
		Name:        "hacker pack hammer",
		Description: "Remove Hammer",
		Details:     "Downloads and runs the remove.hl script from the hammer repository.",
	},
	{
		Name:        "hacker pack lpm",
		Description: "Remove LPM",
		Details:     "Downloads and runs the remove.hl script from the lpm repository.",
	},
	{
		Name:        "hacker pack HackerScript",
		Description: "Remove HackerScript",
		Details:     "Downloads and runs the remove.hl script from the HackerScript repository.",
	},
	{
		Name:        "hacker pack hackeros-games-addons",
		Description: "Remove HackerOS game add-ons",
		Details:     "Downloads and runs the addons-remove.hl script from the HackerOS-Games repository.",
	},
	{
		Name:        "hacker pack hexai",
		Description: "Remove HexAi",
		Details:     "Downloads and runs the remove.hl script from the HexAi repository.",
	},
	{
		Name:        "hacker pack hackerscript-utils",
		Description: "Remove HackerScript utilities",
		Details:     "Downloads and runs the remove-utils.hl script from the HackerScript repository.",
	},
	{
		Name:        "hacker pack hackerdeck",
		Description: "Remove HackerDeck",
		Details:     "Downloads and runs the remove.hl script from the HackerDeck repository.",
	},

	// ====================== ENV SUBCOMMANDS ======================
	{
		Name:        "hacker env create <file.hk|file.yaml>",
		Description: "Create a new environment from a config file",
		Details:     "Creates a podman container with the specified configuration (name, image, packages, etc.).",
	},
	{
		Name:        "hacker env remove <name>",
		Description: "Remove an environment",
		Details:     "Stops and removes the specified podman container.",
	},
	{
		Name:        "hacker env enter [name]",
		Description: "Enter an environment",
		Details:     "Starts and enters the specified container (or lists all if no name given).",
	},
	{
		Name:        "hacker env docs",
		Description: "Show full tutorial and examples",
		Details:     "Displays a detailed tutorial on how to use 'hacker env' with configuration examples.",
	},
	{
		Name:        "hacker env settings",
		Description: "List all environments",
		Details:     "Shows a table of all containers labeled 'hacker-env=true'.",
	},

	// ====================== RUN SUBCOMMANDS ======================
	{
		Name:        "hacker run update-system",
		Description: "Update the system",
		Details:     "Runs the system update script (update-system.sh).",
	},
	{
		Name:        "hacker run check-updates",
		Description: "Check for system updates",
		Details:     "Runs the check_updates_notify.sh script.",
	},
	{
		Name:        "hacker run steam",
		Description: "Launch Steam via HackerOS script",
		Details:     "Runs HackerOS-Steam.sh to launch Steam with optimizations.",
	},
	{
		Name:        "hacker run hacker-launcher",
		Description: "Launch HackerOS Launcher",
		Details:     "Runs the Hacker_Launcher.AppImage.",
	},
	{
		Name:        "hacker run hackeros-game-mode",
		Description: "Run HackerOS Game Mode",
		Details:     "Launches the HackerOS-Game-Mode.AppImage.",
	},
	{
		Name:        "hacker run update-hackeros",
		Description: "Update HackerOS",
		Details:     "Runs the update-hackeros.sh script.",
	},
	{
		Name:        "hacker run update-wallpapers",
		Description: "Update wallpapers",
		Details:     "Runs the update-wallpapers.sh script.",
	},
	{
		Name:        "hacker run remove-debian-kernel",
		Description: "Remove Debian kernel",
		Details:     "Runs the remove-debian-kernel.sh script to remove the default Debian kernel.",
	},
	{
		Name:        "hacker run HackerOS-Store",
		Description: "Open HackerOS Store",
		Details:     "Runs the HackerOS-Store binary.",
	},
	{
		Name:        "hacker run HackerOS-Steam",
		Description: "Launch HackerOS Steam",
		Details:     "Runs 'HackerOS-Steam run' to launch Steam with the HackerOS container.",
	},
	{
		Name:        "hacker run HackerDeck",
		Description: "Launch HackerDeck",
		Details:     "Runs the HackerDeck binary.",
	},
	{
		Name:        "hacker run Hacker-Term",
		Description: "Launch Hacker-Term",
		Details:     "Runs the Hacker-Term.AppImage.",
	},
	{
		Name:        "hacker run build-hackeros",
		Description: "Build HackerOS (live build)",
		Details:     "Runs the build-hackeros script from the Archived directory.",
	},

	// ====================== PLUGIN SUBCOMMANDS ======================
	{
		Name:        "hacker plugin list",
		Description: "List available plugins",
		Details:     "Displays all plugins found in ~/.config/hackeros/hacker/plugins/ with their status.",
	},
	{
		Name:        "hacker plugin enable <name>",
		Description: "Enable a plugin",
		Details:     "Sets the 'enabled' flag to true in the plugin's .hacker file.",
	},
	{
		Name:        "hacker plugin disable <name>",
		Description: "Disable a plugin",
		Details:     "Sets the 'enabled' flag to false in the plugin's .hacker file.",
	},

	// ====================== ENABLE/DISABLE SUBCOMMANDS ======================
	{
		Name:        "hacker enable motd",
		Description: "Enable standard Message of the Day",
		Details:     "Copies hackeros-motd to /usr/libexec/ and sets executable permissions.",
	},
	{
		Name:        "hacker enable special-motd",
		Description: "Enable special Message of the Day",
		Details:     "Copies hackeros-special-motd to /usr/libexec/hackeros-motd and makes it executable.",
	},
	{
		Name:        "hacker disable motd",
		Description: "Disable standard Message of the Day",
		Details:     "Removes /usr/libexec/hackeros-motd.",
	},
	{
		Name:        "hacker disable special-motd",
		Description: "Disable special Message of the Day",
		Details:     "Removes /usr/libexec/hackeros-motd (same as above).",
	},

	// ====================== SWITCH SUBCOMMANDS ======================
	{
		Name:        "hacker switch hacker-mode",
		Description: "Switch to Hacker-Mode (Wayland session)",
		Details:     "Detects current DE, kills it, and starts the Hacker-Mode session (requires Wayland and gamescope).",
	},
	{
		Name:        "hacker switch steam-gamemode",
		Description: "Switch to Steam Game Mode",
		Details:     "Switches to the gamescope-session-steam environment for a console-like gaming experience.",
	},

	// ====================== SYSTEM SUBCOMMAND ======================
	{
		Name:        "hacker system logs",
		Description: "Show system logs",
		Details:     "Runs 'journalctl -xe' to display recent system logs.",
	},

	// ====================== SETTINGS SUBCOMMAND ======================
	{
		Name:        "hacker settings language [lang]",
		Description: "Set or display language",
		Details:     "Without argument, shows current language. With argument, sets language (pl, en, de, fr, es, it, ru, zh, ja, ko, pt, ar, hi).",
	},

	// ====================== TOP-LEVEL COMMANDS ======================
	{
		Name:        "hacker help",
		Description: "Show this help",
		Details:     "Displays this interactive help UI.",
	},
	{
		Name:        "hacker help-ui",
		Description: "Show help UI",
		Details:     "Same as 'hacker help'.",
	},
	{
		Name:        "hacker docs",
		Description: "Show documentation and FAQ",
		Details:     "Opens an interactive UI with frequently asked questions and answers.",
	},
	{
		Name:        "hacker install <package>",
		Description: "Install a package using apt-fronted",
		Details:     "Redirects to apt-fronted install <package>.",
	},
	{
		Name:        "hacker remove <package>",
		Description: "Remove a package using apt-fronted",
		Details:     "Redirects to apt-fronted remove <package>.",
	},
	{
		Name:        "hacker flatpak-install <package>",
		Description: "Install a Flatpak package",
		Details:     "Runs 'flatpak install -y <package>'.",
	},
	{
		Name:        "hacker flatpak-remove <package>",
		Description: "Remove a Flatpak package",
		Details:     "Runs 'flatpak remove -y <package>'.",
	},
	{
		Name:        "hacker update",
		Description: "Run HackerOS updater",
		Details:     "Runs the HackerOS-Updater script. Optionally use --with-gui for a graphical interface.",
	},
	{
		Name:        "hacker update --with-gui",
		Description: "Run HackerOS updater with GUI",
		Details:     "Runs the update-system script which may open a GUI.",
	},
	{
		Name:        "hacker game",
		Description: "Play a text-based adventure game",
		Details:     "Starts an interactive hacker-themed adventure game in the terminal.",
	},
	{
		Name:        "hacker hacker-lang",
		Description: "Information about Hacker programming language",
		Details:     "Displays info about using .hacker files and the 'hl'/'bytes' tools.",
	},
	{
		Name:        "hacker ascii",
		Description: "Display HackerOS ASCII art",
		Details:     "Shows the HackerOS ASCII logo from /usr/share/HackerOS/Config-Files/HackerOS-Ascii.",
	},
	{
		Name:        "hacker shell",
		Description: "Run the Hacker shell",
		Details:     "Activates the HackerOS virtual environment and runs the hacker-shell script.",
	},
	{
		Name:        "hacker enter <container>",
		Description: "Enter a Distrobox container",
		Details:     "Runs 'distrobox enter <container>'.",
	},
	{
		Name:        "hacker remove-container <container>",
		Description: "Remove a Distrobox container",
		Details:     "Runs 'distrobox rm <container>' after confirmation.",
	},
	{
		Name:        "hacker restart <service>",
		Description: "Restart a system service",
		Details:     "Runs 'sudo systemctl restart <service>'.",
	},
	{
		Name:        "hacker how-to-create-commands",
		Description: "Show how to create custom commands",
		Details:     "Displays instructions for creating custom .hacker commands in ~/.config/hackeros/hacker/custom-commands/.",
	},
	{
		Name:        "hacker index",
		Description: "Show index of all HackerOS tools",
		Details:     "Lists all available HackerOS tools with brief descriptions.",
	},
	{
		Name:        "hacker info",
		Description: "Show tool and OS versions",
		Details:     "Displays the latest version of the hacker tool and HackerOS.",
	},
	{
		Name:        "hacker --version",
		Description: "Show hacker tool version",
		Details:     "Displays the current version of the hacker CLI tool.",
	},
	{
		Name:        "hacker --hackeros",
		Description: "Show HackerOS version",
		Details:     "Displays the version of HackerOS.",
	},
	{
		Name:        "hacker --edition",
		Description: "Show HackerOS edition",
		Details:     "Reads the 'Variant' line from /etc/xdg/kcm-about-distrorc and displays it.",
	},
	{
		Name:        "hacker issue",
		Description: "Open new issue on GitHub",
		Details:     "Opens the HackerOS GitHub issue page in the default browser (prefers Vivaldi).",
	},
	{
		Name:        "hacker repair",
		Description: "Repair HackerOS system",
		Details:     "Runs the hacker-repair script from ~/.hackeros/hacker/.",
	},
	{
		Name:        "hacker settings",
		Description: "Show settings help",
		Details:     "Displays available settings subcommands (e.g., 'language').",
	},
	{
		Name:        "hacker switch",
		Description: "Show switch help",
		Details:     "Displays available switch subcommands (hacker-mode, steam-gamemode).",
	},
}

type item struct {
	cmd Command
}

func (i item) Title() string       { return i.cmd.Name }
func (i item) Description() string { return i.cmd.Description }
func (i item) FilterValue() string { return i.cmd.Name + " " + i.cmd.Description }

type mode int

const (
	listMode mode = iota
	detailsMode
)

type keyMap struct {
	quit key.Binding
}

func newKeyMap() *keyMap {
	return &keyMap{
		quit: key.NewBinding(
			key.WithKeys("q", "ctrl+c"),
			key.WithHelp("q", "quit"),
		),
	}
}

type model struct {
	list     list.Model
	viewport viewport.Model
	keys     *keyMap
	ready    bool
	mode     mode
	selected int
}

func newModel() model {
	var items []list.Item
	// Add Exit item first
	items = append(items, item{Command{Name: "Exit", Description: "Press to exit"}})
	for _, c := range commands {
		items = append(items, item{c})
	}
	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.Foreground(lipgloss.Color("#FF75CB")).Bold(true)
	l := list.New(items, delegate, 0, 0)
	l.Title = "HackerOS Commands"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#FA8072")).Padding(0, 1)
	l.SetShowHelp(true)

	vp := viewport.New(0, 0)
	vp.Style = lipgloss.NewStyle().Border(lipgloss.NormalBorder(), true).Padding(1)

	return model{
		list:     l,
		viewport: vp,
		keys:     newKeyMap(),
	}
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.list.SetWidth(msg.Width/2 - 1)
		m.list.SetHeight(msg.Height - 2)
		m.viewport.Width = msg.Width/2 - 4
		m.viewport.Height = msg.Height - 4
		if !m.ready {
			m.ready = true
		}
		return m, nil
	case tea.KeyMsg:
		if key.Matches(msg, m.keys.quit) {
			return m, tea.Quit
		}
		switch msg.String() {
		case "enter":
			if m.mode == listMode {
				idx := m.list.Index()
				if idx == 0 { // Exit item
					return m, tea.Quit
				}
				m.selected = idx - 1
				m.viewport.SetContent(commands[m.selected].Details)
				m.viewport.GotoTop()
				m.mode = detailsMode
				return m, nil
			}
		case "esc":
			if m.mode == detailsMode {
				m.mode = listMode
				return m, nil
			}
		}
	}
	if m.mode == listMode {
		m.list, cmd = m.list.Update(msg)
	} else {
		m.viewport, cmd = m.viewport.Update(msg)
	}
	return m, cmd
}

func (m model) View() string {
	if !m.ready {
		return "Initializing..."
	}
	left := lipgloss.NewStyle().
		Width(m.list.Width() + 2).
		Border(lipgloss.NormalBorder(), false, true, false, false).
		Render(m.list.View())
	rightContent := "Select a command from the list to view details.\n\nPress 'enter' to select, 'esc' to go back, 'q' to quit."
	if m.mode == detailsMode {
		rightContent = m.viewport.View()
	}
	right := lipgloss.NewStyle().
		Width(m.viewport.Width + 4).
		Height(m.list.Height() + 2).
		Border(lipgloss.NormalBorder(), true).
		Padding(1).
		Render(rightContent)
	return lipgloss.JoinHorizontal(lipgloss.Top, left, right)
}

func main() {
	p := tea.NewProgram(newModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
}
