#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
exec python3 -m unittest discover -s tests -t . -v
