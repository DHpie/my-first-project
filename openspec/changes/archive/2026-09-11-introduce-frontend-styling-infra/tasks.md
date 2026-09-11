## 1. Tailwind CSS 安装与配置

- [x] 1.1 在 `frontend/` 目录下执行 `npm install -D tailwindcss @tailwindcss/postcss`，验证 `package.json` 的 `devDependencies` 包含 `tailwindcss` 和 `@tailwindcss/postcss`
- [x] 1.2 创建 `frontend/postcss.config.mjs`，注册 `@tailwindcss/postcss` 插件，验证文件存在且语法正确
- [x] 1.3 在 `frontend/src/app/globals.css` 顶部添加 `@import "tailwindcss";` 指令，验证文件保存无语法错误

## 2. shadcn/ui 初始化

- [x] 2.1 在 `frontend/` 目录下执行 `npx shadcn@latest init -y -d`，验证 `components.json` 生成且配置为 style=new-york、baseColor=neutral、cssVariables=true
- [x] 2.2 验证 `frontend/src/lib/utils.ts` 生成且导出 `cn()` 函数（基于 `clsx` + `tailwind-merge`）
- [x] 2.3 验证 `frontend/src/app/globals.css` 被 shadcn/ui 初始化覆盖，包含 `:root` 中的 shadcn/ui 主题 CSS variables（`--background`、`--foreground`、`--primary` 等）
- [x] 2.4 验证 `clsx` 和 `tailwind-merge` 已安装至 `package.json`（`cn()` 的依赖）

## 3. 首批 shadcn/ui 组件安装

- [x] 3.1 在 `frontend/` 目录下执行 `npx shadcn@latest add button`，验证 `frontend/src/components/ui/button.tsx` 生成且支持 variant（default/destructive/outline/secondary/ghost/link）和 size（default/sm/lg/icon）props
- [x] 3.2 在 `frontend/` 目录下执行 `npx shadcn@latest add input`，验证 `frontend/src/components/ui/input.tsx` 生成且支持原生 `input` 的所有 props 透传

## 4. lucide-react 安装

- [x] 4.1 在 `frontend/` 目录下执行 `npm install lucide-react`，验证 `package.json` 的 `dependencies` 包含 `lucide-react`
- [x] 4.2 验证所有 homepage spec 引用的图标（`Search`、`Users`、`Map`、`Bot`、`Globe`、`User`）均可从 `lucide-react` 导入（创建临时测试文件导入并检查无报错）

## 5. 构建管线验证

- [x] 5.1 在 `frontend/` 目录下执行 `npm run build`，验证构建零错误完成且产物中包含 Tailwind 生成的 CSS
- [x] 5.2 在 `frontend/` 目录下执行 `npm run lint`，验证 Lint 零错误零警告完成
- [x] 5.3 在 `frontend/` 目录下执行 `npx tsc --noEmit`，验证类型检查零错误完成
- [x] 5.4 在 `frontend/` 目录下执行 `npm run dev`，验证开发服务器正常启动于 `http://localhost:3000` 且页面无样式相关报错
- [x] 5.5 在任意页面组件中使用 Tailwind 工具类（如 `flex`、`md:flex`、`text-3xl`），验证构建产物中生成对应 CSS 规则且页面渲染时样式正确应用
