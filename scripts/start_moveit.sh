#!/usr/bin/env bash
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/config/env.sh"
source_ros

echo "[启动] MoveIt  ${NERO_MOVEIT_PKG}/${NERO_MOVEIT_LAUNCH}"
if ! ros2 pkg prefix "${NERO_MOVEIT_PKG}" >/dev/null 2>&1; then
  echo "[错误] 找不到包 ${NERO_MOVEIT_PKG}"
  echo "可用包："
  ros2 pkg list | grep -iE 'nero|moveit_config' || true
  exit 1
fi
exec ros2 launch "${NERO_MOVEIT_PKG}" "${NERO_MOVEIT_LAUNCH}"
