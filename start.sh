#!/usr/bin/env bash
# Nero 仿真一键入口
# 用法:
#   ./start.sh              # 交互菜单
#   ./start.sh moveit       # 直接启动 MoveIt
#   ./start.sh rviz
#   ./start.sh record
#   ./start.sh convert <bag目录>
#   ./start.sh plot <csv>
#   ./start.sh gazebo-cam       # 仅顶视桌面
#   ./start.sh gazebo-arm       # Gazebo + Nero 机械臂（可视化）
#   ./start.sh collect [张数]
#   ./start.sh randomize [轮数]
#   ./start.sh check

set -eo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="${ROOT}/scripts"

# 若从 Windows 拷贝导致 CRLF，尝试修正自身与子脚本（需要 dos2unix 或 sed）
fix_crlf() {
  if grep -q $'\r' "$1" 2>/dev/null; then
    sed -i 's/\r$//' "$1" || true
  fi
}
fix_crlf "${ROOT}/start.sh"
fix_crlf "${ROOT}/config/env.sh"
for f in "${SCRIPTS}"/*.sh; do
  [[ -f "$f" ]] && fix_crlf "$f"
done

chmod +x "${ROOT}/start.sh" "${SCRIPTS}"/*.sh "${SCRIPTS}"/*.py 2>/dev/null || true

run_cmd() {
  local cmd="$1"
  shift || true
  case "$cmd" in
    check)  bash "${SCRIPTS}/check_env.sh" ;;
    rviz)   bash "${SCRIPTS}/start_rviz.sh" ;;
    moveit) bash "${SCRIPTS}/start_moveit.sh" ;;
    record) bash "${SCRIPTS}/record_joints.sh" ;;
    convert)
      if [[ $# -lt 1 ]]; then
        echo "用法: ./start.sh convert ~/nero_data/nero_bag_xxx"
        exit 1
      fi
      # shellcheck disable=SC1091
      source "${ROOT}/config/env.sh"
      source_ros
      python3 "${SCRIPTS}/bag_to_csv.py" "$@"
      ;;
    plot)
      if [[ $# -lt 1 ]]; then
        echo "用法: ./start.sh plot ~/nero_data/xxx_q.csv"
        exit 1
      fi
      python3 "${SCRIPTS}/plot_q.py" "$@"
      ;;
    gazebo-cam|topcam)
      bash "${SCRIPTS}/start_gazebo_topcam.sh" "${1:-0}"
      ;;
    gazebo-arm|gazebo)
      # 带 Nero 机械臂的 Gazebo 可视化（顶视世界 + MoveIt）
      bash "${SCRIPTS}/start_gazebo_topcam.sh" arm
      ;;
    collect)
      # shellcheck disable=SC1091
      source "${ROOT}/config/env.sh"
      source_ros
      count="${1:-50}"
      python3 "${SCRIPTS}/collect_topdown_images.py" \
        --auto-topic \
        -n "${count}" \
        -o "${NERO_IMAGE_DIR}/$(date +%Y%m%d_%H%M%S)"
      ;;
    randomize)
      # shellcheck disable=SC1091
      source "${ROOT}/config/env.sh"
      source_ros
      python3 "${SCRIPTS}/randomize_table_objects.py" --rounds "${1:-20}"
      ;;
    help|-h|--help)
      sed -n '2,16p' "$0"
      ;;
    *)
      echo "未知命令: $cmd"
      echo "支持: check | rviz | moveit | record | convert | plot | gazebo-cam | gazebo-arm | collect | randomize"
      exit 1
      ;;
  esac
}

if [[ $# -ge 1 ]]; then
  run_cmd "$@"
  exit $?
fi

echo "======================================"
echo "  Nero 仿真一键启动"
echo "  工作空间: 见 config/env.sh"
echo "======================================"
echo "  1) 环境检查"
echo "  2) 启动 RViz 显示 Nero"
echo "  3) 启动 MoveIt 规划仿真   ← 常用"
echo "  4) 录制 /joint_states"
echo "  5) bag 转 CSV"
echo "  6) 绘制关节角曲线"
echo "  7) 启动 Gazebo 顶视桌面（无臂，采图）"
echo "  8) 启动 Gazebo + Nero 机械臂（可视化）"
echo "  9) 采集顶视图片"
echo "  a) 随机摆放桌面物体"
echo "  0) 退出"
echo "======================================"
read -r -p "请选择 [0-9/a]: " choice

case "$choice" in
  1) run_cmd check ;;
  2) run_cmd rviz ;;
  3) run_cmd moveit ;;
  4) run_cmd record ;;
  5)
    read -r -p "bag 目录路径: " bag
    run_cmd convert "$bag"
    ;;
  6)
    read -r -p "csv 路径: " csv
    run_cmd plot "$csv"
    ;;
  7) run_cmd gazebo-cam ;;
  8) run_cmd gazebo-arm ;;
  9)
    read -r -p "采集张数 [50]: " n
    run_cmd collect "${n:-50}"
    ;;
  a|A) run_cmd randomize ;;
  0) exit 0 ;;
  *) echo "无效选项"; exit 1 ;;
esac
