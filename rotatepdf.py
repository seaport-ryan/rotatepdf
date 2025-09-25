#!/usr/bin/env python3
"""
rotatepdf.py — Rotate every page in PDFs 90° CCW or CW.

Examples:
  rotatepdf.exe ccw "C:\path\file.pdf"
  rotatepdf.exe cw --inplace "C:\path\file.pdf"
  (or) Copy one or more full PDF paths to the clipboard (one per line), then:
  rotatepdf.exe ccw
"""

import argparse
import sys
from pathlib import Path
import tempfile
import shutil

def _maybe_import_pyperclip():
    try:
        import pyperclip
        return pyperclip
    except Exception:
        return None

def collect_input_paths(cli_paths, use_clipboard_default=True):
    paths = [Path(p.strip().strip('"')) for p in cli_paths if p.strip()]
    if not paths and use_clipboard_default:
        pyperclip = _maybe_import_pyperclip()
        if pyperclip:
            text = (pyperclip.paste() or "").strip()
            if text:
                candidates = [s.strip().strip('"') for s in text.replace("\r", "\n").split("\n") if s.strip()]
                paths = [Path(c) for c in candidates]
    paths = [p for p in paths if p.exists() and p.suffix.lower() == ".pdf"]
    return paths

def rotate_file(pdf_path: Path, direction: str, inplace: bool = False):
    # direction: "ccw" or "cw"
    from pypdf import PdfReader, PdfWriter

    try:
        reader = PdfReader(str(pdf_path))
        if getattr(reader, "is_encrypted", False):
            try:
                reader.decrypt("")
            except Exception:
                pass

        writer = PdfWriter()

        # pypdf positive degrees = clockwise; 270° CW == 90° CCW
        degrees = 270 if direction == "ccw" else 90

        for page in reader.pages:
            page.rotate(degrees)
            writer.add_page(page)

        try:
            if reader.metadata:
                writer.add_metadata(reader.metadata)
        except Exception:
            pass

        if inplace:
            with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf", dir=str(pdf_path.parent)) as tmp:
                writer.write(tmp)
            shutil.move(tmp.name, str(pdf_path))
            return pdf_path
        else:
            suffix = f"_rotated_{direction}.pdf"
            out_path = pdf_path.with_name(f"{pdf_path.stem}{suffix}")
            with open(out_path, "wb") as f:
                writer.write(f)
            return out_path

    except Exception as e:
        print(f"[ERROR] Failed to rotate '{pdf_path}': {e}", file=sys.stderr)
        return None

def main():
    parser = argparse.ArgumentParser(description="Rotate all pages in PDFs 90° CCW or CW.")
    parser.add_argument("direction", choices=["ccw", "cw"], help="Rotation direction: ccw or cw.")
    parser.add_argument("paths", nargs="*", help="PDF file paths. If omitted, app reads clipboard.")
    parser.add_argument("-i", "--inplace", action="store_true", help="Overwrite original PDF (safe replace).")
    args = parser.parse_args()

    inputs = collect_input_paths(args.paths, use_clipboard_default=True)
    if not inputs:
        print("No valid PDF paths provided (CLI or clipboard).")
        print("Tip: Right-click a PDF → Copy as path, then run this app.")
        sys.exit(2)

    any_failed = False
    for p in inputs:
        result = rotate_file(p, direction=args.direction, inplace=args.inplace)
        if result:
            action = "overwritten" if args.inplace else "created"
            print(f"[OK] {action}: {result}")
        else:
            any_failed = True

    sys.exit(1 if any_failed else 0)

if __name__ == "__main__":
    main()

