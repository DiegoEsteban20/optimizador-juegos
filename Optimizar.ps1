<#
.SYNOPSIS
  Optimizador para jugar: deja el PC liviano antes de abrir un juego y después devuelve todo a la normalidad.
.DESCRIPTION
  - Cierra de forma ordenada las aplicaciones que consumen recursos en segundo plano (según Config.psd1).
  - Opcionalmente cierra los navegadores (pierde las pestañas; por eso va aparte).
  - Cambia el plan de energía a Alto rendimiento.
  - Mide la memoria RAM que se liberó.
  - Guarda qué cerró y el plan anterior en datos\Estado.json, para poder restaurarlo.
  Nunca toca procesos críticos de Windows ni el antivirus (lista NoCerrarJamas).
  Úsalo solo en tu propio equipo.
.PARAMETER Restaurar
  Vuelve a abrir lo que se cerró y devuelve el plan de energía anterior.
.PARAMETER CerrarNavegadores
  Fuerza el cierre de navegadores en esta corrida (equivale a CerrarNavegadores = $true en el Config).
.EXAMPLE
  .\Optimizar.ps1
  .\Optimizar.ps1 -CerrarNavegadores
  .\Optimizar.ps1 -Restaurar
.NOTES
  Autor: Diego Molina (github.com/DiegoEsteban20). Windows PowerShell 5.1 y PowerShell 7.
#>
[CmdletBinding()]
param(
    [switch]$Restaurar,
    [switch]$CerrarNavegadores,
    [switch]$SinPausa
)

$ErrorActionPreference = 'Stop'
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$DirDatos = Join-Path $Base 'datos'
if (-not (Test-Path $DirDatos)) { New-Item -ItemType Directory -Path $DirDatos | Out-Null }
$ArchEstado = Join-Path $DirDatos 'Estado.json'
$ArchConfig = Join-Path $Base 'Config.psd1'
$ArchLog = Join-Path $Base 'Optimizador.log'

# GUID del plan "Alto rendimiento" de Windows
$PLAN_ALTO = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'

function Log([string]$m, [string]$color = 'Gray') {
    Add-Content -Path $ArchLog -Value ('{0:yyyy-MM-dd HH:mm:ss}  {1}' -f (Get-Date), $m) -Encoding UTF8
    Write-Host $m -ForegroundColor $color
}

function Leer-Config {
    $def = @{
        AppsACerrar       = @('Discord','Spotify','SpotifyWebHelper','Slack','Teams','ms-teams',
                              'WhatsApp','Telegram','OneDrive','Dropbox','GoogleDriveFS','Zoom',
                              'EpicGamesLauncher','Battle.net','GalaxyClient','skype')
        CerrarNavegadores = $false
        Navegadores       = @('chrome','msedge','firefox','opera','opera_gx','brave','vivaldi')
        CambiarPlanEnergia= $true
        MostrarTopConsumo = $true
        NoCerrarJamas     = @('explorer','dwm','csrss','winlogon','wininit','services','lsass',
                              'svchost','system','smss','fontdrvhost','sihost','taskhostw',
                              'steam','steamwebhelper','powershell','pwsh','windowsterminal','cmd',
                              'conhost','msmpeng','securityhealthservice','nissrv')
    }
    if (Test-Path $ArchConfig) {
        try {
            $c = Import-PowerShellDataFile -Path $ArchConfig
            foreach ($k in $c.Keys) { $def[$k] = $c[$k] }
        } catch { Log "No pude leer Config.psd1, uso valores por defecto: $($_.Exception.Message)" 'Yellow' }
    }
    return $def
}

function RAM-Libre-MB {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        return [math]::Round($os.FreePhysicalMemory / 1024)
    } catch { return $null }
}

function RAM-Total-MB {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        return [math]::Round($os.TotalVisibleMemorySize / 1024)
    } catch { return $null }
}

function Plan-Activo {
    try {
        $s = (powercfg /getactivescheme) 2>$null
        if ($s -match '([0-9a-fA-F-]{36})') { return $matches[1] }
    } catch { }
    return $null
}

# ------------------------------------------------------------------ RESTAURAR
if ($Restaurar) {
    if (-not (Test-Path $ArchEstado)) {
        Log 'No hay nada que restaurar (no existe datos\Estado.json).' 'Yellow'
        if (-not $SinPausa) { Read-Host 'Enter para salir' }
        return
    }
    $estado = Get-Content $ArchEstado -Raw | ConvertFrom-Json
    Log "Restaurando lo cerrado el $($estado.fecha)..." 'Cyan'

    $reabiertas = 0
    foreach ($app in $estado.cerradas) {
        # Si ya está abierto (por ejemplo arrancó solo tras un reinicio), no lo abre de nuevo
        if (@(Get-Process -Name $app.nombre -ErrorAction SilentlyContinue).Count -gt 0) {
            Write-Host "  $($app.nombre) ya estaba abierto" -ForegroundColor DarkGray
            continue
        }
        if ($app.ruta -and (Test-Path $app.ruta)) {
            try {
                Start-Process -FilePath $app.ruta -ErrorAction Stop
                Write-Host "  Reabrí $($app.nombre)" -ForegroundColor Green
                $reabiertas++
                Start-Sleep -Milliseconds 300
            } catch {
                Write-Host "  No pude reabrir $($app.nombre): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  $($app.nombre): sin ruta guardada, ábrelo tú" -ForegroundColor DarkGray
        }
    }

    if ($estado.planAnterior) {
        try {
            powercfg /setactive $estado.planAnterior 2>$null
            Log "Plan de energía devuelto al anterior." 'Green'
        } catch { Log "No pude cambiar el plan de energía." 'Yellow' }
    }

    Remove-Item $ArchEstado -ErrorAction SilentlyContinue
    Log "Listo. Reabrí $reabiertas aplicación(es)." 'Green'
    if (-not $SinPausa) { Read-Host 'Enter para salir' }
    return
}

# ------------------------------------------------------------------ OPTIMIZAR
$cfg = Leer-Config
$noCerrar = @($cfg.NoCerrarJamas | ForEach-Object { $_.ToLower() })

$objetivos = @($cfg.AppsACerrar)
if ($CerrarNavegadores -or $cfg.CerrarNavegadores) { $objetivos += $cfg.Navegadores }
$objetivos = $objetivos | Where-Object { $_ } | Select-Object -Unique

$ramAntes = RAM-Libre-MB
$total = RAM-Total-MB
if ($ramAntes -ne $null) {
    $pct = if ($total) { [math]::Round(($total - $ramAntes) / $total * 100) } else { '?' }
    Log "RAM libre antes: $ramAntes MB de $total MB (en uso: $pct%)" 'Cyan'
}

if ($cfg.MostrarTopConsumo) {
    Write-Host "`nLo que mas memoria usa ahora:" -ForegroundColor DarkCyan
    Get-Process | Where-Object { $_.WorkingSet64 -gt 0 } |
        Sort-Object WorkingSet64 -Descending | Select-Object -First 8 |
        ForEach-Object {
            '  {0,-28} {1,6} MB' -f $_.ProcessName, [math]::Round($_.WorkingSet64 / 1MB)
        }
}

Write-Host ''
$cerradas = @()
foreach ($nombre in $objetivos) {
    if ($noCerrar -contains $nombre.ToLower()) {
        Write-Host "  (protegido, no se cierra) $nombre" -ForegroundColor DarkGray
        continue
    }
    $procs = @(Get-Process -Name $nombre -ErrorAction SilentlyContinue)
    if ($procs.Count -eq 0) { continue }

    # recordar la ruta para poder reabrirlo
    $ruta = $null
    foreach ($p in $procs) { if (-not $ruta) { try { $ruta = $p.Path } catch { } } }

    # cerrar primero de forma ordenada
    foreach ($p in $procs) { try { $p.CloseMainWindow() | Out-Null } catch { } }
    Start-Sleep -Milliseconds 700

    $vivos = @(Get-Process -Name $nombre -ErrorAction SilentlyContinue)
    foreach ($p in $vivos) {
        try { Stop-Process -Id $p.Id -Force -ErrorAction Stop } catch { }
    }

    $quedan = @(Get-Process -Name $nombre -ErrorAction SilentlyContinue)
    if ($quedan.Count -eq 0) {
        Write-Host "  Cerre $nombre" -ForegroundColor Green
        $cerradas += [pscustomobject]@{ nombre = $nombre; ruta = $ruta }
    } else {
        Write-Host "  No pude cerrar $nombre del todo" -ForegroundColor Yellow
    }
}

# plan de energia
$planAnterior = $null
if ($cfg.CambiarPlanEnergia) {
    $planAnterior = Plan-Activo
    try {
        powercfg /setactive $PLAN_ALTO 2>$null
        if ((Plan-Activo) -eq $PLAN_ALTO) {
            Log "Plan de energia: Alto rendimiento" 'Green'
        } else {
            Log "No encontre el plan Alto rendimiento (tu PC quizas no lo tiene); se deja el actual." 'Yellow'
            $planAnterior = $null
        }
    } catch {
        Log "No pude cambiar el plan de energia." 'Yellow'
        $planAnterior = $null
    }
}

# guardar estado para restaurar
$estado = [pscustomobject]@{
    fecha        = (Get-Date).ToString('dd-MM-yyyy HH:mm')
    planAnterior = $planAnterior
    cerradas     = $cerradas
}
$estado | ConvertTo-Json -Depth 5 | Set-Content -Path $ArchEstado -Encoding UTF8

Start-Sleep -Seconds 1
$ramDespues = RAM-Libre-MB
Write-Host ''
if ($ramAntes -ne $null -and $ramDespues -ne $null) {
    $libre = $ramDespues - $ramAntes
    $signo = if ($libre -ge 0) { "+$libre" } else { "$libre" }
    Log ("RAM libre despues: $ramDespues MB  (liberada: $signo MB)") 'Cyan'
}
Log ("Listo: cerre {0} aplicacion(es). Ya puedes abrir tu juego." -f $cerradas.Count) 'Green'
Write-Host "Cuando termines de jugar, usa Restaurar.cmd para devolver todo a la normalidad." -ForegroundColor DarkCyan

if (-not $SinPausa) { Read-Host 'Enter para salir' }
