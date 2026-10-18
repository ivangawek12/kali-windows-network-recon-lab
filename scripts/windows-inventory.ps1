# Inventario de solo lectura para el laboratorio Kali + Windows/WSL2.
# Ejecutar en PowerShell. No cambia reglas ni perfiles del firewall.

Write-Host "`n=== Interfaces IP ===" -ForegroundColor Cyan
ipconfig

Write-Host "`n=== Perfiles activos del firewall ===" -ForegroundColor Cyan
Get-NetFirewallProfile -PolicyStore ActiveStore |
    Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction

Write-Host "`n=== Logging del firewall ===" -ForegroundColor Cyan
Get-NetFirewallProfile -PolicyStore ActiveStore |
    Select-Object Name, LogBlocked, LogAllowed, LogFileName

Write-Host "`n=== Sockets TCP en escucha ===" -ForegroundColor Cyan
Get-NetTCPConnection -State Listen |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, OwningProcess

Write-Host "`n=== Servicios asociados al proceso que escucha en TCP 135 ===" -ForegroundColor Cyan
$pid135 = Get-NetTCPConnection -State Listen -LocalPort 135 -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty OwningProcess

if ($null -ne $pid135) {
    Get-Process -Id $pid135 -ErrorAction SilentlyContinue
    Get-CimInstance Win32_Service |
        Where-Object ProcessId -eq $pid135 |
        Select-Object Name, DisplayName, State, StartMode
} else {
    Write-Host "No se encontró un socket TCP en escucha en el puerto 135."
}

Write-Host "`n=== Sockets en el rango dinámico observado ===" -ForegroundColor Cyan
$ports = 49664..49670
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $ports -contains $_.LocalPort } |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, OwningProcess,
        @{Name='ProcessName';Expression={
            (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        }}

Write-Host "`n=== Reglas entrantes RPC-EPMAP habilitadas ===" -ForegroundColor Cyan
Get-NetFirewallRule -PolicyStore ActiveStore -Enabled True -Direction Inbound |
    Where-Object DisplayName -Like '*RPC-EPMAP*' |
    Select-Object Name, DisplayName, Enabled, Direction, Action, Profile,
        PolicyStoreSourceType, PolicyStoreSource

Write-Host "`nInventario terminado. Este script solo consulta información." -ForegroundColor Green
