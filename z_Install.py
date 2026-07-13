#!/usr/bin/env python3
"""
Install the Zibo-only VNAV descent table hooks into B738.a_fms.lua.

The installer intentionally works on bytes for the target Lua file so it can
preserve the user's existing LF or CRLF line endings. This avoids depending on
external diff tools and avoids Python text-mode newline conversion.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path


LUA_FILE = Path("B738.a_fms.lua")
BACKUP_FILE = Path("B738.a_fms.backup")
TABLE_FILE = Path("B738.a_fms_zibo_tables.lua")
DOFILE_FRAGMENT = Path("Add_dofile.txt")
TABLE_FILE_ALT_DIST = Path("Add_to_take_alt_dist.txt")
TABLE_FILE_ALT_DIST_MACH = Path("Add_to_take_alt_dist_mach.txt")
DOFILE_LINE = 'dofile("B738.a_fms_zibo_tables.lua")'
ALT_DIST_FUNC = "function take_alt_dist(x_idx_alt, x_spd_alt, x_spd_wnd_alt, x_flap)"
ALT_DIST_MACH_FUNC = "function take_alt_dist_mach(x_idx_alt, x_spd_alt, x_spd_wnd_alt)"
ALT_DIST_MARKER = "pcall(B738_variant_test_take_alt_dist,"
ALT_DIST_MACH_MARKER = "pcall(B738_variant_test_take_alt_dist_mach,"
DOFILE_BEGIN = "-- BEGIN ZIBO_VNAV_DESCENT_TABLES DOFILE"
DOFILE_END = "-- END ZIBO_VNAV_DESCENT_TABLES DOFILE"
ALT_DIST_BEGIN = "-- BEGIN ZIBO_VNAV_DESCENT_TABLES KIAS"
ALT_DIST_END = "-- END ZIBO_VNAV_DESCENT_TABLES KIAS"
ALT_DIST_MACH_BEGIN = "-- BEGIN ZIBO_VNAV_DESCENT_TABLES MACH"
ALT_DIST_MACH_END = "-- END ZIBO_VNAV_DESCENT_TABLES MACH"


def is_commented(line: str) -> bool:
    return line.lstrip().startswith("--")


def detect_eol(data: bytes) -> str:
    crlf_count = data.count(b"\r\n")
    lf_only_count = data.count(b"\n") - crlf_count
    return "\r\n" if crlf_count > lf_only_count else "\n"


def split_lines(data: bytes) -> tuple[list[str], str, bool]:
    eol = detect_eol(data)
    has_final_eol = data.endswith(b"\n") or data.endswith(b"\r")
    text = data.decode("utf-8", errors="strict")
    lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    if has_final_eol and lines and lines[-1] == "":
        lines = lines[:-1]
    return lines, eol, has_final_eol


def read_logical_lines(path: Path) -> list[str]:
    data = path.read_bytes()
    lines, _, _ = split_lines(data)
    return lines


def write_lines_preserving_eol(path: Path, lines: list[str], eol: str, has_final_eol: bool) -> None:
    payload = eol.join(lines)
    if has_final_eol:
        payload += eol
    path.write_bytes(payload.encode("utf-8"))


def find_non_commented_line(lines: list[str], search_text: str) -> int:
    for i, line in enumerate(lines):
        if search_text in line and not is_commented(line):
            return i
    return -1


def has_non_commented_line(lines: list[str], search_text: str) -> bool:
    return find_non_commented_line(lines, search_text) >= 0


def require_file(path: Path) -> None:
    if not path.exists():
        print(f"ERROR: {path} not found. Run this script from the B738.a_fms script folder.", file=sys.stderr)
        raise SystemExit(2)


def add_insertion(
    lines: list[str],
    insertions: list[tuple[int, list[str]]],
    search_text: str,
    content: list[str],
    label: str,
) -> None:
    idx = find_non_commented_line(lines, search_text)
    if idx < 0:
        print(f"ERROR: Could not find a non-commented line matching:\n  {search_text}", file=sys.stderr)
        raise SystemExit(1)
    insertions.append((idx + 1, content))
    print(f"{label}: found line {idx + 1}, will insert {len(content)} line(s).")


def find_line(lines: list[str], search_text: str) -> int:
    for i, line in enumerate(lines):
        if search_text in line:
            return i
    return -1


def add_replacement(
    replacements: list[tuple[int, int, list[str]]],
    start: int,
    end_exclusive: int,
    content: list[str],
    label: str,
) -> None:
    replacements.append((start, end_exclusive, content))
    old_len = end_exclusive - start
    print(f"{label}: will replace {old_len} line(s) at line {start + 1}.")


def add_replacement_if_changed(
    lines: list[str],
    replacements: list[tuple[int, int, list[str]]],
    start: int,
    end_exclusive: int,
    content: list[str],
    label: str,
) -> None:
    if lines[start:end_exclusive] == content:
        print(f"{label}: marked block already current.")
        return
    add_replacement(replacements, start, end_exclusive, content, label)


def find_marked_block(lines: list[str], begin_marker: str, end_marker: str) -> tuple[int, int] | None:
    begin = find_line(lines, begin_marker)
    if begin < 0:
        return None
    for end in range(begin + 1, len(lines)):
        if end_marker in lines[end]:
            return begin, end + 1
    print(f"ERROR: Found {begin_marker!r} without matching {end_marker!r}.", file=sys.stderr)
    raise SystemExit(1)


def find_legacy_hook_block(lines: list[str], marker: str) -> tuple[int, int] | None:
    start = find_non_commented_line(lines, marker)
    if start < 0:
        return None
    for end in range(start + 1, min(start + 8, len(lines))):
        if lines[end].strip() == "end":
            return start, end + 1
    print(f"ERROR: Found legacy hook marker {marker!r}, but could not find the hook block end.", file=sys.stderr)
    raise SystemExit(1)


def schedule_block_update(
    lines: list[str],
    insertions: list[tuple[int, list[str]]],
    replacements: list[tuple[int, int, list[str]]],
    begin_marker: str,
    end_marker: str,
    legacy_marker: str | None,
    anchor_text: str,
    content: list[str],
    label: str,
) -> None:
    marked = find_marked_block(lines, begin_marker, end_marker)
    if marked is not None:
        add_replacement_if_changed(lines, replacements, marked[0], marked[1], content, label)
        return

    if legacy_marker is not None:
        legacy = find_legacy_hook_block(lines, legacy_marker)
        if legacy is not None:
            add_replacement(replacements, legacy[0], legacy[1], content, f"{label} legacy migration")
            return

    add_insertion(lines, insertions, anchor_text, content, label)


def schedule_dofile_update(
    lines: list[str],
    insertions: list[tuple[int, list[str]]],
    replacements: list[tuple[int, int, list[str]]],
    content: list[str],
) -> None:
    marked = find_marked_block(lines, DOFILE_BEGIN, DOFILE_END)
    if marked is not None:
        add_replacement_if_changed(lines, replacements, marked[0], marked[1], content, "dofile hook")
        return

    legacy_idx = find_non_commented_line(lines, DOFILE_LINE)
    if legacy_idx >= 0:
        add_replacement(replacements, legacy_idx, legacy_idx + 1, content, "dofile hook legacy migration")
        return

    add_insertion(lines, insertions, "jit.off()", content, "dofile hook")


def main() -> int:
    for path in (LUA_FILE, TABLE_FILE, DOFILE_FRAGMENT, TABLE_FILE_ALT_DIST, TABLE_FILE_ALT_DIST_MACH):
        require_file(path)

    original_data = LUA_FILE.read_bytes()
    lua_lines, eol, has_final_eol = split_lines(original_data)
    dofile_content = read_logical_lines(DOFILE_FRAGMENT)
    alt_dist_content = read_logical_lines(TABLE_FILE_ALT_DIST)
    alt_dist_mach_content = read_logical_lines(TABLE_FILE_ALT_DIST_MACH)

    insertions: list[tuple[int, list[str]]] = []
    replacements: list[tuple[int, int, list[str]]] = []

    schedule_dofile_update(lua_lines, insertions, replacements, dofile_content)
    schedule_block_update(
        lua_lines,
        insertions,
        replacements,
        ALT_DIST_BEGIN,
        ALT_DIST_END,
        ALT_DIST_MARKER,
        ALT_DIST_FUNC,
        alt_dist_content,
        "take_alt_dist hook",
    )
    schedule_block_update(
        lua_lines,
        insertions,
        replacements,
        ALT_DIST_MACH_BEGIN,
        ALT_DIST_MACH_END,
        ALT_DIST_MACH_MARKER,
        ALT_DIST_MACH_FUNC,
        alt_dist_mach_content,
        "take_alt_dist_mach hook",
    )

    if not insertions and not replacements:
        print("Already installed; no changes made.")
        return 0

    if not BACKUP_FILE.exists():
        shutil.copy2(LUA_FILE, BACKUP_FILE)
        print(f"Backup created: {BACKUP_FILE}")
    else:
        print(f"Backup already exists, not overwritten: {BACKUP_FILE}")

    for start, end_exclusive, content in sorted(replacements, key=lambda item: item[0], reverse=True):
        lua_lines[start:end_exclusive] = content

    for insert_at, content in sorted(insertions, key=lambda item: item[0], reverse=True):
        lua_lines[insert_at:insert_at] = content

    write_lines_preserving_eol(LUA_FILE, lua_lines, eol, has_final_eol)
    print(f"Installed or updated {len(insertions) + len(replacements)} hook block(s) in {LUA_FILE}.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
