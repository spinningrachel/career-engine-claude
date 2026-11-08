#!/usr/bin/env python3
"""Read and upsert rows in the run-log workbook (.xlsx). Used by skills/run-records.

  xlsx_log.py headers <file>
      Print each sheet's header row as JSON: {"Sheet": ["col", ...], ...}
  xlsx_log.py init <file>
      Create the workbook with the default sheets and headers (no rows). Refuses to overwrite.
  xlsx_log.py upsert <file> <sheet> --key-cols "A,B" --row '{"A": "x", ...}' [--create-default]
      Update the row whose key columns match, else append one. Only columns
      that already exist in the header row are written; the rest are reported
      as "unmapped". Never adds, renames or deletes a column unless
      --create-default creates a missing workbook with the default headers.
"""
import argparse
import json
import os
import sys

try:
    import openpyxl
except ImportError:
    sys.exit("openpyxl is required: pip install openpyxl")

DEFAULT = {
    "Runs": ["Run", "Mode", "Started", "Ended", "Roles processed", "Roles flagged",
             "Summary", "Reports", "Session link", "Cleanup"],
    "Applications": ["Company", "Role", "Run", "Action", "Date", "Status", "Flag reason",
                     "CV file", "Cover letter file", "Tracker link", "Feedback report"],
}


def headers_of(ws):
    return [c.value for c in ws[1]] if ws.max_row >= 1 else []


def cmd_headers(path):
    wb = openpyxl.load_workbook(path)
    print(json.dumps({ws.title: [h for h in headers_of(ws) if h] for ws in wb}, indent=2))


def make_default(path):
    wb = openpyxl.Workbook()
    wb.remove(wb.active)
    for name, cols in DEFAULT.items():
        wb.create_sheet(name).append(cols)
    wb.save(path)


def cmd_init(path):
    if os.path.exists(path):
        sys.exit(f"already exists, not overwriting: {path}")
    make_default(path)
    print(json.dumps({"created": path}))


def cmd_upsert(path, sheet, key_cols, row, create_default):
    if not os.path.exists(path):
        if not create_default:
            sys.exit(f"workbook not found: {path} (pass --create-default to create it)")
        make_default(path)
    wb = openpyxl.load_workbook(path)
    if sheet not in wb.sheetnames:
        sys.exit(f"sheet not found: {sheet} (have: {wb.sheetnames})")
    ws = wb[sheet]
    heads = headers_of(ws)
    idx = {h: i for i, h in enumerate(heads) if h}
    missing_keys = [k for k in key_cols if k not in idx]
    if missing_keys:
        sys.exit(f"key columns not in header row: {missing_keys}")
    target = None
    for r in range(2, ws.max_row + 1):
        if all(str(ws.cell(r, idx[k] + 1).value or "") == str(row.get(k, "")) for k in key_cols):
            target = r
            break
    action = "updated"
    if target is None:
        target = ws.max_row + 1 if ws.max_row > 1 or ws.cell(2, 1).value else 2
        action = "created"
    unmapped = []
    for col, val in row.items():
        if col in idx:
            ws.cell(target, idx[col] + 1).value = val
        else:
            unmapped.append(col)
    wb.save(path)
    print(json.dumps({"action": action, "sheet": sheet, "row": target, "unmapped": unmapped}))


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    h = sub.add_parser("headers")
    h.add_argument("file")
    i = sub.add_parser("init")
    i.add_argument("file")
    u = sub.add_parser("upsert")
    u.add_argument("file")
    u.add_argument("sheet")
    u.add_argument("--key-cols", required=True)
    u.add_argument("--row", required=True)
    u.add_argument("--create-default", action="store_true")
    a = p.parse_args()
    if a.cmd == "headers":
        cmd_headers(a.file)
    elif a.cmd == "init":
        cmd_init(a.file)
    else:
        cmd_upsert(a.file, a.sheet, [k.strip() for k in a.key_cols.split(",")],
                   json.loads(a.row), a.create_default)


if __name__ == "__main__":
    main()
