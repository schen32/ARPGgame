@echo off
setlocal
rem Keep this editor's cache writable without changing Windows account permissions.
set "LOCALAPPDATA=%~dp0..\.godot-local"
if not exist "%LOCALAPPDATA%\Godot" mkdir "%LOCALAPPDATA%\Godot"
start "" "D:\Simon\Programs\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe" --editor --path "%~dp0."
endlocal
