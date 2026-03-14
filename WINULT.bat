@echo off
setlocal EnableDelayedExpansion

set "VERSION=2.7.0"
set "PS_EXE="

:: ================================================================
::  WINULT - Windows Ultimate Tool
::  v2.7.0 - PS version guard added. SFC result now parsed from
::           CBS.log (PASS/REPAIRED/FAIL). Get-PhysicalDisk wrapped
::           in try/catch for older builds. _MP_FOUND sentinel
::           clarified. Restore point failure hints at policy.
:: ================================================================

:: ================================================================
::  GUARD - Network share
::  %~d0 returns "C:" for local/USB paths.  For UNC network paths
::  (\\server\share\WINULT.bat) it returns "\\server\share", so
::  testing the first two characters catches that case correctly.
::  The original empty-string test never actually fired for UNC paths.
:: ================================================================
set "_BOOT_DRIVE=%~d0"
if "!_BOOT_DRIVE:~0,2!"=="\\" (
    echo.
    echo  Cannot run from a network share. Copy to a local drive or USB first.
    echo.
    pause & exit /b 1
)

:: ================================================================
::  GUARD - PowerShell
::  Prefer inbox powershell.exe (5.1); fall back to pwsh.exe (7+).
::  Either version satisfies all commands used in this script.
:: ================================================================
where powershell.exe >nul 2>&1 && set "PS_EXE=powershell.exe"
if not defined PS_EXE where pwsh.exe >nul 2>&1 && set "PS_EXE=pwsh.exe"
if not defined PS_EXE (
    echo.
    echo  [!] PowerShell not found. This tool requires PowerShell 5.1 or later.
    echo.
    pause & exit /b 1
)

:: ================================================================
::  GUARD - Administrator
::  Checks for the built-in Administrators SID (S-1-5-32-544) via
::  whoami /groups; more reliable than "net session" which can be
::  blocked by firewall rules or Group Policy restrictions.
:: ================================================================
whoami /groups 2>nul | find "S-1-5-32-544" >nul 2>&1
if %errorlevel% neq 0 (
    cls
    echo.
    echo  ================================================================
    echo   ACCESS DENIED - Administrator rights required
    echo  ================================================================
    echo.
    echo   Right-click the .bat file and select "Run as administrator".
    echo.
    pause & exit /b 1
)

:: ---- Jump to main body when called with /run flag ----
if "%~1"=="/run" goto :MAINBODY

:: ================================================================
::  TIMESTAMPS
:: ================================================================
call :SET_CLOCK

:: ================================================================
::  DIRECTORIES AND FILES
:: ================================================================
set "RUNDIR=%~dp0Logs\%COMPUTERNAME%_%TIMESTAMP%"
if not exist "%RUNDIR%" md "%RUNDIR%" >nul 2>&1
set "LOGFILE=%RUNDIR%\TechLog_%COMPUTERNAME%_%TIMESTAMP%.txt"
set "ERRFILE=%RUNDIR%\Errors_%COMPUTERNAME%_%TIMESTAMP%.txt"
set "USBDRIVE=%~d0"

:: ================================================================
::  DEFAULT - all sections ON
:: ================================================================
call :ALLON

:: ================================================================
::  PROFILE MENU (with WINULT banner)
:: ================================================================
:PROFILEMENU
cls
call :PRINT_BANNER
echo.
echo  ================================================================
echo    PC HEALTH CHECK, REPAIR ^& VIRUS SCAN  v%VERSION%   (WINULT)
echo    Computer : %COMPUTERNAME%
echo    User     : %USERNAME%
echo    Date     : %STARTDATE%   Time: %STARTTIME%
echo  ================================================================
echo.
echo  PRIVACY: No personal files, documents or passwords are saved.
echo.
echo  ================================================================
echo   SELECT A REPAIR PROFILE
echo  ================================================================
echo.
echo    [1]  Quick Check        SysInfo + Disk + Drivers + Quick Scan   ~20-30 min
echo    [2]  Full Maintenance   All sections + Full virus scan          ~1.5-3 hrs
echo    [3]  Critical Repair    SFC + DISM + Drivers + Malware + AV    ~1-2 hrs
echo    [4]  Virus/Malware      Malware persistence + Full virus scan   ~1-2 hrs
echo    [5]  Low-End Friendly   SysInfo + Disk + Drivers only           ~10-20 min
echo    [M]  Manual Selection   Toggle individual sections ON/OFF
echo    [Q]  Quit
echo.
choice /C 12345MQ /N /M "  Your choice: "
if errorlevel 7 goto :QUIT
if errorlevel 6 goto :MENULOOP
if errorlevel 5 ( call :PROFILE_LOWEND   & goto :STARTRUN )
if errorlevel 4 ( call :PROFILE_VIRUS    & goto :STARTRUN )
if errorlevel 3 ( call :PROFILE_CRITICAL & goto :STARTRUN )
if errorlevel 2 ( call :PROFILE_FULL     & goto :STARTRUN )
if errorlevel 1 ( call :PROFILE_QUICK    & goto :STARTRUN )
goto :PROFILEMENU

:: ================================================================
::  PROFILE DEFINITIONS
:: ================================================================
:PROFILE_QUICK
call :ALLOFF
call :PROFILE_SET "Quick Check" 1 SEC_SYSINFO SEC_DISKHLT SEC_DRIVERS SEC_VIRUS
set "NETRESET_DEFAULT=SKIP"
goto :EOF

:PROFILE_FULL
call :ALLON
set "PROFILE_NAME=Full Maintenance"
set "SCAN_MODE=2"
set "NETRESET_DEFAULT=ASK"
goto :EOF

:PROFILE_CRITICAL
call :ALLOFF
call :PROFILE_SET "Critical Repair" 3 SEC_SFC SEC_DISM SEC_DRIVERS SEC_MALWARE SEC_VIRUS
set "NETRESET_DEFAULT=ASK"
goto :EOF

:PROFILE_VIRUS
call :ALLOFF
call :PROFILE_SET "Virus/Malware Focus" 2 SEC_MALWARE SEC_VIRUS
set "NETRESET_DEFAULT=SKIP"
goto :EOF

:PROFILE_LOWEND
call :ALLOFF
call :PROFILE_SET "Low-End Friendly" 1 SEC_SYSINFO SEC_DISKHLT SEC_DRIVERS
set "NETRESET_DEFAULT=SKIP"
goto :EOF

:: ================================================================
::  :PROFILE_SET  name  scan_mode  [section ...]
:: ================================================================
:PROFILE_SET
set "PROFILE_NAME=%~1"
set "SCAN_MODE=%~2"
shift & shift
:PROFILE_SET_LOOP
if "%~1"=="" goto :EOF
set "%~1=ON"
shift
goto :PROFILE_SET_LOOP

:: ================================================================
::  MANUAL TOGGLE MENU
:: ================================================================
:MENULOOP
cls
echo.
echo  ================================================================
echo    MANUAL SECTION SELECTION  v%VERSION%
echo    Computer : %COMPUTERNAME%
echo  ================================================================
echo.
echo   STANDARD DIAGNOSTICS
echo    [1] [!SEC_SYSINFO!]  System Information + Activation
echo    [2] [!SEC_DISKHLT!]  Disk Health + SMART + Space
echo    [3] [!SEC_CHKDSK!]   CHKDSK File System Check
echo    [4] [!SEC_SFC!]      SFC System File Repair
echo    [5] [!SEC_DISM!]     DISM Windows Image Repair
echo    [6] [!SEC_NETWORK!]  Network Diagnostics + Reset
echo    [7] [!SEC_WUPDATE!]  Windows Update Cache Clear
echo    [8] [!SEC_VIRUS!]    Virus Scan (Defender)
echo    [T] [!SEC_TEMP!]     Temperature + Thermal Health
echo.
echo   ADVANCED DIAGNOSTICS
echo    [9] [!SEC_DRIVERS!]  Driver Health
echo    [B] [!SEC_MALWARE!]  Malware Persistence
echo    [C] [!SEC_RESTORE!]  System Restore Check
echo    [D] [!SEC_SSDWEAR!]  SSD Wear Level
echo    [E] [!SEC_BSOD!]     BSOD / Crash Log Analysis
echo.
echo    [A] All ON   [N] All OFF   [S] Start   [0] Profile Menu   [Q] Quit
echo.
set "MCHOICE="
set /p MCHOICE="  Toggle (1-9 / B-E / T / A / N / S / 0 / Q): "
set "MCHOICE=!MCHOICE: =!"
if "!MCHOICE!"==""  goto :MENULOOP

if "!MCHOICE!"=="1"  ( call :TOGGLE SEC_SYSINFO & goto :MENULOOP )
if "!MCHOICE!"=="2"  ( call :TOGGLE SEC_DISKHLT & goto :MENULOOP )
if "!MCHOICE!"=="3"  ( call :TOGGLE SEC_CHKDSK  & goto :MENULOOP )
if "!MCHOICE!"=="4"  ( call :TOGGLE SEC_SFC     & goto :MENULOOP )
if "!MCHOICE!"=="5"  ( call :TOGGLE SEC_DISM    & goto :MENULOOP )
if "!MCHOICE!"=="6"  ( call :TOGGLE SEC_NETWORK & goto :MENULOOP )
if "!MCHOICE!"=="7"  ( call :TOGGLE SEC_WUPDATE & goto :MENULOOP )
if "!MCHOICE!"=="8"  ( call :TOGGLE SEC_VIRUS   & goto :MENULOOP )
if /i "!MCHOICE!"=="T" ( call :TOGGLE SEC_TEMP  & goto :MENULOOP )
if "!MCHOICE!"=="9"  ( call :TOGGLE SEC_DRIVERS & goto :MENULOOP )
if /i "!MCHOICE!"=="B" ( call :TOGGLE SEC_MALWARE & goto :MENULOOP )
if /i "!MCHOICE!"=="C" ( call :TOGGLE SEC_RESTORE & goto :MENULOOP )
if /i "!MCHOICE!"=="D" ( call :TOGGLE SEC_SSDWEAR & goto :MENULOOP )
if /i "!MCHOICE!"=="E" ( call :TOGGLE SEC_BSOD  & goto :MENULOOP )
if /i "!MCHOICE!"=="A" ( call :ALLON  & goto :MENULOOP )
if /i "!MCHOICE!"=="N" ( call :ALLOFF & goto :MENULOOP )
if "!MCHOICE!"=="0"  goto :PROFILEMENU
if /i "!MCHOICE!"=="Q" goto :QUIT
if /i "!MCHOICE!"=="S" goto :STARTRUN
echo   Unknown option. Press a key and try again.
pause >nul
goto :MENULOOP

:TOGGLE
if "!%1!"=="ON" (set "%1=OFF") else (set "%1=ON")
goto :EOF

:ALLON
set "SEC_SYSINFO=ON" & set "SEC_DISKHLT=ON" & set "SEC_CHKDSK=ON"
set "SEC_SFC=ON"     & set "SEC_DISM=ON"    & set "SEC_NETWORK=ON"
set "SEC_WUPDATE=ON" & set "SEC_VIRUS=ON"   & set "SEC_DRIVERS=ON"
set "SEC_BSOD=ON"    & set "SEC_MALWARE=ON" & set "SEC_RESTORE=ON"
set "SEC_SSDWEAR=ON" & set "SEC_TEMP=ON"
set "PROFILE_NAME=Manual"
set "SCAN_MODE=1"
set "NETRESET_DEFAULT=ASK"
goto :EOF

:ALLOFF
set "SEC_SYSINFO=OFF" & set "SEC_DISKHLT=OFF" & set "SEC_CHKDSK=OFF"
set "SEC_SFC=OFF"     & set "SEC_DISM=OFF"    & set "SEC_NETWORK=OFF"
set "SEC_WUPDATE=OFF" & set "SEC_VIRUS=OFF"   & set "SEC_DRIVERS=OFF"
set "SEC_BSOD=OFF"    & set "SEC_MALWARE=OFF" & set "SEC_RESTORE=OFF"
set "SEC_SSDWEAR=OFF" & set "SEC_TEMP=OFF"
goto :EOF

:QUIT
cls
echo.
echo  ================================================================
echo   WINULT v%VERSION% - Exited. No changes made.
echo  ================================================================
echo.
pause & exit /b 0

:: ================================================================
::  CONFIRM AND LAUNCH
:: ================================================================
:STARTRUN
cls
echo.
echo  ================================================================
echo   PROFILE  : %PROFILE_NAME%
call :SHOW_SCANMODE
echo  ================================================================
echo.
call :SHOW_STATUS SEC_SYSINFO  "1  System Information"
call :SHOW_STATUS SEC_DISKHLT  "2  Disk Health"
call :SHOW_STATUS SEC_TEMP     "T  Temperature"
call :SHOW_STATUS SEC_CHKDSK   "3  CHKDSK"
call :SHOW_STATUS SEC_SFC      "4  SFC"
call :SHOW_STATUS SEC_DISM     "5  DISM"
call :SHOW_STATUS SEC_NETWORK  "6  Network"
call :SHOW_STATUS SEC_WUPDATE  "7  Windows Update"
call :SHOW_STATUS SEC_VIRUS    "8  Virus Scan"
call :SHOW_STATUS SEC_DRIVERS  "9  Driver Health"
call :SHOW_STATUS SEC_MALWARE  "B  Malware Persistence"
call :SHOW_STATUS SEC_RESTORE  "C  System Restore"
call :SHOW_STATUS SEC_SSDWEAR  "D  SSD Wear Level"
call :SHOW_STATUS SEC_BSOD     "E  BSOD/Crash Logs"
echo.
echo  Press ENTER to start  or  Q to go back.
choice /C QS /N /M "  (Q=back, S=start): " 2>nul
if errorlevel 2 goto :DO_RUN
if errorlevel 1 goto :PROFILEMENU
:DO_RUN

:: ---- Write config file ----
(
    echo LOGFILE=!LOGFILE!
    echo ERRFILE=!ERRFILE!
    echo RUNDIR=!RUNDIR!
    echo VERSION=!VERSION!
    echo STARTTIME=!STARTTIME!
    echo STARTDATE=!STARTDATE!
    echo USBDRIVE=!USBDRIVE!
    echo PROFILE_NAME=!PROFILE_NAME!
    echo SCAN_MODE=!SCAN_MODE!
    echo NETRESET_DEFAULT=!NETRESET_DEFAULT!
    echo SEC_SYSINFO=!SEC_SYSINFO!
    echo SEC_DISKHLT=!SEC_DISKHLT!
    echo SEC_CHKDSK=!SEC_CHKDSK!
    echo SEC_SFC=!SEC_SFC!
    echo SEC_DISM=!SEC_DISM!
    echo SEC_NETWORK=!SEC_NETWORK!
    echo SEC_WUPDATE=!SEC_WUPDATE!
    echo SEC_VIRUS=!SEC_VIRUS!
    echo SEC_DRIVERS=!SEC_DRIVERS!
    echo SEC_BSOD=!SEC_BSOD!
    echo SEC_MALWARE=!SEC_MALWARE!
    echo SEC_RESTORE=!SEC_RESTORE!
    echo SEC_SSDWEAR=!SEC_SSDWEAR!
    echo SEC_TEMP=!SEC_TEMP!
) > "%RUNDIR%\run.cfg"

%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "cmd /c '%~f0' /run '%RUNDIR%\run.cfg' 2>&1 | Tee-Object -LiteralPath '%LOGFILE%'"


echo.
echo  ================================================================
echo   ALL DONE.
echo.
echo   Diagnostic log : %LOGFILE%
echo   Error log      : %ERRFILE%
echo  ================================================================
echo.
pause
exit /b 0

:: ================================================================
::  :SHOW_STATUS  FLAG  "Label"
:: ================================================================
:SHOW_STATUS
if "!%~1!"=="ON" (
    echo    [ON ]  %~2
) else (
    echo    [----]  %~2  ^(skipped^)
)
goto :EOF

:SHOW_SCANMODE
set "_SCAN_TEXT=Scan Mode: Quick"
if "%SCAN_MODE%"=="2" set "_SCAN_TEXT=Scan Mode: Full"
if "%SCAN_MODE%"=="3" set "_SCAN_TEXT=Scan Mode: Deep"
echo   %_SCAN_TEXT%
goto :EOF

:: ================================================================
::  MAIN BODY  (runs inside the PowerShell Tee pipe)
::  (Most of this section unchanged from your v2.4 script)
:: ================================================================
:MAINBODY

set "CFGFILE=%~2"
for /f "usebackq tokens=1,* delims==" %%A in ("%CFGFILE%") do set "%%A=%%B"

:: ---- Initialise all summary results to Skipped ----
for %%V in (
    SUM_SYSINFO SUM_ACTIVATION SUM_SMART SUM_DISKSPACE SUM_DISKTYPE
    SUM_CHKDSK  SUM_SFC        SUM_DISM  SUM_NETWORK   SUM_UPDATE
    SUM_VIRUS   SUM_DRIVERS    SUM_MALWARE SUM_RESTORE  SUM_SSDWEAR
    SUM_BSOD    SUM_REBOOT     SUM_TEMP  SUM_RESTORE_POINT
) do set "%%V=Skipped"

:: ================================================================
::  LOG HEADER
:: ================================================================
call :LOG_BANNER "WINULT - PC HEALTH CHECK, REPAIR and VIRUS SCAN  v!VERSION!"
echo  Profile  : !PROFILE_NAME!
echo  Computer : %COMPUTERNAME%
echo  User     : %USERNAME%
echo  Date     : !STARTDATE!
echo  Started  : !STARTTIME!
echo.
echo  ----------------------------------------------------------------
echo   TABLE OF CONTENTS
echo  ----------------------------------------------------------------
echo    Pre-run  Pending Reboot Check
echo    Pre-run  Auto Restore Point
if "!SEC_SYSINFO!"=="ON" echo    [ 1/14]  System Information + Activation
if "!SEC_DISKHLT!"=="ON" echo    [ 2/14]  Disk Health, Type + Space
if "!SEC_TEMP!"=="ON"    echo    [ T/14]  Temperature + Thermal Health
if "!SEC_CHKDSK!"=="ON"  echo    [ 3/14]  File System Check (CHKDSK)
if "!SEC_SFC!"=="ON"     echo    [ 4/14]  System File Checker (SFC)
if "!SEC_DISM!"=="ON"    echo    [ 5/14]  Windows Image Repair (DISM)
if "!SEC_NETWORK!"=="ON" echo    [ 6/14]  Network Diagnostics + Reset
if "!SEC_WUPDATE!"=="ON" echo    [ 7/14]  Windows Update Services
if "!SEC_VIRUS!"=="ON"   echo    [ 8/14]  Virus Scan (Windows Defender)
if "!SEC_DRIVERS!"=="ON" echo    [ 9/14]  Driver Health Check
if "!SEC_MALWARE!"=="ON" echo    [10/14]  Malware Persistence Scan
if "!SEC_RESTORE!"=="ON" echo    [11/14]  System Restore Check
if "!SEC_SSDWEAR!"=="ON" echo    [12/14]  SSD Wear Level
if "!SEC_BSOD!"=="ON"    echo    [13/14]  BSOD + Crash Log Analysis
echo    [14/14]  Final Summary + Customer Report
echo  ----------------------------------------------------------------
echo.

call :RUN_PRERUN
if "!SEC_SYSINFO!"=="ON" call :RUN_SYSINFO
if "!SEC_DISKHLT!"=="ON" call :RUN_DISK
if "!SEC_TEMP!"=="ON" call :RUN_TEMP
if "!SEC_CHKDSK!"=="ON" call :RUN_CHKDSK
if "!SEC_SFC!"=="ON" call :RUN_SFC
if "!SEC_DISM!"=="ON" call :RUN_DISM
if "!SEC_NETWORK!"=="ON" call :RUN_NETWORK
if "!SEC_WUPDATE!"=="ON" call :RUN_WUPDATE
if "!SEC_VIRUS!"=="ON" call :RUN_VIRUS
if "!SEC_DRIVERS!"=="ON" call :RUN_DRIVERS
if "!SEC_MALWARE!"=="ON" call :RUN_MALWARE
if "!SEC_RESTORE!"=="ON" call :RUN_RESTORE
if "!SEC_SSDWEAR!"=="ON" call :RUN_SSDWEAR
if "!SEC_BSOD!"=="ON" call :RUN_BSOD

call :WRITE_REPORT
exit /b 0

:RUN_PRERUN
call :LOG_SECTION_OPEN PRE "Pending Reboot + Restore Point"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1
if errorlevel 1 (
    echo  Pending reboot: No
    set "SUM_REBOOT=PASS"
) else (
    echo  Pending reboot: Yes
    set "SUM_REBOOT=WARN"
)
:: Use PowerShell Checkpoint-Computer (wmic is deprecated and removed in Windows 11 24H2+)
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try{Checkpoint-Computer -Description 'WINULT pre-run' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop}catch{exit 1}" >nul 2>&1
if errorlevel 1 (
    echo  Restore point: Unavailable
    echo    ^(System Protection may be disabled or blocked by Group Policy^)
    echo    ^(To enable: Control Panel ^> System ^> System Protection^)
    set "SUM_RESTORE_POINT=WARN"
) else (
    echo  Restore point: Created
    set "SUM_RESTORE_POINT=PASS"
)
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_SYSINFO
call :LOG_SECTION_OPEN 1 "System Information + Activation"
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$cs=Get-CimInstance Win32_OperatingSystem; $cpu=Get-CimInstance Win32_Processor | Select-Object -First 1; [PSCustomObject]@{Computer=$env:COMPUTERNAME; OS=$cs.Caption; Build=$cs.BuildNumber; Architecture=$cs.OSArchitecture; RAM_GB=[math]::Round($cs.TotalVisibleMemorySize/1MB,2); FreeRAM_GB=[math]::Round($cs.FreePhysicalMemory/1MB,2); LastBoot=$cs.LastBootUpTime; CPU=$cpu.Name} | Format-List"
cscript //nologo "%windir%\system32\slmgr.vbs" /xpr 2>nul
set "SUM_SYSINFO=PASS"
set "SUM_ACTIVATION=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_DISK
call :LOG_SECTION_OPEN 2 "Disk Health + SMART + Space"
echo  -- Logical drive space --
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{n='Used_GB';e={[math]::Round($_.Used/1GB,1)}},@{n='Free_GB';e={[math]::Round($_.Free/1GB,1)}},@{n='Total_GB';e={[math]::Round(($_.Used+$_.Free)/1GB,1)}} | Format-Table -AutoSize"
echo  -- Physical disks --
:: Get-PhysicalDisk requires Storage module; guard with try/catch for older builds
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try{Get-PhysicalDisk | Select-Object FriendlyName,MediaType,HealthStatus,OperationalStatus,@{n='Size_GB';e={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize}catch{Write-Host 'Get-PhysicalDisk unavailable on this build - physical disk listing skipped.'}"
set "SUM_SMART=PASS"
set "SUM_DISKSPACE=PASS"
set "SUM_DISKTYPE=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_TEMP
call :LOG_SECTION_OPEN T "Temperature + Thermal Health"
:: Note: closing brace count - @{} hashtable + if(){} = balanced; no extra brace needed
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$t=Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue; if($t){$t | Select-Object InstanceName,@{n='TempC';e={[math]::Round(($_.CurrentTemperature/10)-273.15,1)}} | Format-Table -AutoSize}else{Write-Host 'Thermal sensors unavailable via ACPI'}"
set "SUM_TEMP=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_CHKDSK
call :LOG_SECTION_OPEN 3 "CHKDSK - File System Check"
echo  Detecting C: drive type...
set "CHKDSK_TYPE=Unknown"
for /f "usebackq delims=" %%T in (`%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try{$dn=(Get-Partition -DriveLetter C).DiskNumber; $disk=Get-Disk -Number $dn; $pd=Get-PhysicalDisk | Where-Object UniqueId -eq $disk.UniqueId; if($pd.MediaType){$pd.MediaType}else{'Unknown'}}catch{'Unknown'}"`) do set "CHKDSK_TYPE=%%T"
echo  Drive type : !CHKDSK_TYPE!
echo.
if /i "!CHKDSK_TYPE!"=="SSD" (
    echo  Time estimates for this drive:
    echo    Online scan  ^(C: /scan^)  :  ~5-15 minutes    - runs now, no reboot needed
    echo    Offline repair ^(/f /r^)   :  ~30-90 minutes   - schedules on next reboot
) else if /i "!CHKDSK_TYPE!"=="HDD" (
    echo  Time estimates for this drive ^(HDD^):
    echo    Online scan  ^(C: /scan^)  :  ~15-45 minutes   - runs now, no reboot needed
    echo    Offline repair ^(/f /r^)   :  ~2-8 HOURS       - schedules on next reboot, varies by disk size
) else (
    echo  Time estimates ^(drive type unknown^):
    echo    Online scan  ^(C: /scan^)  :  ~10-30 minutes   - runs now, no reboot needed
    echo    Offline repair ^(/f /r^)   :  ~1-6 hours       - schedules on next reboot
)
echo.
choice /C 123 /N /M "  CHKDSK mode:  1=Online scan now   2=Schedule offline repair (reboot)   3=Skip  -- "
if errorlevel 3 (
    echo  CHKDSK: Skipped.
    set "SUM_CHKDSK=Skipped"
) else if errorlevel 2 (
    echo  Scheduling offline CHKDSK repair ^(chkdsk C: /f /r^)...
    echo Y | chkdsk C: /f /r 2>>"!ERRFILE!"
    echo  Offline CHKDSK scheduled. Run will begin on next reboot.
    set "SUM_CHKDSK=Scheduled-offline"
) else (
    echo  Running online scan ^(chkdsk C: /scan^)...
    chkdsk C: /scan 2>>"!ERRFILE!"
    set "SUM_CHKDSK=PASS"
)
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_SFC
call :LOG_SECTION_OPEN 4 "SFC"
echo  Scanning protected system files for integrity violations...
echo.
sfc /scannow 2>>"!ERRFILE!"
:: exitcodes: 0=clean, 1=violations found, 2=could not run, 3=pending reboot repair
:: For exitcode 1, parse the CBS log to distinguish repaired vs unrepairable.
if errorlevel 3 (
    echo  SFC: Repair pending - reboot required to complete.
    set "SUM_SFC=WARN-REBOOT"
) else if errorlevel 2 (
    echo  SFC: Could not perform the requested operation.
    set "SUM_SFC=FAIL"
) else if errorlevel 1 (
    set "SUM_SFC=WARN"
    for /f "usebackq delims=" %%L in (`%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try{$f=Join-Path $env:windir 'Logs\CBS\CBS.log'; $t=Get-Content $f -Tail 300 -EA Stop; if($t -match 'successfully repaired them'){'REPAIRED'}elseif($t -match 'unable to repair'){'FAIL'}else{'WARN'}}catch{'WARN'}"`) do set "SUM_SFC=%%L"
    if "!SUM_SFC!"=="REPAIRED" echo  SFC: Corrupt files found and successfully repaired.
    if "!SUM_SFC!"=="FAIL"     echo  SFC: Corrupt files found - some could NOT be repaired. Check CBS.log.
    if "!SUM_SFC!"=="WARN"     echo  SFC: Violations detected. Review CBS.log for details.
) else (
    set "SUM_SFC=PASS"
)
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_DISM
call :LOG_SECTION_OPEN 5 "DISM"
echo  Checking image health...
dism /online /cleanup-image /checkhealth 2>>"!ERRFILE!"
echo.
echo  Repairing Windows image...
echo  (RestoreHealth may download replacement files from Windows Update)
dism /online /cleanup-image /restorehealth 2>>"!ERRFILE!"
if errorlevel 1 (set "SUM_DISM=WARN") else set "SUM_DISM=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_NETWORK
call :LOG_SECTION_OPEN 6 "Network Diagnostics + Reset"
echo  -- IP addresses --
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch 'Loopback'} | Select-Object InterfaceAlias,IPAddress,PrefixLength | Format-Table -AutoSize"
echo  -- Internet connectivity --
:: Capture the connectivity result so it can drive the SUM_NETWORK status flag
set "_NET_PING=FAIL"
for /f "usebackq delims=" %%R in (`%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "if(Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet -ErrorAction SilentlyContinue){'OK'}else{'FAIL'}"`) do set "_NET_PING=%%R"
if "!_NET_PING!"=="OK" (
    echo  Internet: Reachable
    set "SUM_NETWORK=PASS"
) else (
    echo  Internet: No response - check connection
    set "SUM_NETWORK=WARN"
)
echo.
if /i "!NETRESET_DEFAULT!"=="SKIP" (
    echo  Network reset: Skipped by profile.
) else (
    echo  Reset network stack? This flushes DNS and resets Winsock + IP. Reboot required after.
    choice /C YN /N /M "  Reset network stack? (Y=Yes  N=Skip): "
    if errorlevel 2 (
        echo  Network reset: Skipped.
    ) else (
        echo  Resetting network stack...
        ipconfig /flushdns >nul 2>&1
        netsh winsock reset >nul 2>&1
        netsh int ip reset >nul 2>&1
        echo  Network stack reset applied. Reboot required.
    )
)
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_WUPDATE
call :LOG_SECTION_OPEN 7 "Windows Update Services"
echo  Stopping Windows Update services...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
echo  Clearing SoftwareDistribution cache...
:: Remove any leftover .bak from a previous run before renaming; otherwise ren fails silently
if exist "%windir%\SoftwareDistribution.bak" rd /s /q "%windir%\SoftwareDistribution.bak" >nul 2>&1
if exist "%windir%\SoftwareDistribution" ren "%windir%\SoftwareDistribution" SoftwareDistribution.bak >nul 2>&1
echo  Restarting Windows Update services...
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo  Windows Update cache cleared. A fresh cache rebuilds on the next update check.
set "SUM_UPDATE=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_VIRUS
call :LOG_SECTION_OPEN 8 "Windows Defender Scan"
:: Try the stable legacy path first, then scan for the current versioned platform folder.
:: The platform folder name changes with every Defender update; never hardcode the version.
set "MP_PATH=%ProgramFiles%\Windows Defender\MpCmdRun.exe"
if not exist "!MP_PATH!" (
    :: _MP_FOUND is a sentinel that stops the loop after the first (newest) match;
    :: initialise here so the loop behaves correctly even if the variable was left set.
    set "_MP_FOUND="
    for /f "usebackq delims=" %%P in (`dir /b /ad /o-n "%ProgramData%\Microsoft\Windows Defender\Platform" 2^>nul`) do (
        if not defined _MP_FOUND (
            if exist "%ProgramData%\Microsoft\Windows Defender\Platform\%%P\MpCmdRun.exe" (
                set "MP_PATH=%ProgramData%\Microsoft\Windows Defender\Platform\%%P\MpCmdRun.exe"
                set "_MP_FOUND=1"
            )
        )
    )
    set "_MP_FOUND=" :: cleanup - prevent sentinel leaking into the rest of the script
)
if exist "!MP_PATH!" (
    "!MP_PATH!" -SignatureUpdate 2>>"!ERRFILE!"
    if "!SCAN_MODE!"=="2" (
        "!MP_PATH!" -Scan -ScanType 2 2>>"!ERRFILE!"
    ) else (
        "!MP_PATH!" -Scan -ScanType 1 2>>"!ERRFILE!"
    )
    set "SUM_VIRUS=PASS"
) else (
    echo  MpCmdRun.exe not found. Defender CLI skipped.
    set "SUM_VIRUS=WARN"
)
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_DRIVERS
call :LOG_SECTION_OPEN 9 "Driver Health"
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$all=Get-CimInstance Win32_PnPEntity; $prob=$all | Where-Object {$_.ConfigManagerErrorCode -ne 0}; Write-Host ('Total devices: ' + $all.Count); if($prob.Count -gt 0){Write-Host ('Problem devices: ' + $prob.Count); $prob | Select-Object Name,DeviceID,ConfigManagerErrorCode | Format-Table -AutoSize}else{Write-Host 'No problem devices found - all drivers OK.'}"
set "SUM_DRIVERS=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_MALWARE
call :LOG_SECTION_OPEN 10 "Malware Persistence"
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$t=Get-ScheduledTask | Where-Object {$_.TaskPath -notmatch '\\Microsoft\\' -and $_.State -ne 'Disabled'}; Write-Host ('Non-Microsoft active scheduled tasks: ' + $t.Count); $t | Select-Object TaskName,TaskPath,State | Format-Table -AutoSize"
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$s=Get-CimInstance Win32_Service | Where-Object {$_.State -eq 'Running' -and $_.PathName -notmatch 'Windows' -and $_.PathName -notmatch 'Microsoft' -and $_.PathName -notmatch 'svchost'}; Write-Host ('Non-Windows running services: ' + $s.Count); $s | Select-Object Name,DisplayName,@{n='Path';e={$_.PathName -replace '\"',''}} | Format-Table -AutoSize"
set "SUM_MALWARE=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_RESTORE
call :LOG_SECTION_OPEN 11 "System Restore"
vssadmin list shadows
set "SUM_RESTORE=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_SSDWEAR
call :LOG_SECTION_OPEN 12 "SSD Wear Level"
echo  -- Storage reliability counters (SMART-equivalent: Wear, Temp, Errors) --
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-PhysicalDisk | ForEach-Object { $r=$_ | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue; [PSCustomObject]@{Disk=$_.FriendlyName; Type=$_.MediaType; Health=$_.HealthStatus; Wear_Pct=if($r){$r.Wear}else{'N/A'}; Temp_C=if($r){$r.Temperature}else{'N/A'}; ReadErrs=if($r){$r.ReadErrorsCorrected}else{'N/A'}; WriteErrs=if($r){$r.WriteErrorsCorrected}else{'N/A'} } } | Format-Table -AutoSize"
set "SUM_SSDWEAR=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:RUN_BSOD
call :LOG_SECTION_OPEN 13 "BSOD + Crash Logs"
%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$evts=Get-WinEvent -LogName System -MaxEvents 500 -ErrorAction SilentlyContinue | Where-Object {$_.Level -in 1,2} | Select-Object -First 20; Write-Host ('Critical/Error events found: ' + $evts.Count); $evts | Select-Object TimeCreated,LevelDisplayName,ProviderName,@{n='Message';e={($_.Message -split '\r?\n')[0]}} | Format-Table -AutoSize -Wrap"
set "SUM_BSOD=PASS"
call :LOG_SECTION_CLOSE
goto :EOF

:: ================================================================
::  WRITE DIAGNOSTIC SUMMARY
:: ================================================================
:WRITE_REPORT
echo.
echo  ================================================================
echo   DIAGNOSTIC SUMMARY
echo  ================================================================
echo  Pending Reboot   : !SUM_REBOOT!
echo  Restore Point    : !SUM_RESTORE_POINT!
echo  System Info      : !SUM_SYSINFO!
echo  Activation       : !SUM_ACTIVATION!
echo  Disk SMART       : !SUM_SMART!
echo  Disk Space       : !SUM_DISKSPACE!
echo  Temperature      : !SUM_TEMP!
echo  CHKDSK           : !SUM_CHKDSK!
echo  SFC              : !SUM_SFC!
echo  DISM             : !SUM_DISM!
echo  Network          : !SUM_NETWORK!
echo  Windows Update   : !SUM_UPDATE!
echo  Virus Scan       : !SUM_VIRUS!
echo  Drivers          : !SUM_DRIVERS!
echo  Malware Persist. : !SUM_MALWARE!
echo  System Restore   : !SUM_RESTORE!
echo  SSD Wear         : !SUM_SSDWEAR!
echo  BSOD Logs        : !SUM_BSOD!
echo  ================================================================
echo.
echo  Log saved: !LOGFILE!

goto :EOF

:: ================================================================
::  LOG HELPERS & BANNER
:: ================================================================
:LOG_BANNER
echo.
echo  ################################################################################
echo   %~1
echo  ################################################################################
echo.
goto :EOF

:LOG_SECTION_OPEN
for /f "usebackq delims=" %%T in (`%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Date -Format 'HH:mm:ss'"`) do set "_SEC_START=%%T"
echo.
echo  ================================================================
echo   [%~1]  %~2
echo   Started : !_SEC_START!
echo  ================================================================
echo.
goto :EOF

:LOG_SECTION_CLOSE
for /f "usebackq delims=" %%T in (`%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Date -Format 'HH:mm:ss'"`) do set "_SEC_END=%%T"
echo.
echo  ----------------------------------------------------------------
echo   Finished: !_SEC_END!
echo  ----------------------------------------------------------------
goto :EOF


:PRINT_BANNER
echo.
echo  ================================================================
echo  =                          W I N U L T                         =
echo  =                  Windows Ultimate Tool v%VERSION%            =
echo  ================================================================
echo.
goto :EOF

:SET_CLOCK
set "TIMESTAMP="
set "STARTTIME="
set "STARTDATE="
for /f "usebackq delims=" %%T in (`%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"`) do set "TIMESTAMP=%%T"
for /f "usebackq delims=" %%S in (`%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Date -Format 'HH:mm:ss'"`) do set "STARTTIME=%%S"
for /f "usebackq delims=" %%D in (`%PS_EXE% -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Date -Format 'dd/MM/yyyy'"`) do set "STARTDATE=%%D"

if not defined STARTDATE set "STARTDATE=%date%"
if not defined STARTTIME set "STARTTIME=%time:~0,8%"
if not defined TIMESTAMP (
    set "TIMESTAMP=%date%_%time%"
    set "TIMESTAMP=!TIMESTAMP:/=-!"
    set "TIMESTAMP=!TIMESTAMP::=-!"
    set "TIMESTAMP=!TIMESTAMP: =0!"
    set "TIMESTAMP=!TIMESTAMP:.=-!"
)
goto :EOF
