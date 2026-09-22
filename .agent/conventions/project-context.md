# 项目上下文

## 技术栈约束

### 前端: Next.js 15

| 组件 | 选型 | 版本 |
|------|------|------|
| UI 框架 | React | ^19 |
| 元框架 | Next.js (App Router) | 15 |
| 语言 | TypeScript | ~6 |
| 构建工具 | Next.js 内置 (Turbopack) | -- |
| 样式方案 | Tailwind CSS + shadcn/ui | latest |
| 图标库 | lucide-react | latest |
| 图片优化 | next/image (所有图片必须使用) | 内置 |
| 响应式策略 | 移动优先 (Tailwind 断点前缀) | -- |
| HTTP 客户端 | Axios | ^1.20 |
| 代码检查 | Oxlint | ^1.79 |

### 后端: Spring Boot 3

| 组件 | 选型 | 版本 |
|------|------|------|
| 语言 | Java | 17 |
| 框架 | Spring Boot | 3.3.x |
| ORM | Spring Data JPA + Hibernate | 由 Spring Boot 管理 |
| 数据库 | MySQL | 8.x |
| 构建工具 | Maven (Maven Wrapper) | 由 Spring Boot 管理 |
| 参数校验 | Spring Boot Starter Validation | 由 Spring Boot 管理 |

### 部署

| 目标 | 前端 | 后端 |
|------|------|------|
| 主要 | Vercel | Docker |
| 备选 | Docker | Docker |

## 仓库拓扑

```
backend/src/main/java/com/example/myfirst/
  ├── common/        # 全局共享: Result<T>, ResultCode, GlobalExceptionHandler
  ├── config/        # 配置类 (CORS 等)
  ├── controller/    # REST 控制器
  ├── dto/
  │   ├── request/   # 入站 DTO
  │   └── response/  # 出站 DTO
  ├── entity/        # JPA 实体
  ├── mapper/        # Entity <-> DTO 手动映射
  ├── repository/    # Spring Data JPA 接口
  └── service/       # 业务接口
      └── impl/      # 业务实现

frontend/src/
  ├── api/           # API 调用层 (axios 实例 + 按功能分文件)
  ├── app/           # Next.js App Router 页面 (page.tsx / layout.tsx)
  ├── components/    # 按功能域分目录
  │   ├── <feature>/ # 功能组件 (section + card 等)
  │   ├── layout/    # 布局组件 (header, footer)
  │   └── ui/        # 基础 UI 组件 (shadcn/ui)
  ├── lib/           # 工具函数 (format.ts, utils.ts)
  └── types/         # 全局 TypeScript 类型
```

## 语言边界

- 前端 = 仅 TypeScript
- 后端 = 仅 Java
- 接口 = 基于 REST 的 JSON，所有端点使用 `/api` 前缀

## 禁止动作

- 禁止引入 Vue/Nuxt/Svelte 等前端框架
- 禁止引入 NestJS/Express 等 Node 后端框架
- 禁止使用 Pages Router (已废弃，仅用 App Router)
- 禁止引入竞争性框架 (如 Express, Fastify, Vue, Svelte)
- 禁止绕过 `Result<T>` 统一响应包装
- 禁止在 API 路径中省略 `/api` 前缀
- AI 生成质量优先: 当多种实现方案存在时，选择 AI 训练数据覆盖最多的方案 (如标准 Spring 注解优于自定义抽象)

## 编码原则

- **YAGNI**: 不需要的东西就不要做 -- 不做过度设计
- **DRY**: 不要重复自己 -- 消除重复
- **TDD**: 红 -> 绿 -> 重构 -- 测试驱动开发

## 规约文件语言约定

- 所有规约文件 (`.agent/conventions/` 下的文件) 必须使用**中文**编写
- 代码标识符 (类名、方法名、注解名等) 保持英文原样
- 技术术语首次出现时可附带英文原文，如: 移动优先 (mobile-first)
- 代码示例中的注释使用中文
