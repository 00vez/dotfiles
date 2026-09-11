#Requires -Version 7.2
# PowerShell profile — PowerShell 7.2+ in Windows Terminal.
# Two parts: (1) personal helper functions, (2) zsh-style aliases/commands
# ported for parity with the dev-bootcamp zsh setup. All ported commands were
# verified working under real pwsh on this machine.

# ===========================================================================
# Personal helper functions
# ===========================================================================

function tten { & "$HOME\bin\tten.ps1" @args }
function ttde { & "$HOME\bin\ttde.ps1" @args }
function gst  { & git status }
function oc { & opencode }

function tailnet   { & "C:\Users\v\Documents\lib\llama_monitor\tailnet.ps1" }
function hardfetch { & "C:\Users\v\Documents\lib\hardfetch\bin\hardfetch.exe" }
function ept { python C:\Users\v\Documents\lib\scripts\export_to_phone.py @args }

# cd ohne Argument -> nach ~/Documents
if (Get-Alias cd -ErrorAction SilentlyContinue) { Remove-Item Alias:cd -Force }
function cd {
    if ($args.Count -eq 0) { Set-Location "$HOME\Documents\lib" }
    else { Set-Location @args }
}

# -- ops -- ollama ps plus
function ops { python C:\Users\v\documents\lib\ops-llama-ps\ops.py @args }

# -- ssdm -- ssh unraid sata drives info
function ssdm { ssh unraid 'ts=$(date "+%H:%M %d.%m"); for d in /dev/sd[a-z]; do t=$(smartctl -A "$d" 2>/dev/null | awk "/Temperature_Celsius/{print \$10}"); model=$(smartctl -i "$d" 2>/dev/null | awk -F": " "/Device Model/{print \$2}"); [ -n "$t" ] && echo "[$ts] $d ($model): ${t}C"; done' }

# -- wt -- whats running
function wt { python C:\Users\v\Documents\lib\wt-whats-running\wt.py @args }

# -- tmux sessions (socket per name) --
function tn {
    param(
        [Parameter(Position = 0)]
        [string]$Name = 'main'
    )

    tmux -L $Name new-session -A -s $Name
}

function ta {
    param(
        [Parameter(Position = 0)]
        [string]$Name = 'main'
    )

    tmux -L $Name attach -t $Name
}

function tl {
    param(
        [Parameter(Position = 0)]
        [string]$Name = 'main'
    )

    tmux -L $Name ls
}

function tk {
    param(
        [Parameter(Position = 0)]
        [string]$Name = 'main'
    )

    tmux -L $Name kill-server
}

# ===========================================================================
# zsh-style aliases & commands (ported for parity — verified under pwsh)
# ===========================================================================

# ---------------------------------------------------------------------------
# Color helper (parity with zsh's 256-color palette; requires ANSI host)
# ---------------------------------------------------------------------------

$Script:ExtColors = @{}
$Script:ExtColorKeys = @{
    'py' = '214'; 'js' = '227'; 'jsx' = '227'; 'ts' = '75'; 'tsx' = '75'; 'go' = '80'; 'rs' = '209';
    'c' = '111'; 'cpp' = '111'; 'h' = '111'; 'java' = '173'; 'rb' = '203'; 'php' = '140';
    'sh' = '150'; 'zsh' = '150'; 'ps1' = '150'; 'psm1' = '150';
    'md' = '114'; 'txt' = '81';
    'json' = '141'; 'jsonl' = '141';
    'yaml' = '208'; 'yml' = '208';
    'xml' = '172'; 'html' = '172'; 'toml' = '179'; 'csv' = '37';
    'png' = '213'; 'jpg' = '213'; 'jpeg' = '213'; 'gif' = '213'; 'svg' = '213'; 'webp' = '213'; 'ico' = '213'; 'bmp' = '213'; 'tiff' = '213';
    'mp4' = '207'; 'mov' = '207'; 'avi' = '207'; 'mkv' = '207'; 'webm' = '207'; 'flv' = '207'; 'wmv' = '207'; 'm4v' = '207';
    'zip' = '203'; 'tar' = '203'; 'gz' = '203'; 'rar' = '203'; '7z' = '203'; 'bz2' = '203';
    'exe' = '150'; 'cmd' = '150'; 'bat' = '150'
}
foreach ($k in $Script:ExtColorKeys.Keys) { $Script:ExtColors[$k] = $Script:ExtColorKeys[$k] }

function Get-TypeColor {
    param([Parameter(Mandatory)][string]$Path, [bool]$IsDir = $false)
    if ($IsDir) { return '34' } # blue (dirs stay simple)
    $ext = [System.IO.Path]::GetExtension($Path).TrimStart('.').ToLower()
    if ($ext) { $c = $Script:ExtColors[$ext]; if ($c) { return $c } }
    return '255'
}

function Write-Colored {
    param([string]$Text, [string]$Code)
    # Raw ANSI escapes so the exact 256-color codes match the zsh version 1:1.
    $esc = [char]27
    "$esc[38;5;${Code}m${Text}${esc}[0m"
}

# ---------------------------------------------------------------------------
# Shared pruned recursive walker (mirrors `find ... -prune`: skip build/VCS
# noise instead of filtering after the fact).
# ---------------------------------------------------------------------------

$Script:PruneNames = @(
    '.git', 'node_modules', '__pycache__', '.venv', 'venv', '.pytest_cache', '.mypy_cache',
    '.tox', 'target', '.next', '.nuxt', '.cache', '.terraform', 'dist', 'build', 'coverage',
    'vendor', 'Pods', '.gradle', '.m2', '.build', '.eggs', '.angular', '.turbo',
    '.parcel-cache', 'CMakeFiles', 'site-packages'
)
$Script:PruneNamePatterns = @('*.egg-info', 'cmake-build-*')
$Script:PrunePathPatterns = @('*\ggml\src', '*/ggml/src')

function Test-IsPruned {
    param([string]$Name)
    if ($Script:PruneNames -contains $Name) { return $true }
    foreach ($pat in $Script:PruneNamePatterns) { if ($Name -like $pat) { return $true } }
    return $false
}

function Get-PrunedEntries {
    param(
        [Parameter(Mandatory)][string]$Root,
        [bool]$ShowHidden = $false,
        [int]$MaxDepth = 0
    )
    $rootAbs = (Resolve-Path -LiteralPath $Root).Path
    $stack = [System.Collections.Generic.Stack[System.IO.DirectoryInfo]]::new()
    $stack.Push([System.IO.DirectoryInfo]::new($rootAbs))
    while ($stack.Count -gt 0) {
        $dir = $stack.Pop()
        try {
            foreach ($item in $dir.EnumerateFileSystemInfos()) {
                $name = $item.Name
                $isDir = [bool]($item.Attributes -band [System.IO.FileAttributes]::Directory)

                # Path-pattern prune (e.g. */ggml/src) checked before name-based prune.
                $pathPruned = $false
                foreach ($pp in $Script:PrunePathPatterns) { if ($item.FullName -like $pp) { $pathPruned = $true; break } }

                if ($isDir -and ($pathPruned -or (Test-IsPruned $name))) { continue }

                if (-not $ShowHidden) {
                    # Windows "hidden" is an ATTRIBUTE, not a dot-prefix convention like Unix.
                    # Hide on EITHER signal so dotfiles behave like on macOS/Linux.
                    $isHidden = [bool]($item.Attributes -band [System.IO.FileAttributes]::Hidden) -or $name.StartsWith('.')
                    if ($isHidden) { continue }
                }

                $prefix = if ($isDir) { 'D' } else { 'F' }
                "$prefix$($item.FullName)"
                if ($isDir) {
                    # Tiefe = Pfadsegmente relativ zum Root. Direkte Kinder = Tiefe 1.
                    if ($MaxDepth -gt 0 -and $item.FullName.Substring($rootAbs.Length).Split([char]'\', [System.StringSplitOptions]::RemoveEmptyEntries).Count -ge $MaxDepth) { continue }
                    $stack.Push($item)
                }
            }
        } catch {
            # Broken symlinks/junctions (z.B. scoop "current"-Links) überspringen.
            continue
        }
    }
}

# ---------------------------------------------------------------------------
# f / ff — recursive multi-pattern search. f hides dotfiles/hidden, ff shows
# them. Category order: txt, md, executable, image, video, other-known (by
# recency), then unrecognized types + directories (alphabetical).
# ---------------------------------------------------------------------------

function Show-FindHelp {
    Write-Host (Write-Colored "f/ff – rekursive Dateisuche. " '36') "ohne Argument oder 'help' zeigt diese Parameterübersicht."
    Write-Host ""
    Write-Host "Syntax:  f  <pattern> [pattern2 ...] [.ext] [dir/] [*] [*N] [,text] [=text] [-N] [+N] [:N]"
    Write-Host ""
    Write-Host "  <pattern>   Dateiname enthält Muster (mehrere = UND-Verknüpfung)"
    Write-Host "  .ext        nur diese Endung (z.B. .md .txt; mehrere = ODER)"
    Write-Host "  dir/        nur in diesem Verzeichnis suchen (z.B. src/)"
    Write-Host "  *           nur Verzeichnisse anzeigen (nicht mit ,/= kombinierbar)"
    Write-Host "  *N          nur erste N Ergebnisse zeigen (z.B. *10)"
    Write-Host "  ,text       Dateiinhalt muss Text enthalten (mehrere = UND)"
    Write-Host "  =text       Treffer-Tag wenn Datei Text enthält (nur Anzeige)"
    Write-Host "  -N / +N     N Zeilen Kontext vor/nach Content-Treffer (z.B. -2 +2)"
    Write-Host "  :N          maximale Suchtiefe ab Suchroot (z.B. :2)"
    Write-Host "  ff          wie f, zeigt zusätzlich versteckte Dateien"
    Write-Host ""
    Write-Host "Sortierung: txt > md > ausführbar > Bild > Video > bekannt (neueste zuerst), Rest alphabetisch."}

function Invoke-FindImpl {
    param(
        [bool]$ShowHidden,
        [string[]]$FindArgs
    )
    if ($FindArgs.Count -eq 0 -or $FindArgs[0] -in 'help', '?', '--help', '-h') {
        Show-FindHelp
        return
    }

    $patterns = @()
    $extensions = @()
    $reqContent = @()
    $optContent = @()
    $root = '.'
    $rootSet = $false
    $dirsOnly = $false
    $maxDepth = 0
    $limit = 0
    $beforeCtx = 0
    $afterCtx = 0

    foreach ($arg in $FindArgs) {
        if ($arg -eq '*') {
            $dirsOnly = $true
        }
        elseif ($arg -match '^\*(\d+)$') {
            $limit = [int]$Matches[1]
        }
        elseif ($arg -match '^,(.+)$') {
            $reqContent += $Matches[1]
        }
        elseif ($arg -match '^=(.+)$') {
            $optContent += $Matches[1]
        }
        elseif ($arg -match '^-(\d+)$') {
            $beforeCtx = [int]$Matches[1]
        }
        elseif ($arg -match '^\+(\d+)$') {
            $afterCtx = [int]$Matches[1]
        }
        elseif ($arg -eq '.') {
            if ($patterns.Count -gt 0) {
                $prev = $patterns[-1]
                if (-not (Test-Path -LiteralPath $prev -PathType Container)) {
                    Write-Host "f/ff: '$prev' is not a directory"
                    return
                }
                if ($rootSet) {
                    Write-Host "f/ff: only one search directory allowed (got '$root' and '$prev')"
                    return
                }
                $patterns = $patterns[0..($patterns.Count - 2)]
                $root = $prev
                $rootSet = $true
            }
            else {
                if ($rootSet) {
                    Write-Host "f/ff: only one search directory allowed (got '$root' and '.')"
                    return
                }
                $root = '.'
                $rootSet = $true
            }
        }
        elseif ($arg -match '[\\/]$' -or $arg -eq '..') {
            if (-not (Test-Path -LiteralPath $arg -PathType Container)) {
                Write-Host "f/ff: '$arg' is not a directory"
                return
            }
            if ($rootSet) {
                Write-Host "f/ff: only one search directory allowed (got '$root' and '$arg')"
                return
            }
            $root = $arg
            $rootSet = $true
        }
        elseif ($arg -match '^[^.*].*\.$' -and $arg -notmatch '\*') {
            $cand = $arg.TrimEnd('.')
            if (-not (Test-Path -LiteralPath $cand -PathType Container)) {
                Write-Host "f/ff: '$cand' is not a directory"
                return
            }
            if ($rootSet) {
                Write-Host "f/ff: only one search directory allowed (got '$root' and '$cand')"
                return
            }
            $root = $cand
            $rootSet = $true
        }
        elseif ($arg.StartsWith('.')) {
            if (Test-Path -LiteralPath $arg -PathType Container) {
                if ($rootSet) {
                    Write-Host "f/ff: only one search directory allowed (got '$root' and '$arg')"
                    return
                }
                $root = $arg
                $rootSet = $true
            }
            else {
                $extensions += $arg
            }
        }
        else {
            $patterns += $arg
        }
    }

    if ($patterns.Count -eq 0 -and $extensions.Count -eq 0 -and $reqContent.Count -eq 0 -and $optContent.Count -eq 0 -and -not $dirsOnly -and $maxDepth -eq 0) {
        Show-FindHelp
        return
    }
    if ($dirsOnly -and ($reqContent.Count -gt 0 -or $optContent.Count -gt 0)) {
        Write-Host "f/ff: Content-Suche nicht mit '*' kombinierbar"
        return
    }

    # Sammeln, Content-Filter, Ranking wie zsh: txt > md > exe > Bild > Video >
    # bekannt (neueste zuerst), Rest alphabetisch. Limit vor Count anwenden.
    $rootAbs = (Resolve-Path -LiteralPath $root).Path
    Write-Host (Write-Colored $rootAbs '36')

    $found = @()
    foreach ($raw in Get-PrunedEntries -Root $root -ShowHidden $ShowHidden -MaxDepth $maxDepth) {
        $isDir = $raw[0] -eq 'D'
        $entry = $raw.Substring(1)
        if ($dirsOnly -and -not $isDir) { continue }
        $name = [System.IO.Path]::GetFileName($entry)
        if ($patterns.Count -gt 0) {
            $skip = $false
            foreach ($p in $patterns) {
                $glob = if ($p -match '\*') { $p } else { "*$p*" }
                if ($p -match '[\\/]') {
                    if ($entry -notlike "*$glob*" -and ($entry -replace '\\', '/') -notlike "*$glob*") { $skip = $true; break }
                } else {
                    if ($name -notlike $glob) { $skip = $true; break }
                }
            }
            if ($skip) { continue }
        }
        if ($extensions.Count -gt 0) {
            $matched = $false
            foreach ($e in $extensions) { if ($name -like "*$e") { $matched = $true; break } }
            if (-not $matched) { continue }
        }
        $found += [pscustomobject]@{ Entry = $entry; IsDir = $isDir }
    }

    $tags = @{}
    if ($reqContent.Count -gt 0 -or $optContent.Count -gt 0) {
        $filtered = @()
        foreach ($it in $found) {
            $fp = $it.Entry
            if (-not (Test-Path -LiteralPath $fp -PathType Leaf)) {
                if ($reqContent.Count -eq 0) { $filtered += $it }
                continue
            }
            $ok = $true
            foreach ($rc in $reqContent) {
                if (-not (Select-String -LiteralPath $fp -Pattern $rc -SimpleMatch -Quiet)) { $ok = $false; break }
            }
            if (-not $ok) { continue }
            $tl = @()
            foreach ($oc in $optContent) {
                if (Select-String -LiteralPath $fp -Pattern $oc -SimpleMatch -Quiet) { $tl += $oc }
            }
            if ($tl.Count -gt 0) { $tags[$fp] = ($tl -join ', ') }
            $filtered += $it
        }
        $found = $filtered
    }

    $knownExt = @('py','js','jsx','ts','tsx','go','rs','c','cpp','h','java','rb','php','sh','zsh','ps1','psm1','json','jsonl','yaml','yml','xml','html','toml','csv','zip','tar','gz','rar','7z','bz2')
    $imgExt = @('png','jpg','jpeg','gif','svg','webp','ico','bmp','tiff')
    $vidExt = @('mp4','mov','avi','mkv','webm','flv','wmv','m4v')
    $ranked = @()
    foreach ($it in $found) {
        $ext = [System.IO.Path]::GetExtension($it.Entry).TrimStart('.').ToLower()
        if ($it.IsDir) { $rank = 6 }
        elseif ($ext -eq 'txt') { $rank = 0 }
        elseif ($ext -eq 'md') { $rank = 1 }
        elseif ($imgExt -contains $ext) { $rank = 3 }
        elseif ($vidExt -contains $ext) { $rank = 4 }
        elseif ($knownExt -contains $ext) { $rank = 5 }
        else {
            try { $isExe = -not (Test-Path -LiteralPath $it.Entry -PathType Container) -and ((Get-Item -LiteralPath $it.Entry).Extension -match '^\.(exe|cmd|bat|ps1|sh)$') } catch { $isExe = $false }
            $rank = if ($isExe) { 2 } else { 6 }
        }
        try { $mtime = (Get-Item -LiteralPath $it.Entry).LastWriteTime } catch { $mtime = [datetime]::MinValue }
        $ranked += [pscustomobject]@{ Rank = $rank; Mtime = $mtime; Item = $it }
    }
    $known = @($ranked | Where-Object { $_.Rank -le 5 } | Sort-Object Rank, @{ E = 'Mtime'; Descending = $true })
    $rest = @($ranked | Where-Object { $_.Rank -eq 6 } | Sort-Object { $_.Item.Entry })
    $ordered = @($known + $rest)
    if ($limit -gt 0 -and $ordered.Count -gt $limit) { $ordered = @($ordered[0..($limit - 1)]) }

    $count = 0
    foreach ($r in $ordered) {
        $entry = $r.Item.Entry; $isDir = $r.Item.IsDir
        $rel = $entry.Substring($rootAbs.Length).TrimStart('\')
        if ($isDir) { $rel = "$rel\" }
        $line = Write-Colored $rel (Get-TypeColor $entry -IsDir $isDir)
        if ($tags.ContainsKey($entry)) { $line += "  $(Write-Colored "[$($tags[$entry])]" '3')" }
        Write-Host "  $line"
        if ($reqContent.Count -gt 0 -and (Test-Path -LiteralPath $entry -PathType Leaf)) {
            $ctx = @()
            foreach ($rc in $reqContent) { $ctx += Select-String -LiteralPath $entry -Pattern $rc -SimpleMatch -Context $beforeCtx,$afterCtx }
            foreach ($m in $ctx) {
                $txt = ($m.Line.Length -gt 64) ? $m.Line.Substring(0,64) + '…' : $m.Line
                Write-Host ("      > {0,5}  {1}" -f $m.LineNumber, $txt)
            }
        }
        $count++
    }
    Write-Host (Write-Colored "Anzahl # $count" '36')
}

function f  { Invoke-FindImpl -ShowHidden $false -FindArgs $args }
function ff { Invoke-FindImpl -ShowHidden $true  -FindArgs $args }

# ---------------------------------------------------------------------------
# t — colorized tree, dirs first, same prune list as f/ff
# ---------------------------------------------------------------------------

function t {
    $dirsOnly = $false
    $Dir = '.'
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($i -eq 0 -and $args[$i] -eq '*') {
            $dirsOnly = $true
            continue
        }
        if ($i -eq 0 -and $args[$i] -notmatch '^-') {
            $Dir = $args[$i]
            continue
        }
    }

    if (-not (Test-Path -LiteralPath $Dir -PathType Container)) {
        Write-Host "t: '$Dir' is not a directory"
        return
    }
    Write-Host (Write-Colored (Resolve-Path $Dir).Path '36')

    $Script:TreeShown = 0
    $Script:TreeMax = 100
    $Script:TreeTruncated = $false

    function Write-TreeLevel {
        param([string]$Path, [string]$Prefix)
        if ($Script:TreeShown -ge $Script:TreeMax) { return }
        $items = @()
        try { $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop |
              Where-Object { -not (Test-IsPruned $_.Name) } |
              Where-Object { -not $dirsOnly -or $_.PSIsContainer } |
              Sort-Object @{Expression = { -not $_.PSIsContainer }}, Name } catch { return }

        for ($idx = 0; $idx -lt $items.Count; $idx++) {
            if ($Script:TreeShown -ge $Script:TreeMax) {
                if (-not $Script:TreeTruncated) {
                    Write-Host (Write-Colored "... truncated — showing first $Script:TreeMax items. Use f/ff to search." '244')
                    $Script:TreeTruncated = $true
                }
                return
            }
            $item = $items[$idx]
            $isLast = $idx -eq ($items.Count - 1)
            $connector = if ($isLast) { '└── ' } else { '├── ' }
            $color = Get-TypeColor $item.FullName -IsDir $item.PSIsContainer
            $label = if ($item.PSIsContainer) { "$($item.Name)\" } else { $item.Name }
            Write-Host "$Prefix$connector$(Write-Colored $label $color)"
            $Script:TreeShown++
            if ($item.PSIsContainer) {
                $childPrefix = $Prefix + $(if ($isLast) { '    ' } else { '│   ' })
                Write-TreeLevel -Path $item.FullName -Prefix $childPrefix
            }
        }
    }
    Write-TreeLevel -Path (Resolve-Path $Dir).Path -Prefix ''
}

# ---------------------------------------------------------------------------
# i — path info: absolute/relative, type, size, timestamps, ACL owner.
# NOTE: Windows/NTFS has no direct equivalent of Unix "ctime" (metadata-changed
# timestamp) exposed via standard APIs — that field is omitted, not faked.
# ---------------------------------------------------------------------------

function i {
    param([string]$TargetPath = '.')
    if (-not (Test-Path -LiteralPath $TargetPath)) {
        Write-Host "i: '$TargetPath' does not exist"
        return
    }
    $item = Get-Item -LiteralPath $TargetPath -Force
    $abs = $item.FullName
    $rel = Resolve-Path -Relative -LiteralPath $TargetPath

    $type = if ($item.PSIsContainer) { 'directory' }
            elseif ($item.LinkType) { "symlink -> $($item.Target)" }
            else { 'file' }

    $size =
        if ($item.PSIsContainer) {
            $bytes = (Get-ChildItem -LiteralPath $abs -Recurse -File -Force -ErrorAction SilentlyContinue |
                      Measure-Object -Property Length -Sum).Sum
            if (-not $bytes) { $bytes = 0 }
            Format-Bytes $bytes
        } else {
            Format-Bytes $item.Length
        }

    $owner = (Get-Acl -LiteralPath $abs).Owner

    Write-Host (Write-Colored "Name:     " '36') $item.Name
    Write-Host (Write-Colored "Type:     " '36') $type
    if (-not $item.PSIsContainer) { Write-Host (Write-Colored "Ext:      " '36') $item.Extension }
    Write-Host (Write-Colored "Path:     " '36') "$abs"
    Write-Host (Write-Colored "Relative: " '36') "$rel"
    Write-Host (Write-Colored "Size:     " '36') "$size"
    Write-Host (Write-Colored "Owner:    " '36') "$owner"
    Write-Host (Write-Colored "Modified: " '36') "$($item.LastWriteTime)"
    Write-Host (Write-Colored "Created:  " '36') "$($item.CreationTime)"
    Write-Host (Write-Colored "Accessed: " '36') "$($item.LastAccessTime)"
}

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -lt 1KB) { return "${Bytes}B" }
    if ($Bytes -lt 1MB) { return "{0:N1}K" -f ($Bytes / 1KB) }
    if ($Bytes -lt 1GB) { return "{0:N1}M" -f ($Bytes / 1MB) }
    return "{0:N1}G" -f ($Bytes / 1GB)
}

# ---------------------------------------------------------------------------
# ll — colorized long listing (non-recursive), same color scheme as f/ff/t
# ---------------------------------------------------------------------------

function ll {
    $dirsOnly = $false
    $Dir = '.'
    if ($args.Count -gt 0 -and $args[0] -eq '*') {
        $dirsOnly = $true
        if ($args.Count -gt 1) { $Dir = $args[1] }
    }
    elseif ($args.Count -gt 0) { $Dir = $args[0] }

    if (-not (Test-Path -LiteralPath $Dir -PathType Container)) {
        Write-Host "ll: '$Dir' is not a directory"
        return
    }
    $items = Get-ChildItem -LiteralPath $Dir -Force |
        Where-Object { -not $_.Name.StartsWith('.') } |
        Where-Object { -not $dirsOnly -or $_.PSIsContainer } |
        Sort-Object Name
    foreach ($item in $items) {
        $size = if ($item.PSIsContainer) { '' } else { Format-Bytes $item.Length }
        $mtime = $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
        $color = Get-TypeColor $item.FullName -IsDir $item.PSIsContainer
        $name = if ($item.PSIsContainer) { "$($item.Name)\" } else { $item.Name }
        $meta = "{0,-6} {1,8}  {2}" -f $item.Mode, $size, $mtime
        Write-Host (Write-Colored $meta '242') "  $(Write-Colored $name $color)"
    }
}

# ---------------------------------------------------------------------------
# catmd / catm — markdown/json/jsonl/yaml viewer (reuses cross-platform tools:
# jq, mdcat, pygmentize; falls back to Get-Content when a tool is missing).
# NOTE: mdcat/pygmentize strip all styling when stdout is a pipe — that's why
# --ansi (mdcat) forces colors even when captured, and YAML runs uncaptured
# straight to the console. Paging uses native Out-Host -Paging (no `less` on
# Windows).
# ---------------------------------------------------------------------------

function Invoke-CatMdImpl {
    param([bool]$Paginate)
    if ($args.Count -eq 0) { Write-Host "usage: catm/catmd <file>"; return }
    $FilePath = $args[0]
    if (-not (Test-Path -LiteralPath $FilePath)) { Write-Host "catm: '$FilePath' not found"; return }

    $output = $null
    if ($FilePath -match '\.jsonl?$') {
        if (Get-Command jq -ErrorAction SilentlyContinue) {
            try { $output = jq -C . $FilePath 2>$null } catch { $output = $null }
        }
        if ($null -eq $output) { $output = Get-Content $FilePath }
    }
    elseif ($FilePath -match '\.ya?ml$') {
        if (-not $Paginate -and (Get-Command pygmentize -ErrorAction SilentlyContinue)) {
            & pygmentize -l yaml -O style=monokai $FilePath
            return
        }
        $output = Get-Content $FilePath
    }
    else {
        if (Get-Command mdcat -ErrorAction SilentlyContinue) {
            # --ansi erzwingt Styling auch bei Pipe-Ausgabe, --columns 0 deaktiviert
            # Hard-Wrapping (das Terminal soft-wrappt selbst).
            try { $output = mdcat --ansi --columns 0 $FilePath 2>$null } catch { $output = $null }
        }
        if ($null -eq $output) { $output = Get-Content $FilePath }
    }

    if ($Paginate) {
        # Out-Host -Paging blockiert bei umgeleitetem stdin (Jobs/CI) -> dort dumps.
        if ([Console]::IsInputRedirected) { $output }
        else {
            # Q-Quit des Pagers wirft OperationStopped -> still schlucken, kein roter Error.
            try { $output | Out-Host -Paging }
            catch [System.Management.Automation.OperationStoppedException] { }
            catch [System.Management.Automation.PipelineStoppedException] { }
        }
    } else {
        $output
    }
}

function catm  { Invoke-CatMdImpl -Paginate $false @args }
function catmd { Invoke-CatMdImpl -Paginate $true  @args }

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------

Set-Alias -Name cl  -Value Clear-Host
if (Get-Command claude -ErrorAction SilentlyContinue) { Set-Alias -Name cc -Value claude }
if (Get-Command python -ErrorAction SilentlyContinue) { Set-Alias -Name py -Value python }

function Invoke-Reload { . $PROFILE }
Set-Alias -Name reload -Value Invoke-Reload

function ..  { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

function l {
    $dirsOnly = $false
    $Dir = '.'
    if ($args.Count -gt 0 -and $args[0] -eq '*') {
        $dirsOnly = $true
        if ($args.Count -gt 1) { $Dir = $args[1] }
    }
    elseif ($args.Count -gt 0) { $Dir = $args[0] }

    if (-not (Test-Path -LiteralPath $Dir -PathType Container)) {
        Write-Host "l: '$Dir' is not a directory"
        return
    }
    Get-ChildItem -LiteralPath $Dir -Force |
        Where-Object { -not $dirsOnly -or $_.PSIsContainer } |
        Sort-Object Name |
        Format-Table Mode, LastWriteTime, @{Name = 'Size'; Expression = { Format-Bytes $_.Length } }, Name -AutoSize
}

# ===========================================================================
# Host / module setup
# ===========================================================================

# PowerToys CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound

# autocd: a bare path changes directory (like zsh `setopt autocd`).
# Chains any pre-existing CommandNotFound handler (e.g. PowerToys suggestions).
if (-not $Script:AutocdRegistered) {
    function global:__autocdNoop { }
    $Script:AutocdNoop = Get-Command __autocdNoop
    $Script:PrevCommandNotFound = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction
    $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
        param($Name, $EventArgs)
        if (Test-Path -LiteralPath $Name -ErrorAction SilentlyContinue) {
            Set-Location -LiteralPath $Name
            $EventArgs.StopSearch = $true
            $EventArgs.Command = $Script:AutocdNoop
            return
        }
        if ($Script:PrevCommandNotFound) { $Script:PrevCommandNotFound.Invoke($null, $EventArgs) }
    }
    $Script:AutocdRegistered = $true
}
