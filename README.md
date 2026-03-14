# WINULT - Windows Ultimate Tool

```
============================================================
  __      __      __  ___   _   _   _   _   _       _______ 
  \ \    /  \    / / |_ _| | \ | | | | | | | |     |__   __|
   \ \  / /\ \  / /   | |  |  \| | | | | | | |        | |   
    \ \/ /  \ \/ /    | |  | . ` | | | | | | |        | |   
     \  /    \  /     | |  | |\  | | |_| | | |____    | |   
      \/      \/     |___| |_| \_|  \___/  |______|   |_|   

 WINULT | Windows Ultimate Tool
 PC Health Check, Repair, and Malware-Safety Diagnostics
============================================================
```

> Interactive Windows diagnostic & repair toolkit.  
> SFC · DISM · CHKDSK · Defender · Drivers · SMART · Malware persistence. Fully logged, admin-safe.

**Current version:** v2.7.0  
**Platform:** Windows 10 / 11 (PowerShell 5.1+)  
**Requires:** Administrator rights
**Terms:** [TERMS.md](TERMS.md)

## Download Latest

- Latest source ZIP (main branch): [Download ZIP](https://github.com/yassine-el-B/PC_HealthCheck_And_Repair/archive/refs/heads/main.zip)
- Repository: [PC_HealthCheck_And_Repair](https://github.com/yassine-el-B/PC_HealthCheck_And_Repair)

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

## How to Use

First, download this repository and extract it to a local folder such as your Desktop. Do not run it from a network share, because WINULT blocks that on purpose.

Then open `WINULT.bat` as **Administrator**. The script checks for admin rights and PowerShell before anything starts.

When the main menu appears, choose the profile you want:

- Use **1** for a fast health check
- Use **2** if you want all sections enabled
- Use **3** if you mainly want repair actions like SFC and DISM
- Use **4** if you want to focus on malware checks and Defender scanning
- Use **5** for a lighter run on low-end systems
- Use **M** if you want to manually choose each section yourself

After you pick a profile, WINULT shows a confirmation screen with every enabled and skipped section. Review it, then press **S** to start or **Q** to go back.

During the run, some checks may ask for an extra choice. For example, CHKDSK lets you choose between an online scan, an offline repair on reboot, or skipping it. Network diagnostics can also offer an optional reset.

When the script finishes, open the `Logs` folder next to `WINULT.bat`. You will find the full diagnostic log and the error log there.

If you are not sure what a section does, use the profile presets first instead of Manual mode. The presets are the safest way to start using the tool.

---

## Menu Guide

When WINULT starts, it shows a profile menu. Each key selects a predefined repair workflow:

- **1 - Quick Check**: fast diagnostic pass for general health checks
- **2 - Full Maintenance**: runs all sections, including the full Defender scan
- **3 - Critical Repair**: focuses on repair tasks like SFC, DISM, drivers, and malware checks
- **4 - Virus/Malware**: focuses on persistence checks and antivirus scanning
- **5 - Low-End Friendly**: lighter run for slower machines
- **M - Manual**: lets you turn each section on or off yourself
- **Q - Quit**: exits without making changes

If you choose **Manual**, the next screen shows every section with an `ON` or `OFF` status. Press the matching key to toggle a section:

- `1-9` toggle the numbered checks
- `T` toggles temperature checks
- `B-E` toggle the advanced sections
- `A` turns all sections on
- `N` turns all sections off
- `S` moves to the confirmation screen
- `0` returns to the profile menu

Before anything runs, WINULT shows a confirmation screen listing every enabled and skipped section. Press **S** to begin or **Q** to go back.

Some sections then ask for an extra decision during runtime:

- **CHKDSK** asks whether to run an online scan, schedule an offline repair, or skip
- **Network** can optionally reset DNS, Winsock, and IP settings
- **Virus Scan** uses the selected profile's scan mode, such as quick or full

This keeps the tool technician-friendly: you can use a preset when you need speed, or fine-tune every step when you want full control.

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

## Support & Feedback

- Found a bug? Open an issue on GitHub
- Have a feature request? Let me know
- Need help? Check the Menu Guide section above

---

## GitHub Topics

`batch-script`, `windows-diagnostics`, `pc-repair`, `system-maintenance`, `sfc-dism-chkdsk`, `malware-detection`, `driver-diagnostics`, `disk-health`, `windows-admin-tools`, `windows-utilities`

---

## License

This project is licensed under the MIT License, with additional ethical usage terms.
See [LICENSE](LICENSE), [TERMS.md](TERMS.md) for more details.


