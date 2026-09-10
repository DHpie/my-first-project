## Context

The current frontend is a Vite + React SPA located in `frontend/`. It uses `main.tsx` as the entry point, `App.tsx` as the root component, and a single page component `UserManagement.tsx`. API requests are proxied to the backend via Vite's dev server proxy (`vite.config.ts`). The project's technology selection (`.harness/config.md`) mandates migration to Next.js 14 with App Router. See `proposal.md` for the full motivation.

## Goals / Non-Goals

**Goals:**
- Migrate the frontend from Vite SPA to Next.js 14 App Router without changing any user-facing behavior
- Preserve the existing API contract (`/api/*` endpoints, `Result<T>` envelope) and backend code unchanged
- Establish the Next.js project structure (`app/` directory, root layout, file-based routing) as the foundation for all future frontend development
- Ensure the migrated frontend is deployable to Vercel (primary) and Docker (alternative)

**Non-Goals:**
- Adding new features or pages beyond the existing User Management page
- Converting the User Management page to use Server Components or Server Actions — it remains a Client Component due to its interactive state requirements
- Changing the backend API or response format in any way
- Introducing a UI component library (e.g., shadcn/ui, MUI) — inline styles are preserved as-is
- Setting up authentication, middleware, or edge runtime

## Decisions

### 1. App Router over Pages Router

**Decision**: Use Next.js App Router (`app/` directory) exclusively.

**Rationale**: App Router is the current architectural direction of Next.js and the React ecosystem. Pages Router is considered legacy. The technology selection explicitly forbids Pages Router patterns.

**Alternatives considered**: Pages Router — rejected per project constraints.

### 2. Client Component for User Management

**Decision**: The User Management page SHALL be a Client Component (`"use client"` directive).

**Rationale**: The page uses `useState`, `useEffect`, form event handlers, and `window.confirm` — all browser-only APIs. Converting to a Server Component would require a fundamental rewrite (Server Actions, server-side data fetching) that adds complexity without benefit for this CRUD page.

**Alternatives considered**: 
- Server Component + Server Actions — rejected because it would require changing the API interaction pattern and adds unnecessary complexity for a page that is inherently interactive
- Hybrid (Server Component wrapper with Client Component child) — rejected as over-engineering for a single-page MVP; can be adopted when adding more pages

### 3. Next.js Rewrites over API Route proxy

**Decision**: Use `next.config.ts` `rewrites` to forward `/api/*` to `http://localhost:8080`.

**Rationale**: Rewrites are the direct replacement for Vite's dev proxy. They work in both dev and production, require no custom code, and are transparent to the client. API Routes would add an unnecessary proxy layer.

**Alternatives considered**:
- Custom API Route handlers (`app/api/[...path]/route.ts`) — rejected as unnecessary indirection; rewrites handle this natively
- Environment variable for backend URL in client code — rejected because it would expose the backend URL to the browser and break the `/api/*` contract

### 4. Preserve Axios-based API layer

**Decision**: Keep the existing Axios-based API layer (`api/request.ts`, `api/user.ts`) with minimal path adjustments.

**Rationale**: Axios works identically in Next.js Client Components. The interceptor logic for `Result<T>` unwrapping is valuable and should be preserved. Rewriting to `fetch` adds risk without benefit.

**Alternatives considered**:
- Native `fetch` API — rejected because it would require rewriting the response interceptor logic and adds no meaningful advantage in a Client Component context
- Next.js `server()` functions — rejected because the page is a Client Component

### 5. Project structure

**Decision**: Reuse the existing `frontend/` directory. Replace Vite files with Next.js equivalents:

| Current (Vite) | Target (Next.js) |
|----------------|-------------------|
| `index.html` | Removed (Next.js generates HTML) |
| `vite.config.ts` | `next.config.ts` |
| `src/main.tsx` | `app/layout.tsx` |
| `src/App.tsx` | Removed (layout handles root) |
| `src/pages/UserManagement.tsx` | `app/users/page.tsx` |
| `src/api/*` | `src/api/*` (preserved, moved up) |
| `src/types/*` | `src/types/*` (preserved, moved up) |
| `src/index.css` | `app/globals.css` |

**Rationale**: Keeping `frontend/` as the project root minimizes disruption. The `src/` directory is retained for non-route code (API layer, types) following Next.js convention where `app/` holds routes and `src/` holds supporting modules.

## Risks / Trade-offs

- **[Risk] Import path changes during migration** → Mitigation: All imports in `api/` and `types/` use relative paths; the directory move from `src/` to `src/` (same level) means paths remain stable. Verify with `tsc --noEmit` after migration.
- **[Risk] Next.js version compatibility with React 19** → Mitigation: Next.js 14 supports React 19 via `react` and `react-dom` ^19. Pin exact versions in `package.json` to avoid drift.
- **[Risk] Vercel deployment requires no `next.config.ts` rewrites in production** → Mitigation: In production on Vercel, use Vercel's `rewrites` in `vercel.json` or environment variables for the backend URL. The `next.config.ts` rewrites handle local dev; production routing is configured per deployment target.
- **[Trade-off] Client Component means no SSR for the user list** → Accepted. The page is inherently interactive and the data volume is small. SSR can be added later by wrapping the Client Component in a Server Component that pre-fetches data.
