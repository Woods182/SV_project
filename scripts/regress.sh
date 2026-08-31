#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
ran=0
failed=0
total=0

while IFS= read -r -d '' problem_dir; do
  ((total += 1))
  problem="$(basename -- "${problem_dir}")"
  rtl_count="$(find "${problem_dir}/rtl" -maxdepth 1 -type f -name '*.sv' -print -quit | wc -l)"
  tb_count="$(find "${problem_dir}/tb" -maxdepth 1 -type f -name '*.sv' -print -quit | wc -l)"
  if [[ "${rtl_count}" == 0 || "${tb_count}" == 0 ]]; then
    echo "SKIP ${problem}: no complete user RTL+TB pair"
    continue
  fi

  ((ran += 1))
  if ! "${script_dir}/lint.sh" "${problem}"; then
    ((failed += 1))
    continue
  fi
  if ! "${script_dir}/sim.sh" "${problem}"; then
    ((failed += 1))
  fi
done < <(find "${repo_root}/problems" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

echo "Regression summary: ran=${ran} failed=${failed} total=${total}"
(( failed == 0 ))
