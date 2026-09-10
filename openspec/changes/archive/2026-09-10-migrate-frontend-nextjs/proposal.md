## Why

The project's technology selection has been updated: the frontend must migrate from the current Vite + React SPA to Next.js 14 (App Router). This aligns with the binding constraints in `.harness/config.md` — Next.js 14 was selected for its superior AI code generation quality, native Vercel deployment, and alignment with the React ecosystem's architectural direction. The current Vite-based SPA cannot fulfill these goals.

## What Changes

- **BREAKING**: Replace the Vite + React SPA (`frontend/`) with a Next.js 14 App Router project
- Remove Vite-specific entry points (`main.tsx`, `App.tsx`, `index.html`, `vite.config.ts`)
- Adopt Next.js file-based routing via the `app/` directory
- Migrate the existing User Management page to a Next.js route (`app/users/page.tsx`)
- Preserve the existing API layer (Axios client, type definitions, API functions) with minimal adaptation for the Next.js environment
- Replace Vite dev proxy (`/api` → `localhost:8080`) with Next.js `rewrites` in `next.config.ts`
- Add a root layout (`app/layout.tsx`) replacing the current `main.tsx` + `App.tsx` bootstrap
- Update `package.json` scripts (`dev`, `build`, `start`, `lint`) for Next.js conventions
- Backend remains unchanged — all REST endpoints and the `Result<T>` response contract are preserved

## Capabilities

### New Capabilities

_None — this is a framework migration, not a new capability._

### Modified Capabilities

- `user-crud`: The "Frontend User Management Page" requirement is affected by the framework migration. The user-facing behavior (display list, create, edit, delete) remains identical, but the implementation moves from a Vite SPA component to a Next.js App Router page component. The delta spec captures the migration-specific constraints: the page must be a Client Component (due to interactive state), API calls must go through Next.js rewrites, and the root layout must replace the previous `main.tsx` bootstrap.

## Impact

- **Frontend code**: All files under `frontend/src/` will be restructured into `frontend/app/` (Next.js App Router). Existing component logic (`UserManagement.tsx`) and API layer (`api/`, `types/`) will be migrated with adaptations, not rewritten from scratch.
- **Configuration**: `vite.config.ts` → `next.config.ts`; `tsconfig.json` adjusted for Next.js; `package.json` dependencies updated (remove `vite`, `@vitejs/plugin-react`; add `next`).
- **Dependencies removed**: `vite`, `@vitejs/plugin-react`
- **Dependencies added**: `next`
- **Dependencies preserved**: `react`, `react-dom`, `axios`, `typescript`, `oxlint`, `@types/react`, `@types/react-dom`, `@types/node`
- **Deployment**: Frontend deployable to Vercel with zero-config; Docker deployment via `next build` + `next start`.
- **Backend**: No changes. All `/api/*` endpoints and CORS configuration remain as-is.
- **API contract**: No changes. The `Result<T>` envelope, endpoint paths, and request/response shapes are preserved.
