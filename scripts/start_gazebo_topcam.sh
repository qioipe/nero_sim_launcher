#!/usr/bin/env bash
# 启动带顶视相机的 Gazebo 桌面场景（可选同时加载 Nero）
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/config/env.sh"
source_ros

WORLD="${ROOT}/gazebo/worlds/tabletop_topdown.world"
WITH_ARM="${1:-${NERO_TOPCAM_WITH_ARM:-0}}"

if [[ ! -f "$WORLD" ]]; then
  echo "[错误] 找不到世界文件: $WORLD"
  exit 1
fi

echo "[启动] Gazebo 顶视桌面场景"
echo "  world = $WORLD"
echo "  图像话题通常为 /top_camera/image_raw 或 /top_camera/top_camera/image_raw"
echo "  另开终端运行: ./start.sh collect"

if [[ "$WITH_ARM" == "1" || "$WITH_ARM" == "arm" ]]; then
  echo "[模式] Gazebo + MoveIt（Nero）+ 自定义顶视世界"
  exec ros2 launch "${NERO_MOVEIT_PKG}" gazebo_moveit.launch.py \
    "world:=${WORLD}" \
    "use_sim_time:=true"
fi

# 仅场景：不加载机械臂，适合先采物体/桌面图
exec ros2 launch gazebo_ros gazebo.launch.py \
  "world:=${WORLD}" \
  "gui:=true"
