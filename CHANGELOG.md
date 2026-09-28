# Changelog

版本号的唯一事实来源是 `apk/AndroidManifest.xml`（`versionCode` / `versionName`）；
git tag = `v` + versionName。本分支版本跟母工程
[byd-dashboard](https://github.com/BH4GMI/byd-dashboard) 走：
`<母工程 versionName>-netease`，versionCode 相同。

## 5.0-netease (versionCode 118) — ⚠️ 正式 release，仍未实机验证

与母工程 [`5.0`](https://github.com/BH4GMI/byd-dashboard/releases/tag/v5.0) 同源，
由 `scripts/sync_netease_fork.ps1` 机械生成。含 `4.4-display-detect-netease` 与
`4.4-diagnostics-netease` 的全部改动。

**本版没有装车验证过。** 稳定版仍是 `4.3-user-intent-netease`（`versionCode 115`，`main` 分支）。

**为什么从 4.4 跳到 5.0**：4.4 做的是"认得出哪块屏"，5.0 在其上加了跨代次可用性与
用户可自助排障，属能力跃迁而非修订。

- **诊断只在判定失败时出**：平台事实不再混进每一条判定日志；代价是成功路径失去跨代证据，
  由一键导出补上。
- **一键导出诊断报告**：操作条新增「诊断」按钮，报告含身份/设备/平台事实/通路判定/
  原始屏表/日志尾部 6000 字符。先交系统分享，同时写 `getExternalFilesDir` 下的 txt
  —— 车机多半没有能接收 `ACTION_SEND` 的应用，文件与路径是兜底。
- 母工程完整的变更说明与验证状态表见母工程 CHANGELOG，此处不复制以免漂移。

**安装提示**：`versionCode 118 > 115`，可覆盖安装；装了 118 后**不能**覆盖回 115，退回需卸载重装。

## 4.4-diagnostics-netease (versionCode 117) — ⚠️ 预发布 / pre-release，未实机验证

与母工程 [`4.4-diagnostics`](https://github.com/BH4GMI/byd-dashboard/releases/tag/v4.4-diagnostics) 同源。
与 116 属同一条加固线，只是补上诊断信息；**同样没有装车验证过**。116 的改动见下一节。

- **未适配时补出平台事实**（`product=` / `sdk=` / `single_os=`），原因串不再只有一句"没命中任何屏族"。
  `single_os` 经 shell 通道（uid 2000）读取 —— `android.os.SystemProperties` 是 @hide，
  反射在 targetSdk 32 下会被隐藏 API 限制挡住。
- **单 OS 机型额外说明一句**「仪表由车机原生渲染，这类机型不适用第三方投屏」。
  **该说明只影响文案、不参与判定**：通路仍然只看显示拓扑，不按版本号决策。
- 母工程完整的落盘形态示例与验证状态表见母工程 CHANGELOG，此处不复制。

**安装提示**：`versionCode 117 > 115`，可覆盖安装；装了 117 后**不能**覆盖回 115，退回需卸载重装。

## 4.4-display-detect-netease (versionCode 116) — ⚠️ 预发布 / pre-release，未实机验证

与母工程 [`4.4-display-detect`](https://github.com/BH4GMI/byd-dashboard/releases/tag/v4.4-display-detect) 同源，
由 `scripts/sync_netease_fork.ps1` 机械生成（改名与编码断言随生成流程执行）。

**本版没有装车验证过。** 稳定版仍是 `4.3-user-intent-netease`（`versionCode 115`，`main` 分支）。
母工程 4.4 的完整变更说明与验证状态表见[母工程 CHANGELOG](https://github.com/BH4GMI/byd-dashboard/blob/main/CHANGELOG.md)，
此处不复制，避免两边漂移。

- **认屏判据化，新增 `DisplayTable`**（纯 Java、零 Android 依赖，因而可离线验证）；
  本分支的 `DashboardSession` / `CastActivity` / `ShellChannel` 同步跟进。
- **删除投屏槽位兜底常量 3**：认不出来一律判「本机未适配」，不再猜 id。
- **新增 DiLink 3/4 直投通路 `DIRECT` 与 owner 归属校验**；识别升级为应用侧枚举 + daemon 精化两趟。

**安装提示**：`versionCode 116 > 115`，可覆盖安装；但装了 116 之后**不能**覆盖回 115
（`INSTALL_FAILED_VERSION_DOWNGRADE`），退回旧版必须卸载重装，那会一并清掉已保存的 ADB 授权身份。

## 4.3-user-intent-netease (versionCode 115)

与母工程 `4.3-user-intent` 同源，由 `scripts/sync_netease_fork.ps1` 机械生成。

- **归位不再对着空壳任务空转**（母工程 CHANGELOG 4.3 详述）。本分支实测的失败现场正是这一条：
  网易云被系统回收后 task 残留成 `sz=0` 的空壳，而 `taskDisplay()` 只认"Task 行存在"，
  于是把"必须启动应用"误判成"只需搬移"，`am display move-stack` 对空壳无效，屏位回查永远不变，
  8 秒内重试 22 次后如实报"搬到仪表盘没生效"，仪表屏全程空白。
  判据层新增 `isLiveTask()`：只认 `sz>0` 的任务；解析不到 `sz` 时保守按"有内容"处理。
- **用户可以点桌面图标把投屏收回去**（母工程 CHANGELOG 4.3 详述）。守位新增按 AMS 的
  activity 启动记录区分"应用自己跳回主屏"与"用户点桌面图标叫回来"，后者按用户意图结束投屏，
  而不是搬回。判据排在归位之前。
- 实测（2026-09-28，同一台车）：修复前 `当前屏位=0` → 8 秒内 22 次归位失败 → 投屏失败；
  修复后 `当前屏位=-1` → 走启动分支 → `投屏完成`（display 3），`screencap -d 2` 得到 256 KB
  的正常画面（修复前该屏全程空白）。
- 分支差异仍是 `apk/fork/` 三个片段；`keepWatchAfterTarget()` 仍返回 `false`，
  投屏驻留统一由守位服务负责。

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
