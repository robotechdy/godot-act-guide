# Godot ACT Guide

面向有 Unity 开发经验的开发者，以知识迁移为主线学习 Godot，最终逐步形成 3D 动作游戏开发指南。
课程目录与实施状态见 [index.md](index.md)。当前是轻量教程工程，已提供两章可运行示例。

## 开始

使用 Godot 标准版 **4.7.2 stable**，精确版本见 [.godot-version](.godot-version)。本机通过 godotenv 安装并设为默认版本。

```bash
just check
just editor
```

`godot` 和 `just` 需在 PATH 中。也可以用 `GODOT_BIN="/path/to/Godot" just editor` 指定可执行文件。
没有 just 时，直接用对应版本的 Godot 打开 `project.godot`。

### 从编辑器运行与观察

在编辑器右上的运行工具栏操作，悬停图标可查看命令名：

- **Run Project**（三角形播放按钮，默认 F5）：运行项目主场景 `game/main/main.tscn`，从课程目录进入章节。
- **Run Current Scene**（带播放符号的场记板，默认 F6）：运行当前选中的场景 tab。独立运行教程时，先在 FileSystem 双击该章的 `chapter.tscn`，确认顶部选中它。
- **Stop**（方形按钮）：停止当前运行，再选择需要的运行方式。Mac 上可以直接点这些按钮，无需使用功能键。

进入章节后，运行界面底部的 **Reset** 重新创建当前章节，**Back to list** 返回课程目录。
独立运行章节时没有这组公共导航，停止后再次运行即可重置。Reset 不会撤销文件修改。

要观察运行对象，回到启动这次运行的编辑器，在 **Scene** 面板切到 **Remote**；**Local** 显示当前编辑场景。
运行实例和 Local 编辑对象是不同的对象。顶部场景 tab 切换的是编辑上下文，不会因此改变 Remote 中正在运行的章节。
也可以用 `just run` 单独预览课程，但它不会自动连接编辑器调试器；需要 Remote 时使用上面的编辑器运行方式。

## 编辑器中的场景与视图

本项目带有 Scene Layout 插件。启用时，中央区域的两行选择器是：

```text
[main] [chapter] [actor] [+]       已打开的场景
[2D] [3D]        [Script] [Game] [Asset Store]
```

| 控件 | 作用 |
| --- | --- |
| 顶部场景 tabs | 选择当前编辑场景，决定 Local 树与 Run Current Scene 的目标；它们不是脚本文档 tabs |
| 2D / 3D | 编辑当前场景的空间或 UI 视图 |
| Script | 跨场景共享的脚本文档编辑器，在其文档列表里选择 `.gd`；不会给每个场景建立独立的脚本列表 |
| Game | 查看当前游戏运行会话；它不是 Run Project 按钮，也不是当前场景 tab 的自动预览 |
| Asset Store | 跨场景共享的资源商店 |

例如顶部选中 `chapter.tscn`，Script 仍可能显示 `actor.gd`；应分别确认场景名和脚本文档名。
插件在本次会话内记住各场景选中的中央视图，工具内容仍共享。Game 使用浮动窗口时，中央区域会回到之前的视图。
在 **Project → Project Settings → Plugins → Scene Layout** 可启停插件；停用后恢复原生排列，教程中的命令与面板名称仍适用。

### 本机的文档与场景切换键

本机已在 Godot 原生 **Editor → Editor Settings → Shortcuts** 中交换以下键位：

| 操作 | 本机键位（macOS） | Godot 默认键位（macOS） |
| --- | --- | --- |
| 下／上一个 Script 文档 | Ctrl+Tab / Ctrl+Shift+Tab | ⌘⇧. / ⌘⇧, |
| 下／上一个场景 tab | ⌘⇧. / ⌘⇧, | Ctrl+Tab / Ctrl+Shift+Tab |

Script 文档切换在 Script 编辑器可见时生效，文档列表也可能包含帮助页。这是全局编辑器偏好，
不是插件改键，也不会随仓库复制到另一台机器；教程操作以上述命令名为准。

## 当前内容

- [01 场景树、实例与生命周期](game/tutorials/01_scene_tree/README.md)：创建、移出、重新加入和销毁节点子树。
- [02 脚本复用与节点组合](game/tutorials/02_scripts_and_composition/README.md)：同一脚本资源、多份独立实例、子节点职责拆分和信号。

`game/main/` 是运行目录；各章的场景、脚本与说明位于 `game/tutorials/`。
初期用 Compatibility 渲染器，专注对象与场景机制；后续渲染章节再比较渲染方案。
本项目未套用正式 3D ACT 工程模板。Python、发布构建与测试框架尚无需求；MCP 可在需要现场演示时单独配置。

## 初始化验证

2026-11-07 使用 Godot 4.7 stable 完成导入、headless 行为检查，以及 Apple M4 / Compatibility 的图形运行与画面检查。
验证了节点身份与生命周期、移出节点的清理、两个计数器的状态隔离、信号更新、章节重置与独立加载。
检查通过临时脚本触发按钮完成；未将验证脚本或测试框架加入课程工程。

该引擎在首次 `--editor --quit` 快速退出时发生过崩溃；改为等待导入和编辑器初始化完成后退出，通过检查。
需要命令行导入时可用 `godot --headless --path . --editor --quit-after 90`，并检查日志；正常 `just editor` 不使用快速退出参数。
