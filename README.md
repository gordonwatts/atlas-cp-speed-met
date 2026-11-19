# ATLAS missing transverse momentum with CorrectionLib

On 20,000 original PHYSLITE events, standalone Python and the CorrectionLib adapter inside AnalysisBase reproduced the stock CP tools for all eight MET terms and four Final significance quantities across nominal and four recommended soft-term variations. The qualified five-state end-to-end timing was **22.685 ± 0.458 s** for stock, **22.939 ± 0.451 s** for the framework replacement and **2.525 ± 0.042 s** for standalone, an **8.99×** stock-to-standalone speedup. The framework-only B/A ratio was 1.0112. Stock nominal warm-up failed its process screen, so a nominal stock-relative speedup remains inconclusive. [Full comparison](met-20261119/report.md) · [Timing records](met-20261119/evidence/offset-final/timing/summary.json)

## Reading the results

| Material | Location |
| --- | --- |
| Final technical report and working-group slides | [Report](met-20261119/report.md) · [Editable PowerPoint](met-20261119/talk/MET.pptx) · [Speaker outline](met-20261119/talk/TALK.md) |
| Final standalone analysis and offline Linux CPython 3.14 package | [Instructions and package](met-20261119/standalone-offset/) |
| Campaign decisions, physics comparison and independent review | [Campaign log](met-20261119/campaign.md) · [Final evidence](met-20261119/evidence/offset-final/) · [Review](met-20261119/evidence/final-review.md) |
| Optimization trials, timing, profiles and plots | [Trial register](met-20261119/optimization.md) · [Final CPU profile](met-20261119/evidence/offset-final/profile-5000/native/render.txt) · [Figures](met-20261119/figures/) |
| Runtime logs, event traces and machine-readable run reports | [Runtime records](runtime-logs/) · [Path, size and SHA-256 inventory](runtime-logs/manifest.tsv) |
| Earlier MET table-conversion checkpoint | [Report](met/README.md) · [Historical log](met/log.txt) |
| Code repository map and original optimization commits | [Implementation map](https://github.com/gordonwatts/atlas-cp-speed-met-code#repository-map) · [Validated source revision](https://github.com/gordonwatts/atlas-cp-speed-met-code/commit/51d6b22bfcfb1b097952f101266cb2ed1aa6b1e9) |

## Reading the runtime records

The manifest maps each original path under `results/` to its published file under `runtime-logs/`. It includes build, framework, validation, timing, packaging and profiler output, including failed trials. Small records are plain files. For larger records the `encoding` column says `gzip`. To recover one exactly, run `gzip -dc <published-file.gz> > <original-name>` and check the SHA-256 of the decompressed bytes against the manifest. The original event input, build directories and installed dependency environments are separate from the published logs. Absolute paths recorded inside a log refer to the machine that ran it.

The MET report snapshot corresponds to the local delivery commit `3cff485f566946ecbaf5e1ae5e2add400ecef122`. References to earlier studies link to their published files where available. Citations marked “workspace reference” identify the historical source path for related work outside these MET repositories.
