# 经验教训（Lessons Learned）

本文档沉淀项目开发过程中的踩坑记录，供后续会话与 spec 审查直接引用。每条经验按「问题现象 → 根因分析 → 正确做法」三段式书写。

> 更新约定：新经验追加在文末；语言以中文优先（见 `openspec/config.yaml`）。

---

## 1. 技术约束跨层耦合（spec 引用 Harness）

### 问题现象

ChinaBuddy 首页 6 个 spec（homepage-shell / hero / navigation / destinations / community / ai-widget）在五维审查后，各自新增了 `## Technical Constraints` 章节，其中引用 `.harness/config.md > Technology Stack Constraints`。这使产品规格反向依赖了 Agent 配置层。

### 根因分析

五维审查的第 5 维"技术约束合规性"被误解为"spec 必须声明技术约束"。但技术栈约束的执行者是 AI Agent（会话启动时已读取 `.harness/config.md`），不是 spec 本身。spec 引用 Harness 造成三个问题：

1. **破坏 OpenSpec 自包含性**——spec 应描述系统"做什么"，而非"用什么做"
2. **跨层耦合**——产品规格依赖 Agent 配置，与 Harness + OpenSpec + Superpowers 的职责分离理念冲突
3. **引用仍是维护负担**——路径变更、格式漂移、新 spec 遗漏引用，都是潜在不一致点

### 正确做法

- **spec 不写任何技术约束章节**（含引用行）。技术栈约束唯一权威源是 `.harness/config.md` > Technology Stack Constraints
- 五维审查第 5 维的执行方式是：Agent 在审查时**自行对照** `.harness/config.md` 检查合规性，而非要求 spec 声明
- spec 中需要保留的模块级信息（如 Server/Client Component 类型）应写入 In Scope 或 Requirements，而非 Technical Constraints 章节

---

## 2. 依赖存在性未核实（spec 引用了未安装的库）

### 问题现象

6 个 homepage spec 大量引用了 Tailwind CSS 类名（`md:flex`、`hover:shadow-lg` 等）、shadcn/ui 组件（`Input`、`Button`）和 lucide-react 图标（`Search`、`Users`、`Map`、`Bot`），但编写时未核对 `frontend/package.json`。实际情况是：这些库**全部未安装**（项目仅有 next / react / react-dom / axios）。若直接进入实施，验收清单中的类名检查将全部失败。

### 根因分析

spec 编写时把"期望的技术栈"当成了"实际的技术栈"。审查流程在 hero spec 时指出了"未声明技术约束"的问题，修复时直接把 Tailwind + shadcn/ui 写进约束声明，却未反向验证这些约束在项目中是否已落地。约束声明（What we want）与依赖现状（What exists）之间缺少核实环节。

### 正确做法

- **写 spec 引用任何依赖前，必须先核实 `frontend/package.json`**（或对应后端的 `pom.xml`）
- **新引入技术栈必须先有独立前置提案**：如 `introduce-frontend-styling-infra`，完成安装落地后，后续 spec 才能引用
- 基础设施类 spec 的验收清单应包含"依赖已安装至 package.json"的验证项，保证落地可核查
- 实施顺序遵循依赖拓扑：infra → shell → 静态区域（hero/navigation）→ API 区域（destinations/community）→ ai-widget

---

## 3. 语言规范变更的连带影响

### 问题现象

早期 session 中 `openspec/config.yaml` 配置为 `language: English`，所有 spec 用英文书写。本 session 将语言切换为 Chinese 后，6 个 homepage spec 与既有 user-crud spec 仍是英文内容，出现了"配置声明中文、实际文档英文"的不一致。

### 根因分析

语言规范属于项目级约定，变更时只改了配置文件本身，没有同步评估既有文档。同时，长期记忆中仍存有旧的"spec must be written in English"规则（来自 config.yaml 的旧值），若未更新记忆，后续会话可能按旧规则继续生成英文 spec，使变更失效。

### 正确做法

- **今后所有 OpenSpec spec 文档与 docs/ 教训文档以中文优先书写**（`openspec/config.yaml` > `language: Chinese` 为权威配置）
- 语言配置变更时，同步检查三类连带项：既有 spec 内容、长期记忆中引用了旧语言值的规则、文档模板/技能文件中的语言示例
- 语言偏好属于项目配置，不属于用户沟通偏好——以 config.yaml 为准，不以单次会话习惯为准

---

## 记录历史

| 日期 | 来源 session | 涉及内容 |
|------|-------------|---------|
| 2026-09-11 | ChinaBuddy 首页 spec 拆分与五维审查 | 技术约束跨层耦合、依赖未核实、语言规范连带影响 |
