# dotfiles

Portable zsh-Konfiguration für macOS, Linux, WSL2 und Termux.

## Features

Dateisuche, Verzeichnislisting, Baum-Ansicht, Metadaten, farbiges Cat —
alles als Kurzbefehle, die auf allen Plattformen identisch laufen.

## Installation

Ablauf: **1.** Pakete (je nach OS) → **2.** Oh My Zsh + Repo (alle) → **3.** Plugin (nicht macOS) → **4.** Neustart.

### 1. Pakete

#### macOS

```bash
brew install mdcat jq pygments tree fd fzf ripgrep zsh-autosuggestions zsh-history-substring-search
```

#### Debian / Ubuntu / WSL2

```bash
sudo apt install zsh git curl tree jq python3-pygments fd-find fzf ripgrep
```

Ohne sudo-Rechte: `su -` und die Befehle als root ausführen.

#### Termux

```bash
pkg install zsh git curl tree jq python fd ripgrep fzf
chsh -s zsh
```

### 2. Oh My Zsh + Repo (alle Plattformen)

```bash
RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/00vez/dotfiles.git ~/dotfiles
cd ~/dotfiles
ln -sfn "$PWD/.zshrc" ~/.zshrc
```

Der Symlink braucht einen **absoluten** Pfad. Ein relatives Ziel wie `ln -sf .zshrc ~/.zshrc` erzeugt eine Schleife ("Too many levels of symbolic links").
Existiert `~/.oh-my-zsh` schon, bricht der Installer ab. Das ist unproblematisch, einfach überspringen.

### 3. History-Substring-Search (Linux, WSL2, Termux)

Auf macOS entfällt der Schritt, `brew` hat das Plugin bereits installiert.

```bash
git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search.git \
  ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search
```

### 4. Neu starten

```bash
exec zsh -l
```

Fehlt ein Tool, meldet `f`, `t`, `i`, `catm` den passenden Install-Befehl für dein OS.

## Befehle (zsh)

| Befehl | Typ | Beschreibung |
|--------|-----|--------------|
| `f <args>` | Funktion | Dateisuche ohne versteckte Dateien |
| `ff <args>` | Funktion | Wie `f`, inkl. versteckter Dateien |
| `ll [dir]` | Funktion | Verzeichnislisting mit Größe, Datum, Farbe |
| `t [dir]` | Funktion | `tree`-Ansicht, ignoriert `.git`, `node_modules`, `venv`, Build-Dirs |
| `i <pfad>` | Funktion | Metadaten: Typ, Größe, Rechte, Owner, mtime/ctime |
| `catmd <datei>` | Funktion | Markdown/JSON/YAML farbig via `less` |
| `catm <datei>` | Funktion | Wie `catmd`, ohne Pager |
| `py` | Alias | `python3` |
| `reload` | Alias | `source ~/.zshrc` |
| `cl` | Alias | `clear` |
| `cc` | Alias | `claude` (separat installieren) |

### `f` / `ff` — Argumente

| Argument | Bedeutung |
|----------|-----------|
| `<name>` | Dateiname enthält `name` (case-insensitive, mehrere = UND) |
| `.ext` | nur diese Endung (mehrere = ODER) |
| `dir/` | nur in diesem Verzeichnis suchen |
| `,text` | Inhalt enthält `text` (case-insensitive) |
| `,,text` | Inhalt enthält `text` (case-sensitive) |
| `*` | nur Verzeichnisse anzeigen |
| `*N` | max. N Treffer (`*0` = unbegrenzt) |
| `:N` | maximale Suchtiefe |
| `-N` | N Zeilen Kontext um Content-Treffer |
| `-v` | zeigt äquivalenten `rg`/`grep`-Befehl |

Beispiele: `f .py`, `f ,TODO`, `f .py ,def main src/`, `f test *20`, `f ,TODO -2`.

`f`/`ff` sind `noglob` – `*` und Klammern nicht escapen.
Default-Limit bei Content-Suche: 200 (mit `*0` abschaltbar).

### Sortierung

`txt > md > exec > Bild > Video > Code > Rest`, innerhalb einer Kategorie neueste zuerst.

## Befehle (PowerShell, Windows)

`Microsoft.PowerShell_profile.ps1` deckt die Suche in pwsh 7 ab.
Komma quoten: `f ',text'` — der PowerShell-Parser liest `,` sonst als Array-Operator.

| Befehl | Beschreibung |
|--------|--------------|
| `f` / `ff` | Suche wie zsh |
| `t` / `ll` / `l` | Baum / Listing / Kurzlisting |
| `i` | Metadaten |
| `catm` / `catmd` | farbiges Cat ohne/mit Pager |
| `..` `...` `....` | 1/2/3 Ebenen hoch |

## Hinweise

- **Reload** nach Edits: `reload`.
- **Theme:** `robbyrussell`. Andere Themes in `~/.oh-my-zsh/custom/themes/` + `ZSH_THEME` in `.zshrc`.
- **Zeilenenden:** `.zshrc` muss LF sein — `.gitattributes` erzwingt das.
- **Private PowerShell-Helpers** (`tn`, `oc`, `hardfetch` …) sind nicht portabel und nur in der Vollvariante der `.ps1`.
- **Prompt-Name:** `echo foo > ~/.zshrc.local` setzt `foo` (magenta) vor das `➜`. Datei leer oder fehlend = Standard-robbyrussell. Liegt außerhalb des Repos.
