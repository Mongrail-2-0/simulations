# Mongrail 2.0 — Source Code (Paper Version)

This is the development version of Mongrail 2.0 used to produce the simulation results in the paper. The current release has undergone significant modifications.

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

This produces two binaries:
- `mongrail2` — the main inference engine
- `gendiplo` — helper for enumerating diplotypes compatible with genotypes

## Files

```
src/
├── mongrail2.c    # Main Mongrail 2.0 inference
└── gendiplo.c     # Diplotype enumeration

include/
└── bit.h          # Constants and data structures (MAXLOCI=10, MAXHAPS=1024)

Makefile           # Build configuration
```
