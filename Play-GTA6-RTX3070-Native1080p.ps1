# Launches GTA VI at native 1080p (1920x1080, VICTORY_RENDER_SCALE=1.0, no internal downscale)
# Delegates to Play-GTA6-RTX3070.ps1 without modifying it.

param(
    [switch]$Safe,
    [switch]$Warm,
    [switch]$RayTracing,
    [switch]$ExperimentalPorts
)

$script = Join-Path $PSScriptRoot 'Play-GTA6-RTX3070.ps1'
& $script -Output '1920x1080' -More @{ VICTORY_RENDER_SCALE = '1.0' } -Safe:$Safe -Warm:$Warm -RayTracing:$RayTracing -ExperimentalPorts:$ExperimentalPorts
