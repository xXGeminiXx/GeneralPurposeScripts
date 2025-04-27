<#
.SYNOPSIS
Super Windows Network Optimizer
Target: 1Gbps Fiber Internet + Developer Workstations
Author: [Your Name or GitHub Handle]
Version: 1.0.0
Description: Optimizes Windows TCP/IP Stack, NIC settings, disables unnecessary services, improves latency and throughput.
#>

param(
    [switch]$EnablePacing,
    [switch]$RebootAfter,
    [switch]$Rollback
)

Write-Host "🚀 Starting Windows Network Optimization..." -ForegroundColor Cyan

# Functions
function Test-NetworkPerformance {
    Write-Host "📊 Running basic network performance test..." -ForegroundColor Cyan
    $ping = Test-Connection -ComputerName "8.8.8.8" -Count 4 -ErrorAction SilentlyContinue
    $avgLatency = ($ping | Measure-Object -Property ResponseTime -Average).Average
    Write-Host "🏓 Average latency to 8.8.8.8: $avgLatency ms" -ForegroundColor Green
}

function Undo-Optimizations {
    Write-Host "🔄 Rolling back optimizations..." -ForegroundColor Yellow
    Enable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    netsh interface tcp set global autotuninglevel=normal
    netsh interface tcp set heuristics enabled
    netsh interface tcp set global rss=enabled
    netsh interface tcp set global rsc=disabled
    netsh interface tcp set global ecncapability=enabled
    netsh interface tcp set global fastopen=disabled
    netsh interface tcp set global pacingprofile=off
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Tcp1323Opts" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "InitialRto" -ErrorAction SilentlyContinue

    $servicesToEnable = @(
        "Spooler",
        "DiagTrack",
        "dmwappushservice",
        "WMPNetworkSvc",
        "XblGameSave"
    )
    foreach ($service in $servicesToEnable) {
        Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
    }

    Write-Host "✅ Rollback complete. Please reboot manually." -ForegroundColor Green
    exit
}

# Main Flow

# 1. Detect Active Ethernet Adapter
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -match "Ethernet" } | Select-Object -First 1
if (-not $adapter) {
    Write-Host "❌ No active Ethernet adapter found!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Active adapter detected: $($adapter.Name)" -ForegroundColor Green

# If rollback flag is used, rollback and exit
if ($Rollback) {
    Undo-Optimizations
}

# 2. Pre-Optimization Performance Test
Test-NetworkPerformance

# 3. Backup Registry Keys
Write-Host "📂 Backing up registry keys..." -ForegroundColor Cyan
try {
    reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" ".\Tcpip-Parameters-Backup.reg" /y
    reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" ".\Tcpip-Interfaces-Backup.reg" /y
    Write-Host "✅ Registry backups saved" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Failed to backup registry keys" -ForegroundColor Yellow
}

# 4. Disable IPv6
$ipv6Binding = Get-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6
if ($ipv6Binding.Enabled) {
    Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    Write-Host "✅ IPv6 disabled" -ForegroundColor Green
}

# 5. Set MTU to 1500
netsh interface ipv4 set subinterface "$($adapter.Name)" mtu=1500 store=persistent
Write-Host "✅ MTU set to 1500" -ForegroundColor Green

# 6. TCP/IP Stack Optimizations
netsh interface tcp set global autotuninglevel=normal
netsh interface tcp set heuristics disabled
netsh interface tcp set global rss=enabled
netsh interface tcp set global rsc=enabled
netsh interface tcp set global ecncapability=disabled
netsh interface tcp set global fastopen=enabled
netsh interface tcp set global fastopenfallback=enabled

# Lower TCP Initial RTO
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "InitialRto" -PropertyType DWord -Value 200 -Force

# Optional TCP Pacing
if ($EnablePacing) {
    netsh interface tcp set global pacingprofile=initialwindow
    Write-Host "✅ TCP Pacing enabled (initial window)" -ForegroundColor Green
} else {
    netsh interface tcp set global pacingprofile=off
}

Write-Host "✅ TCP/IP stack optimizations applied" -ForegroundColor Green

# 7. Disable Nagle's Algorithm and Delayed ACK
$adapterGUIDs = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | Select-Object -ExpandProperty PSChildName
foreach ($guid in $adapterGUIDs) {
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name "TcpAckFrequency" -PropertyType DWord -Value 1 -Force
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name "TCPNoDelay" -PropertyType DWord -Value 1 -Force
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name "TcpDelAckTicks" -PropertyType DWord -Value 0 -Force
}
Write-Host "✅ Nagle's Algorithm and Delayed ACK disabled" -ForegroundColor Green

# 8. NIC Driver-Level Tuning
try {
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -NoRestart -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Flow Control" -DisplayValue "Rx & Tx Enabled" -NoRestart -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Receive Buffers" -DisplayValue "512" -NoRestart -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Transmit Buffers" -DisplayValue "512" -NoRestart -ErrorAction SilentlyContinue
    Write-Host "✅ NIC driver tuning applied" -ForegroundColor Green
} catch {
    Write-Host "⚠️ NIC driver tuning skipped (unsupported adapter)" -ForegroundColor Yellow
}

# 9. Disable Unnecessary Windows Services
$servicesToDisable = @("Spooler", "DiagTrack", "dmwappushservice", "WMPNetworkSvc", "XblGameSave")
foreach ($service in $servicesToDisable) {
    try {
        Stop-Service -Name $service -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}
}
Write-Host "✅ Unnecessary Windows services disabled" -ForegroundColor Green

# 10. Set High Performance Power Plan
powercfg -setactive SCHEME_MIN
Write-Host "✅ Power Plan set to High Performance" -ForegroundColor Green

# 11. Post-Optimization Test
Test-NetworkPerformance

# 12. Final Message
Write-Host "🎯 Network optimization completed!" -ForegroundColor Green
if ($RebootAfter) {
    Write-Host "🔁 Rebooting..." -ForegroundColor Yellow
    Restart-Computer -Force
} else {
    Write-Host "⚡ Please reboot manually for full effect." -ForegroundColor Yellow
}

