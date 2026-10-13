@{
    # ===== Aplicaciones que se cierran al optimizar =====
    # Pon el nombre del proceso SIN ".exe". Agrega o quita a tu gusto.
    AppsACerrar = @(
        'Spotify', 'SpotifyWebHelper',
        'Slack', 'Teams', 'ms-teams',
        'WhatsApp', 'Telegram', 'skype',
        'OneDrive', 'Dropbox', 'GoogleDriveFS',
        'Zoom',
        'EpicGamesLauncher', 'Battle.net', 'GalaxyClient'
    )

    # ===== Navegadores =====
    # $true = también cierra los navegadores (OJO: pierdes las pestañas abiertas).
    # Déjalo en $false y ciérralos tú, o usa Optimizar.cmd navegadores para una vez.
    CerrarNavegadores = $false
    Navegadores = @('chrome', 'msedge', 'firefox', 'opera', 'opera_gx', 'brave', 'vivaldi')

    # ===== Plan de energía =====
    # $true = cambia a "Alto rendimiento" mientras juegas (Restaurar lo devuelve).
    CambiarPlanEnergia = $true

    # Muestra los 8 programas que más memoria usan antes de cerrar nada.
    MostrarTopConsumo = $true

    # ===== Procesos que NUNCA se cierran, aunque aparezcan arriba =====
    # Procesos de Windows, Steam (para poder abrir juegos) y el antivirus.
    NoCerrarJamas = @(
        'explorer', 'dwm', 'csrss', 'winlogon', 'wininit', 'services', 'lsass',
        'svchost', 'system', 'smss', 'fontdrvhost', 'sihost', 'taskhostw',
        'steam', 'steamwebhelper',
        'Discord',   # lo usas para jugar: nunca se cierra
        'powershell', 'pwsh', 'windowsterminal', 'cmd', 'conhost',
        'MsMpEng', 'SecurityHealthService', 'NisSrv'
    )
}
