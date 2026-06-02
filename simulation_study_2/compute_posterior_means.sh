#!/bin/bash
# =============================================================================
# compute_posterior_means.sh
# =============================================================================
# Computes posterior mean haplotype frequencies from multinomial-sampled count
# files. For each replicate, it:
#   1. Extracts haplotypes from the individual's genotypes
#   2. Finds the union of all unique haplotypes across popA, popB, and individual
#   3. Computes posterior mean: (count + 1/K) / (N + 1) for each haplotype
#
# Usage:
#   ./compute_posterior_means.sh <recom_freq> <n_hap> <sample_size> <n_replicate> \
#       <sim_dir> <panel_dir> <output_dir> <awk_dir>
#
# Arguments:
#   recom_freq     Recombination frequency (1 or 50)
#   n_hap          Number of haplotypes (5 or 15)
#   sample_size    Sample size used for panels (10, 100, or 1000)
#   n_replicate    Number of replicates (e.g., 10000)
#   sim_dir        Directory with per-individual .sim files (from Study 1)
#   panel_dir      Directory with .countA/.countB files (from Study 1)
#   output_dir     Directory for .postMeanA/.postMeanB output files
#   awk_dir        Directory containing awk helper scripts
#
# Output:
#   <output_dir>/<sim_params>.postMeanA_rep{i}
#   <output_dir>/<sim_params>.postMeanB_rep{i}
#
# Example:
#   ./compute_posterior_means.sh 50 5 1000 10000 \
#       ../simulation_study_1/individuals/ \
#       ../simulation_study_1/panels/N1000/ \
#       ./posterior_means/ \
#       ./awk_scripts/
# =============================================================================

set -euo pipefail

if [[ $# -lt 8 ]]; then
    echo "Usage: $0 <recom_freq> <n_hap> <sample_size> <n_replicate> \\"
    echo "          <sim_dir> <panel_dir> <output_dir> <awk_dir>"
    exit 1
fi

recom_freq=$1
n_hap=$2
sample_size=$3
n_replicate=$4
sim_dir=$5
panel_dir=$6
output_dir=$7
awk_dir=$8

# Derived names
pop_parameters="c20_m10_h${n_hap}_au1_hc0.1"
sim_parameters="c20_m10_r${recom_freq}_h${n_hap}_au1_hc0.1"
chrom_no=20

# Get script directory for transpose.sh
script_dir="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "${output_dir}"

echo "============================================================"
echo "  Computing Posterior Means"
echo "============================================================"
echo "  Sim params:    ${sim_parameters}"
echo "  Sample size:   N=${sample_size}"
echo "  Replicates:    ${n_replicate}"
echo "============================================================"
echo ""

for (( i=1; i<=n_replicate; i++ )); do
    sim_filename="${sim_parameters}.sim_i${i}"
    A_filename="${pop_parameters}.countA_rep${i}"
    B_filename="${pop_parameters}.countB_rep${i}"

    A_file_postMean="${output_dir}/${sim_parameters}.postMeanA_rep${i}"
    B_file_postMean="${output_dir}/${sim_parameters}.postMeanB_rep${i}"

    for (( j=1; j<=chrom_no; j++ )); do
        # Extract haplotypes from individual's genotype data for this chromosome
        sim_file=$(grep "^${j}:" "${sim_dir}/${sim_filename}" | "${script_dir}/transpose.sh" | awk -f "${awk_dir}/hap_frequency.awk")

        # Get haplotype counts from reference panels
        A_pop=$(grep "^${j} " "${panel_dir}/${A_filename}" | awk -f "${awk_dir}/count.awk")
        B_pop=$(grep "^${j} " "${panel_dir}/${B_filename}" | awk -f "${awk_dir}/count.awk")

        # Find union of all unique haplotypes
        all_hap=$(echo "${A_pop}" | awk '{print $1}')
        all_hap="${all_hap}"$'\n'"$(echo "${B_pop}" | awk '{print $1}')"
        all_hap="${all_hap}"$'\n'"$(echo "${sim_file}" | awk '{print $1}')"
        uniq_hap=$(echo "${all_hap}" | awk -f "${awk_dir}/uniq_hap.awk")

        # Compute posterior mean frequencies
        A_pop_freq=$(echo "${j}"$'\t')
        B_pop_freq=$(echo "${j}"$'\t')
        A_pop_freq+=$(awk -f "${awk_dir}/final_update_hap_freq.awk" <(echo "${uniq_hap}") <(echo "${A_pop}"))
        B_pop_freq+=$(awk -f "${awk_dir}/final_update_hap_freq.awk" <(echo "${uniq_hap}") <(echo "${B_pop}"))

        echo "${A_pop_freq}" >> "${A_file_postMean}"
        echo "${B_pop_freq}" >> "${B_file_postMean}"
    done

    if (( i % 1000 == 0 )); then
        echo "  ${i} / ${n_replicate} completed"
    fi
done

echo "Done."
