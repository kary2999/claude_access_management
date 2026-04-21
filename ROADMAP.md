# 版本规划 Roadmap

当前版本：**v1.0.0**（MVP）

## v1.0.0 — MVP（已完成）
- 可视化管理 `~/.claude/settings.json` 的 allow / deny / ask
- 目录白名单（`permissions.additionalDirectories`），通过系统目录选择器授权
- 内置指令目录，每条带用途、风险说明、风险等级 L1–L5
- 风险等级评估：
  - L1 只读 `ls / cat / git status`
  - L2 网络读 `curl / gh pr view / WebFetch`
  - L3 写入 / 装包 `npm install / Edit / Write / git commit`
  - L4 网络写 `git push / gh pr create`
  - L5 破坏性 `rm / git reset --hard / sudo`
- 快照：保存当前 settings，任意恢复
- 定时授权：到期自动恢复到指定快照；`UserDefaults` 持久化，App 重启续上
- Universal Binary：arm64（M 系列）+ x86_64（Intel），macOS 13+

## v1.1.0 — 菜单栏常驻
- `NSStatusItem` 菜单栏图标，显示当前生效的风险水位
- 一键切换预设（"保守 / 日常 / 自由"）
- 到期前通知（`UNUserNotificationCenter`）

## v1.2.0 — 审计日志
- 记录每次授权变更（时间、变更项、操作人）
- 导出 JSON / CSV
- 侧边栏时间线视图

## v1.3.0 — 指令目录热更新
- 从 `claude --help` / 官方 schema 抓取最新指令
- 社区贡献的风险评估（签名校验）

## v1.4.0 — 预设模板
- 官方预设：Frontend / Backend / Ops / Security Review
- 个人预设的导入导出

## v2.0.0 — 项目级联动（可选）
- 管理 project 级 `.claude/settings.json`（当前版本明确不管）
- 多 profile：按工作目录自动切换

## 兼容性承诺
- macOS 13.0+
- Apple Silicon (M1/M2/M3/M4) 原生 + Intel 通过 universal binary
- 所有 release 走 `ARCHS="arm64 x86_64"` 构建
