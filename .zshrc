unsetopt EQUALS

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$HOME/Documents/.verapdf:/usr/local/bin:$PATH"

[[ -n $HOMEBREW_PREFIX ]] && source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

export ZSH="$HOME/.oh-my-zsh"
# Eigene Plugins/Themes hier ablegen, z.B.:
#   export ZSH_CUSTOM="$HOME/.zsh-custom"

ZSH_THEME="robbyrussell"

plugins=(git)

# Suppress oh-my-zsh glob errors (missing caches/custom dirs).
# NULL_GLOB statt unsetopt NOMATCH: wirkt unabhängig davon, ob
# extendedglob zum Zeitpunkt des jeweiligen Globs aktiv ist.
setopt NULL_GLOB

source $ZSH/oh-my-zsh.sh

unsetopt NULL_GLOB

[[ -n $HOMEBREW_PREFIX ]] && source $HOMEBREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

export EDITOR="${EDITOR:-code --wait}"

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

if command -v fd 1>/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

_type_color() {
  local fp="$1" ext
  if [[ -d "$fp" ]]; then
    echo blue
    return
  fi
  ext="${fp:e:l}"
  case "$ext" in
    py) echo 214 ;;
    js|jsx) echo 227 ;;
    ts|tsx) echo 75 ;;
    go) echo 80 ;;
    rs) echo 209 ;;
    c|cpp|h) echo 111 ;;
    java) echo 173 ;;
    rb) echo 203 ;;
    php) echo 140 ;;
    sh|zsh) echo 150 ;;
    md) echo 114 ;;
    txt) echo 81 ;;
    json|jsonl) echo 141 ;;
    yaml|yml) echo 208 ;;
    xml|html) echo 172 ;;
    toml) echo 179 ;;
    csv) echo 37 ;;
    png|jpg|jpeg|gif|svg|webp|ico|bmp|tiff) echo 213 ;;
    mp4|mov|avi|mkv|webm|flv|wmv|m4v) echo 207 ;;
    zip|tar|gz|rar|7z|bz2) echo 203 ;;
    *) echo white ;;
  esac
}

unalias f ff ll t 2>/dev/null
_ff_impl() {
  local show_hidden="$1"
  shift
  if [[ $# -eq 0 ]]; then
    echo "usage: f/ff <pattern> [pattern2 ...] [.ext]"
    return 1
  fi
  local -a patterns=() extensions=() req_content=() opt_content=()
  local -A tags_for
  local arg glob root="." root_set=0 dirs_only=0 before_ctx=0 after_ctx=0
  for arg in "$@"; do
    if [[ "$arg" == "*" ]]; then
      dirs_only=1
    elif [[ "$arg" == ","?* ]]; then
      req_content+=("${arg#,}")
    elif [[ "$arg" == "="?* ]]; then
      opt_content+=("${arg#=}")
    elif [[ "$arg" == -[0-9]* ]]; then
      before_ctx="${arg#-}"
    elif [[ "$arg" == +[0-9]* ]]; then
      after_ctx="${arg#+}"
    elif [[ "$arg" == "." ]]; then
      if (( ${#patterns} > 0 )); then
        local prev="${patterns[-1]}"
        if [[ ! -d "$prev" ]]; then
          echo "f/ff: '$prev' is not a directory"
          return 1
        fi
        if (( root_set )); then
          echo "f/ff: only one search directory allowed (got '$root' and '$prev')"
          return 1
        fi
        patterns[-1]=()
        root="$prev"
        root_set=1
      else
        if (( root_set )); then
          echo "f/ff: only one search directory allowed (got '$root' and '.')"
          return 1
        fi
        root="."
        root_set=1
      fi
    elif [[ "$arg" == */ || "$arg" == ".." ]]; then
      if [[ ! -d "$arg" ]]; then
        echo "f/ff: '$arg' is not a directory"
        return 1
      fi
      if (( root_set )); then
        echo "f/ff: only one search directory allowed (got '$root' and '$arg')"
        return 1
      fi
      root="$arg"
      root_set=1
    elif [[ "$arg" == [^.]*. && "$arg" != *"*"* ]]; then
      local cand="${arg%.}"
      if [[ ! -d "$cand" ]]; then
        echo "f/ff: '$cand' is not a directory"
        return 1
      fi
      if (( root_set )); then
        echo "f/ff: only one search directory allowed (got '$root' and '$cand')"
        return 1
      fi
      root="$cand"
      root_set=1
    elif [[ "$arg" == .* ]]; then
      if [[ -d "$arg" ]]; then
        if (( root_set )); then
          echo "f/ff: only one search directory allowed (got '$root' and '$arg')"
          return 1
        fi
        root="$arg"
        root_set=1
      else
        extensions+=("$arg")
      fi
    else
      patterns+=("$arg")
    fi
  done
  if [[ ${#patterns[@]} -eq 0 && ${#extensions[@]} -eq 0 && ${#req_content[@]} -eq 0 && ${#opt_content[@]} -eq 0 && $dirs_only -eq 0 ]]; then
    echo "usage: f/ff [dir/] <pattern> [.ext] [,content] [=content] [-N] [+N] [*]"
    return 1
  fi
  if (( dirs_only && (${#req_content[@]} || ${#opt_content[@]}) )); then
    echo "f/ff: content search (','/'=') not valid with '*' (dirs only)"
    return 1
  fi

  local -a name_clauses=()
  local p
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
    dist build coverage vendor Pods .gradle .m2 .build .eggs .angular .turbo .parcel-cache 'cmake-build-*' CMakeFiles site-packages)
  local -a prune_paths=('*/ggml/src')
  local -a prune_expr
  local d
  for d in $prune_dirs; do
    prune_expr+=(-o -name "$d")
  done
  for d in $prune_paths; do
    prune_expr+=(-o -path "$d")
  done

  local -a hidden_exclude=()
  if (( ! show_hidden )); then
    prune_expr+=(-o -name '.?*')
    hidden_exclude=(! -iname '.?*')
  fi

  local -a type_clause
  (( dirs_only )) && type_clause=(-type d) || type_clause=(\( -type f -o -type d \))

  local -a raw
  raw=(${(f)"$(find "$root" -mindepth 1 \( -type d \( -false "${prune_expr[@]}" \) -prune \) -o "${type_clause[@]}" "${name_clauses[@]}" "${hidden_exclude[@]}" -print0 2>/dev/null \
    | xargs -0 stat -f '%m|%Sm|%N' -t '%Y-%m-%d_%H:%M' 2>/dev/null)"})

  if (( ${#req_content[@]} || ${#opt_content[@]} )); then
    local -a filtered=()
    local rline2 fp ok rc oc
    local -a tag_list
    for rline2 in $raw; do
      fp="${rline2#*|*|}"
      if [[ ! -f "$fp" ]]; then
        (( ${#req_content[@]} == 0 )) && filtered+=("$rline2")
        continue
      fi
      ok=1
      for rc in "${req_content[@]}"; do
        grep -qi -- "$rc" "$fp" 2>/dev/null || { ok=0; break }
      done
      (( ok )) || continue
      tag_list=()
      for oc in "${opt_content[@]}"; do
        grep -qi -- "$oc" "$fp" 2>/dev/null && tag_list+=("$oc")
      done
      (( ${#tag_list[@]} )) && tags_for[$fp]="${(j:, :)tag_list}"
      filtered+=("$rline2")
    done
    raw=("$filtered[@]")
  fi

  local -a ranked
  local rline epoch mtime filepath ext rank
  for rline in $raw; do
    epoch="${rline%%|*}"
    rline="${rline#*|}"
    mtime="${rline%%|*}"
    filepath="${rline#*|}"
    if [[ -d "$filepath" ]]; then
      rank=6
    else
      ext="${filepath:e:l}"
      case "$ext" in
        txt) rank=0 ;;
        md) rank=1 ;;
        *)
          if [[ -x "$filepath" ]]; then
            rank=2
          else
            case "$ext" in
              png|jpg|jpeg|gif|svg|webp|ico|bmp|tiff) rank=3 ;;
              mp4|mov|avi|mkv|webm|flv|wmv|m4v) rank=4 ;;
              py|js|jsx|ts|tsx|go|rs|c|cpp|h|java|rb|php|sh|zsh|json|jsonl|yaml|yml|xml|html|toml|csv|zip|tar|gz|rar|7z|bz2) rank=5 ;;
              *) rank=6 ;;
            esac
          fi
          ;;
      esac
    fi
    ranked+=("${rank}|${epoch}|${mtime}|${filepath}")
  done

  local -a known rest
  for rline in $ranked; do
    [[ "${rline%%|*}" -le 5 ]] && known+=("$rline") || rest+=("$rline")
  done

  local -a pairs
  (( ${#known} > 0 )) && pairs+=(${(f)"$(printf '%s\n' "${known[@]}" | sort -t'|' -k1,1n -k2,2rn)"})
  (( ${#rest} > 0 )) && pairs+=(${(f)"$(printf '%s\n' "${rest[@]}" | sort -t'|' -k4)"})

  print -P "%F{cyan}# ${#pairs} matches found in ${root:A}%f"
  (( ${#pairs} == 0 )) && return 0
  local line color disp tag
  local -a greppat
  local rq cline num linerest sepchar content trunc marker
  for line in $pairs; do
    rank="${line%%|*}"; line="${line#*|}"
    epoch="${line%%|*}"; line="${line#*|}"
    mtime="${line%%|*}"
    filepath="${line#*|}"
    disp="${filepath#./}"
    color=$(_type_color "$filepath")
    [[ -d "$filepath" ]] && disp="${disp}/"
    tag="${tags_for[$filepath]}"
    if [[ -n "$tag" ]]; then
      print -P "  %F{$color}${disp}%f  %F{3}[${tag}]%f"
    else
      print -P "  %F{$color}${disp}%f"
    fi
    if (( ${#req_content[@]} )) && [[ -f "$filepath" ]]; then
      greppat=()
      for rq in "${req_content[@]}"; do greppat+=(-e "$rq"); done
      grep -n -i -B"$before_ctx" -A"$after_ctx" "${greppat[@]}" -- "$filepath" 2>/dev/null | while IFS= read -r cline; do
        if [[ "$cline" == "--" ]]; then
          print ""
          continue
        fi
        num="${cline%%[^0-9]*}"
        linerest="${cline#$num}"
        sepchar="${linerest[1]}"
        content="${linerest:1}"
        [[ "$sepchar" == ":" ]] && marker=">" || marker=" "
        trunc="${content[1,64]}"
        (( ${#content} > 64 )) && trunc="${trunc}…"
        printf "    %s %5s  %s\n" "$marker" "$num" "$trunc"
      done
    fi
  done
}
f() { _ff_impl 0 "$@" }
ff() { _ff_impl 1 "$@" }

unalias ll 2>/dev/null
ll() {
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
  local -a type_clause
  (( dirs_only )) && type_clause=(-type d)
  local -a entries
  entries=(${(f)"$(find "$dir" -mindepth 1 -maxdepth 1 ! -name '.*' "${type_clause[@]}" -print0 2>/dev/null \
    | xargs -0 stat -f '%z|%Sm|%N' -t '%Y-%m-%d %H:%M' 2>/dev/null \
    | sort -t'|' -k3)"})
  (( ${#entries} == 0 )) && return 0
  local line size mtime filepath name color hsize
  for line in $entries; do
    size="${line%%|*}"; line="${line#*|}"
    mtime="${line%%|*}"; filepath="${line#*|}"
    name="${filepath:t}"
    color=$(_type_color "$filepath")
    [[ -d "$filepath" ]] && name="${name}/"
    hsize=$(awk -v s="$size" 'BEGIN{
      if (s<1024) printf "%dB", s
      else if (s<1048576) printf "%.1fK", s/1024
      else if (s<1073741824) printf "%.1fM", s/1048576
      else printf "%.1fG", s/1073741824
    }')
    printf -v hsize "%6s" "$hsize"
    print -P "%F{8}${hsize}  ${mtime}%f  %F{$color}${name}%f"
  done
}

t() {
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
alias t='noglob t'

i() {
  local target="${1:-.}"
  if [[ ! -e "$target" ]]; then
    echo "i: '$target' does not exist"
    return 1
  fi
  local abs rel type size perms owner group mtime btime ctime
  abs="${target:A}"
  rel=$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1]))" "$abs")

  local stline
  stline=$(stat -f '%Sp|%Su|%Sg|%z|%Sm|%SB|%Sc' -t '%Y-%m-%d %H:%M:%S' "$target")
  perms="${stline%%|*}"; stline="${stline#*|}"
  owner="${stline%%|*}"; stline="${stline#*|}"
  group="${stline%%|*}"; stline="${stline#*|}"
  size="${stline%%|*}"; stline="${stline#*|}"
  mtime="${stline%%|*}"; stline="${stline#*|}"
  btime="${stline%%|*}"; ctime="${stline#*|}"

  if [[ -L "$target" ]]; then
    type="symlink -> $(readlink "$target")"
  elif [[ -d "$target" ]]; then
    type="directory"
    size=$(du -sh "$target" 2>/dev/null | awk '{print $1}')
  else
    type="file"
    size=$(awk -v s="$size" 'BEGIN{
      if (s<1024) printf "%dB", s
      else if (s<1048576) printf "%.1fK", s/1024
      else if (s<1073741824) printf "%.1fM", s/1048576
      else printf "%.1fG", s/1073741824
    }')
  fi

  print -P "%F{cyan}Path:%f      $abs"
  print -P "%F{cyan}Relative:%f  $rel"
  print -P "%F{cyan}Type:%f      $type"
  print -P "%F{cyan}Size:%f      $size"
  print -P "%F{cyan}Perms:%f     $perms  ($owner:$group)"
  print -P "%F{cyan}Modified:%f  $mtime"
  print -P "%F{cyan}Created:%f   $btime"
  print -P "%F{cyan}Changed:%f   $ctime"
}

# Case-insensitive completion matching (scree -> Screenshots_...)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*' 'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*'

# Tab-completion at command position: suggest only from history, not full $PATH
_history_commands() {
  local -a cmds raw
  raw=(${(f)"$(LC_ALL=C tail -r "$HISTFILE" 2>/dev/null | LC_ALL=C sed -E 's/^: [0-9]+:[0-9]+;//' | awk '{print $1}' | awk '!seen[$0]++')"})
  local c
  for c in $raw; do
    (( $+commands[$c] || $+functions[$c] || $+aliases[$c] || $+builtins[$c] )) && cmds+=("$c")
  done
  compadd -a cmds
}
compdef '_alternative "history:command:_history_commands" "directories:directory:_path_files -/" "files:file:_path_files -f"' -command-

# Tab: past 10 chars, only a double-tap (two Tabs within 0.5s) triggers completion
zmodload zsh/datetime
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

alias py=python3
alias reload="source ~/.zshrc"
alias cl=clear
alias c=clear
alias cc=claude
alias ccc=clang
unalias catmd catm 2>/dev/null
catmd() {
  if [[ "$1" == *.json || "$1" == *.jsonl ]]; then
    jq -C . "$1" | less -R
  elif [[ "$1" == *.yml || "$1" == *.yaml ]]; then
    pygmentize -l yaml -O style=monokai "$1" | less -R
  else
    mdcat --paginate "$@"
  fi
}
catm() {
  if [[ "$1" == *.json || "$1" == *.jsonl ]]; then
    jq -C . "$1"
  elif [[ "$1" == *.yml || "$1" == *.yaml ]]; then
    pygmentize -l yaml -O style=monokai "$1"
  else
    mdcat "$@"
  fi
}
alias ssdm='echo CPU && ps -A -o %cpu | awk '"'"'{s+=$1} END {print s/16 "%"}'"'"' && echo RAM && memory_pressure | grep "System-wide memory free percentage" | awk '"'"'{print 100-$5 "%"}'"'"''

# exp: siehe ~/.local/bin/exp (funktioniert in jeder Shell, jedem Agent via PATH)
