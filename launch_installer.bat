@echo off
REM --- GenAI Training Toolchain Installer Launcher ---
REM This script ensures Python is installed and then launches the Streamlit UI.

echo Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python not found. Please install Python first to use this installer.
    echo Or run setup\windows\install_tools.ps1 directly.
    pause
    exit /b 1
)

echo Checking Streamlit...
pip show streamlit >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Streamlit...
    pip install streamlit
)

echo Starting Installer UI...
streamlit run setup\installer_ui.py
pause
