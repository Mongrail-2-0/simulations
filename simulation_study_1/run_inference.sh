#!/bin/bash
# =============================================================================
# run_inference.sh
# =============================================================================
# Runs mongrail2 inference on each simulated individual in parallel batches,
# then concatenates all per-individual outputs into a single results file.
#
# Usage:
#   ./run_inference.sh <recom_freq> <n_hap> <sample_size> <n_replicate> <threads> \
#                      <mongrail2_bin> <chrom_dir> <panel_dir> <indv_dir> <output_dir>
#
# Arguments:
#   recom_freq      Recombination frequency (1 or 50)
#   n_hap           Number of haplotypes (5 or 15)
#   sample_size     Reference panel sample size used (10, 100, or 1000)
#   n_replicate     Number of replicates/individuals (e.g., 10000)
#   threads         Number of parallel jobs (e.g., 100)
#   mongrail2_bin   Path to mongrail2 executable
#   chrom_dir       Directory containing .chrom files
#   panel_dir       Directory containing .countA / .countB files
#   indv_dir        Directory containing per-individual .sim files
#   output_dir      Directory for output files
#
# Output:
#   Per-individual: <output_dir>/<sim_params>.m2out_i{1..n_replicate}
#   Combined:       <output_dir>/<sim_params>.m2out_N<sample_size>
#
# Example:
#   ./run_inference.sh 50 5 10 10000 100 \
#       ../src/mongrail2/mongrail2 \
#       ../data/chrom_files \
#       ./panels/ \
#       ./individuals/ \
#       ./results/
# =============================================================================

set -euo pipefail

if [[ $# -lt 10 ]]; then
    echo "Usage: $0 <recom_freq> <n_hap> <sample_size> <n_replicate> <threads> \\"
    echo "          <mongrail2_bin> <chrom_dir> <panel_dir> <indv_dir> <output_dir>"
    exit 1
fi

recom_freq=$1
n_hap=$2
sample_size=$3
n_replicate=$4
threads=$5
mongrail2_bin=$6
chrom_dir=$7
panel_dir=$8
indv_dir=$9
output_dir=${10}

# --- Derived filenames ---
chrom_filename="c20_m10_r${recom_freq}.chrom"
pop_parameters="c20_m10_h${n_hap}_au1_hc0.1"
sim_parameters="c20_m10_r${recom_freq}_h${n_hap}_au1_hc0.1"

mkdir -p "${output_dir}"

echo "============================================================"
echo "  Mongrail 2.0 Inference"
echo "============================================================"
echo "  Chrom file:    ${chrom_filename}"
echo "  Pop params:    ${pop_parameters}"
echo "  Sim params:    ${sim_parameters}"
echo "  Sample size:   N=${sample_size}"
echo "  Replicates:    ${n_replicate}"
echo "  Threads:       ${threads}"
echo "============================================================"
echo ""

# --- Run inference in parallel batches ---
a=$(seq 1 ${threads} ${n_replicate})

for i in ${a}; do
    c=0
    while [[ $c -lt ${threads} ]] && [[ $i -le ${n_replicate} ]]; do
        sim_filename="${sim_parameters}.sim_i${i}"
        A_filename="${pop_parameters}.countA_rep${i}"
        B_filename="${pop_parameters}.countB_rep${i}"
        out_filename="${sim_parameters}.m2out_i${i}"

        ${mongrail2_bin} \
            -c "${chrom_dir}/${chrom_filename}" \
            -A "${panel_dir}/${A_filename}" \
            -B "${panel_dir}/${B_filename}" \
            -i "${indv_dir}/${sim_filename}" \
            -o "${output_dir}/${out_filename}" &

        c=$(( c + 1 ))
        i=$(( i + 1 ))
    done
    wait
    echo "  ${i} / ${n_replicate} completed"
done

# --- Concatenate results ---
final_output="${output_dir}/${sim_parameters}.m2out_N${sample_size}"
echo ""
echo "Concatenating into ${final_output}..."

for rep in $(seq 1 ${n_replicate}); do
    rep_out="${output_dir}/${sim_parameters}.m2out_i${rep}"

    if [[ ${rep} -eq 1 ]]; then
        cat "${rep_out}" > "${final_output}"
    else
        sed -n '2p' "${rep_out}" >> "${final_output}"
    fi
done

# Remove per-individual temp files now that they are concatenated into the
# combined output. (On a failed run, set -e exits before here, so the temps
# are left in place for debugging.)
rm -f "${output_dir}/${sim_parameters}.m2out_i"*

echo "Done. Final output: ${final_output}"
