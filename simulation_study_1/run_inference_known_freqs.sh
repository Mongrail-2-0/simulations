#!/bin/bash
# =============================================================================
# run_inference_known_freqs.sh
# =============================================================================
# Runs the original Mongrail using known population haplotype frequencies
# (.popA / .popB). This produces the baseline output that Mongrail 2.0 is
# compared against in Study 1.
#
# Usage:
#   ./run_inference_known_freqs.sh <recom_freq> <n_hap> <n_replicate> <threads> \
#       <mongrail_bin> <chrom_dir> <pop_dir> <indv_dir> <output_dir>
#
# Arguments:
#   recom_freq     Recombination frequency (1 or 50)
#   n_hap          Number of haplotypes (5 or 15)
#   n_replicate    Number of individuals (e.g., 10000)
#   threads        Number of parallel jobs (e.g., 100)
#   mongrail_bin   Path to original mongrail executable
#   chrom_dir      Directory containing .chrom files
#   pop_dir        Directory containing .popA / .popB files
#   indv_dir       Directory containing per-individual .sim files
#   output_dir     Directory for output files
#
# Output:
#   Combined: <output_dir>/<sim_params>.out
#
# Example:
#   ./run_inference_known_freqs.sh 50 5 10000 100 \
#       ../src/mongrail/mongrail \
#       ../data/chrom_files \
#       ../data/pop_files \
#       ./individuals/ \
#       ./results/
# =============================================================================

set -euo pipefail

if [[ $# -lt 9 ]]; then
    echo "Usage: $0 <recom_freq> <n_hap> <n_replicate> <threads> \\"
    echo "          <mongrail_bin> <chrom_dir> <pop_dir> <indv_dir> <output_dir>"
    exit 1
fi

recom_freq=$1
n_hap=$2
n_replicate=$3
threads=$4
mongrail_bin=$5
chrom_dir=$6
pop_dir=$7
indv_dir=$8
output_dir=$9

# Derived filenames
chrom_filename="c20_m10_r${recom_freq}.chrom"
pop_parameters="c20_m10_h${n_hap}_au1_hc0.1"
sim_parameters="c20_m10_r${recom_freq}_h${n_hap}_au1_hc0.1"

mkdir -p "${output_dir}"

echo "============================================================"
echo "  Mongrail Inference (Known Frequencies)"
echo "============================================================"
echo "  Chrom file:    ${chrom_filename}"
echo "  Pop params:    ${pop_parameters}"
echo "  Sim params:    ${sim_parameters}"
echo "  Replicates:    ${n_replicate}"
echo "  Threads:       ${threads}"
echo "============================================================"
echo ""

# Run inference in parallel batches
a=$(seq 1 ${threads} ${n_replicate})

for i in ${a}; do
    c=0
    while [[ $c -lt ${threads} ]] && [[ $i -le ${n_replicate} ]]; do
        sim_filename="${sim_parameters}.sim_i${i}"
        out_filename="${sim_parameters}.out_i${i}"

        ${mongrail_bin} \
            -c "${chrom_dir}/${chrom_filename}" \
            -A "${pop_dir}/${pop_parameters}.popA" \
            -B "${pop_dir}/${pop_parameters}.popB" \
            -i "${indv_dir}/${sim_filename}" \
            -o "${output_dir}/${out_filename}" &

        c=$(( c + 1 ))
        i=$(( i + 1 ))
    done
    wait
    echo "  ${i} / ${n_replicate} completed"
done

# Concatenate results
final_output="${output_dir}/${sim_parameters}.out"
echo ""
echo "Concatenating into ${final_output}..."

for rep in $(seq 1 ${n_replicate}); do
    rep_out="${output_dir}/${sim_parameters}.out_i${rep}"

    if [[ ${rep} -eq 1 ]]; then
        cat "${rep_out}" > "${final_output}"
    else
        sed -n '2p' "${rep_out}" >> "${final_output}"
    fi
done

# Remove per-individual temp files now that they are concatenated into the
# combined output. (On a failed run, set -e exits before here, so the temps
# are left in place for debugging.)
rm -f "${output_dir}/${sim_parameters}.out_i"*

echo "Done. Final output: ${final_output}"
