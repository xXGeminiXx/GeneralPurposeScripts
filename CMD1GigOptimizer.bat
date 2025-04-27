@echo off
setlocal ENABLEDELAYEDEXPANSION

echo =========================================
echo  🚀  Windows Full Network Optimizer Launcher
echo  Target: 1 Gbps / Fiber connections  
echo =========================================
echo.

:: ------------------------------------------------------------------
:: 1 – detect PowerShell host (pwsh ► powershell) – abort only if none
:: ------------------------------------------------------------------
set "foundShell="
where pwsh.exe    >nul 2>&1 && set "foundShell=pwsh.exe"
if not defined foundShell (
    where powershell.exe >nul 2>&1 && set "foundShell=powershell.exe"
)
if not defined foundShell (
    echo ❌  PowerShell 5.1+ or 7+ is required. Install it and rerun.
    goto :END
)

:: ------------------------------------------------------------------
:: 2 – create temp folder & write full advanced PS script in one shot
:: ------------------------------------------------------------------
set "tmpDir=%TEMP%\WinNetOptimizer"
set "psFile=%tmpDir%\Optimize-WindowsNetwork.ps1"
if not exist "%tmpDir%" md "%tmpDir%"

echo 📄  Writing optimizer script to %psFile% …
%foundShell% -NoProfile -Command ^
"$code=@'
<#
  Super Windows Network Optimizer  (v1.0.1, full)
  – registry backup / rollback
  – MTU 1500  – TCP stack tuning
  – IPv6 disable  – Nagle / Delayed-ACK off
  – optional pacing  – NIC driver tweaks
  – service trim  – High-Performance power
#>
param([switch]$EnablePacing,[switch]$RebootAfter,[switch]$Rollback)

function Test-Ping {
  try {
    \$r=(Test-Connection 8.8.8.8 -Count 4 -ErrorAction Stop|
        Measure-Object -Property ResponseTime -Average).Average
    Write-Host \"🏓 Avg latency 8.8.8.8 = \$r ms\" -fo Green
  }catch{Write-Host '↯ Ping failed' -fo Yellow}
}

function Undo {
 param(\$a)
 Enable-NetAdapterBinding -Name \$a.Name -ComponentID ms_tcpip6 -ea SilentlyContinue
 netsh int tcp set global autotuninglevel=normal
 netsh int tcp set heuristics enabled
 netsh int tcp set global rss=enabled rsc=disabled ecncapability=enabled fastopen=disabled pacingprofile=off
 Remove-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters' -Name InitialRto -ea SilentlyContinue
 'Spooler','DiagTrack','dmwappushservice','WMPNetworkSvc','XblGameSave'|%{Set-Service $_ -StartupType Manual -ea SilentlyContinue}
 Write-Host '✅ Rollback done – reboot.' -fo Green
 exit
}

Write-Host '🚀 Optimizer starting…' -fo Cyan
\$ad=(Get-NetAdapter|? Status -eq 'Up')
if(!\$ad){Write-Host '❌ No active adapters.' -fo Red;exit}
if(\$ad.Count -gt 1){
 \$i=1;\$ad|%{Write-Host \"\$i. \$_.Name (\$_.InterfaceDescription)\"; \$i++}
 \$sel=[int](Read-Host 'Select adapter number')-1
 \$ad=\$ad[\$sel]
}
Write-Host \"✅ Using adapter: \$($ad.Name)\" -fo Green

if(\$Rollback){Undo \$ad}

Test-Ping
reg export 'HKLM\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters' \"\$env:TEMP\\Tcpip-Parameters-BACKUP.reg\" /y >\$null
reg export 'HKLM\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces' \"\$env:TEMP\\Tcpip-Interfaces-BACKUP.reg\" /y >\$null
Write-Host '💾 Registry backup saved (%TEMP%)' -fo Green

if((Get-NetAdapterBinding -Name \$ad.Name -ComponentID ms_tcpip6).Enabled){
 Disable-NetAdapterBinding -Name \$ad.Name -ComponentID ms_tcpip6
 Write-Host '↯ IPv6 disabled' -fo Yellow
}
netsh int ipv4 set subinterface \"\$([regex]::Escape(\$ad.Name))\" mtu=1500 store=persistent >\$null
netsh int tcp set global autotuninglevel=normal heuristics=disabled rss=enabled rsc=enabled ecncapability=disabled fastopen=enabled fastopenfallback=enabled >\$null
New-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters' -Name InitialRto -Type DWord -Value 200 -Force >\$null
if(\$EnablePacing){netsh int tcp set global pacingprofile=initialwindow}

(Get-ChildItem 'HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces').PsChildName|%{
  \$k=\"HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces\\$_\"
  New-ItemProperty \$k -Name TcpAckFrequency -Type DWord -Value 1 -Force >\$null
  New-ItemProperty \$k -Name TCPNoDelay       -Type DWord -Value 1 -Force >\$null
  New-ItemProperty \$k -Name TcpDelAckTicks   -Type DWord -Value 0 -Force >\$null
}

try{
  Set-NetAdapterAdvancedProperty -Name \$ad.Name -DisplayName 'Interrupt Moderation' -DisplayValue 'Disabled' -NoRestart -ea Stop
  Set-NetAdapterAdvancedProperty -Name \$ad.Name -DisplayName 'Flow Control' -DisplayValue 'Rx & Tx Enabled' -NoRestart -ea Stop
  Set-NetAdapterAdvancedProperty -Name \$ad.Name -DisplayName 'Receive Buffers' -DisplayValue '512' -NoRestart -ea Stop
  Set-NetAdapterAdvancedProperty -Name \$ad.Name -DisplayName 'Transmit Buffers' -DisplayValue '512' -NoRestart -ea Stop
  Write-Host '🔧 NIC advanced tuning applied' -fo Green
}catch{Write-Host '⚠️ NIC tuning skipped' -fo Yellow}

'SPOOLER','DiagTrack','dmwappushservice','WMPNetworkSvc','XblGameSave'|%{
  Stop-Service \$_-ea SilentlyContinue
  Set-Service \$_ -StartupType Disabled -ea SilentlyContinue
}
Write-Host '🧹 Background services disabled' -fo Green

powercfg -setactive SCHEME_MIN
Write-Host '⚡ High-Performance power plan enabled' -fo Green

Test-Ping
Write-Host '🎯 Optimization complete! Reboot to feel it.' -fo Green
if(\$RebootAfter){Restart-Computer -Force}
'@; Set-Content -Path '%psFile%' -Value $code -Encoding UTF8"

if errorlevel 1 (
    echo ❌  Failed to create PowerShell script.  Aborting.
    goto :END
)

:: ------------------------------------------------------------------
:: 3 – run the optimizer
:: ------------------------------------------------------------------
echo.&echo 🚀  Launching optimizer using %foundShell% …&echo.
%foundShell% -NoProfile -ExecutionPolicy Bypass -File "%psFile%"

echo.&echo =========================================
echo ✅  All done – *reboot* to unleash full gigabit speed.
echo    Need rollback?  run:
echo    %foundShell% -NoProfile -ExecutionPolicy Bypass -File "%psFile%" -Rollback
echo =========================================

:END
pause
endlocal
