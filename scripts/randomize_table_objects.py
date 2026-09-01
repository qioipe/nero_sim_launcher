#!/usr/bin/env python3
"""随机摆放桌面上的占位物体，便于采集多样化训练图。"""

from __future__ import annotations

import argparse
import math
import random
import time

from geometry_msgs.msg import Pose
from gazebo_msgs.srv import SetEntityState
from gazebo_msgs.msg import EntityState
import rclpy
from rclpy.node import Node


OBJECTS = ("obj_red_cube", "obj_green_cylinder", "obj_blue_box", "obj_yellow_sphere")


def yaw_to_quat(yaw: float):
    return (0.0, 0.0, math.sin(yaw / 2.0), math.cos(yaw / 2.0))


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--rounds", type=int, default=20, help="随机摆放轮数")
    p.add_argument("--sleep", type=float, default=0.6, help="每轮间隔秒")
    p.add_argument("--x-min", type=float, default=0.22)
    p.add_argument("--x-max", type=float, default=0.68)
    p.add_argument("--y-min", type=float, default=-0.22)
    p.add_argument("--y-max", type=float, default=0.22)
    p.add_argument("--z", type=float, default=0.80, help="物体中心高度（略高于桌面 0.75）")
    args = p.parse_args()

    rclpy.init()
    node = Node("randomize_table_objects")
    cli = node.create_client(SetEntityState, "/gazebo/set_entity_state")
    if not cli.wait_for_service(timeout_sec=8.0):
        print("[错误] 等不到 /gazebo/set_entity_state，请先启动 Gazebo")
        rclpy.shutdown()
        return 1

    for r in range(args.rounds):
        print(f"[随机] 第 {r + 1}/{args.rounds} 轮")
        for name in OBJECTS:
            pose = Pose()
            pose.position.x = random.uniform(args.x_min, args.x_max)
            pose.position.y = random.uniform(args.y_min, args.y_max)
            pose.position.z = args.z
            qx, qy, qz, qw = yaw_to_quat(random.uniform(-math.pi, math.pi))
            pose.orientation.x = qx
            pose.orientation.y = qy
            pose.orientation.z = qz
            pose.orientation.w = qw
            req = SetEntityState.Request()
            req.state = EntityState()
            req.state.name = name
            req.state.pose = pose
            req.state.reference_frame = "world"
            fut = cli.call_async(req)
            rclpy.spin_until_future_complete(node, fut, timeout_sec=2.0)
        time.sleep(args.sleep)

    node.destroy_node()
    rclpy.shutdown()
    print("[完成] 随机摆放结束")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
