# 01 场景树、实例与生命周期

目标：区分磁盘上的场景资源、内存中的 Node 子树、正在运行的 SceneTree；不把 scene 只理解成关卡。
此章故意不展示角色模型，Actor 只有几个节点，方便直接观察结构与对象身份。

## 操作与预期结果

打开 [chapter.tscn](chapter.tscn)，按 F6，或从主目录进入本章。

1. 点击两次 **Create actor**。得到两棵来自同一 PackedScene 的子树，每个 Actor 的 ID 不同，`enter=1 ready=1`。
2. 点击 **Detach last**。最后一个 Actor 从活动子树移出，但仍显示在 Detached 区域，ID 不变、`inside_tree=false`。
3. 点击 **Reattach**。它回到活动树，ID 不变、`enter=2 ready=1`：重新入树不默认再次调用 `_ready()`。
4. 点击 **Destroy detached / last**。有移出的 Actor 时销毁它，否则销毁最后一个活动 Actor；下一帧它从显示中消失。
5. 在 Godot 的 Scene 面板切换 **Remote**，查看真实运行节点。对照屏幕中的路径、ID 和 owner；Local 仍是正在编辑的源场景。
6. 停止运行后按 F5，从课程目录进入同一章节，观察路径多了入口及 Content。F6 则直接以本章作为运行主场景。

底部 **Reset** 会重新创建整个章节。F6 独立运行时没有公共导航，停止后再次运行即可恢复起点。

## 原理与代码

- [actor.tscn](actor.tscn) 是序列化场景，加载后是 PackedScene 资源；它也可以只包含一个节点。
- [chapter.gd](chapter.gd) 的 `create_actor()` 先 `instantiate()`，再 `add_child()`。创建实例和进入活动树是两件事。
- `detach_actor()` 只调用 `remove_child()`，本章继续持有对象引用，因此可以重新加入。
- `destroy_actor()` 调用 `queue_free()`，在帧末删除节点及其子节点；存着引用不代表 Node 会一直有效。
- [actor.gd](actor.gd) 记录入树和 ready 次数。代码没有调用 `request_ready()`，所以重新入树时 ready 不再执行。
- 章节退出时主动释放暂存的 detached 节点；它已经不是子节点，不能指望父节点销毁时替我们清理。

`parent` 与 `owner` 不是同一关系。前者描述活动树；后者关系到场景序列化。
当前例子显示它们，但不在此章写磁盘文件；04 章再通过打包实验展开。

## 小练习

在 `actor.tscn` 的 Actor 下添加一个普通 Node，命名为 `Sensor`，保存后重新运行章节。
预测新创建实例的结构和 owner，再通过 Remote 检查；源场景的修改应出现在每个新实例里。

自检：能解释为什么 Detach 没有销毁对象、为什么重新加入没有自动 ready，以及为什么动态实例没有出现在 Local 源场景中。

依据：[SceneTree](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_tree.html)、
[Node](https://docs.godotengine.org/en/stable/classes/class_node.html)、[PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html)。
