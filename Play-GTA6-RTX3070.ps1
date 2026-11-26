# Unified VIctory Launcher - Optimized for NVIDIA GeForce RTX 3070 (8 GB) + AMD Ryzen 5 5600XT (6C/12T) + 32 GB RAM
# Integrates VIctory-7900XTX renderer ports + victory-fork fixes + kelvaroq 8GB VRAM profile + DexNom shader/ambient work.
# Usage:
#   .\Play-GTA6-RTX3070.ps1              # Launch GTA VI (1080p, RT off, max FPS)
#   .\Play-GTA6-RTX3070.ps1 -Warm        # Pre-translate shaders & warm pipelines first, then launch
#   .\Play-GTA6-RTX3070.ps1 -Safe        # Safe fallback mode (disables experimental ports if needed)
#   .\Play-GTA6-RTX3070.ps1 -RayTracing  # Enable ray-traced indirect lighting (heavier on 8 GB VRAM)

param(
    [string]$Exe = 'E:\gta\game_scarlett_master.exe',
    [switch]$Safe,
    [switch]$Warm,
    [switch]$RayTracing,
    [switch]$ExperimentalPorts,
    [ValidateSet('series-s', 'series-x')][string]$Console = 'series-x',
    [ValidateSet('diag', 'release')][string]$Build = 'diag',
    [string]$Output = '1920x1080',
    [hashtable]$More = @{}
)

$ErrorActionPreference = 'Stop'

$victory = Join-Path $PSScriptRoot "target\$Build\victory.exe"
if (-not (Test-Path $victory)) {
    Write-Host "Binary not found at $victory. Building..."
    Push-Location $PSScriptRoot
    try {
        if ($Build -eq 'diag') {
            cargo build --locked --profile diag -p victory --features diagnostics
        } else {
            cargo build --locked --release -p victory
        }
    } finally { Pop-Location }
}
if (-not (Test-Path $Exe)) { Write-Error "Game executable not found: $Exe"; exit 1 }

New-Item -ItemType Directory -Force -Path 'C:\Repos-GTA6\victory-data\cache', 'C:\Repos-GTA6\victory-data\data' | Out-Null

$settings = @{
    # Hardware targeting: NVIDIA RTX 3070 (8 GB VRAM)
    VICTORY_D3D12_ADAPTER      = 'NVIDIA'

    # 8 GB VRAM & buffer management: move >=1MB buffers to GPU to cut 33ms CPU snapshots, keep windows small
    VICTORY_CARD_WINDOWS_MB      = '256'
    VICTORY_CARD_BUFFERS_MIN_MB  = '1'
    VICTORY_CARD_BUFFERS_MB      = '1024'
    VICTORY_TEXTURE_ROOM_PERCENT = '95'

    # Core VIctory-7900XTX async & relay pipeline (tested baseline from scripts/play.ps1)
    VICTORY_TEXTURE_NO_WAIT    = '1'
    VICTORY_RELAY              = '2'
    VICTORY_RELAY_COPY         = '1'
    VICTORY_WIDE_BACK          = '1'
    VICTORY_CARD_REHASH_RUNS   = '1'
    VICTORY_JOIN_COPIES        = '1'
    VICTORY_INDIRECT_WINDOW    = '1'
    VICTORY_CARD_STEPS         = '2'
    VICTORY_INDIRECT_BATCH     = '2'
    VICTORY_MAP_THREADS        = '1'
    VICTORY_TITLE_PRIORITIES   = '0'
    VICTORY_CARD_AWAKE         = '1'
    VICTORY_SHOW_AFTER         = '1'

    # Ambient lighting: DexNom material albedo floor + VIctory-7900XTX dynamic ambient + indoor air clamp
    VICTORY_AMBIENT_FALLBACK   = '1'
    VICTORY_AMBIENT            = '0.8'
    VICTORY_AMBIENT_AIR        = '0.1'
    VICTORY_AMBIENT_SETTLE     = '250,3'

    # Record used pipelines so 'victory warm --used' can precompile them
    VICTORY_PIPELINE_BOOK      = '1'
}

if ($Safe) {
    $settings.VICTORY_UNDER_WIDE = '0'
    $settings.VICTORY_LAND_ECHO  = '0'
} else {
    # Multi-threading & CPU ports tuned for Ryzen 5 5600XT (6 physical cores / 12 threads)
    $settings.VICTORY_ASYNC_SUBMIT     = '1'
    $settings.VICTORY_THIN             = '0'
    $settings.VICTORY_UNDER_THREADS    = '4'
    $settings.VICTORY_VIEW_THREADS     = '4'
    $settings.VICTORY_UPLOAD_AHEAD     = '1'
    $settings.VICTORY_PORT_GUARD       = '1'
    $settings.VICTORY_PORT_JOURNAL     = '1'
    $settings.VICTORY_SUBMIT_DEPTH     = '8'
    $settings.VICTORY_SUBMIT_FRAMES    = '0'
    $settings.VICTORY_LATE_WAIT_LISTS  = '16'
}

if ($ExperimentalPorts) {
    $settings.VICTORY_PORT_CONSTANTS   = '1'
    $settings.VICTORY_PORT_DESCRIPTORS = '1'
    $settings.VICTORY_PORT_CBV         = '1'
}

if ($RayTracing) {
    $settings.VICTORY_BVH_BUILDER = '1'
}

if ($Output) {
    $settings.VICTORY_OUTPUT = $Output
}

foreach ($k in $More.Keys) { $settings[$k] = $More[$k] }

$paths = 'VICTORY_CONFIG', 'VICTORY_GAME_DIR', 'VICTORY_CACHE_DIR', 'VICTORY_DATA_DIR'
Get-ChildItem Env:VICTORY_* | Where-Object { $_.Name -notin $paths } | ForEach-Object {
    Remove-Item "Env:$($_.Name)"
}
foreach ($k in $settings.Keys) { Set-Item "Env:$k" $settings[$k] }

$Exe = (Resolve-Path $Exe).Path
Push-Location $PSScriptRoot
try {
    if ($Warm) {
        Write-Host "Pre-warming shader & pipeline cache..."
        & $victory warm --used
    }
    Write-Host "Launching GTA VI on NVIDIA RTX 3070 ($Console, $Output)..."
    $logFile = 'C:\Repos-GTA6\victory-data\latest.log'
    $ErrorActionPreference = 'Continue'
    & $victory run --console $Console $Exe --execute 2>&1 | ForEach-Object { "$_" } | Tee-Object -FilePath $logFile
} finally {
    Pop-Location
}
