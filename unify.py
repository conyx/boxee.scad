#!/usr/bin/env python3
"""Generate a single-file boxee.scad from main.scad.

Inlines all local include files (non-BOSL2) at the /* [Hidden] */ marker,
making the output self-contained for sharing on [MakerWorld/Thingvers/Printables]
platforms.

With --remove-preview, additionally strips all $preview usage from the unified
output, for web customizers (e.g. MakerWorld) that ignore $preview mode.
"""

import argparse
import datetime
import re
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_NAME = "[boxee.scad] Parametric storage box created in OpenSCAD"
PROJECT_COPYRIGHT = "Copyright © 2026 by Conyx"
PROJECT_URL = "https://github.com/conyx/boxee.scad"
PROJECT_LICENCE = "CC BY-SA 4.0"
PROJECT_LICENCE_URL = "https://creativecommons.org/licenses/by-sa/4.0"

INCLUDE_RE = re.compile(r"^include\s*<([^>]+)>")
HIDDEN_MARKER = "/* [Hidden] */"


def git_short_commit():
    if not shutil.which("git") or not Path(".git").exists():
        return None
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
    except subprocess.CalledProcessError:
        return None
    return out or None


def header(preview_removed=False):
    timestamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    lines = [
        f"// {PROJECT_NAME}",
        f"// {PROJECT_COPYRIGHT}",
        f"// Project repository: {PROJECT_URL}",
        f"// Licence: {PROJECT_LICENCE} ({PROJECT_LICENCE_URL})",
        f"// Generated: {timestamp}",
    ]
    commit = git_short_commit()
    if commit:
        lines.append(f"// Commit: {commit}")
    if preview_removed:
        lines.append("// Note: $preview mode was removed from this code because web customizers ignore it")
    lines.append("")
    return lines


def inline(source):
    deferred = []
    body = []
    for line in source.read_text().splitlines():
        match = INCLUDE_RE.match(line)
        if match and not match.group(1).startswith("BOSL2/"):
            deferred.append(source.parent / match.group(1))
            continue
        body.append(line)
        if HIDDEN_MARKER in line:
            body.append("")
            for path in deferred:
                body.extend(path.read_text().splitlines())
                body.append("")
    return body


def remove_preview(lines):
    text = "\n".join(lines)
    replacements = [
        # Drop the model_detail_preview parameter together with its comment above.
        (r"(?m)^//[^\n]*\n^model_detail_preview\s*=[^\n]*\n\n?", ""),
        # The render detail now drives the customizer preview too, so lower it a bit.
        (r"(?m)^(model_detail_render\s*=\s*)[0-9.]+", r"\g<1>0.75"),
        # The $preview self-assignment workaround is pointless once nothing reads it.
        (r"(?m)^\$preview\s*=\s*\$preview\s*;[^\n]*\n\n?", ""),
        (re.escape("generate_summary_plate && $preview"), "generate_summary_plate"),
        (
            re.escape("$preview ? model_detail_preview : model_detail_render"),
            "model_detail_render",
        ),
    ]
    for pattern, replacement in replacements:
        text, count = re.subn(pattern, replacement, text)
        if count != 1:
            sys.exit(f"unify.py: expected exactly 1 match for {pattern!r}, found {count}")
    for marker in ("$preview", "model_detail_preview"):
        if marker in text:
            sys.exit(f"unify.py: '{marker}' still present after --remove-preview")
    return text.splitlines()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="entry .scad file (main.scad)")
    parser.add_argument(
        "--remove-preview",
        action="store_true",
        help="strip $preview support for web customizers that ignore it",
    )
    args = parser.parse_args()
    body = inline(args.source)
    if args.remove_preview:
        body = remove_preview(body)
    sys.stdout.write("\n".join(header(args.remove_preview) + body) + "\n")


if __name__ == "__main__":
    main()
