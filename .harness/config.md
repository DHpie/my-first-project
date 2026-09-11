---
description: Spec-driven 工作流强制规则，always-on 全局生效
trigger: always_on
---

# Harness Configuration

Configures the AI coding agent's behavior, constraints, and lifecycle controls.

## Agent Identity

- **Project**: my-first-project
- **Methodology**: Harness + OpenSpec + Superpowers
- **Primary Language**: Java 17 (Backend) / TypeScript 6 (Frontend)

## Session Startup

At the start of each session:
1. Read this file (`.harness/config.md`)
2. Read `skills/using-superpowers/SKILL.md` — the skills system entry point
3. Check `openspec/changes/` for in-flight changes
4. Check `openspec/specs/` for current specifications
5. Load any skill referenced by the current task context

## Technology Stack Constraints

The following technology choices are **binding** for this project. All AI-generated code MUST conform to these selections.

### Frontend: Next.js 15

| Component | Selection | Version |
|-----------|-----------|----------|
| UI Framework | React | ^19 |
| Meta Framework | Next.js (App Router) | 15 |
| Language | TypeScript | ~6 |
| Build Tool | Next.js built-in (Turbopack) | — |
| Styling | Tailwind CSS + shadcn/ui | latest |
| Icon Library | lucide-react | latest |
| Image Optimization | next/image (mandatory for all images) | built-in |
| Responsive Strategy | mobile-first (Tailwind breakpoint prefixes) | — |
| HTTP Client | Axios | ^1.20 |
| Linting | Oxlint | ^1.79 |

**Selection rationale:**
- Team is fully proficient in React — zero learning cost
- Next.js 15 has the highest AI code generation quality among React frameworks (Next.js 14 selected initially but upgraded to 15 for React 19 compatibility)
- App Router + Server Components is the current architectural direction of the React ecosystem
- Native Vercel deployment support; Docker deployment also mature
- **DO NOT** introduce Vue/Nuxt or non-App-Router patterns (Pages Router is legacy)

### Backend: Spring Boot 3

| Component | Selection | Version |
|-----------|-----------|----------|
| Language | Java | 17 |
| Framework | Spring Boot | 3.3.x |
| ORM | Spring Data JPA + Hibernate | managed by Spring Boot |
| Database | MySQL | 8.x |
| Build Tool | Maven (Maven Wrapper) | managed by Spring Boot |
| Validation | Spring Boot Starter Validation | managed by Spring Boot |

**Selection rationale:**
- Team has extensive Spring Boot development experience
- Spring Boot has the richest AI training data among backend frameworks
- Layered architecture (Controller → Service → Repository → Entity → DTO) is well-established and AI-generatable
- Enterprise-grade ecosystem supports long-term continuous iteration
- **DO NOT** introduce NestJS or other Node.js backend frameworks

### Deployment

| Target | Frontend | Backend |
|--------|----------|---------|
| Primary | Vercel | Docker |
| Alternative | Docker | Docker |

### Cross-Cutting Rules

1. **Language boundary is strict**: Frontend = TypeScript only, Backend = Java only
2. **API contract**: JSON over REST, unified `Result<T>` response wrapper, all endpoints prefixed with `/api`
3. **AI generation quality first**: When multiple implementation approaches exist, prefer the one with the most AI training data coverage (e.g., standard Spring annotations over custom abstractions, Next.js built-in features over third-party libraries)
4. **No framework mixing**: Do not introduce competing frameworks (e.g., Express, Fastify, Vue, Svelte) into the project

## Behavioral Constraints

### Before Writing Code
- ALWAYS check `skills/` for relevant skills before ANY task
- ALWAYS read existing specs in `openspec/specs/` for context
- NEVER jump into implementation without a spec or plan
- Invoke using-superpowers skill first — it governs all other skills

### During Implementation
- Follow TDD: failing test -> minimal code -> pass -> refactor
- Keep tasks small (2-5 minutes each) per writing-plans skill
- Run tests after every change
- Commit frequently with meaningful messages
- Use systematic-debugging when tests fail unexpectedly (4-phase process)

### After Implementation
- Run full test suite before declaring completion
- Use `verification-before-completion` skill — requires fresh evidence
- Verify against the original spec/proposal
- Request code review using `requesting-code-review` skill
- Archive completed changes per OpenSpec workflow

## Spec-Driven Workflow

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
| worktree | `skills/using-git-worktrees` | 隔离工作区 | — |
| 实现 | `openspec-apply-change` + `skills/test-driven-development` + `skills/subagent-driven-development` | `src/` 代码 + 测试 | 测试全绿 |
| review | `skills/requesting-code-review` | review 报告 | critical 问题清零 |
| verify | `skills/verification-before-completion` | 新鲜验证证据 | — |
| archive | `openspec-archive-change` + `skills/finishing-a-development-branch` | `openspec/changes/archive/<date>-<name>/` | 用户选择集成方式 |

### 例外

- 修复明显 typo / 注释 / 文档：可以跳过 propose，但仍需 TDD（如改了行为）。
- 仅修改 `.qoder/`、`.harness/` 或 `openspec/` 自身的配置文件：无需走 OpenSpec 流程。

### 违反处理

如果发现 agent 跳步直接写 `src/`，立刻停止、回退、从 brainstorming 重来。

## Quality Gates

- [ ] All tests pass (with evidence, not assumptions)
- [ ] Code follows project conventions
- [ ] Specs are up to date
- [ ] No unresolved TODOs or placeholders
- [ ] Changes are documented in OpenSpec
- [ ] Verification-before-completion checklist satisfied
- [ ] Code review requested and feedback addressed

## Tool Preferences

### Backend
- **Build Tool**: Maven (via Maven Wrapper `mvnw.cmd`)
- **Test Framework**: JUnit 5 (via `spring-boot-starter-test`)
- **Linter**: N/A (Java — IDE-based)

### Frontend
- **Package Manager**: npm
- **Test Framework**: (to be determined)
- **Linter**: Oxlint
- **Formatter**: (to be determined)

## Skills Reference

All 13 mandatory skills are in `skills/<skill-name>/SKILL.md`. Each skill directory may contain supporting reference files:

| Skill | Supporting Files |
|-------|-----------------|
| brainstorming | spec-document-reviewer-prompt.md |
| dispatching-parallel-agents | — |
| executing-plans | — |
| finishing-a-development-branch | — |
| receiving-code-review | — |
| requesting-code-review | code-reviewer.md |
| subagent-driven-development | implementer-prompt.md, task-reviewer-prompt.md, re-review-prompt.md |
| systematic-debugging | root-cause-tracing.md, defense-in-depth.md, condition-based-waiting.md |
| test-driven-development | writing-good-tests.md |
| using-git-worktrees | — |
| using-superpowers | — |
| verification-before-completion | — |
| writing-plans | plan-document-reviewer-prompt.md |
| writing-skills | — |
