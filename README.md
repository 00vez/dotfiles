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
# 1. zsh ist auf macOS bereits vorinstalliert. Prüfen statt blind installieren:
zsh --version          # erwartet: zsh 5.9 (x86_64-apple-darwin...)
command -v zsh         # erwartet: /bin/zsh
#
# 2. Oh My Zsh installieren:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 3. Homebrew installieren (falls noch nicht geschehen):
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#   Apple Silicon: beim ersten Start von brew die angezeigten export-Zeilen
#   in ~/.zprofile übernehmen, sonst landet brew nicht im PATH.

# 4. Abhängige Tools installieren (siehe Abschnitt "Abhängigkeiten"):
brew install mdcat jq pygments fd fzf tree \
  zsh-autosuggestions zsh-history-substring-search

# 5. fzf-Integration nachinstallieren:
"$(brew --prefix)/opt/fzf/install"   # Completion/Key-Bindings, Defaults übernehmen

# 6. Diese dotfiles holen und verlinken:
git clone https://github.com/00vez/dotfiles.git ~/.dotfiles
ln -sf ~/.dotfiles/.zshrc ~/.zshrc

# 7. Übernehmen:
reload        # oder: source ~/.zshrc  /  neue Shell öffnen
```

## Installation (Linux)

```bash
# 1. zsh, git und curl installieren. Paketnamen hängen von der Distro ab:
#
#    Debian / Ubuntu / Mint
sudo apt update && sudo apt install -y zsh git curl
#
#    Fedora / RHEL / Rocky
#    sudo dnf install -y zsh git curl
#
#    Arch / Manjaro
#    sudo pacman -S --needed zsh git curl
#
#    openSUSE
#    sudo zypper install zsh git curl

# 2. Prüfen:
zsh --version          # erwartet: zsh 5.9 (x86_64-...)
command -v zsh         # erwartet: /usr/bin/zsh

# 3. Oh My Zsh installieren:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 4. zsh zur Standard-Shell machen. Ohne das startet die Login-Shell weiter bash,
#    auch wenn die dotfiles geladen sind:
chsh -s "$(command -v zsh)"
#    Wirkt erst nach Abmelden und neu Anmelden. Prüfen mit:  echo $SHELL

# 5. Abhängige Tools. Variante A - Systempaketmanager (empfohlen, kein brew nötig):
sudo apt install -y tree jq fzf python3-pygments fd-find ripgrep
sudo apt install -y zsh-autosuggestions
#   Achtung Debian/Ubuntu: das Paket heisst fd-find, die Binary danach fdfind.
#   Die .zshrc erkennt beide Namen automatisch.
#   Markdown: cargo install mdcat   (alternativ via brew, siehe Variante B)
#   Für zsh-history-substring-search gibt es unter Debian/Ubuntu 24.04 KEIN
#   apt-Paket - stattdessen aus dem Repo klonen:
git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search.git \
  ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search
#
#   Variante B - Linuxbrew, falls du dieselben Paketnamen wie auf macOS willst:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#   Anschließend die in der Ausgabe genannten export-Zeilen übernehmen,
#   damit brew im PATH liegt:
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"   # in ~/.zshrc eintragen
brew install mdcat jq pygments fd fzf tree \
  zsh-autosuggestions zsh-history-substring-search

# 6. fzf-Integration nachinstallieren:
"$(brew --prefix)/opt/fzf/install"

# 7. Diese dotfiles holen und verlinken:
git clone https://github.com/00vez/dotfiles.git ~/.dotfiles
ln -sf ~/.dotfiles/.zshrc ~/.zshrc

# 8. Übernehmen:
reload
```

---

## Installation (WSL2)

WSL2 ist unter Windows die empfohlene Variante, wenn du die vollständigen
zsh-Features willst. Das PowerShell-Profil deckt nur die Suchbefehle ab --
History-Substring-Search und Autosuggestions gibt es dort nicht.

```bash
# Alles läuft in der WSL-Shell, nicht in PowerShell.
sudo apt update
sudo apt install -y zsh git curl
zsh --version                    # Prüfen

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
chsh -s "$(command -v zsh)"      # Wirkt erst nach neuer Sitzung

git clone https://github.com/00vez/dotfiles.git ~/.dotfiles
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
reload
```

**Windows Terminal:** Für jede Sitzung direkt in zsh starten – unter
*Einstellungen -> Start-Programm* beim WSL-Profil eintragen:

```
wsl.exe -d Ubuntu-24.04 -i
```

Ohne das startet jede neue WSL-Sitzung mit bash, auch wenn `chsh` gesetzt ist.

**Pfad-Overhead beachten:** Liegt das Repo unter `/mnt/c/...` (Windows-Laufwerk),
geht es über die 9P-Schicht und ist spürbar langsamer als das Linux-Dateisystem.
Für reine Lese-/Schreibvorgänge unkritisch; wenn `f` oder `t` hängen, das Repo
in die Distribution selbst klonen:

```bash
git clone https://github.com/00vez/dotfiles.git ~/dotfiles
ln -sf ~/dotfiles/.zshrc ~/.zshrc
```

## Installation (Windows 11)

Die PowerShell-Variante ist eigenständig — sie braucht weder zsh noch Oh My
Zsh noch Homebrew. Sie läuft in Windows Terminal mit PowerShell 7.

```powershell
# 1. PowerShell 7 (falls nicht vorhanden):
winget install --id Microsoft.PowerShell --source winget

# 2. Abhängige Tools (alle optional, catm/catmd fallen sonst auf Get-Content zurück):
winget install --id jqlang.jq        --source winget   # JSON-Einfärbung in catm/catmd
winget install --id marlocarlo.psmux --source winget   # tn/ta/tl/tk
pip install -U pygments                               # YAML-Einfärbung in catm/catmd
#   mdcat (Markdown) via Scoop:  scoop install mdcat

# 3. Diese dotfiles holen:
git clone https://github.com/00vez/dotfiles.git $HOME\Documents\dotfiles

# 4. Verzeichnis für das PowerShell-Profil anlegen, falls noch nicht vorhanden:
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PROFILE)

# 5. Profil verlinken. Wichtig: New-Item -ItemType HardLink, nicht Copy-Item —
#    nur so wirken Edits an der Repo-Datei sofort auf dein $PROFILE.
$repo = "$HOME\Documents\dotfiles\Microsoft.PowerShell_profile.ps1"
New-Item -ItemType HardLink -Path $PROFILE -Value $repo -Force

# 6. Übernehmen: entweder neues Terminal öffnen oder
. $PROFILE

# 7. Prüfen (erwartet: 16/16 Funktionen, "2.0K" mit Punkt):
f help
Format-Bytes 2048
tl
```

**Nachprüfen, ob der Hardlink sitzt** – beide Befehle müssen dieselbe File-ID
liefern:

```powershell
(Get-Item $PROFILE).LinkType                  # HardLink
fsutil hardlink list $PROFILE
```

**Wichtige Unterschiede zur zsh-Variante:**

- `$PROFILE` neu laden ist der Neustart-Mechanismus; der Alias `reload` deckt
  das ab.
- Der `,`-Präfix der Inhaltssuche muss in PowerShell **gequotet** werden
  (`f ',text'`), weil der Parser das Komma als Array-Operator liest. Portabel
  ist `%text` in beiden Shells.
- `tn` startet eine echte PowerShell 7, keine generische psmux-Shell.
- Die Personal Helpers (`tn`, `cath`, `curfew`, `nikl`, `tailnet`, `hardfetch`,
  `ept`, `ops`, `ssdm`, `wt`, `oc`, `gst`, `gic`, `tten`/`ttde`) enthalten
  hartkodierte absolute Pfade auf dieses konkrete Gerät (`C:\Users\v\...`).
  Auf einer anderen Maschine zeigen die nicht passenden Befehle ins Leere —
  sie stehen nicht in der reduzierten `.txt`-Variante, die nur den
  Parity-Set enthält und deshalb ohne Anpassung überall läuft.

---

## Verifikation (alle Systeme)

Nach der Installation einmal durchlaufen. Alles hier ist gegen eine echte
Installation geprüft (Ubuntu 24.04 / zsh 5.9 bzw. Windows 11 / pwsh 7.6.6).

```bash
# Shell und Version
zsh --version                    # erwartet: zsh 5.9
echo $SHELL                      # nach chsh: Pfad auf .../zsh

# Sind die dotfiles überhaupt geladen?
reload && echo ok

# Parity-Befehle: alle müssen eine Ausgabe liefern
t                                # Baum, baut Build-Verzeichnisse aus
ll                               # Listing mit Größe und Datum
i README.md                      # Metadaten der Datei
f README                         # Dateisuche nach Name
f %PowerShell                    # Inhaltssuche (unquotiert, pwsh-tauglich)
catm README.md                   # Markdown farbig

# Kein Ergebnis heisst: Funktion nicht geladen oder falsches Verzeichnis
f help                           # zeigt die Syntax-Uebersicht
```

Erwartete Ausgabe bei `f %PowerShell` ist eine Trefferliste mit
`> Zeilennummer  Kontext`. Kommt stattdessen `f/ff: Content-Suche nicht mit
'*' kombinierbar` oder eine Fehlermeldung, stimmt der Aufruf nicht.

```powershell
# Windows / PowerShell
$PSVersionTable.PSVersion        # erwartet: 7.x
Format-Bytes 2048                # erwartet: 2.0K  (Punkt, nicht Komma)
f help
f %PowerShell
tl                               # psmux-Sessions, darf leer sein
```

**Wenn eine Meldung wie `Hinweis: 'zsh-autosuggestions' fehlt` erscheint:**
Das ist kein Fehler, sondern der vorgesehene Hinweis. Die `.zshrc` läuft ohne
das Plugin weiter – nur die Inline-Vorschau fehlt dann.

---

## Aliases & Funktionen (Übersicht)

Alle Suchbefehle sind als `noglob` deklariert – Sternchen und Klammern müssen
also nicht escaped werden.

### zsh (`.zshrc`)

| Befehl | Typ | Beschreibung |
|--------|-----|--------------|
| `f` | Funktion | Dateisuche ohne versteckte Dateien: `f <pattern> [.ext] [dir/] [*] [*N] [%text] [=text] [-N] [+N] [:N]` |
| `ff` | Funktion | Wie `f`, inklusive versteckter Dateien |
| `ll [dir]` | Funktion | Verzeichnisinhalt mit Größe + Datum, farbig nach Typ |
| `t [dir]` | Funktion | `tree`-Ansicht, ignoriert `.git`, `node_modules`, `venv`, Build-Dirs etc. |
| `i [pfad]` | Funktion | Metadaten: Typ, Größe, Rechte, Owner, mtime/ctime |
| `py` | Alias | Python 3 Aufruf (`python3`) |
| `reload` | Alias | Config neu laden (`source ~/.zshrc`) |
| `cl` | Alias | Terminal leeren (`clear`) |
| `cc` | Alias | Claude-CLI (`claude`, separat installieren) |
| `catmd <datei>` | Funktion | Markdown/JSON/YAML farbig via `less` (mdcat/jq/pygmentize) |
| `catm <datei>` | Funktion | Wie `catmd`, aber ohne Pager |

`f`/`ff` Syntax im Detail:

- `<pattern>` – Namenssuche (case-insensitive, `*` erlaubt)
- `.<ext>` – nur diese Endung (mehrere kombinierbar)
- `%text` – Datei MUSS `text` enthalten (Pflicht-Inhalt)
- `,text` – identisch zu `%text`. In zsh direkt nutzbar, in PowerShell **muss
  das Argument gequotet werden** (`f ',text'`), sonst wirft der Parser schon
  vor dem Funktionsaufruf einen Fehler. Nutze in Skripten, die auf beiden
  Shells laufen sollen, `%text`.
- `=text` – Datei enthält `text` optional (wird als `[tag]` angezeigt)
- `-N` / `+N` – `N` Zeilen Kontext vor/nach Treffer
- `*` – nur Verzeichnisse (nicht mit `%text`/`=text` kombinierbar)
- `*N` – nur erste N Ergebnisse (Count zählt Angezeigte)
- `dir/` oder `.` – Durchsucht nur dieses Verzeichnis
- `:N` – maximale Suchtiefe ab Suchroot
- Sortierung: txt > md > ausführbar > Bild > Video > bekannt (neueste zuerst), Rest alphabetisch

### PowerShell (`Microsoft.PowerShell_profile.ps1`)

Das aktive Profil (`$PROFILE`) ist ein Hardlink auf diese Datei – Edits wirken nach `reload`.
`Microsoft.PowerShell_profile.ps1.txt` ist die reduzierte Variante (nur Parity-Set, keine Personal Helpers).

Parity-Befehle (wie zsh):

| Befehl | Typ | Beschreibung |
|--------|-----|--------------|
| `f` / `ff` | Funktion | Dateisuche, gleiche Syntax + Sortierung wie zsh (`ff` mit versteckten) |
| `t` | Funktion | `tree`-Ansicht, gleiche Prune-Liste wie `f/ff` |
| `ll` | Funktion | Verzeichnisinhalt mit Größe + Datum, farbig nach Typ |
| `l` | Funktion | Kurzform für `ll`; `l *` nur Unterverzeichnisse |
| `l` | Funktion | Kompakte Verzeichnisliste |
| `i` | Funktion | Metadaten zu Datei/Dir |
| `catm` / `catmd` | Funktion | Markdown/JSON/YAML farbig, ohne/mit Pager |
| `..` / `...` / `....` | Funktion | 1 / 2 / 3 Ebenen hoch |
| `cl` | Alias | Bildschirm leeren (`Clear-Host`) |
| `cc` | Alias | Claude-CLI (nur wenn installiert) |
| `py` | Alias | Python (nur wenn installiert) |
| `reload` | Alias | Profil neu laden |
| `cath` | Funktion | `progress.html` als formatierter Text (Konsole, kein Pager, pipe-fähig) |
| `gst` | Funktion | `git status` |

Personal Helpers (nur Vollvariante):

| Befehl | Typ | Beschreibung |
|--------|-----|--------------|
| `tten` / `ttde` | Funktion | Session-Start/-Ende per Skript (`$HOME\bin\tten.ps1` / `ttde.ps1`) |
| `oc` | Funktion | `opencode` starten |
| `tailnet` | Funktion | Tailscale-Monitor-Skript |
| `hardfetch` | Funktion | Systeminfo (`hardfetch.exe`) |
| `ept` | Funktion | Datei aufs Handy exportieren |
| `ops` | Funktion | Ollama-PS-Helfer |
| `ssdm` | Funktion | SATA-Temperaturen per SSH auf unraid |
| `wt` | Funktion | Was läuft gerade (Prozessübersicht) |
| `curfew` | Funktion | Nachtmodus-Steuerung (`C:\Users\v\curfew.ps1`) |
| `nikl` | Funktion | Beendet Gaming-/Social-Prozesse (cs2, discord, brave, steam) |
| `tn [name]` | Funktion | Neue psmux-Session; startet darin eine echte PowerShell 7 (`pwsh -NoLogo`). Ohne Name: erste freie Nummer. Belegt den Namen nicht doppelt |
| `ta` | Funktion | Sessions mit Letztverbindung auflisten, Dialog, anhängen |
| `tl [name]` | Funktion | Alle psmux-Sessions auflisten. Mit Argument: nur die Session dieses Namens |
| `tk` | Funktion | psmux-Server beenden, beendet **alle** Sessions |

`tn`/`ta`/`tl`/`tk` nutzen **psmux** (WinGet `marlocarlo.psmux`), nicht tmux.
psmux hat genau einen Server und kein Socket-pro-Session-Konzept, deshalb gibt
es keinen Socket-Parameter mehr. `tk` beendet daher immer alle Sessions — der
Parameter existiert nur noch für Abwärtskompatibilität.

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
| `zsh-history-substring-search` | nein (Hinweis bei Fehlen) | Pfeil-hoch/runter History | brew: `brew install zsh-history-substring-search` **oder** WSL/Linux: `git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search.git ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search` (in Ubuntu 24.04 gibt es kein apt-Paket) |

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
- PowerShell-`i`: `Fingerprint` (Datei) ist SHA256 über die Dateigröße und
  bei Dateien über 192 KiB drei Stichproben à 64 KiB (Anfang, Mitte, Ende),
  angezeigt als 15 Hex-Zeichen. `Structure-ID` (Verzeichnis) ist MD5 über
  Pfad/Größe/mtime aller Einträge, **kein** Inhalt. Gleicher Fingerprint heißt
  gleiche Größe und gleiche Stichproben, nicht garantiert identischen Inhalt;
  Änderungen außerhalb der Stichproben bleiben unentdeckt.
