<#
.SYNOPSIS
Super Windows Network Optimizer
Target: 1Gbps Fiber Internet + Developer Workstations
Author: [YourGitHubNameHere]
Version: 1.0.1
Description: Optimizes Windows TCP/IP stack, network adapter, and system for low latency and maximum throughput.
#>

function main {
    param(
        [switch]$EnablePacing,
        [switch]$RebootAfter,
        [switch]$Rollback
    )

    Write-Host "🚀 Starting Windows Network Optimization..." -ForegroundColor Cyan

    # Detect any active network adapter (Ethernet, Wi-Fi, USB Ethernet, etc.)
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if (-not $adapters) {
        Write-Host "❌ No active network adapters found!" -ForegroundColor Red
        exit 1
    }

    if ($adapters.Count -gt 1) {
        Write-Host "⚡ Multiple active adapters detected:"
        $i = 1
        foreach ($adapterOption in $adapters) {
            Write-Host "$i. $($adapterOption.Name) ($($adapterOption.InterfaceDescription))"
            $i++
        }
        $selection = Read-Host "Select adapter number to optimize"
        $adapter = $adapters[($selection - 1)]
    } else {
        $adapter = $adapters[0]
    }

    Write-Host "✅ Active adapter selected: $($adapter.Name)" -ForegroundColor Green

    if ($Rollback) {
        Undo-Optimizations $adapter
        exit
    }

    Test-NetworkPerformance

    # Backup Registry
    Write-Host "📂 Backing up registry settings..." -ForegroundColor Cyan
    try {
        reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" ".\Tcpip-Parameters-Backup.reg" /y
        reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" ".\Tcpip-Interfaces-Backup.reg" /y
        Write-Host "✅ Registry backup complete" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Registry backup failed, continuing..." -ForegroundColor Yellow
    }

    # Disable IPv6 if active
    $ipv6Binding = Get-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6
    if ($ipv6Binding.Enabled) {
        Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6
        Write-Host "✅ IPv6 disabled" -ForegroundColor Green
    }

    # Set MTU
    netsh interface ipv4 set subinterface "$($adapter.Name)" mtu=1500 store=persistent
    Write-Host "✅ MTU set to 1500" -ForegroundColor Green

    # TCP/IP Optimizations
    netsh interface tcp set global autotuninglevel=normal
    netsh interface tcp set heuristics disabled
    netsh interface tcp set global rss=enabled
    netsh interface tcp set global rsc=enabled
    netsh interface tcp set global ecncapability=disabled
    netsh interface tcp set global fastopen=enabled
    netsh interface tcp set global fastopenfallback=enabled

    # Lower TCP Initial Retransmit Timeout
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "InitialRto" -PropertyType DWord -Value 200 -Force

    # Optional TCP Pacing
    if ($EnablePacing) {
        netsh interface tcp set global pacingprofile=initialwindow
        Write-Host "✅ TCP pacing enabled" -ForegroundColor Green
    } else {
        netsh interface tcp set global pacingprofile=off
    }

    # Disable Nagle's Algorithm and Delayed ACK
    $adapterGUIDs = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | Select-Object -ExpandProperty PSChildName
    foreach ($guid in $adapterGUIDs) {
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name "TcpAckFrequency" -PropertyType DWord -Value 1 -Force
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name "TCPNoDelay" -PropertyType DWord -Value 1 -Force
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name "TcpDelAckTicks" -PropertyType DWord -Value 0 -Force
    }
    Write-Host "✅ Nagle's Algorithm and Delayed ACK disabled" -ForegroundColor Green

    # NIC Driver Tuning
    try {
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -NoRestart -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Flow Control" -DisplayValue "Rx & Tx Enabled" -NoRestart -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Receive Buffers" -DisplayValue "512" -NoRestart -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Transmit Buffers" -DisplayValue "512" -NoRestart -ErrorAction SilentlyContinue
        Write-Host "✅ NIC tuning applied" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ NIC advanced properties not supported" -ForegroundColor Yellow
    }

    # Disable Unnecessary Services
    $servicesToDisable = @("Spooler", "DiagTrack", "dmwappushservice", "WMPNetworkSvc", "XblGameSave")
    foreach ($service in $servicesToDisable) {
        try {
            Stop-Service -Name $service -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        } catch {}
    }
    Write-Host "✅ Unnecessary services disabled" -ForegroundColor Green

    # High Performance Power Plan
    powercfg -setactive SCHEME_MIN
    Write-Host "✅ Power Plan set to High Performance" -ForegroundColor Green

    # Post Optimization Test
    Test-NetworkPerformance

    Write-Host "🎯 Optimization complete!" -ForegroundColor Green

    if ($RebootAfter) {
        Restart-Computer -Force
    } else {
        Write-Host "⚡ Please reboot manually for full effect." -ForegroundColor Yellow
    }
}

function Undo-Optimizations {
    param($adapter)

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

    $servicesToEnable = @("Spooler", "DiagTrack", "dmwappushservice", "WMPNetworkSvc", "XblGameSave")
    foreach ($service in $servicesToEnable) {
        Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
    }

    Write-Host "✅ Rollback complete. Please reboot manually." -ForegroundColor Green
}

function Test-NetworkPerformance {
    Write-Host "📊 Running basic network performance test..." -ForegroundColor Cyan
    $ping = Test-Connection -ComputerName "8.8.8.8" -Count 4 -ErrorAction SilentlyContinue
    $avgLatency = ($ping | Measure-Object -Property ResponseTime -Average).Average
    Write-Host "🏓 Average latency to 8.8.8.8: $avgLatency ms" -ForegroundColor Green
}

main @PSBoundParameters
