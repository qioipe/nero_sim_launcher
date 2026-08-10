# Nero 仿真一键启动工程

面向 Ubuntu 22.04 + ROS2 Humble + `~/agx_ws`（`agx_arm_sim`）的一键脚本，覆盖：

- RViz 显示 Nero  
- MoveIt 规划仿真（`nero_gripper_moveit_config`）  
- 录制 `/joint_states`  
- bag → CSV（`q/qd/qdd`）  
- 关节角曲线图  

## 目录

```text
nero_sim_launcher/
├── start.sh                 # 一键入口（菜单 / 子命令）
├── config/env.sh            # 路径与包名配置
├── scripts/
│   ├── check_env.sh
│   ├── start_rviz.sh
│   ├── start_moveit.sh
│   ├── record_joints.sh
│   ├── bag_to_csv.py
│   └── plot_q.py
└── README.md
```

## 安装到虚拟机

在 **Windows 主机** 把本目录拷到虚拟机，例如：

```bash
# 虚拟机内
mkdir -p ~/tools
# 用共享文件夹 / scp / U 盘拷贝到:
# ~/tools/nero_sim_launcher

cd ~/tools/nero_sim_launcher
chmod +x start.sh scripts/*.sh scripts/*.py
# 若从 Windows 拷贝出现 $'\r' 错误，执行:
sed -i 's/\r$//' start.sh config/env.sh scripts/*.sh
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

### 常用一键命令

```bash
./start.sh check          # 检查环境
./start.sh moveit         # 启动 MoveIt（主流程）
./start.sh rviz           # 仅 RViz 显示
./start.sh record         # 另开终端录 bag（MoveIt 先开着）
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
