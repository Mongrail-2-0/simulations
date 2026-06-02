#!/bin/bash
# =============================================================================
# run_inference_plugin.sh
# =============================================================================
# Runs the original Mongrail on posterior mean haplotype frequency files,
# then concatenates results. This is the "plug-in" approach: estimate
# frequencies first, then treat them as known.
#
# Usage:
#   ./run_inference_plugin.sh <recom_freq> <n_hap> <sample_size> <n_replicate> \
#       <threads> <mongrail_bin> <chrom_dir> <postmean_dir> <sim_dir> <output_dir>
#
# Arguments:
#   recom_freq     Recombination frequency (1 or 50)
#   n_hap          Number of haplotypes (5 or 15)
#   sample_size    Reference panel sample size (10, 100, or 1000)
#   n_replicate    Number of replicates (e.g., 10000)
#   threads        Number of parallel jobs (e.g., 100)
#   mongrail_bin   Path to original mongrail executable
#   chrom_dir      Directory containing .chrom files
#   postmean_dir   Directory containing .postMeanA/.postMeanB files
#   sim_dir        Directory containing per-individual .sim files
#   output_dir     Directory for output files
#
# Output:
#   Per-individual: <output_dir>/<sim_params>.out_i{1..n}
#   Combined:       <output_dir>/<sim_params>.out_N<sample_size>
#
# Example:
#   ./run_inference_plugin.sh 50 5 1000 10000 100 \
#       ../src/mongrail/mongrail \
#       ../data/chrom_files \
#       ./posterior_means/ \
#       ../simulation_study_1/individuals/ \
#       ./results/
# =============================================================================

set -euo pipefail

if [[ $# -lt 10 ]]; then
    echo "Usage: $0 <recom_freq> <n_hap> <sample_size> <n_replicate> <threads> \\"
    echo "          <mongrail_bin> <chrom_dir> <postmean_dir> <sim_dir> <output_dir>"
    exit 1
fi

recom_freq=$1
n_hap=$2
sample_size=$3
n_replicate=$4
threads=$5
mongrail_bin=$6
chrom_dir=$7
postmean_dir=$8
sim_dir=$9
output_dir=${10}

# Derived filenames
chrom_filename="c20_m10_r${recom_freq}.chrom"
sim_parameters="c20_m10_r${recom_freq}_h${n_hap}_au1_hc0.1"

mkdir -p "${output_dir}"

echo "============================================================"
echo "  Mongrail Inference (Plug-in Posterior Mean)"
echo "============================================================"
echo "  Chrom file:    ${chrom_filename}"
echo "  Sim params:    ${sim_parameters}"
echo "  Sample size:   N=${sample_size}"
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
        A_filename="${sim_parameters}.postMeanA_rep${i}"
        B_filename="${sim_parameters}.postMeanB_rep${i}"
        out_filename="${sim_parameters}.out_i${i}"

        ${mongrail_bin} \
            -c "${chrom_dir}/${chrom_filename}" \
            -A "${postmean_dir}/${A_filename}" \
            -B "${postmean_dir}/${B_filename}" \
            -i "${sim_dir}/${sim_filename}" \
            -o "${output_dir}/${out_filename}" &

        c=$(( c + 1 ))
        i=$(( i + 1 ))
    done
    wait
    echo "  ${i} / ${n_replicate} completed"
done

# Concatenate results
final_output="${output_dir}/${sim_parameters}.out_N${sample_size}"
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

echo "Done. Final output: ${final_output}"
