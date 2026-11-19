# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.9,<4", "numpy>=1.26", "typer>=0.12,<1"]
# ///
"""Render MET overlays from the matched event comparisons made in WSL."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import matplotlib
import numpy as np
import typer

matplotlib.use("Agg")
from matplotlib import pyplot as plt
from matplotlib.lines import Line2D


LABELS = {
    "mpx": "$p_x^{\\mathrm{miss}}$ [GeV]",
    "mpy": "$p_y^{\\mathrm{miss}}$ [GeV]",
    "sumet": "$\\Sigma E_{\\mathrm{T}}$ [GeV]",
    "met": "$E_{\\mathrm{T}}^{\\mathrm{miss}}$ [GeV]",
    "phi": "$\\phi$ [rad]",
    "significance": "MET significance",
    "sigDirectional": "Directional significance",
    "METOverSqrtSumET": "$E_{\\mathrm{T}}^{\\mathrm{miss}}/\\sqrt{\\Sigma E_{\\mathrm{T}}}$ [$\\sqrt{\\mathrm{GeV}}$]",
    "METOverSqrtHT": "$E_{\\mathrm{T}}^{\\mathrm{miss}}/\\sqrt{H_{\\mathrm{T}}}$ [$\\sqrt{\\mathrm{GeV}}$]",
}
STATES = {
    "NOSYS": "Nominal",
    "MET_SoftTrk_ResoPara": "Parallel resolution",
    "MET_SoftTrk_ResoPerp": "Perpendicular resolution",
    "MET_SoftTrk_Scale__1down": "Scale down",
    "MET_SoftTrk_Scale__1up": "Scale up",
    "MET_SoftTrk_ResoCorr": "Correlated resolution",
}
STOCK_COLOR = "#233e5b"
CANDIDATE_COLOR = "#ac5129"
FINAL_LABELS = {
    "significance": "Significance", "sigDirectional": "Directional significance",
    "METOverSqrtSumET": "Scalar transverse energy", "METOverSqrtHT": "Hard activity",
}


def factor(field: str) -> float:
    return 0.001 if field in ("mpx", "mpy", "met", "sumet") else 1.0


def make_panel(figure, slot, data, report, field, term, state, path, response=False, single=False):
    inner = slot.subgridspec(2, 1, height_ratios=[3, 1], hspace=0.08)
    top = figure.add_subplot(inner[0])
    bottom = figure.add_subplot(inner[1], sharex=top)
    state_id = report["states"].index(state)
    term_id = report["fields"][field]["terms"].index(term)
    suffix = "_delta" if response else ""
    edges = data[f"{field}{suffix}_edges"] * factor(field)
    a = data[f"{field}_a{suffix}"][state_id, term_id]
    c = data[f"{field}_candidate{suffix}"][state_id, term_id]
    centers = (edges[1:] + edges[:-1]) / 2
    if len(a) != len(edges) + 1 or a.shape != c.shape:
        raise ValueError(f"Inconsistent histogram dimensions for {field} {term}.")
    top.stairs(a[1:-1], edges, color=STOCK_COLOR, linewidth=1.25, baseline=None)
    populated = c[1:-1] > 0
    top.plot(centers[populated], c[1:-1][populated], linestyle="none", marker="o",
             markersize=2.9, markeredgewidth=0.6, fillstyle="none", color=CANDIDATE_COLOR)
    ymax = max(int(np.max(a[1:-1])), int(np.max(c[1:-1])), 1)
    top.set(yscale="log", ylim=(0.7, max(4.0, ymax * 2.3)), ylabel="Events / bin")
    title = STATES[state] if response else FINAL_LABELS.get(field, term)
    if not single:
        top.set_title(title, loc="left", fontsize=11, weight="bold")
    for ax in (top, bottom):
        ax.spines[["right", "top"]].set_visible(False)
        ax.grid(axis="y", color="#bbc3ca", alpha=0.35, linewidth=0.6)
        ax.tick_params(labelsize=8)
    top.tick_params(axis="x", which="both", bottom=False, labelbottom=False)
    residual = c[1:-1] - a[1:-1]
    limit = max(1, int(np.max(abs(residual))))
    bottom.axhline(0, color="#7b8790", linewidth=0.9)
    bottom.stairs(residual, edges, color=CANDIDATE_COLOR, linewidth=1.0, baseline=None, zorder=3)
    bottom.set(xlim=(edges[0], edges[-1]), ylim=(-1.3 * limit, 1.3 * limit),
               ylabel=f"{path} − A", xlabel=("Shift in " if response else "") + LABELS[field])
    bottom.set_yticks([-limit, 0, limit])
    return {
        "field": field, "term": term, "state": state, "response_to_nominal": response,
        "a_under_over_nonfinite": [int(a[0]), int(a[-1]), report["events"] - int(a.sum())],
        "candidate_under_over_nonfinite": [int(c[0]), int(c[-1]), report["events"] - int(c.sum())],
        "max_absolute_bin_count_difference_including_flows": int(np.max(abs(c - a))),
    }


def overlay(data, report, panels, title, path, output, response=False):
    cols = min(4, len(panels))
    rows = (len(panels) + cols - 1) // cols
    single = len(panels) == 1
    fig = plt.figure(figsize=(7.9 if single else 3.7 * cols, (4.4 if single else 3.3 * rows) + 1.15))
    fig.subplots_adjust(left=0.11 if single else 0.065, right=0.968 if single else 0.977,
                        bottom=0.18 if single else (0.14 if rows == 1 else 0.09),
                        top=0.835 if single else (0.77 if rows == 1 else 0.85))
    grid = fig.add_gridspec(rows, cols, hspace=0.72, wspace=0.45)
    stats = [make_panel(fig, grid[i], data, report, field, term, state, path, response, single)
             for i, (field, term, state) in enumerate(panels)]
    fig.suptitle(title, x=0.035, y=0.99, ha="left", fontsize=16, weight="bold", color=STOCK_COLOR)
    legend = [Line2D([], [], color=STOCK_COLOR, label="A  ·  ATLAS CP tools"),
              Line2D([], [], marker="o", markersize=5, markerfacecolor="none", linestyle="none",
                     color=CANDIDATE_COLOR, label=f"{path}  ·  " + ("Standalone Python" if path == "C" else "AnalysisBase replacement"))]
    fig.legend(handles=legend, loc="upper left", bbox_to_anchor=(0.03, 0.95), frameon=False, ncol=2, fontsize=9)
    caption = f"{report['events']:,} matched events per panel. Unit weights. Residual in events per bin."
    if single:
        af = stats[0]["a_under_over_nonfinite"]
        cf = stats[0]["candidate_under_over_nonfinite"]
        caption += f"\nUnderflow / overflow / nonfinite   A  {af[0]} / {af[1]} / {af[2]}     {path}  {cf[0]} / {cf[1]} / {cf[2]}"
    fig.text(0.035, 0.01, caption, fontsize=8.5, color="#43505b")
    fig.savefig(output, dpi=150, facecolor="white")
    plt.close(fig)
    return stats


def state_summary(report, path, output):
    from matplotlib.table import Table

    states = report["states"]
    fig, ax = plt.subplots(figsize=(max(9.2, 1.6 * len(states) + 2.4), 4.9))
    fig.subplots_adjust(left=0.025, right=0.985, top=0.79, bottom=0.11)
    ax.axis("off")
    fig.suptitle(f"Maximum event-level difference  |{path} − A|", x=0.03, y=0.97,
                 ha="left", fontsize=16, weight="bold", color=STOCK_COLOR)
    fig.text(0.03, 0.867, f"{report['events']:,} events. Maximum over the finite values of every applicable MET term.",
             fontsize=10)
    table = Table(ax, bbox=[0, 0, 1, 1])
    fields = list(LABELS)
    cell_height = 1 / (len(fields) + 1)
    col_width = 0.74 / len(states)
    for i, row in enumerate([None, *fields]):
        title = "Observable" if row is None else LABELS[row]
        table.add_cell(i, 0, 0.26, cell_height, text=title, loc="left",
                       facecolor="#e2eaf0" if i == 0 else "#f3f6f8", edgecolor="white")
        for j, state in enumerate(states, 1):
            if row is None:
                value = STATES[state].replace(" resolution", "\nresolution")
            else:
                groups = report["fields"][row]["comparison"][state]["residual"]
                maxima = [g["max_absolute"] for g in groups if g["finite"]]
                value = f"{max(maxima) * factor(row):.3g}" if maxima else "—"
            table.add_cell(i, j, col_width, cell_height, text=value, loc="center",
                           facecolor="#e2eaf0" if i == 0 else ("#f3f6f8" if i % 2 else "white"), edgecolor="white")
    table.auto_set_font_size(False)
    table.set_fontsize(9)
    ax.add_table(table)
    fig.text(0.03, 0.038, "Azimuthal differences are wrapped. The accompanying counts record flows and nonfinite values.",
             fontsize=9, color="#43505b")
    fig.savefig(output, dpi=150, facecolor="white")
    plt.close(fig)


def render(distributions: Path, comparisons: Path, output_dir: Path, path: str = "C",
           package_manifest: Path | None = None):
    """Make nominal term panels, systematic responses, and the all-state comparison."""
    if path not in ("B", "C"):
        raise typer.BadParameter("Supply B for AnalysisBase or C for standalone Python.")
    output_dir.mkdir(parents=True, exist_ok=True)
    report = json.loads(comparisons.read_text(encoding="utf-8"))
    sizes = {term["finite"] + term["nonfinite"]
             for field in report["fields"].values()
             for state in field["comparison"].values()
             for term in state["residual"]}
    if len(sizes) != 1:
        raise ValueError("The event counts differ between the saved term or state comparisons.")
    events = sizes.pop()
    if report.setdefault("events", events) != events:
        raise ValueError("The reported event count differs from the saved comparisons.")
    plotted = {}
    with np.load(distributions, allow_pickle=False) as data:
        states = report["states"]
        if states != data["states"].tolist() or report["terms"] != data["terms"].tolist() or states[0] != "NOSYS":
            raise ValueError("The state or term axes differ between the two input files.")
        def draw(name, panels, title, response=False):
            plotted[name] = overlay(data, report, panels, title, path, output_dir / f"{name}.png", response)
        for field, info in report["fields"].items():
            if len(info["terms"]) > 1:
                draw(f"nominal-{field}", [(field, t, "NOSYS") for t in info["terms"]],
                     f"Nominal MET terms   ·   {LABELS[field]}")
        finals = [f for f in LABELS if report["fields"][f]["terms"] == ["Final"]]
        draw("nominal-significance", [(f, "Final", "NOSYS") for f in finals], "Nominal Final MET significance and activity")
        draw("nominal-final-met", [("met", "Final", "NOSYS")], "Nominal Final missing transverse momentum")
        if len(states) > 1:
            draw("responses-final-met", [("met", "Final", s) for s in states[1:]],
                 "Change in Final missing transverse momentum from nominal", True)
    state_summary(report, path, output_dir / "all-states.png")
    manifest = {"candidate": path, "events": report["events"], "states": states,
                "input_sha256": {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in (distributions, comparisons)},
                "panels": plotted}
    if package_manifest is not None:
        package = json.loads(package_manifest.read_bytes())
        manifest["wheel"] = package["wheel"]
        manifest["wheel_sha256"] = package["wheel_sha256"]
    (output_dir / "counts.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    typer.run(render)
