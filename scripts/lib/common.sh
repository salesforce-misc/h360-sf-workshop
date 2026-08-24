#!/usr/bin/env bash
# Shared helpers for Headless 360 workshop scripts.
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; }
warn() { echo "WARN: $1"; }
org_arg() { local org="$1"; if [ -n "$org" ]; then echo "--target-org $org"; fi; }
# Resolve org alias from --org flag or .env ORG_ALIAS
resolve_org() {
  local org=""
  while [ $# -gt 0 ]; do case "$1" in --org) org="$2"; shift 2;; *) shift;; esac; done
  if [ -z "$org" ] && [ -f .env ]; then org="$(grep -E '^ORG_ALIAS=' .env | cut -d= -f2)"; fi
  echo "$org"
}
