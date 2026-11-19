# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.9,<4", "typer>=0.12,<1"]
# ///
"""Draw the stock MET spectrum and the change in yield for the four variations."""

import json
from pathlib import Path

import matplotlib
import numpy as np
import typer

matplotlib.use("Agg")
from matplotlib import pyplot as plt


def render(source: Path, output: Path) -> None:
    data = json.loads(source.read_text(encoding="utf-8"))
    if not data["histogram_counts_sumw_sumw2_exact"] or not data["reference_equals_production_per_event"]:
        raise ValueError("The production histogram must pass the stock reference checks.")
    edges = np.asarray(data["bin_edges_GeV"])
    counts = data["per_state_counts"]
    nominal = np.asarray(counts["NOSYS"])[1:-1]
    colors = {
        "MET_SoftTrk_ResoPara": ("Parallel resolution", "#4978a8", "-"),
        "MET_SoftTrk_ResoPerp": ("Perpendicular resolution", "#5c4697", "--"),
        "MET_SoftTrk_Scale__1up": ("Scale up", "#c06521", "-"),
        "MET_SoftTrk_Scale__1down": ("Scale down", "#008478", "--"),
    }
    fig, (spectrum, changes) = plt.subplots(
        2, 1, sharex=True, figsize=(9.6, 5.8), layout="constrained",
        gridspec_kw={"height_ratios": [1.35, 1]},
    )
    spectrum.stairs(nominal, edges, color="#284963", linewidth=1.7, baseline=None)
    spectrum.set(yscale="log", ylim=(0.65, 2400), ylabel="Events per 5 GeV")
    spectrum.set_title("Final missing transverse momentum", loc="left", weight="bold")
    under, over = data["per_state_flows"]["NOSYS"]
    spectrum.text(0.98, 0.95,
                  f"Stock AnalysisBase 25.2.117\n{sum(counts['NOSYS']):,} events\n"
                  f"Nominal flows   {under} below, {over} above",
                  ha="right", va="top", transform=spectrum.transAxes, fontsize=10)
    changes.axhline(0, color="#65757f", linewidth=0.8)
    for key, (label, color, linestyle) in colors.items():
        delta = np.asarray(counts[key])[1:-1] - nominal
        changes.stairs(delta, edges, color=color, linestyle=linestyle,
                       label=label, linewidth=1.25, baseline=None)
    changes.set(xlim=(edges[0], edges[-1]), ylabel="Change in events per bin",
                xlabel="Final missing transverse momentum [GeV]")
    changes.legend(ncol=2, loc="upper right", frameon=False, fontsize=9)
    for axis in (spectrum, changes):
        axis.spines[["right", "top"]].set_visible(False)
        axis.grid(axis="y", which="major", alpha=0.15)
    fig.savefig(output, dpi=170, facecolor="white")
    plt.close(fig)


if __name__ == "__main__":
    typer.run(render)
