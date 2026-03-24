#!/bin/bash
# =============================================================================
# split_individuals.sh
# =============================================================================
# Splits a multi-individual .sim file into per-individual files.
# Each output file contains the position column and one individual's genotypes.
#
# Usage:
#   ./split_individuals.sh <input_sim_file> <output_dir>
#
# Arguments:
#   input_sim_file   Path to .sim file (e.g., data/sim_files/c20_m10_r1_h5_au1_hc0.1.sim)
#   output_dir       Directory for per-individual files
#
# Output:
#   <output_dir>/<sim_filename>_i1, _i2, ..., _i10000
#
# Example:
#   ./split_individuals.sh ../data/sim_files/c20_m10_r50_h5_au1_hc0.1.sim ./individuals/
# =============================================================================

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <input_sim_file> <output_dir>"
    exit 1
fi

input_sim_file="$1"
output_dir="$2"

if [[ ! -f "${input_sim_file}" ]]; then
    echo "Error: File '${input_sim_file}' not found."
    exit 1
fi

mkdir -p "${output_dir}"

sim_basename=$(basename "${input_sim_file}")

n_col=$(head -1 "${input_sim_file}" | awk '{print NF}')
n_indv=$((n_col - 1))

echo "Input:       ${input_sim_file}"
echo "Individuals: ${n_indv}"
echo "Output dir:  ${output_dir}"
echo ""

for (( i=2; i<=n_col; i++ )); do
    index_indv=$(( i - 1 ))
    out_filename="${output_dir}/${sim_basename}_i${index_indv}"
    awk -v j=${i} '{print $1, $j}' "${input_sim_file}" > "${out_filename}"
done

echo "Done. Created ${n_indv} individual files."
