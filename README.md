# Godot ACT Guide

面向有 Unity 开发经验的开发者，以知识迁移为主线学习 Godot，最终逐步形成 3D 动作游戏开发指南。
课程目录与实施状态见 [index.md](index.md)。当前是轻量教程工程，已提供两章可运行示例。

## 开始

使用 Godot 标准版 **4.7 stable**，精确版本见 [.godot-version](.godot-version)。本机已有该版本，因此初始化没有升级引擎。

```bash
just check
just editor
just run
```

`godot` 和 `just` 需在 PATH 中。也可以用 `GODOT_BIN="/path/to/Godot" just editor` 指定可执行文件。
没有 just 时，直接用对应版本的 Godot 打开 `project.godot`。

F5 运行课程目录；进入章节后，底部 Reset 重新创建当前章节，Back to list 返回目录。
在编辑器打开具体章节的 `.tscn` 后按 F6，可独立运行该章。Reset 不会撤销已保存的文件修改。

## 当前内容

- [01 场景树、实例与生命周期](game/tutorials/01_scene_tree/README.md)：创建、移出、重新加入和销毁节点子树。
- [02 脚本复用与节点组合](game/tutorials/02_scripts_and_composition/README.md)：同一脚本资源、多份独立实例、子节点职责拆分和信号。

`game/main/` 是运行目录；各章的场景、脚本与说明位于 `game/tutorials/`。
初期用 Compatibility 渲染器，专注对象与场景机制；后续渲染章节再比较渲染方案。
本项目未套用正式 3D ACT 工程模板。Python、发布构建与测试框架尚无需求；MCP 可在需要现场演示时单独配置。

## 初始化验证

2026-11-07 使用上述 Godot 版本完成导入、headless 行为检查，以及 Apple M4 / Compatibility 的图形运行与画面检查。
验证了节点身份与生命周期、移出节点的清理、两个计数器的状态隔离、信号更新、章节重置与独立加载。
检查通过临时脚本触发按钮完成；未将验证脚本或测试框架加入课程工程。

该引擎在首次 `--editor --quit` 快速退出时发生过崩溃；改为等待导入和编辑器初始化完成后退出，通过检查。
需要命令行导入时可用 `godot --headless --path . --editor --quit-after 90`，并检查日志；正常 `just editor` 不使用快速退出参数。
