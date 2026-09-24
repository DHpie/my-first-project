# 个人中心（Profile）交互规格

## 1. 组件架构总览

```
/profile（查看页）
  └── ProfilePage                     ← 页面容器（Server Component 壳 + Client Component 数据层）
        ├── ProfileHeader             ← 头像 + 昵称 + 编辑按钮
        │     ├── Avatar              ← 头像展示组件
        │     └── NicknameDisplay     ← 昵称文本
        ├── ProfileBio                ← 简介展示区
        └── ProfileTags               ← 兴趣标签展示区
              └── TagBadge × N        ← 单个标签 badge

/profile/edit（编辑页）
  └── ProfileEditPage                 ← 页面容器（Client Component）
        ├── AvatarUploader            ← 头像上传/裁剪组件
        │     ├── AvatarPreview       ← 当前头像预览
        │     ├── UploadTrigger       ← 上传触发区域
        │     └── CropOverlay         ← 裁剪预览浮层
        ├── NicknameField             ← 昵称输入 + 校验
        ├── BioField                  ← 简介输入 + 字数统计
        ├── InterestTagSelector       ← 兴趣标签选择器
        │     └── TagChip × 10        ← 可选标签芯片
        └── ActionBar                 ← 保存 / 取消按钮栏
```

| 组件 | 文件路径 | 类型 |
|------|---------|------|
| `ProfilePage` | `app/profile/page.tsx` | Server Component（路由守卫） + Client Component（数据层） |
| `ProfileEditPage` | `app/profile/edit/page.tsx` | Client Component |
| `Avatar` | `components/profile/avatar.tsx` | Client Component |
| `AvatarUploader` | `components/profile/avatar-uploader.tsx` | Client Component |
| `ProfileBio` | `components/profile/profile-bio.tsx` | Client Component |
| `ProfileTags` | `components/profile/profile-tags.tsx` | Client Component |
| `InterestTagSelector` | `components/profile/interest-tag-selector.tsx` | Client Component |

---

## 2. ProfilePage（查看页）

### 2.1 进入条件

- 路由：`/profile`
- 守卫：需要登录。未登录用户访问时重定向到登录页（登录成功后回跳 `/profile`）

### 2.2 页面状态全表

页面存在 **4 个互斥状态**，按优先级从高到低排列：

| 状态名 | 触发条件 | 视觉表现 |
|--------|---------|---------|
| **loading** | 首次拉取用户资料（API 请求中） | 全面板 Skeleton 占位 |
| **error** | 首次拉取失败（网络错误 / 超时 / 服务端异常） | 错误提示 + Retry 按钮 |
| **unauthorized** | API 返回 401（token 过期 / 未登录） | 重定向到登录页 |
| **data** | 数据成功返回 | 正常渲染个人资料 |

### 2.3 各状态详细视觉表现

#### 2.3.1 loading 状态

```
┌─────────────────────────────────────────────┐
│                                             │
│         [──── 圆形 Skeleton 96×96 ────]     │  ← 头像占位
│                                             │
│         [──── Skeleton 文字 120px ────]     │  ← 昵称占位
│                                             │
│    ┌───────────────────────────────────┐    │
│    │ [── Skeleton 行1 ──────────────]  │    │  ← 简介占位
│    │ [── Skeleton 行2 (60%) ──────]    │    │
│    └───────────────────────────────────┘    │
│                                             │
│    [○ Skeleton] [○ Skeleton] [○ Skeleton]  │  ← 标签占位
│                                             │
│              [ Edit Profile ]               │  ← 编辑按钮 Skeleton
└─────────────────────────────────────────────┘
```

- 头像：`h-24 w-24 rounded-full animate-pulse bg-muted`，居中
- 昵称：`h-5 w-32 rounded animate-pulse bg-muted`，居中
- 简介：两行 Skeleton，`h-4 rounded bg-muted`，第二行宽度 60%
- 标签：3 个 `h-6 w-20 rounded-full animate-pulse bg-muted`，水平排列 `gap-2`
- 编辑按钮：`h-8 w-28 rounded-lg animate-pulse bg-muted`

#### 2.3.2 error 状态

```
┌─────────────────────────────────────────────┐
│                                             │
│              ⚠️ (AlertCircle, 48×48)        │
│              text-muted-foreground           │
│                                             │
│          "Something went wrong"              │
│       "Could not load your profile"         │
│                                             │
│              [ Retry ]                      │
│                                             │
└─────────────────────────────────────────────┘
```

- 图标：`lucide-react` 的 `AlertCircle`，48×48，`text-muted-foreground`
- 主文案：`text-base font-medium text-foreground`，"Something went wrong"
- 副文案：`text-sm text-muted-foreground`，"Could not load your profile"
- Retry 按钮：`variant="outline"`，点击后进入 **loading** 状态
- Retry 按钮在请求中：显示 loading spinner + disabled，防止重复提交

#### 2.3.3 unauthorized 状态

- 不渲染任何 UI，直接执行 `redirect("/login?callbackUrl=/profile")`
- 视觉表现：页面瞬间空白（Next.js 服务端重定向，用户无感知）

#### 2.3.4 data 状态（正常渲染）

```
┌─────────────────────────────────────────────┐
│                                             │
│            [ Avatar 96×96 ]                 │
│         (圆形, object-cover)                │
│                                             │
│             TravelerJohn                     │  ← text-xl font-bold
│                                             │
│    ┌───────────────────────────────────┐    │
│    │ "Exploring China one city at a    │    │  ← text-sm text-muted-foreground
│    │  time 🌏 Food & history lover"    │    │
│    └───────────────────────────────────┘    │
│                                             │
│    [ Food ] [ History ] [ Photography ]     │  ← 标签 badges
│                                             │
│              [ Edit Profile ]               │  ← variant="outline"
└─────────────────────────────────────────────┘
```

### 2.4 各子区域 data 态规格

#### 2.4.1 Avatar 组件

| 场景 | 视觉表现 |
|------|---------|
| 有头像 | `h-24 w-24 rounded-full object-cover ring-2 ring-border`，使用 `next/image` 渲染 |
| 无头像 | `h-24 w-24 rounded-full bg-muted flex items-center justify-center`，内部显示 `lucide-react` 的 `User` 图标，32×32，`text-muted-foreground` |
| 图片加载失败 | 降级为无头像默认样式 + toast "Failed to load avatar" |

#### 2.4.2 昵称展示

| 场景 | 视觉表现 |
|------|---------|
| 有昵称 | `text-xl font-bold text-foreground text-center` |
| 昵称为空（理论上不应出现） | 显示 "Anonymous"，`text-muted-foreground italic` |

#### 2.4.3 简介展示

| 场景 | 视觉表现 |
|------|---------|
| 有简介 | `text-sm text-muted-foreground text-center max-w-[400px] mx-auto`，支持换行 |
| 无简介 | 显示 "No bio yet"，`text-sm text-muted-foreground italic text-center` |

#### 2.4.4 兴趣标签展示

| 场景 | 视觉表现 |
|------|---------|
| 有标签（1-5 个） | 水平排列 `flex flex-wrap justify-center gap-2`，每个标签为 badge 样式 |
| 无标签 | 显示 "No interests yet"，`text-sm text-muted-foreground italic text-center` |

**TagBadge 样式**：
```
bg-secondary text-secondary-foreground
text-xs font-medium
px-3 py-1 rounded-full
```

#### 2.4.5 Edit Profile 按钮

| 状态 | 视觉表现 |
|------|---------|
| default | `variant="outline"`，`lucide-react` 的 `Pencil` 图标 + "Edit Profile" |
| hover | `bg-muted`（shadcn/ui outline 变体自带） |
| focus-visible | `outline outline-2 outline-ring` |

点击后跳转到 `/profile/edit`。

---

## 3. ProfileEditPage（编辑页）

### 3.1 进入条件

- 路由：`/profile/edit`
- 守卫：需要登录。未登录用户重定向到登录页
- 前置：用户资料数据必须已加载（从 `/profile` 进入时通过 URL state 或 API 重新拉取）

### 3.2 页面状态全表

编辑页存在 **6 个互斥或叠加状态**：

| 状态名 | 触发条件 | 视觉表现 |
|--------|---------|---------|
| **loading** | 首次拉取用户资料 + 兴趣标签列表 | 全面板 Skeleton（同查看页 loading） |
| **error** | 首次拉取失败 | 错误提示 + Retry 按钮（同查看页 error） |
| **unauthorized** | API 返回 401 | 重定向到登录页 |
| **editing** | 数据加载完成，用户正在编辑 | 正常渲染编辑表单 |
| **saving** | 用户点击 Save，API 请求中 | Save 按钮 loading + 全表单 disabled |
| **save-success** | 保存成功 | toast 提示 + 跳转到 `/profile` |
| **save-error** | 保存失败 | toast 错误提示 + 表单恢复可编辑 |

### 3.3 editing 状态布局

```
┌─────────────────────────────────────────────┐
│  ← Back to Profile                          │  ← 返回链接
│                                             │
│         [ Avatar 96×96 ]                    │
│         [ Change photo ]                    │  ← 文字按钮
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │ Nickname                                ││
│  │ [ TravelerJohn_______________ ]         ││  ← Input, maxLength=30
│  │   18/30                                 ││  ← 字数统计（可选）
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │ Bio                                     ││
│  │ ┌───────────────────────────────────┐   ││
│  │ │ Exploring China one city at a     │   ││  ← textarea, maxLength=200
│  │ │ time 🌏                           │   ││
│  │ └───────────────────────────────────┘   ││
│  │   35/200                                ││  ← 字数统计
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │ Interests (select up to 5)             ││
│  │                                         ││
│  │ [✓Food] [✓History] [✓Photography]     ││  ← 已选标签（高亮）
│  │ [ Nature ] [ Adventure ] [ Culture ]    ││  ← 未选标签（常规）
│  │ [ Shopping ] [ Nightlife ]              ││
│  │ [ Architecture ] [ Music ]              ││
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │          [ Cancel ]  [ Save Changes ]   ││  ← ActionBar
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

### 3.4 各编辑组件交互规格

#### 3.4.1 AvatarUploader

**Props 定义**

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `currentAvatar` | `string \| null` | 是 | — | 当前头像 URL |
| `onAvatarChange` | `(file: File) => void` | 是 | — | 选择新文件回调 |

**状态定义**

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **default** | 初始状态 | 显示当前头像（或默认占位）+ 悬浮时出现半透明遮罩 + "Change photo" 文字 |
| **hover** | 鼠标悬浮头像 | 半透明黑色遮罩 `bg-black/40` + 白色 "Change photo" 文字 + `cursor-pointer` |
| **uploading** | 文件已选，上传中 | 头像区域显示圆形 progress ring（`border-4 border-primary border-t-transparent animate-spin`），覆盖在头像上 |
| **preview** | 上传成功，等待最终保存 | 显示新头像预览，`ring-2 ring-primary` 高亮边框 |
| **error** | 上传失败 | toast 错误提示，头像恢复为上传前状态 |

**交互行为**

| 用户操作 | 系统响应 |
|---------|---------|
| 点击头像区域 | 打开系统文件选择对话框（`<input type="file" hidden>` 触发） |
| 选择文件 | 前端校验 → 通过则上传预览；不通过则 toast 错误 |
| 拖拽文件到头像 | 同点击选择（`onDrop` 事件处理） |
| 拖拽悬浮 | 头像区域 `ring-2 ring-dashed ring-primary` 虚线高亮 |

**文件校验规则**

| 校验项 | 规则 | 失败提示（toast） |
|--------|------|-----------------|
| 文件类型 | 仅 JPG / PNG / WebP | "Please upload a JPG, PNG, or WebP image" |
| 文件大小 | ≤ 2MB | "File size must be under 2MB" |
| 非图片文件 | MIME type 校验 | "Please upload a valid image file" |

#### 3.4.2 NicknameField

**Props 定义**

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `initialValue` | `string` | 是 | — | 当前昵称 |
| `onChange` | `(value: string) => void` | 是 | — | 值变化回调 |

**状态定义**

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **pristine** | 初始值，未修改 | Input 正常样式，无错误提示 |
| **dirty** | 用户修改了值 | Input `border-ring`，右下角显示字数统计 |
| **valid** | 值通过校验（1-30 字符，非纯空白，无 HTML） | 正常 Input 样式 |
| **invalid-empty** | 提交时值为空 | Input `border-destructive`，下方显示 "Nickname is required"，`text-xs text-destructive` |
| **invalid-too-long** | 输入超过 30 字符 | 输入被截断（`maxLength={30}`），字数统计变红 `text-destructive` |
| **invalid-whitespace** | 提交时值为纯空白 | 同 invalid-empty 样式，提示 "Nickname cannot be only spaces" |
| **invalid-html** | 输入包含 HTML 标签 | 前端过滤 HTML 标签，不报错，静默移除 |

**字数统计**

- 位置：Input 右下方
- 格式：`{currentLength}/30`
- 样式：`text-xs`；`currentLength <= 25` 时 `text-muted-foreground`；`currentLength > 25` 时 `text-accent`；`currentLength === 30` 时 `text-destructive`

#### 3.4.3 BioField

**Props 定义**

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `initialValue` | `string` | 是 | — | 当前简介 |
| `onChange` | `(value: string) => void` | 是 | — | 值变化回调 |

**状态定义**

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **pristine** | 初始值，未修改 | textarea 正常样式 |
| **dirty** | 用户修改了值 | textarea `border-ring`，右下角显示字数统计 |
| **empty** | 简介被清空 | 字数统计显示 "0/200"，保存后显示 "No bio yet" |
| **near-limit** | 字数 > 180 | 字数统计 `text-accent` |
| **at-limit** | 字数 === 200 | 字数统计 `text-destructive`，输入被截断（`maxLength={200}`） |

**textarea 规格**

- 行数：`rows={3}`
- 最大高度：`max-h-[120px]`，超出后内部滚动
- 字数统计位置：textarea 右下方外侧
- 字数统计格式：`{currentLength}/200`

#### 3.4.4 InterestTagSelector

**Props 定义**

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `availableTags` | `string[]` | 是 | — | 可选标签列表（10 项） |
| `selectedTags` | `string[]` | 是 | — | 当前已选标签 |
| `maxSelect` | `number` | 否 | `5` | 最大可选数量 |
| `onChange` | `(tags: string[]) => void` | 是 | — | 选择变化回调 |

**TagChip 状态定义**

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **unselected** | 未选中 | `bg-muted text-muted-foreground border border-border`，`hover:bg-muted/80`，`cursor-pointer` |
| **selected** | 已选中 | `bg-primary text-primary-foreground`，左侧显示 `✓` 图标 |
| **disabled** | 已选 5 个，当前未选中 | `opacity-40 cursor-not-allowed`，不可点击 |
| **hover** | 未选中标签悬浮 | `bg-muted/80`，`transition-colors duration-150` |
| **focus-visible** | 键盘聚焦 | `outline outline-2 outline-ring outline-offset-1` |
| **orphaned** | 标签已不在 availableTags 中但用户之前选了 | 正常展示为 selected，但不可重新选中（取消后该标签消失） |

**交互行为**

| 用户操作 | 系统响应 |
|---------|---------|
| 点击未选中标签（已选 < 5） | 标签变为 selected，`selectedTags` 数组追加 |
| 点击未选中标签（已选 = 5） | 标签不可选中，显示 toast "Maximum 5 tags allowed"（2s 自动消失） |
| 点击已选中标签 | 标签变为 unselected，`selectedTags` 数组移除 |
| 从 5 个减到 4 个 | 之前 disabled 的标签恢复可点击 |

**布局**

- 容器：`flex flex-wrap gap-2`
- TagChip：`px-3 py-1.5 rounded-full text-sm font-medium transition-colors duration-150`

#### 3.4.5 ActionBar

**布局**

- 容器：`flex justify-end gap-3`，固定在表单底部
- Mobile：`sticky bottom-0 bg-background border-t border-border py-3 -mx-4 px-4`（吸底）
- Desktop：正常文档流

**按钮规格**

| 按钮 | variant | 行为 |
|------|---------|------|
| Cancel | `variant="outline"` | 触发离开确认（如果有未保存修改）或直接返回 `/profile` |
| Save Changes | `variant="default"` | 触发保存 API 调用 |

**Save Changes 状态**

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **enabled** | 表单有修改（dirty）且通过校验 | 正常 primary 样式，`cursor-pointer` |
| **disabled** | 表单无修改（pristine）或校验不通过 | `opacity-50 cursor-not-allowed` |
| **saving** | API 请求中 | 显示 spinner + "Saving..."，disabled |

**防重复提交**

- Save 按钮在 saving 状态时 disabled + `pointer-events-none`
- 内部使用 ref 标记请求进行中，忽略额外点击

### 3.5 saving 状态

```
┌─────────────────────────────────────────────┐
│  （表单所有输入变为 disabled）               │
│                                             │
│         [ Avatar ] (disabled overlay)       │
│                                             │
│  Nickname: [ TravelerJohn ] (disabled)      │
│  Bio: [ Exploring China... ] (disabled)     │
│  Interests: [✓Food] [✓History] (disabled)  │
│                                             │
│          [ Cancel ]  [ ⟳ Saving... ]        │
│           (disabled)    (disabled)           │
└─────────────────────────────────────────────┘
```

- 所有 Input / textarea / TagChip 变为 `disabled` 状态
- Save 按钮：显示 `lucide-react` 的 `Loader2` 图标（`animate-spin`）+ "Saving..."
- Cancel 按钮：disabled

### 3.6 save-success 状态

- 显示 toast "Profile updated successfully"（3s 自动消失）
- 自动跳转到 `/profile`，页面展示更新后的数据
- 无其他视觉变化

### 3.7 save-error 状态

- 显示 toast "Failed to save changes. Please try again."（手动关闭）
- 表单恢复可编辑状态（所有输入 enabled）
- 用户修改后可再次点击 Save

---

## 4. 离开确认对话框（Unsaved Changes Dialog）

### 4.1 触发条件

用户在编辑页有未保存修改（`isDirty === true`）时：
- 点击 Cancel 按钮
- 点击 "Back to Profile" 链接
- 浏览器后退 / 前进
- 直接修改 URL 导航

### 4.2 对话框视觉

```
┌───────────────────────────────────┐
│                                   │
│   Discard changes?                │  ← text-lg font-semibold
│                                   │
│   You have unsaved changes.       │
│   Are you sure you want to        │  ← text-sm text-muted-foreground
│   leave this page?                │
│                                   │
│   [ Keep editing ]  [ Discard ]   │
│                                   │
└───────────────────────────────────┘
```

- 使用 shadcn/ui Dialog 组件
- 背景遮罩：`bg-black/50`
- 对话框：`bg-popover rounded-lg shadow-lg p-6 w-[360px]`
- "Keep editing"：`variant="outline"`，关闭对话框，留在编辑页
- "Discard"：`variant="destructive"`，丢弃修改并导航

### 4.3 状态定义

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **closed** | 无未保存修改，或用户未触发导航 | 不渲染 |
| **open** | 有未保存修改 + 触发导航意图 | Dialog 弹出，焦点 trap 在对话框内 |

### 4.4 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 点击 "Keep editing" | 关闭对话框，留在编辑页，焦点回到触发导航的元素 |
| 点击 "Discard" | 关闭对话框，丢弃所有未保存修改，导航到目标页面 |
| 按 `Escape` | 等同于 "Keep editing" |
| 点击遮罩层 | 等同于 "Keep editing" |

### 4.5 浏览器导航拦截

- 使用 `beforeunload` 事件拦截浏览器关闭/刷新
- `event.returnValue` 设置为浏览器默认提示文案
- Next.js `useRouter` 的 `beforePopState` 拦截浏览器后退/前进

---

## 5. Toast 通知汇总

| Toast 类型 | 触发场景 | 文案 | 持续时间 |
|-----------|---------|------|---------|
| **success** | 保存成功 | "Profile updated successfully" | 3s，自动消失 |
| **error** | 保存失败 | "Failed to save changes. Please try again." | 手动关闭 |
| **error** | 头像上传失败（文件校验） | "Please upload a JPG, PNG, or WebP image" / "File size must be under 2MB" | 3s，自动消失 |
| **error** | 头像上传失败（网络） | "Failed to upload avatar. Please try again." | 手动关闭 |
| **error** | 头像加载失败 | "Failed to load avatar" | 3s，自动消失 |
| **warning** | 尝试选择第 6 个标签 | "Maximum 5 tags allowed" | 2s，自动消失 |
| **info** | 加载兴趣标签列表失败 | "Could not load interest tags" | 手动关闭 |

---

## 6. 完整页面状态流转图

### 6.1 查看页（/profile）

```
  用户访问 /profile
       │
       ▼
  ┌──────────────┐
  │  已登录？     │
  └──┬────────┬──┘
     │ 否     │ 是
     ▼        ▼
  redirect  ┌────────────┐
  to login  │  loading   │ ← Skeleton 占位
            └─────┬──────┘
                  │
          ┌───────┴────────┐
          │                │
          ▼                ▼
    ┌──────────┐    ┌──────────┐
    │  error   │    │   data   │
    │ (错误+   │    │ (正常    │
    │  Retry)  │    │  渲染)   │
    └────┬─────┘    └────┬─────┘
         │               │
    点击 Retry          点击 Edit Profile
         │               │
         ▼               ▼
    回到 loading     导航到 /profile/edit
```

### 6.2 编辑页（/profile/edit）

```
  用户访问 /profile/edit
       │
       ▼
  ┌──────────────┐
  │  已登录？     │
  └──┬────────┬──┘
     │ 否     │ 是
     ▼        ▼
  redirect  ┌────────────┐
  to login  │  loading   │ ← Skeleton 占位（拉取资料 + 标签列表）
            └─────┬──────┘
                  │
          ┌───────┼────────┐
          │       │        │
          ▼       ▼        ▼
    ┌────────┐ ┌──────┐ ┌──────────┐
    │ error  │ │ 401  │ │ editing  │
    │(错误+  │ │      │ │ (编辑表单)│
    │ Retry) │ │redir │ └────┬─────┘
    └────────┘ └──────┘      │
                      ┌──────┼──────────┐
                      │      │          │
                      ▼      ▼          ▼
                 点击 Save  点击 Cancel  导航离开
                      │      │          │
                      │      ▼          ▼
                      │  ┌──────────────────┐
                      │  │ isDirty?         │
                      │  └──┬──────────┬────┘
                      │     │ 否       │ 是
                      │     ▼          ▼
                      │  直接返回   ┌──────────────┐
                      │            │ Unsaved Dialog│
                      │            └──┬─────────┬──┘
                      │               │         │
                      │          Keep editing  Discard
                      │               │         │
                      │               ▼         ▼
                      │           留在编辑页  返回 /profile
                      │
                      ▼
                ┌───────────┐
                │  saving   │ ← 全表单 disabled
                └─────┬─────┘
                      │
                ┌─────┴──────┐
                │            │
                ▼            ▼
          ┌──────────┐ ┌───────────┐
          │ success  │ │   error   │
          │ toast +  │ │ toast +   │
          │ redirect │ │ 恢复编辑  │
          │ /profile │ │           │
          └──────────┘ └───────────┘
```

---

## 7. 响应式规则

| 断点 | 查看页 `/profile` | 编辑页 `/profile/edit` |
|------|-------------------|----------------------|
| Mobile（< 768px） | 单列居中布局，`max-w-[400px] mx-auto px-4`；头像 80×80；标签 `flex-wrap justify-center` | 单列布局，`px-4`；ActionBar 吸底 `sticky bottom-0`；textarea 全宽 |
| Desktop（≥ 768px，`md:`） | 居中布局，`max-w-[560px] mx-auto`；头像 96×96；标签水平居中 | 表单最大宽度 `max-w-[480px] mx-auto`；ActionBar 正常文档流 |

---

## 8. 无障碍要求

| 要求 | 实现 |
|------|------|
| 页面标题 | `<title>` 设置为 "My Profile - ChinaBuddy" |
| 头像 | `alt="{nickname}'s profile photo"` 或 `alt="Default avatar"` |
| 昵称输入 | `aria-label="Nickname"` + `aria-describedby="nickname-hint"` |
| 简介输入 | `aria-label="Bio"` + `aria-describedby="bio-counter"` |
| 字数统计 | `aria-live="polite"` 区域，屏幕阅读器播报字数变化 |
| 兴趣标签 | 每个 TagChip `role="checkbox"` + `aria-checked` + `aria-label="{tag name}"` |
| 标签选择器 | 容器 `role="group"` + `aria-label="Interest tags"` |
| 离开确认对话框 | `role="alertdialog"` + `aria-labelledby` + `aria-describedby` |
| 焦点管理 | 对话框打开时焦点 trap；关闭后焦点回到触发元素 |
| 错误提示 | Input `aria-invalid="true"` + `aria-describedby` 关联错误文案 |
| 保存按钮 | saving 状态 `aria-busy="true"` |

---

## 9. 动画规格汇总

| 动画 | 触发时机 | CSS 实现 | 时长 |
|------|---------|---------|------|
| Skeleton 脉冲 | loading 状态 | `animate-pulse`（Tailwind 内置） | 2s loop |
| TagChip 选中 | 点击标签切换状态 | `transition-colors duration-150` | 150ms |
| 头像上传 progress | 上传中 | `animate-spin`（`border-4 border-primary border-t-transparent`） | 1s loop |
| 头像切换 | 上传成功预览 | `opacity-0 → opacity-100`，`transition-opacity` | 200ms |
| Dialog 进入 | 离开确认弹出 | shadcn/ui Dialog 默认 `fade-in` + `zoom-in-95` | 150ms |
| Dialog 退出 | 关闭对话框 | shadcn/ui Dialog 默认 `fade-out` + `zoom-out-95` | 100ms |
| 尊重用户偏好 | 系统级减少动画 | 复用 `globals.css` 中 `prefers-reduced-motion` 媒体查询 | 所有动画降为 0.01ms |

---

## 10. 验收清单

### 查看页

- [ ] 未登录访问 `/profile` → 重定向到登录页
- [ ] 已登录访问 `/profile` → 显示 loading Skeleton → 正常渲染个人资料
- [ ] 加载失败 → 显示 error 状态 + Retry 按钮
- [ ] Retry 点击 → 重新 loading → 成功/失败
- [ ] 有头像 → 圆形展示；无头像 → 默认 User 图标占位
- [ ] 头像加载失败 → 降级为默认占位 + toast 提示
- [ ] 有昵称 → 正常展示；昵称为空 → 显示 "Anonymous"
- [ ] 有简介 → 正常展示；无简介 → 显示 "No bio yet"（italic）
- [ ] 有标签 → badge 水平居中展示；无标签 → 显示 "No interests yet"
- [ ] Edit Profile 按钮 → 跳转到 `/profile/edit`

### 编辑页

- [ ] 未登录访问 `/profile/edit` → 重定向到登录页
- [ ] 已登录访问 → 显示 loading Skeleton → 正常渲染编辑表单
- [ ] 加载失败 → 显示 error 状态 + Retry 按钮
- [ ] 头像点击 → 打开文件选择器
- [ ] 上传非图片文件 → toast "Please upload a JPG, PNG, or WebP image"
- [ ] 上传 > 2MB 文件 → toast "File size must be under 2MB"
- [ ] 上传成功 → 头像预览更新，`ring-2 ring-primary`
- [ ] 昵称清空提交 → 错误提示 "Nickname is required"
- [ ] 昵称超过 30 字符 → 输入截断 + 字数统计变红
- [ ] 昵称纯空白提交 → 错误提示 "Nickname cannot be only spaces"
- [ ] 简介清空 → 字数统计 "0/200"，保存后查看页显示 "No bio yet"
- [ ] 简介超过 200 字符 → 输入截断
- [ ] 选择标签（< 5 个） → 标签高亮选中
- [ ] 选择第 6 个标签 → toast "Maximum 5 tags allowed"
- [ ] 取消已选标签 → 标签恢复未选中，disabled 标签恢复可点击
- [ ] 表单无修改 → Save 按钮 disabled
- [ ] 表单有修改 → Save 按钮 enabled
- [ ] 点击 Save → saving 状态（全表单 disabled + spinner）
- [ ] Save 成功 → toast + 跳转 `/profile`
- [ ] Save 失败 → toast 错误 + 表单恢复可编辑
- [ ] 有未保存修改 + 点击 Cancel → 弹出离开确认对话框
- [ ] 有未保存修改 + 浏览器后退 → 弹出离开确认对话框
- [ ] 对话框 "Keep editing" → 关闭对话框，留在编辑页
- [ ] 对话框 "Discard" → 丢弃修改，返回 `/profile`
- [ ] 无未保存修改 + 点击 Cancel → 直接返回 `/profile`
- [ ] Mobile：ActionBar 吸底
- [ ] Desktop：ActionBar 正常文档流
- [ ] 键盘操作：Tab 遍历所有输入，Enter 提交表单
- [ ] 屏幕阅读器：字数统计通过 `aria-live` 播报
- [ ] 减少动画偏好：所有动画降级
