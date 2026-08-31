#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
ran=0
failed=0
total=0

for filelist in "${repo_root}"/filelists/[0-9][0-9]_*.f; do
  ((total += 1))
  problem="$(basename -- "${filelist}" .f)"
  source_count="$(sed '/^[[:space:]]*\($\|#\|\/\/\)/d' "${filelist}" | wc -l)"
  if [[ "${source_count}" == 0 ]]; then
    echo "SKIP ${problem}: empty filelist"
    continue
  fi

  ((ran += 1))
  if ! make -C "${repo_root}" lint PROBLEM="${problem}"; then
    ((failed += 1))
    continue
  fi
  if ! make -C "${repo_root}" run PROBLEM="${problem}"; then
    ((failed += 1))
  fi
done

echo "Regression summary: ran=${ran} failed=${failed} total=${total}"
(( failed == 0 ))
