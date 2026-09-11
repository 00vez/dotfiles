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
| `f` | Funktion `_ff_impl` | Dateisuche: `f <pattern> [.ext] [dir/] [*] [*N] [,text] [=text] [-N] [+N] [:N]` (ohne versteckte) |
| `ff` | Funktion `_ff_impl` | Wie `f`, inklusive versteckter Dateien |
| `ll [dir]` | Funktion | Verzeichnisinhalt mit Größe + Datum, farbig nach Typ |
| `t [dir]` | Funktion | `tree`-Ansicht, ignoriert `.git`, `node_modules`, `venv`, Build-Dirs etc. |
| `i [pfad]` | Funktion | Metadaten: Typ, Größe, Rechte, Owner, mtime/ctime |
| `py` | `python3` | Python 3 Aufruf |
| `reload` | `source ~/.zshrc` | Config neu laden |
| `cl` | `clear` | Terminal leeren |
| `cc` | `claude` | Claude-CLI (separat installieren) |
| `catmd <datei>` | Funktion | Markdown/JSON/YAML farbig via `less` (mdcat/jq/pygmentize) |
| `catm <datei>` | Funktion | Wie `catmd`, aber ohne Pager |

`f`/`ff` Syntax im Detail:

- `<pattern>` – Namenssuche (case-insensitive, `*` erlaubt)
- `.<ext>` – nur diese Endung (mehrere kombinierbar)
- `,text` – Datei MUSS `text` enthalten (Pflicht-Inhalt)
- `=text` – Datei enthält `text` optional (wird als `[tag]` angezeigt)
- `-N` / `+N` – `N` Zeilen Kontext vor/nach Treffer
- `*` – nur Verzeichnisse (nicht mit `,text`/`=text` kombinierbar)
- `*N` – nur erste N Ergebnisse (Count zählt Angezeigte)
- `dir/` oder `.` – Durchsucht nur dieses Verzeichnis
- `:N` – maximale Suchtiefe ab Suchroot
- Sortierung: txt > md > ausführbar > Bild > Video > bekannt (neueste zuerst), Rest alphabetisch

---

## Abhängigkeiten (zusätzlich zu installieren)

Die `.zshrc` setzt folgende externe Tools voraus. Fehlt ein **erforderliches**
Tool, gibt die entsprechende Funktion einen Fehler aus und nennt den passenden
Installationsbefehl für dein Betriebssystem (macOS → `brew`, Linux/WSL2 → `apt`
bzw. Linuxbrew). Optionale Features (z. B. die Oh-My-Zsh-Plugins) geben nur
einen Hinweis aus, die Shell startet trotzdem.

| Tool | Pflicht? | Wird genutzt von | Installation |
|------|----------|------------------|--------------|
| `mdcat` | ja (Markdown in `catmd`/`catm`) | `catmd`, `catm` | macOS: `brew install mdcat` · Linux/WSL2: `brew install mdcat` (Linuxbrew) bzw. `cargo install mdcat` |
| `jq` | ja (JSON in `catmd`/`catm`) | `catmd`, `catm` | `brew install jq` bzw. `sudo apt install jq` |
| `pygments` (binary `pygmentize`) | ja (YAML in `catmd`/`catm`) | `catmd`, `catm` | `brew install pygments` bzw. `sudo apt install python3-pygments` |
| `tree` | ja (`t`) | `t` | `brew install tree` bzw. `sudo apt install tree` |
| `python3` | ja (`i`) | `i` | macOS: in CLT enthalten · Linux: `sudo apt install python3` |
| `fd` | nein (`fzf`-Default, optional) | `fzf`-Default-Command | macOS/Linux (brew): `brew install fd`. Debian/Ubuntu (apt) liefert die Binary als **`fdfind`** – die `.zshrc` erkennt beide automatisch |
| `fzf` | nein | History-Substring-Search, Default-Command | `brew install fzf` + Integration (`opt/fzf/install`) |
| `zsh-autosuggestions` | nein (Hinweis bei Fehlen) | Autosuggest im Prompt | brew: `brew install zsh-autosuggestions` **oder** apt: `sudo apt install zsh-autosuggestions` |
| `zsh-history-substring-search` | nein (Hinweis bei Fehlen) | Pfeil-hoch/runter History | brew: `brew install zsh-history-substring-search` **oder** apt: `sudo apt install zsh-history-substring-search` |

### Optional

| Tool | Wird genutzt von | Installation |
|------|------------------|--------------|
| `pyenv` | Python-Versionierung (automatisch geladen, falls vorhanden) | `brew install pyenv` |
| `claude` | Alias `cc` | `npm install -g @anthropic-ai/claude-code` |

---

## Hinweise

- Die Config ist bewusst portabel gehalten: private Pfade (z. B. ein
  projektspezifisches Oh-My-Zsh-Plugin) sind entfernt. Eigene Plugins/Themes
  bindest du über `ZSH_CUSTOM` ein (siehe Kopf der `.zshrc`).
- `EDITOR` ist auf `code --wait` gesetzt, sofern `code` im PATH ist, sonst
  automatisch auf `vim` zurückfallend. Anpassen in der `.zshrc` (z. B.
  `export EDITOR="nano"`).

## Plattform-Unterstützung (einheitlich)

Getestet und identisch laufend auf:

- **macOS Apple Silicon** (`/opt/homebrew`) und **macOS Intel** (`/usr/local`)
- **Linux** (native) und **WSL2** (Ubuntu 24.04, GNU-Userland)

Dafür ist die Config so gebaut:

- **Eine Datei für alle drei OS.** Am Anfang erkennt `case "$(uname -r)"` bzw.
  `$OSTYPE` das System (`macos` / `linux` / `wsl`). Diese Variable `$OS` steuert
  u. a. die Installationshinweise. Optional kann man OS-spezifisches in
  `~/.zshrc.$OS` auslagern und via `[[ -f ~/.zshrc.$OS ]] && source ~/.zshrc.$OS`
  einbinden – die Hauptdatei bleibt für die gemeinsamen Aliases/Functions.
- **Fehlende Pflicht-Tools → Fehler mit OS-Install-Hinweis.** Der Helper
  `_require <tool>` prüft via `command -v`; fehlt das Tool, kommt ein Fehler
  mit dem passenden Befehl (`brew install …` auf macOS, `sudo apt install …`
  bzw. Linuxbrew auf Linux/WSL2). `catmd`/`catm` (mdcat/jq/pygmentize), `t`
  (tree) und `i` (python3) nutzen das. Optionale Features (Oh-My-Zsh-Plugins)
  geben nur einen `_warn_tool`-Hinweis, ohne die Shell zu blockieren.
- **Kein BSD-/GNU-`stat`-Split mehr.** Alle Metadaten kommen aus `zstat`
  (zsh-Builtin, `zsh/stat`), das auf allen Plattformen identisch formatiert.
  Früher nutzte die `.zshrc` `stat -f` (BSD/macOS) – das bricht unter Linux/WSL2,
  wo `stat` GNU-Syntax (`-c`) erwartet.
- **Portable History-Completion.** `_history_commands` nutzt `tac` (GNU/Linux)
  bzw. `tail -r` (macOS) – `tail -r` allein würde unter Linux/WSL2 abbrechen.
- **PATH automatisch plattformgerecht**: Apple-Silicon-, Intel- und
  Linuxbrew-Pfade werden je nach Vorhandensein ergänzt – keine manuelle
  `brew shellenv`-Voraussetzung nötig (empfohlen bleibt sie trotzdem).
- **Plugins unabhängig von der Installationsart**: `zsh-autosuggestions` und
  `zsh-history-substring-search` werden via brew (`$HOMEBREW_PREFIX/share/...`)
  **oder** apt (`/usr/share/...`) geladen – je nachdem, was existiert.
- **`fd` vs. `fdfind`**: Debian/Ubuntu liefert `fd` als `fdfind`; beide werden
  für den `fzf`-Default-Command erkannt.
- **Zeilenenden**: Die `.zshrc` muss LF sein (CRLF lässt zsh mit
  `no such option: EQUALS^M` abstürzen). `.gitattributes` erzwingt `eol=lf`,
  sodass ein Klon auf jedem OS korrekt ausgeliefert wird.
- `i` zeigt `Modified`/`Changed` (mtime/ctime). Die macOS-only "Birth"-Zeit
  (`stat %SB`) ist entfernt, weil sie unter Linux/GNU nicht portabel verfügbar
  ist.
