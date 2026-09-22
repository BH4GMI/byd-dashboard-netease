# Changelog

版本号的唯一事实来源是 `apk/AndroidManifest.xml`（`versionCode` / `versionName`）；
git tag = `v` + versionName。本分支版本跟母工程
[byd-dashboard](https://github.com/BH4GMI/byd-dashboard) 走：
`<母工程 versionName>-netease`，versionCode 相同。

## 4.1-cast-reliable-netease (versionCode 113)

首个公开发布的版本。

- 与母工程 `4.1-cast-reliable` 同源，由 `scripts/sync_netease_fork.ps1` 机械生成，
  可从 byd-dashboard 逐字复现（脚本内建断言：改名零遗漏、无编码损坏）。
- 分支差异仅三处（`apk/fork/`）：类注释、`onCreate`（打开即投屏，不看开关 /
  登录账号 / 首启标记）、`keepWatchAfterTarget` 返回 `false`（送到歌词页即撤看门）。
- 此前该分支以仓外目录维护，从未公开发布；旧内部版本为 1.x 系
  （`1.2-agent-selfheal-netease`，versionCode 100，车上实测过的最后一版），
  架构与 3.0 起的母工程完全不同（共享 uid-2000 代理 jar，本版起特权进程随包）。
