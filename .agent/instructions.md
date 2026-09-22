# Agent 指令

你是一个 AI 编码助手，正在参与 **ChinaBuddy** (my-first-project) 项目。

## 会话启动

1. 阅读 `.agent/conventions/project-context.md` 了解项目上下文
2. 阅读 `.harness/config.md` 了解工作流约束
3. 检查 `openspec/changes/` 中的进行中变更
4. 检查 `openspec/specs/` 中的当前规格说明

## 规约文件

实现层规约在 `.agent/conventions/` 目录下:

| 文件 | 范围 |
|------|------|
| `project-context.md` | 技术栈、仓库结构、语言边界、硬规则 |
| `backend.md` | Java 分层架构、DTO、Result\<T\>、异常处理 |
| `frontend.md` | 组件模式、数据获取、TypeScript 类型、可访问性 |
| `styling.md` | Tailwind、shadcn/ui、响应式、主题、动画 |
| `database.md` | BaseEntity、公共字段、命名、主键策略 |

**在对应领域编写代码前，必须先加载相关规约文件。**

## Superpowers 技能

技能文件在 `skills/<skill-name>/SKILL.md`。每个技能都是强制性工作流 -- 在任何操作之前调用，而非事后参考。

| 类别 | 技能 | 核心规则 |
|------|------|---------|
| 流程 | brainstorming, writing-plans, executing-plans, subagent-driven-development | 分类想法、2-5 分钟粒度任务、每任务独立子代理 |
| 测试 | test-driven-development | 没有失败的测试就不写生产代码 |
| 调试 | systematic-debugging, verification-before-completion | 四阶段根因分析、完成前必须有新鲜证据 |
| 评审 | requesting-code-review, receiving-code-review | 技术验证，不做表演式认同 |
| Git | using-git-worktrees, finishing-a-development-branch | 隔离工作区、合并前验证测试 |
| 元技能 | using-superpowers, writing-skills, dispatching-parallel-agents | 先调用技能、技能创建也遵循 TDD |

### 辅助参考文件

许多技能包含按需加载的辅助文件:
- `systematic-debugging/` 包含 root-cause-tracing.md, defense-in-depth.md, condition-based-waiting.md
- `subagent-driven-development/` 包含 implementer、reviewer、re-review 的提示词模板
- `test-driven-development/` 包含 writing-good-tests.md
- `brainstorming/` 包含 spec-document-reviewer-prompt.md
- `writing-plans/` 包含 plan-document-reviewer-prompt.md
- `requesting-code-review/` 包含 code-reviewer.md

## 硬规则 (不可违反)

- **TDD**: 没有失败的测试就不写生产代码
- **YAGNI / DRY**: 不过度设计，不重复
- **规格先行**: 没有规格或计划不动 `src/`
- **语言边界**: 前端 = TypeScript，后端 = Java
- **接口契约**: 所有端点使用 `/api` 前缀，`Result<T>` 包装
