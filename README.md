# dotfiles

Persönliche zsh-Konfiguration: eine `.zshrc` mit durchdachter Dateisuche,
baumäßiger Verzeichnisansicht, Metadaten-Inspektion und farbigem Cat für
Markdown/JSON/YAML.

Features:

- `f` / `ff` – schnelle Dateisuche mit `find` (Name, Endung, Inhalt, Kontext)
- `ll` – Verzeichnisinhalt mit Größe und Datum, farbcodiert nach Typ
- `t` – `tree`-Ansicht, die Build-/Cache-Verzeichnisse ignoriert
- `i` – Metadaten (Typ, Größe, Rechte, Zeitstempel) zu einer Datei/Dir
- `catmd` / `catm` – Markdown/JSON/YAML farbig darstellen (mit Pager bzw. ohne)
- History-Substring-Search und Autosuggestions
- Farbcodierte Completion und smarte Tab-Completion

---

## Voraussetzungen

| Tool | Zweck |
|------|-------|
| `zsh` | Die Shell selbst |
| [Oh My Zsh](https://ohmyz.sh) | Plugin-Framework (lädt die `.zshrc`) |
| [Homebrew](https://brew.sh) | Paketmanager für macOS und Linux (liefert die meisten Tools) |
| `git` | Pflicht-Plugin in der `.zshrc` |

Die `.zshrc` lädt `zsh-autosuggestions` und `zsh-history-substring-search`
direkt aus dem Homebrew-Prefix (`$HOMEBREW_PREFIX/share/...`). Ohne Homebrew
werden diese beiden Features einfach übersprungen – die Config läuft trotzdem.

---

## Installation (macOS)

```bash
# 1. zsh ist auf macOS bereits vorhanden. Oh My Zsh installieren:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 2. Homebrew installieren (falls noch nicht geschehen):
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Abhängige Tools installieren (siehe Abschnitt "Abhängigkeiten"):
brew install mdcat jq pygments fd fzf tree \
  zsh-autosuggestions zsh-history-substring-search

# 4. fzf-Integration nachinstallieren:
"$(brew --prefix)/opt/fzf/install"   # Completion/Key-Bindings, Defaults übernehmen

# 5. Diese dotfiles holen und verlinken:
git clone https://github.com/00vez/dotfiles.git ~/.dotfiles
ln -sf ~/.dotfiles/.zshrc ~/.zshrc

# 6. Übernehmen:
reload        # oder: source ~/.zshrc  /  neue Shell öffnen
```

## Installation (Linux)

```bash
# 1. zsh + git installieren (apt als Beispiel, analog dnf/pacman):
sudo apt update && sudo apt install -y zsh git curl

# 2. Oh My Zsh installieren:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#   (zsh ggf. via `chsh -s $(which zsh)` zur Standardshell machen)

# 3. Homebrew für Linux (Linuxbrew) installieren:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#   Anschließend die in der Ausgabe genannten drei export-Zeilen (~/.zshrc.local
#   oder temporär in die Shell) übernehmen, damit `brew` im PATH liegt:
#   eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 4. Abhängige Tools installieren:
brew install mdcat jq pygments fd fzf tree \
  zsh-autosuggestions zsh-history-substring-search

# 5. fzf-Integration nachinstallieren:
"$(brew --prefix)/opt/fzf/install"

# 6. Diese dotfiles holen und verlinken:
git clone https://github.com/00vez/dotfiles.git ~/.dotfiles
ln -sf ~/.dotfiles/.zshrc ~/.zshrc

# 7. Übernehmen:
reload
```

---

## Aliases & Funktionen (Übersicht)

Alle Suchbefehle sind als `noglob` deklariert – Sternchen und Klammern müssen
also nicht escaped werden.

| Befehl | Ersetzung / Funktion | Kurzbeschreibung |
|--------|----------------------|------------------|
| `f` | Funktion `_ff_impl` | Dateisuche: `f <pattern> [.ext] [,text] [=text] [-N] [+N] [*]` (ohne versteckte) |
| `ff` | Funktion `_ff_impl` | Wie `f`, inklusive versteckter Dateien |
| `ll [dir]` | Funktion | Verzeichnisinhalt mit Größe + Datum, farbig nach Typ |
| `t [dir]` | Funktion | `tree`-Ansicht, ignoriert `.git`, `node_modules`, `venv`, Build-Dirs etc. |
| `i [pfad]` | Funktion | Metadaten: Typ, Größe, Rechte, Owner, mtime/ctime/btime |
| `py` | `python3` | Python 3 Aufruf |
| `reload` | `source ~/.zshrc` | Config neu laden |
| `cl` / `c` | `clear` | Terminal leeren |
| `cc` | `claude` | Claude-CLI (separat installieren) |
| `ccc` | `clang` | C-Compiler (Xcode CLT / LLVM) |
| `catmd <datei>` | Funktion | Markdown/JSON/YAML farbig via `less` (mdcat/jq/pygmentize) |
| `catm <datei>` | Funktion | Wie `catmd`, aber ohne Pager |
| `ssdm` | Alias | CPU- und RAM-Auslastung anzeigen |

`f`/`ff` Syntax im Detail:

- `<pattern>` – Namenssuche (case-insensitive, `*` erlaubt)
- `.<ext>` – nur diese Endung (mehrere kombinierbar)
- `,text` – Datei MUSS `text` enthalten (Pflicht-Inhalt)
- `=text` – Datei enthält `text` optional (wird als `[tag]` angezeigt)
- `-N` / `+N` – `N` Zeilen Kontext vor/nach Treffer
- `*` – nur Verzeichnisse
- `dir/` oder `.` – Durchsucht nur dieses Verzeichnis

---

## Abhängigkeiten (zusätzlich zu installieren)

Die `.zshrc` setzt folgende externe Tools voraus. Fehlen sie, werden die
betroffenen Features einfach übersprungen (die Shell startet trotzdem).

| Tool | Wird genutzt von | Installation |
|------|------------------|--------------|
| `mdcat` | `catmd`, `catm` (Markdown) | `brew install mdcat` |
| `jq` | `catmd`, `catm` (JSON/JSONL) | `brew install jq` |
| `pygments` (binary `pygmentize`) | `catmd`, `catm` (YAML) | `brew install pygments` (oder `pip install pygments`) |
| `fd` | `fzf`-Default-Command, Schnellsuche | `brew install fd` |
| `fzf` | History-Substring-Search, Default-Command | `brew install fzf` + Integration (`opt/fzf/install`) |
| `tree` | `t` | `brew install tree` |
| `zsh-autosuggestions` | Autosuggest im Prompt | `brew install zsh-autosuggestions` |
| `zsh-history-substring-search` | Pfeil-hoch/runter History | `brew install zsh-history-substring-search` |
| `python3` | `i`, `catmd` (YAML via pygmentize) | macOS: in CLT enthalten; Linux: `sudo apt install python3` |

### Optional

| Tool | Wird genutzt von | Installation |
|------|------------------|--------------|
| `pyenv` | Python-Versionierung (automatisch geladen, falls vorhanden) | `brew install pyenv` |
| `clang` | Alias `ccc` | Xcode Command Line Tools / `brew install llvm` |
| `claude` | Alias `cc` | `npm install -g @anthropic-ai/claude-code` |

---

## Hinweise

- Die Config ist bewusst portabel gehalten: private Pfade (z. B. ein
  projektspezifisches Oh-My-Zsh-Plugin) sind entfernt. Eigene Plugins/Themes
  bindest du über `ZSH_CUSTOM` ein (siehe Kopf der `.zshrc`).
- `EDITOR` ist auf `code --wait` gesetzt. Ohne VS Code einfach in der `.zshrc`
  anpassen (z. B. `export EDITOR="vim"`).
- Getestet mit Oh My Zsh auf macOS (Apple Silicon, `/opt/homebrew`) und Linux
  (Linuxbrew, `/home/linuxbrew/.linuxbrew`).
