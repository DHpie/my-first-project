## Purpose

为 ChinaBuddy 登录用户实现个人资料（Profile）查看与编辑能力。扩展现有 User 实体，新增头像、昵称、个人简介、兴趣标签字段，提供头像上传、资料查看/编辑的 REST API 和前端页面。本变更是所有社交互动功能（消息通知、站内信）的基础依赖——用户展示信息（头像、昵称）是互动通知和个人私信的身份标识。

## ADDED Requirements

### Requirement: 头像上传 API
系统 SHALL 提供 `POST /api/profile/avatar` 端点，接受 `multipart/form-data` 格式的文件上传，将头像存储到本地文件系统并返回头像 URL。

#### Scenario: 成功上传头像
- **WHEN** 登录用户上传一个有效的图片文件（JPG/PNG/WebP，≤ 2MB）
- **THEN** 系统 SHALL 生成 UUID 文件名，存储到 `uploads/avatars/` 目录
- **AND** 返回 HTTP 200，`data` 中包含 `avatarUrl`（如 `/uploads/avatars/{uuid}.jpg`）
- **AND** 更新当前用户的 `avatarUrl` 字段
- **AND** 如果用户之前有头像，旧头像文件 SHALL 被异步清理

#### Scenario: 文件类型无效
- **WHEN** 用户上传非图片文件（如 PDF、TXT）
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Please upload a JPG, PNG, or WebP image"

#### Scenario: 文件超过大小限制
- **WHEN** 用户上传的图片文件超过 2MB
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "File size must be under 2MB"

#### Scenario: 未登录上传
- **WHEN** 未登录用户尝试上传头像
- **THEN** 系统 SHALL 返回 HTTP 401

### Requirement: 资料查看 API
系统 SHALL 提供 `GET /api/profile` 端点，返回当前登录用户的完整个人资料。

#### Scenario: 成功获取资料
- **WHEN** 登录用户请求 `GET /api/profile`
- **THEN** 系统 SHALL 返回 HTTP 200，`data` 包含 `id`、`username`、`email`、`nickname`、`bio`、`avatarUrl`、`interestTags`

#### Scenario: 未登录访问
- **WHEN** 未登录用户请求 `GET /api/profile`
- **THEN** 系统 SHALL 返回 HTTP 401

### Requirement: 资料编辑 API
系统 SHALL 提供 `PUT /api/profile` 端点，更新当前登录用户的昵称、简介和兴趣标签。请求体为 JSON 格式，包含 `nickname`、`bio`、`interestTags` 字段。

#### Scenario: 成功编辑资料
- **WHEN** 登录用户发送 PUT 请求，包含有效的 `nickname`（1-30 字符）、`bio`（≤ 200 字符）、`interestTags`（从 10 项预定义列表中选 ≤ 5 项）
- **THEN** 系统 SHALL 更新用户资料并返回 HTTP 200，`data` 包含更新后的完整资料

#### Scenario: 昵称为空
- **WHEN** 用户提交的 `nickname` 为空字符串或纯空白
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Nickname is required"

#### Scenario: 昵称超过长度限制
- **WHEN** 用户提交的 `nickname` 超过 30 字符
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Nickname must be 30 characters or less"

#### Scenario: 昵称包含 HTML 标签
- **WHEN** 用户提交的 `nickname` 包含 HTML 标签（如 `<script>`、`<b>`）
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Nickname cannot contain HTML tags"

#### Scenario: 简介超过长度限制
- **WHEN** 用户提交的 `bio` 超过 200 字符
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Bio must be 200 characters or less"

#### Scenario: 兴趣标签超过数量限制
- **WHEN** 用户提交的 `interestTags` 超过 5 项
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Maximum 5 tags allowed"

#### Scenario: 兴趣标签不在预定义列表中
- **WHEN** 用户提交的 `interestTags` 中包含不在预定义 10 项列表中的标签
- **THEN** 系统 SHALL 返回 HTTP 400，错误信息 "Invalid interest tag"

#### Scenario: 未登录编辑
- **WHEN** 未登录用户尝试编辑资料
- **THEN** 系统 SHALL 返回 HTTP 401

### Requirement: 兴趣标签列表 API
系统 SHALL 提供 `GET /api/profile/tags` 端点，返回预定义的兴趣标签列表。

#### Scenario: 获取标签列表
- **WHEN** 登录用户请求 `GET /api/profile/tags`
- **THEN** 系统 SHALL 返回 HTTP 200，`data` 包含 10 项标签数组：`["History", "Food", "Nature", "Photography", "Adventure", "Culture", "Shopping", "Nightlife", "Architecture", "Music"]`

### Requirement: 前端查看页
前端 SHALL 提供 `/profile` 路由页面，展示当前登录用户的头像、昵称、简介、兴趣标签，以及 "Edit Profile" 按钮。页面需覆盖 loading / error / unauthorized / data 四个互斥状态。

#### Scenario: 查看页 loading 状态
- **WHEN** 登录用户首次访问 `/profile`，资料 API 请求中
- **THEN** 页面 SHALL 显示 Skeleton 占位（头像圆形 + 昵称/简介/标签 Skeleton 行）

#### Scenario: 查看页 error 状态
- **WHEN** 资料 API 请求失败
- **THEN** 页面 SHALL 显示 AlertCircle 图标 + "Something went wrong" + "Could not load your profile" + Retry 按钮

#### Scenario: 查看页 unauthorized 状态
- **WHEN** API 返回 401
- **THEN** 页面 SHALL 重定向到登录页（`/login?callbackUrl=/profile`）

#### Scenario: 查看页 data 状态——有头像
- **WHEN** 用户有头像 URL
- **THEN** 页面 SHALL 以圆形（`h-24 w-24 rounded-full object-cover`）展示头像

#### Scenario: 查看页 data 状态——无头像
- **WHEN** 用户无头像（`avatarUrl` 为 null）
- **THEN** 页面 SHALL 显示默认占位头像（圆形灰色背景 + `User` 图标）

#### Scenario: 查看页 data 状态——昵称展示
- **WHEN** 用户有昵称
- **THEN** 页面 SHALL 显示昵称文本（`text-xl font-bold`）
- **WHEN** 用户昵称为 null
- **THEN** 页面 SHALL 显示 "Anonymous"（`text-muted-foreground italic`）

#### Scenario: 查看页 data 状态——简介展示
- **WHEN** 用户有简介
- **THEN** 页面 SHALL 显示简介文本
- **WHEN** 用户无简介
- **THEN** 页面 SHALL 显示 "No bio yet"（`italic text-muted-foreground`）

#### Scenario: 查看页 data 状态——兴趣标签展示
- **WHEN** 用户有 1-5 个兴趣标签
- **THEN** 页面 SHALL 以 badge 样式水平居中展示标签
- **WHEN** 用户无兴趣标签
- **THEN** 页面 SHALL 显示 "No interests yet"（`italic text-muted-foreground`）

#### Scenario: 查看页 data 状态——Edit Profile 按钮
- **WHEN** 用户点击 "Edit Profile" 按钮
- **THEN** 页面 SHALL 导航到 `/profile/edit`

### Requirement: 前端编辑页
前端 SHALL 提供 `/profile/edit` 路由页面，提供头像上传、昵称/简介编辑、兴趣标签选择器、保存/取消操作。页面需覆盖 loading / error / unauthorized / editing / saving / save-success / save-error 七个状态。

#### Scenario: 编辑页 loading 状态
- **WHEN** 登录用户首次访问 `/profile/edit`，资料 + 标签列表 API 请求中
- **THEN** 页面 SHALL 显示 Skeleton 占位（同查看页 loading）

#### Scenario: 编辑页头像上传——文件校验
- **WHEN** 用户选择文件上传
- **THEN** 前端 SHALL 校验文件类型（JPG/PNG/WebP）和大小（≤ 2MB）
- **AND** 校验失败时显示对应 toast 错误提示

#### Scenario: 编辑页头像上传——成功
- **WHEN** 文件校验通过并上传成功
- **THEN** 头像预览 SHALL 更新为新图片，显示 `ring-2 ring-primary` 高亮边框

#### Scenario: 编辑页昵称校验
- **WHEN** 用户提交空昵称或纯空白昵称
- **THEN** 表单 SHALL 显示错误 "Nickname is required"（`text-xs text-destructive`）
- **WHEN** 用户输入超过 30 字符
- **THEN** 输入 SHALL 被截断（`maxLength={30}`），字数统计变红

#### Scenario: 编辑页简介校验
- **WHEN** 用户输入超过 200 字符
- **THEN** 输入 SHALL 被截断（`maxLength={200}`）

#### Scenario: 编辑页兴趣标签选择
- **WHEN** 用户点击未选中标签且已选 < 5 个
- **THEN** 标签 SHALL 变为选中状态（`bg-primary text-primary-foreground`）
- **WHEN** 用户尝试选择第 6 个标签
- **THEN** 系统 SHALL 显示 toast "Maximum 5 tags allowed"
- **WHEN** 已选 5 个标签
- **THEN** 未选中标签 SHALL 显示为 disabled（`opacity-40 cursor-not-allowed`）

#### Scenario: 编辑页保存——成功
- **WHEN** 用户点击 "Save Changes" 且 API 返回成功
- **THEN** 页面 SHALL 显示 toast "Profile updated successfully"（3s 自动消失）并导航到 `/profile`

#### Scenario: 编辑页保存——失败
- **WHEN** 用户点击 "Save Changes" 且 API 返回失败
- **THEN** 页面 SHALL 显示 toast "Failed to save changes. Please try again."（手动关闭）并恢复表单可编辑

#### Scenario: 编辑页 Save 按钮启用条件
- **WHEN** 表单无修改（pristine）
- **THEN** Save 按钮 SHALL 为 disabled（`opacity-50 cursor-not-allowed`）
- **WHEN** 表单有修改且通过校验
- **THEN** Save 按钮 SHALL 为 enabled

### Requirement: 未保存离开确认
编辑页 SHALL 在用户有未保存修改时拦截导航意图，弹出确认对话框。

#### Scenario: 触发离开确认
- **WHEN** 用户在编辑页有未保存修改（`isDirty === true`）并尝试导航离开（点击 Cancel、Back to Profile、浏览器后退）
- **THEN** 页面 SHALL 弹出确认对话框 "Discard changes?" + "You have unsaved changes. Are you sure you want to leave this page?"
- **AND** 对话框包含 "Keep editing"（`variant="outline"`）和 "Discard"（`variant="destructive"`）两个按钮

#### Scenario: 点击 Keep editing
- **WHEN** 用户点击 "Keep editing" 或按 Escape 或点击遮罩层
- **THEN** 对话框 SHALL 关闭，用户留在编辑页

#### Scenario: 点击 Discard
- **WHEN** 用户点击 "Discard"
- **THEN** 对话框 SHALL 关闭，未保存修改被丢弃，导航到目标页面

#### Scenario: 无未保存修改时离开
- **WHEN** 表单无修改（`isDirty === false`）且用户点击 Cancel 或 Back to Profile
- **THEN** 页面 SHALL 直接导航到 `/profile`，不弹出对话框

#### Scenario: 浏览器关闭/刷新拦截
- **WHEN** 用户有未保存修改并尝试关闭或刷新浏览器标签页
- **THEN** 浏览器 SHALL 显示默认离开确认提示（`beforeunload` 事件）

### Requirement: 响应式布局
查看页和编辑页 SHALL 支持 Mobile（< 768px）和 Desktop（≥ 768px）两种布局。

#### Scenario: 查看页 Mobile 布局
- **WHEN** 视口宽度 < 768px
- **THEN** 查看页 SHALL 使用单列居中布局（`max-w-[400px] mx-auto px-4`），头像 80×80

#### Scenario: 查看页 Desktop 布局
- **WHEN** 视口宽度 ≥ 768px
- **THEN** 查看页 SHALL 使用居中布局（`max-w-[560px] mx-auto`），头像 96×96

#### Scenario: 编辑页 Mobile 布局
- **WHEN** 视口宽度 < 768px
- **THEN** 编辑页 ActionBar SHALL 吸底（`sticky bottom-0 bg-background border-t`）

#### Scenario: 编辑页 Desktop 布局
- **WHEN** 视口宽度 ≥ 768px
- **THEN** 编辑页 ActionBar SHALL 在正常文档流中，表单最大宽度 `max-w-[480px]`

### Requirement: 无障碍支持
查看页和编辑页 SHALL 满足以下无障碍要求。

#### Scenario: 页面标题
- **WHEN** 页面渲染完成
- **THEN** `<title>` SHALL 设置为 "My Profile - ChinaBuddy"

#### Scenario: 头像 alt 文本
- **WHEN** 头像图片渲染
- **THEN** `alt` 属性 SHALL 为 "{nickname}'s profile photo" 或 "Default avatar"

#### Scenario: 兴趣标签角色
- **WHEN** 兴趣标签选择器渲染
- **THEN** 每个 TagChip SHALL 有 `role="checkbox"` + `aria-checked` + `aria-label="{tag name}"`
- **AND** 容器 SHALL 有 `role="group"` + `aria-label="Interest tags"`

#### Scenario: 离开确认对话框角色
- **WHEN** 离开确认对话框打开
- **THEN** 对话框 SHALL 有 `role="alertdialog"` + `aria-labelledby` + `aria-describedby`
- **AND** 焦点 SHALL trap 在对话框内

#### Scenario: 字数统计播报
- **WHEN** 用户输入昵称或简介
- **THEN** 字数统计区域 SHALL 有 `aria-live="polite"`，屏幕阅读器播报字数变化
