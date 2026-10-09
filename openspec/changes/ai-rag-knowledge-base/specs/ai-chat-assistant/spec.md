## MODIFIED Requirements

### Requirement: 多轮对话上下文管理

系统 SHALL 维护每个用户的多轮对话上下文，使 AI 能够理解上下文相关的追问。当 RAG 功能启用时，系统 SHALL 在构建上下文前执行知识检索，用检索结果增强 System Prompt。

#### Scenario: 上下文窗口构建
- **WHEN** 用户发送新消息
- **AND** 该会话已有历史消息
- **THEN** 系统 SHALL 从 ai_message 表加载最近 20 条消息（按时间倒序）
- **AND** SHALL 按时间正序排列为 `[system_prompt, ...history-messages, new_user_message]`
- **AND** 消息数组 SHALL 按 role 交替：user → assistant → user → assistant...

#### Scenario: 上下文窗口截断
- **WHEN** 会话历史消息超过 20 条
- **THEN** 系统 SHALL 仅取最近 20 条作为上下文
- **AND** 更早的消息 SHALL 保留在数据库中，但不发送给 AI 模型

#### Scenario: System Prompt
- **WHEN** 构建发送给通义千问的 messages 数组
- **THEN** 第一条消息 SHALL 为 system role
- **AND** 内容 SHALL 基于配置文件中定义的 ChinaBuddy 旅游专家角色 prompt
- **AND** 当 RAG 功能启用且检索到相关文档时，内容 SHALL 为增强后的 prompt（原始 prompt + 检索上下文）
- **AND** 当 RAG 功能禁用或未检索到相关文档时，内容 SHALL 为原始 prompt
- **AND** prompt 内容 SHALL 在配置文件中定义（`application.yml`），支持运行时修改

#### Scenario: 空会话上下文
- **WHEN** 用户发送首条消息（无历史消息）
- **THEN** 发送给 AI 的 messages SHALL 仅包含 `[system_prompt, user_message]`

#### Scenario: RAG 检索上下文注入
- **WHEN** RAG 功能启用
- **AND** 知识检索返回 ≥ 1 个相关文档
- **THEN** System Prompt SHALL 在原始内容后追加检索上下文
- **AND** 检索上下文格式 SHALL 为 `[SourceType: Title]` + 内容 + 使用指令
- **AND** 注入的检索内容总长度 SHALL 不超过 max-context-chars 配置值
- **AND** 历史消息结构和用户消息 SHALL 保持不变

#### Scenario: RAG 失败时透明降级
- **WHEN** RAG 功能启用
- **AND** 知识检索失败（向量数据库不可达、Embedding 服务失败、或无相关结果）
- **THEN** System Prompt SHALL 使用原始内容（不追加任何内容）
- **AND** 对话行为 SHALL 与 RAG 功能实现前完全一致
