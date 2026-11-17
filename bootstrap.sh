#!/usr/bin/env bash
# First command to run on a new machine, and safe to run again at any time.
# Clones every repo in repos.conf that is missing, links shared skills and
# agents into ~/.claude, then checks the setup. See docs/05-workflows.md.
exec "$(cd "$(dirname "$0")" && pwd)/bin/ws" bootstrap "$@"
