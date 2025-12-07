package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"

	"github.com/pterm/pterm"
	"github.com/vbauerster/mpb/v8"
	"github.com/vbauerster/mpb/v8/decor"
	"golang.org/x/term"
)

const (
	HackerOSUpdateScript   = "/usr/share/HackerOS/Scripts/Bin/update-hackeros.sh"
	WallpapersUpdateScript = "/usr/share/HackerOS/Scripts/Bin/update-wallpapers.sh"
)

var (
	binPath        string
	AutoScriptPath = filepath.Join(os.Getenv("HOME"), ".hackeros/auto-update.sh")
	blueStyle      = pterm.NewStyle(pterm.FgBlue)
	redStyle       = pterm.NewStyle(pterm.FgRed)
	yellowStyle    = pterm.NewStyle(pterm.FgYellow)
	greenStyle     = pterm.NewStyle(pterm.FgGreen)
	cyanStyle      = pterm.NewStyle(pterm.FgCyan)
	magentaStyle   = pterm.NewStyle(pterm.FgMagenta)
)

func displayHeader(title string) {
	pterm.DefaultHeader.WithBackgroundStyle(pterm.NewStyle(pterm.BgYellow)).WithTextStyle(pterm.NewStyle(pterm.FgBlack)).Println(title)
}

func runCommand(cmdStr string) (bool, string) {
	cmd := exec.Command("bash", "-c", cmdStr)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	return err == nil, ""
}

func getStatus(success bool) string {
	if success {
		return blueStyle.Sprint("COMPLETE")
	}
	return redStyle.Sprint("FAILED")
}

func runCommandWithProgress(cmdStr, name string, progress *mpb.Progress) bool {
	bar := progress.AddBar(100,
			       mpb.PrependDecorators(
				       decor.Name(name, decor.WC{C: decor.DSyncWidthR}),
						     decor.Percentage(decor.WCSyncSpace),
			       ),
			mpb.AppendDecorators(
				decor.OnComplete(decor.Name("done"), "done"),
			),
			mpb.BarFillerOnComplete("✓"),
	)

	cmd := exec.Command("bash", "-c", cmdStr)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		bar.Abort(false)
		return false
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		bar.Abort(false)
		return false
	}
	cmd.Stdin = os.Stdin

	if err := cmd.Start(); err != nil {
		bar.Abort(false)
		return false
	}

	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := scanner.Text()
			fmt.Println(line)
			updateProgressFromLine(line, bar)
		}
	}()

	go func() {
		defer wg.Done()
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			line := scanner.Text()
			fmt.Println(line)
			updateProgressFromLine(line, bar)
		}
	}()

	wg.Wait()
	err = cmd.Wait()
	if err == nil {
		bar.SetCurrent(100)
		return true
	} else {
		bar.Abort(false)
		return false
	}
}

func updateProgressFromLine(line string, bar *mpb.Bar) {
	// Parse % patterns
	rePercent := regexp.MustCompile(`(\d+)%`)
	match := rePercent.FindStringSubmatch(line)
	if len(match) > 1 {
		perc, err := strconv.ParseInt(match[1], 10, 64)
		if err == nil {
			bar.SetCurrent(perc)
		}
	}

	// Parse step patterns like 1/10
	reStep := regexp.MustCompile(`(\d+)/(\d+)`)
	matchStep := reStep.FindStringSubmatch(line)
	if len(matchStep) > 2 {
		curr, _ := strconv.ParseInt(matchStep[1], 10, 64)
		total, _ := strconv.ParseInt(matchStep[2], 10, 64)
		if total > 0 {
			bar.SetCurrent((curr * 100) / total)
		}
	}
}

func performUpdates(progress *mpb.Progress) (string, string, string, string, string, string, string, string) {
	// APT Update
	displayHeader("System Update")
	aptSuccess := true
	aptSuccess = aptSuccess && runCommandWithProgress("sudo apt update", "APT Update", progress)
	aptSuccess = aptSuccess && runCommandWithProgress("sudo apt upgrade -y", "APT Upgrade", progress)
	aptSuccess = aptSuccess && runCommandWithProgress("sudo apt autoclean", "APT Autoclean", progress)
	aptStatus := getStatus(aptSuccess)

	// Flatpak Update
	displayHeader("Flatpak Update")
	flatpakSuccess := runCommandWithProgress("flatpak update -y", "Flatpak Update", progress)
	flatpakStatus := getStatus(flatpakSuccess)

	// Snap Update
	displayHeader("Snap Update")
	snapSuccess := runCommandWithProgress("sudo snap refresh", "Snap Update", progress)
	snapStatus := getStatus(snapSuccess)

	// Firmware Update
	displayHeader("Firmware Update")
	fwSuccess := runCommandWithProgress("sudo fwupdmgr update", "Firmware Update", progress)
	fwStatus := getStatus(fwSuccess)

	// Oh My Zsh Update
	displayHeader("Oh My Zsh Update")
	omzSuccess := runCommandWithProgress("omz update", "Oh My Zsh Update", progress)
	omzStatus := getStatus(omzSuccess)

	// Distrobox Update
	displayHeader("Distrobox Update")
	distroboxSuccess := runCommandWithProgress("distrobox-upgrade --all", "Distrobox Update", progress)
	distroboxStatus := getStatus(distroboxSuccess)

	// HackerOS Update
	displayHeader("HackerOS Update")
	hackerSuccess, _ := runCommand(HackerOSUpdateScript)
	hackerStatus := getStatus(hackerSuccess)

	// Wallpapers Update
	displayHeader("Wallpaper Updates")
	wallSuccess, _ := runCommand(WallpapersUpdateScript)
	wallStatus := getStatus(wallSuccess)

	return aptStatus, flatpakStatus, snapStatus, fwStatus, omzStatus, distroboxStatus, hackerStatus, wallStatus
}

func showSummary(aptStatus, flatpakStatus, snapStatus, fwStatus, omzStatus, distroboxStatus, hackerStatus, wallStatus string) {
	data := [][]string{
		{"System Updates", aptStatus},
		{"Flatpak Updates", flatpakStatus},
		{"Snap Updates", snapStatus},
		{"Firmware Updates", fwStatus},
		{"Oh My Zsh Updates", omzStatus},
		{"Distrobox Updates", distroboxStatus},
		{"HackerOS Updates", hackerStatus},
		{"Wallpaper Updates", wallStatus},
	}
	pterm.DefaultTable.WithHasHeader(false).WithData(data).Render()
}

func enableAutomaticUpdates() {
	autoScript := fmt.Sprintf(`#!/bin/bash
	while ! ping -c 1 google.com &> /dev/null; do
		sleep 5
		done
		%s`, binPath)
	os.WriteFile(AutoScriptPath, []byte(autoScript), 0755)

	currentCrontab := getCrontab()
	entry := fmt.Sprintf("@reboot %s", AutoScriptPath)
	if !strings.Contains(currentCrontab, entry) {
		newCrontab := currentCrontab + "\n" + entry + "\n"
		setCrontab(newCrontab)
	}
	pterm.Println(greenStyle.Sprint("Automatic updates enabled."))
}

func disableAutomaticUpdates() {
	currentCrontab := getCrontab()
	lines := strings.Split(currentCrontab, "\n")
	var newLines []string
	entry := fmt.Sprintf("@reboot %s", AutoScriptPath)
	for _, line := range lines {
		if !strings.Contains(line, entry) {
			newLines = append(newLines, line)
		}
	}
	newCrontab := strings.Join(newLines, "\n")
	setCrontab(newCrontab)
	os.Remove(AutoScriptPath)
	pterm.Println(greenStyle.Sprint("Automatic updates disabled."))
}

func getCrontab() string {
	cmd := exec.Command("crontab", "-l")
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	return string(out)
}

func setCrontab(content string) {
	tmpFile := "/tmp/crontab.txt"
	os.WriteFile(tmpFile, []byte(content), 0644)
	runCommand(fmt.Sprintf("crontab %s", tmpFile))
	os.Remove(tmpFile)
}

func showGuiMenu() {
	for {
		pterm.Println(yellowStyle.Sprint("=== HackerOS Updater Menu ==="))
		pterm.Println(greenStyle.Sprint("[Q]uit") + " " + cyanStyle.Sprint("- Close this terminal"))
		pterm.Println(greenStyle.Sprint("[R]eboot") + " " + cyanStyle.Sprint("- Reboot the system"))
		pterm.Println(greenStyle.Sprint("[S]hutdown") + " " + cyanStyle.Sprint("- Shutdown the system"))
		pterm.Println(greenStyle.Sprint("[L]og out") + " " + cyanStyle.Sprint("- Log out from current session"))
		pterm.Println(greenStyle.Sprint("[T]erminal") + " " + cyanStyle.Sprint("- Open a new Alacritty terminal"))
		pterm.Println(greenStyle.Sprint("[A]utomatic Updates") + " " + cyanStyle.Sprint("- Enable automatic updates on boot"))
		pterm.Print(magentaStyle.Sprint("Enter your choice: "))

		oldState, err := term.MakeRaw(int(os.Stdin.Fd()))
		if err != nil {
			fmt.Println(err)
			return
		}
		defer term.Restore(int(os.Stdin.Fd()), oldState)

		byteBuf := make([]byte, 1)
		_, err = os.Stdin.Read(byteBuf)
		if err != nil && err != io.EOF {
			fmt.Println(err)
			return
		}
		choice := strings.ToUpper(string(byteBuf[0]))
		fmt.Println(choice)

		switch choice {
			case "Q":
				os.Exit(0)
			case "R":
				runCommand("sudo reboot")
			case "S":
				runCommand("sudo shutdown -h now")
			case "L":
				runCommand("qdbus org.kde.ksmserver /KSMServer logout 0 0 0")
			case "T":
				exec.Command("alacritty").Start()
			case "A":
				enableAutomaticUpdates()
			default:
				pterm.Println(redStyle.Sprint("Invalid choice. Try again."))
		}
	}
}

func main() {
	var withGui bool
	var guiMode bool
	flag.BoolVar(&withGui, "with-gui", false, "Run in GUI mode with Alacritty")
	flag.BoolVar(&guiMode, "gui-mode", false, "Internal GUI mode")
	flag.Parse()

	var err error
	binPath, err = os.Executable()
	if err != nil {
		pterm.Fatal.Println("Failed to get executable path:", err)
	}

	if withGui {
		exec.Command("alacritty", "-e", binPath, "--gui-mode").Start()
		return
	}

	progress := mpb.New()
	aptStatus, flatpakStatus, snapStatus, fwStatus, omzStatus, distroboxStatus, hackerStatus, wallStatus := performUpdates(progress)
	progress.Wait()

	showSummary(aptStatus, flatpakStatus, snapStatus, fwStatus, omzStatus, distroboxStatus, hackerStatus, wallStatus)

	if guiMode {
		showGuiMenu()
	}
}

