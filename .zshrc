# --------------------------------------------------------------------
#  .zshrc — portabel: macOS · Linux · WSL2 · Termux
# --------------------------------------------------------------------

# Portable PATH: brew für Apple Silicon, Intel und Linux/Linuxbrew + lokale Binaries.
export PATH="$HOME/.local/bin:$HOME/Documents/.verapdf:/usr/local/bin:$PATH"
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
[[ -d /home/linuxbrew/.linuxbrew/bin ]] && export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Betriebssystem erkennen: eine .zshrc für macOS (Intel + Apple Silicon), Linux, WSL2 und Termux.
if [[ -n "$TERMUX_VERSION" || -d /data/data/com.termux ]]; then
  OS="termux"
elif [[ "$(uname -r)" == *[Mm]icrosoft* ]]; then
  OS="wsl"
elif [[ "$OSTYPE" == darwin* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == linux* ]]; then
  OS="linux"
else
  OS="unknown"
fi

# Plattformneutrale Builtins: zsh/stat (statt BSD/GNU-stat), zsh/datetime (strftime),
# zsh/terminfo (Pfeiltasten unter WSL2/tmux).
zmodload zsh/stat 2>/dev/null
zmodload zsh/datetime 2>/dev/null
zmodload zsh/terminfo 2>/dev/null

# Erforderliches Tool prüfen; bei Fehlen OS-spezifischen Installationsweg ausgeben.
_require() {
  local tool="$1"
  local macos_cmd="${2:-brew install $tool}"
  local linux_cmd="${3:-sudo apt install $tool}"
  local wsl_cmd="${4:-$linux_cmd}"
  command -v "$tool" >/dev/null 2>&1 && return 0
  local cmd="$macos_cmd"
  [[ "$OS" == "linux"  ]] && cmd="$linux_cmd"
  [[ "$OS" == "wsl"    ]] && cmd="$wsl_cmd"
  [[ "$OS" == "termux" ]] && cmd="pkg install $tool"
  print -P "%F{1}Fehler:%f '$tool' ist nicht installiert." >&2
  print -P "  Installation ($OS): %F{3}$cmd%f" >&2
  return 1
}

# Wie _require, aber nicht fatal (Hinweis statt Abbruch) – für optionale Features.
_warn_tool() {
  local tool="$1"
  local macos_cmd="${2:-brew install $tool}"
  local linux_cmd="${3:-sudo apt install $tool}"
  local wsl_cmd="${4:-$linux_cmd}"
  local cmd="$macos_cmd"
  [[ "$OS" == "linux"  ]] && cmd="$linux_cmd"
  [[ "$OS" == "wsl"    ]] && cmd="$wsl_cmd"
  [[ "$OS" == "termux" ]] && cmd="pkg install $tool"
  print -P "%F{3}Hinweis:%f '$tool' fehlt. Installation ($OS): %F{3}$cmd%f" >&2
}

# Erste existierende Datei aus Argumenten sourcen; sonst Warnung.
_source_first() {
  local label="$1"; shift
  local p
  for p in "$@"; do
    [[ -f "$p" ]] && { source "$p"; return 0; }
  done
  _warn_tool "$label"
  return 1
}

# HOMEBREW_PREFIX kann auf WSL/Linux/Termux leer sein ? Pfad-Fallback verhindert "/share/…".
_hbp="${HOMEBREW_PREFIX:-/nonexistent}"

# zsh-autosuggestions: egal ob via brew (macOS/Linux) oder apt (Debian/Ubuntu/WSL2) installiert.
_source_first zsh-autosuggestions \
  "$_hbp/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

# Suppress oh-my-zsh glob errors (missing caches/custom dirs).
setopt NULL_GLOB
if [[ -f $ZSH/oh-my-zsh.sh ]]; then
  source $ZSH/oh-my-zsh.sh
else
  _warn_tool oh-my-zsh
fi
unsetopt NULL_GLOB

# typesetsilent: verhindert "mtime=<wert>"-Fremdzeilen in f-Ausgabe durch doppelte local-Deklarationen.
setopt typesetsilent

# zsh-history-substring-search — Plugin-Pfad mehrfach probiert (brew, distro, oh-my-zsh, git clone).
typeset -g _hss_loaded=0
_source_first zsh-history-substring-search \
  "$_hbp/share/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh \
  /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh \
  "$ZSH/plugins/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh" \
  "$ZSH/custom/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  && _hss_loaded=1

# Pfeiltasten — terminfo deckt WSL2 + tmux Application-Mode ab; Fallback auf ANSI.
if (( _hss_loaded )); then
  if [[ -n "${terminfo[kcuu1]:-}" ]]; then
    bindkey "${terminfo[kcuu1]}" history-substring-search-up
    bindkey "${terminfo[kcud1]}" history-substring-search-down
  else
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
  fi
fi

if (( $+commands[code] )); then
  export EDITOR="${EDITOR:-code --wait}"
else
  export EDITOR="${EDITOR:-vim}"
fi

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
elif command -v fdfind >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# --- Farben ---------------------------------------------------------
# Setzt REPLY_COLOR (kein Subshell); Aufrufer liest $REPLY_COLOR.
typeset -g REPLY_COLOR
_type_color() {
  if [[ -d "$1" ]]; then REPLY_COLOR=blue; return; fi
  case "${1:e:l}" in
    py)      REPLY_COLOR=214 ;;
    js|jsx)  REPLY_COLOR=227 ;;
    ts|tsx)  REPLY_COLOR=75  ;;
    go)      REPLY_COLOR=80  ;;
    rs)      REPLY_COLOR=209 ;;
    c|cpp|h) REPLY_COLOR=111 ;;
    java)    REPLY_COLOR=173 ;;
    rb)      REPLY_COLOR=203 ;;
    php)     REPLY_COLOR=140 ;;
    sh|zsh)  REPLY_COLOR=150 ;;
    md)      REPLY_COLOR=114 ;;
    txt)     REPLY_COLOR=81  ;;
    json|jsonl) REPLY_COLOR=141 ;;
    yaml|yml)   REPLY_COLOR=208 ;;
    xml|html)   REPLY_COLOR=172 ;;
    toml)       REPLY_COLOR=179 ;;
    csv)        REPLY_COLOR=37  ;;
    png|jpg|jpeg|gif|svg|webp|ico|bmp|tiff) REPLY_COLOR=213 ;;
    mp4|mov|avi|mkv|webm|flv|wmv|m4v)       REPLY_COLOR=207 ;;
    zip|tar|gz|rar|7z|bz2)                  REPLY_COLOR=203 ;;
    *) REPLY_COLOR=white ;;
  esac
}

# --- Tool-Discovery -------------------------------------------------
_find_rg() {
  command -v rg >/dev/null 2>&1 && { command -v rg; return 0; }
  local p
  for p in "$HOME/.cargo/bin/rg" "$HOME/.local/bin/rg" \
           /opt/homebrew/bin/rg /usr/local/bin/rg \
           /home/linuxbrew/.linuxbrew/bin/rg; do
    [[ -x "$p" ]] && { print -r -- "$p"; return 0; }
  done
  return 1
}

# Portabler Core-Count für parallele Tool-Aufrufe.
_cores() {
  nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || print -r -- 4
}

# Einmaliger --color-Check (GNU grep hat es, BSD grep nicht immer).
typeset -g _GREP_HAS_COLOR=0
grep --color=always "" /dev/null >/dev/null 2>&1 && _GREP_HAS_COLOR=1

# --- f / ff ---------------------------------------------------------
unalias f ff ll t 2>/dev/null

_ff_help() {
  local rg_cmd rg_status
  if rg_cmd=$(_find_rg); then
    rg_status="%F{2}?%f $rg_cmd"
  else
    rg_status="%F{3}?%f — Fallback auf grep (langsamer)"
  fi
  print -P "%F{cyan}f%f   — Datei-/Inhaltssuche (ohne Hidden)"
  print -P "%F{cyan}ff%f  — wie f, aber inkl. Hidden"
  print -P "  ripgrep: $rg_status"
  print ""
  print -P "%F{cyan}Syntax:%f f [patterns] [.ext] [dir/] [*] [*N] [,text] [,,text] [:N] [-N] [-v]"
  print ""
  print "  <pattern>   Dateiname enthält Muster (mehrere = UND-Verknüpfung)"
  print "  .ext        nur diese Endung (mehrere = ODER)"
  print "  dir/        nur in diesem Verzeichnis suchen"
  print "  *           nur Verzeichnisse anzeigen"
  print "  *N          max. N Treffer (Default 200 bei Content, sonst alle)"
  print "  ,text       Inhalt enthält Text (case-insensitive, mehrere = UND)"
  print "  ,,text      Inhalt enthält Text (case-sensitive)"
  print "  -N          N Zeilen Kontext um Content-Treffer (grep -C)"
  print "  :N          maximale Suchtiefe ab Suchroot"
  print "  -v          zeigt äquivalenten rg/grep-Befehl"
  print ""
  print -P "%F{cyan}Beispiele:%f"
  print "  f .py                  alle .py-Dateien"
  print "  f test .js             'test' im Namen, nur .js"
  print "  f ,TODO                Inhalt enthält 'TODO' (insensitive)"
  print "  f ,,TODO               Inhalt enthält 'TODO' (sensitive)"
  print "  f ,TODO ,FIXME         Inhalt enthält beide"
  print "  f .py ,def main        Python-Dateien mit 'def main'"
  print "  f ,TODO -2             mit 2 Zeilen Kontext"
  print "  f ,TODO src/ :2        in src/, max Tiefe 2"
  print "  f ,TODO *0             unbegrenzt"
  print ""
  print -P "%F{cyan}Sortierung:%f txt > md > exec > Bild > Video > Code > Rest (neueste zuerst)"
}

# Ergebnis-Array (global, damit Filterkette sauber durchläuft)
typeset -ga _FF_MATCHED

# Filtert eine Datei-Liste gegen ein Muster (case-insensitive oder -sensitive).
# $1 = Muster, $2 = ci-Flag (1 = insensitive), $3.. = Dateien
_ff_filter_pattern() {
  local pattern="$1" ci="$2"; shift 2
  _FF_MATCHED=()
  (( $# == 0 )) && return
  local -a files=("$@")
  local rg
  rg=$(_find_rg)
  local -a extra=()
  (( ci )) && extra=(-i)

  if [[ -n "$rg" ]]; then
    # rg kennt kein -0; --null liefert NUL-Separatoren.
    _FF_MATCHED=("${(@0)$(printf '%s\0' "${files[@]}" \
      | xargs -0 -n 500 "$rg" -lF --null --no-messages -e "$pattern" "${extra[@]}" -- 2>/dev/null)}")
  else
    _FF_MATCHED=("${(@0)$(printf '%s\0' "${files[@]}" \
      | xargs -0 -P "$(_cores)" -n 200 grep -lF -e "$pattern" "${extra[@]}" -- 2>/dev/null \
      | tr '\n' '\0')}")
  fi
}

# Gibt Content-Treffer einer Datei aus (mit Kontext + Highlight).
# $1 = Datei, $2 = ctx, $3 = ci-Flag, $4.. = Muster
_ff_print_hits() {
  local fp="$1" ctx="$2" ci="$3"; shift 3
  local -a ga=(-n)
  (( ctx > 0 )) && ga+=(-C "$ctx")
  (( ci )) && ga+=(-i)
  local p
  for p in "$@"; do ga+=(-e "$p"); done
  (( _GREP_HAS_COLOR )) && ga+=(--color=always)

  local cline num sepchar content marker
  grep "${ga[@]}" -- "$fp" 2>/dev/null | while IFS= read -r cline; do
    [[ "$cline" == "--" ]] && { print ""; continue; }
    num="${cline%%[!0-9]*}"
    [[ -z "$num" ]] && continue
    sepchar="${cline[${#num}+1]}"
    content="${cline[${#num}+2,-1]}"
    (( ${#content} > 100 )) && content="${content[1,100]}…"
    [[ "$sepchar" == ":" ]] && marker=">" || marker=" "
    printf "    %s %5s  %s\033[0m\n" "$marker" "$num" "$content"
  done
}

_ff_impl() {
  local show_hidden="$1"; shift
  if [[ $# -eq 0 || "$1" == "help" || "$1" == "?" || "$1" == "--help" || "$1" == "-h" ]]; then
    _ff_help; return 0
  fi

  local -a patterns=() extensions=() req_ci=() req_cs=()
  local root="." root_set=0 dirs_only=0
  local ctx=0 limit=200 limit_set=0 maxdepth=0 verbose=0
  local arg

  # Flags vorab
  local -a args=()
  for arg in "$@"; do
    case "$arg" in
      -v|--verbose) verbose=1 ;;
      *) args+=("$arg") ;;
    esac
  done
  set -- "${args[@]}"

  for arg in "$@"; do
    if   [[ "$arg" == "*" ]];       then dirs_only=1
    elif [[ "$arg" == \*<-> ]];     then limit="${arg#\*}"; limit_set=1
    elif [[ "$arg" == :<-> ]];      then maxdepth="${arg#:}"
    elif [[ "$arg" == ",,"?* ]];    then req_cs+=("${arg#,,}")
    elif [[ "$arg" == ","?* ]];     then req_ci+=("${arg#,}")
    elif [[ "$arg" == -<-> ]];      then ctx="${arg#-}"
    elif [[ -d "$arg" ]]; then
      if (( root_set )); then
        print -u2 "f/ff: nur ein Suchverzeichnis erlaubt"
        return 1
      fi
      root="$arg"; root_set=1
    elif [[ "$arg" == .?* ]];       then extensions+=("$arg")
    else                                 patterns+=("$arg")
    fi
  done

  # -N ohne Content: Warnung nur mit -v
  if (( ctx > 0 && ${#req_ci[@]} == 0 && ${#req_cs[@]} == 0 && verbose )); then
    print -u2 -P "%F{3}Hinweis:%f -N ohne ,text wird ignoriert."
  fi
  if [[ ${#patterns[@]} -eq 0 && ${#extensions[@]} -eq 0 \
      && ${#req_ci[@]} -eq 0 && ${#req_cs[@]} -eq 0 \
      && $dirs_only -eq 0 && $maxdepth -eq 0 && $root_set -eq 0 ]]; then
    _ff_help; return 0
  fi

  if (( dirs_only && (${#req_ci[@]} + ${#req_cs[@]}) > 0 )); then
    print -u2 "f/ff: Content-Suche nicht mit '*' kombinierbar"
    return 1
  fi

  # find-Argumente
  local -a name_clauses=()
  local p glob
  for p in "${patterns[@]}"; do
    [[ "$p" == *"*"* ]] && glob="$p" || glob="*${p}*"
    if [[ "$p" == */* ]]; then
      name_clauses+=(-ipath "$glob")
    else
      name_clauses+=(-iname "$glob")
    fi
  done
  if (( ${#extensions[@]} > 0 )); then
    name_clauses+=(\()
    local e first=1
    for e in "${extensions[@]}"; do
      (( first )) || name_clauses+=(-o)
      name_clauses+=(-iname "*${e}")
      first=0
    done
    name_clauses+=(\))
  fi

  local -a prune_dirs=(.git node_modules __pycache__ .venv venv .pytest_cache .mypy_cache .tox target .next .nuxt .cache .terraform '*.egg-info' \
    dist build coverage vendor .gradle .m2 .build .eggs .angular .turbo .parcel-cache 'cmake-build-*' CMakeFiles site-packages)
  local -a prune_paths=('*/ggml/src')
  local -a prune_expr
  local d
  for d in $prune_dirs;  do prune_expr+=(-o -name "$d"); done
  for d in $prune_paths; do prune_expr+=(-o -path "$d"); done

  local -a hidden_exclude=()
  if (( ! show_hidden )); then
    prune_expr+=(-o -name '.?*')
    hidden_exclude=(! -iname '.?*')
  fi

  local -a type_clause
  (( dirs_only )) && type_clause=(-type d) || type_clause=(-type f)

  local -a maxdepth_clause=()
  (( maxdepth > 0 )) && maxdepth_clause=(-maxdepth "$maxdepth")

  print -P "%F{cyan}${root:A}%f"

  # 1) Namen finden
  local -a found
  found=(${(0)"$(find "$root" -mindepth 1 "${maxdepth_clause[@]}" \( -type d \( -false "${prune_expr[@]}" \) -prune \) -o "${type_clause[@]}" "${name_clauses[@]}" "${hidden_exclude[@]}" -print0 2>/dev/null)"})
  (( ${#found} == 0 )) && { print -P "%F{cyan}# 0%f"; return 0; }

  # 2) Content-Filter (vor stat!)
  local -a matched=("${found[@]}")
  local q
  for q in "${req_ci[@]}"; do
    _ff_filter_pattern "$q" 1 "${matched[@]}"
    matched=("${_FF_MATCHED[@]}")
    (( ${#matched} == 0 )) && break
  done
  if (( ${#matched} > 0 )); then
    for q in "${req_cs[@]}"; do
      _ff_filter_pattern "$q" 0 "${matched[@]}"
      matched=("${_FF_MATCHED[@]}")
      (( ${#matched} == 0 )) && break
    done
  fi
  (( ${#matched} == 0 )) && { print -P "%F{cyan}# 0%f"; return 0; }

  # 3) Stat + Ranking (Basis-Syntax mit Leerzeichen nach jedem ')')
  local -A _z
  local -a ranked
  local fp epoch mtime ext rank
  for fp in "${matched[@]}"; do
    _z=()
    zstat -H _z "$fp" 2>/dev/null || continue
    epoch="${_z[mtime]}"
    strftime -s mtime '%Y-%m-%d %H:%M' "$epoch" 2>/dev/null || mtime=""

    if [[ -d "$fp" ]]; then
      rank=6
    else
      ext="${fp:e:l}"
      case "$ext" in
        txt) rank=0 ;;
        md)  rank=1 ;;
        *)
          if [[ -x "$fp" ]]; then
            rank=2
          else
            case "$ext" in
              png|jpg|jpeg|gif|svg|webp|ico|bmp|tiff) rank=3 ;;
              mp4|mov|avi|mkv|webm|flv|wmv|m4v)       rank=4 ;;
              py|js|jsx|ts|tsx|go|rs|c|cpp|h|java|rb|php|sh|zsh|json|jsonl|yaml|yml|xml|html|toml|csv|zip|tar|gz|rar|7z|bz2) rank=5 ;;
              *) rank=6 ;;
            esac
          fi
          ;;
      esac
    fi
    ranked+=("${rank}|${epoch}|${mtime}|${fp}")
  done

  local -a known rest
  local rline
  for rline in $ranked; do
    [[ "${rline%%|*}" -le 5 ]] && known+=("$rline") || rest+=("$rline")
  done

  local -a pairs
  (( ${#known} > 0 )) && pairs+=(${(f)"$(printf '%s\n' "${known[@]}" | sort -t'|' -k1,1n -k2,2rn)"})
  (( ${#rest}  > 0 )) && pairs+=(${(f)"$(printf '%s\n' "${rest[@]}"  | sort -t'|' -k4)"})

  # 4) Limit (Default nur bei Content-Suche)
  (( ! limit_set && ${#req_ci[@]} + ${#req_cs[@]} == 0 )) && limit=0
  if (( limit > 0 && ${#pairs} > limit )); then
    pairs=("${(@)pairs[1,limit]}")
  fi

  print -P "%F{cyan}# ${#pairs}%f"
  (( ${#pairs} == 0 )) && return 0

  # 5) Ausgabe
  local line color disp
  for line in $pairs; do
    rank="${line%%|*}";   line="${line#*|}"
    epoch="${line%%|*}";  line="${line#*|}"
    mtime="${line%%|*}";  fp="${line#*|}"
    disp="${fp#./}"
    _type_color "$fp"; color="$REPLY_COLOR"
    [[ -d "$fp" ]] && disp="${disp}/"
    print -P "  %F{$color}${disp}%f"

    (( ${#req_ci[@]} + ${#req_cs[@]} > 0 )) && [[ -f "$fp" ]] || continue
    (( ${#req_ci[@]} > 0 )) && _ff_print_hits "$fp" "$ctx" 1 "${req_ci[@]}"
    (( ${#req_cs[@]} > 0 )) && _ff_print_hits "$fp" "$ctx" 0 "${req_cs[@]}"
  done

  # 6) -v ? äquivalenter Befehl
  (( verbose )) || return 0
  local rg
  rg=$(_find_rg)
  local -a cmd=()
  local dd

  if [[ -n "$rg" ]]; then
    cmd=("$rg" -lF --null --no-messages)
    for p in "${req_ci[@]}"; do cmd+=(-i -e "$p"); done
    for p in "${req_cs[@]}"; do cmd+=(-e "$p"); done
    for p in "${extensions[@]}"; do cmd+=(-g "*.${p#.}"); done
    for dd in $prune_dirs;    do cmd+=(-g "!${dd}/**"); done
    (( ! show_hidden )) && cmd+=(-g '!.*')
    print -P "%F{cyan}# rg äquivalent:%f"
  else
    cmd=(grep -rIlF)
    (( ctx > 0 )) && cmd+=(-C "$ctx")
    for p in "${req_ci[@]}"; do cmd+=(-i -e "$p"); done
    for p in "${req_cs[@]}"; do cmd+=(-e "$p"); done
    for p in "${extensions[@]}"; do cmd+=(--include="*.${p#.}"); done
    for dd in $prune_dirs;    do cmd+=(--exclude-dir="$dd"); done
    (( ! show_hidden )) && cmd+=(--exclude='.*')
    print -P "%F{cyan}# grep äquivalent:%f"
  fi
  print -r -- "  $(printf '%q ' "${cmd[@]}")${root}"
}

f()  { _ff_impl 0 "$@" }
ff() { _ff_impl 1 "$@" }

# --- ll -------------------------------------------------------------
unalias ll 2>/dev/null
ll() {
  setopt local_options null_glob extended_glob
  local dir="." dirs_only=0
  if [[ "$1" == "*" ]]; then
    dirs_only=1
    shift
  fi
  [[ -n "$1" ]] && dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo "ll: '$dir' is not a directory"
    return 1
  fi

  local -a paths
  (( dirs_only )) && paths=("$dir"/*(/N)) || paths=("$dir"/*(N))
  (( ${#paths} == 0 )) && return 0

  local -A _z
  local fp sz hsize mtime name color
  for fp in $paths; do
    _z=()
    zstat -H _z "$fp" 2>/dev/null || continue
    strftime -s mtime '%Y-%m-%d %H:%M' "${_z[mtime]}" 2>/dev/null || continue
    sz="${_z[size]}"
    if   (( sz < 1024 ));       then printf -v hsize '%5dB'   $sz
    elif (( sz < 1048576 ));    then printf -v hsize '%5.1fK' $(( sz / 1024.0 ))
    elif (( sz < 1073741824 )); then printf -v hsize '%5.1fM' $(( sz / 1048576.0 ))
    else                             printf -v hsize '%5.1fG' $(( sz / 1073741824.0 ))
    fi
    name="${fp:t}"
    _type_color "$fp"; color="$REPLY_COLOR"
    [[ -d "$fp" ]] && name="${name}/"
    print -P "%F{8}${hsize}  ${mtime}%f  %F{$color}${name}%f"
  done
}

# --- t --------------------------------------------------------------
t() {
  _require tree || return 1
  local dir="." dirs_only=0
  if [[ "$1" == "*" ]]; then
    dirs_only=1
    shift
  fi
  [[ -n "$1" && "$1" != -* ]] && dir="$1" && shift
  local ignore='.git|node_modules|__pycache__|.venv|venv|.pytest_cache|.mypy_cache|.tox|target|.next|.nuxt|.cache|.terraform|*.egg-info|dist|build|coverage|.idea|.vscode|.DS_Store'
  local -a dflag
  (( dirs_only )) && dflag=(-d)
  tree -C --dirsfirst "${dflag[@]}" -I "$ignore" "$@" "$dir"
}

alias f='noglob f'
alias ff='noglob ff'
alias ll='noglob ll'
unalias l 2>/dev/null
l() { ll "$@" }
alias l='noglob l'
alias t='noglob t'

# --- _human ---------------------------------------------------------
_human() {
  awk -v s="${1:-0}" 'BEGIN{
    if (s<1024) printf "%dB", s
    else if (s<1048576) printf "%.1fK", s/1024
    else if (s<1073741824) printf "%.1fM", s/1048576
    else printf "%.1fG", s/1073741824
  }'
}

# --- i --------------------------------------------------------------
i() {
  local target="${1:-.}"
  if [[ ! -e "$target" ]]; then
    echo "i: '$target' does not exist"
    return 1
  fi
  _require python3 || return 1
  local abs rel type size perms owner group mtime ctime
  abs="${target:A}"
  rel=$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1]))" "$abs")

  local -A _z
  _z=()
  if ! zstat -H _z "$target" 2>/dev/null; then
    echo "i: cannot stat '$target'"
    return 1
  fi
  perms=$(python3 -c 'import stat,sys; print(stat.filemode(int(sys.argv[1])))' "${_z[mode]}")
  owner="${_z[uid]}"
  group="${_z[gid]}"
  size="${_z[size]}"
  strftime -s mtime '%Y-%m-%d %H:%M:%S' "${_z[mtime]}" 2>/dev/null
  strftime -s ctime '%Y-%m-%d %H:%M:%S' "${_z[ctime]}" 2>/dev/null

  if [[ -L "$target" ]]; then
    type="symlink -> $(readlink "$target")"
  elif [[ -d "$target" ]]; then
    type="directory"
    local dsize
    dsize=$(du -sh "$target" 2>/dev/null | awk '{print $1}')
    size="${dsize:-0}"
    if [[ -z "$dsize" || "$dsize" == 0 ]]; then
      size="$(_human "${_z[size]}")"
    fi
  else
    type="file"
    size=$(_human "$size")
  fi

  print -P "%F{cyan}Path:%f      $abs"
  print -P "%F{cyan}Relative:%f  $rel"
  print -P "%F{cyan}Type:%f      $type"
  print -P "%F{cyan}Size:%f      $size"
  print -P "%F{cyan}Perms:%f     $perms  ($owner:$group)"
  print -P "%F{cyan}Modified:%f  $mtime"
  print -P "%F{cyan}Changed:%f   $ctime"
}

# --- Completions ----------------------------------------------------
# Case-insensitive completion matching (scree -> Screenshots_...)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*' 'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*'

# Tab-completion at command position: nur History, nicht ganzes $PATH.
# Pure-zsh: ein Lesevorgang, keine 4 Subprozesse (tac/sed/awk/awk).
_history_commands() {
  [[ -r "${HISTFILE:-}" ]] || return
  local -a histlines cmds
  local line first
  local -A seen
  local i

  while IFS= read -r line; do
    histlines+=("$line")
  done < "$HISTFILE"

  setopt local_options extended_glob
  for (( i = ${#histlines[@]}; i > 0; i-- )); do
    line="${histlines[i]}"
    [[ "$line" == ": "* ]] && line="${line#*;}"
    line="${line##[[:space:]]#}"
    first="${line%%[[:space:]]*}"
    [[ -z "$first" ]] && continue
    [[ -n "${seen[$first]:-}" ]] && continue
    if (( $+commands[$first] || $+functions[$first] || $+aliases[$first] || $+builtins[$first] )); then
      seen[$first]=1
      cmds+=("$first")
    fi
  done

  compadd -a cmds
}
if (( $+functions[compdef] )); then
  compdef '_alternative "history:command:_history_commands" "directories:directory:_path_files -/" "files:file:_path_files -f"' -command-
fi

# --- Smart Tab ------------------------------------------------------
typeset -g _tab_last_time=0
_smart_tab() {
  if (( ${#LBUFFER} <= 10 )); then
    zle expand-or-complete
    return 0
  fi
  local now=$EPOCHREALTIME
  if (( now - _tab_last_time < 0.5 )); then
    _tab_last_time=0
    zle expand-or-complete
  else
    _tab_last_time=$now
    zle -M ""
  fi
}
zle -N _smart_tab
bindkey '^I' _smart_tab

# --- Aliase ---------------------------------------------------------
alias py=python3
alias reload="source ~/.zshrc"
alias cl=clear
alias cc=claude

unalias catmd catm 2>/dev/null
catmd() {
  if [[ "$1" == *.json || "$1" == *.jsonl ]]; then
    _require jq || return 1
    jq -C . "$1" | less -R
  elif [[ "$1" == *.yml || "$1" == *.yaml ]]; then
    _require pygmentize "brew install pygments" "sudo apt install python3-pygments" "sudo apt install python3-pygments" || return 1
    pygmentize -l yaml -O style=monokai "$1" | less -R
  else
    _require mdcat "brew install mdcat" "brew install mdcat  (Linuxbrew) bzw. cargo install mdcat" "brew install mdcat  (Linuxbrew) bzw. cargo install mdcat" || return 1
    mdcat --paginate "$@"
  fi
}
catm() {
  if [[ "$1" == *.json || "$1" == *.jsonl ]]; then
    _require jq || return 1
    jq -C . "$1"
  elif [[ "$1" == *.yml || "$1" == *.yaml ]]; then
    _require pygmentize "brew install pygments" "sudo apt install python3-pygments" "sudo apt install python3-pygments" || return 1
    pygmentize -l yaml -O style=monokai "$1"
  else
    _require mdcat "brew install mdcat" "brew install mdcat  (Linuxbrew) bzw. cargo install mdcat" "brew install mdcat  (Linuxbrew) bzw. cargo install mdcat" || return 1
    mdcat "$@"
  fi
}