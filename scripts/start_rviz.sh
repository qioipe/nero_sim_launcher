#!/usr/bin/env bash
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/config/env.sh"
source_ros

echo "[启动] RViz 显示 Nero  arm_type=${NERO_ARM_TYPE} ee=${NERO_EE}"
exec ros2 launch agx_arm_description display.launch.py \
  "arm_type:=${NERO_ARM_TYPE}" \
  "end_effector:=${NERO_EE}"
