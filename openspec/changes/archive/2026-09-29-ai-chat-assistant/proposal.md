## Why

ChinaBuddy 首页右下角 AI Travel Assistant 当前为 Mock 实现——后端 `AiChatController` 基于关键词匹配返回硬编码回复，前端一次性接收完整响应，无流式体验、无多轮上下文记忆、无会话持久化。用户刷新页面即丢失所有对话历史。需要将其升级为真正的智能聊天系统，集成通义千问大模型，提供 SSE 流式输出和数据库级多轮对话上下文管理。

## What Changes

- **新增 SSE 流式聊天接口** `POST /api/ai/chat/stream`：替代现有 `POST /api/ai/chat` 的 Mock 一次性响应，通过 Server-Sent Events 逐 token 推送 AI 回复
- **新增对话历史查询接口** `GET /api/ai/chat/history`：返回用户当前会话的历史消息列表，支持前端会话恢复
- **新增新建对话接口** `DELETE /api/ai/chat/conversation`：归档当前会话并开启新对话
- **新增 Spring AI + 通义千问集成**：通过 OpenAI-Compatible Client 接入 `qwen-plus` 模型，base-url 指向阿里云百炼平台
- **新增 MySQL 对话持久化**：`ai_conversation` + `ai_message` 两张表，支持多轮上下文加载（最近 20 条）与会话归档
- **升级前端 AI Widget**：从一次性 `POST` 改为 `fetch` + `ReadableStream` 消费 SSE，实现逐字流式渲染、会话历史恢复、"New Chat" 按钮
- **固定 System Prompt**：ChinaBuddy 中国旅游专家角色，在 `application.yml` 中配置

## Capabilities

### New Capabilities
- `ai-chat-assistant`: 后端 SSE 流式聊天、通义千问集成、MySQL 对话持久化、多轮上下文管理；前端 SSE 流式消费与会话恢复

### Modified Capabilities
- `homepage-ai-widget`: 聊天 API 从一次性 POST 响应升级为 SSE 流式消费，新增会话历史恢复和 "New Chat" 功能，组件新增 streaming 状态与光标动画

## Impact

- **后端依赖**：新增 `spring-ai-openai-spring-boot-starter`（Spring AI 1.0.x BOM）+ `spring-boot-starter-webflux`（Flux 流式输出）
- **数据库**：新增 `ai_conversation`、`ai_message` 两张表，需要 Flyway/手动 DDL 迁移
- **API 变更**：新增 3 个端点（stream/history/conversation），现有 `POST /api/ai/chat` 保留但不再被前端使用
- **前端**：`api/ai.ts` 从 Axios 改为 fetch + ReadableStream；`ai-widget.tsx` 组件大幅升级；`chat-message.tsx` 新增 streaming 状态
- **配置**：`application.yml` 新增 `spring.ai.openai.*` 配置块（base-url、api-key、model、temperature）及 system prompt
- **认证**：新接口遵循项目现有 `X-User-Id` header 认证模式
