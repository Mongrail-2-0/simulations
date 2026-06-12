#!/bin/bash
# =============================================================================
# run_study1.sh <recom_freq> <n_hap>   —  ONE parameter combination
# =============================================================================
# Runs a single combo through all three reference-panel sample sizes
# (N = 10, 100, 1000) and writes the output files to results/:
#   - Mongrail baseline (known frequencies):  <combo>.out
#   - Mongrail 2.0:                            <combo>.m2out_N10/_N100/_N1000
#
# This does NOT make figures — plotting is a separate step
# (see plot_stacked_barplots.R), so the expensive compute and the
# light-weight (and dependency-heavy) plotting stay decoupled.
#
#   ../build.sh            # build the binaries first (once)
#   ./run_study1.sh 50 5   # run one combo
#
# To run every combination, use ./run_all_study1.sh
#
# Environment overrides (optional):
#   N_REPLICATE  number of simulated individuals  (default 10000; the full
#                study uses 10000 — lower it only for a quick plumbing test,
#                with a correspondingly truncated sim file)
#   THREADS      parallel jobs                    (default 100)
#
# Note: N (the reference-panel sample size, 10/100/1000) is a scientific
# parameter and ALWAYS runs all three values — it is not a test knob.
# =============================================================================
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <recom_freq> <n_hap>   (e.g. $0 50 5)" >&2
    echo "  runs one combo across N=10,100,1000; output files go to results/" >&2
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
M2="$ROOT/src/mongrail2/mongrail2"
sp="c20_m10_r${r}_h${h}_au1_hc0.1"
pop="c20_m10_h${h}_au1_hc0.1"

mkdir -p "$HERE/individuals" "$HERE/panels" "$HERE/results"
[ -x "$M1" ] || { echo "ERROR: $M1 missing — run ../build.sh first" >&2; exit 1; }
[ -x "$M2" ] || { echo "ERROR: $M2 missing — run ../build.sh first" >&2; exit 1; }

echo "## Study 1 — combo r=$r h=$h ($sp)"

# 1) split the simulated individuals (independent of N)
"$HERE/split_individuals.sh" "$DATA/sim_files/${sp}.sim" "$HERE/individuals/"

# 2) Mongrail baseline on known frequencies -> .out
"$HERE/run_inference_known_freqs.sh" \
    "$r" "$h" "$N_REPLICATE" "$THREADS" \
    "$M1" "$DATA/chrom_files" "$DATA/pop_files" "$HERE/individuals/" "$HERE/results/"

# 3) Mongrail 2.0 across every sample size
for N in $SAMPLE_SIZES; do
    pdir="$HERE/panels/N${N}"; mkdir -p "$pdir"
    # the sampler APPENDS; clear this combo's count files so reruns / shared-h
    # combos can't corrupt them
    rm -f "$pdir/${pop}.countA_rep"* "$pdir/${pop}.countB_rep"*
    Rscript "$HERE/sample_reference_panels.R" "$DATA/pop_files/${pop}.popA" "$N" "$N_REPLICATE" "$pdir/"
    Rscript "$HERE/sample_reference_panels.R" "$DATA/pop_files/${pop}.popB" "$N" "$N_REPLICATE" "$pdir/"
    "$HERE/run_inference.sh" \
        "$r" "$h" "$N" "$N_REPLICATE" "$THREADS" \
        "$M2" "$DATA/chrom_files" "$pdir/" "$HERE/individuals/" "$HERE/results/"
done

echo "## done r=$r h=$h -> $HERE/results/"
