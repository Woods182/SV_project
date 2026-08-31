#!/usr/bin/env bash
set -uo pipefail

problem="${1:-01_async_fifo}"
top="${2:-tb}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
problem_root="${repo_root}/problems/${problem}"

if [[ ! -d "${problem_root}" ]]; then
  echo "ERROR: problem directory not found: ${problem_root}" >&2
  exit 2
fi

mapfile -d '' rtl < <(find "${problem_root}/rtl" -maxdepth 1 -type f -name '*.sv' -print0)
mapfile -d '' tb < <(find "${problem_root}/tb" -maxdepth 1 -type f -name '*.sv' -print0)
if (( ${#rtl[@]} == 0 || ${#tb[@]} == 0 )); then
  echo "SKIP sim: ${problem} needs at least one user RTL .sv and one user TB .sv"
  exit 0
fi

if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "BLOCKED sim: iverilog or vvp not found on Arous PATH" >&2
  exit 3
fi

build_dir="${repo_root}/work/sim/${problem}"
mkdir -p -- "${build_dir}"
out="${build_dir}/sim.vvp"

iverilog -g2012 -Wall -s "${top}" -o "${out}" "${rtl[@]}" "${tb[@]}"
vvp "${out}"
