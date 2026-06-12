#!/bin/bash
# =============================================================================
# smoke_test.sh  —  quick check that the pipeline RUNS end to end
# =============================================================================
# This is a PLUMBING TEST, not a scientific run. It runs one combo with only a
# handful of individuals so it finishes in ~1-2 minutes, then checks that all
# the expected output files were produced. It still runs all three real
# reference-panel sample sizes (N = 10, 100, 1000) through the workhorse.
#
# It temporarily truncates one sim file and ALWAYS restores it afterward
# (even if the run fails).
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
SIM="$HERE/data/sim_files/${SP}.sim"

[ -x "$HERE/src/mongrail/mongrail"   ] || { echo "Build first: ./build.sh"; exit 1; }
[ -x "$HERE/src/mongrail2/mongrail2" ] || { echo "Build first: ./build.sh"; exit 1; }
[ -f "$SIM" ] || { echo "No sim file for combo r$R h$H: $SIM"; exit 1; }

# always restore the real sim file, even on failure
BACKUP="$(mktemp)"
cleanup() { cp "$BACKUP" "$SIM"; rm -f "$BACKUP"; echo "[smoke] restored $(basename "$SIM")"; }
trap cleanup EXIT

echo "[smoke] combo r=$R h=$H, $N_IND individuals (plumbing test only)"

# truncate the sim to N_IND individuals (position column + N_IND columns)
cp "$SIM" "$BACKUP"
awk -v n=$((N_IND+1)) '{printf "%s",$1; for(i=2;i<=n;i++) printf " %s",$i; printf "\n"}' "$BACKUP" > "$SIM"

# clean working dirs so we test from scratch
rm -rf "$HERE/simulation_study_1/individuals" "$HERE/simulation_study_1/panels" "$HERE/simulation_study_1/results"
rm -rf "$HERE/simulation_study_2/posterior_means" "$HERE/simulation_study_2/results"

# run both studies for this one combo, few individuals, 2 threads
( cd "$HERE/simulation_study_1" && N_REPLICATE=$N_IND THREADS=2 ./run_study1.sh "$R" "$H" )
( cd "$HERE/simulation_study_2" && N_REPLICATE=$N_IND THREADS=2 ./run_study2.sh "$R" "$H" )

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
