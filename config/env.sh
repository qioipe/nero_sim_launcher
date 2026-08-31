#!/usr/bin/env bash
# Nero 仿真环境变量（按需修改）

export ROS_DISTRO="${ROS_DISTRO:-humble}"
export AGX_WS="${AGX_WS:-$HOME/agx_ws}"
export NERO_DATA_DIR="${NERO_DATA_DIR:-$HOME/nero_data}"
export NERO_ARM_TYPE="${NERO_ARM_TYPE:-nero}"
export NERO_EE="${NERO_EE:-gripper}"

# 包名：你当前编译结果是 nero_gripper_moveit_config
export NERO_MOVEIT_PKG="${NERO_MOVEIT_PKG:-nero_gripper_moveit_config}"
export NERO_MOVEIT_LAUNCH="${NERO_MOVEIT_LAUNCH:-demo.launch.py}"
export NERO_TOPCAM_TOPIC="${NERO_TOPCAM_TOPIC:-/top_camera/image_raw}"
export NERO_IMAGE_DIR="${NERO_IMAGE_DIR:-$HOME/nero_data/topdown_images}"

source_ros() {
  # ROS setup.bash 会读取未定义变量；在 set -u 下必须临时关闭 nounset
  set +u
  if [[ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]]; then
    # shellcheck disable=SC1090
    source "/opt/ros/${ROS_DISTRO}/setup.bash"
  else
    set -u
    echo "[错误] 未找到 /opt/ros/${ROS_DISTRO}/setup.bash"
    exit 1
  fi
  if [[ -f "${AGX_WS}/install/setup.bash" ]]; then
    # shellcheck disable=SC1090
    source "${AGX_WS}/install/setup.bash"
  else
    set -u
    echo "[错误] 未找到 ${AGX_WS}/install/setup.bash，请先编译 agx_ws"
    exit 1
  fi
  set -u
}

ensure_data_dir() {
  mkdir -p "${NERO_DATA_DIR}"
}
