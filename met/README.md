# Missing transverse energy conversion: initial checkpoint

The soft-term uncertainty **tables** have been converted to CorrectionLib, with **747/747 exact comparisons** against original ROOT lookups. This is an initial component checkpoint, not a completed MET calibration conversion or a performance result.

The original checkout was `/home/gwatts/atlas/correctionlib_tests/met` in WSL `atlas_al9`. That checkout is no longer present. This directory preserves its evidence and source inspection copies. The November 19 campaign independently rebuilt the full MET workflow in `/home/gwatts/atlas-cp-speed/met-20261119`. [Full MET comparison](../met-20261119/report.md) · [Campaign and evidence locations](../met-20261119/campaign.md)

## Verified scope

The unmodified AnalysisBase 25.2.117 METSystematicsTool resolves `METUtilities/R22_PreRecs/TrackSoftTerms-pflow_Dec24.config`, which loads `R22_PreRecs_Run2Run3_TSTSystematics_Dec24.root`. The active histograms are `shiftpara_TST`, `resopara_TST`, and `resoperp_TST`. Source and configuration hashes are in [table provenance](evidence/table-provenance.json).

Fresh tool initialization reports four recommended variations: `MET_SoftTrk_Scale__1up`, `MET_SoftTrk_Scale__1down`, `MET_SoftTrk_ResoPara`, and `MET_SoftTrk_ResoPerp`. `MET_SoftTrk_ResoCorr` is also affecting but not recommended. Nominal is a separate state. This list is the MET tool list; it does not enumerate uncertainties propagated from other objects. See [discovery](evidence/discovery.json).

The existing original PHYSLITE input was retained: MC23 full-simulation ttbar dataset 601229, p7266, UUID `79ee6652-311f-11f1-aa37-0445010abeef`, 20,000 events and 245,815,772 bytes. Its association-map, core-MET and truth-MET branches are present. Presence alone does not validate columnar link decoding.

## Table implementation and checks

The repeatable offline exporter uses PathResolver and TEnv, reads TH3D contents and emits three standard CorrectionLib MultiBinning nodes. It preserves ROOT underflow/overflow values and the tool's special pt-hard overflow clamp. Histogram errors are not consumed by this active lookup prescription. The source histograms have 16 × 1 × 1 regular bins.

The checker loads the payload through the existing develop-based CorrectionLib binding. It compares every bin/flow-bin center combination, each axis edge and adjacent representable floating-point values, with exact equality. All 747 probes pass; [comparison evidence](evidence/table-comparison.json) records the binding and payload hashes. This is a table-value check, not an original METSystematicsTool corrected-output comparison. NaN inputs, complete recipe error behavior, RNG, object states, significance and event-level outputs are not yet covered.

The original checkout used these commands with fresh output directories.

```bash
cd /home/gwatts/atlas/correctionlib_tests
bash met/scripts/export_tables.sh /absolute/new/table-directory
bash met/scripts/check_tables.sh /absolute/new/table-directory /absolute/new/check-directory
```

The wrappers use the existing AnalysisBase setup; the checker explicitly reuses the fresh muon campaign's CorrectionLib binding and Python dependencies. This is development reuse, not a standalone package. [Inspection manifest](inspection/manifest.json) identifies the source copies.

## Remaining conversion boundary

METMaker reconstructs contributions through the association map, original-object links and ordered selection flags. Default ordering is electrons, photons, taus, muons, then jets. Jet overlap treatment needs constituent and track quantities, muon energy loss and JVT decisions. It cannot be replaced faithfully by summing calibrated object vectors alone.

METSystematicsTool derives recoil from truth MET and reconstructed hard terms. It uses actual pile-up interactions, jet constituent counts and a Gaussian drawn even for scale variations. The framework seeds it from `int(1e6 * softTerm.phi())`. Those operations must execute behind CorrectionLib nodes in the replacement.

Default MET significance follows constituent links and calls jet, electron/photon, muon and tau resolution tools. It uses average pile-up interactions. A complete conversion therefore needs a separate significance boundary and those numerical dependencies, even with fixed upstream object momenta.

For the first conversion, hold upstream jets, leptons, photons and taus at their nominal inputs and selections across MET variations. The user selected this scope on 2026-11-04. Convert MET reconstruction, significance and MET-specific systematic uncertainties; defer propagation of upstream object uncertainties to a later campaign. Significance still requires its nominal object-resolution inputs. This scope does not waive any validation requirement within the selected MET calculation, and the result must not be described as the full combined analysis uncertainty model.

Required work still includes the original I/O/nominal/full reference captures, resolved output/acceptance contract, METMaker and significance implementations, complete systematic recipe, unchanged-configuration framework adapter, original-PHYSLITE columnar adapter, independent A/B and A/C acceptance, optimization and matched timings, CPython 3.14 standalone package, profiling, footprint measurements, overlays and final report/talk. There is no speedup or framework-adoption claim at this checkpoint.

## Storage and preservation

Initial Windows free space was approximately 17 GB. WSL's 718 GB logical free space does not establish host capacity. The new source/evidence checkpoint occupies approximately 106 KB in WSL. Existing environments and bindings were reused without copying their large packages. Historical benchmark/acceptance artifacts remain intact. [Task log](log.txt) records setup failures and decisions; [optimization register](optimization-ideas.md) records transferable hypotheses without claiming measured MET benefits.

