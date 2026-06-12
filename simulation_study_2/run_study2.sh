#!/bin/bash
# =============================================================================
# run_study2.sh <recom_freq> <n_hap>   —  ONE parameter combination
# =============================================================================
# Plug-in posterior-mean approach: estimate frequencies from the sampled
# panels, then run the original Mongrail on them. Writes to results/:
#   <combo>.out_N10 / _N100 / _N1000
#
# PREREQUISITE: Study 1 must have been run for this combo and all N first —
# this reads ../simulation_study_1/{individuals,panels/N*}/. Plotting (AUC)
# is a separate step run once across all combos (see plot_auc.R).
#
#   ../build.sh
#   ../simulation_study_1/run_study1.sh 50 5   # (or run_all_study1.sh)
#   ./run_study2.sh 50 5
#
# To run every combination, use ./run_all_study2.sh
#
# Environment overrides: N_REPLICATE (default 10000, number of individuals;
# lower only for a quick test with a truncated sim), THREADS (default 100).
# N (10/100/1000) is the scientific panel sample size and always runs all three.
# =============================================================================
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <recom_freq> <n_hap>   (e.g. $0 50 5)" >&2
    echo "  requires Study 1 to have been run for this combo first" >&2
    exit 1
fi
r="$1"; h="$2"

N_REPLICATE="${N_REPLICATE:-10000}"
THREADS="${THREADS:-100}"
SAMPLE_SIZES="10 100 1000"   # reference-panel sample sizes (scientific N; always all three)

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DATA="$ROOT/data"
M1="$ROOT/src/mongrail/mongrail"
S1="$ROOT/simulation_study_1"
sp="c20_m10_r${r}_h${h}_au1_hc0.1"

mkdir -p "$HERE/posterior_means" "$HERE/results"
[ -x "$M1" ]              || { echo "ERROR: $M1 missing — run ../build.sh first" >&2; exit 1; }
[ -d "$S1/individuals" ] || { echo "ERROR: $S1/individuals missing — run Study 1 first" >&2; exit 1; }

echo "## Study 2 — combo r=$r h=$h ($sp)"

for N in $SAMPLE_SIZES; do
    [ -d "$S1/panels/N${N}" ] || { echo "ERROR: $S1/panels/N${N} missing — run Study 1 for N=$N first" >&2; exit 1; }
    # .postMean files are NOT tagged by N and the script appends, so clear ->
    # compute -> infer within each N before moving on
    rm -f "$HERE/posterior_means/${sp}.postMean"*
    "$HERE/compute_posterior_means.sh" \
        "$r" "$h" "$N" "$N_REPLICATE" \
        "$S1/individuals/" "$S1/panels/N${N}/" "$HERE/posterior_means/" "$HERE/awk_scripts/"
    "$HERE/run_inference_plugin.sh" \
        "$r" "$h" "$N" "$N_REPLICATE" "$THREADS" \
        "$M1" "$DATA/chrom_files" "$HERE/posterior_means/" "$S1/individuals/" "$HERE/results/"
done

echo "## done r=$r h=$h -> $HERE/results/"
