# Nero 仿真一键启动工程

面向 Ubuntu 22.04 + ROS2 Humble + `~/agx_ws`（`agx_arm_sim`）的一键脚本，覆盖：

- RViz 显示 Nero  
- MoveIt 规划仿真（`nero_gripper_moveit_config`）  
- 录制 `/joint_states`  
- bag → CSV（`q/qd/qdd`）  
- 关节角曲线图
- **Gazebo 顶视相机采图**（桌面场景，供视觉模型训练）
- **Gazebo + Nero 机械臂可视化**（`./start.sh gazebo-arm`）

## 目录

```text
nero_sim_launcher/
├── start.sh
├── config/env.sh
├── gazebo/worlds/tabletop_topdown.world
├── scripts/
│   ├── ...
│   ├── start_gazebo_topcam.sh
│   ├── collect_topdown_images.py
│   └── randomize_table_objects.py
└── README.md
```

## 仓库

GitHub：https://github.com/qioipe/nero_sim_launcher

## 安装到虚拟机（推荐 git clone）

```bash
mkdir -p ~/tools
cd ~/tools

# 若以前是手动拷贝的目录，先备份再删，避免混用
# mv nero_sim_launcher nero_sim_launcher.bak

git clone https://github.com/qioipe/nero_sim_launcher.git
cd nero_sim_launcher
chmod +x start.sh scripts/*.sh scripts/*.py
```

之后在虚拟机更新：

```bash
cd ~/tools/nero_sim_launcher
git pull
chmod +x start.sh scripts/*.sh scripts/*.py
```

主机改代码后推送：

```bash
cd nero_sim_launcher
git add -A && git commit -m "your message" && git push
```

按需编辑 `config/env.sh`：

```bash
AGX_WS=$HOME/agx_ws
NERO_MOVEIT_PKG=nero_gripper_moveit_config
NERO_DATA_DIR=$HOME/nero_data
```

依赖：已编译好的 `~/agx_ws`，以及：

```bash
pip3 install --user numpy matplotlib
```

## 用法

### 交互菜单

```bash
cd ~/tools/nero_sim_launcher
./start.sh
```

### 顶视相机采图（Gazebo）

先装：

```bash
sudo apt install -y ros-humble-gazebo-ros-pkgs ros-humble-gazebo-ros2-control ros-humble-cv-bridge
```

虚拟机内存建议 ≥8GB。

```bash
# 终端 A：开场景（桌子 + 彩色物体 + 顶视相机）
./start.sh gazebo-cam

# 终端 B：采 50 张 PNG
./start.sh collect 50

# 可选：随机挪动物体再采
./start.sh randomize 30
```

带 Nero 机械臂可视化（Gazebo + MoveIt + RViz，更吃内存）：

```bash
./start.sh gazebo-arm
# 等价于: ./start.sh gazebo-cam arm
# 菜单选 8 也可
```

图片默认写到 `~/nero_data/topdown_images/<时间戳>/frame_xxxxx.png`。

**对齐真实环境**：用尺子量桌面长宽高、相机离桌高度、视野里有哪些物体，改  
`gazebo/worlds/tabletop_topdown.world` 里 `work_table` 的 `size/pose` 和 `topdown_camera` 的高度。占位物体可换成真机对应的 mesh。仿真图只能作预训练/域随机；上真机仍需少量真实顶视图做微调。

### 常用一键命令

```bash
./start.sh check          # 检查环境
./start.sh moveit         # 启动 MoveIt（主流程）
./start.sh rviz           # 仅 RViz 显示
./start.sh record         # 另开终端录 bag（MoveIt 先开着）
./start.sh gazebo-cam     # Gazebo 顶视桌面（无臂）
./start.sh gazebo-arm     # Gazebo + Nero 机械臂可视化
./start.sh collect 50     # 保存顶视 PNG
./start.sh randomize 20   # 随机摆物体
./start.sh convert ~/nero_data/nero_bag_20260101_120000
./start.sh plot ~/nero_data/nero_bag_xxx_q.csv
```

### 推荐操作顺序

1. 终端 A：`./start.sh moveit`  
2. 在 RViz 中 Plan & Execute  
3. 终端 B：`./start.sh record`，动臂后 Ctrl+C  
4. `./start.sh convert <刚生成的 bag 目录>`  
5. `./start.sh plot <生成的 csv>`  

## 说明

- 当前 MoveIt demo 的 `effort` 常为 `nan`，CSV 中的 `qd/qdd` 由位置差分得到，**不能当作完整逆动力学训练集**。  
- 完整力矩标签需 MuJoCo/Gazebo 或真机。  
- 算法阶段可继续使用 BaxterRand / iCub 公开集。  

## License

MIT（脚本工程）
