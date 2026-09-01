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
function top  { & "$HOME\Documents\lib\top.ps1" }
function oc  { & opencode }
function op  { & opencode --mini }
function gst  { & git status }


function tailnet   { & "C:\Users\v\Documents\lib\llama_monitor\tailnet.ps1" }
function hardfetch { & "C:\Users\v\Documents\lib\hardfetch\build\Release\hardfetch.exe" }
function ept { python C:\Users\v\Documents\lib\scripts\export_to_phone.py @args }

# cd ohne Argument -> nach lib
if (Get-Alias cd -ErrorAction SilentlyContinue) { Remove-Item Alias:cd -Force }
function cd {
    if ($args.Count -eq 0) { Set-Location "C:\Users\v\Documents\lib" }
    else { Set-Location @args }
}

# -- ops -- ollama ps plus
function ops { python C:\Users\v\documents\lib\ops-llama-ps\ops.py @args }

# -- ssdm -- ssh unraid sata drives info
function ssdm { ssh unraid 'ts=$(date "+%H:%M %d.%m"); for d in /dev/sd[a-z]; do t=$(smartctl -A "$d" 2>/dev/null | awk "/Temperature_Celsius/{print \$10}"); model=$(smartctl -i "$d" 2>/dev/null | awk -F": " "/Device Model/{print \$2}"); [ -n "$t" ] && echo "[$ts] $d ($model): ${t}C"; done' }

# -- wt -- whats running
function wt { python C:\Users\v\Documents\lib\wt-whats-running\wt.py @args }

# -- lsr -- ls recursive
function lsr {
    param([int]$LimitKB = 0)
    $root = (Get-Location).Path
    Write-Host $root
    Get-ChildItem -Path "." -Recurse -Force -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Attributes -notmatch 'System' -and $_.Length -gt 0 -and ($LimitKB -eq 0 -or $_.Length -le ($LimitKB * 1KB)) } |
        Select-Object @{Name = 'KB Size'; Expression = { [math]::Round($_.Length / 1KB, 2) } },
                      @{Name = 'Path'; Expression = { $_.FullName.Substring($root.Length + 1) } },
                      Length, LastWriteTime |
        Format-Table -AutoSize
}

# -- lsf -- ls find
function lsf {
    param([string]$NamePart, [string]$Extension)
    if ([string]::IsNullOrWhiteSpace($NamePart) -and [string]::IsNullOrWhiteSpace($Extension)) {
        throw "lsf braucht mindestens 1 Parameter: z.B. lsf wt oder lsf wt .py oder lsf '' .py"
    }
    Get-ChildItem -Path "." -Recurse -Force -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Attributes -notmatch 'System' -and
            ([string]::IsNullOrWhiteSpace($NamePart) -or $_.Name -like "*$NamePart*") -and
            ([string]::IsNullOrWhiteSpace($Extension) -or $_.Extension -ieq $(if ($Extension.StartsWith('.')) { $Extension } else { ".$Extension" }))
        } |
        Sort-Object FullName -Unique |
        Select-Object @{N = 'Path'; E = { $_.FullName } }
}

# -- lsi -- ls info
function lsi {
    param([Parameter(Mandatory)][string]$Path)
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($item.PSIsContainer) {
        $item | Select-Object Name, FullName, CreationTime, LastWriteTime, @{N = 'Type'; E = { 'Directory' } }
        return
    }
    $bytes = $item.Length
    $size = if ($bytes -ge 1GB) { "{0:N2} GB" -f ($bytes / 1GB) }
            elseif ($bytes -ge 1MB) { "{0:N2} MB" -f ($bytes / 1MB) }
            elseif ($bytes -ge 1KB) { "{0:N2} KB" -f ($bytes / 1KB) }
            else { "{0} B" -f $bytes }
    $item | Select-Object Name, Extension, @{N = 'Size'; E = { $size } }, LastWriteTime, CreationTime, FullName
}

# ===========================================================================
# zsh-style aliases & commands (ported for parity — verified under pwsh)
# ===========================================================================

# ---------------------------------------------------------------------------
# Color helper (parity with zsh's 256-color palette; requires ANSI host)
# ---------------------------------------------------------------------------

function Get-TypeColor {
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Container) { return '34' } # blue (dirs stay simple)
    $ext = [System.IO.Path]::GetExtension($Path).TrimStart('.').ToLower()
    switch ($ext) {
        'py'                                                    { return '214' }
        { $_ -in 'js', 'jsx' }                                  { return '227' }
        { $_ -in 'ts', 'tsx' }                                  { return '75' }
        'go'                                                    { return '80' }
        'rs'                                                    { return '209' }
        { $_ -in 'c', 'cpp', 'h' }                              { return '111' }
        'java'                                                  { return '173' }
        'rb'                                                    { return '203' }
        'php'                                                   { return '140' }
        { $_ -in 'sh', 'zsh', 'ps1', 'psm1' }                   { return '150' }
        'md'                                                    { return '114' }
        'txt'                                                   { return '81' }
        { $_ -in 'json', 'jsonl' }                              { return '141' }
        { $_ -in 'yaml', 'yml' }                                { return '208' }
        { $_ -in 'xml', 'html' }                                { return '172' }
        'toml'                                                  { return '179' }
        'csv'                                                   { return '37' }
        { $_ -in 'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'ico', 'bmp', 'tiff' } { return '213' }
        { $_ -in 'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', 'm4v' }          { return '207' }
        { $_ -in 'zip', 'tar', 'gz', 'rar', '7z', 'bz2' }       { return '203' }
        { $_ -in 'exe', 'ps1', 'cmd', 'bat' }                   { return '150' } # heuristic "executable" bucket
        default                                                 { return '255' } # white-ish
    }
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
        [bool]$ShowHidden = $false
    )
    $stack = [System.Collections.Generic.Stack[string]]::new()
    $stack.Push((Resolve-Path -LiteralPath $Root).Path)
    while ($stack.Count -gt 0) {
        $dir = $stack.Pop()
        $entries = $null
        try { $entries = [System.IO.Directory]::EnumerateFileSystemEntries($dir) } catch { continue }
        foreach ($entry in $entries) {
            $name = [System.IO.Path]::GetFileName($entry)
            $isDir = [System.IO.Directory]::Exists($entry)

            # Path-pattern prune (e.g. */ggml/src) checked before name-based prune.
            $pathPruned = $false
            foreach ($pp in $Script:PrunePathPatterns) { if ($entry -like $pp) { $pathPruned = $true; break } }

            if ($isDir -and ($pathPruned -or (Test-IsPruned $name))) { continue }

            if (-not $ShowHidden) {
                # Windows "hidden" is an ATTRIBUTE, not a dot-prefix convention like Unix.
                # Hide on EITHER signal so dotfiles behave like on macOS/Linux.
                $isHiddenAttr = $false
                try {
                    $attrs = [System.IO.File]::GetAttributes($entry)
                    $isHiddenAttr = [bool]($attrs -band [System.IO.FileAttributes]::Hidden)
                } catch {
                    # Unreadable entries (e.g. device paths like \\.\nul) -> treat as visible.
                    $isHiddenAttr = $false
                }
                $isDotfile = $name.StartsWith('.')
                if ($isHiddenAttr -or $isDotfile) {
                    if ($isDir) { continue } # don't descend into hidden dirs either
                    else { continue }
                }
            }

            Write-Output $entry
            if ($isDir) { $stack.Push($entry) }
        }
    }
}

# ---------------------------------------------------------------------------
# f / ff — recursive multi-pattern search. f hides dotfiles/hidden, ff shows
# them. Category order: txt, md, executable, image, video, other-known (by
# recency), then unrecognized types + directories (alphabetical).
# ---------------------------------------------------------------------------

function Invoke-FindImpl {
    param(
        [bool]$ShowHidden,
        [string[]]$FindArgs
    )
    if ($FindArgs.Count -eq 0) {
        Write-Host "usage: f/ff <pattern> [pattern2 ...] [.ext]"
        return
    }

    $patterns = @()
    $extensions = @()
    $root = '.'
    $rootSet = $false
    $dirsOnly = $false

    foreach ($arg in $FindArgs) {
        if ($arg -eq '*') {
            $dirsOnly = $true
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

    if ($patterns.Count -eq 0 -and $extensions.Count -eq 0 -and -not $dirsOnly) {
        Write-Host "usage: f/ff [dir/] <pattern> [pattern2 ...] [.ext] [.ext2 ...] [*]"
        return
    }

    $entries = Get-PrunedEntries -Root $root -ShowHidden $ShowHidden
    if ($dirsOnly) {
        $entries = $entries | Where-Object { [System.IO.Directory]::Exists($_) }
    }

    # AND across patterns; patterns containing a path separator match full path, else basename.
    foreach ($p in $patterns) {
        $isPathPattern = $p -match '[\\/]'
        $glob = if ($p -match '\*') { $p } else { "*$p*" }
        $entries = $entries | Where-Object {
            if ($isPathPattern) { $_ -like "*$glob*" -or ($_ -replace '\\', '/') -like "*$glob*" }
            else { [System.IO.Path]::GetFileName($_) -like $glob }
        }
    }

    # OR across extensions
    if ($extensions.Count -gt 0) {
        $entries = $entries | Where-Object {
            $name = [System.IO.Path]::GetFileName($_)
            $matched = $false
            foreach ($e in $extensions) { if ($name -like "*$e") { $matched = $true; break } }
            $matched
        }
    }

    $entries = @($entries)
    if ($entries.Count -eq 0) {
        Write-Host (Write-Colored "# 0 matches found in $((Resolve-Path $root).Path)" '36')
        return
    }

    $imgExt = 'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'ico', 'bmp', 'tiff'
    $vidExt = 'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', 'm4v'
    $knownExt = 'py', 'js', 'jsx', 'ts', 'tsx', 'go', 'rs', 'c', 'cpp', 'h', 'java', 'rb', 'php',
                'sh', 'zsh', 'ps1', 'json', 'jsonl', 'yaml', 'yml', 'xml', 'html', 'toml', 'csv',
                'zip', 'tar', 'gz', 'rar', '7z', 'bz2'

    $ranked = foreach ($e in $entries) {
        $isDir = [System.IO.Directory]::Exists($e)
        $ext = [System.IO.Path]::GetExtension($e).TrimStart('.').ToLower()
        $rank =
            if ($isDir) { 6 }
            elseif ($ext -eq 'txt') { 0 }
            elseif ($ext -eq 'md') { 1 }
            elseif ($ext -in 'exe', 'cmd', 'bat', 'ps1') { 2 } # Windows has no unix "+x bit"; approximate via extension
            elseif ($ext -in $imgExt) { 3 }
            elseif ($ext -in $vidExt) { 4 }
            elseif ($ext -in $knownExt) { 5 }
            else { 6 }
        [PSCustomObject]@{ Path = $e; Rank = $rank; IsDir = $isDir; LastWrite = (Get-Item -LiteralPath $e -Force).LastWriteTime }
    }

    $known = $ranked | Where-Object { $_.Rank -le 5 } | Sort-Object Rank, @{Expression = 'LastWrite'; Descending = $true }
    $rest = $ranked | Where-Object { $_.Rank -eq 6 } | Sort-Object Path
    $final = @($known) + @($rest)

    Write-Host (Write-Colored "# $($final.Count) matches found in $((Resolve-Path $root).Path)" '36')
    foreach ($r in $final) {
        $rel = Resolve-Path -Relative -LiteralPath $r.Path
        $disp = if ($r.IsDir) { "$rel\" } else { $rel }
        $color = Get-TypeColor $r.Path
        Write-Host (Write-Colored $disp $color)
    }
}

function f  { Invoke-FindImpl -ShowHidden $false -FindArgs $args }
function ff { Invoke-FindImpl -ShowHidden $true  -FindArgs $args }

# ---------------------------------------------------------------------------
# t — colorized tree, dirs first, same prune list as f/ff
# ---------------------------------------------------------------------------

function t {
    $dirsOnly = $false
    $Dir = '.'
    $remaining = @()
    $skipNext = $false
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($skipNext) { $skipNext = $false; continue }
        if ($i -eq 0 -and $args[$i] -eq '*') {
            $dirsOnly = $true
            continue
        }
        if ($i -eq 0 -and $args[$i] -notmatch '^-') {
            $Dir = $args[$i]
            continue
        }
        $remaining += $args[$i]
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
            $color = Get-TypeColor $item.FullName
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

    Write-Host (Write-Colored "Path:     " '36') "$abs"
    Write-Host (Write-Colored "Relative: " '36') "$rel"
    Write-Host (Write-Colored "Type:     " '36') "$type"
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
        $color = Get-TypeColor $item.FullName
        $name = if ($item.PSIsContainer) { "$($item.Name)\" } else { $item.Name }
        $meta = "{0,-6} {1,8}  {2}" -f $item.Mode, $size, $mtime
        Write-Host (Write-Colored $meta '242') "  $(Write-Colored $name $color)"
    }
}

# ---------------------------------------------------------------------------
# catmd / catm — markdown/json/jsonl/yaml viewer (reuses cross-platform tools:
# jq, mdcat, pygmentize; falls back to Get-Content when a tool is missing).
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
        if (Get-Command pygmentize -ErrorAction SilentlyContinue) {
            try { $output = pygmentize -l yaml -O style=monokai $FilePath 2>$null } catch { $output = $null }
        }
        if ($null -eq $output) { $output = Get-Content $FilePath }
    }
    else {
        if (Get-Command mdcat -ErrorAction SilentlyContinue) {
            try { $output = mdcat @args 2>$null } catch { $output = $null }
        }
        if ($null -eq $output) { $output = Get-Content $FilePath }
    }

    if ($Paginate -and (Get-Command less -ErrorAction SilentlyContinue)) {
        $output | less -R
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
    param([string]$Dir = '.')
    Get-ChildItem -LiteralPath $Dir -Force | Sort-Object Name |
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

# Clear screen on load (defensive: only when a real console is attached).
try { Clear-Host } catch { }

$env:OPENAI_API_KEY = "local-dummy"



# hardfetch
Set-Alias -Name hrf -Value 'C:\Users\v\Documents\lib\hardfetch\bin\hardfetch.exe'
