# Standalone MET

Use CPython 3.14 and x86-64 Linux. The tested environment was AlmaLinux 9
under WSL2. The analysis executable includes its native CorrectionLib provider
and calibration payloads. Its input is the original PHYSLITE file identified
in input.txt. An exact local copy with the recorded ROOT UUID is also accepted.

From this extracted directory, run the five-state histogram with uv and the
included public dependency wheels. Use these thread limits to reproduce the
single-thread numerical environment.

```bash
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1 BLIS_NUM_THREADS=1 RAYON_NUM_THREADS=1
uv run --offline --no-index --find-links public-wheels --python /path/to/python3.14 \
    met_demo.py "$(cat input.txt)" full.npz
```

To create a separate nominal histogram, add `--nominal-only` and use a new
output filename. The separate correlated diagnostic uses
`--correlated-diagnostic`. The option `-n 2` reopens and recalculates the
original stream twice and checks that the final histogram repeats exactly.

The same local wheel can be installed with pip using the tested dependencies
and their exact hashes.

```bash
python3.14 -m venv .venv
.venv/bin/python -m pip install --no-index --find-links wheels \
    --find-links public-wheels --require-hashes -r requirements-lock.txt
.venv/bin/python met_demo.py "$(cat input.txt)" full.npz
sha256sum -c files.sha256
```

Each Final histogram has unit weights, 100 bins from 0 to 500 GeV and both
flow bins. The NPZ contains labels, bin edges, counts, sum of weights and
sum of squared weights. Use a new output path so an existing result is
preserved. See bundle.json and identity.json for the compiled API identity,
payload hashes, original input and source revision.
