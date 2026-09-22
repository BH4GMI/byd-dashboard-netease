# byd-dashboard-netease

BYD DiLink 5 仪表盘投屏 · **网易云音乐一键版**（`com.byd.dashcast.netease`）

> ⚠️ **Caution · 未经真机验收**
> 本版本已通过构建级验证（签名、打包、断言），但**尚未在实车上安装与运行**。
> 功能行为（投屏链路、特权进程、看门撤除）继承自同版本号的
> [byd-dashboard](https://github.com/BH4GMI/byd-dashboard)，那边的链路已实车验证；
> 本仓差异点（打开即投屏、不留看门）最后一次实车验证发生在 1.x 旧架构上。

## 这是什么

[byd-dashboard](https://github.com/BH4GMI/byd-dashboard) 的网易云共存分支：
独立包名，可与主应用同时安装。**打开即投屏**——不看开关、不看登录账号、不看
是不是首启，每次启动都执行同一条链路：

```
投到仪表屏 display 2 → 轮询真实屏位等它稳定 → 抓帧判页、闭环补点进歌词播放页 → 撤看门退出
```

送到歌词页即结束、**不留看门**（主应用留：用户还要继续用；本版送完就走，
留着看门会把网易云钉死在仪表屏上，用户按了回不到前台）。

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
