package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/viewport"
	"github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ─── Styles ───────────────────────────────────────────────────────────────────

var (
	colorAccent  = lipgloss.Color("#c026d3")
	colorAccent2 = lipgloss.Color("#7c3aed")
	colorGreen   = lipgloss.Color("#22c55e")
	colorYellow  = lipgloss.Color("#eab308")
	colorRed     = lipgloss.Color("#ef4444")
	colorCyan    = lipgloss.Color("#06b6d4")
	colorDim     = lipgloss.Color("#475569")
	colorText    = lipgloss.Color("#e2e8f0")
	colorBg      = lipgloss.Color("#0d0d0f")
	colorBg2     = lipgloss.Color("#13131a")
	colorBorder  = lipgloss.Color("#2a2a3a")

	styleTitle = lipgloss.NewStyle().
	Bold(true).
	Foreground(colorAccent).
	Background(colorBg2).
	Padding(0, 2).
	Width(0)

	stylePromptLabel = lipgloss.NewStyle().
	Bold(true).
	Foreground(colorAccent)

	styleInputBox = lipgloss.NewStyle().
	Border(lipgloss.RoundedBorder()).
	BorderForeground(colorAccent).
	Padding(0, 1)

	styleOutput = lipgloss.NewStyle().
	Border(lipgloss.RoundedBorder()).
	BorderForeground(colorBorder).
	Padding(0, 1)

	styleOutputTitle = lipgloss.NewStyle().
	Foreground(colorDim).
	Italic(true)

	styleSidebar = lipgloss.NewStyle().
	Border(lipgloss.NormalBorder(), false, true, false, false).
	BorderForeground(colorBorder).
	Padding(0, 1, 0, 0)

	styleStatusBar = lipgloss.NewStyle().
	Background(colorBg2).
	Foreground(colorDim).
	Padding(0, 1)

	styleSuccess = lipgloss.NewStyle().Foreground(colorGreen)
	styleError   = lipgloss.NewStyle().Foreground(colorRed)
	styleWarning = lipgloss.NewStyle().Foreground(colorYellow)
	styleCyan    = lipgloss.NewStyle().Foreground(colorCyan)
	styleDim     = lipgloss.NewStyle().Foreground(colorDim)
)

// ─── Commands catalogue ───────────────────────────────────────────────────────

type cmdEntry struct {
	name    string
	desc    string
	group   string
	hasArgs bool
}

func (c cmdEntry) Title() string       { return c.name }
func (c cmdEntry) Description() string { return c.desc }
func (c cmdEntry) FilterValue() string { return c.name + " " + c.desc + " " + c.group }

var allCommands = []cmdEntry{
	// Packages
	{"install", "Zainstaluj pakiet APT", "Pakiety", true},
	{"remove", "Usuń pakiet APT", "Pakiety", true},
	{"flatpak-install", "Zainstaluj pakiet Flatpak", "Pakiety", true},
	{"flatpak-remove", "Usuń pakiet Flatpak", "Pakiety", true},
	// Unpack
	{"unpack add-ons", "Wine, BoxBuddy, WineZGUI, GearLever", "Unpack", false},
	{"unpack gaming", "Steam, Heroic, ProtonPlus…", "Unpack", false},
	{"unpack gaming with-roblox", "Gaming + Roblox (Sober, Vinegar)", "Unpack", false},
	{"unpack devtools", "VS Code, Rust, Go, Node, Zig…", "Unpack", false},
	{"unpack emulators", "shadPS4, Ryujinx, DOSBox-X, RPCS3", "Unpack", false},
	{"unpack cybersecurity", "Kontener BlackArch", "Unpack", false},
	{"unpack select", "Interaktywny wybór (TUI)", "Unpack", false},
	{"unpack hacker-mode", "Tryb Hacker-Mode (Wayland)", "Unpack", false},
	{"unpack gamescope-session-steam", "Steam GameMode (gamescope)", "Unpack", false},
	{"unpack automatic-updates", "Włącz auto-aktualizacje (hup)", "Unpack", false},
	{"unpack alacritty-config", "Konfiguracja Alacritty", "Unpack", false},
	{"unpack nvidia-drivers", "Sterowniki NVIDIA", "Unpack", false},
	{"unpack hackeros-containers", "Kontenery HackerOS (blackarch, kali…)", "Unpack", false},
	{"unpack h#", "H# (H-Sharp) — język HackerOS", "Unpack", false},
	{"unpack h#-utils", "Narzędzia pomocnicze H#", "Unpack", false},
	{"unpack flox", "Flox — menedżer środowisk", "Unpack", false},
	{"unpack hammer", "Hammer — atomowy menedżer pakietów", "Unpack", false},
	{"unpack lpm", "LPM — następca apt", "Unpack", false},
	{"unpack isolator", "Isolator — pakiety w kontenerach", "Unpack", false},
	{"unpack hexai", "HexAi — AI dla HackerOS", "Unpack", false},
	{"unpack hackerdeck", "HackerDeck — nakładka Waydroid", "Unpack", false},
	{"unpack hackeros-games-addons", "Dodatki do gier HackerOS", "Unpack", false},
	// Pack
	{"pack add-ons", "Usuń Wine i dodatki", "Pack", false},
	{"pack gaming", "Usuń narzędzia do gier", "Pack", false},
	{"pack devtools", "Usuń narzędzia deweloperskie", "Pack", false},
	{"pack emulators", "Usuń emulatory", "Pack", false},
	{"pack cybersecurity", "Usuń kontener BlackArch", "Pack", false},
	{"pack hacker-mode", "Usuń Hacker-Mode", "Pack", false},
	{"pack automatic-updates", "Wyłącz auto-aktualizacje", "Pack", false},
	{"pack nvidia-drivers", "Usuń sterowniki NVIDIA", "Pack", false},
	{"pack h#", "Usuń H# (H-Sharp)", "Pack", false},
	{"pack h#-utils", "Usuń narzędzia H#", "Pack", false},
	{"pack hammer", "Usuń Hammer", "Pack", false},
	{"pack lpm", "Usuń LPM", "Pack", false},
	{"pack hexai", "Usuń HexAi", "Pack", false},
	{"pack hackerdeck", "Usuń HackerDeck", "Pack", false},
	// Env
	{"env create", "Utwórz środowisko z pliku .hk", "Env", true},
	{"env remove", "Usuń środowisko", "Env", true},
	{"env enter", "Wejdź do środowiska", "Env", true},
	{"env settings", "Lista środowisk", "Env", false},
	{"env docs", "Tutorial środowisk", "Env", false},
	// System
	{"update", "Aktualizacja systemu (TUI)", "System", false},
	{"update --with-gui", "Aktualizacja w nowym oknie", "System", false},
	{"system logs", "Logi systemowe (journalctl)", "System", false},
	{"switch hacker-mode", "Przełącz na Hacker-Mode", "System", false},
	{"switch steam-gamemode", "Przełącz na Steam GameMode", "System", false},
	{"restart", "Restart usługi systemd", "System", true},
	{"doctor", "Diagnostyka systemu", "System", false},
	{"repair", "Narzędzie naprawcze (TUI)", "System", false},
	// Run
	{"run update-system", "Skrypt aktualizacji", "Run", false},
	{"run check-updates", "Sprawdź aktualizacje", "Run", false},
	{"run steam", "Uruchom Steam", "Run", false},
	{"run hacker-launcher", "Hacker Launcher", "Run", false},
	{"run hackeros-game-mode", "HackerOS Game Mode", "Run", false},
	{"run HackerOS-Store", "Sklep HackerOS", "Run", false},
	{"run HackerDeck", "HackerDeck", "Run", false},
	{"run Hacker-Term", "Terminal HackerOS", "Run", false},
	// Plugins
	{"plugin list", "Lista pluginów", "Pluginy", false},
	{"plugin enable", "Włącz plugin", "Pluginy", true},
	{"plugin disable", "Wyłącz plugin", "Pluginy", true},
	// Enable/Disable
	{"enable motd", "Włącz MOTD", "Enable/Disable", false},
	{"enable special-motd", "Włącz specjalny MOTD", "Enable/Disable", false},
	{"disable motd", "Wyłącz MOTD", "Enable/Disable", false},
	// Settings
	{"settings language", "Zmień język interfejsu", "Ustawienia", true},
	// Misc
	{"game", "Tekstowa gra przygodowa", "Inne", false},
	{"ascii", "Logo HackerOS ASCII", "Inne", false},
	{"enter", "Wejdź do kontenera distrobox", "Inne", true},
	{"remove-container", "Usuń kontener distrobox", "Inne", true},
	{"index", "Indeks narzędzi HackerOS", "Inne", false},
	{"info", "Wersje narzędzia i systemu", "Inne", false},
	{"issue", "Zgłoś błąd na GitHub", "Inne", false},
	{"hacker-lang", "Info o Hacker Lang", "Inne", false},
	{"how-to-create-commands", "Jak tworzyć własne komendy", "Inne", false},
}

// ─── Msg types ────────────────────────────────────────────────────────────────

type execFinishedMsg struct {
	output string
	err    error
	cmd    string
	dur    time.Duration
}

type tickMsg time.Time

// ─── Mode ─────────────────────────────────────────────────────────────────────

type appMode int

const (
	modeBrowse  appMode = iota // sidebar list focused
	modeInput                  // typing a command in input box
	modeRunning                // command executing
	modeOutput                 // viewing output
)

// ─── Model ────────────────────────────────────────────────────────────────────

type model struct {
	width, height int
	mode          appMode

	list      list.Model
	input     textinput.Model
	viewport  viewport.Model

	history       []string // command history
	historyIdx    int
	outputLines   []string
	lastCmd       string
	lastDur       time.Duration
	lastExitOk    bool
	runningSpinner int
	spinnerFrames []string

	// hsh binary path
	hshPath string

	// keybindings
	keys keyMap
}

type keyMap struct {
	run    key.Binding
	clear  key.Binding
	quit   key.Binding
	back   key.Binding
	hist   key.Binding
	histUp key.Binding
}

func newKeyMap() keyMap {
	return keyMap{
		run:    key.NewBinding(key.WithKeys("enter"), key.WithHelp("enter", "wyślij")),
		clear:  key.NewBinding(key.WithKeys("ctrl+l"), key.WithHelp("ctrl+l", "wyczyść")),
		quit:   key.NewBinding(key.WithKeys("ctrl+c", "ctrl+q"), key.WithHelp("ctrl+c", "wyjdź")),
		back:   key.NewBinding(key.WithKeys("esc"), key.WithHelp("esc", "wróć")),
		histUp: key.NewBinding(key.WithKeys("up"), key.WithHelp("↑", "historia+")),
		hist:   key.NewBinding(key.WithKeys("down"), key.WithHelp("↓", "historia-")),
	}
}

func findHsh() string {
	// 1. Check $PATH
	if p, err := exec.LookPath("hsh"); err == nil {
		return p
	}
	// 2. Check ~/.hackeros/hacker/hsh
	home, _ := os.UserHomeDir()
	p := filepath.Join(home, ".hackeros", "hacker", "hsh")
	if _, err := os.Stat(p); err == nil {
		return p
	}
	// 3. fallback: bash -c (still works, just less featureful)
	return "bash"
}

func initialModel() model {
	// List
	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.
	Foreground(colorAccent).
	Bold(true).
	BorderLeftForeground(colorAccent)
	delegate.Styles.SelectedDesc = delegate.Styles.SelectedDesc.
	Foreground(colorAccent2).
	BorderLeftForeground(colorAccent)
	delegate.ShowDescription = true

	items := make([]list.Item, len(allCommands))
	for i, c := range allCommands {
		items[i] = c
	}

	l := list.New(items, delegate, 0, 0)
	l.Title = "Komendy"
	l.SetShowStatusBar(true)
	l.SetFilteringEnabled(true)
	l.Styles.Title = lipgloss.NewStyle().
	Bold(true).
	Foreground(colorAccent).
	Padding(0, 1)
	l.SetShowHelp(false)

	// Input
	ti := textinput.New()
	ti.Placeholder = "hacker ..."
	ti.PlaceholderStyle = lipgloss.NewStyle().Foreground(colorDim)
	ti.TextStyle = lipgloss.NewStyle().Foreground(colorText)
	ti.CharLimit = 512
	ti.Width = 60

	// Viewport
	vp := viewport.New(0, 0)
	vp.Style = lipgloss.NewStyle().Foreground(colorText)

	return model{
		mode:          modeBrowse,
		list:          l,
		input:         ti,
		viewport:      vp,
		history:       []string{},
		historyIdx:    -1,
		outputLines:   []string{},
		spinnerFrames: []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
		hshPath:       findHsh(),
		keys:          newKeyMap(),
	}
}

// ─── Init ─────────────────────────────────────────────────────────────────────

func (m model) Init() tea.Cmd {
	return textinput.Blink
}

// ─── Update ───────────────────────────────────────────────────────────────────

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {

		case tea.WindowSizeMsg:
			m.width = msg.Width
			m.height = msg.Height
			m = m.recalcLayout()

		case tickMsg:
			if m.mode == modeRunning {
				m.runningSpinner = (m.runningSpinner + 1) % len(m.spinnerFrames)
				cmds = append(cmds, tickCmd())
			}

		case execFinishedMsg:
			m.lastDur = msg.dur
			m.lastCmd = msg.cmd
			m.lastExitOk = msg.err == nil

			lines := strings.Split(strings.TrimRight(msg.output, "\n"), "\n")
			if msg.err != nil {
				lines = append(lines, "")
				lines = append(lines, styleError.Render("✗  Błąd: "+msg.err.Error()))
			} else {
				lines = append(lines, "")
				lines = append(lines, styleSuccess.Render("✓  OK"))
			}
			m.outputLines = lines
			m.viewport.SetContent(strings.Join(colorizeOutput(lines), "\n"))
			m.viewport.GotoBottom()
			m.mode = modeOutput

		case tea.KeyMsg:
			// Global quit
			if key.Matches(msg, m.keys.quit) {
				return m, tea.Quit
			}

			switch m.mode {

				case modeBrowse:
					switch {
						case msg.Type == tea.KeyEnter:
							if sel, ok := m.list.SelectedItem().(cmdEntry); ok {
								m.mode = modeInput
								prefix := "hacker " + sel.name
								if sel.hasArgs {
									prefix += " "
								}
								m.input.SetValue(prefix)
								m.input.CursorEnd()
								m.input.Focus()
								return m, textinput.Blink
							}
						case msg.Type == tea.KeyRunes && msg.String() == "i":
							// direct input mode
							m.mode = modeInput
							m.input.SetValue("hacker ")
							m.input.CursorEnd()
							m.input.Focus()
							return m, textinput.Blink
						case msg.Type == tea.KeyRunes && msg.String() == "q":
							return m, tea.Quit
					}
					var lCmd tea.Cmd
					m.list, lCmd = m.list.Update(msg)
					cmds = append(cmds, lCmd)

						case modeInput:
							switch {
								case key.Matches(msg, m.keys.back):
									m.mode = modeBrowse
									m.input.Blur()
									return m, nil

								case key.Matches(msg, m.keys.run):
									raw := strings.TrimSpace(m.input.Value())
									if raw == "" {
										return m, nil
									}
									// strip leading "hacker " if user typed it
									cmd := raw
									if strings.HasPrefix(cmd, "hacker ") {
										cmd = strings.TrimPrefix(cmd, "hacker ")
									}
									// push to history
									m.history = append([]string{raw}, m.history...)
									if len(m.history) > 200 {
										m.history = m.history[:200]
									}
									m.historyIdx = -1
									m.input.SetValue("")
									m.mode = modeRunning
									m.runningSpinner = 0
									m.lastCmd = cmd
									cmds = append(cmds, runCommand(m.hshPath, cmd), tickCmd())

								case key.Matches(msg, m.keys.histUp):
									if len(m.history) > 0 {
										m.historyIdx++
										if m.historyIdx >= len(m.history) {
											m.historyIdx = len(m.history) - 1
										}
										m.input.SetValue(m.history[m.historyIdx])
										m.input.CursorEnd()
									}

								case key.Matches(msg, m.keys.hist):
									if m.historyIdx > 0 {
										m.historyIdx--
										m.input.SetValue(m.history[m.historyIdx])
										m.input.CursorEnd()
									} else if m.historyIdx == 0 {
										m.historyIdx = -1
										m.input.SetValue("hacker ")
										m.input.CursorEnd()
									}

								case key.Matches(msg, m.keys.clear):
									m.input.SetValue("hacker ")
									m.input.CursorEnd()

								default:
									var tiCmd tea.Cmd
									m.input, tiCmd = m.input.Update(msg)
									cmds = append(cmds, tiCmd)
							}

								case modeRunning:
									// nothing interactive while running

								case modeOutput:
									switch {
										case key.Matches(msg, m.keys.back) || msg.Type == tea.KeyEnter:
											m.mode = modeInput
											m.input.SetValue("hacker ")
											m.input.CursorEnd()
											m.input.Focus()
											return m, textinput.Blink
										case msg.Type == tea.KeyRunes && msg.String() == "b":
											m.mode = modeBrowse
											m.input.Blur()
											return m, nil
										default:
											var vpCmd tea.Cmd
											m.viewport, vpCmd = m.viewport.Update(msg)
											cmds = append(cmds, vpCmd)
									}
			}
	}

	return m, tea.Batch(cmds...)
}

func (m model) recalcLayout() model {
	sideW := 36
	if m.width < 90 {
		sideW = 28
	}
	mainW := m.width - sideW - 4
	bodyH := m.height - 5 // header(2) + input(3) + statusbar(1)

	m.list.SetWidth(sideW)
	m.list.SetHeight(bodyH)

	m.input.Width = mainW - 4
	m.viewport.Width = mainW - 2
	m.viewport.Height = bodyH - 4
	return m
}

// ─── View ─────────────────────────────────────────────────────────────────────

func (m model) View() string {
	if m.width == 0 {
		return "Inicjalizacja..."
	}

	sideW := 36
	if m.width < 90 {
		sideW = 28
	}
	mainW := m.width - sideW - 2

	// ── Header ──
	hackerLabel := lipgloss.NewStyle().
	Bold(true).
	Foreground(colorAccent).
	Render("⬡  hacker")
	interactiveLabel := lipgloss.NewStyle().
	Foreground(colorDim).
	Render(" interactive")
	versionLabel := lipgloss.NewStyle().
	Foreground(colorDim).
	Render("v2.3.1")
	hshLabel := lipgloss.NewStyle().
	Foreground(colorCyan).
	Render("hsh: " + filepath.Base(m.hshPath))

	headerLeft := hackerLabel + interactiveLabel
	headerRight := hshLabel + "  " + versionLabel
	gap := m.width - lipgloss.Width(headerLeft) - lipgloss.Width(headerRight) - 2
	if gap < 0 {
		gap = 0
	}
	header := lipgloss.NewStyle().
	Background(colorBg2).
	Width(m.width).
	Padding(0, 1).
	Render(headerLeft + strings.Repeat(" ", gap) + headerRight)

	// ── Sidebar ──
	sidebar := styleSidebar.
	Width(sideW).
	Height(m.height - 4).
	Render(m.list.View())

	// ── Main area ──
	var mainContent string
	bodyH := m.height - 5

	switch m.mode {

		case modeBrowse:
			hint := lipgloss.NewStyle().
			Foreground(colorDim).
			Italic(true).
			Width(mainW - 2).
			Render("\n  ↑↓ nawigacja  ·  Enter wybierz  ·  / filtruj  ·  i wpisz komendę  ·  q wyjdź")
			tip := lipgloss.NewStyle().
			Foreground(colorCyan).
			Width(mainW - 2).
			Render("\n  Wybierz komendę z listy lub naciśnij [i] aby wpisać bezpośrednio.")

			if sel, ok := m.list.SelectedItem().(cmdEntry); ok {
				grpBox := lipgloss.NewStyle().
				Foreground(colorDim).
				Italic(true).
				Render("  Grupa: " + sel.group)
				argsNote := ""
				if sel.hasArgs {
					argsNote = styleCyan.Render("  ⬡ Ta komenda przyjmuje argumenty.")
				}
				preview := lipgloss.NewStyle().
				Border(lipgloss.RoundedBorder()).
				BorderForeground(colorBorder).
				Width(mainW - 4).
				Padding(1, 2).
				Render(
					styleSuccess.Render("hacker "+sel.name) + "\n\n" +
					lipgloss.NewStyle().Foreground(colorText).Render(sel.desc) + "\n\n" +
					grpBox + "\n" + argsNote,
				)
				mainContent = lipgloss.JoinVertical(lipgloss.Left, preview, hint)
			} else {
				mainContent = tip + hint
			}
			// pad to fill height
			mainContent = padToHeight(mainContent, bodyH, mainW)

		case modeInput:
			promptLine := stylePromptLabel.Render("❯ ") + m.input.View()
			inputArea := styleInputBox.
			Width(mainW - 2).
			Render(promptLine)

			histHint := ""
			if len(m.history) > 0 {
				histHint = styleDim.Render(
					fmt.Sprintf("  Historia: %d komend  ↑↓ nawiguj  Ctrl+L wyczyść  Esc wróć",
						    len(m.history)),
				)
			} else {
				histHint = styleDim.Render("  Esc — wróć do listy  ·  Enter — wykonaj")
			}

			recentBlock := ""
			if len(m.history) > 0 {
				recent := m.history
				if len(recent) > 5 {
					recent = recent[:5]
				}
				lines := []string{styleDim.Render("  Ostatnie komendy:")}
				for i, h := range recent {
					prefix := "  "
					if i == m.historyIdx {
						prefix = styleCyan.Render("  ▶ ")
					} else {
						prefix = styleDim.Render("    ")
					}
					lines = append(lines, prefix+styleDim.Render(h))
				}
				recentBlock = strings.Join(lines, "\n")
			}

			mainContent = lipgloss.JoinVertical(lipgloss.Left,
							    "\n",
				       inputArea,
				       "",
				       histHint,
				       "",
				       recentBlock,
			)
			mainContent = padToHeight(mainContent, bodyH, mainW)

		case modeRunning:
			spinner := m.spinnerFrames[m.runningSpinner]
			spinLine := lipgloss.NewStyle().
			Bold(true).
			Foreground(colorAccent).
			Render(fmt.Sprintf("\n  %s  Wykonywanie: ", spinner)) +
			styleSuccess.Render("hacker "+m.lastCmd)

			note := styleDim.Render("\n  Proszę czekać... (Ctrl+C aby przerwać)")

			mainContent = padToHeight(
				lipgloss.JoinVertical(lipgloss.Left, spinLine, note),
						  bodyH, mainW,
			)

		case modeOutput:
			statusLine := ""
			if m.lastExitOk {
				statusLine = styleSuccess.Render("✓ OK") + styleDim.Render(
					fmt.Sprintf("  ·  hacker %s  ·  %s", m.lastCmd, m.lastDur.Round(time.Millisecond)))
			} else {
				statusLine = styleError.Render("✗ Błąd") + styleDim.Render(
					fmt.Sprintf("  ·  hacker %s  ·  %s", m.lastCmd, m.lastDur.Round(time.Millisecond)))
			}
			outputBox := styleOutput.
			Width(mainW - 2).
			Height(bodyH - 3).
			Render(m.viewport.View())
			hint := styleDim.Render("  Enter/Esc — nowa komenda  ·  b — lista  ·  ↑↓ — przewijaj")

			mainContent = lipgloss.JoinVertical(lipgloss.Left,
							    "  "+statusLine,
				       outputBox,
				       hint,
			)
	}

	// ── Status bar ──
	modeStr := map[appMode]string{
		modeBrowse:  "BROWSE",
		modeInput:   "INPUT",
		modeRunning: "RUNNING",
		modeOutput:  "OUTPUT",
	}[m.mode]

	modeColor := map[appMode]lipgloss.Color{
		modeBrowse:  colorCyan,
		modeInput:   colorAccent,
		modeRunning: colorYellow,
		modeOutput:  colorGreen,
	}[m.mode]

	modeTag := lipgloss.NewStyle().
	Background(modeColor).
	Foreground(colorBg).
	Bold(true).
	Padding(0, 1).
	Render(modeStr)

	keysHint := styleDim.Render(" Ctrl+C wyjdź  ·  / filtruj komendy")
	statusBar := styleStatusBar.
	Width(m.width).
	Render(modeTag + keysHint)

	// ── Combine ──
	body := lipgloss.JoinHorizontal(lipgloss.Top,
					sidebar,
				 " ",
				 mainContent,
	)

	return lipgloss.JoinVertical(lipgloss.Left,
				     header,
			      body,
			      statusBar,
	)
}

// ─── Commands (tea.Cmd) ───────────────────────────────────────────────────────

func runCommand(hshPath, cmd string) tea.Cmd {
	return func() tea.Msg {
		start := time.Now()

		// Build: hsh -c "hacker <cmd>"  OR  bash -c "hacker <cmd>"
		fullCmd := "hacker " + cmd
		var c *exec.Cmd
		if filepath.Base(hshPath) == "bash" {
			c = exec.Command("bash", "-c", fullCmd)
		} else {
			c = exec.Command(hshPath, "-c", fullCmd)
		}
		c.Env = append(os.Environ(), "TERM=xterm-256color")

		out, err := c.CombinedOutput()
		dur := time.Since(start)

		return execFinishedMsg{
			output: string(out),
			err:    err,
			cmd:    cmd,
			dur:    dur,
		}
	}
}

func tickCmd() tea.Cmd {
	return tea.Tick(80*time.Millisecond, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func colorizeOutput(lines []string) []string {
	result := make([]string, len(lines))
	for i, l := range lines {
		switch {
			case strings.HasPrefix(l, "[ERROR]") || strings.Contains(l, "error:") || strings.HasPrefix(l, "✗"):
				result[i] = styleError.Render(l)
			case strings.HasPrefix(l, "[WARN]") || strings.Contains(l, "Warning"):
				result[i] = styleWarning.Render(l)
			case strings.HasPrefix(l, "[INFO]") || strings.HasPrefix(l, "✓"):
				result[i] = styleSuccess.Render(l)
			case strings.HasPrefix(l, ">>>") || strings.HasPrefix(l, "━━━") || strings.HasPrefix(l, "==="):
				result[i] = lipgloss.NewStyle().Foreground(colorAccent).Bold(true).Render(l)
			default:
				result[i] = l
		}
	}
	return result
}

func padToHeight(content string, targetH, w int) string {
	lines := strings.Split(content, "\n")
	current := len(lines)
	for current < targetH {
		lines = append(lines, "")
		current++
	}
	out := strings.Join(lines, "\n")
	_ = w
	_ = utf8.RuneCountInString(out)
	return out
}

// ─── Main ─────────────────────────────────────────────────────────────────────

func main() {
	m := initialModel()
	p := tea.NewProgram(m,
			    tea.WithAltScreen(),
			    tea.WithMouseCellMotion(),
	)
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Błąd uruchomienia: %v\n", err)
		os.Exit(1)
	}
}
