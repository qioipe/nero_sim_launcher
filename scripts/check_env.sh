#!/usr/bin/env bash
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/config/env.sh"

echo "==== Nero 仿真环境检查 ===="
echo "ROS_DISTRO     = ${ROS_DISTRO}"
echo "AGX_WS         = ${AGX_WS}"
echo "NERO_DATA_DIR  = ${NERO_DATA_DIR}"
echo "MOVEIT_PKG     = ${NERO_MOVEIT_PKG}"
echo

ok=1
[[ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]] && echo "[OK] ROS2" || { echo "[NG] ROS2"; ok=0; }
[[ -f "${AGX_WS}/install/setup.bash" ]] && echo "[OK] agx_ws" || { echo "[NG] agx_ws"; ok=0; }

if [[ -f "/opt/ros/${ROS_DISTRO}/setup.bash" && -f "${AGX_WS}/install/setup.bash" ]]; then
  # shellcheck disable=SC1090
  source "/opt/ros/${ROS_DISTRO}/setup.bash"
  # shellcheck disable=SC1090
  source "${AGX_WS}/install/setup.bash"
  if ros2 pkg prefix agx_arm_description >/dev/null 2>&1; then
    echo "[OK] agx_arm_description"
  else
    echo "[NG] agx_arm_description"
    ok=0
  fi
  if ros2 pkg prefix "${NERO_MOVEIT_PKG}" >/dev/null 2>&1; then
    echo "[OK] ${NERO_MOVEIT_PKG}"
  else
    echo "[NG] ${NERO_MOVEIT_PKG}"
    ok=0
  fi
fi

python3 -c "import numpy" 2>/dev/null && echo "[OK] numpy" || echo "[NG] numpy (pip3 install --user numpy)"
command -v ros2 >/dev/null && echo "[OK] ros2 CLI" || echo "[提示] source 后才有 ros2"

echo
[[ "$ok" == "1" ]] && echo "环境可用。" || echo "环境有缺失，请按提示修复。"
exit $((1 - ok))
