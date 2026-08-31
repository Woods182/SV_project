#!/usr/bin/env bash
set -uo pipefail

problem="${1:-01_async_fifo}"
top="${2:-tb_async_fifo}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

exec make -C "${repo_root}" run PROBLEM="${problem}" TOPMODULE="${top}"
