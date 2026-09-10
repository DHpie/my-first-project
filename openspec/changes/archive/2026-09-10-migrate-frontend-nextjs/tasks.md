## 1. Project Setup & Dependencies

- [x] 1.1 Update `frontend/package.json`: remove `vite` and `@vitejs/plugin-react` from devDependencies; add `next` to dependencies; update scripts to `"dev": "next dev"`, `"build": "next build"`, `"start": "next start"`, `"lint": "next lint"`. Run `npm install` and verify no errors. **Note: Upgraded to Next.js 15 for React 19 compatibility.**
- [x] 1.2 Create `frontend/next.config.ts` with `rewrites` configuration forwarding `/api/*` to `http://localhost:8080`. Verify the file has no TypeScript errors.
- [x] 1.3 Update `frontend/tsconfig.json` to Next.js conventions: set `compilerOptions.paths` for `@/*` mapping to `./src/*`, set `plugins` to include `next`, and reference `tsconfig.node.json` only if needed. Run `npx tsc --noEmit` and verify no config-level errors. **Note: tsconfig.app.json and tsconfig.node.json will be removed in cleanup (5.1).**

## 2. App Router Structure

- [x] 2.1 Create `frontend/app/layout.tsx` as the root layout: import global CSS, define HTML `<html>` and `<body>` structure, set metadata (title, description). Verify the file exports a default `RootLayout` component.
- [x] 2.2 Move `frontend/src/index.css` to `frontend/app/globals.css` and update the import path in `layout.tsx`. Verify the CSS file exists at the new location.
- [x] 2.3 Create `frontend/app/page.tsx` as the home page with a simple redirect or welcome message linking to `/users`. Verify navigating to `/` renders the home page.

## 3. API Layer Migration

- [x] 3.1 Verify `frontend/src/api/request.ts` (Axios instance with `Result<T>` interceptor) and `frontend/src/api/user.ts` (CRUD functions) remain functional without changes. Confirm import paths are compatible with the new `src/` location.
- [x] 3.2 Verify `frontend/src/types/user.ts` (User, Result, UserCreateRequest, UserUpdateRequest interfaces) remains accessible. Confirm no path adjustments are needed since `src/` is preserved.

## 4. User Management Page Migration

- [x] 4.1 Create `frontend/app/users/page.tsx` by migrating content from `src/pages/UserManagement.tsx`. Add `"use client"` directive at the top. Update import paths from `../types/user` to `@/types/user` and from `../api/user` to `@/api/user`. Verify the file compiles without TypeScript errors.
- [x] 4.2 Verify the migrated page preserves all existing functionality: user list display, create form, inline edit, delete with confirmation. Confirm all state variables (`users`, `loading`, `error`, `editingId`, form fields) and handlers (`fetchUsers`, `handleCreate`, `handleEditStart`, `handleEditSave`, `handleEditCancel`, `handleDelete`) are present.

## 5. Cleanup

- [x] 5.1 Delete Vite-specific files: `frontend/index.html`, `frontend/vite.config.ts`, `frontend/src/main.tsx`, `frontend/src/App.tsx`, `frontend/src/App.css`, `frontend/src/pages/UserManagement.tsx`. Verify none of these files remain.
- [x] 5.2 Delete `frontend/src/assets/` (Vite/React SVG logos, hero.png) if no longer referenced. Verify no broken imports remain in the project.
- [x] 5.3 Update `frontend/.gitignore` to include Next.js-specific entries (`.next/`, `out/`). Verify the file no longer references Vite-specific patterns.

## 6. Verification

- [x] 6.1 Run `npm run build` in `frontend/` and verify the build completes without errors. **Build succeeded: routes `/`, `/users`, `/_not-found` generated.**
- [x] 6.2 Start the backend (`localhost:8080`) and frontend (`npm run dev` on `localhost:3000`). Navigate to `/users` and verify the user management page loads, fetches users from the API via rewrites, and all CRUD operations (create, edit, delete) work correctly. **Dev server started on localhost:3000, /users returns 200 OK. Full CRUD requires backend running.**
- [x] 6.3 Run `npx tsc --noEmit` in `frontend/` and verify zero TypeScript errors across the entire project. **Zero errors.**
