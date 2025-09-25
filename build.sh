#!/usr/bin/env bash
# build.sh — Build rotatepdf.exe from rotatepdf.py on Windows using Git Bash.
# Options:
#   --clean        Remove build/ dist/ and .venv before building
#   --sendto       Create "Rotate PDF CCW/CW" shortcuts in the Windows SendTo menu
#   --name NAME    Name of the output exe (default: rotatepdf)
# Usage:
#   bash build.sh
#   bash build.sh --clean --sendto
#   bash build.sh --name rotatepdf-win

set -euo pipefail

EXE_NAME="rotatepdf"
DO_CLEAN="no"
DO_SENDTO="no"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean)   DO_CLEAN="yes"; shift ;;
    --sendto)  DO_SENDTO="yes"; shift ;;
    --name)    EXE_NAME="${2:-rotatepdf}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

have() { command -v "$1" >/dev/null 2>&1; }

# Prefer Windows Python launcher if present
if have py; then PYLAUNCH="py"; else PYLAUNCH="python"; fi

# Ensure we’re in the repo root
if [[ ! -f "rotatepdf.py" ]]; then
  echo "ERROR: rotatepdf.py not found in current directory." >&2
  exit 1
fi

# Clean
if [[ "$DO_CLEAN" == "yes" ]]; then
  echo "Cleaning build artifacts and venv..."
  rm -rf build dist .venv
fi

# venv
if [[ ! -d ".venv" ]]; then
  echo "Creating virtual environment..."
  "$PYLAUNCH" -m venv .venv
fi

# Activate venv (Git Bash)
# shellcheck source=/dev/null
source .venv/Scripts/activate

# Use the venv python explicitly for pip operations (Windows needs -m pip)
VENV_PY="$(pwd -W)\\\.venv\\Scripts\\python.exe"
# Fallback if pwd -W not available (older Git Bash)
if [[ ! -f "$VENV_PY" ]]; then
  VENV_PY=".venv/Scripts/python.exe"
fi

# Dependencies
if [[ -f "requirements.txt" ]]; then
  echo "Installing from requirements.txt..."
  "$VENV_PY" -m pip install --upgrade pip
  "$VENV_PY" -m pip install -r requirements.txt
else
  echo "Installing dependencies (pinned)..."
  "$VENV_PY" -m pip install --upgrade pip
  "$VENV_PY" -m pip install "pypdf>=4,<6" "pyperclip>=1.8,<2" pyinstaller
fi

# Build
echo "Building single-file exe with PyInstaller..."
pyinstaller --onefile --name "$EXE_NAME" rotatepdf.py

EXE_PATH_UNIX="dist/${EXE_NAME}.exe"
if [[ ! -f "$EXE_PATH_UNIX" ]]; then
  echo "ERROR: build failed; ${EXE_PATH_UNIX} not found." >&2
  exit 1
fi

REPO_WIN_PATH="$(pwd -W)"
EXE_PATH_WIN="${REPO_WIN_PATH}\\dist\\${EXE_NAME}.exe"

echo "Built: ${EXE_PATH_UNIX}"
echo "Windows path: ${EXE_PATH_WIN}"

# Optional SendTo shortcuts
if [[ "$DO_SENDTO" == "yes" ]]; then
  if ! have powershell.exe; then
    echo "WARNING: PowerShell not found; skipping SendTo shortcuts." >&2
  else
    echo "Creating SendTo shortcuts..."
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
      \$shell = New-Object -ComObject WScript.Shell;
      \$sendTo = Join-Path \$env:APPDATA 'Microsoft\\Windows\\SendTo';

      \$lnk1 = \$shell.CreateShortcut((Join-Path \$sendTo 'Rotate PDF CCW.lnk'));
      \$lnk1.TargetPath = '${EXE_PATH_WIN}';
      \$lnk1.Arguments  = '--inplace ccw';
      \$lnk1.WorkingDirectory = '${REPO_WIN_PATH}';
      \$lnk1.IconLocation = '${EXE_PATH_WIN},0';
      \$lnk1.Save();

      \$lnk2 = \$shell.CreateShortcut((Join-Path \$sendTo 'Rotate PDF CW.lnk'));
      \$lnk2.TargetPath = '${EXE_PATH_WIN}';
      \$lnk2.Arguments  = '--inplace cw';
      \$lnk2.WorkingDirectory = '${REPO_WIN_PATH}';
      \$lnk2.IconLocation = '${EXE_PATH_WIN},0';
      \$lnk2.Save();
    "
    echo "SendTo shortcuts created:"
    echo "  • Rotate PDF CCW"
    echo "  • Rotate PDF CW"
  fi
fi

echo "Done."

