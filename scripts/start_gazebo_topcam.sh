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
  echo "[模式] Gazebo + Nero 机械臂可视化（MoveIt + 顶视世界）"
  echo "  包: ${NERO_MOVEIT_PKG}/gazebo_moveit.launch.py"
  echo "  建议内存 ≥8GB；启动后可用 RViz Plan & Execute，并另开终端采图"
  if ! ros2 pkg prefix "${NERO_MOVEIT_PKG}" >/dev/null 2>&1; then
    echo "[错误] 找不到包 ${NERO_MOVEIT_PKG}"
    echo "可用包："
    ros2 pkg list | grep -iE 'nero|moveit_config' || true
    exit 1
  fi
  if ! ros2 pkg prefix gazebo_ros >/dev/null 2>&1; then
    echo "[错误] 找不到 gazebo_ros，请安装: sudo apt install -y ros-humble-gazebo-ros-pkgs"
    exit 1
  fi
  exec ros2 launch "${NERO_MOVEIT_PKG}" gazebo_moveit.launch.py \
    "world:=${WORLD}" \
    "use_sim_time:=true" \
    "use_rviz:=true" \
    "gui:=true"
fi

# 仅场景：不加载机械臂，适合先采物体/桌面图
echo "[模式] 仅顶视桌面（无 Nero 臂）"
exec ros2 launch gazebo_ros gazebo.launch.py \
  "world:=${WORLD}" \
  "gui:=true"
