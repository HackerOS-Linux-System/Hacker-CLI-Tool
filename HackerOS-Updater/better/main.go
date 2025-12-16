package main

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/bubbles/progress"
	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/stopwatch"
	"github.com/charmbracelet/bubbles/viewport"
	"github.com/charmbracelet/lipgloss"
)

var (
	yellowStyle   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#FFFF00"))
	greenStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("#00FF00"))
	blueStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("#0000FF"))
	redStyle      = lipgloss.NewStyle().Foreground(lipgloss.Color("#FF0000"))
	cyanStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("#00FFFF"))
	magentaStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("#FF00FF"))
	spinnerStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("#FF00FF"))
	viewportStyle = lipgloss.NewStyle().BorderStyle(lipgloss.NormalBorder()).BorderForeground(lipgloss.Color("240")).Padding(0, 1)
)

type step struct {
	title string
	cmds  []string
}

var steps = []step{
	{"System Update", []string{"sudo apt update", "sudo apt upgrade -y", "sudo apt autoclean"}},
	{"Flatpak Update", []string{"flatpak update -y"}},
	{"Snap Update", []string{"sudo snap refresh"}},
	{"Brew Update", []string{"brew update", "brew upgrade"}},
	{"Firmware Update", []string{"sudo fwupdmgr update"}},
	{"Oh My Zsh Update", []string{"omz update"}},
	{"Distrobox Update", []string{"distrobox-upgrade --all"}},
	{"HackerOS Update", []string{"/usr/share/HackerOS/Scripts/Bin/update-hackeros.sh"}},
	{"Wallpaper Updates", []string{"/usr/share/HackerOS/Scripts/Bin/update-wallpapers.sh"}},
}

type tickMsg time.Time
type lineMsg string
type doneMsg bool

type model struct {
	steps     []step
	current   int
	statuses  []string
	spinner   spinner.Model
	progress  progress.Model
	stopwatch stopwatch.Model
	viewport  viewport.Model
	output    []string
	running   bool
	inMenu    bool
	lines     chan string
	done      chan bool
	ctx       context.Context
	cancel    context.CancelFunc
	width     int
	height    int
}

func New() *model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = spinnerStyle
	p := progress.New(progress.WithDefaultGradient())
	vp := viewport.New(80, 10)
	vp.Style = viewportStyle
	sw := stopwatch.New()
	statuses := make([]string, len(steps))
	return &model{
		steps:     steps,
		statuses:  statuses,
		spinner:   s,
		progress:  p,
		stopwatch: sw,
		viewport:  vp,
		output:    []string{},
	}
}

func (m *model) Init() tea.Cmd {
	return tea.Batch(m.stopwatch.Init(), m.nextStep())
}

func (m *model) nextStep() tea.Cmd {
	if m.current >= len(m.steps) {
		m.inMenu = true
		return nil
	}
	m.running = true
	m.output = []string{}
	m.viewport.SetContent("")
	m.lines = make(chan string, 100)
	m.done = make(chan bool)
	ctx, cancel := context.WithCancel(context.Background())
	m.ctx = ctx
	m.cancel = cancel
	go m.runStep()
	return tea.Batch(m.spinner.Tick, tick())
}

func (m *model) runStep() {
	success := true
	for _, cmdStr := range m.steps[m.current].cmds {
		cmd := exec.CommandContext(m.ctx, "bash", "-c", cmdStr)
		stdout, err := cmd.StdoutPipe()
		if err != nil {
			m.lines <- fmt.Sprintf("Error creating stdout pipe: %v", err)
			success = false
			continue
		}
		stderr, err := cmd.StderrPipe()
		if err != nil {
			m.lines <- fmt.Sprintf("Error creating stderr pipe: %v", err)
			success = false
			continue
		}
		if err := cmd.Start(); err != nil {
			m.lines <- fmt.Sprintf("Error starting command: %v", err)
			success = false
			continue
		}
		reader := io.MultiReader(stdout, stderr)
		scanner := bufio.NewScanner(reader)
		for scanner.Scan() {
			m.lines <- scanner.Text()
		}
		if err := scanner.Err(); err != nil {
			m.lines <- fmt.Sprintf("Error reading output: %v", err)
		}
		if err := cmd.Wait(); err != nil {
			m.lines <- fmt.Sprintf("Command failed: %v", err)
			success = false
		}
	}
	m.done <- success
	close(m.lines)
	close(m.done)
}

func tick() tea.Cmd {
	return tea.Tick(100*time.Millisecond, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

func (m *model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd
	switch msg := msg.(type) {
		case tea.WindowSizeMsg:
			m.width = msg.Width
			m.height = msg.Height
			m.progress.Width = msg.Width - 4
			if m.width > 80 {
				m.viewport.Width = 80
			} else {
				m.viewport.Width = m.width - 4
			}
			m.viewport.Height = m.height/2 - 5
		case tea.KeyMsg:
			if m.running || !m.inMenu {
				return m, nil
			}
			switch strings.ToUpper(msg.String()) {
				case "Q":
					return m, tea.Quit
				case "R":
					exec.Command("sudo", "reboot").Run()
				case "S":
					exec.Command("sudo", "shutdown", "-h", "now").Run()
				case "L":
					exec.Command("qdbus", "org.kde.ksmserver", "/KSMServer", "logout", "0", "0", "0").Run()
				case "T":
					exec.Command("alacritty").Start()
				case "A":
					m.enableAutomaticUpdates()
			}
				case spinner.TickMsg:
					if m.running {
						var cmd tea.Cmd
						m.spinner, cmd = m.spinner.Update(msg)
						cmds = append(cmds, cmd)
					}
				case stopwatch.TickMsg:
					var cmd tea.Cmd
					m.stopwatch, cmd = m.stopwatch.Update(msg)
					cmds = append(cmds, cmd)
				case progress.FrameMsg:
					var cmd tea.Cmd
					var tm tea.Model
					tm, cmd = m.progress.Update(msg)
					m.progress = tm.(progress.Model)
					cmds = append(cmds, cmd)
				case tickMsg:
					loop := true
					for loop {
						select {
				case line, ok := <-m.lines:
					if !ok {
						loop = false
						break
					}
					m.output = append(m.output, line)
					content := strings.Join(m.output, "\n")
					m.viewport.SetContent(content)
					m.viewport.GotoBottom()
				case success, ok := <-m.done:
					if !ok {
						loop = false
						break
					}
					m.running = false
					status := "FAILED"
					if success {
						status = "COMPLETE"
					}
					m.statuses[m.current] = status
					frac := float64(m.current+1) / float64(len(m.steps))
					pcmd := m.progress.SetPercent(frac)
					m.current++
					cmds = append(cmds, pcmd, m.nextStep())
					loop = false
				default:
					loop = false
						}
					}
					if m.running {
						cmds = append(cmds, tick())
					}
	}
	return m, tea.Batch(cmds...)
}

func (m *model) View() string {
	var b strings.Builder
	b.WriteString(yellowStyle.Render("HackerOS Updater") + "\n\n")
	b.WriteString("Time elapsed: " + m.stopwatch.View() + "\n")
	b.WriteString(m.progress.View() + "\n\n")
	if !m.inMenu {
		if m.current < len(m.steps) {
			b.WriteString(yellowStyle.Render("<--------[ " + m.steps[m.current].title + " ]-------->") + "\n")
			if m.running {
				b.WriteString(m.spinner.View() + " Running...\n\n")
			}
			b.WriteString(m.viewport.View() + "\n")
		}
		return b.String()
	}
	// Summary
	b.WriteString("Summary:\n")
	for i, st := range m.steps {
		s := st.title + " - "
		status := m.statuses[i]
		if status == "COMPLETE" {
			s += blueStyle.Render(status)
		} else if status == "FAILED" {
			s += redStyle.Render(status)
		} else {
			s += status // for empty, just -
		}
		b.WriteString(s + "\n")
	}
	b.WriteString("\n")
	// Menu
	b.WriteString(yellowStyle.Render("=== HackerOS Updater Menu ===") + "\n")
	b.WriteString(greenStyle.Render("[Q]uit") + " " + cyanStyle.Render("- Close this terminal") + "\n")
	b.WriteString(greenStyle.Render("[R]eboot") + " " + cyanStyle.Render("- Reboot the system") + "\n")
	b.WriteString(greenStyle.Render("[S]hutdown") + " " + cyanStyle.Render("- Shutdown the system") + "\n")
	b.WriteString(greenStyle.Render("[L]og out") + " " + cyanStyle.Render("- Log out from current session") + "\n")
	b.WriteString(greenStyle.Render("[T]erminal") + " " + cyanStyle.Render("- Open a new Alacritty terminal") + "\n")
	b.WriteString(greenStyle.Render("[A]utomatic Updates") + " " + cyanStyle.Render("- Enable automatic updates on boot") + "\n")
	b.WriteString(magentaStyle.Render("Enter your choice: "))
	return b.String()
}

func (m *model) enableAutomaticUpdates() {
	binPath, err := os.Executable()
	if err != nil {
		return
	}
	home := os.Getenv("HOME")
	autoScriptPath := filepath.Join(home, ".hackeros/auto-update.sh")
	script := fmt.Sprintf(`#!/bin/bash
	while ! ping -c 1 google.com &> /dev/null; do
		sleep 5
		done
		%s`, binPath)
	if err := os.WriteFile(autoScriptPath, []byte(script), 0755); err != nil {
		return
	}
	out, err := exec.Command("crontab", "-l").CombinedOutput()
	currentCrontab := string(out)
	if err != nil && !strings.Contains(err.Error(), "exit status 1") {
		return
	}
	entry := "@reboot " + autoScriptPath
	if !strings.Contains(currentCrontab, entry) {
		newCrontab := currentCrontab + "\n" + entry + "\n"
		tmpPath := "/tmp/crontab.txt"
		if err := os.WriteFile(tmpPath, []byte(newCrontab), 0644); err != nil {
			return
		}
		exec.Command("crontab", tmpPath).Run()
		os.Remove(tmpPath)
	}
}

func main() {
	p := tea.NewProgram(New(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}
}
