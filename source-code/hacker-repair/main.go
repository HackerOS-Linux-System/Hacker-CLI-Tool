package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

var (
	windowSize tea.WindowSizeMsg

	titleStyle = lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#FAFAFA")).
		Background(lipgloss.Color("#7D56F4")).
		Padding(0, 1).
		Width(80).
		Align(lipgloss.Center)

	subtitleStyle = lipgloss.NewStyle().
		Italic(true).
		Foreground(lipgloss.Color("#AAA")).
		Margin(1, 0)

	errorStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("#FF0000"))

	successStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("#00FF00"))

	listStyle = lipgloss.NewStyle().
		Margin(1, 2)

	viewportStyle = lipgloss.NewStyle().
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(lipgloss.Color("#7D56F4")).
		Margin(1, 2).
		Padding(0, 1)
)

type stage int

const (
	mainMenu stage = iota
	questions
	repair
	timeshiftMenu
	outputView
)

type model struct {
	stage     stage
	list      list.Model
	textInput textinput.Model
	viewport  viewport.Model
	questions []string
	answers   []string
	currentQ  int
	dontKnow  bool
	output    string
	err       error
}

type item struct {
	title, desc string
}

func (i item) Title() string       { return i.title }
func (i item) Description() string { return i.desc }
func (i item) FilterValue() string { return i.title }

func initialModel() *model {
	items := []list.Item{
		item{title: "Rozpocznij diagnostykę (odpowiadaj na pytania)", desc: "Krok po kroku odpowiadaj na pytania o problemy"},
		item{title: "Nie wiem, co jest nie tak - automatyczne skanowanie i naprawa", desc: "Narzędzie samo sprawdzi i naprawi typowe problemy"},
		item{title: "Zarządzanie Timeshift (snapshoty systemu)", desc: "Twórz, przywracaj snapshoty"},
		item{title: "Wyjdź", desc: "Zamknij program"},
	}

	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.Foreground(lipgloss.Color("#7D56F4")).Bold(true)
	delegate.Styles.NormalTitle = delegate.Styles.NormalTitle.Foreground(lipgloss.Color("#FFFFFF"))

	l := list.New(items, delegate, 0, 0)
	l.Title = "Menu Główne"
	l.Styles.Title = subtitleStyle

	ti := textinput.New()
	ti.Placeholder = "Wpisz tak/nie"
	ti.Focus()
	ti.Width = 30

	vp := viewport.New(0, 0)
	vp.Style = viewportStyle

	m := &model{
		stage:     mainMenu,
		list:      l,
		textInput: ti,
		viewport:  vp,
		questions: []string{
			"Czy masz problemy z pakietami (np. błędy apt)?",
			"Czy system nie bootuje poprawnie?",
			"Czy są problemy z dyskiem (np. błędy fs)?",
			"Czy chcesz zaktualizować system?",
		},
		answers: make([]string, 4),
	}

	return m
}

func (m *model) Init() tea.Cmd {
	return textinput.Blink
}

func (m *model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		windowSize = msg
		h, v := listStyle.GetFrameSize()
		m.list.SetSize(msg.Width-h, msg.Height-v-10) // Adjust for title and margins
		m.viewport.Width = msg.Width - viewportStyle.GetHorizontalFrameSize()
		m.viewport.Height = msg.Height - viewportStyle.GetVerticalFrameSize() - 10
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		}
	}

	switch m.stage {
	case mainMenu, timeshiftMenu:
		m.list, cmd = m.list.Update(msg)
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "enter" {
				selected := m.list.SelectedItem().(item)
				switch m.stage {
				case mainMenu:
					switch selected.title {
					case "Rozpocznij diagnostykę (odpowiadaj na pytania)":
						m.stage = questions
						m.currentQ = 0
						m.textInput.SetValue("")
						m.textInput.Focus()
						return m, textinput.Blink
					case "Nie wiem, co jest nie tak - automatyczne skanowanie i naprawa":
						m.dontKnow = true
						m.output = autoScanAndRepair()
						m.viewport.SetContent(m.output)
						m.stage = outputView
					case "Zarządzanie Timeshift (snapshoty systemu)":
						m.stage = timeshiftMenu
						items := []list.Item{
							item{title: "Utwórz nowy snapshot", desc: "Stwórz punkt przywracania"},
							item{title: "Przywróć snapshot", desc: "Przywróć system do poprzedniego stanu"},
							item{title: "Lista snapshotów", desc: "Wyświetl dostępne snapshoty"},
							item{title: "Wróć", desc: "Powrót do menu głównego"},
						}
						m.list.SetItems(items)
						m.list.Title = "Menu Timeshift"
					case "Wyjdź":
						return m, tea.Quit
					}
				case timeshiftMenu:
					switch selected.title {
					case "Utwórz nowy snapshot":
						m.output = runTimeshift("--create")
						m.viewport.SetContent(m.output)
						m.stage = outputView
					case "Przywróć snapshot":
						m.output = runTimeshift("--restore")
						m.viewport.SetContent(m.output)
						m.stage = outputView
					case "Lista snapshotów":
						m.output = runTimeshift("--list")
						m.viewport.SetContent(m.output)
						m.stage = outputView
					case "Wróć":
						m.stage = mainMenu
						m.list.SetItems(initialModel().list.Items())
						m.list.Title = "Menu Główne"
					}
				}
			}
		}

	case questions:
		m.textInput, cmd = m.textInput.Update(msg)
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "enter" {
				ans := strings.ToLower(strings.TrimSpace(m.textInput.Value()))
				if ans != "tak" && ans != "nie" {
					m.output = "Proszę wpisać 'tak' lub 'nie'."
					m.viewport.SetContent(errorStyle.Render(m.output))
					m.stage = outputView
					return m, nil
				}
				m.answers[m.currentQ] = ans
				m.currentQ++
				if m.currentQ >= len(m.questions) {
					m.output = repairBasedOnAnswers(m.answers)
					m.viewport.SetContent(m.output)
					m.stage = outputView
				} else {
					m.textInput.SetValue("")
				}
			}
		}

	case outputView:
		m.viewport, cmd = m.viewport.Update(msg)
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "enter" || msg.String() == "esc" {
				m.stage = mainMenu
				m.list.SetItems(initialModel().list.Items())
				m.list.Title = "Menu Główne"
			}
		}
	}

	return m, cmd
}

func (m *model) View() string {
	var s strings.Builder

	s.WriteString(titleStyle.Render("Hacker-Repair: Narzędzie do naprawy systemu Debian") + "\n\n")

	switch m.stage {
	case mainMenu, timeshiftMenu:
		s.WriteString(listStyle.Render(m.list.View()))

	case questions:
		s.WriteString(subtitleStyle.Render(m.questions[m.currentQ]) + "\n")
		s.WriteString(m.textInput.View() + "\n")
		s.WriteString("\nNaciśnij enter aby potwierdzić.")

	case outputView:
		if strings.Contains(m.output, "Błąd") {
			s.WriteString(subtitleStyle.Render("Wynik operacji:") + "\n")
			s.WriteString(viewportStyle.Render(errorStyle.Render(m.viewport.View())) + "\n")
		} else {
			s.WriteString(subtitleStyle.Render("Wynik operacji:") + "\n")
			s.WriteString(viewportStyle.Render(successStyle.Render(m.viewport.View())) + "\n")
		}
		s.WriteString("\nNaciśnij enter lub esc aby wrócić.")
	}

	s.WriteString("\n\nNaciśnij q aby wyjść.\n")

	return lipgloss.NewStyle().MaxWidth(windowSize.Width).Render(s.String())
}

func runCommand(cmd string, args ...string) string {
	c := exec.Command(cmd, args...)
	c.Stderr = os.Stderr // For real-time output if needed
	out, err := c.CombinedOutput()
	if err != nil {
		return fmt.Sprintf("Błąd: %v\nOutput: %s", err, string(out))
	}
	return string(out)
}

func runTimeshift(args ...string) string {
	// Assume timeshift is installed and run with necessary privileges
	return runCommand("timeshift", args...)
}

func repairBasedOnAnswers(answers []string) string {
	var output strings.Builder

	for i, ans := range answers {
		if ans == "tak" {
			switch i {
			case 0:
				output.WriteString("Naprawiam pakiety...\n")
				output.WriteString(runCommand("apt", "update"))
				output.WriteString(runCommand("apt", "install", "-f"))
				output.WriteString(runCommand("dpkg", "--configure", "-a"))
			case 1:
				output.WriteString("Naprawiam boot loader...\n")
				output.WriteString(runCommand("update-grub"))
			case 2:
				output.WriteString("Sprawdzam dysk (wymaga ręcznej interwencji dla root).\n")
				output.WriteString("Użyj fsck na odmontowanym dysku.\n")
			case 3:
				output.WriteString("Aktualizuję system...\n")
				output.WriteString(runCommand("apt", "upgrade", "-y"))
				output.WriteString(runCommand("apt", "autoremove", "-y"))
			}
		}
	}

	if output.Len() == 0 {
		return "Nic do naprawy na podstawie odpowiedzi."
	}
	return output.String()
}

func autoScanAndRepair() string {
	var output strings.Builder

	output.WriteString("Automatyczne skanowanie i naprawa...\n\n")

	output.WriteString("Aktualizacja listy pakietów:\n")
	output.WriteString(runCommand("apt", "update"))

	output.WriteString("\nNaprawa uszkodzonych pakietów:\n")
	output.WriteString(runCommand("apt", "install", "-f"))
	output.WriteString(runCommand("dpkg", "--configure", "-a"))

	output.WriteString("\nAktualizacja systemu:\n")
	output.WriteString(runCommand("apt", "upgrade", "-y"))

	output.WriteString("\nUsuwanie niepotrzebnych pakietów:\n")
	output.WriteString(runCommand("apt", "autoremove", "-y"))

	output.WriteString("\nOstatnie błędy z journalctl:\n")
	output.WriteString(runCommand("journalctl", "-p", "err", "-n", "100"))

	return output.String()
}

func main() {
	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Błąd: %v\n", err)
		os.Exit(1)
	}
}
