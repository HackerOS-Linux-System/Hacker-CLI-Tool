package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/viewport"
	"github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ─── Styles ───────────────────────────────────────────────────────────────────

var (
	accent  = lipgloss.Color("#c026d3")
	dimCol  = lipgloss.Color("#475569")
	textCol = lipgloss.Color("#e2e8f0")
	cyan    = lipgloss.Color("#06b6d4")
	green   = lipgloss.Color("#22c55e")
	yellow  = lipgloss.Color("#eab308")
	bg2     = lipgloss.Color("#13131a")
	border  = lipgloss.Color("#2a2a3a")
)

// ─── FAQ entries ──────────────────────────────────────────────────────────────

type FAQ struct {
	Question string
	Answer   string
}

var faqs = []FAQ{
	// ── Ogólne ──
	{
		Question: "Czym jest HackerOS?",
		Answer: `HackerOS to polska dystrybucja Linuksa oparta na Debianie Testing (część edycji na Debianie Stable). Przeznaczona jest dla zwykłych użytkowników, graczy, entuzjastów cyberbezpieczeństwa i deweloperów.

		Filozofia projektu: pełna kontrola użytkownika + przyjazne, gotowe środowisko do pracy i rozrywki.

		Kluczowe cechy:
		• Baza Debian Testing — równowaga między nowoczesnością a stabilnością
		• Domyślne środowisko KDE Plasma (edycja Official)
		• Przeglądarka Vivaldi preinstalowana
		• Własne narzędzia CLI (hacker, lpm, hl, h#, ngt, hedit, hbuild…)
		• Własne gry: StarBlaster, Bit Jump, The Racer, Bark Squadron
		• Obsługa gier Windows przez Proton (~90% gier działa)
		• Ciągły rozwój — wydania co miesiąc

		Strona: https://hackeros-linux-system.github.io/HackerOS-Website/Home-page.html`,
	},
	{
		Question: "Jakie są wymagania sprzętowe?",
		Answer: `Minimalne:
		• Procesor: 2 rdzenie, 1.6 GHz (x86_64 / ARMv8)
		• RAM: 2 GB
		• Dysk: 20 GB
		• Grafika: zintegrowana, rozdzielczość 1024×768
		• Sieć: Ethernet lub Wi-Fi

		Rekomendowane:
		• Procesor: 4+ rdzenie, 2.5 GHz (x86_64 / ARM64)
		• RAM: 8 GB lub więcej
		• Dysk: 50 GB (SSD zalecany)
		• GPU: NVIDIA / AMD / Intel z akceleracją 3D
		• Stabilne łącze internetowe

		Obsługiwane architektury: x86_64 (amd64) — pełne wsparcie.`,
	},
	{
		Question: "Jak zainstalować HackerOS?",
		Answer: `1. Pobierz ISO ze strony:
		https://hackeros-linux-system.github.io/HackerOS-Website/download.html

		2. Stwórz bootowalny nośnik USB:
		• Windows: Rufus
		• Linux: balenaEtcher, Fedora Media Writer lub dd:
		sudo dd if=HackerOS.iso of=/dev/sdX bs=4M status=progress oflag=sync

		3. Uruchom z USB i postępuj zgodnie z instalatorem Calamares.
		Instalator obsługuje dual-boot obok istniejącego systemu.

		Uwaga: zawsze rób backup przed zmianami partycji.`,
	},
	// ── Pakiety i aktualizacje ──
	{
		Question: "Jak instalować i usuwać pakiety?",
		Answer: `HackerOS oferuje kilka sposobów zarządzania pakietami:

		APT (standardowy):
		sudo apt install <pakiet>
		sudo apt remove <pakiet>
		sudo apt update && sudo apt upgrade

		hacker (własny wrapper):
		hacker install <pakiet>
		hacker remove <pakiet>
		hacker update          ← aktualizuje APT + Flatpak + Snap + firmware

		lpm (własny następca apt):
		lpm install <pakiet>
		lpm remove <pakiet>
		lpm update && lpm upgrade

		Flatpak:
		hacker flatpak-install <id>
		hacker flatpak-remove <id>

		Snap:
		sudo snap install <pakiet>

		hacker unpack <zestaw>  ← instaluje gotowe zestawy oprogramowania`,
	},
	{
		Question: "Jak zaktualizować system?",
		Answer: `Zalecana metoda: hacker update

		Aktualizuje jednocześnie:
		• APT (sudo apt update && upgrade)
		• Flatpak
		• Snap
		• Firmware (fwupdmgr)
		• Oh-My-Zsh
		• Distrobox
		• Komponenty HackerOS

		Z graficznym interfejsem:
		hacker update --with-gui   ← otwiera nowe okno Alacritty

		Alternatywnie: aplikacja "Update System" w menu.`,
	},
	// ── Narzędzia hacker ──
	{
		Question: "Jak działa komenda hacker?",
		Answer: `hacker to główne narzędzie CLI HackerOS. Centralny punkt zarządzania systemem.

		Najważniejsze komendy:
		hacker help              — lista wszystkich komend
		hacker help-ui           — interaktywne TUI z wyszukiwarką
		hacker docs              — ta dokumentacja (FAQ)
		hacker update            — aktualizacja systemu
		hacker install <pkg>     — instalacja pakietu APT
		hacker unpack <zestaw>   — instalacja zestawu oprogramowania
		hacker pack <zestaw>     — usunięcie zestawu
		hacker env create <.hk>  — tworzenie środowiska kontenerowego
		hacker languages         — info o językach programowania HackerOS
		hacker settings look     — zmiana schematu kolorów CLI
		hacker doctor            — diagnostyka systemu
		hacker interactive       — interaktywna powłoka TUI
		hacker game              — tekstowa gra przygodowa

		Pełna dokumentacja: https://hackeros-linux-system.github.io/HackerOS-Website/tools-docs/hacker.html`,
	},
	{
		Question: "Co to są zestawy hacker unpack?",
		Answer: `hacker unpack instaluje gotowe grupy powiązanego oprogramowania jedną komendą.

		Dostępne zestawy:
		add-ons          — Wine, BoxBuddy, WineZGUI, GearLever
		gaming           — Steam, Heroic, ProtonPlus, Protontricks, Varia
		gaming with-roblox — jak gaming + Sober i Vinegar (Roblox)
		devtools         — VS Code, Rust, Go, Node.js, Lua, Zig, Crystal
		emulators        — shadPS4, Ryujinx, DOSBox-X, RPCS3
		cybersecurity    — kontener BlackArch
		h#               — język programowania H# (H-Sharp)
		h#-utils         — narzędzia pomocnicze H# (bytes, vira)
		lpm              — następca apt
		hexai            — AI dla HackerOS (wymaga mocnego sprzętu)
		hackerdeck       — nakładka Waydroid
		hammer           — atomowy menedżer pakietów (edycja Atomic)
		hacker-mode      — tryb gry inspirowany SteamOS

		hacker pack <zestaw> — usuwa zainstalowany zestaw`,
	},
	// ── Środowiska ──
	{
		Question: "Jak zarządzać środowiskami kontenerowymi (hacker env)?",
		Answer: `hacker env tworzy izolowane środowiska oparte na podman/distrobox.

		Tworzenie środowiska z pliku .hk:
		hacker env create ./pentest.hk

		Przykładowy plik pentest.hk:
		[env]
		-> name  => pentest-env
		-> image => fedora:latest
		-> shell => zsh

		[packages]
		-> -> nmap
		-> -> metasploit-framework

		[sync_configs]
		-> -> ~/.zshrc
		-> -> ~/.config/nvim

		Podkomendy:
		hacker env enter <nazwa>    — wejdź do środowiska
		hacker env remove <nazwa>   — usuń środowisko
		hacker env settings         — lista wszystkich środowisk
		hacker env docs             — pełny tutorial

		Środowiska to zwykłe kontenery podman — działają też: distrobox enter, podman exec.`,
	},
	// ── Jądro ──
	{
		Question: "Jak zmienić jądro systemu?",
		Answer: `HackerOS domyślnie używa standardowego jądra Debiana.
		Dostępne alternatywy: XanMod LTS i Liquorix.

		Instalacja za pomocą chker:
		sudo chker xanmod     — jądro XanMod LTS (polecane dla graczy)
		sudo chker liquorix   — jądro Liquorix (starsze urządzenia)

		Po instalacji uruchom ponownie komputer.

		Uwaga: różnica wydajności w grach jest zazwyczaj niewielka.
		Edycja Gaming Old ma wbudowane jądro Liquorix,
		Edycja Gaming New ma wbudowane jądro XanMod LTS.`,
	},
	// ── GPU / sterowniki ──
	{
		Question: "Jak zainstalować sterowniki NVIDIA?",
		Answer: `Metoda 1 — przez hacker (zalecana):
		hacker unpack nvidia-drivers

		Metoda 2 — przez APT:
		sudo apt install nvidia-driver

		Po instalacji wymagany restart systemu.

		HackerOS posiada również dedykowaną edycję NVIDIA z preinstalowanymi sterownikami.
		Edycja NVIDIA oparta jest na Debianie Testing — identyczna z Official, ale ze sterownikami.

		Usunięcie sterowników:
		hacker pack nvidia-drivers`,
	},
	// ── Języki programowania ──
	{
		Question: "Czym jest Hacker Lang?",
		Answer: `Hacker Lang to własny język skryptowy HackerOS — wydajna alternatywa dla powłoki bash/zsh.

		Posiada własną interaktywną powłokę (uruchom: hl bez argumentów).

		Składnia — operatory prefiksowe:
		>    — zwykła komenda systemowa
		>>   — komenda ze zmiennymi
		>>>  — komenda jako oddzielny proces
		&    — komenda w tle (background)
		^    — wymuszenie sudo (modyfikator)
		!!   — komentarz blokowy
		\\   — ładowanie pluginu

		Typy danych: int, bool, str, list [a,b], dict {k:v}
		Zmienne: @nazwa:typ = wartość (globalne), $nazwa:typ = wartość (lokalne)

		Struktury sterujące:
		=N > komenda       — pętla N razy
		?warunek > komenda — warunek (if/then/fi)
		%lista > komenda   — foreach
		T> try C> catch F> finally

		Narzędzia CLI:
		hl       — kompiluj/uruchamiaj pliki .hk/.hacker
		hli      — interaktywny interfejs (hacker unpack hl-utils)
		bytes    — manager bibliotek Hacker Lang
		hlh      — dokumentacja CLI

		Dokumentacja: https://hackeros-linux-system.github.io/HackerOS-Website/hacker-lang/docs.html`,
	},
	{
		Question: "Czym jest H# (H-Sharp)?",
		Answer: `H# (H-Sharp) to w pełni funkcjonalny język programowania ogólnego przeznaczenia stworzony dla ekosystemu HackerOS.

		Wyróżnia się zaawansowanym systemem extern — bezproblemowa integracja z bibliotekami zewnętrznymi (C, Rust i inne).
		Nadaje się zarówno do dużych projektów, jak i krótkich skryptów.

		Tryby uruchomienia:
		• Kompilowany — natywny kod binarny (najlepsza wydajność)
		• Interpretowany JIT — wydajne uruchomienie bez kompilacji
		• Interpretowany (podgląd) — szybki test kodu

		Menedżery pakietów H#:
		bytes — uruchamia kod H# w trybie wydajnym
		vira  — kompiluje do jednej statycznej binarki

		Instalacja:
		hacker unpack h#          — język H#
		hacker unpack h#-utils    — narzędzia (bytes, vira)

		Usuwanie:
		hacker pack h#
		hacker pack h#-utils

		Dokumentacja: https://hackeros-linux-system.github.io/HackerOS-Website/h-sharp/docs.html`,
	},
	// ── Edycje ──
	{
		Question: "Jakie są dostępne edycje HackerOS?",
		Answer: `HackerOS dostępny jest w wielu edycjach:

		OFICJALNE (wydawane co miesiąc):
		Official   — KDE Plasma, dla każdego użytkownika
		Cybersecurity — narzędzia pentestingowe, jądro Xen (jak Qubes OS)
		NVIDIA     — jak Official + preinstalowane sterowniki NVIDIA

		ŚRODOWISKA GRAFICZNE (wydawane przy x.0 i x.5):
		Hydra      — jak Official, motyw inspirowany Garuda Linux
		GNOME      — jak Official ze środowiskiem GNOME
		XFCE       — jak Official ze środowiskiem Xfce
		Blue       — z autorskim środowiskiem graficznym HackerOS (w przyszłości)

		SPECJALNE:
		LTS        — Debian Stable zamiast Testing (co 9 miesięcy, wersje x.0)
		Gaming     — inspirowana SteamOS/Bazzite, tryb gry:
		Old: jądro Liquorix (starsze GPU)
		New: jądro XanMod LTS (nowsze GPU)
		Atomic     — immutable, system plików Btrfs, narzędzie hammer
		UWAGA: aktualnie w fazie pre-release

		Harmonogram wydań:
		Official/Cybersecurity/NVIDIA — co miesiąc
		GNOME/Hydra/XFCE — przy x.0 i x.5
		LTS — co 9 miesięcy (wersje x.0)
		Atomic — brak stałego harmonogramu (intensywny rozwój)`,
	},
	// ── Gaming ──
	{
		Question: "Jak grać w gry na HackerOS?",
		Answer: `HackerOS jest dobrze przystosowany do grania dzięki bazie Debian Testing.

		Instalacja narzędzi do grania:
		hacker unpack gaming       — Steam, Heroic, ProtonPlus, Protontricks, Varia
		hacker unpack gaming with-roblox — jak wyżej + Sober i Vinegar dla Roblox

		Narzędzia do uruchamiania gier Windows:
		Steam + Proton            — główna platforma (~90% gier działa)
		Heroic Games Launcher     — Epic Games Store, GOG, Amazon Prime
		Hacker Launcher           — uruchamianie plików .exe bezpośrednio
		ProtonPlus                — zarządzanie wersjami Proton
		Lutris                    — obsługa wielu bibliotek gier

		Tryby gry:
		Hacker Mode    — sesja Wayland inspirowana gamescope/Steam (hacker unpack hacker-mode)
		Steam GameMode — sesja gamescope-session-steam (hacker unpack gamescope-session-steam)
		HackerOS Game Mode — nakładka optymalizująca system, pokazuje FPS

		Własne gry HackerOS (uruchom przez HackerOS Games):
		StarBlaster   — inspirowana Galaxy Attack (Rust)
		Bit Jump      — inspirowana Geometry Dash (Lua)
		The Racer     — gra wyścigowa (Python)
		Bark Squadron — gra akcji

		Przełączanie trybu gry: hacker switch hacker-mode / hacker switch steam-gamemode
		Gry z anti-cheatem (np. Fortnite) mogą nie działać. Sprawdź: areweanticheatyet.com`,
	},
	// ── Cybersecurity ──
	{
		Question: "Jak używać narzędzi cyberbezpieczeństwa?",
		Answer: `HackerOS oferuje dedykowaną edycję Cybersecurity oraz kontener BlackArch.

		Instalacja kontenera BlackArch:
		hacker unpack cybersecurity

		Wejście do kontenera:
		hacker enter blackarch

		Wewnątrz kontenera dostępne są wszystkie narzędzia BlackArch.

		Dedykowana edycja Cybersecurity zawiera:
		• Narzędzia pentestingowe preinstalowane
		• Jądro Xen (jak w Qubes OS) — izolacja sprzętowa
		• Cybersecurity Mode — sesja z narzędziami bezpieczeństwa
		• Penetration Mode — aplikacja do testów penetracyjnych
		• bph — narzędzie CLI do testów penetracyjnych (edukacyjne)
		• eiq — narzędzie szyfrowania w tle

		UWAGA: Narzędzia przeznaczone wyłącznie do legalnych testów
		i celów edukacyjnych. Używaj odpowiedzialnie.`,
	},
	// ── Diagnostyka ──
	{
		Question: "Jak naprawić problemy z systemem?",
		Answer: `Krok 1: Diagnostyka przez hacker doctor
		hacker doctor
		Przeprowadza automatyczną diagnostykę i umożliwia uruchomienie hacker-repair.

		Krok 2: Narzędzie naprawcze (TUI)
		hacker repair  (tylko po przejściu przez doctor)
		Oferuje: naprawa pakietów APT, GRUB, diagnostyka sieci,
		analiza logów, czyszczenie systemu, snapshoty Timeshift.

		Ręczna naprawa pakietów:
		sudo apt --fix-broken install
		sudo dpkg --configure -a
		sudo apt update

		Logi systemowe:
		hacker system logs         — journalctl -xe
		journalctl -b              — logi z bieżącego rozruchu
		dmesg | less               — logi jądra

		Sieć:
		nmcli device status
		ping 8.8.8.8
		nmtui

		Kontakt:
		hacker issue               — otwiera formularz na GitHub
		Email: hackeros068@gmail.com`,
	},
	// ── Narzędzia dodatkowe ──
	{
		Question: "Jakie narzędzia są wbudowane w HackerOS?",
		Answer: `Narzędzia wbudowane w każdej edycji:
		hacker       — główne CLI (zarządzanie systemem)
		ngt          — menedżer plików TUI (inspirowany mc, GoLang)
		hedit        — edytor tekstu TUI (inspirowany nano, GoLang)
		hbuild       — system budowania (alternatywa dla cmake/meson, Rust)
		hl           — interpreter/kompilator Hacker Lang
		hsh          — własna powłoka (zastępuje bash/zsh)
		hpm          — menedżer pakietów z repozytorium community
		Hacker-Term  — własny terminal HackerOS
		HackerOS-Steam — Steam w izolowanym kontenerze
		Hacker Launcher — uruchamianie gier .exe (Proton)
		HackerOS-Games — launcher gier HackerOS
		HackerOS-Store — sklep aplikacji
		getit        — pobieranie z GitHub/GitLab (zastępuje wget/curl/git)
		chker        — zmiana jądra systemu (Debian → XanMod/Liquorix)
		hpager       — własny pager
		hacker-repair — narzędzie naprawcze TUI (Rust + ratatui)

		Instalowane opcjonalnie:
		lpm          — następca apt (hacker unpack lpm)
		h#           — język programowania H-Sharp (hacker unpack h#)
		hexai        — AI dla HackerOS (hacker unpack hexai)
		hackerdeck   — nakładka Waydroid (hacker unpack hackerdeck)
		hammer       — atomowy menedżer (wbudowany w Atomic)
		anvil        — zarządzanie systemem readonly (wbudowany w Atomic)
		isolator     — pakiety w kontenerach (wbudowany w Atomic)
		bph          — CLI pentesting (wbudowany w Cybersecurity)

		Dokumentacja narzędzi: https://hackeros-linux-system.github.io/HackerOS-Website/tools-docs/index.html`,
	},
	{
		Question: "Co to jest lpm?",
		Answer: `lpm (Legendary Package Manager) to własny następca apt w ekosystemie HackerOS.
		Szybszy i zoptymalizowany pod HackerOS.

		Instalacja:
		hacker unpack lpm

		Użycie:
		lpm install <pakiet>
		lpm remove <pakiet>
		lpm update
		lpm upgrade
		lpm clean
		lpm search <zapytanie>

		Usunięcie:
		hacker pack lpm

		Dokumentacja: https://hackeros-linux-system.github.io/HackerOS-Website/tools-docs/lpm.html`,
	},
	{
		Question: "Co to jest HexAi?",
		Answer: `HexAi to lokalny asystent AI zintegrowany z HackerOS.
		Działa w oparciu o lokalne modele językowe — bez wysyłania danych do chmury.

		Wymagania: mocny sprzęt (GPU z obsługą CUDA/ROCm lub szybki CPU).

		Instalacja:
		hacker unpack hexai

		Usunięcie:
		hacker pack hexai

		Uruchomienie:
		hacker run HexAi   lub bezpośrednio: hexai

		Dokumentacja: https://hackeros-linux-system.github.io/HackerOS-Website/tools-docs/hexai.html`,
	},
	{
		Question: "Jak działa hacker env i pliki .hk?",
		Answer: `Pliki .hk (HackerOS Environment) definiują izolowane środowiska kontenerowe oparte na podman.

		Pełna struktura pliku .hk:
		[env]
		-> name  => nazwa-srodowiska     (wymagane)
		-> image => obraz:tag            (wymagane, np. fedora:latest)
		-> shell => zsh                  (opcjonalne, domyślnie bash)

		[packages]
		-> -> nmap
		-> -> burpsuite
		-> -> wireshark

		[sync_configs]
		-> -> ~/.zshrc
		-> -> ~/.config/nvim
		-> -> ~/.tmux.conf

		[sync_tools]
		-> snap    => ["code"]
		-> flatpak => ["com.brave.Browser"]
		-> system  => ["~/go/bin/gf", "~/go/bin/subfinder"]

		Komendy:
		hacker env create ./plik.hk   — utwórz środowisko
		hacker env enter <nazwa>      — wejdź do środowiska
		hacker env remove <nazwa>     — usuń środowisko
		hacker env settings           — lista środowisk
		hacker env docs               — pełny tutorial

		Środowiska to normalne kontenery podman — hacker add kompatybilny z distrobox.
		Dokumentacja: https://hackeros-linux-system.github.io/HackerOS-Website/tools-docs/hk.html`,
	},
	{
		Question: "Jak personalizować wygląd CLI (hacker settings look)?",
		Answer: `hacker settings look pozwala zmienić schemat kolorów interfejsu CLI.
		Ustawienia zapisywane są w ~/.config/hackeros/hacker/look.json.

		Presety:
		hacker settings look preset default   — domyślny (fiolet)
		hacker settings look preset ocean     — odcienie błękitu
		hacker settings look preset forest    — odcienie zieleni
		hacker settings look preset sunset    — odcienie pomarańczu
		hacker settings look preset mono      — monochromatyczny
		hacker settings look preset hacker    — klasyczny green-on-black

		Własny kolor:
		hacker settings look set accent  #ff6600
		hacker settings look set success #00ff88
		hacker settings look set error   #ff2244
		hacker settings look set warning #ffcc00
		hacker settings look set info    #00ccff
		hacker settings look set dim     #556677

		Podgląd bieżącego schematu:
		hacker settings look show

		Reset do domyślnych:
		hacker settings look reset

		Zmiany wchodzą w życie przy następnym wywołaniu hacker.`,
	},
	{
		Question: "Jak zgłosić błąd lub skontaktować się z zespołem?",
		Answer: `Sposoby kontaktu i zgłaszania błędów:

		1. Przez hacker:
		hacker issue   — otwiera formularz GitHub w przeglądarce

		2. GitHub Issues:
		https://github.com/HackerOS-Linux-System/HackerOS-Website/issues

		3. Email:
		hackeros068@gmail.com

		4. Discord:
		https://discord.com/invite/8yHNcBaEKy

		5. GitHub Discussions:
		https://github.com/orgs/HackerOS-Linux-System/discussions

		Przy zgłaszaniu błędu podaj:
		• Opis problemu krok po kroku
		• Logi (hacker system logs lub journalctl -b)
		• Wersja systemu: hacker info
		• Konfiguracja sprzętowa (CPU, GPU, RAM)

		Śledź HackerOS:
		GitHub: https://github.com/HackerOS-Linux-System
		X/Twitter: https://x.com/hackeros_linux
		Reddit: https://www.reddit.com/r/HackerOS_/
		DistroWatch: https://distrowatch.com/table.php?distribution=hackeros
		Linuxiarze.pl: https://linuxiarze.pl/distro-hackeros/`,
	},
}

// ─── List item ────────────────────────────────────────────────────────────────

type item struct {
	faq FAQ
}

func (i item) Title() string       { return i.faq.Question }
func (i item) Description() string { return "" }
func (i item) FilterValue() string { return i.faq.Question }

// ─── Mode ─────────────────────────────────────────────────────────────────────

type mode int

const (
	listMode mode = iota
	detailsMode
)

// ─── Key map ──────────────────────────────────────────────────────────────────

type keyMap struct {
	quit key.Binding
}

func newKeyMap() *keyMap {
	return &keyMap{
		quit: key.NewBinding(
			key.WithKeys("q", "ctrl+c"),
				     key.WithHelp("q", "wyjdź"),
		),
	}
}

// ─── Model ────────────────────────────────────────────────────────────────────

type model struct {
	list     list.Model
	viewport viewport.Model
	keys     *keyMap
	ready    bool
	mode     mode
	selected int
	width    int
	height   int
}

func newModel() model {
	var items []list.Item
	items = append(items, item{FAQ{Question: "[ Wyjdź ]", Answer: ""}})
	for _, f := range faqs {
		items = append(items, item{f})
	}

	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.
	Foreground(lipgloss.Color("#FF75CB")).
	Bold(true).
	BorderLeftForeground(lipgloss.Color("#c026d3"))
	delegate.Styles.NormalTitle = delegate.Styles.NormalTitle.
	Foreground(lipgloss.Color("#94a3b8"))
	delegate.ShowDescription = false

	l := list.New(items, delegate, 0, 0)
	l.Title = "HackerOS — Dokumentacja & FAQ"
	l.SetShowStatusBar(true)
	l.SetFilteringEnabled(true)
	l.Styles.Title = lipgloss.NewStyle().
	Bold(true).
	Foreground(lipgloss.Color("#c026d3")).
	Padding(0, 1)
	l.SetShowHelp(true)

	vp := viewport.New(0, 0)

	return model{
		list:     l,
		viewport: vp,
		keys:     newKeyMap(),
	}
}

// ─── Init ─────────────────────────────────────────────────────────────────────

func (m model) Init() tea.Cmd {
	return nil
}

// ─── Update ───────────────────────────────────────────────────────────────────

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	switch msg := msg.(type) {
		case tea.WindowSizeMsg:
			m.width = msg.Width
			m.height = msg.Height
			sideW := msg.Width/2 - 2
			if sideW < 30 {
				sideW = 30
			}
			mainW := msg.Width - sideW - 4
			if mainW < 20 {
				mainW = 20
			}
			m.list.SetWidth(sideW)
			m.list.SetHeight(msg.Height - 2)
			m.viewport.Width = mainW - 2
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
						if idx == 0 {
							return m, tea.Quit
						}
						m.selected = idx - 1
						content := renderAnswer(faqs[m.selected].Answer, m.viewport.Width)
						m.viewport.SetContent(content)
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

// renderAnswer formatuje treść odpowiedzi z kolorowaniem
func renderAnswer(answer string, width int) string {
	lines := splitLines(answer)
	var result string
	for _, line := range lines {
		styled := styleLine(line)
		result += styled + "\n"
	}
	return result
}

func splitLines(s string) []string {
	var lines []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' {
			lines = append(lines, s[start:i])
			start = i + 1
		}
	}
	lines = append(lines, s[start:])
	return lines
}

func styleLine(line string) string {
	if len(line) == 0 {
		return line
	}
	// URL-e — cyan
	if len(line) > 4 && (line[0:4] == "http" || containsURL(line)) {
		return lipgloss.NewStyle().Foreground(cyan).Render(line)
	}
	// Nagłówki sekcji (kończy się dwukropkiem, krótka)
	if len(line) < 40 && len(line) > 2 && line[len(line)-1] == ':' && line[0] != ' ' {
		return lipgloss.NewStyle().Foreground(accent).Bold(true).Render(line)
	}
	// Komendy — linie z dwoma spacjami i komendą
	if len(line) > 4 && line[0:2] == "  " && line[2] != ' ' && containsCommand(line) {
		return lipgloss.NewStyle().Foreground(cyan).Render(line)
	}
	// Bullet points z •
	if len(line) > 4 && line[0:2] == "  " && strings.HasPrefix(line[2:], "•") {
		return lipgloss.NewStyle().Foreground(lipgloss.Color("#94a3b8")).Render(line)
	}
	// Ostrzeżenia
	if len(line) > 6 && line[0:6] == "UWAGA:" {
		return lipgloss.NewStyle().Foreground(yellow).Bold(true).Render(line)
	}
	// Normalna linia
	return lipgloss.NewStyle().Foreground(textCol).Render(line)
}

func containsURL(s string) bool {
	return len(s) > 8 && (contains(s, "https://") || contains(s, "http://"))
}

func containsCommand(s string) bool {
	cmds := []string{"hacker ", "sudo ", "apt ", "lpm ", "hl ", "chker ", "nmcli ", "journalctl ", "dmesg ", "dd "}
	for _, c := range cmds {
		if contains(s, c) {
			return true
		}
	}
	return false
}

func contains(s, substr string) bool {
	if len(substr) > len(s) {
		return false
	}
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

// ─── View ─────────────────────────────────────────────────────────────────────

func (m model) View() string {
	if !m.ready {
		return "Inicjalizacja..."
	}

	sideW := m.width/2 - 2
	if sideW < 30 {
		sideW = 30
	}

	// Sidebar
	left := lipgloss.NewStyle().
	Width(sideW+2).
	Border(lipgloss.NormalBorder(), false, true, false, false).
	BorderForeground(border).
	Render(m.list.View())

	// Right panel
	var rightContent string
	if m.mode == detailsMode {
		title := lipgloss.NewStyle().
		Bold(true).
		Foreground(accent).
		Padding(0, 1).
		Render("▌ " + faqs[m.selected].Question)

		hint := lipgloss.NewStyle().
		Foreground(dimCol).
		Render(" Esc — wróć  ·  ↑↓ — przewijaj  ·  q — wyjdź")

		rightContent = lipgloss.JoinVertical(lipgloss.Left,
						     title,
				       lipgloss.NewStyle().Foreground(border).Render(horizontalLine(m.viewport.Width+2)),
						     m.viewport.View(),
						     hint,
		)
	} else {
		rightContent = lipgloss.NewStyle().
		Foreground(dimCol).
		Padding(2, 2).
		Render("Wybierz pytanie z listy, aby wyświetlić odpowiedź.\n\n" +
		"  Enter  — wybierz\n" +
		"  Esc    — wróć\n" +
		"  /      — szukaj\n" +
		"  q      — wyjdź")
	}

	right := lipgloss.NewStyle().
	Width(m.width - sideW - 4).
	Height(m.height - 2).
	Padding(0, 1).
	Render(rightContent)

	return lipgloss.JoinHorizontal(lipgloss.Top, left, right)
}

func horizontalLine(width int) string {
	line := ""
	for i := 0; i < width; i++ {
		line += "─"
	}
	return line
}

// ─── Main ─────────────────────────────────────────────────────────────────────

func main() {
	p := tea.NewProgram(newModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Błąd: %v\n", err)
		os.Exit(1)
	}
}
