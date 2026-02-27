# =============================================
# HackerOS CLI Build System
# =============================================
# Uruchom:
#   make          → zbuduj wszystko
#   sudo make install → zainstaluj
#   make clean    → wyczyść

ODIN     := odin
CARGO    := cargo
GO       := go
CRYSTAL  := crystal

# Katalogi źródłowe
HACKER_DIR       := hacker
APT_FRONTED      := apt-fronted
HACKER_REPAIR    := hacker-repair
HACKER_UPDATER   := HackerOS-Updater
HACKER_SHELL     := hacker-shell
HACKER_DOCS      := hacker-docs
HACKER_SELECT    := hacker-select
HACKER_HELP      := hacker-help
UPDATE_SYSTEM    := update-system

# Katalogi docelowe
BUILD_DIR        := bin
HACKEROS_DIR     := $(HOME)/.hackeros/hacker
SYSTEM_BIN       := /usr/bin

.PHONY: all build install clean help

all: build

# ==================== GŁÓWNY BUILD ====================
build: hacker rust go crystal
	@echo "\033[1;32m✓ Wszystko zbudowane pomyślnie!\033[0m"

# ==================== ODIN (główny hacker) ====================
hacker:
	@echo "\033[1;34m→ Buduję hacker (Odin)...\033[0m"
	mkdir -p $(BUILD_DIR)
	cd $(HACKER_DIR) && $(ODIN) build main.odin \
		-file \
		-out:../$(BUILD_DIR)/hacker \
		-release \
		-vet \
		-strict-style \
		-o:none
	@echo "\033[1;32m✓ hacker (Odin) zbudowany\033[0m"

# ==================== RUST (Cargo) ====================
rust: apt-fronted hacker-repair hacker-updater hacker-shell-rust

apt-fronted:
	@echo "\033[1;34m→ Buduję apt-fronted (Rust)...\033[0m"
	cd $(APT_FRONTED) && $(CARGO) build --release
	cp $(APT_FRONTED)/target/release/apt-fronted $(BUILD_DIR)/

hacker-repair:
	@echo "\033[1;34m→ Buduję hacker-repair (Rust)...\033[0m"
	cd $(HACKER_REPAIR) && $(CARGO) build --release
	cp $(HACKER_REPAIR)/target/release/hacker-repair $(BUILD_DIR)/

hacker-updater:
	@echo "\033[1;34m→ Buduję HackerOS-Updater (Rust)...\033[0m"
	cd $(HACKER_UPDATER) && $(CARGO) build --release
	cp $(HACKER_UPDATER)/target/release/HackerOS-Updater $(BUILD_DIR)/

hacker-shell-rust:
	@echo "\033[1;34m→ Buduję hacker-shell (Rust)...\033[0m"
	cd $(HACKER_SHELL) && $(CARGO) build --release || true
	cp $(HACKER_SHELL)/target/release/hacker-shell $(BUILD_DIR)/ 2>/dev/null || true

# ==================== GO ====================
go: hacker-shell-go hacker-docs hacker-select hacker-help

hacker-shell-go:
	@echo "\033[1;34m→ Buduję hacker-shell (Go)...\033[0m"
	cd $(HACKER_SHELL) && $(GO) mod tidy -e || true
	cd $(HACKER_SHELL) && $(GO) build -o ../../$(BUILD_DIR)/hacker-shell -ldflags="-s -w" .

hacker-docs:
	@echo "\033[1;34m→ Buduję hacker-docs (Go)...\033[0m"
	cd $(HACKER_DOCS) && $(GO) build -o ../../$(BUILD_DIR)/hacker-docs -ldflags="-s -w" .

hacker-select:
	@echo "\033[1;34m→ Buduję hacker-select (Go)...\033[0m"
	cd $(HACKER_SELECT) && $(GO) build -o ../../$(BUILD_DIR)/hacker-select -ldflags="-s -w" .

hacker-help:
	@echo "\033[1;34m→ Buduję hacker-help (Go)...\033[0m"
	cd $(HACKER_HELP) && $(GO) build -o ../../$(BUILD_DIR)/hacker-help -ldflags="-s -w" .

# ==================== CRYSTAL ====================
crystal:
	@echo "\033[1;34m→ Buduję update-system (Crystal)...\033[0m"
	cd $(UPDATE_SYSTEM) && $(CRYSTAL) build main.cr --release -o ../../$(BUILD_DIR)/update-system --no-debug

# ==================== INSTALACJA ====================
install: build
	@echo "\033[1;33m→ Instaluję narzędzia HackerOS...\033[0m"
	
	mkdir -p $(HACKEROS_DIR)
	mkdir -p $(SYSTEM_BIN)

	# Główny tool
	install -Dm755 $(BUILD_DIR)/hacker $(SYSTEM_BIN)/hacker

	# Wszystkie wewnętrzne narzędzia
	cp -f $(BUILD_DIR)/* $(HACKEROS_DIR)/ 2>/dev/null || true
	chmod +x $(HACKEROS_DIR)/*

	# Symlinki (dla wygody)
	ln -sf $(HACKEROS_DIR)/hacker-select $(SYSTEM_BIN)/hacker-select 2>/dev/null || true
	ln -sf $(HACKEROS_DIR)/hacker-help    $(SYSTEM_BIN)/hacker-help    2>/dev/null || true
	ln -sf $(HACKEROS_DIR)/hacker-docs    $(SYSTEM_BIN)/hacker-docs    2>/dev/null || true
	ln -sf $(HACKEROS_DIR)/update-system  $(SYSTEM_BIN)/update-system  2>/dev/null || true

	@echo "\033[1;32m✓ Instalacja zakończona!\033[0m"
	@echo "   Uruchom: hacker"

# ==================== CZYSZCZENIE ====================
clean:
	rm -rf $(BUILD_DIR)
	find . -name "target" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.o" -delete 2>/dev/null || true
	@echo "\033[1;32m✓ Wyczyszczono\033[0m"

help:
	@echo "HackerOS Build System"
	@echo ""
	@echo "make              → zbuduj wszystko"
	@echo "make hacker       → tylko Odin"
	@echo "make rust         → wszystkie projekty Rust"
	@echo "make go           → wszystkie projekty Go"
	@echo "make crystal      → update-system (Crystal)"
	@echo "sudo make install → zainstaluj systemowo"
	@echo "make clean        → wyczyść"
