# 02 脚本复用、实例状态与节点组合

目标：把“脚本文件是一份可复用的类定义”与“Node 上的实例状态”分开理解，
再用一个极小的例子观察 Godot 如何拆分职责。

## 操作与预期结果

在编辑器打开并选中本章的 [chapter.tscn](chapter.tscn)，点右上 **Run Current Scene**（默认 F6）；
也可以点 **Run Project**（默认 F5），从课程目录进入本章。按钮与布局说明见 [项目 README](../../../README.md#从编辑器运行与观察)。

1. 两个计数器初始都为 0。点击 A 的 **+1** 三次，应得到 A=3、B=0。
2. 点击 B 的 **+1** 一次，再点 A 的 **Reset this counter**，应得到 A=0、B=1。
3. 观察身份说明：`Same counter.gd resource: true`，但 `Same Node instance: false`，两份 State 的 ID 也不同。
4. 保持游戏运行，在编辑器打开 [counter.tscn](counter.tscn)，切到 **Scene → Local** 检查：根 PanelContainer 使用 `counter.gd`，State 子 Node 使用 `counter_state.gd`。这是源场景，顶部切换到它不会重启正在运行的教程。
5. 切到 **Scene → Remote**，在运行中的 `Chapter/Margin/Rows/Counters` 下查看 `A/State` 和 `B/State` 的 `value`，对照运行 UI 的数值；不要把 Local 源场景中的 State 当成 A 或 B。

Script 工作区的文档列表跨场景共享。查看 `counter.gd` 或 `counter_state.gd` 不代表顶部已选中对应场景；
下次独立运行本章前，仍要选回本章的 `chapter.tscn`，再点 **Run Current Scene**。

从课程入口运行时，底部 **Reset** 重新实例化本章，A、B 都回到 0；独立运行时停止再运行即可。

## 原理与代码

```text
Counter (PanelContainer + counter.gd)     负责显示与连接
├── State (Node + counter_state.gd)       保存 value，提供 increment/reset，发出 changed
└── Rows (VBoxContainer)                 标签与按钮
```

[chapter.tscn](chapter.tscn) 放了同一个 Counter 场景的两个实例，分别覆盖 caption。
[counter_state.gd](counter_state.gd) 中的 `value` 是实例成员，两份 State 不共享它。
[counter.gd](counter.gd) 在 `_ready()` 连接按钮和 State 的 `changed` 信号，再更新 Label。
子节点 ready 先于父节点，这样父节点可以在自己的 ready 中完成对已就绪子节点的连接。

一个 Node 同时最多附加一个脚本，但同一脚本资源可以用在多个 Node 上。
`extends PanelContainer` 表示继承；GDScript 文件本身定义了类，不是 Node 中的一段匿名代码。
这与“GameObject 上同时挂多个 MonoBehaviour”不是相同组织方式。

这里使用 State 子 Node 是为了展示树内组合。计数器本身很简单，实际工程完全可以用一个脚本完成；
不需要树服务的普通状态也可以用 RefCounted，编辑器中的可序列化配置则考虑 Resource。
下一章会验证共享 Resource 与独立运行状态的区别，避免把“脚本复用”误当成“所有数据自动独立”。

## 小练习

在 State 增加 `decrement()`，再给 Counter 增加 **-1** 按钮。
职责保持不变：State 修改 value 并发信号，显示脚本连接按钮和更新标签。保存后选回本章 `chapter.tscn`，再点 **Run Current Scene** 验证两个实例。

自检：改一次 Counter 源场景后 A、B 都有新按钮，但操作 A 仍不会改变 B；返回目录再进入不残留旧计数。

依据：[GDScript 类与继承](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)、
[Object 与脚本](https://docs.godotengine.org/en/stable/classes/class_object.html)、
[何时不使用 Node](https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html)。
