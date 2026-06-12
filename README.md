# Mongrail 2.0 — Simulation Studies

Reproducibility materials for the simulation studies in the Mongrail 2.0 paper.

## Quick Start

```bash
# 1. Prerequisites + build (once)
sudo apt install build-essential libglib2.0-dev pkg-config
./build.sh                              # compiles mongrail + mongrail2

# 2. Quick check that everything runs (~1–2 min, a handful of individuals)
./smoke_test.sh

# 3. Inference — produces the output files (no figures)
./simulation_study_1/run_all_study1.sh  # all 4 combos × N=10,100,1000
./simulation_study_2/run_all_study2.sh  # requires Study 1 to have run first

# 4. Figures — separate step, needs R (run after inference)
#    see each study's README for the exact plot command
```

`run_all_study1.sh` / `run_all_study2.sh` are the single entry points: each runs
**every** parameter combination across **all** sample sizes (N = 10, 100, 1000).
To run one combination at a time:

```bash
./simulation_study_1/run_study1.sh <recom_freq> <n_hap>   # e.g. 50 5
```

Plotting is intentionally separate from inference, so the (slow) inference can run
on a machine without the R graphics stack and figures can be made afterwards from
the output files on any machine with R.

<!--
**Runtime:** one parameter combination takes approximately **[TODO: ~X on Y cores]**;
the full set is four combinations. Set parallelism with `THREADS=<n>`.
-->

## Prerequisites

- C compiler (gcc) with glib-2.0 (see Software section above)
- R (≥ 4.0) with packages:
  - Study 1: `ggplot2`, `ggh4x`, `RColorBrewer`, `reshape`, `ggpubr`
  - Study 2: `ggplot2`, `pROC`
- Bash with awk/sed (standard Linux)

Re-running a study re-creates its working directories; for a clean reproduction,
delete `panels/`, `individuals/`, `results/`, `posterior_means/`, and `figures/`
first (all are gitignored).

## Software

The simulations were run with a **development version** of Mongrail and Mongrail 2.0.
The source code for those versions is in `src/`. The current release has undergone
significant modifications since these simulations were conducted.

```bash
./build.sh                  # builds both, from the repo root
# equivalently, by hand:
cd src/mongrail/  && make   # builds: mongrail,  gendiplo
cd src/mongrail2/ && make   # builds: mongrail2, gendiplo
```

Requires gcc and glib-2.0. On Ubuntu/Debian: `sudo apt install build-essential libglib2.0-dev pkg-config`

## Repository Layout

```
simulations/
├── README.md
├── build.sh                         # compile both binaries
├── smoke_test.sh                    # quick end-to-end runnability check
├── data/
│   ├── chrom_files/                 # Chromosome definitions (r=1, r=50)
│   ├── pop_files/                   # Population haplotype frequencies (h=5, h=15)
│   ├── sim_files/                   # Simulated individuals (4 parameter combos)
│   └── model_specified_10000.txt    # True model labels for 10,000 individuals
├── src/
│   ├── mongrail/                    # Original Mongrail source (paper version)
│   └── mongrail2/                   # Mongrail 2.0 source (paper version)
├── simulation_study_1/              # Mongrail 2.0 vs Mongrail (known frequencies)
│   ├── run_all_study1.sh            #   all combos (main script)
│   ├── run_study1.sh                #   one combo:  <recom_freq> <n_hap>
│   └── plot_stacked_barplots.R      #   figures (separate step)
└── simulation_study_2/              # Mongrail 2.0 vs plug-in posterior mean
    ├── run_all_study2.sh            #   all combos (needs Study 1 first)
    ├── run_study2.sh                #   one combo:  <recom_freq> <n_hap>
    └── plot_auc.R                   #   figures (separate step)
```

## Simulation Studies

**Study 1:** Compares Mongrail 2.0 (sampled reference panels at N=10, 100, 1000)
against original Mongrail (known frequencies). Output: stacked barplots of posterior
model probabilities. See [`simulation_study_1/README.md`](simulation_study_1/README.md).

**Study 2:** Compares Mongrail 2.0 against a plug-in approach where posterior mean
frequencies are estimated from counts and passed to original Mongrail as if they were
known. Output: AUC comparison across all models, sample sizes, recombination rates,
and haplotype counts. See [`simulation_study_2/README.md`](simulation_study_2/README.md).

## Parameter Combinations

All simulations are run across 4 parameter combinations:

| Recombination (R) | Haplotypes (h) | Parameters |
|---|---|---|
| 1 cM | 5 | `c20_m10_r1_h5_au1_hc0.1` |
| 1 cM | 15 | `c20_m10_r1_h15_au1_hc0.1` |
| 50 cM | 5 | `c20_m10_r50_h5_au1_hc0.1` |
| 50 cM | 15 | `c20_m10_r50_h15_au1_hc0.1` |

## Naming Convention

Filenames follow the pattern `c20_m10_rX_hY_au1_hcZ`:

| Code | Parameter | Meaning |
|---|---|---|
| `c20` | 20 chromosomes | Number of simulated chromosomes |
| `m10` | 10 markers | Number of biallelic markers per chromosome |
| `rX` | Recombination rate | Marker spacing in cM (1 or 50) |
| `hY` | Haplotypes | Number of distinct haplotypes per chromosome (5 or 15) |
| `au1` | α = 1 | Dirichlet symmetry parameter for haplotype frequencies |
| `hc0.1` | c = 0.1 | Switch rate for haplotype allelic configurations (p = c/m10) |

Haplotype configurations are generated using a switching process that flips adjacent
allele states, mimicking recombination along the chromosome. Haplotype frequencies
follow a symmetric Dirichlet distribution with parameter α.

## Citation

If you use MONGRAIL in your research, please cite:

Sneha Chakraborty, Bruce Rannala. 2025. Improved Bayesian inference of hybrids using genome sequences. bioRxiv 2025.12.26.696621; doi: https://doi.org/10.64898/2025.12.26.69662

Sneha Chakraborty, Bruce Rannala. 2023. An efficient exact algorithm for identifying hybrids using population genomic sequences, Genetics 223:4, iyad011, https://doi.org/10.1093/genetics/iyad011

## Disclaimer — this repository is for reproducibility only

This repository exists **solely to reproduce the simulation studies** in the paper.
The code in `src/` is the development version of Mongrail and Mongrail 2.0 used to
generate those results; it is frozen at the paper's state and is **not** maintained
for general use.

**To run Mongrail on your own data, use the current, maintained release:**

**→ https://github.com/mongrail/mongrail2**

The maintained software provides pre-built binaries and has been substantially
revised since these simulations were conducted; see that repository for installation
instructions, supported input formats, and the current version. Outputs from this
reproducibility repository are not expected to match the current release
version-for-version.
