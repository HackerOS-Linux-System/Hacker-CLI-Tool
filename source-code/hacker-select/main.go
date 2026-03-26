package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type itemType string

const (
	header   itemType = "header"
	category itemType = "category"
	app      itemType = "app"
)

type item struct {
	typ      itemType
	title    string
	desc     string
	value    string
	selected bool
}

func (i item) Title() string       { return i.title }
func (i item) Description() string { return i.desc }
func (i item) FilterValue() string { return i.title + " " + i.desc }

type keyMap struct {
	quit   key.Binding
	toggle key.Binding
}

func newKeyMap() *keyMap {
	return &keyMap{
		quit: key.NewBinding(
			key.WithKeys("q", "ctrl+c"),
				     key.WithHelp("q", "quit"),
		),
		toggle: key.NewBinding(
			key.WithKeys(" "),
				       key.WithHelp("space", "toggle select"),
		),
	}
}

type model struct {
	list  list.Model
	keys  *keyMap
	ready bool
	mode  string // "unpack", "pack", "cyber"
}

func newModel(items []list.Item, mode string) model {
	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.Foreground(lipgloss.Color("#FF75CB")).Bold(true)

	l := list.New(items, delegate, 0, 0)
	l.Title = "Select items (space to toggle, enter to confirm)"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#FA8072")).Padding(0, 1)
	l.SetShowHelp(true)

	del := &customDelegate{DefaultDelegate: delegate}
	l.SetDelegate(del)

	return model{
		list:  l,
		keys:  newKeyMap(),
		mode:  mode,
	}
}

type customDelegate struct {
	list.DefaultDelegate
}

func (d customDelegate) Render(w io.Writer, m list.Model, index int, listItem list.Item) {
	i, ok := listItem.(item)
	if !ok {
		return
	}
	if i.typ == header {
		fmt.Fprint(w, lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#00FF00")).Render(i.title))
		return
	}
	checkbox := "[ ] "
	if i.selected {
		checkbox = "[x] "
	}
	str := checkbox + i.title
	if i.desc != "" {
		str += "\n  " + lipgloss.NewStyle().Foreground(lipgloss.Color("#AAAAAA")).Render(i.desc)
	}
	fn := d.Styles.NormalTitle.Render
	if index == m.Index() {
		fn = func(s ...string) string {
			return d.Styles.SelectedTitle.Render(s...)
		}
	}
	fmt.Fprint(w, fn(str))
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
		case tea.WindowSizeMsg:
			m.list.SetWidth(msg.Width)
			m.list.SetHeight(msg.Height - 2)
			if !m.ready {
				m.ready = true
			}
			return m, nil
		case tea.KeyMsg:
			if key.Matches(msg, m.keys.quit) {
				return m, tea.Quit
			}
			if key.Matches(msg, m.keys.toggle) {
				idx := m.list.Index()
				currItem, ok := m.list.Items()[idx].(item)
				if ok && currItem.typ != header {
					currItem.selected = !currItem.selected
					m.list.SetItem(idx, currItem)
				}
				return m, nil
			}
			if msg.String() == "enter" {
				selectedTokens := []string{}
				selectedCommands := []string{}

				for _, it := range m.list.Items() {
					i, ok := it.(item)
					if ok && i.selected {
						switch m.mode {
							case "cyber":
								selectedTokens = append(selectedTokens, i.value)
								selectedCommands = append(selectedCommands, fmt.Sprintf("hacker cyber %s", i.value))
							default:
								if i.typ == category {
									selectedTokens = append(selectedTokens, "category:"+i.value)
									selectedCommands = append(selectedCommands, fmt.Sprintf("hacker %s %s", m.mode, i.value))
								} else if i.typ == app {
									selectedTokens = append(selectedTokens, "app:"+i.value)
									selectedCommands = append(selectedCommands, fmt.Sprintf("hacker %s %s", m.mode, i.value))
								}
						}
					}
				}

				// Print tokens to stdout (for the parent hacker script)
				for _, tok := range selectedTokens {
					fmt.Println(tok)
				}

				// Print human-readable commands to stderr (visible to the user)
				if len(selectedCommands) > 0 {
					fmt.Fprintf(os.Stderr, "\nSelected items:\n")
					for _, cmd := range selectedCommands {
						fmt.Fprintf(os.Stderr, "  %s\n", cmd)
					}
					fmt.Fprintf(os.Stderr, "\n")
				} else {
					fmt.Fprintf(os.Stderr, "\nNo items selected.\n")
				}

				return m, tea.Quit
			}
	}
	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m model) View() string {
	if !m.ready {
		return "Initializing..."
	}
	return m.list.View()
}

func main() {
	var mode string
	flag.StringVar(&mode, "mode", "unpack", "Mode: unpack, pack, cyber")
	flag.Parse()

	var items []list.Item

	switch mode {
		case "unpack":
			// Categories
			items = append(items, item{typ: header, title: "Categories"})
			items = append(items, item{typ: category, title: "Add-Ons", desc: "Install Wine and related tools", value: "add-ons"})
			items = append(items, item{typ: category, title: "Gaming", desc: "Install gaming tools (Steam, Heroic, ProtonPlus, etc.)", value: "gaming"})
			items = append(items, item{typ: category, title: "Cybersecurity", desc: "Setup BlackArch container", value: "cybersecurity"})
			items = append(items, item{typ: category, title: "Devtools", desc: "Install development tools", value: "devtools"})
			items = append(items, item{typ: category, title: "Emulators", desc: "Install emulators", value: "emulators"})
			items = append(items, item{typ: category, title: "Hacker Mode", desc: "Install Hacker Mode (gamescope session)", value: "hacker-mode"})
			items = append(items, item{typ: category, title: "Gamescope Session Steam", desc: "Install gamescope session for Steam", value: "gamescope-session-steam"})
			items = append(items, item{typ: category, title: "Automatic Updates", desc: "Enable hup service", value: "automatic-updates"})
			items = append(items, item{typ: category, title: "Alacritty Config", desc: "Install Alacritty configuration", value: "alacritty-config"})
			items = append(items, item{typ: category, title: "HackerOS TV", desc: "Install HackerOS TV", value: "hackeros-tv"})
			items = append(items, item{typ: category, title: "Winboat", desc: "Install Winboat", value: "winboat"})
			items = append(items, item{typ: category, title: "NVIDIA Drivers", desc: "Install NVIDIA drivers", value: "nvidia-drivers"})
			items = append(items, item{typ: category, title: "Hacker Lang Utilities", desc: "Install hl-utils", value: "hl-utils"})
			items = append(items, item{typ: category, title: "Flox", desc: "Install Flox", value: "flox"})
			items = append(items, item{typ: category, title: "HackerOS Builder", desc: "Install HackerOS Builder", value: "hackeros-builder"})
			items = append(items, item{typ: category, title: "Isolator", desc: "Install Isolator", value: "isolator"})
			items = append(items, item{typ: category, title: "Hydra Look & Feel", desc: "Install Hydra look-and-feel", value: "hydra"})
			items = append(items, item{typ: category, title: "Hammer", desc: "Install Hammer", value: "hammer"})
			items = append(items, item{typ: category, title: "HackerOS Games Addons", desc: "Install game add-ons", value: "hackeros-games-addons"})
			items = append(items, item{typ: category, title: "LPM", desc: "Install LPM package manager", value: "lpm"})
			items = append(items, item{typ: category, title: "HackerScript", desc: "Install HackerScript", value: "HackerScript"})
			items = append(items, item{typ: category, title: "HexAi", desc: "Install HexAi AI tool", value: "hexai"})
			items = append(items, item{typ: category, title: "HackerScript Utils", desc: "Install HackerScript utilities", value: "hackerscript-utils"})
			items = append(items, item{typ: category, title: "HackerDeck", desc: "Install HackerDeck (Waydroid overlay)", value: "hackerdeck"})

			// Individual applications
			items = append(items, item{typ: header, title: "Individual Applications"})

			// Add-Ons apps
			items = append(items, item{typ: app, title: "wine", desc: "APT - Run Windows apps", value: "wine"})
			items = append(items, item{typ: app, title: "winetricks", desc: "APT - Wine utilities", value: "winetricks"})
			items = append(items, item{typ: app, title: "BoxBuddy", desc: "Flatpak - Manage Flatpaks", value: "io.github.dvlv.boxbuddyrs"})
			items = append(items, item{typ: app, title: "Winezgui", desc: "Flatpak - Wine GUI", value: "it.mijorus.winezgui"})
			items = append(items, item{typ: app, title: "Gearlever", desc: "Flatpak - Utilities", value: "it.mijorus.gearlever"})

			// Gaming apps
			items = append(items, item{typ: app, title: "Steam", desc: "Flatpak - Gaming platform", value: "com.valvesoftware.Steam"})
			items = append(items, item{typ: app, title: "Protontricks", desc: "Flatpak - Proton utilities", value: "com.github.Matoking.protontricks"})
			items = append(items, item{typ: app, title: "Heroic Games Launcher", desc: "Flatpak - Epic/GOG launcher", value: "com.heroicgameslauncher.hgl"})
			items = append(items, item{typ: app, title: "ProtonPlus", desc: "Flatpak - Proton manager", value: "com.vysp3r.ProtonPlus"})
			items = append(items, item{typ: app, title: "Varia", desc: "Flatpak - Torrent client", value: "io.github.giantpinkrobots.varia"})
			items = append(items, item{typ: app, title: "Sober (Roblox)", desc: "Flatpak - Roblox player", value: "org.vinegarhq.Sober"})
			items = append(items, item{typ: app, title: "Vinegar (Roblox)", desc: "Flatpak - Roblox helper", value: "org.vinegarhq.Vinegar"})

			// Devtools apps
			items = append(items, item{typ: app, title: "Visual Studio Code", desc: "Flatpak - Code editor", value: "com.visualstudio.code"})
			items = append(items, item{typ: app, title: "crystal", desc: "APT - Crystal language", value: "crystal"})
			items = append(items, item{typ: app, title: "shards", desc: "APT - Crystal package manager", value: "shards"})
			items = append(items, item{typ: app, title: "nodejs", desc: "APT - Node.js", value: "nodejs"})
			items = append(items, item{typ: app, title: "npm", desc: "APT - Node.js package manager", value: "npm"})
			items = append(items, item{typ: app, title: "rust", desc: "curl - Rust installer", value: "rust"})
			items = append(items, item{typ: app, title: "golang", desc: "APT - Go language", value: "golang"})
			items = append(items, item{typ: app, title: "lua5.4", desc: "APT - Lua interpreter", value: "lua5.4"})
			items = append(items, item{typ: app, title: "zig", desc: "Snap - Zig language", value: "zig"})

			// Emulators apps
			items = append(items, item{typ: app, title: "shadPS4", desc: "Flatpak - PS4 emulator", value: "org.shadps4.shadPS4"})
			items = append(items, item{typ: app, title: "Ryujinx", desc: "Flatpak - Nintendo Switch emulator", value: "io.ryujinx.Ryujinx"})
			items = append(items, item{typ: app, title: "DOSBox-X", desc: "Flatpak - DOS emulator", value: "com.dosbox_x.DOSBox-X"})
			items = append(items, item{typ: app, title: "RPCS3", desc: "Snap - PS3 emulator", value: "rpcs3-emu"})

			// Hacker Mode apps
			items = append(items, item{typ: app, title: "gamescope", desc: "APT - Gaming session manager", value: "gamescope"})

			case "pack":
				// Categories for removal
				items = append(items, item{typ: header, title: "Categories"})
				items = append(items, item{typ: category, title: "Add-Ons", desc: "Remove Wine and related tools", value: "add-ons"})
				items = append(items, item{typ: category, title: "Gaming", desc: "Remove gaming tools", value: "gaming"})
				items = append(items, item{typ: category, title: "Cybersecurity", desc: "Remove BlackArch container", value: "cybersecurity"})
				items = append(items, item{typ: category, title: "Devtools", desc: "Remove development tools", value: "devtools"})
				items = append(items, item{typ: category, title: "Emulators", desc: "Remove emulators", value: "emulators"})
				items = append(items, item{typ: category, title: "Hacker Mode", desc: "Remove Hacker Mode", value: "hacker-mode"})
				items = append(items, item{typ: category, title: "Gamescope Session Steam", desc: "Remove gamescope session", value: "gamescope-session-steam"})
				items = append(items, item{typ: category, title: "Automatic Updates", desc: "Disable hup service", value: "automatic-updates"})
				items = append(items, item{typ: category, title: "Alacritty Config", desc: "Remove Alacritty config", value: "alacritty-config"})
				items = append(items, item{typ: category, title: "HackerOS TV", desc: "Remove HackerOS TV", value: "hackeros-tv"})
				items = append(items, item{typ: category, title: "Winboat", desc: "Remove Winboat", value: "winboat"})
				items = append(items, item{typ: category, title: "NVIDIA Drivers", desc: "Remove NVIDIA drivers", value: "nvidia-drivers"})
				items = append(items, item{typ: category, title: "Hacker Lang Utilities", desc: "Remove hl-utils", value: "hl-utils"})
				items = append(items, item{typ: category, title: "Flox", desc: "Remove Flox", value: "flox"})
				items = append(items, item{typ: category, title: "HackerOS Builder", desc: "Remove HackerOS Builder", value: "hackeros-builder"})
				items = append(items, item{typ: category, title: "Isolator", desc: "Remove Isolator", value: "isolator"})
				items = append(items, item{typ: category, title: "Hammer", desc: "Remove Hammer", value: "hammer"})
				items = append(items, item{typ: category, title: "HackerOS Games Addons", desc: "Remove game add-ons", value: "hackeros-games-addons"})
				items = append(items, item{typ: category, title: "LPM", desc: "Remove LPM", value: "lpm"})
				items = append(items, item{typ: category, title: "HackerScript", desc: "Remove HackerScript", value: "HackerScript"})
				items = append(items, item{typ: category, title: "HexAi", desc: "Remove HexAi", value: "hexai"})
				items = append(items, item{typ: category, title: "HackerScript Utils", desc: "Remove HackerScript utilities", value: "hackerscript-utils"})
				items = append(items, item{typ: category, title: "HackerDeck", desc: "Remove HackerDeck", value: "hackerdeck"})

				// Individual apps (same as unpack but for removal)
				items = append(items, item{typ: header, title: "Individual Applications"})
				items = append(items, item{typ: app, title: "wine", desc: "Remove wine", value: "wine"})
				items = append(items, item{typ: app, title: "winetricks", desc: "Remove winetricks", value: "winetricks"})
				items = append(items, item{typ: app, title: "BoxBuddy", desc: "Remove BoxBuddy", value: "io.github.dvlv.boxbuddyrs"})
				items = append(items, item{typ: app, title: "Winezgui", desc: "Remove Winezgui", value: "it.mijorus.winezgui"})
				items = append(items, item{typ: app, title: "Gearlever", desc: "Remove Gearlever", value: "it.mijorus.gearlever"})
				items = append(items, item{typ: app, title: "Steam", desc: "Remove Steam", value: "com.valvesoftware.Steam"})
				items = append(items, item{typ: app, title: "Protontricks", desc: "Remove Protontricks", value: "com.github.Matoking.protontricks"})
				items = append(items, item{typ: app, title: "Heroic Games Launcher", desc: "Remove Heroic", value: "com.heroicgameslauncher.hgl"})
				items = append(items, item{typ: app, title: "ProtonPlus", desc: "Remove ProtonPlus", value: "com.vysp3r.ProtonPlus"})
				items = append(items, item{typ: app, title: "Varia", desc: "Remove Varia", value: "io.github.giantpinkrobots.varia"})
				items = append(items, item{typ: app, title: "Sober (Roblox)", desc: "Remove Roblox", value: "org.vinegarhq.Sober"})
				items = append(items, item{typ: app, title: "Vinegar (Roblox)", desc: "Remove Vinegar", value: "org.vinegarhq.Vinegar"})
				items = append(items, item{typ: app, title: "Visual Studio Code", desc: "Remove VSCode", value: "com.visualstudio.code"})
				items = append(items, item{typ: app, title: "crystal", desc: "Remove crystal", value: "crystal"})
				items = append(items, item{typ: app, title: "shards", desc: "Remove shards", value: "shards"})
				items = append(items, item{typ: app, title: "nodejs", desc: "Remove nodejs", value: "nodejs"})
				items = append(items, item{typ: app, title: "npm", desc: "Remove npm", value: "npm"})
				items = append(items, item{typ: app, title: "rust", desc: "Remove rust", value: "rust"})
				items = append(items, item{typ: app, title: "golang", desc: "Remove golang", value: "golang"})
				items = append(items, item{typ: app, title: "lua5.4", desc: "Remove lua", value: "lua5.4"})
				items = append(items, item{typ: app, title: "zig", desc: "Remove zig", value: "zig"})
				items = append(items, item{typ: app, title: "shadPS4", desc: "Remove shadPS4", value: "org.shadps4.shadPS4"})
				items = append(items, item{typ: app, title: "Ryujinx", desc: "Remove Ryujinx", value: "io.ryujinx.Ryujinx"})
				items = append(items, item{typ: app, title: "DOSBox-X", desc: "Remove DOSBox-X", value: "com.dosbox_x.DOSBox-X"})
				items = append(items, item{typ: app, title: "RPCS3", desc: "Remove RPCS3", value: "rpcs3-emu"})
				items = append(items, item{typ: app, title: "gamescope", desc: "Remove gamescope", value: "gamescope"})

				case "cyber":
					items = append(items, item{typ: category, title: "All", desc: "Install all BlackArch tools", value: "all"})
					items = append(items, item{typ: header, title: "BlackArch Categories"})

					// Fetch categories from BlackArch container
					cmd := exec.Command("distrobox-enter", "-n", "blackarch", "--", "bash", "-c", "pacman -Sg | grep '^blackarch-'")
					out, err := cmd.Output()
					if err != nil {
						fmt.Printf("Error fetching categories: %v\n", err)
						os.Exit(1)
					}
					lines := strings.Split(string(out), "\n")
					for _, line := range lines {
						line = strings.TrimSpace(line)
						if line != "" {
							items = append(items, item{typ: category, title: line, desc: "BlackArch category", value: line})
						}
					}

				default:
					fmt.Println("Invalid mode. Use -mode=unpack, -mode=pack, or -mode=cyber")
					os.Exit(1)
	}

	p := tea.NewProgram(newModel(items, mode), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
}
