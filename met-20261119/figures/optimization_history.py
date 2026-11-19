# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.9,<4", "numpy>=1.26", "typer>=0.12,<1"]
# ///
"""Show matched full-workflow timings for each MET optimization trial."""

import json
from pathlib import Path

import matplotlib
import typer

matplotlib.use("Agg")
from matplotlib import pyplot as plt
from matplotlib.lines import Line2D


def main(register: Path, output: Path) -> None:
    trials = json.loads(register.read_bytes())["trials"]
    fig, ax = plt.subplots(figsize=(9.2, max(2.8, 1.5 + 0.56 * len(trials))),
                           layout="constrained")
    labels = []
    for i, trial in enumerate(trials):
        record = json.loads((register.parent / trial["timing"]).read_bytes())
        group = record["results"]["full"]
        control = group[trial["control"]]
        candidate = group[trial["candidate"]]
        labels.append(trial["label"])
        ax.plot([control["mean"], candidate["mean"]], [i, i], color="#9ba5ac", lw=2)
        for label, row, color, marker in [("Control", control, "#233e5b", "o"),
                                          ("Candidate", candidate, "#ad5129", "s")]:
            ax.errorbar(row["mean"], i, xerr=row["sample_sd"], marker=marker,
                        ms=7, color=color, elinewidth=1.1, capsize=4,
                        markerfacecolor=color if row["qualified"] else "white",
                        zorder=3 if label == "Candidate" else 2)
    ax.set_yticks(range(len(labels)), labels)
    ax.set_ylim(len(labels) - 0.5, -0.5)
    ax.set_xlabel("Seconds from original PHYSLITE to saved five-state histogram")
    ax.grid(axis="x", alpha=0.2)
    ax.set_axisbelow(True)
    ax.tick_params(axis="y", length=0, pad=8)
    ax.spines[["top", "right", "left"]].set_visible(False)
    handles = [Line2D([], [], marker=m, color=c, linestyle="", label=l)
               for m, c, l in [("o", "#233e5b", "Control"), ("s", "#ad5129", "Candidate")]]
    ax.legend(handles=handles, frameon=False, ncol=2, loc="lower right",
              bbox_to_anchor=(1.0, 1.0))
    fig.savefig(output, dpi=165)
    plt.close(fig)


if __name__ == "__main__":
    typer.run(main)
