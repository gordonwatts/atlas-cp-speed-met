# A one-coefficient CorrectionSet

The parallel-resolution ROOT bin in the Dec24 MET calibration stores the double `0x1.b6e246f39336ep+10`. Its JSON representation is `1755.5355805337563`. A constant CorrectionLib correction with that decimal reproduces the difference independently of ATLAS, MET, bin finding and random numbers. The witness reads the same correction through the ordinary file, gzip and string entry points. [Constant payload](decimal_precision.json) · [C++ witness](decimal_precision.cxx)

| CorrectionSet reader | Pinned develop | Same revision with full-precision parsing |
| --- | --- | --- |
| File | `0x1.b6e246f39336fp+10` | `0x1.b6e246f39336ep+10` |
| Gzip | `0x1.b6e246f39336fp+10` | `0x1.b6e246f39336ep+10` |
| String | `0x1.b6e246f39336fp+10` | `0x1.b6e246f39336ep+10` |

The two builds use GCC 15.2 and the same CorrectionLib revision, `3dcfa20ec01fb40c4d5fec58383785519dec1c00`. The patch adds RapidJSON's full-precision flag where CorrectionSet reads documents. It preserves the flag for nonfinite literals. The MET evaluator reads those doubles during payload loading. The campaign has no isolated measurement of how the parser setting changes load time. [Patch](precision-correctionset.patch) · [Build and library digest](job.log) · [Unmodified build](../core/job.log) · [Upstream checks](../core/numeric-parsing-upstream.json)

From the campaign checkout in `atlas_al9`, the existing witness executables can be repeated in the release compiler environment. Each prints expected, file, gzip and string values. The unmodified executable returns 1 when any value differs. The corrected executable returns 0. [Output from the original reader](original.log) · [Output from the corrected reader](exact.log)

```bash
cd /home/gwatts/atlas-cp-speed/met-20261119
source scripts/release_environment.sh
taskset -c 0 results/core-precision-audit-001/original \
    fixtures/decimal_precision.json results/core-precision-audit-001/decimal.json.gz
taskset -c 0 results/core-precision-audit-001/exact \
    fixtures/decimal_precision.json results/core-precision-audit-001/decimal.json.gz
```

To repeat the independent witness with another installed core, set `core` to the directory containing its `include` and `lib` subdirectories. Use the files alongside this note and a fresh output directory.

```bash
work=$(mktemp -d)
gzip -nc decimal_precision.json > "$work/decimal.json.gz"
g++ -std=c++17 -I"$core/include" decimal_precision.cxx -L"$core/lib" \
    -Wl,--disable-new-dtags,-rpath,"$core/lib" -lcorrectionlib -o "$work/decimal"
"$work/decimal" decimal_precision.json "$work/decimal.json.gz"
```

Full-payload tests on the corrected core covered 774 table rows per tested loader and the stage, seed and draw comparisons against AnalysisBase. [Table result](../soft/smoke.log) · [Stock soft-term result](../soft/stock.log)
