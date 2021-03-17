#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
./flakes/update.sh

nix flake update --commit-lock-file
