# Godot 从入门到中级：Unity 开发者的知识迁移

目标读者熟悉 Unity、面向对象、实时主循环、向量与常见游戏系统。因此从 Godot 的对象模型和运行机制开始，
通过小实验校准已有经验，再进入 3D 动作游戏的运动、相机、动画与交互。最终成果是可以运行、阅读和扩展的 tut-to-guide。

**当前状态：01、02 已有起始示例；03–24 是课程计划，尚未实现。** 后续章节按学习反馈推进，不一次生成整套游戏。

运行按钮、Scene Layout 的界面分工及本机快捷键见 [项目操作说明](README.md#从编辑器运行与观察)。
下面的对象模型是引擎机制，不取决于是否启用该布局插件。

## 先建立准确的心智模型

```text
Object
├── Node                         场景树中的对象：层级、生命周期、处理回调
│   ├── Node3D                   3D 变换
│   ├── CanvasItem → Node2D / Control
│   └── Timer、其他专职节点……
└── RefCounted                   引用计数对象
    └── Resource                 可序列化、可共享的数据
        ├── PackedScene          保存的场景结构
        ├── Script               脚本资源
        └── Material、Mesh、Animation……
```

这是选取关键分支的继承示意，不是完整类图。`SceneTree` 是运行主循环与活动节点树的管理者，
`/root` 指它管理的根 Window/Viewport；某个 `.tscn` 实例只是这棵运行时树里的一个子树。

| 你已有的概念 | 在 Godot 中怎样重新理解 |
| --- | --- |
| Scene / Prefab | `.tscn` 加载为 `PackedScene`，`instantiate()` 创建 Node 子树；角色、武器、UI、关卡都可以是 scene，不以“一个关卡”作为 scene 的尺度 |
| GameObject + Components | Godot 以有具体类型的 Node 组成树；Node 并不是 GameObject 的一对一替身，普通 Node 甚至没有空间变换 |
| MonoBehaviour | 一个 Node 最多挂一个脚本，同一脚本资源可服务多个 Node 实例；不是“一个脚本文件只能对应一个 Node” |
| 拆分组件职责 | 需要树与生命周期的职责可拆为子 Node；普通逻辑用 RefCounted，配置用 Resource，不把所有类都做成节点 |
| ScriptableObject | 自定义 Resource 可承载可编辑、可序列化数据；重点学习共享引用与实例隔离，而不是只对应名称 |
| Hierarchy / Inspector | 同时观察编辑器 Local 树、运行时 Remote 树、Inspector 和 `.tscn` 文本，区分源场景与运行实例 |

对已有笔记的细化：

- “Scene 是 serializable tree”是好的入口，但序列化范围还受 `owner`、存储属性、资源引用等影响；不会自动保存所有临时运行状态。
- `parent` 决定树结构，`owner` 参与场景保存归属；有父节点不等于动态创建的节点会被打包保存。
- GDScript 文件本身就是类，`extends` 是继承；它不是“写在某个 Node 内部的一段代码”。还可以定义内部类，并继承 Node 以外的类型。
- 场景就近放脚本和专属资源是本项目约定；真实共享的资源再提到公共目录，不为每个 scene 强制创建空的资源文件夹。
- 主场景在这里负责课程入口与章节装卸；这是一种项目组织方式，不是 Godot 要求所有游戏拥有通用场景管理器。

对象模型依据：[Object](https://docs.godotengine.org/en/stable/classes/class_object.html)、[Node](https://docs.godotengine.org/en/stable/classes/class_node.html)、
[PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html)、[SceneTree](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_tree.html)。

## A. 对象、场景与数据：先理解引擎在管理什么

| 章 | 核心问题与知识迁移 | 实验 / 预期产出 | 状态 |
| --- | --- | --- | --- |
| [01 场景树与实例生命周期](game/tutorials/01_scene_tree/README.md) | 磁盘上的 PackedScene、已实例化但未入树的 Node、运行中的 SceneTree 有何区别？`remove_child` 和 `queue_free` 有何不同？ | 创建同一场景的多个实例；移出后重新加入，观察身份与回调次数；比较 Run Project 与 Run Current Scene 的运行树路径 | 起始示例可运行 |
| [02 脚本、继承与组合](game/tutorials/02_scripts_and_composition/README.md) | 脚本资源与实例状态如何分开？为什么不能照搬同一 GameObject 挂多个 MonoBehaviour？ | 两个计数器复用同一场景和脚本，独立持有状态；用子节点与信号连接逻辑和显示 | 起始示例可运行 |
| 03 Resource 与对象身份 | `Object → RefCounted → Resource` 的职责；`.tres`、内嵌资源、加载缓存与引用计数；Unity ScriptableObject 经验的适用边界 | 两个对象引用同一份配置，对比共享修改、复制与 `resource_local_to_scene` | 待实现 |
| 04 场景序列化与组织 | `parent` / `owner`、存储属性、`PackedScene.pack()`、嵌套场景、继承场景与属性覆盖 | 运行时创建子节点，分别设定 owner 后打包并重载；检查哪些状态被保存 | 待实现 |

这一阶段结束时，应能解释一个对象从文件到运行、从入树到释放的过程，并判断一份状态该属于 Node 实例还是共享 Resource。

## B. 编程与调度：迁移行为模型

| 章 | 核心问题与知识迁移 | 实验 / 预期产出 | 状态 |
| --- | --- | --- | --- |
| 05 面向 C# 使用者的 GDScript | 类型标注、`class_name`、`@export`、属性、内部类、Array/Dictionary、Variant、`load` / `preload`；不重复教授变量和循环 | 写一个类型清晰的小配置与消费对象，观察 Inspector 与脚本类型检查 | 待实现 |
| 06 生命周期与时间 | `_init`、`_enter_tree`、`_ready`、`_exit_tree`；`_process` / `_physics_process`、delta、process_mode、暂停与 `call_deferred` | 记录父子回调顺序；对比固定步进与逐帧运动；发现“隐藏 UI”不等于停止处理 | 待实现 |
| 07 通信与依赖 | Signals、Callable、Groups、NodePath、唯一名 `%`、直接引用；哪些通信属于局部，哪些属于跨场景 | 伤害按钮驱动生命值，UI 通过信号更新；替换节点后检查失效引用与重复连接 | 待实现 |
| 08 输入与异步 | InputMap、轮询 / 事件、`_input` / `_unhandled_input` / `_gui_input`、`await`、Timer、Tween；与 Unity Input System / coroutine 的差异 | UI 消耗输入时角色不响应；节点被移除后，异步流程不再错误操作旧对象 | 待实现 |

依据：[GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)、
[Resource](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html)、[何时不使用 Node](https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html)。

## C. 编辑器与工程：理解文件、实例和工具之间的关系

| 章 | 核心问题与知识迁移 | 实验 / 预期产出 | 状态 |
| --- | --- | --- | --- |
| 09 调试与观察 | 当前编辑场景与共享 Script/Game 视图、Local / Remote、Inspector、断点与调用栈；Run Project / Run Current Scene 的区别；哪些修改只影响运行实例 | 从一个生命周期或信号错误定位到具体 Node；保存前后检查磁盘差异 | 待实现 |
| 10 资源导入与版本管理 | `res://` / `user://`、UID、导入设置、缓存、外部资源引用；迁移 Unity meta 与 Library 的经验 | 导入一个小型 glTF，修改导入配置，清除可重建缓存后检查引用；记录资源来源 | 待实现 |
| 11 编辑器脚本与可见演示 | `@tool` 的执行边界、Inspector 导出属性；可选 MCP 的项目/session 选择 | 用练习副本演示编辑节点和保存，学习者可以按人工步骤复现；不把运行重置当作文件回滚 | 待实现 |
| 12 UI 与项目状态 | Control、Container、锚点、Theme、Focus、CanvasLayer；Autoload 的用途和边界 | 一个分辨率适配的菜单与暂停界面；区分局部关卡状态和跨场景状态 | 待实现 |

MCP 作为可选演示方式接入，尚未安装。需要时用 `godot-mcp-setup` 的轻量分支；
每次通过 repo 的完整路径确认唯一 editor session，再显式传入 session_id。课程始终保留无需 MCP 的操作说明。

## D. 3D 基础与移动：开始面向 ACT，但保持单题实验

| 章 | 核心问题与知识迁移 | 实验 / 预期产出 | 状态 |
| --- | --- | --- | --- |
| 13 空间与渲染 | Node3D、Transform3D、Basis、局部/世界空间、相机方向；与 Unity 坐标约定的差异；Material / Environment / 渲染器 | 用轴向标记解释前方向与父子变换；比较同一场景的材质和光照设置 | 待实现 |
| 14 物理体与查询 | StaticBody3D、RigidBody3D、CharacterBody3D、Area3D、Shape、layer/mask、射线与形状查询 | 同一障碍前对比物理体、角色体和检测区域，观察碰撞与触发的不同用途 | 待实现 |
| 15 角色地面运动 | velocity、重力、`move_and_slide`、地面判定、斜坡；迁移 Unity CharacterController 经验 | 独立制作可调速度的胶囊行走、跳跃和落地实验，不复制预制 ACT 控制器 | 待实现 |
| 16 第三人称相机 | 相机相对输入、yaw/pitch、SpringArm3D、遮挡、鼠标捕获；不假设存在 Cinemachine 的一对一替代 | 观察相机绕角色、贴墙缩短、角色出生朝向变化，解释每层节点的坐标空间 | 待实现 |

## E. 动作表达：从可移动对象到有行为的角色

| 章 | 核心问题与知识迁移 | 实验 / 预期产出 | 状态 |
| --- | --- | --- | --- |
| 17 动画资源与播放 | AnimationPlayer、AnimationLibrary、Skeleton3D、导入动画、方法轨道；资源本身与驱动逻辑的分工 | 预览实际存在的动画，解释采样、循环、轨道目标与事件 | 待实现 |
| 18 动画混合与位移 | AnimationTree、混合空间、状态转换、root motion；与 Animator Controller 的概念差异 | 对比原地动画与根运动的位移来源，避免角色移动被重复计算 | 待实现 |
| 19 行为状态与输入窗口 | Idle/Move/Jump/Attack、状态所有权、输入缓冲、取消窗口；动画状态与玩法状态的边界 | 自己实现一个小状态机和可观察的输入窗口，不先引入完整框架 | 待实现 |
| 20 交互与战斗判定 | Area / Shape 查询、命中去重、hurtbox/hitbox、伤害数据、交互目标选择 | 用几何占位体完成一次攻击与命中反馈，列出时序与空间判定依据 | 待实现 |

## F. 中级整合：组织、验证和迭代

| 章 | 核心问题与知识迁移 | 实验 / 预期产出 | 状态 |
| --- | --- | --- | --- |
| 21 简单敌人与导航 | NavigationRegion3D、NavigationAgent3D、路径与实际移动的分工、感知与行为 | 一个可追踪、可失去目标的敌人实验，观察寻路更新和角色移动 | 待实现 |
| 22 场景装卸与存档 | 加载关卡、实例释放、跨场景引用、`user://`、可序列化状态与版本 | 两个小房间切换并恢复少量进度；验证没有残留节点和错误引用 | 待实现 |
| 23 调试、性能与回归 | Profiler、渲染/物理/脚本耗时、资源共享、实例数量；什么时候才值得自动化测试 | 找到一个可复现瓶颈并测量改动；有重复回归需求时再引入测试工具 | 待实现 |
| 24 综合练习与 guide 整理 | 将前述知识组织成一个小型 3D ACT 练习，解释架构选择和限制 | 组合移动、相机、动画、一次攻击与一个交互点；归纳为可查阅指南 | 待实现 |

最终练习使用前面逐章写出的内容；不套用 `godot-3d-action-adventure`，也不扩展为完整游戏生产工程。

## 每章怎样学习与验收

1. 先提出一个需要校准的 Unity 经验，再给出 Godot 的对象或数据关系。
2. 打开并选中本章 `chapter.tscn`，分别检查 Local 场景树、Inspector 与相关脚本文档；点 Run Current Scene 独立运行，按 README 操作，在 Remote 中观察运行对象。
3. 对照代码解释机制，完成一个小改动，再尝试预测运行结果。
4. 明确哪些是引擎行为、哪些是本项目的设计选择，记录当前版本和未验证事项。

各章 README 包含目标、操作、预期现象、原理与代码、小练习。阶段验收以能解释、修改并验证行为为准，
不是以记住 API 名字为准。课程目录中的“待实现”不代表目录或场景已经生成。
