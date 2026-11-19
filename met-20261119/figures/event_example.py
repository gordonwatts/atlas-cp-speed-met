# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.9,<4", "typer>=0.12,<1"]
# ///
"""Plot a stock event's term vectors and the four changes in Final MET."""

import json
from pathlib import Path

import matplotlib
import typer

matplotlib.use("Agg")
from matplotlib import pyplot as plt
from matplotlib.patches import FancyArrowPatch


def render(source: Path, output: Path):
    event = json.loads(source.read_text(encoding="utf-8"))
    states = {
        state: {row["name"]: row for row in rows}
        for state, rows in event["states"].items()
    }
    nominal = states["NOSYS"]
    styles = {
        "RefEle": ("Electrons", "#346f9a"), "RefGamma": ("Photons", "#8560a0"),
        "RefTau": ("Taus", "#9f486a"), "Muons": ("Muons", "#574b90"),
        "MuonEloss": ("Muon energy loss", "#8f7651"), "RefJet": ("Jets", "#c46a28"),
        "PVSoftTrk": ("Track soft term", "#208571"),
    }
    names = {
        "MET_SoftTrk_Scale__1up": "Scale up",
        "MET_SoftTrk_Scale__1down": "Scale down",
        "MET_SoftTrk_ResoPara": "Parallel resolution",
        "MET_SoftTrk_ResoPerp": "Perpendicular resolution",
    }
    fig, (plane, shifts) = plt.subplots(
        1, 2, figsize=(11, 4.8), gridspec_kw={"width_ratios": [1.05, 1.1], "wspace": 0.46}
    )
    origin = (0.0, 0.0)
    points = [origin]
    for term, row in nominal.items():
        if term == "Final" or (row["mpx"] == 0 and row["mpy"] == 0):
            continue
        end = (origin[0] + row["mpx"] / 1000, origin[1] + row["mpy"] / 1000)
        label, color = styles[term]
        plane.quiver(*origin, end[0] - origin[0], end[1] - origin[1],
                     angles="xy", scale_units="xy", scale=1, color=color,
                     width=0.009, headwidth=3.8, headlength=5.0, zorder=3)
        plane.plot([], [], color=color, lw=2.3, label=label)
        points.append(end)
        origin = end
    final = nominal["Final"]
    plane.add_patch(FancyArrowPatch((0, 0), (final["mpx"]/1000, final["mpy"]/1000),
                                    arrowstyle="-|>", mutation_scale=15, color="#303b43",
                                    lw=1.4, linestyle="--", shrinkA=0, shrinkB=0, zorder=2))
    plane.plot([], [], color="#303b43", lw=1.4, ls="--", label="Final MET")
    plane.update_datalim(points)
    plane.autoscale_view()
    plane.margins(x=0.24, y=0.15)
    plane.set(aspect="equal", xlabel=r"$p_x^{\rm miss}$ [GeV]", ylabel=r"$p_y^{\rm miss}$ [GeV]")
    plane.axvline(0, color="#cfdae0", lw=0.9)
    plane.axhline(0, color="#cfdae0", lw=0.9)
    plane.legend(loc="upper left", frameon=False, fontsize=9)
    plane.set_title("Nominal term vectors", loc="left", weight="bold", pad=10)

    shift_range = 0.001
    for y, state in enumerate(names):
        shift = (states[state]["Final"]["met"] - final["met"]) / 1000
        shift_range = max(shift_range, abs(shift))
        shifts.plot([0, shift], [y, y], color="#346f9a", lw=2.3)
        shifts.plot(shift, y, "o", ms=7, color="#346f9a")
        shifts.annotate(f"{shift:+.3f}", (shift, y), xytext=(0, 11),
                        textcoords="offset points", ha="center", fontsize=10)
    shifts.axvline(0, color="#677780", lw=1.0, zorder=0)
    shifts.set(xlim=(-1.32 * shift_range, 1.32 * shift_range), ylim=(3.45, -0.65),
               yticks=range(len(names)), yticklabels=names.values(),
               xlabel="Change in Final MET magnitude [GeV]")
    shifts.set_title("Soft-term variations", loc="left", weight="bold", pad=10)
    for ax in (plane, shifts):
        ax.spines[["top", "right"]].set_visible(False)
        ax.tick_params(labelsize=10)
    fig.suptitle(f"Stock AnalysisBase   ·   event {event['eventNumber']}   ·   nominal Final MET {final['met']/1000:.2f} GeV",
                 x=0.04, ha="left", y=0.99, fontsize=13)
    fig.subplots_adjust(left=0.08, right=0.98, bottom=0.16, top=0.80)
    fig.savefig(output, dpi=180, facecolor="white", bbox_inches="tight")
    plt.close(fig)


if __name__ == "__main__":
    typer.run(render)
