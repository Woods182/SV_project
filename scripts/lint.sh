#!/usr/bin/env bash
set -uo pipefail

problem="${1:-01_async_fifo}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
problem_root="${repo_root}/problems/${problem}"

if [[ ! -d "${problem_root}" ]]; then
  echo "ERROR: problem directory not found: ${problem_root}" >&2
  exit 2
fi

mapfile -d '' sources < <(
  find "${problem_root}/rtl" "${problem_root}/tb" -maxdepth 1 -type f -name '*.sv' -print0
)
if (( ${#sources[@]} == 0 )); then
  echo "SKIP lint: no user-authored .sv files in ${problem}"
  exit 0
fi

if ! command -v verible-verilog-lint >/dev/null 2>&1; then
  echo "BLOCKED lint: verible-verilog-lint not found on Arous PATH" >&2
  exit 3
fi

verible-verilog-lint --rules_config_search "${sources[@]}"
