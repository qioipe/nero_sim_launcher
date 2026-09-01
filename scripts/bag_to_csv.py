#!/usr/bin/env python3
"""将 nero rosbag2 (/joint_states) 转为 t,q1..q7,qd,qdd CSV。"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np


def convert(bag_path: Path, out_csv: Path) -> int:
    from rclpy.serialization import deserialize_message
    from rosidl_runtime_py.utilities import get_message
    import rosbag2_py

    reader = rosbag2_py.SequentialReader()
    reader.open(
        rosbag2_py.StorageOptions(uri=str(bag_path), storage_id="sqlite3"),
        rosbag2_py.ConverterOptions("", ""),
    )
    topic_types = {t.name: t.type for t in reader.get_all_topics_and_types()}
    if "/joint_states" not in topic_types:
        raise RuntimeError(f"bag 中无 /joint_states: {list(topic_types)}")

    msg_type = get_message(topic_types["/joint_states"])
    arm_names = [f"joint{i}" for i in range(1, 8)]
    rows = []
    while reader.has_next():
        topic, data, _t_ns = reader.read_next()
        if topic != "/joint_states":
            continue
        msg = deserialize_message(data, msg_type)
        idx = {n: i for i, n in enumerate(msg.name)}
        if not all(n in idx for n in arm_names):
            continue
        q = [float(msg.position[idx[n]]) for n in arm_names]
        t = float(msg.header.stamp.sec + msg.header.stamp.nanosec * 1e-9)
        rows.append([t] + q)

    if not rows:
        raise RuntimeError("未解析到有效 joint1..joint7 数据")

    arr = np.asarray(rows, dtype=np.float64)
    dt = np.diff(arr[:, 0], prepend=arr[0, 0])
    dt[dt == 0] = np.nan
    qd = np.vstack([np.zeros((1, 7)), np.diff(arr[:, 1:8], axis=0) / dt[1:, None]])
    qdd = np.vstack([np.zeros((1, 7)), np.diff(qd, axis=0) / dt[1:, None]])
    qd = np.nan_to_num(qd)
    qdd = np.nan_to_num(qdd)

    header = (
        "t,"
        + ",".join(f"q{i}" for i in range(1, 8))
        + ","
        + ",".join(f"qd{i}" for i in range(1, 8))
        + ","
        + ",".join(f"qdd{i}" for i in range(1, 8))
    )
    out = np.hstack([arr, qd, qdd])
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(out_csv, out, delimiter=",", header=header, comments="")
    return len(out)


def main() -> int:
    p = argparse.ArgumentParser(description="rosbag2 /joint_states -> CSV")
    p.add_argument("bag", type=Path, help="rosbag2 目录，如 ~/nero_data/nero_moveit1")
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="输出 csv（默认：bag 同级 <bag名>_q.csv）",
    )
    args = p.parse_args()
    bag = args.bag.expanduser().resolve()
    out = args.output.expanduser().resolve() if args.output else bag.parent / f"{bag.name}_q.csv"
    try:
        n = convert(bag, out)
    except Exception as e:
        print(f"[错误] {e}", file=sys.stderr)
        return 1
    print(f"[完成] {out}  rows={n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
