# 个人中心（Profile）PRD

## 1. 背景与目标

境外用户在注册/登录后，需要一个专属的个人中心来管理自己的身份信息。个人中心是用户建立信任感和归属感的核心入口，也是后续社交互动（消息通知、站内信）的基础——所有互动都需要展示用户的头像和昵称。

**目标**：让用户能够查看和编辑自己的公开资料，建立平台身份认同。

## 2. 目标用户与场景

| 用户角色 | 场景 |
|---------|------|
| 新注册用户 | 首次登录后完善个人资料，填写昵称、上传头像 |
| 活跃用户 | 旅行计划变更后更新兴趣标签，以获得更精准的推荐 |
| 内容贡献者 | 更新个人简介以展示旅行经历，增加社区可信度 |

## 3. 用户故事

### US-1.1 查看个人资料

```
As a logged-in user,
I want to view my profile page with my avatar, nickname, bio, and interest tags,
So that I can see how I appear to other users on the platform.

Acceptance Criteria:
- Given I am logged in, When I navigate to /profile, Then I see my avatar (or a default avatar), nickname, bio (or "No bio yet"), and interest tags (or "No interests yet")
- Given I am not logged in, When I navigate to /profile, Then I am redirected to the login page
```

### US-1.2 编辑昵称

```
As a logged-in user,
I want to change my display nickname,
So that I can update how others see me.

Acceptance Criteria:
- Given I am on my profile edit page, When I change my nickname to a new value (1-30 chars, no HTML) and save, Then the nickname is updated and reflected immediately
- Given I submit an empty nickname, When I submit the form, Then I see a validation error "Nickname is required"
- Given I submit a nickname longer than 30 characters, When I submit, Then I see a validation error "Nickname must be 30 characters or less"
```

### US-1.3 上传/更换头像

```
As a logged-in user,
I want to upload a profile photo,
So that other users can recognize me visually.

Acceptance Criteria:
- Given I am editing my profile, When I upload an image file (JPG/PNG/WebP, max 2MB), Then the image is cropped/resized to a square thumbnail and displayed as my new avatar
- Given I upload a file that is not an image or exceeds 2MB, When I submit, Then I see a validation error with the specific reason
- Given I have no avatar uploaded, When my profile is displayed, Then a default placeholder avatar is shown
```

### US-1.4 编辑个人简介

```
As a logged-in user,
I want to write a short bio about myself,
So that other travelers can learn about my travel experience.

Acceptance Criteria:
- Given I am editing my profile, When I enter a bio (max 200 characters) and save, Then the bio is updated
- Given I clear my bio and save, When my profile is viewed, Then "No bio yet" is displayed
```

### US-1.5 管理兴趣标签

```
As a logged-in user,
I want to select interest tags from a predefined list,
So that the platform can personalize content recommendations for me.

Acceptance Criteria:
- Given I am editing my profile, When I see the interest tag selector, Then I see a predefined list of tags and can select/deselect up to 5 tags
- Given I have selected 5 tags, When I try to select a 6th, Then the system prevents selection and shows "Maximum 5 tags allowed"
- Given I save my selected tags, When I view my profile, Then my selected tags are displayed as colored badges
```

## 4. 已确认决策

| 决策项 | 结论 |
|--------|------|
| 头像存储方案 | **本地文件系统**（后端服务器本地存储） |
| 查看他人主页 | **本期不实现**，仅通过消息通知/站内信看到头像+昵称 |
| 兴趣标签初始列表 | 由产品定义，**不需要多语言**，初始列表见下方 |
| 认证机制 | **假设已有登录功能**，本期不实现认证 |

### 兴趣标签初始列表（10 项）

`History`, `Food`, `Nature`, `Photography`, `Adventure`, `Culture`, `Shopping`, `Nightlife`, `Architecture`, `Music`

## 5. 边界清单

| 编号 | 边界场景 | 处理方式 |
|------|---------|---------|
| B-1.1 | 用户尝试查看他人个人资料 | 本期不支持，返回 404 或重定向到自己的 profile |
| B-1.2 | 头像上传并发/重复提交 | 上传后替换旧头像，旧图片异步清理 |
| B-1.3 | 昵称包含特殊字符/emoji | 允许 Unicode 字符（含 emoji），禁止 HTML 标签和前后空格 |
| B-1.4 | 兴趣标签列表变更 | 预定义标签列表由后端配置，前端拉取最新列表；已选标签若不在新列表中，保留展示但不可重新选中 |
| B-1.5 | 资料编辑中途离开 | 未保存的修改不持久化，离开前弹出确认提示 |

## 6. 验收标准汇总

- [ ] 登录用户可访问 `/profile` 查看自己的头像、昵称、简介、兴趣标签
- [ ] 未登录用户访问 `/profile` 被重定向到登录页
- [ ] 昵称可编辑，1-30 字符，不允许 HTML，不允许纯空白
- [ ] 头像支持 JPG/PNG/WebP 上传，限制 2MB，自动生成方形缩略图
- [ ] 无头像时展示默认占位图
- [ ] 简介可编辑，最多 200 字符，清空后显示 "No bio yet"
- [ ] 兴趣标签从 10 项预定义列表中选择，最多 5 个
- [ ] 编辑页离开前未保存时弹出确认提示
