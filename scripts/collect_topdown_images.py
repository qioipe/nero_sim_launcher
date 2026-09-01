#!/usr/bin/env python3
"""订阅 Gazebo 顶视相机，保存 PNG 用于后续训练。"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path


def _find_image_topic(preferred: str) -> str:
    import rclpy
    from rclpy.node import Node
    from sensor_msgs.msg import Image

    rclpy.init()
    node = Node("topcam_topic_probe")
    deadline = time.time() + 8.0
    names = set()
    while time.time() < deadline:
        for name, types in node.get_topic_names_and_types():
            if "sensor_msgs/msg/Image" in types or "sensor_msgs/Image" in types:
                names.add(name)
        if preferred in names:
            node.destroy_node()
            rclpy.shutdown()
            return preferred
        time.sleep(0.4)
    node.destroy_node()
    rclpy.shutdown()
    for n in sorted(names):
        if "image" in n and "top" in n:
            return n
    for n in sorted(names):
        if n.endswith("image_raw"):
            return n
    raise RuntimeError(
        "未找到图像话题。请先启动 ./start.sh gazebo-cam，再检查: ros2 topic list | grep image"
    )


def main() -> int:
    p = argparse.ArgumentParser(description="采集 Gazebo 顶视 RGB 图")
    p.add_argument("-o", "--outdir", type=Path, default=None, help="输出目录")
    p.add_argument("-t", "--topic", default="/top_camera/image_raw")
    p.add_argument("-n", "--count", type=int, default=50, help="保存帧数，0 表示一直采直到 Ctrl+C")
    p.add_argument("--hz", type=float, default=2.0, help="保存频率（Hz），避免连续重复帧")
    p.add_argument("--auto-topic", action="store_true", help="自动探测 image 话题")
    args = p.parse_args()

    outdir = args.outdir
    if outdir is None:
        stamp = time.strftime("%Y%m%d_%H%M%S")
        outdir = Path.home() / "nero_data" / "topdown_images" / stamp
    outdir = outdir.expanduser().resolve()
    outdir.mkdir(parents=True, exist_ok=True)

    topic = args.topic
    if args.auto_topic:
        print("[探测] 图像话题...")
        topic = _find_image_topic(args.topic)
        print(f"[探测] 使用 {topic}")

    import rclpy
    from cv_bridge import CvBridge
    from rclpy.node import Node
    from sensor_msgs.msg import Image
    import cv2

    saved = {"n": 0, "done": False}
    last_t = [0.0]
    min_dt = 1.0 / max(args.hz, 0.1)
    bridge = CvBridge()

    def cb(msg: Image) -> None:
        if saved["done"]:
            return
        now = time.monotonic()
        if now - last_t[0] < min_dt:
            return
        last_t[0] = now
        try:
            img = bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")
        except Exception as e:
            print(f"[警告] cv_bridge 失败: {e}", file=sys.stderr)
            return
        idx = saved["n"]
        path = outdir / f"frame_{idx:05d}.png"
        cv2.imwrite(str(path), img)
        meta = {
            "file": path.name,
            "topic": topic,
            "stamp_sec": int(msg.header.stamp.sec),
            "stamp_nsec": int(msg.header.stamp.nanosec),
            "width": int(msg.width),
            "height": int(msg.height),
        }
        with open(outdir / f"frame_{idx:05d}.json", "w", encoding="utf-8") as f:
            json.dump(meta, f, ensure_ascii=False, indent=2)
        saved["n"] += 1
        print(f"[保存] {path}  ({saved['n']})")
        if args.count > 0 and saved["n"] >= args.count:
            saved["done"] = True

    rclpy.init()
    node = Node("collect_topdown_images")
    node.create_subscription(Image, topic, cb, 10)
    print(f"[订阅] {topic}")
    print(f"[输出] {outdir}")
    print("按 Ctrl+C 结束" if args.count <= 0 else f"目标 {args.count} 张")
    try:
        while rclpy.ok() and not saved["done"]:
            rclpy.spin_once(node, timeout_sec=0.2)
    except KeyboardInterrupt:
        pass
    node.destroy_node()
    if rclpy.ok():
        rclpy.shutdown()
    print(f"[完成] 共 {saved['n']} 张 -> {outdir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
