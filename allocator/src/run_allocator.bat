@echo off
REM ============================================================================
REM  run_allocator.bat
REM
REM  Launcher for the GTAP-AEZ allocator workflow.
REM
REM  Modes:
REM      P = probe the GDX structure with probe_gdx.py
REM      A = run the pixel allocator with allocate.py
REM
REM  Usage:
REM      run_allocator.bat
REM
REM  or:
REM      run_allocator.bat "C:\path\to\Rdyn.gdx"
REM ============================================================================

setlocal

REM --- Python environment ---
set "VENV_PY=C:\Users\JesusMERCADO\QGISProjects\MERCOSUR2\.venv\Scripts\python.exe"

REM --- Default directory for interactive GDX selection ---
set "OUTDIR=C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn\output"

REM --- Python targets ---
set "PROBE_TARGET=%~dp0probe_gdx.py"
set "ALLOC_TARGET=%~dp0allocate.py"


REM ============================================================================
REM Choose mode
REM ============================================================================

echo.
echo ============================================================
echo GTAP-AEZ Allocator
echo ============================================================
echo.
choice /C PA /N /M "Choose mode: [P]robe GDX or run [A]llocator: "

if errorlevel 2 (
    set "MODE=allocator"
    set "TARGET=%ALLOC_TARGET%"
) else (
    set "MODE=probe"
    set "TARGET=%PROBE_TARGET%"
)


REM ============================================================================
REM Validate prerequisites
REM ============================================================================

if not exist "%VENV_PY%" (
    echo [error] Python not found at:
    echo     %VENV_PY%
    exit /b 1
)

if not exist "%TARGET%" (
    echo [error] Target script not found:
    echo     %TARGET%
    exit /b 1
)


REM ============================================================================
REM Use GDX supplied as first argument, if present
REM ============================================================================

set "GDX=%~1"

if defined GDX goto validate_gdx


REM ============================================================================
REM Otherwise open interactive GDX picker
REM ============================================================================

set "PICKFILE=%TEMP%\allocator_gdx_%RANDOM%_%RANDOM%.txt"

powershell.exe -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.InitialDirectory = '%OUTDIR%'; $d.Filter = 'GDX files (*.gdx)' + [char]124 + '*.gdx' + [char]124 + 'All files (*.*)' + [char]124 + '*.*'; $d.Title = 'Pick a CGE result .gdx'; if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { [Console]::Out.Write($d.FileName) }" > "%PICKFILE%"

set /p "GDX="<"%PICKFILE%"

del /q "%PICKFILE%" >nul 2>&1

if not defined GDX (
    echo No file selected. Nothing to do.
    exit /b 1
)


REM ============================================================================
REM Validate GDX
REM ============================================================================

:validate_gdx

if not exist "%GDX%" (
    echo [error] GDX file not found:
    echo     %GDX%
    exit /b 1
)


REM ============================================================================
REM Run selected mode
REM ============================================================================

echo.
echo Mode         : %MODE%
echo Selected GDX : %GDX%
echo Python       : %VENV_PY%
echo Target       : %TARGET%
echo.

"%VENV_PY%" "%TARGET%" --gdx "%GDX%"

set "RC=%ERRORLEVEL%"

echo.

if not "%RC%"=="0" (
    echo [error] %MODE% exited with code %RC%.
    exit /b %RC%
)

echo [done] %MODE% completed successfully.

endlocal
exit /b 0