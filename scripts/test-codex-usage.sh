#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-usage-tests.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

swiftc \
    "$ROOT_DIR/Widgets/CodexUsage/CodexUsagePercent.swift" \
    "$ROOT_DIR/Tests/CodexUsagePercentTests.swift" \
    -o "$TEST_DIR/CodexUsagePercentTests"

"$TEST_DIR/CodexUsagePercentTests"
