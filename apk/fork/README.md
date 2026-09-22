# fork/ — 网易云分支的差异片段

本目录的东西**不是代码**，是 `dashcast-netease` 相对母工程的可审阅差异。
`dashboard` 工作区的 `scripts/sync_netease_fork.ps1` 会读它们，把分支重新生成出来。

## 为什么这样组织

分支原先靠手工拷贝文件维护，它自己的类注释声称「差异点收敛在 onCreate 一处，
其余类与母工程逐字相同」。这句注释曾一度不成立——母工程的 `CastActivity` 长出了
222 行界面接线，分支没跟上——于是每次同步都得重新分析全量差异，很容易漏。

把差异从代码里抽出来放进本目录后：

- 同步变成一条命令，母工程的修复自动流到分支
- 分支到底改了什么，看这几个文件就够，不用做 diff
- 同步脚本能对"不该改的东西"做断言（见下）

## 文件

| 文件 | 作用 |
| --- | --- |
| `CastActivity.doc.txt` | 替换分支 `CastActivity` 的类注释 |
| `CastActivity.onCreate.txt` | 替换分支 `CastActivity` 的 `onCreate` —— **唯一的行为差异** |
| `CastActivity.overrides.txt` | 替换 `keepWatchAfterTarget`（分支返回 `false`，送到即撤看门） |
| `app_name.txt` | 应用显示名（`网易云投屏`） |

中文一律放这里、不放 `.ps1`：Windows PowerShell 5.1 把无 BOM 的 `.ps1` 按 ANSI 解码，
写在脚本里的中文字面量会先变成乱码再写进产出文件（多字节序列还会吞掉紧跟的 ASCII 字符）。
本目录的文件按 UTF-8 读取，没有这个问题。

## 同步

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File `
  C:\Users\REDMI\Desktop\Workspace\Android\dashboard\scripts\sync_netease_fork.ps1
```

构建（签名走 `CE_KS_*` 环境变量，与母工程同一把密钥，产物 `dashcast-netease.apk`）：

```powershell
cd C:\Users\REDMI\Desktop\Workspace\Android\dashcast-netease\apk
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1 -NoInstall
```

## 改名规则（3.0 架构起与旧版相反）

1.x 时代分支与母工程**共享**一个 uid-2000 代理 jar，因此有 4 个跨进程名字绝不能改。
3.0 起特权进程用 `CLASSPATH=<本 APK>` 拉起，代码就在本包 dex 里，协议常量与调用方
来自同一份源码——于是规则反了过来：**所有**跨进程名字都必须带 `netease` 前缀
（Binder 描述符、就绪广播、extra key、`app_process` 入口类、由 `APP_PACKAGE` 派生的
进程名 `com.byd.dashcast.netease-priv`）。两个应用同时装着时互不串线。

同步脚本跑完会断言：产出源码里不存在未改名的 `"com.byd.dashcast…"` 字符串字面量，
且关键改名后的常量都在。

## 已知限制

授权丢失时，母工程的 `ensureAgent()` 会因 `autoMode` 为真而不弹引导页，分支继承同一行为
（只留一条 toast）。需要手工授权时显式打开引导页：

```powershell
adb shell am start -n com.byd.dashcast.netease/.GuideActivity
```

从 1.x 版本升级到本版后**首次运行会弹一次 ADB 授权框**：1.x 随包分发过
`adb_identity.pk8`，本版不再随包带身份，应用改用自己私钥（首次生成）。
