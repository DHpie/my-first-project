## 1. 后端数据模型扩展

- [ ] 1.1 在 `entity/User.java` 中新增 `nickname`（VARCHAR(30)）、`bio`（VARCHAR(200)）、`avatarUrl`（VARCHAR(500)）、`interestTags`（VARCHAR(200)）四个字段，添加对应 getter/setter，验证编译通过
- [ ] 1.2 配置 `application-dev.yml` 中 `spring.jpa.hibernate.ddl-auto=update`（或编写 Flyway/Liquibase 迁移脚本），启动后端验证 `users` 表新增列正确
- [ ] 1.3 更新 `dto/response/` 中 User 相关 DTO，包含新字段 `nickname`、`bio`、`avatarUrl`、`interestTags`，验证 `GET /api/users` 和 `GET /api/users/{id}` 响应包含新字段

## 2. 头像上传 API

- [ ] 2.1 创建 `service/ProfileService.java` 接口和 `service/impl/ProfileServiceImpl.java`，实现头像上传逻辑（MultipartFile 接收、MIME type + 扩展名校验、2MB 大小限制、UUID 文件名生成、存储到 `uploads/avatars/` 目录），验证上传逻辑正确
- [ ] 2.2 创建 `controller/AvatarController.java`，实现 `POST /api/profile/avatar` 端点（`multipart/form-data`），返回 `Result<AvatarUploadResponse>`（含 `avatarUrl` 字段），验证成功上传返回 200
- [ ] 2.3 实现文件类型校验（仅 JPG/PNG/WebP），验证无效类型返回 HTTP 400 + "Please upload a JPG, PNG, or WebP image"
- [ ] 2.4 实现文件大小校验（≤ 2MB），验证超限返回 HTTP 400 + "File size must be under 2MB"
- [ ] 2.5 实现旧头像异步清理（上传新头像后删除旧文件），验证旧文件被清理
- [ ] 2.6 配置 Spring Boot 静态资源映射，将 `/uploads/avatars/**` 映射到 `uploads/avatars/` 目录，验证通过 HTTP 可直接访问头像文件
- [ ] 2.7 配置 `application.yml` 中 `spring.servlet.multipart.max-file-size=2MB` 和 `max-request-size=2MB`，验证配置生效

## 3. 资料查看与编辑 API

- [ ] 3.1 在 `ProfileService` 中实现 `GET /api/profile` 逻辑（根据当前登录用户 ID 查询完整资料），创建 `dto/response/ProfileResponse.java`
- [ ] 3.2 创建 `controller/ProfileController.java`，实现 `GET /api/profile` 端点，验证返回当前用户完整资料（含新字段）
- [ ] 3.3 创建 `dto/request/ProfileUpdateRequest.java`（`nickname`、`bio`、`interestTags` 字段），实现校验逻辑：昵称非空、≤30 字符、无 HTML 标签；简介 ≤200 字符；标签 ≤5 项且在预定义列表中
- [ ] 3.4 在 `ProfileController` 中实现 `PUT /api/profile` 端点，验证成功编辑返回 200 + 更新后资料
- [ ] 3.5 实现所有校验场景：昵称为空 → 400、昵称超长 → 400、昵称含 HTML → 400、简介超长 → 400、标签超量 → 400、标签无效 → 400，验证各返回正确错误信息
- [ ] 3.6 实现 `GET /api/profile/tags` 端点，返回 10 项预定义标签列表 `["History","Food","Nature","Photography","Adventure","Culture","Shopping","Nightlife","Architecture","Music"]`，验证响应正确
- [ ] 3.7 实现未登录访问保护（`GET /api/profile`、`PUT /api/profile`、`POST /api/profile/avatar`、`GET /api/profile/tags` 均返回 401），验证未登录请求被拒绝

## 4. 前端 API 层与类型定义

- [ ] 4.1 创建 `frontend/src/types/profile.ts`，定义 `Profile`（id, username, email, nickname, bio, avatarUrl, interestTags）、`ProfileUpdateRequest`、`AvatarUploadResponse`、`TagListResponse` 类型，验证 TypeScript 编译通过
- [ ] 4.2 创建 `frontend/src/api/profile.ts`，封装 `getProfile()`、`updateProfile(data)`、`uploadAvatar(file)`、`getTags()` 四个 API 调用，验证 TypeScript 编译通过

## 5. 前端查看页（/profile）

- [ ] 5.1 创建 `frontend/src/app/profile/page.tsx`（Client Component），实现 loading 状态（Skeleton 占位：圆形头像 + 昵称/简介/标签 Skeleton 行），验证 loading 可见
- [ ] 5.2 实现 error 状态（AlertCircle 图标 + "Something went wrong" + Retry 按钮），验证错误状态显示正确
- [ ] 5.3 实现 unauthorized 状态（401 时重定向到 `/login?callbackUrl=/profile`），验证重定向逻辑
- [ ] 5.4 实现 data 状态：头像展示（有头像 → 圆形图片，无头像 → 默认占位图标）、昵称展示（有昵称 → 文本，无 → "Anonymous"）、简介展示（有 → 文本，无 → "No interests yet"）、兴趣标签 badge 展示
- [ ] 5.5 实现 "Edit Profile" 按钮，点击导航到 `/profile/edit`，验证跳转正确
- [ ] 5.6 实现响应式布局：Mobile（< 768px）单列居中 `max-w-[400px]`、Desktop（≥ 768px）`max-w-[560px]`，验证两种布局正确
- [ ] 5.7 实现无障碍：`<title>` 设为 "My Profile - ChinaBuddy"、头像 `alt` 文本、兴趣标签 `role="group"` + `aria-label`，验证屏幕阅读器可识别

## 6. 前端编辑页（/profile/edit）

- [ ] 6.1 创建 `frontend/src/app/profile/edit/page.tsx`（Client Component），实现 loading 状态（并行拉取资料 + 标签列表），验证 loading 可见
- [ ] 6.2 实现头像上传区域：文件选择 → 前端校验（类型 + 大小）→ 上传 → 预览更新 + `ring-2 ring-primary` 高亮，验证上传流程正确
- [ ] 6.3 实现昵称输入（`maxLength={30}` + 字数统计）、简介输入（`maxLength={200}` + 字数统计），验证截断和字数统计正确
- [ ] 6.4 实现兴趣标签选择器：点击选中/取消、最多 5 项限制、超出 toast 提示、未选中标签 disabled 样式（`opacity-40 cursor-not-allowed`），验证选择逻辑正确
- [ ] 6.5 实现 `isDirty` 状态追踪（比较表单当前值与初始值），Save 按钮在 pristine 时 disabled（`opacity-50 cursor-not-allowed`），验证按钮启用/禁用逻辑
- [ ] 6.6 实现保存成功：调用 `PUT /api/profile` → toast "Profile updated successfully"（3s）→ 导航到 `/profile`，验证流程正确
- [ ] 6.7 实现保存失败：API 错误 → toast "Failed to save changes. Please try again."（手动关闭）→ 恢复表单可编辑，验证错误处理正确
- [ ] 6.8 实现响应式布局：Mobile ActionBar 吸底（`sticky bottom-0 bg-background border-t`）、Desktop 正常文档流（`max-w-[480px]`），验证两种布局正确
- [ ] 6.9 实现无障碍：兴趣标签选择器 `role="checkbox"` + `aria-checked` + `aria-label`、字数统计 `aria-live="polite"`，验证屏幕阅读器可识别

## 7. 未保存离开确认

- [ ] 7.1 创建离开确认 Dialog 组件（"Discard changes?" 标题 + "Keep editing" / "Discard" 按钮），实现 `role="alertdialog"` + `aria-labelledby` + `aria-describedby` + 焦点 trap，验证对话框无障碍属性正确
- [ ] 7.2 实现 `isDirty === true` 时点击 Cancel / Back to Profile / 浏览器后退触发对话框，验证对话框弹出
- [ ] 7.3 实现 "Keep editing" 按钮 / Escape / 点击遮罩层关闭对话框，用户留在编辑页，验证交互正确
- [ ] 7.4 实现 "Discard" 按钮关闭对话框并导航到目标页面，验证跳转正确
- [ ] 7.5 实现 `isDirty === false` 时直接导航不弹对话框，验证无对话框弹出
- [ ] 7.6 实现 `beforeunload` 事件监听，浏览器关闭/刷新时显示默认离开确认提示，验证浏览器拦截行为

## 8. 集成与验证

- [ ] 8.1 修改 `frontend/src/components/layout/header.tsx`，添加 Profile 入口链接（需登录后显示），验证 Header 中 Profile 链接可见且可点击
- [ ] 8.2 配置 Next.js rewrites（`next.config.ts`），将 `/uploads/*` 转发到后端 `http://localhost:8080/uploads/*`，验证头像图片可通过前端 URL 访问
- [ ] 8.3 更新 `frontend/src/types/user.ts`，扩展 User 类型包含新字段（nickname, bio, avatarUrl, interestTags），验证 TypeScript 编译通过
- [ ] 8.4 运行 `npm run build` 验证前端构建通过，无 TypeScript 编译错误
- [ ] 8.5 运行 `mvn spring-boot:run` 验证后端启动成功，所有 API 端点可访问
- [ ] 8.6 在浏览器中验证完整流程：查看页四状态切换、编辑页资料修改 + 头像上传 + 标签选择 + 保存、离开确认对话框、响应式布局、无障碍属性（构建通过，待浏览器手动验证）
