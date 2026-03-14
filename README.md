# WINULT - Windows Ultimate Tool

> Interactive Windows diagnostic & repair toolkit.  
> SFC · DISM · CHKDSK · Defender · Drivers · SMART · Malware persistence. Fully logged, admin-safe.

**Current version:** v2.7.0  
**Platform:** Windows 10 / 11 (PowerShell 5.1+)  
**Requires:** Administrator rights

---

## Why use WINULT?

- **Fixes slow PCs** - clears Windows Update cache, repairs corrupted system files with SFC + DISM
- **Repairs corruption** - runs CHKDSK, SFC, and DISM in one go with actionable results
- **Detects malware persistence** - audits non-Microsoft scheduled tasks and suspicious running services
- **Generates full diagnostic logs** - every section timestamped and saved; stderr captured separately
- **Safe for technicians** - prompts before every destructive action; auto restore point before repairs begin
- **Portable** - single `.bat` file, runs from USB, no installation required

---

## Who is this for?

- **IT technicians** who want a fast, reproducible diagnostic workflow
- **PC repair shops** needing a one-click audit trail to show customers
- **Power users** who maintain their own machines
- **MSPs** looking for a lightweight, scriptable first-response toolkit

---

## What it does

WINULT runs a structured sequence of health checks and repairs on a Windows PC and writes a full diagnostic log. Everything is interactive - nothing destructive happens without a prompt first, and a system restore point is created automatically before any repairs begin.

---

## Sections

| # | Section | What it checks / does |
|---|---------|----------------------|
| PRE | Pre-run | Pending reboot detection · Auto restore point |
| 1 | System Info | OS, CPU, RAM, build number, last boot, activation status |
| 2 | Disk Health | Drive space per volume · Physical disk health via `Get-PhysicalDisk` |
| T | Temperature | CPU / thermal zone temperatures via ACPI WMI |
| 3 | CHKDSK | Online scan or scheduled offline repair (user choice, drive-type aware) |
| 4 | SFC | System File Checker with CBS.log parsing (`PASS / REPAIRED / FAIL`) |
| 5 | DISM | `CheckHealth` + `RestoreHealth` Windows image repair |
| 6 | Network | IP addresses · Internet ping test · Optional stack reset (DNS/Winsock/IP) |
| 7 | Windows Update | Clear `SoftwareDistribution` cache · Restart WU/BITS services |
| 8 | Virus Scan | Windows Defender signature update + Quick or Full scan |
| 9 | Drivers | PnP device error code audit via WMI |
| B | Malware | Non-Microsoft scheduled tasks · Suspicious running services |
| C | System Restore | VSS shadow copy listing |
| D | SSD Wear | SMART-equivalent: wear %, temperature, read/write errors |
| E | BSOD Logs | Last 20 critical/error events from the System event log |
| 14 | Summary | Pass/Warn/Fail status for every section · Log file path |

---

## Profiles

Choose at the menu or use one-key shortcuts:

| Key | Profile | Sections included | Est. time |
|-----|---------|-------------------|-----------|
| 1 | Quick Check | SysInfo + Disk + Drivers + Quick Scan | ~20-30 min |
| 2 | Full Maintenance | All sections + Full virus scan | ~1.5-3 hrs |
| 3 | Critical Repair | SFC + DISM + Drivers + Malware + AV | ~1-2 hrs |
| 4 | Virus/Malware | Malware persistence + Full virus scan | ~1-2 hrs |
| 5 | Low-End Friendly | SysInfo + Disk + Drivers only | ~10-20 min |
| M | Manual | Toggle individual sections ON/OFF | varies |

---

## Requirements

- **Windows 10 or 11** (works on Server 2016+ with Storage module)
- **PowerShell 5.1 or later** - detected automatically at startup
- **Administrator rights** - script will refuse to run without elevation
- Must be run from a **local drive or USB** - UNC/network paths are blocked

---

## Usage

1. Copy `WINULT.bat` to a local drive or USB stick
2. Right-click → **Run as administrator**
3. Select a profile or use Manual mode to toggle sections
4. Review the confirmation screen, press **S** to start
5. Find logs in the `Logs\` folder next to the script

```
Logs\
└── COMPUTERNAME_20260314_153000\
    ├── TechLog_COMPUTERNAME_20260314_153000.txt   ← full diagnostic log
    └── Errors_COMPUTERNAME_20260314_153000.txt    ← stderr from repair tools
```

---

## Output files

| File | Contents |
|------|----------|
| `TechLog_*.txt` | Full console output - everything shown on screen, timestamped per section |
| `Errors_*.txt` | Stderr from SFC, DISM, CHKDSK, and Defender - useful for deep troubleshooting |

---

## Privacy

No personal files, documents, or passwords are read or saved. The log contains only system configuration data, event log entries, and tool output.

---

## Changelog

### v2.7.0
- Added PowerShell 5.1+ version guard - aborts with a clear message on older PS
- SFC result now parsed from `CBS.log`: distinguishes `PASS / REPAIRED / FAIL / WARN-REBOOT`
- `Get-PhysicalDisk` wrapped in try/catch for compatibility with older Windows builds
- `_MP_FOUND` Defender path sentinel initialised before loop; commented for clarity
- Restore point failure message now hints at System Protection / Group Policy as likely causes

### v2.6.0
- Fixed UNC network share guard (original empty-string test never fired on `\\server\share` paths)
- Replaced deprecated `wmic` with `Checkpoint-Computer` for restore point creation
- Dynamic Defender platform path discovery - no longer hardcodes the version folder name
- SFC exit code corrected from `errorlevel 2` to `errorlevel 1`
- Fixed extraneous `}` in thermal zone PowerShell command
- `SUM_NETWORK` now reflects actual internet connectivity (was always `PASS`)
- `SoftwareDistribution.bak` collision fix - removes old `.bak` before rename
- Stderr redirected to `ERRFILE` for SFC, DISM, CHKDSK, and Defender

### v2.5.0
- Initial public release

---

## Limitations

- **Windows only** - not compatible with Linux or macOS
- **No GUI** - runs entirely in the command prompt; no graphical interface
- **CHKDSK only scans C:** - other volumes must be checked manually
- **Defender scans only** - does not integrate with third-party antivirus tools
- **Temperature readings depend on ACPI support** - some systems (especially VMs) report no sensors
- **SSD wear data requires driver support** - NVMe/SATA controllers must expose SMART data to Windows
- **Restore points require System Protection to be enabled** - may be off by default on some builds or blocked by Group Policy
- **Malware persistence scan is heuristic** - flags suspicious entries for human review; not a replacement for a dedicated AV tool

---

## License

MIT License

Copyright (c) 2026 Yassine El-B

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
