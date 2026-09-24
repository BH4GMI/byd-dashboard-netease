# Changelog

版本号的唯一事实来源是 `apk/AndroidManifest.xml`（`versionCode` / `versionName`）；
git tag = `v` + versionName。本分支版本跟母工程
[byd-dashboard](https://github.com/BH4GMI/byd-dashboard) 走：
`<母工程 versionName>-netease`，versionCode 相同。

## 4.2-cast-hold-netease (versionCode 114)

与母工程 `4.2-cast-hold` 同源，由 `scripts/sync_netease_fork.ps1` 机械生成。本版改动最大的地方，
正是这个分支此前**刻意不做**的那件事：

- **不再"送到歌词页就撤手"。** 4.1 为了不把网易云钉在仪表屏上，链路一结束就松开看门；
  实测的后果是：网易云自己一跳（闪屏交接、应用内跳转）整条 root task 就被 AMS 挪回主驾屏，
  而且**没有人再搬回** —— 投屏当场丢失（实测 12:22 那一次：上屏 2.3 秒后被拽回）。
  现在屏位不变量由前台服务持有：每 2 秒巡检，界面退出也继续。
- **收回入口交给用户**：常驻通知上的「收回投屏」把网易云搬回主屏并停服务。
  这比"时间窗自动过期"更贴合本分支的意图 —— 打开即投屏，想用的时候再收回。
- **直接启动 `com.netease.cloudmusic.activity.CloudMusicRNActivity`**（不再经桌面入口的闪屏），
  这是"投上去两秒就被拽回主屏"的直接修法；该 Activity 的 `android:exported=true` 已核实。
- 顺带：投屏落点改为闭环回查纠正、判页固定抓主投影屏（见母工程 CHANGELOG 4.2），
  以及关键日志落盘到 `/sdcard/Android/data/com.byd.dashcast.netease/files/dashcast.log`。
- 分支差异仍是 `apk/fork/` 三个片段；`keepWatchAfterTarget()` 仍返回 `false`，
  但该形参在当前实现里没有被读取，投屏驻留已统一由守位服务负责。

## 4.1-cast-reliable-netease (versionCode 113)

首个公开发布的版本。

- 与母工程 `4.1-cast-reliable` 同源，由 `scripts/sync_netease_fork.ps1` 机械生成，
  可从 byd-dashboard 逐字复现（脚本内建断言：改名零遗漏、无编码损坏）。
- 分支差异仅三处（`apk/fork/`）：类注释、`onCreate`（打开即投屏，不看开关 /
  登录账号 / 首启标记）、`keepWatchAfterTarget` 返回 `false`（送到歌词页即撤看门）。
- 此前该分支以仓外目录维护，从未公开发布；旧内部版本为 1.x 系
  （`1.2-agent-selfheal-netease`，versionCode 100，车上实测过的最后一版），
  架构与 3.0 起的母工程完全不同（共享 uid-2000 代理 jar，本版起特权进程随包）。
