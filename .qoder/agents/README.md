# Subagents

放置自定义 subagent 定义（每个一个 `.md` 文件，含 frontmatter + 系统提示词）。

## 何时建 subagent

- 任务可并行（参考 `skills/subagent-driven-development/SKILL.md`）
- 需要独立上下文窗口的专项工作（review、debug、调研）
- 需要二阶段评审：spec 合规检查 + 代码质量检查

## 当前子代理清单

| 文件 | 角色 | 触发时机 |
|------|------|---------|
| `product-agent.md` | 产品规划 | 需求澄清、设计探索、规格/实施计划编写、OpenSpec 变更提案 |
| `project-manager.md` | 产品经理 | 需求分析、PRD/用户故事/功能规格撰写 |
| `interaction-agent.md` | 交互设计 | UI 交互方案设计、组件交互规格撰写 |
| `frontend-agent.md` | 前端开发 | Next.js + React 页面与组件实现、前端 TDD |
| `backend-agent.md` | 后端开发 | Spring Boot API 与业务逻辑实现、后端 TDD |
| `test-agent.md` | 测试工程 | 测试策略、测试用例、API 契约与上线前验证 |
| `experience-agent.md` | 体验审查 | 页面视觉/交互/无障碍合规走查 |

## 命名建议

- `<role>-agent.md` — 角色命名采用小写字母 + 连字符，与 frontmatter `name` 字段一致

## 模板

新角色的结构、字段与内容要求以 `.qoder/template/` 下的模板文件为准，核心结构：

```markdown
---
name: <agent-name>
description: <一句话说明何时调用>
tools: Read, Grep, Glob, Write, Edit, Bash
skills:
  - <skill-name>
rules:
  - <rule-name>
---

# 角色定义

<角色定位与核心职责>

## 角色配置摘要

| 配置项 | 内容 |
|------|------|
| **Skills** | ... |
| **Rules** | ... |
| **Tools** | ... |
| **输出语言** | 中文（正文与回复），英文（代码标识符与路径） |

## 项目背景

<基于 `.agent/conventions/` 与 `openspec/` 的真实项目信息>

## 角色职责

1. ...

## 输出格式

<该角色的产出物格式>

## 角色限制

**必须做：** ...
**禁止做：** ...
```

要点：

- `skills` / `rules` 引用 `skills/` 目录下的技能与 `.agent/conventions/` 下的规范，不得虚构
- 全员共享项：所有角色在 `skills` 中加入 `subagent-driven-development`，在 `rules` 中加入 `coding-conventions`
- 正文与回复使用中文，代码标识符与路径保持英文
