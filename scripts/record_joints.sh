#!/usr/bin/env bash
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/config/env.sh"
source_ros
ensure_data_dir

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="${NERO_DATA_DIR}/nero_bag_${STAMP}"

echo "[录制] /joint_states -> ${OUT}"
echo "请先确保 MoveIt/RViz 已在运行；录制中请 Plan & Execute。"
echo "按 Ctrl+C 结束录制。"
exec ros2 bag record -o "${OUT}" /joint_states
