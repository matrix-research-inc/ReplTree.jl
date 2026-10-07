#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export JULIA_DEPOT_PATH="${PROJECT_ROOT}/.julia"
export HOME="${PROJECT_ROOT}"

exec julia --project="${PROJECT_ROOT}" "$@"
