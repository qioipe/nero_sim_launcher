#!/usr/bin/env python3
"""绘制 nero_*_q.csv 的 7 关节角曲线。"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("csv", type=Path)
    p.add_argument("-o", "--output", type=Path, default=None)
    args = p.parse_args()

    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    csv_path = args.csv.expanduser().resolve()
    d = np.loadtxt(csv_path, delimiter=",", skiprows=1)
    t = d[:, 0] - d[0, 0]
    fig, axes = plt.subplots(4, 2, figsize=(10, 8), sharex=True)
    axes = axes.ravel()
    for i in range(7):
        axes[i].plot(t, d[:, 1 + i])
        axes[i].set_ylabel(f"q{i+1} [rad]")
        axes[i].grid(True, alpha=0.3)
    axes[7].axis("off")
    axes[6].set_xlabel("t [s]")
    axes[5].set_xlabel("t [s]")
    fig.suptitle(csv_path.name)
    fig.tight_layout()
    out = args.output or csv_path.with_suffix(".png")
    fig.savefig(out, dpi=140)
    print(f"[完成] {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
