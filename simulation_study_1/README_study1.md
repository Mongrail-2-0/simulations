# Simulation Study 1: Mongrail 2.0 vs Original Mongrail

Compares Mongrail 2.0 (which integrates over sampling uncertainty in reference
panels) against the original Mongrail (which uses known population frequencies),
at three reference-panel sample sizes N = 10, 100, 1000.

## Run

```bash
../build.sh                 # once, from the repo root

./run_all_study1.sh         # all 4 combos × N=10,100,1000   (main script)
# or one combo at a time:
./run_study1.sh <recom_freq> <n_hap>      # e.g. ./run_study1.sh 50 5
```

This produces the **output files** in `results/` — it does *not* make figures (see
[Plotting](#plotting-separate-step)). Each combo runs all three N automatically.
Optional env overrides: `N_REPLICATE` (number of individuals, default 10000),
`THREADS` (default 100).

Output per combo, in `results/`:
- `<combo>.out` — original Mongrail baseline (known frequencies)
- `<combo>.m2out_N10`, `_N100`, `_N1000` — Mongrail 2.0

## What it does

`run_study1.sh` chains the steps below for one combo (you can also run them by hand):

```
pop files ─→ [sample_reference_panels.R] ─→ count files (panels)
                                                   │
sim file  ─→ [split_individuals.sh] ─→ individual files ─→ [run_inference.sh] ─→ .m2out_N{10,100,1000}
                                                   │  └─→ [run_inference_known_freqs.sh] ─→ .out (baseline)
                                          chrom files
```

1. **Split individuals** — `split_individuals.sh` splits the combo's `.sim` into
   per-individual files.
2. **Baseline** — `run_inference_known_freqs.sh` runs original Mongrail on the known
   `.popA`/`.popB` frequencies → `<combo>.out` (needed for the figure).
3. **Mongrail 2.0** — for each N: `sample_reference_panels.R` multinomial-samples the
   panels, then `run_inference.sh` runs Mongrail 2.0 → `<combo>.m2out_N{N}`.

## Plotting (separate step)

After inference, make the figure with R (needs `ggplot2`, `ggh4x`, `RColorBrewer`,
`reshape`, `ggpubr`):

```bash
Rscript plot_stacked_barplots.R \
    ./results/ <combo> ../data/model_specified_10000.txt ./figures/<combo>.pdf [n_display]
# example:
Rscript plot_stacked_barplots.R \
    ./results/ c20_m10_r50_h5_au1_hc0.1 ../data/model_specified_10000.txt \
    ./figures/barplots_r50_h5.pdf
```

Requires all three `.m2out_N{10,100,1000}` **and** the `.out` baseline for that combo
to be present in `results/` (run the inference first). Produces a 2-page PDF:
Backcross (b) vs F2 (f), and Purebred (d) vs F1 (c).

## Scripts

| Script | Purpose |
|---|---|
| `run_all_study1.sh` | Run every parameter combination (calls `run_study1.sh`) |
| `run_study1.sh` | Run one combo across all N (split → baseline → Mongrail 2.0) |
| `split_individuals.sh` | Split a multi-individual `.sim` into per-individual files |
| `run_inference_known_freqs.sh` | Original Mongrail on known frequencies → `.out` baseline |
| `sample_reference_panels.R` | Multinomial sampling of reference panels |
| `run_inference.sh` | Parallel Mongrail 2.0 inference + concatenation |
| `plot_stacked_barplots.R` | Stacked-barplot figure (separate step) |

## Parameter combinations

| recom_freq | n_hap | sim_params |
|---|---|---|
| 1 | 5 | `c20_m10_r1_h5_au1_hc0.1` |
| 1 | 15 | `c20_m10_r1_h15_au1_hc0.1` |
| 50 | 5 | `c20_m10_r50_h5_au1_hc0.1` |
| 50 | 15 | `c20_m10_r50_h15_au1_hc0.1` |

## Required R packages

```r
install.packages(c("ggplot2", "ggh4x", "RColorBrewer", "reshape", "ggpubr"))
```
