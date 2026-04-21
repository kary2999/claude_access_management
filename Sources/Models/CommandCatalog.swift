import Foundation

struct CommandEntry: Identifiable, Hashable {
    let id = UUID()
    let rule: String
    let risk: RiskLevel
    let purpose: String
    let danger: String
}

enum CommandCatalog {
    static let all: [CommandEntry] = [
        // L1 只读
        .init(rule: "Bash(ls:*)", risk: .l1, purpose: "列目录", danger: "无副作用"),
        .init(rule: "Bash(pwd)", risk: .l1, purpose: "当前路径", danger: "无"),
        .init(rule: "Bash(cat:*)", risk: .l1, purpose: "读文件", danger: "可能读到敏感文件"),
        .init(rule: "Bash(git status)", risk: .l1, purpose: "查看仓库状态", danger: "无"),
        .init(rule: "Bash(git diff:*)", risk: .l1, purpose: "查看 diff", danger: "无"),
        .init(rule: "Bash(git log:*)", risk: .l1, purpose: "查看提交历史", danger: "无"),

        // L2 网络读
        .init(rule: "Bash(curl:*)", risk: .l2, purpose: "HTTP 请求", danger: "可被用于外发数据，建议限定域名"),
        .init(rule: "Bash(gh pr view:*)", risk: .l2, purpose: "查看 PR", danger: "只读 GitHub"),
        .init(rule: "Bash(gh issue view:*)", risk: .l2, purpose: "查看 issue", danger: "只读"),
        .init(rule: "WebFetch", risk: .l2, purpose: "抓取网页", danger: "可能抓到钓鱼页"),

        // L3 写入/安装
        .init(rule: "Bash(npm install:*)", risk: .l3, purpose: "装包", danger: "可能执行恶意 postinstall"),
        .init(rule: "Bash(pnpm install:*)", risk: .l3, purpose: "装包", danger: "同上"),
        .init(rule: "Bash(pip install:*)", risk: .l3, purpose: "装 Python 包", danger: "可能执行 setup.py"),
        .init(rule: "Bash(git commit:*)", risk: .l3, purpose: "本地提交", danger: "可修改历史"),
        .init(rule: "Bash(git add:*)", risk: .l3, purpose: "暂存", danger: "无"),
        .init(rule: "Edit", risk: .l3, purpose: "编辑文件", danger: "只对授权目录生效"),
        .init(rule: "Write", risk: .l3, purpose: "写文件", danger: "同上"),

        // L4 网络写
        .init(rule: "Bash(git push:*)", risk: .l4, purpose: "推送", danger: "修改远程仓库"),
        .init(rule: "Bash(gh pr create:*)", risk: .l4, purpose: "创建 PR", danger: "对外可见"),
        .init(rule: "Bash(gh pr comment:*)", risk: .l4, purpose: "PR 评论", danger: "对外可见"),

        // L5 破坏性
        .init(rule: "Bash(rm:*)", risk: .l5, purpose: "删文件", danger: "不可逆"),
        .init(rule: "Bash(git reset --hard:*)", risk: .l5, purpose: "硬重置", danger: "丢失未提交改动"),
        .init(rule: "Bash(git push --force:*)", risk: .l5, purpose: "强推", danger: "覆盖远程历史"),
        .init(rule: "Bash(sudo:*)", risk: .l5, purpose: "提权", danger: "系统级改动"),
        .init(rule: "Bash(brew uninstall:*)", risk: .l5, purpose: "卸载软件", danger: "影响系统")
    ]

    static func risk(for rule: String) -> RiskLevel {
        all.first { $0.rule == rule }?.risk ?? .l3
    }
}
