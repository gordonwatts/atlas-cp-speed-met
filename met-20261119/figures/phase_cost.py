# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.9,<4", "numpy>=1.26", "typer>=0.12,<1"]
# ///
"""Plot exclusive production phases from a matched MET diagnostic."""

import json
from pathlib import Path

import matplotlib
import typer

matplotlib.use("Agg")
from matplotlib import pyplot as plt


def main(evidence: Path, output: Path) -> None:
    records = json.loads((evidence / "summary.json").read_bytes())
    names = [
        "Read and decode ROOT branches", "Gather nominal object inputs",
        "Evaluate MET states", "Open file and select branches",
        "Import packages and initialize", "Other work and process lifetime",
    ]
    fig, ax = plt.subplots(figsize=(9.0, 4.4), layout="constrained")
    for scope, offset, color, label in [
        ("nominal", -0.18, "#65889c", "Nominal"),
        ("full", 0.18, "#a64f29", "Five states"),
    ]:
        receipt = json.loads((evidence / f"{scope}-phase-receipt.json").read_bytes())
        elapsed = {k: row["wall_ns"] / 1e9 for k, row in receipt["exclusive"].items()}
        total = records[scope]["phase_timed"]["process"]["wall_ns"] / 1e9
        values = [
            elapsed["input_read_decode"], elapsed["nominal_projection"],
            elapsed["shared_event_evaluation"], elapsed["open_original"] + elapsed["input_metadata"],
            elapsed["imports"] + elapsed["initialize"],
        ]
        values.append(total - sum(values))
        bars = ax.barh([idx + offset for idx in range(len(names))], values,
                       height=0.31, color=color, label=label)
        ax.bar_label(bars, fmt="%.2f", fontsize=9, padding=3)
    ax.set_yticks(range(len(names)), names)
    ax.invert_yaxis()
    ax.set_xlabel("Exclusive elapsed time per 20,000 original events [s]")
    ax.set_xlim(left=0, right=ax.get_xlim()[1] * 1.05)
    ax.tick_params(axis="y", length=0, pad=8)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.xaxis.grid(True, alpha=0.18)
    ax.set_axisbelow(True)
    ax.legend(loc="lower right", frameon=False)
    fig.savefig(output, dpi=160)
    plt.close(fig)


if __name__ == "__main__":
    typer.run(main)
