# Source Code (Paper Version)

Both programs share the same dependencies (gcc, glib-2.0) and build with `make`.

```bash
cd mongrail/ && make    # builds: mongrail, gendiplo
cd mongrail2/ && make   # builds: mongrail2, gendiplo
```

- `mongrail/` — Original Mongrail (uses known population frequencies)
- `mongrail2/` — Mongrail 2.0 development version (integrates over sampled reference panels)
