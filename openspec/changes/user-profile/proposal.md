## Why

当前 ChinaBuddy 仅有基础 User CRUD（`user-crud` spec），用户实体只包含 `username` 和 `email` 两个字段。平台缺乏用户个人资料管理能力——用户无法设置头像、昵称、个人简介和兴趣标签。随着消息通知（`user-notifications`）和站内信（`user-direct-messages`）即将实现，用户身份展示（头像、昵称）成为所有社交互动的基础依赖。没有个人中心，通知和站内信将无法展示操作者的身份信息。

本变更为登录用户提供完整的个人资料查看与编辑能力，建立平台身份认同，同时为后续社交功能提供用户展示信息基础。

## What Changes

- **数据模型扩展**：在现有 User 实体上新增 `nickname`（VARCHAR(30)）、`bio`（VARCHAR(200)）、`avatarUrl`（VARCHAR(500)）、`interestTags`（VARCHAR(200)，JSON 数组序列化）字段
- **头像上传 API**：新增 `POST /api/profile/avatar` 端点，支持 JPG/PNG/WebP 上传（≤ 2MB），后端存储到本地文件系统并返回 URL
- **资料查看 API**：新增 `GET /api/profile` 端点，返回当前登录用户的完整资料
- **资料编辑 API**：新增 `PUT /api/profile` 端点，更新昵称（1-30 字符）、简介（≤ 200 字符）、兴趣标签（从 10 项预定义列表中选 ≤ 5 项）
- **兴趣标签列表 API**：新增 `GET /api/profile/tags` 端点，返回预定义标签列表
- **前端查看页**：新增 `/profile` 路由，展示头像（或默认占位）、昵称、简介、兴趣标签
- **前端编辑页**：新增 `/profile/edit` 路由，提供头像上传、昵称/简介编辑、兴趣标签选择器
- **离开确认**：编辑页有未保存修改时，拦截导航并弹出确认对话框

## Capabilities

### New Capabilities

- `user-profile`：用户个人资料查看与编辑，包含头像上传、昵称/简介编辑、兴趣标签管理

### Modified Capabilities

- `user-crud`：User 实体扩展新字段（`nickname`、`bio`、`avatarUrl`、`interestTags`），现有 API 响应结构扩展

## Impact

**前端代码**：
- 新增 2 个页面：`frontend/src/app/profile/page.tsx`、`frontend/src/app/profile/edit/page.tsx`
- 新增组件目录：`frontend/src/components/profile/`（Avatar、AvatarUploader、ProfileBio、ProfileTags、InterestTagSelector 等）
- 新增 1 个 API 层：`frontend/src/api/profile.ts`
- 新增 1 个类型定义：`frontend/src/types/profile.ts`
- 修改 `frontend/src/components/layout/header.tsx`：添加 Profile 入口链接（需登录后显示）

**后端代码**：
- 修改 `entity/User.java`：新增 `nickname`、`bio`、`avatarUrl`、`interestTags` 字段
- 新增 `controller/ProfileController.java`：`GET /api/profile`、`PUT /api/profile`、`GET /api/profile/tags`
- 新增 `controller/AvatarController.java`：`POST /api/profile/avatar`
- 新增 `dto/request/ProfileUpdateRequest.java`、`dto/response/ProfileResponse.java`
- 新增 `service/ProfileService.java` + `service/impl/ProfileServiceImpl.java`
- 新增头像存储目录配置 + 文件上传处理逻辑

**数据库**：
- `users` 表新增列：`nickname VARCHAR(30)`、`bio VARCHAR(200)`、`avatar_url VARCHAR(500)`、`interest_tags VARCHAR(200)`

**依赖**：无新增依赖。头像上传使用 Spring Boot 内置 `MultipartFile` 处理，前端使用原生 `<input type="file">` + `FormData`。

**前置依赖**：
- `user-crud` 已归档（User 实体 + 基础 CRUD 已存在）
- 认证机制已存在（假设已有登录功能，本期不实现认证）

**后续依赖**：
- `user-notifications` 和 `user-direct-messages` 依赖本变更提供的用户展示信息（头像、昵称）

**产品需求文档**：`docs/user-module/prd-profile.md`
**交互规格文档**：`docs/user-module/interaction-profile.md`
