# byd-dashboard-netease

BYD DiLink 5 仪表盘投屏 · **网易云音乐一键版**（`com.byd.dashcast.netease`）

> ✅ **已在实车验证（2026-09-24）**
> 与本版同源的链路已在 DiLink 5.0 车机上安装并实跑：冷启动链路约 11 秒到达歌词播放页，
> 投屏驻留在仪表屏（60 秒后仍在），把目标强制搬回主屏后守位在 ≤2 秒内把它拉回。
> 构建级验证（签名、打包、改名断言）与母工程一致；母工程细节见
> [byd-dashboard](https://github.com/BH4GMI/byd-dashboard)。

## 这是什么

[byd-dashboard](https://github.com/BH4GMI/byd-dashboard) 的网易云共存分支：
独立包名，可与主应用同时安装。**打开即投屏**——不看开关、不看是不是首启，
每次启动都执行同一条链路：

```
投到投屏槽 display 3 → 闭环归位（不在槽位就搬回并回查）→ 抓帧判页、闭环补点进歌词播放页
  → 交给守位前台服务：每 2 秒巡检，界面退出也继续
```

投屏**驻留在仪表屏**，直到用户收回：点常驻通知上的「收回投屏」，网易云被搬回主控屏、服务停止。
槽位到仪表屏的映射由车机自己的 `com.byd.containerservice` 完成，本工程不插手。

补点落点是实测数据（`apk/res/values/quick_taps.xml`）：网易云把播放页做成了
应用内部页面，既不开放深链也不响应语音广播。

## 目录

```
apk/            完整可构建的分支源码（由 scripts/sync_netease_fork.ps1 生成，勿手改）
  fork/         分支相对母工程的全部差异片段（可审阅差异就这几个文件）
scripts/        同步脚本：以 byd-dashboard 为母工程重新生成本仓 apk/
```

本仓不含文档主体：机制、架构、已知边界全部见
[byd-dashboard](https://github.com/BH4GMI/byd-dashboard)（`docs/SOFTWARE_STRUCTURE_ZH.md`）。

## 构建

工具链不依赖 Gradle，只有一步（签名走 `CE_KS_*` 环境变量，缺省时退回本地自签名）：

```powershell
cd apk
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1 -NoInstall
```

## 重新生成（同步母工程更新）

把本仓与 [byd-dashboard](https://github.com/BH4GMI/byd-dashboard) 克隆为兄弟目录，
然后：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync_netease_fork.ps1
```

脚本会把母工程 `apk/` 逐字复制过来并做包名前缀改写（所有跨进程名字带
`.netease` 前缀，与主应用的特权进程互不串线），再拼入 `apk/fork/` 的差异片段，
并断言改名零遗漏、无编码损坏、`keepWatchAfterTarget()` 确为 `false`。

## 已知边界

- **从 1.x 旧版升级后首次运行会弹一次 ADB 授权框**：1.x 随包分发过 ADB 身份，
  本版起改用应用自生成身份。
- 授权丢失时本版不弹引导页（只留一条 toast）；需要手工授权时：
  `adb shell am start -n com.byd.dashcast.netease/.GuideActivity`
- 车机上如装有旧版 `1.0.0-netease` 且签名不同，升级会失败，需卸载重装
  （丢 ADB 授权与偏好设置）。

## 开源与免费

GPL-3.0（同 byd-dashboard）。本项目免费、无广告、不接受捐赠。
