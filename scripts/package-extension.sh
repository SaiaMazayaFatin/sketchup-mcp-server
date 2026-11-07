#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUTPUT_DIRECTORY="$ROOT/dist"
OUTPUT="$OUTPUT_DIRECTORY/sketchup-mcp-0.1.0.rbz"

mkdir -p "$OUTPUT_DIRECTORY"
rm -f "$OUTPUT"
(
  cd "$ROOT/sketchup-extension"
  zip -q -r "$OUTPUT" sketchup_mcp.rb sketchup_mcp
)
printf '%s\n' "$OUTPUT"
