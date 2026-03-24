# Mongrail — Source Code (Paper Version)

Original Mongrail, which uses known population haplotype frequencies for hybrid classification. Used in the paper as the baseline comparison for Mongrail 2.0, and also used in Simulation Study 2 with plug-in posterior mean frequencies.

## Dependencies

- C compiler (gcc)
- glib-2.0 (`pkg-config --cflags --libs glib-2.0`)
- math library (-lm)

On Ubuntu/Debian:
```bash
sudo apt install build-essential libglib2.0-dev pkg-config
```

## Building

```bash
make
```

Produces two binaries:
- `mongrail` — the main inference engine
- `gendiplo` — diplotype enumeration helper

## Files

```
src/
├── mongrail.c     # Main Mongrail inference
└── gendiplo.c     # Diplotype enumeration

include/
└── bit.h          # Constants and data structures
```
