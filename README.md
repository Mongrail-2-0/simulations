# Mongrail 2.0 — Simulation Studies

Reproducibility materials for the simulation studies in the Mongrail 2.0 paper.

## Software

The simulations were run with a **development version** of Mongrail 2.0. The source code for that version is in `src/`. The current release has undergone significant modifications since these simulations were conducted.

```bash
cd src/mongrail2/
# [build instructions]

cd src/mongrail/
# [build instructions]
```

## Repository Layout

```
simulations/
├── README.md
├── data/
│   ├── chrom_files/                 # Chromosome definitions (r=1, r=50)
│   ├── pop_files/                   # Population haplotype frequencies (h=5, h=15)
│   ├── sim_files/                   # Simulated individuals (4 parameter combos)
│   └── model_specified_10000.txt    # True model labels for 10,000 individuals
├── src/
│   ├── mongrail/                    # Original Mongrail source (paper version)
│   └── mongrail2/                   # Mongrail 2.0 source (paper version)
├── simulation_study_1/              # Mongrail 2.0 vs Mongrail (known frequencies)
└── simulation_study_2/              # Mongrail 2.0 vs plug-in posterior mean
```

## Simulation Studies

**Study 1:** Compares Mongrail 2.0 (sampled reference panels at N=10, 100, 1000) against original Mongrail (known frequencies). See [`simulation_study_1/README.md`](simulation_study_1/README.md).

**Study 2:** Compares Mongrail 2.0 against a plug-in approach where posterior mean frequencies are estimated from counts and passed to original Mongrail. See [`simulation_study_2/README.md`](simulation_study_2/README.md).

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
| `hc0.1` | c = 0.1 | Switch rate for haplotype allelic configurations (p = c/L) |

Haplotype configurations are generated using a switching process that flips adjacent allele states, mimicking recombination along the chromosome. Haplotype frequencies follow a symmetric Dirichlet distribution with parameter α.

## Prerequisites

- R (≥ 4.0) with: `ggplot2`, `ggh4x`, `RColorBrewer`, `reshape`, `ggpubr`, `pROC`, `lemon`
- Bash with awk/sed
- Compiled binaries from `src/`

## Citation

```
[Your citation here]
```
