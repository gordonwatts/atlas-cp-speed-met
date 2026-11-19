param([Parameter(Mandatory)][string]$OutputName)

$ErrorActionPreference = 'Stop'
if ($OutputName -notmatch '^[a-zA-Z0-9_-]+\.pptx$') { throw 'Use a PowerPoint filename within the talk directory.' }
$talkDir = $PSScriptRoot
$reportDir = Split-Path -Parent $talkDir
$deckPath = Join-Path $talkDir $OutputName
$renderDir = Join-Path $talkDir ('render-' + [IO.Path]::GetFileNameWithoutExtension($OutputName))
if ((Test-Path -LiteralPath $deckPath) -or (Test-Path -LiteralPath $renderDir)) {
    throw 'Choose a fresh checkpoint name to preserve the previous editable deck.'
}
$ink = 0x3C3425
$blue = 0x8A6728
$accent = 0x2064AB
$white = 0xFFFFFF

function New-Label($slide, $value, $left, $top, $width, $height, $size, $color) {
    $shape = $slide.Shapes.AddTextbox(1, $left, $top, $width, $height)
    $shape.TextFrame.MarginLeft = 0
    $shape.TextFrame.MarginRight = 0
    $shape.TextFrame.WordWrap = -1
    $shape.TextFrame.TextRange.Text = $value
    $shape.TextFrame.TextRange.Font.Name = 'Calibri'
    $shape.TextFrame.TextRange.Font.Size = $size
    $shape.TextFrame.TextRange.Font.Color.RGB = $color
    return $shape
}
function New-ContentSlide($title, $notes) {
    $slide = $deck.Slides.Add($deck.Slides.Count + 1, 11)
    $heading = $slide.Shapes.Title
    $heading.Left = 48
    $heading.Top = 22
    $heading.Width = 870
    $heading.Height = 67
    $heading.TextFrame.TextRange.Text = $title
    $heading.TextFrame.TextRange.Font.Name = 'Calibri Light'
    $heading.TextFrame.TextRange.Font.Size = 37
    $heading.TextFrame.TextRange.Font.Color.RGB = $ink
    $slide.NotesPage.Shapes.Placeholders.Item(2).TextFrame.TextRange.Text = $notes
    $slide.HeadersFooters.Footer.Visible = -1
    $slide.HeadersFooters.Footer.Text = 'Gordon Watts (UW/Seattle)'
    $slide.HeadersFooters.SlideNumber.Visible = -1
    $ref = [regex]::Match($notes, '\.\./[A-Za-z0-9_./-]+\.(?:json|md|tsv|txt|py|png)')
    if ($ref.Success -and (Test-Path -LiteralPath (Join-Path $talkDir $ref.Value))) {
        $caption = if ($ref.Value -match '/timing/') { 'Timing evidence' }
                   elseif ($ref.Value -match 'contract\.json') { 'Study contract' }
                   elseif ($ref.Value -match '\.py$') { 'Analysis code' }
                   else { 'Source record' }
        $link = New-Label $slide $caption 49 502 185 23 12 $blue
        $action = $link.ActionSettings.Item(1)
        $action.Action = 7
        $action.Hyperlink.Address = $ref.Value
    }
    return $slide
}
function Add-Table($slide, $rows, $left, $top, $width, $height, $columnWidths, $size) {
    $table = $slide.Shapes.AddTable($rows.Count, $rows[0].Count, $left, $top, $width, $height).Table
    for ($col = 1; $col -le $columnWidths.Count; $col++) {
        $table.Columns.Item($col).Width = $columnWidths[$col-1]
    }
    for ($row = 1; $row -le $rows.Count; $row++) {
        for ($col = 1; $col -le $rows[0].Count; $col++) {
            $cell = $table.Cell($row,$col).Shape
            $cell.TextFrame.TextRange.Text = $rows[$row-1][$col-1]
            $cell.TextFrame.TextRange.Font.Name = 'Calibri'
            $cell.TextFrame.TextRange.Font.Size = $size
            $cell.TextFrame.VerticalAnchor = 3
            $cell.TextFrame.TextRange.Font.Bold = [int]($row -eq 1) * -1
            $cell.Fill.ForeColor.RGB = if ($row -eq 1) { $blue } elseif ($row % 2 -eq 0) { 0xF7F5F0 } else { $white }
            $cell.TextFrame.TextRange.Font.Color.RGB = if ($row -eq 1) { $white } else { $ink }
        }
    }
}
function Add-Figure($slide, $file, $left, $top, $width, $height) {
    $picture = $slide.Shapes.AddPicture($file, 0, -1, $left, $top, -1, -1)
    $factor = [Math]::Min($width / $picture.Width, $height / $picture.Height)
    $picture.LockAspectRatio = -1
    $picture.Width *= $factor
    $picture.Left = $left + ($width - $picture.Width)/2
    $picture.Top = $top + ($height - $picture.Height)/2
}
$app = New-Object -ComObject PowerPoint.Application
$before = $app.Presentations.Count
$deck = $app.Presentations.Add(0)
try {
    $deck.PageSetup.SlideWidth = 960
    $deck.PageSetup.SlideHeight = 540
    $deck.SlideMaster.Theme.ThemeFontScheme.MajorFont.Item(1).Name = 'Calibri Light'
    $deck.SlideMaster.Theme.ThemeFontScheme.MinorFont.Item(1).Name = 'Calibri'
    $deck.SlideMaster.HeadersFooters.Footer.Text = 'Gordon Watts (UW/Seattle)'
    $deck.SlideMaster.HeadersFooters.Footer.Visible = -1
    $deck.SlideMaster.HeadersFooters.SlideNumber.Visible = -1

    $s = New-ContentSlide 'Rebuilding Missing Transverse Momentum From PHYSLITE' 'Which MET calculations must an independent columnar implementation reproduce? The same original events can reach the same histogram through the stock tools and a shared CorrectionLib calculation. Gordon selected fixed nominal upstream objects across MET variations. The timing and numerical contract is in ../contract.json.'
    $s.Shapes.Title.Top = 105
    $s.Shapes.Title.Height = 125
    $s.Shapes.Title.TextFrame.TextRange.Font.Size = 45
    $null = New-Label $s 'Can AnalysisBase and a direct Python reader share the MET calculation?' 53 260 830 83 30 $blue
    $null = New-Label $s 'ATLAS software and calibration working group   ·   19 November 2026' 53 373 840 50 22 $ink

    $s = New-ContentSlide 'Three Paths to the Same MET Histogram' 'All three begin with the same original PHYSLITE file. The framework budget compares framework legs only. The 10× aspiration compares the sum of both stock legs to the direct standalone workflow. Source: ../contract.json.'
    Add-Table $s @(@('Path','Calculation and output'),@('A · Stock','AnalysisBase CP tools → ntuple → saved MET histogram'),@('B · Framework','CorrectionLib in AnalysisBase → ntuple → same histogram'),@('C · Standalone','uproot and Awkward → shared CorrectionLib nodes → same histogram')) 48 106 860 245 @(203,657) 21
    $null = New-Label $s 'Fill once per event and state. Use 5 GeV bins up to 500 GeV and keep both flows.' 50 390 856 81 24 $ink

    $s = New-ContentSlide 'One Event With Four Soft-Term Variations' 'The arrows on the left add head to tail. Jets and electrons dominate the hard recoil. The soft term then changes its direction or magnitude. Here the scale-up component reduces Final MET by 0.602 GeV. These are stock AnalysisBase results, before replacement comparisons. Source: ../evidence/intake/observer-smoke-008/entry-00000.json.'
    Add-Figure $s (Join-Path $reportDir 'figures/stock-event.png') 28 95 904 380

    $s = New-ContentSlide 'How Much Does the Spectrum Move?' 'The upper panel shows the original nominal Final MET in a 20,000-event top-pair sample. The lower panel subtracts the nominal bin count from each stock variation. Up to 47 events move into or out of a bin on net. The scalar sum stays fixed. All five histograms have six entries beyond 500 GeV. Stock and standalone also agree on the bin of each individual event. Sources: ../evidence/reference/production/full-verification.json and ../evidence/reference/full/summary.json.'
    Add-Figure $s (Join-Path $reportDir 'figures/stock-spectrum.png') 24 89 912 405

    $s = New-ContentSlide 'Where the MET Calculation Uses Object Identity' 'METMaker resolves selected copies back to their original keys and event-local indices. The ordered flags control overlap removal. A hard-jet link can have fractional weight, and an electron link can have zero weight. Significance traverses those links and uses the full object momentum. Sources: ../association-design.md, ../resolution-design.md.'
    Add-Table $s @(@('Stage','What passes to the next calculation'),@('Hard terms and track soft term','Ordered term vectors, source masks, constituent identities and weights'),@('Soft-term uncertainties','Recoil and actual pile-up set the shift or resolution. The seed comes from the soft-term azimuth.'),@('Final MET and significance','The varied Final direction sets the covariance rotation. Its inputs include the nominal object resolutions.')) 48 100 860 302 @(255,605) 19
    $null = New-Label $s 'The upstream object momenta and selections are fixed across all five production states.' 49 425 860 58 23 $blue

    $s = New-ContentSlide 'From One Chunk to Entries in the Histogram' 'The displayed lines come from the standalone analysis, with the checks and intervening preparation code omitted. First, the adapter reads the requested branches and resolves event-local links into typed buffers. The public native bridge invokes named CorrectionLib corrections for nominal preparation, maker, soft shift or smearing, Final and significance. The seven and three subscripts select the Final term and its magnitude. The analysis converts MeV to GeV before filling. Each state gets a separate histogram. Source ../standalone-offset/met_demo.py.'
    $null = New-Label $s 'Excerpt from the standalone Python analysis' 51 110 855 40 20 $blue
    $snippet = @'
raw = tree.arrays(fields, entry_start=first, entry_stop=last,
                  library="ak", how=dict)
# ... project linked inputs and apply nominal preparation ...
terms, sources, significance = bridge.full(
    context, buffers, first, last-first, labels, trace)
for j, label in enumerate(labels):
    gev = terms[:, j, 7, 3].astype("f8") / 1000.
    histogram.fill(label, gev, threads=1)
'@
    $code = New-Label $s $snippet 54 168 870 229 18 $ink
    $code.TextFrame.TextRange.Font.Name = 'Consolas'
    $null = New-Label $s 'The same native reconstruction, soft correction, Final sum and significance also run inside AnalysisBase.' 51 414 849 75 22 $blue

    $s = New-ContentSlide 'Two Checks on the Original File' 'The MET association jetLink stores keys and indices memberwise. The explicit decoder matched the original xAOD identities. The configured analysis also updates NNJVT. The standalone node uses jet momentum, vertex-indexed track sum, corrected jet vertex fraction and primary vertex type. Sources: ../evidence/reference/raw-input-evidence.json and ../evidence/components/nnjvt/exact/comparison.json.'
    Add-Table $s @(@('Original input','Full-file stock comparison'),@('Association links','216,606 jet links and 68,168 nested object links matched ROOT with the memberwise reader.'),@('Nominal jet tagger','The recomputed NNJVT pass flag differed from the stored flag on 2,057 of 196,606 jets.')) 48 108 860 248 @(243,617) 21
    $null = New-Label $s 'From five original fields, Python reproduced the score and both jet decisions for all 196,606 jets.' 50 395 850 76 23 $blue

    $s = New-ContentSlide 'Framework MET Agrees Event by Event' 'The points show the registered CorrectionLib nodes in AnalysisBase and the line shows the stock CP tools. The lower panel is replacement minus stock in events per bin. All five production states passed the individual event comparisons. The diagnostic overlay uses 120 bins. The separate saved 100-bin histogram has identical bytes. Sources: ../evidence/components/framework-full/comparison.json and ../figures/framework/counts.json.'
    Add-Figure $s (Join-Path $reportDir 'figures/framework/nominal-final-met.png') 23 90 604 382
    $null = New-Label $s '20,000 events' 652 133 280 55 28 $blue
    $null = New-Label $s 'Eight terms and four significance quantities matched exactly in nominal and all four recommended variations.' 651 202 270 210 22 $ink

    $s = New-ContentSlide 'Standalone Python Reproduces Final MET' 'CPython 3.14 reads the original PHYSLITE file using uproot. The production comparison has one entry for each event and state. Here the line is stock and the markers show the independent standalone route. Signed count residuals occupy the bottom panel. All eight term vectors, all four significance observables and every event bin agree for the five states. The saved histogram has the same SHA-256 in A, B and C. Sources: ../evidence/components/columnar-full/comparison.json and ../evidence/components/columnar-full/histogram-digests.txt.'
    Add-Figure $s (Join-Path $reportDir 'figures/columnar/nominal-final-met.png') 23 90 604 382
    $null = New-Label $s 'Original PHYSLITE' 646 131 287 50 27 $blue
    $null = New-Label $s 'Jet tagging and hard-object selection run before the shared MET nodes. The same six nominal events exceed 500 GeV.' 648 200 277 214 22 $ink

    $s = New-ContentSlide 'What Has Been Checked?' 'Full-precision JSON parsing recovered the release coefficient in all three readers. The unpatched core differed by one unit in the last place. The framework made all four registered calls in five states. Standalone output agrees with all saved MET numerical quantities. Sources: ../evidence/components/core-exact/reproduction.md, ../evidence/components/framework-full/trace-comparison.json and ../evidence/components/columnar-full/comparison.json.'
    Add-Table $s @(@('Comparison','Result'),@('Soft-term tables and draw','774 table probes per tested loader and 80,000 stock Gaussian draws matched exactly.'),@('Framework associations','64,575 flag writes and 983,030 jet decisions matched in order.'),@('Standalone Python','Eight terms and four significance quantities agreed event by event in all five states.')) 48 105 860 285 @(250,610) 19
    $null = New-Label $s 'The separate correlated resolution run also agreed with stock for all 20,000 events.' 50 417 855 62 22 $ink

    $s = New-ContentSlide 'Where the Standalone Calculation Spends Its Time' 'Exclusive wall times in a single diagnostic pass of the faithful program. Ordinary and association branch decoding took 1.47 s and projecting the links into preparation arrays took 1.31 s. The shared native loop increased from 0.25 to 0.57 s when going from one state to five. The full instrumented run took 3.94 s against 3.98 s for the neighbouring uninstrumented run, with the same histogram. Each phase includes only its own time. Source ../evidence/timing/c-phase/summary.json.'
    Add-Figure $s (Join-Path $reportDir 'figures/faithful-phase.png') 25 94 910 372
    $null = New-Label $s 'The faithful job spent 71% of its elapsed time reading or gathering original inputs.' 48 466 858 40 18 $blue

    $s = New-ContentSlide 'Does Reusing the Hard Terms Pay Off?' 'The same immutable maker result supplies the six hard and jet terms for each state. The soft correction, Final sum and significance still run separately. The full, nominal and correlated observables, flags, links, weights and draws matched stock. The first full trial saved 2.19%, but one-state nominal saved 2.90% with unchanged call count. In the role-reversed repeat the full gain was 0.78%, with paired changes of minus 17, plus 67 and plus 44 ms. We kept the faithful maker for the next trials. The native-stage timing was a separate diagnostic. Sources ../evidence/timing/m02/summary.json, ../evidence/timing/m02/role-reversed-recheck.json, ../evidence/timing/m02/phase-m02.json.'
    Add-Table $s @(@('Five MET states','Faithful maker','Reuse per event'),@('Actual maker calls','100,000','20,000'),@('Native MET loop','0.576 s','0.516 s'),@('File to histogram, repeat','3.967 ± 0.037 s','3.936 ± 0.044 s')) 47 104 865 271 @(327,269,269) 21
    $null = New-Label $s 'The full-run scatter left the gain uncertain at the 0.5% decision threshold.' 49 417 855 63 24 $blue

    $s = New-ContentSlide 'Many Track-Link Projections Have No Rows' 'A single muon may refer to several kinds of tracks. The link resolver considers each allowed target collection. The faithful path flattened fields even for empty selections. We keep the first projection to check input shape and type, and skip repeated empty projections onto the same field within a chunk. The existing gather remains active where links resolve. Both paths used the faithful native libraries. Full, nominal and correlated results matched stock and all retained timing pairs passed. Source ../evidence/timing/m21/summary.json and ../evidence/timing/c-source-focus/source-focus.json.'
    Add-Table $s @(@('Original field projections','Full file'),@('Valid target selections','1,010 field visits'),@('Empty target selections','4,080 field visits'),@('Five-state job after skipping repeats','3.935 → 3.316 s')) 46 109 866 277 @(491,375) 22
    $null = New-Label $s 'A 15.7% saving, with the same links, selections and saved MET histogram.' 49 416 855 65 24 $blue

    $s = New-ContentSlide 'One Optional Jet Branch Costs 5.86 MB' 'The jet presampler fraction is present on the original file. The maker uses per-sampling energies only as a fallback for missing PSFrac. Keeping the fallback but omitting the redundant basket requests removes precisely 478 baskets, 5,863,481 compressed bytes and 23,144,134 serialized bytes in full and nominal runs. The two nominal timing cohorts missed the spread limit and cannot establish a nominal speedup. The focused fixtures cover missing PSFrac and both fields absent. Sources ../evidence/timing/m22/full-logical-root-requests.json and ../evidence/timing/m22/summary.json.'
    Add-Table $s @(@('Same original events','Read both fields','Use the fallback'),@('ROOT leaves','224','223'),@('Compressed basket bytes','75.60 MB','69.74 MB'),@('Five-state file to histogram','3.330 ± 0.022 s','3.255 ± 0.037 s')) 46 103 865 272 @(337,261,267) 20
    $null = New-Label $s 'Removing 7.8% of the compressed input reduced the complete five-state time by 2.27%.' 49 415 855 66 23 $blue

    $s = New-ContentSlide 'How Many Events per Chunk?' 'The same wheel and input read 20,000 events in ten, four or two chunks. In the first comparison, 5,000 events per chunk also reduced nominal time by 16.46%. In the independent second comparison the 5,000-event control ran again. Both full cohorts and nominal cohorts qualified in both comparisons. Empty, partial and over-length requests produced identical saved outputs. The 10,000-event option cost about 73 MiB more peak resident memory for no observed gain. Sources ../evidence/timing/m23/summary.json and ../evidence/timing/m23/five-to-ten-thousand.json.'
    Add-Table $s @(@('Entries per chunk','Full elapsed [s]','Peak RSS [MiB]'),@('2,000 → 5,000','3.278 → 2.809','430 → 471'),@('5,000 → 10,000','2.788 → 2.794','471 → 544')) 50 118 854 223 @(287,295,272) 23
    $null = New-Label $s 'Use 5,000 events per chunk. Four chunks per file reduced repeated reader and preparation calls.' 52 388 850 89 24 $blue

    $s = New-ContentSlide 'The Same Draw Appears in Four Variations' 'Stock reseeds before each active variation and uses the first Gaussian. Both scale states consume it too. The standalone correction caches the first value by effective seed within a single event. A missing or changed seed still invokes the same generator. Full, nominal and the correlated diagnostic match the original values and decisions. The nominal workflow has no draw. Its point estimate was 1.37% slower, with substantial paired scatter. Sources ../evidence/timing/m03/full-draws.json and ../evidence/timing/m03/summary.json.'
    Add-Table $s @(@('Full, 20,000 events','Original calculation','With per-event reuse'),@('Requested Gaussian values','80,000','80,000'),@('Physical first draws','80,000','20,000'),@('File to histogram','2.717 ± 0.048 s','2.657 ± 0.029 s')) 48 102 862 277 @(305,275,282) 20
    $null = New-Label $s 'All four state values and the correlated diagnostic reproduce the stock stream.' 50 419 855 64 23 $blue

    $s = New-ContentSlide 'Index the Linked Values in Their Original Arrays' 'The retained simple scalar field path borrows contiguous original values when the owner offsets match and bounds are proven. Optional or vector-valued fields use the generic gather. In one 5,000-event chunk all 146 prepared buffers matched that general route. The full-file numerical and decision checks used independent stock AnalysisBase observations. The preceding change cached calorimeter sampling buffers across electron and photon views, constructing eight buffers for 80 uses. Sources ../evidence/timing/m26/linked-scalar-layout-5000.json, ../evidence/timing/m24/sampling-path.json and ../evidence/timing/m26/summary.json.'
    Add-Table $s @(@('One 5,000-event chunk','Observed transfer'),@('Simple scalar gathers','81 calls, 258,792 linked rows'),@('Existing storage borrowed','4.10 MB'),@('All 146 prepared columns','Exact agreement with the general gather')) 47 104 865 266 @(358,507) 21
    $null = New-Label $s 'With four chunks per file, the five-state time fell from 2.578 to 2.531 s.' 49 417 847 70 23 $blue

    $s = New-ContentSlide 'Check Jet Track Offsets Once per Chunk' 'Each jet has a variable-length list of track counts. The offset array gives each list boundary. The adapter validated a whole immutable chunk at the start of each event. A checked view can instead live until the end of the chunk. Empty, malformed and boundary checks still run at the original first use. The source-derived adjacent comparison count fell from 983,030,000 to 196,606. An instrumented three-chunk run separately observed one constructor per chunk. All three primary full pairs improved. The reverse-order full candidate failed the spread screens. Sources ../evidence/offset-final/trial/paired-primary.json and ../evidence/offset-final/trial/paired-order-reversed.json.'
    Add-Table $s @(@('20,000 events in four chunks','Per event','Once per chunk'),@('Checks of the whole array','20,000','4'),@('Adjacent comparisons','983,030,000','196,606'),@('Five-state elapsed time','2.684 ± 0.099 s','2.488 ± 0.115 s')) 47 104 865 264 @(355,255,255) 20
    $null = New-Label $s 'The primary full comparison saved 7.28%. Nominal passed in both measurement orders.' 49 411 850 68 22 $blue

    $s = New-ContentSlide 'The Faithful Five-State Comparison' 'The framework budget compares the ntuple-writing legs. Stock took 21.745 s and the replacement 21.825 s. The 1.004 ratio passed the 1.20 budget for five states. The end-to-end A/C ratio is 5.483. Each number is the mean and sample standard deviation of three retained production runs, with a separate warm-up. All full endpoints passed the original process and variability screens. In that faithful cohort, nominal and stored stock-relative timings were inconclusive. Source ../evidence/timing/matched-repeat/summary.json.'
    Add-Table $s @(@('Original file to saved histogram','Elapsed time [s]'),@('Stock AnalysisBase','21.990 ± 0.416'),@('CorrectionLib in AnalysisBase','22.077 ± 0.397'),@('Standalone Python','4.011 ± 0.026')) 56 108 843 274 @(516,327) 23
    $null = New-Label $s 'Framework-only B/A = 1.004.  Complete stock-to-standalone speedup = 5.48×.' 56 412 844 71 22 $blue

    $s = New-ContentSlide 'The Delivered Analysis Runs 8.99 Times Faster' 'All three start from the original 20,000-event file. The measured endpoints include startup, reading, nominal selections, the applicable MET calculation and saved histogram. The displayed values are means and sample standard deviations after one warm-up and three retained runs on CPU 0. All full endpoints qualified. The same-session B/A adoption ratio through the written ntuple was 1.0112. The separate stored-input control qualifies at 11.10×. During stock nominal warm-up, Cling launched a compiler to find its include paths before processing the first event. All three retained runs passed, but the process check covers all four launches and disqualifies the nominal stock ratios. The five-state goal was 10×. Source ../evidence/offset-final/timing/summary.json.'
    Add-Table $s @(@('Saved histogram','Stock A [s]','Framework B [s]','Standalone C [s]'),@('Five states','22.685 ± 0.458','22.939 ± 0.451','2.525 ± 0.042'),@('Nominal','19.709 ± 0.158*','19.855 ± 0.139','2.235 ± 0.007'),@('Stored core term','5.484 ± 0.146','—','0.494 ± 0.011')) 43 108 875 270 @(215,211,220,229) 19
    $null = New-Label $s '* Stock nominal failed the process check. The separate stored-term control qualified at 11.10×.' 48 390 855 55 18 $ink
    $null = New-Label $s 'Faithful C took 4.134 s in the same cohort. The delivered C saves 38.9%.' 48 453 855 47 21 $blue

    $s = New-ContentSlide 'Reading PHYSLITE Is the Largest Remaining Cost' 'The shipped default is 5,000 events per chunk and four native calls cover the file. The phase-timed five-state process took 2.457 seconds, compared with 2.490 seconds in an adjacent run without instrumentation. The reading time includes the original branch values and association decoding. The nominal and full runs request the same original data. The 0.216-second projection row excludes time in nominal correction nodes. Source ../evidence/offset-final/profile-5000/phase/full-phase-receipt.json.'
    Add-Table $s @(@('Five states, 20,000 original events','Exclusive time'),@('Read and decode the original fields','1.293 s'),@('Gather nominal linked inputs','0.216 s'),@('Evaluate all MET states','0.416 s')) 58 113 830 259 @(557,273) 22
    $null = New-Label $s 'The reader requested 69.74 MB in compressed baskets, or 3.487 KB per event.' 60 405 835 78 22 $blue

    $s = New-ContentSlide 'Running the Installed Analysis' 'The visible script and adjacent wheel form the local demonstration. The separate original PHYSLITE file is required, as are the pinned public Python dependencies. In an installed Linux CPython 3.14 environment, the command shown runs the default four MET variations and nominal on the supplied file. It writes the state axis, bin edges, counts, sum of weights and squared weights including flows. The wheel includes CorrectionLib and its loaded native dependencies; the final pip and uv installations were checked. The report gives the complete tested script and install commands. Sources ../evidence/offset-final/package/bundle.json and ../evidence/offset-final/package/installed-identities.json.'
    $null = New-Label $s 'From the installed Linux CPython 3.14 environment' 52 118 850 49 24 $blue
    $sample = New-Label $s 'taskset -c 0 python met_demo.py "$INPUT" met-full.npz' 54 198 850 70 21 $ink
    $sample.TextFrame.TextRange.Font.Name = 'Consolas'
    $null = New-Label $s 'The 2.411 MB wheel contains the MET code, calibration data and CorrectionLib evaluator. The input is the original 20,000-event PHYSLITE file.' 52 307 847 139 25 $ink

    $bundleLink = New-Label $s 'Open the offline distribution' 52 452 410 40 17 $blue
    $bundleAction = $bundleLink.ActionSettings.Item(1)
    $bundleAction.Action = 7
    $bundleAction.Hyperlink.Address = '../standalone-offset/met-standalone-cp314-linux-x86_64.zip'
    $reportLink = New-Label $s 'Read the full analysis and script' 480 452 424 40 17 $blue
    $reportAction = $reportLink.ActionSettings.Item(1)
    $reportAction.Action = 7
    $reportAction.Hyperlink.Address = '../report.md'

    $s = New-ContentSlide 'Where This Result Applies' 'On this 20,000-event mc23a FullSim file, the direct reader and release paths agree in every MET term, association and Final significance quantity that we compared. The input objects and selections are nominal in every MET state. New production layouts need checks on signal-object identities, memberwise links and the nominal preparation tools. One proposed follow-up is to gather vector-valued covariance inputs from original buffers and check their missing-value and link semantics. Another is to test a nested jet track-vector decoder across basket boundaries and more than one file. Source ../report.md.'
    Add-Table $s @(@('Scope','What the measurements support'),@('Physics','Tight particle-flow MET and significance on 20,000 top-pair events, with four soft-term variations.'),@('Transfer to another production','Recheck the collection keys, nominal selections, resolutions and persisted link layout.'),@('Next performance test','Measure vector-valued linked inputs and nested jet track decoding on additional files.')) 48 102 861 318 @(264,597) 21

    $s = New-ContentSlide 'Which Systematic States Run?' 'The correlated resolution is affecting but not recommended in this initialization. It uses one draw shared between the parallel and perpendicular components and is checked in a separate full-file configuration. Sources: ../evidence/intake/release-probe-summary.json and ../evidence/reference/status/corr-verification.json.'
    Add-Table $s @(@('Configuration','States'),@('Production','Nominal, scale up, scale down, parallel resolution, perpendicular resolution'),@('Separate diagnostic','Nominal and correlated resolution'),@('Deferred physics','Propagation of upstream jet, lepton, photon and tau uncertainties')) 48 108 860 279 @(244,616) 21
    $backupStart = $s.SlideIndex
    $s = New-ContentSlide 'Matched Timing for Each Optimization Trial' 'Each control was measured again alongside its candidate, starting from the original file and saving the full five-state histogram. The bars are sample standard deviations of three retained measurements. An open marker denotes a timing series that failed its screen, including the order-reversed full offset candidate. The hard-term reuse recheck and larger chunk were not retained. The grouped association pilot measured the reader only and therefore has no endpoint row. The final cumulative comparison was measured separately. Source ../optimization-trials.json.'
    Add-Figure $s (Join-Path $reportDir 'figures/optimization-times.png') 23 80 914 422
    $s = New-ContentSlide 'Why We Repeated the Initial Stock Timing' 'Each workload has four runs, with the first excluded by the frozen protocol. The three retained values shown include the framework process and a separate histogram process. Both ran single-threaded, fixed to CPU 0. The three full framework legs averaged 27.539 s, plus 0.343 s for histogramming. No A/C speedup can be quoted from this series. Source: ../evidence/reference/stock-timing-summary.json.'
    Add-Table $s @(@('A workload','Three retained totals [s]','Relative SD'),@('Stored track core','6.169, 8.056, 5.944','17.3%'),@('Nominal Final MET','32.949, 23.079, 25.831','18.7%'),@('Five MET states','28.880, 30.460, 24.308','11.5%')) 48 111 860 254 @(234,404,222) 21
    $null = New-Label $s 'The agreed limit is 5% relative sample standard deviation and 10% maximum deviation from the median.' 50 391 855 88 23 $ink
    $s = New-ContentSlide 'Agreement Across the Five Framework States' 'Each entry is the largest absolute paired event discrepancy across the applicable MET terms. The first five rows cover all eight terms, the last four the Final term. Angular differences are wrapped. Source: ../evidence/components/framework-full/plot-summary.json.'
    Add-Figure $s (Join-Path $reportDir 'figures/framework/all-states.png') 22 94 916 389
    foreach ($item in @(
        @('Cartesian x Component by MET Term','nominal-mpx'),
        @('Cartesian y Component by MET Term','nominal-mpy'),
        @('Scalar Transverse Energy by MET Term','nominal-sumet'),
        @('Missing Momentum Magnitude by Term','nominal-met'),
        @('Azimuth by MET Term','nominal-phi'),
        @('Final Significance and Activity','nominal-significance'),
        @('How Each Variation Moves Final MET','responses-final-met'),
        @('Agreement Across the Five Standalone States','all-states')
    )) {
        $notes = 'The line shows stock AnalysisBase and the markers show standalone Python on the same 20,000 original events. Overlays have unit weights. Their lower panels are standalone minus stock in events per bin. The summary table gives the maximum absolute paired event difference in each state. Source data: ../evidence/offset-final/acceptance/full/plot-summary.json. Flow and nonfinite counts: ../figures/columnar/counts.json.'
        $s = New-ContentSlide $item[0] $notes
        Add-Figure $s (Join-Path $reportDir ('figures/columnar/' + $item[1] + '.png')) 20 86 920 406
    }
    $s = New-ContentSlide 'Framework Time Through the Written Ntuple' 'The adoption budget of B/A ≤ 1.20 refers only to the first leg. In the final full cohort both framework legs and both histogram legs passed. The final full B/A framework-only ratio was 1.0112. The stock nominal leg failed the process screen. The earlier full comparison of the same binary independently gave 1.0037. Sources ../evidence/offset-final/timing/summary.json and ../evidence/timing/matched-repeat/summary.json.'
    Add-Table $s @(@('Framework leg','Stock A [s]','Replacement B [s]','B/A'),@('Final nominal','19.449 ± 0.164*','19.599 ± 0.137','—'),@('Final five states','22.421 ± 0.459','22.672 ± 0.447','1.011'),@('Earlier five states','21.745 ± 0.420','21.825 ± 0.410','1.004')) 43 107 875 278 @(235,223,257,160) 18
    $null = New-Label $s '* Stock nominal failed the process screen. Both measured full ratios met the 20% budget.' 50 406 850 76 21 $ink
    $s = New-ContentSlide 'What the Native Profile Can Resolve' 'The final sustained profile used the shipped wheel for 34 passes over 20,000 unique events, or 680,000 event visits. Each pass reset state, reopened the file and checked its histogram. CPU-clock at 99 Hz produced 7,716 in-window samples in 78.359 s elapsed and 78.322 s worker CPU. CPU 0 ran the analysis, CPU 1 collected. A leaf is the instruction that was executing. Stack attribution could not identify the workflow stage for 80.17% of samples. Hardware cycles and instructions were unavailable. Source ../evidence/offset-final/profile-5000/native/summary.json.'
    Add-Table $s @(@('Named instruction sampled','Exclusive CPU share'),@('Validate jagged offsets','7.62% before → 0.065% after'),@('Awkward Forth decoding','4.15%'),@('glibc allocation / memory move','3.21% / 3.01%'),@('MET maker / first Gaussian','1.75% / 0.79%')) 53 107 852 293 @(490,362) 20
    $null = New-Label $s '57% of sampled leaves were unresolved. The phase timers measure reading and MET computation separately.' 54 418 849 70 20 $blue
    $s = New-ContentSlide 'What the CorrectionLib Nodes Exchange' 'The Python bridge starts with the original association map and prepared nominal objects. The AnalysisBase adapter supplies equivalent typed views. The maker node returns ordered terms with links and weights. Soft-term evaluation looks up the recoil, jet count and pile-up in the exported tables. The Final node sums the selected term vectors in stock order. Significance calls the object-resolution providers and rotates each contribution about the varied Final direction. The standalone bridge returns all eight terms and four significance quantities and Python fills the histograms. Sources ../report.md and ../inspection/components/soft/provider.cxx.'
    Add-Table $s @(@('Operation called from either adapter','Values returned'),@('Maker on selected objects and associations','Ordered terms with constituent links and weights'),@('Soft correction on recoil and pile-up','Varied soft vector from the shift or smearing table'),@('Final sum on the selected terms','Missing momentum vector and scalar sum'),@('Significance on the varied Final direction','Covariance-based significance and related quantities')) 47 101 867 329 @(443,424) 19
    $null = $deck.SectionProperties.AddBeforeSlide(1, 'MET')
    $null = $deck.SectionProperties.AddBeforeSlide($backupStart, 'Backup')
    $deck.SaveAs($deckPath,24)
    $deck.Export($renderDir,'PNG',1440,810)
    Write-Output "Saved $($deck.Slides.Count) slides in $deckPath"
} finally {
    $deck.Close()
    if ($before -eq 0 -and $app.Presentations.Count -eq 0) { $app.Quit() }
}
