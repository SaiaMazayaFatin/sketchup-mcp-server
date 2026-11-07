#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE="$ROOT/skills"

for target in "$ROOT/.github/skills" "$ROOT/.claude/skills" "$ROOT/.agents/skills"; do
  mkdir -p "$target"
  for skill in "$SOURCE"/*; do
    name=$(basename "$skill")
    rm -rf "$target/$name"
    cp -R "$skill" "$target/$name"
  done
done

printf '%s\n' 'Synchronized Skills to .github, .claude, and .agents'
