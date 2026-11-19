# MET optimization ideas — discovery register

These are hypotheses, not measured MET gains. No candidate adopted.

| ID | Mechanism and provenance | Constraint / next test | Status |
|---|---|---|---|
| M01 | Bind immutable table and configuration handles once (jets selected 04d; lazy getters rejected after mixed timings). | Compatible; profile MET tool initialization and hot dispatch first. | Proposed |
| M02 | Reuse hard recoil and association work only for states with identical effective inputs (muon invariant-state reuse). | Compatible; derive MET-specific dependency and selection map, then compare every state. | Proposed |
| M03 | Reuse source-equivalent random draws (jets Gaussian work). | Compatible only with exact seed, draw order, zero-seed and error semantics; scale variations also draw. | Proposed |
| M04 | Reuse argument/output storage at original tool boundaries (muon B projection/argument work). | Compatible; establish allocation profile and unchanged framework configuration first. | Proposed |
| M05 | Typed raw-field bindings and element-link index maps (jet/muon input plumbing). | Compatible; independently validate identity, missing links, empty collections and original-object mapping. | Proposed |
| M06 | Narrow ROOT branch loading using actual consumed leaves (muon footprint helper). | Compatible; inventory decoded and compressed bytes, then measured read-only control. | Proposed |
| M07 | Native multiple-output callback after ordinary optimizations (muon accepted indexed outputs). | Compatible later stage; retain prior tool-boundary checkpoint and measure separately. | Deferred |
| M08 | Specialized array callback after ordinary optimizations (muon batch; jets string-only hoisting rejected). | Compatible later stage; prove callback dispatch and full-state equivalence. | Deferred |
| M09 | Combine tool boundaries to share intermediate work. | Major architectural experiment; only after measured ordinary options are exhausted. | Deferred |
| M10 | Bulk branch request / linked-input cache (muon rejected paired trials). | Compatible but no MET cost evidence; do not repeat without a new hypothesis. | Deferred |

Reusable infrastructure: ../muon-fresh/reproduction.md, ../muon-fresh/measure_input_footprint.py, ../jets-fresh/shared-source-04d/README.md, ../jets-fresh/source-map.json. No upstream-object physics or acceptance claim transfers automatically to MET.
