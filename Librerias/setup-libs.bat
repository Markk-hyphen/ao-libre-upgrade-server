@echo off
setlocal enabledelayedexpansion

:: Setup de librerias/OCX para compilar y correr ao-server (VB6) en una maquina Windows nueva.
:: Corre una sola vez por maquina (PC nueva, VM nueva). Requiere permisos de administrador
:: porque copia a C:\Windows\SysWOW64 y registra OCX/COM ahi.

:: --- auto-elevacion: si no es admin, relanza este mismo script pidiendo UAC ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Pidiendo permisos de administrador...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "SCRIPT_DIR=%~dp0"
:: carpeta del proyecto = un nivel arriba de Librerias\ (donde esta SERVER.VBP)
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "WIN_SYSWOW64=%WINDIR%\SysWOW64"
set "REGSVR=%WIN_SYSWOW64%\regsvr32.exe"
set "BACKUP_DIR=%SCRIPT_DIR%backup_syswow64"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo.
echo === 1/3: DLLs especificas del juego -> carpeta del proyecto ===
:: Estas NO son DLLs de Windows, son del juego/AO. No necesitan regsvr32, VB6 las busca
:: en el directorio de la app. Copiarlas a System32 no hace falta y no aporta nada.
for %%F in (AAMD532.DLL AOFX.DLL AOLIB.DLL IJL11.DLL LEEINIS.DLL LEEMAPAS.DLL VBABDX.DLL ZLIB.DLL) do (
    if exist "%SCRIPT_DIR%system32\%%F" (
        copy /Y "%SCRIPT_DIR%system32\%%F" "%PROJECT_DIR%\" >nul
        echo   copiado %%F
    ) else (
        echo   AVISO: no se encontro %%F en system32\, saltando
    )
)

echo.
echo === 2/3: OCX/DLLs de 32 bits -> C:\Windows\SysWOW64 + registro COM ===
:: NO copiamos GDI32.DLL, WINMM.DLL, WS2_32.DLL (carpeta system32 del repo) ni
:: OLEAUT32.DLL, SHDOCVW.DLL, QUARTZ.DLL, OLEPRO32.DLL (carpeta SysWOW64 del repo):
:: son DLLs del propio Windows XP de la epoca del juego. Windows moderno ya trae las suyas;
:: pisarlas es innecesario y riesgoso (Windows Resource Protection puede bloquearlo igual).
for %%F in (COMCTL32.OCX COMDLG32.OCX CSWSK32.OCX DX7VB.DLL DX8VB.DLL MSADODC.OCX MSCOMCTL.OCX MSINET.OCX MSSTDFMT.DLL MSVBVM50.DLL MSVBVM60.DLL MSWINSCK.OCX RICHTX32.OCX VBALPROGBAR6.OCX) do (
    if exist "%SCRIPT_DIR%SysWOW64\%%F" (
        if exist "%WIN_SYSWOW64%\%%F" (
            if not exist "%BACKUP_DIR%\%%F" (
                copy /Y "%WIN_SYSWOW64%\%%F" "%BACKUP_DIR%\%%F" >nul
                echo   backup de %%F existente guardado en backup_syswow64\
            )
        )
        copy /Y "%SCRIPT_DIR%SysWOW64\%%F" "%WIN_SYSWOW64%\" >nul
        echo   copiado %%F
    ) else (
        echo   AVISO: no se encontro %%F en SysWOW64\, saltando
    )
)

echo.
echo === 3/3: Registrando controles COM/OCX ===
for %%F in (COMCTL32.OCX COMDLG32.OCX CSWSK32.OCX MSADODC.OCX MSCOMCTL.OCX MSINET.OCX MSWINSCK.OCX RICHTX32.OCX VBALPROGBAR6.OCX) do (
    if exist "%WIN_SYSWOW64%\%%F" (
        "%REGSVR%" /s "%WIN_SYSWOW64%\%%F"
        if !errorlevel! equ 0 (
            echo   registrado %%F
        ) else (
            echo   AVISO: regsvr32 fallo en %%F ^(codigo !errorlevel!^), puede no ser bloqueante
        )
    )
)

echo.
echo Listo. Abri SERVER.VBP en el IDE de VB6 y dale Run (F5).
echo Si tira error de "componente no encontrado o no registrado correctamente" para algun
echo archivo que este script saltedo a proposito (ver comentarios arriba), avisale a Claude.
echo.
echo Si algun archivo que ya tenias en SysWOW64 fue sobreescrito, hay copia de respaldo en
echo %BACKUP_DIR% (se guarda solo la primera vez, no se pisa en corridas siguientes).
echo Para revertir manualmente: copia los archivos de esa carpeta de vuelta a %WIN_SYSWOW64%
echo y corre "regsvr32 /u archivo.ocx" si lo habias registrado.
echo.
pause
