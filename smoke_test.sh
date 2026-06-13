#!/bin/bash
# =============================================================================
# smoke_test.sh  —  quick check that the pipeline RUNS end to end
# =============================================================================
# This is a PLUMBING TEST, not a scientific run. It runs one combo with only a
# handful of individuals so it finishes in ~1-2 minutes, then checks that all
# the expected output files were produced. It still runs all three real
# reference-panel sample sizes (N = 10, 100, 1000) through the workhorse.
#
# It does NOT modify your real data files. It builds a temporary data directory
# (real reference files symlinked, a truncated sim written into temp) and points
# the run scripts at it with DATA_DIR. Safe even if data/ is read-only.
#
#   ./smoke_test.sh             # default: combo r1_h5, 5 individuals
#   ./smoke_test.sh 50 5        # combo r50_h5, 5 individuals
#   ./smoke_test.sh 1 5 20      # combo r1_h5, 20 individuals
#
# (Note: ~5 individuals is enough to test that inference runs, but too few to
#  PLOT — figures need more individuals to be non-degenerate. This script does
#  not plot; it only verifies the output files are produced.)
# =============================================================================
set -euo pipefail

R="${1:-1}"; H="${2:-5}"; N_IND="${3:-5}"   # combo + number of test individuals
SP="c20_m10_r${R}_h${H}_au1_hc0.1"
HERE="$(cd "$(dirname "$0")" && pwd)"
REALDATA="$HERE/data"
SIM="$REALDATA/sim_files/${SP}.sim"

[ -x "$HERE/src/mongrail/mongrail"   ] || { echo "Build first: ./build.sh"; exit 1; }
[ -x "$HERE/src/mongrail2/mongrail2" ] || { echo "Build first: ./build.sh"; exit 1; }
[ -f "$SIM" ] || { echo "No sim file for combo r$R h$H: $SIM"; exit 1; }

# Temporary data dir — cleaned up on exit. Real data is never written to.
TMPDATA="$(mktemp -d)"
cleanup() {
    rm -rf "$TMPDATA"
    # remove the throwaway working dirs this test created, so it leaves no trace
    rm -rf "$HERE/simulation_study_1/individuals" "$HERE/simulation_study_1/panels" "$HERE/simulation_study_1/results"
    rm -rf "$HERE/simulation_study_2/posterior_means" "$HERE/simulation_study_2/results"
}
trap cleanup EXIT

mkdir -p "$TMPDATA/sim_files"
ln -s "$REALDATA/chrom_files" "$TMPDATA/chrom_files"   # symlink (read-only is fine)
ln -s "$REALDATA/pop_files"   "$TMPDATA/pop_files"
# truncated sim written into TEMP (reading the real file works even if read-only)
awk -v n=$((N_IND+1)) '{printf "%s",$1; for(i=2;i<=n;i++) printf " %s",$i; printf "\n"}' \
    "$SIM" > "$TMPDATA/sim_files/${SP}.sim"

echo "[smoke] combo r=$R h=$H, $N_IND individuals (plumbing test; real data untouched)"

# clean working dirs so we test from scratch
rm -rf "$HERE/simulation_study_1/individuals" "$HERE/simulation_study_1/panels" "$HERE/simulation_study_1/results"
rm -rf "$HERE/simulation_study_2/posterior_means" "$HERE/simulation_study_2/results"

# run both studies against the temp data dir, few individuals, 2 threads
( cd "$HERE/simulation_study_1" && DATA_DIR="$TMPDATA" N_REPLICATE=$N_IND THREADS=2 ./run_study1.sh "$R" "$H" )
( cd "$HERE/simulation_study_2" && DATA_DIR="$TMPDATA" N_REPLICATE=$N_IND THREADS=2 ./run_study2.sh "$R" "$H" )

# verify the expected output files exist
echo "[smoke] checking outputs:"
ok=1
for f in "simulation_study_1/results/${SP}.out" \
         "simulation_study_1/results/${SP}.m2out_N10" \
         "simulation_study_1/results/${SP}.m2out_N100" \
         "simulation_study_1/results/${SP}.m2out_N1000" \
         "simulation_study_2/results/${SP}.out_N10" \
         "simulation_study_2/results/${SP}.out_N100" \
         "simulation_study_2/results/${SP}.out_N1000"; do
    if [ -f "$HERE/$f" ]; then echo "  ok   $f"; else echo "  MISS $f"; ok=0; fi
done

if [ "$ok" = 1 ]; then
    echo "[smoke] PASS — both studies run end to end and produce all output files"
else
    echo "[smoke] FAIL — some outputs missing (see above)"; exit 1
fi
