---
description: Spec-driven 工作流强制规则，always-on 全局生效
trigger: always_on
---

# Harness 配置

配置 AI 编码助手的行为、约束和生命周期控制。

## 助手身份

- **项目**: ChinaBuddy (my-first-project)
- **方法论**: Harness + OpenSpec + Superpowers
- **主要语言**: Java 17 (后端) / TypeScript 6 (前端)

## 技术栈 (绑定约束)

- **前端**: React 19 + Next.js 15 (App Router) + TypeScript 6 + Tailwind CSS + shadcn/ui
- **后端**: Java 17 + Spring Boot 3.3.x + Spring Data JPA + MySQL 8
- **部署**: Vercel (前端) / Docker (后端)
- 完整详情: `.agent/conventions/project-context.md`

## 规格驱动工作流

任何涉及 `src/` 改动的请求，必须按下列顺序推进，**不可跳步**：

```
brainstorming  →  propose  →  plan  →  worktree  →  TDD 实现  →  code review  →  verify  →  archive
```

### 各阶段约束

| 阶段 | 触发 | 产出物 | 人类把关点 |
|---|---|---|---|
| brainstorming | `skills/brainstorming` | 对话产出的需求要点 | 用户确认需求理解 |
| propose | `openspec-propose` | `openspec/changes/<name>/{proposal,specs,design,tasks}.md` | 用户签字四件套 |
| plan | `skills/writing-plans` | `openspec/changes/<name>/tasks.md` 细化步骤 | 用户确认计划 |
| worktree | `skills/using-git-worktrees` | 隔离工作区 | -- |
| 实现 | `openspec-apply-change` + `skills/test-driven-development` + `skills/subagent-driven-development` | `src/` 代码 + 测试 | 测试全绿 |
| review | `skills/requesting-code-review` | review 报告 | critical 问题清零 |
| verify | `skills/verification-before-completion` | 新鲜验证证据 | -- |
| archive | `openspec-archive-change` + `skills/finishing-a-development-branch` | `openspec/changes/archive/<date>-<name>/` | 用户选择集成方式 |

### 例外

- 修复明显 typo / 注释 / 文档：可以跳过 propose，但仍需 TDD（如改了行为）。
- 仅修改 `.qoder/`、`.harness/`、`.agent/` 或 `openspec/` 自身的配置文件：无需走 OpenSpec 流程。

### 违反处理

如果发现 agent 跳步直接写 `src/`，立刻停止、回退、从 brainstorming 重来。

## 质量门禁

- [ ] 所有测试通过 (需有证据，非假设)
- [ ] 代码遵循项目规约 (见 `.agent/conventions/`)
- [ ] 规格文档已更新
- [ ] 无未解决的 TODO 或占位符
- [ ] 变更已记录在 OpenSpec 中
- [ ] 完成前验证清单已满足
- [ ] 已请求代码评审并处理反馈

## 工具配置

### 后端
- **构建工具**: Maven (通过 Maven Wrapper `mvnw.cmd`)
- **测试框架**: JUnit 5 (通过 `spring-boot-starter-test`)

### 前端
- **包管理器**: npm
- **测试框架**: (待定)
- **代码检查**: Oxlint

## 技能参考

所有 13 个强制技能在 `skills/<skill-name>/SKILL.md`:

| 技能 | 辅助文件 |
|------|--------|
| brainstorming | spec-document-reviewer-prompt.md |
| dispatching-parallel-agents | -- |
| executing-plans | -- |
| finishing-a-development-branch | -- |
| receiving-code-review | -- |
| requesting-code-review | code-reviewer.md |
| subagent-driven-development | implementer-prompt.md, task-reviewer-prompt.md, re-review-prompt.md |
| systematic-debugging | root-cause-tracing.md, defense-in-depth.md, condition-based-waiting.md |
| test-driven-development | writing-good-tests.md |
| using-git-worktrees | -- |
| using-superpowers | -- |
| verification-before-completion | -- |
| writing-plans | plan-document-reviewer-prompt.md |
| writing-skills | -- |
