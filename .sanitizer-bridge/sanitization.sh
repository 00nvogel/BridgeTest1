#!/usr/bin/env bash
set -euo pipefail
# The engine always protects .sanitizer-bridge and .github in embedded mode.
# Add project-specific whole-file exclusions here. cwd is this script's directory.
rm -rf -- "$1/private" "$1/customer-private"
