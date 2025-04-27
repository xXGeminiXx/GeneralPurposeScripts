# Windows Network Optimizer

🚀 A complete TCP/IP, NIC, and system-level optimization script for Windows 10/11, targeting Gigabit Fiber connections and high-performance developer/gamer workstations.

### Features
- Sets optimal MTU for 1Gbps connections
- Tunes TCP/IP Stack (AutoTuning, Fast Open, ECN, etc.)
- Disables Nagle's Algorithm and Delayed ACKs
- Tweaks NIC driver properties (Interrupt Moderation, Buffers, Flow Control)
- Disables unnecessary Windows background services
- Sets High Performance power plan
- Full registry backup before changes
- Auto rollback option included

### Usage

```bash
# Basic optimization
.\Optimize-WindowsNetwork.ps1

# Enable TCP pacing (optional, for heavy-load environments)
.\Optimize-WindowsNetwork.ps1 -EnablePacing

# Optimize and automatically reboot
.\Optimize-WindowsNetwork.ps1 -EnablePacing -RebootAfter

# Rollback all changes
.\Optimize-WindowsNetwork.ps1 -Rollback
```

Compatibility
Windows 10 (1809+) and Windows 11

PowerShell 5.1+ or 7.x
