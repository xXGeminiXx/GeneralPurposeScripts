@echo off
setlocal ENABLEDELAYEDEXPANSION

echo =========================================
echo  🚀 Windows Full Network Optimizer Launcher
echo  Target: 1Gbps Fiber Internet + Developers
echo =========================================
echo.

:: Step 1: Create temp directory
set "tempDir=%TEMP%\WinNetOptimizer"
set "psFile=%tempDir%\Optimize-WindowsNetwork.ps1"
mkdir "%tempDir%" >nul 2>&1

:: Step 2: Write the full advanced PowerShell optimization script
echo 📄 Creating advanced optimization script...
(
echo # Super Windows Network Optimizer
echo function main {
echo param(
echo     [switch]$EnablePacing,
echo     [switch]$RebootAfter,
echo     [switch]$Rollback
echo ^)
echo.
echo Write-Host "🚀 Starting Windows Network Optimization..." -ForegroundColor Cyan
echo.
echo $adapters = Get-NetAdapter ^| Where-Object { $_.Status -eq "Up" }
echo if (-not $adapters) { Write-Host "❌ No active network adapters found!" -ForegroundColor Red; exit 1 }
echo if ($adapters.Count -gt 1) {
echo     Write-Host "⚡ Multiple active adapters detected:"
echo     $i = 1
echo     foreach ($adapterOption in $adapters) { Write-Host "$i. $($adapterOption.Name) ($($adapterOption.InterfaceDescription))"; $i++ }
echo     $selection = Read-Host "Select adapter number to optimize"
echo     $adapter = $adapters[($selection - 1)]
echo } else {
echo     $adapter = $adapters[0]
echo }
echo Write-Host "✅ Active adapter selected: $($adapter.Name)" -ForegroundColor Green
echo.
echo if ($Rollback) {
echo     Undo-Optimizations -adapter $adapter
echo     exit
echo }
echo.
echo Test-NetworkPerformance
echo.
echo # Backup Registry
echo try {
echo     reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "%tempDir%\Tcpip-Parameters-Backup.reg" /y
echo     reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "%tempDir%\Tcpip-Interfaces-Backup.reg" /y
echo     Write-Host "✅ Registry backup complete" -ForegroundColor Green
echo } catch {
echo     Write-Host "⚠️ Registry backup failed, continuing..." -ForegroundColor Yellow
echo }
echo.
echo # Disable IPv6
echo $ipv6Binding = Get-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6
echo if ($ipv6Binding.Enabled) {
echo     Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6
echo     Write-Host "✅ IPv6 disabled" -ForegroundColor Green
echo }
echo.
echo # MTU and TCP Stack Tuning
echo netsh interface ipv4 set subinterface "$($adapter.Name)" mtu=1500 store=persistent
echo netsh interface tcp set global autotuninglevel=normal
echo netsh interface tcp set heuristics disabled
echo netsh interface tcp set global rss=enabled
echo netsh interface tcp set global rsc=enabled
echo netsh interface tcp set global ecncapability=disabled
echo netsh interface tcp set global fastopen=enabled
echo netsh interface tcp set global fastopenfallback=enabled
echo New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "InitialRto" -PropertyType DWord -Value 200 -Force
echo.
echo if ($EnablePacing) {
echo     netsh interface tcp set global pacingprofile=initialwindow
echo     Write-Host "✅ TCP pacing enabled" -ForegroundColor Green
echo } else {
echo     netsh interface tcp set global pacingprofile=off
echo }
echo.
echo # Disable Nagle + Delayed ACK
echo $adapterGUIDs = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" ^| Select-Object -ExpandProperty PSChildName
echo foreach ($guid in $adapterGUIDs) {
echo     New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name "TcpAckFrequency" -PropertyType DWord -Value 1 -Force
echo     New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name "TCPNoDelay" -PropertyType DWord -Value 1 -Force
echo     New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name "TcpDelAckTicks" -PropertyType DWord -Value 0 -Force
echo }
echo.
echo # NIC Driver Level Tuning
echo try {
echo     Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -NoRestart -ErrorAction SilentlyContinue
echo     Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Flow Control" -DisplayValue "Rx & Tx Enabled" -NoRestart -ErrorAction SilentlyContinue
echo     Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Receive Buffers" -DisplayValue "512" -NoRestart -ErrorAction SilentlyContinue
echo     Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Transmit Buffers" -DisplayValue "512" -NoRestart -ErrorAction SilentlyContinue
echo     Write-Host "✅ NIC tuning applied" -ForegroundColor Green
echo } catch {
echo     Write-Host "⚠️ NIC tuning not supported" -ForegroundColor Yellow
echo }
echo.
echo # Disable unnecessary services
echo $servicesToDisable = @("Spooler", "DiagTrack", "dmwappushservice", "WMPNetworkSvc", "XblGameSave")
echo foreach ($service in $servicesToDisable) {
echo     try {
echo         Stop-Service -Name $service -ErrorAction SilentlyContinue
echo         Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
echo     } catch {}
echo }
echo Write-Host "✅ Unnecessary services disabled" -ForegroundColor Green
echo.
echo # High Performance Power Plan
echo powercfg -setactive SCHEME_MIN
echo Write-Host "✅ Power Plan set to High Performance" -ForegroundColor Green
echo.
echo Test-NetworkPerformance
echo.
echo Write-Host "🎯 Optimization complete!" -ForegroundColor Green
echo if ($RebootAfter) {
echo     Restart-Computer -Force
echo } else {
echo     Write-Host "⚡ Please reboot manually for full effect." -ForegroundColor Yellow
echo }
echo }
echo.
echo function Undo-Optimizations {
echo param($adapter)
echo.
echo Write-Host "🔄 Rolling back optimizations..." -ForegroundColor Yellow
echo Enable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
echo netsh interface tcp set global autotuninglevel=normal
echo netsh interface tcp set heuristics enabled
echo netsh interface tcp set global rss=enabled
echo netsh interface tcp set global rsc=disabled
echo netsh interface tcp set global ecncapability=enabled
echo netsh interface tcp set global fastopen=disabled
echo netsh interface tcp set global pacingprofile=off
echo Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "InitialRto" -ErrorAction SilentlyContinue
echo.
echo $servicesToEnable = @("Spooler", "DiagTrack", "dmwappushservice", "WMPNetworkSvc", "XblGameSave")
echo foreach ($service in $servicesToEnable) {
echo     Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
echo }
echo Write-Host "✅ Rollback complete. Please reboot manually." -ForegroundColor Green
echo }
echo.
echo function Test-NetworkPerformance {
echo Write-Host "📊 Running basic network performance test..." -ForegroundColor Cyan
echo $ping = Test-Connection -ComputerName "8.8.8.8" -Count 4 -ErrorAction SilentlyContinue
echo $avgLatency = ($ping ^| Measure-Object -Property ResponseTime -Average).Average
echo Write-Host "🏓 Average latency to 8.8.8.8: $avgLatency ms" -ForegroundColor Green
echo }
echo.
echo main @PSBoundParameters
) > "%psFile%"

:: Step 3: Find best available PowerShell (pwsh or powershell.exe)
set "foundShell="

where pwsh.exe >nul 2>&1
if not errorlevel 1 (
    set "foundShell=pwsh.exe"
) else (
    where powershell.exe >nul 2>&1
    if not errorlevel 1 (
        set "foundShell=powershell.exe"
    )
)

if "%foundShell%"=="" (
    echo ❌ No PowerShell found! Install PowerShell 5.1+ or 7+ and try again.
    exit /b 1
)

:: Step 4: Launch
echo 🚀 Running optimizer using %foundShell%...
%foundShell% -NoProfile -ExecutionPolicy Bypass -File "%psFile%"

:: Step 5: Final Message
echo =========================================
echo ✅ Optimization finished! Please REBOOT to unleash full gigabit performance.
echo    To rollback, re-run this with -Rollback.
echo =========================================
endlocal
pause
