# rotatepdf

One‑click Windows tool to rotate **all pages** in a PDF either **90° counter‑clockwise (ccw)** or **90° clockwise (cw)**.  
Works with command‑line **or** by grabbing file paths from your **clipboard**.

## Features
- Rotate every page **ccw** or **cw**
- Accepts file paths from **CLI**, **drag & drop**, or **clipboard**
- Optional `--inplace` safe overwrite (temp‑file then replace)
- Preserves PDF metadata when possible
- Handles multiple PDFs in one go

## Quick Start (build your exe & create Send To shortcuts)
```Bash
./build.sh --clean --sendto
