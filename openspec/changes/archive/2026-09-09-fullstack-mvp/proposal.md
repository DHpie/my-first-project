## Why

The project is a blank slate with no application code. The goal is to learn and practice enterprise-level frontend-backend separated development by building a fully working MVP from scratch. Establishing a clean, well-layered architecture early ensures the codebase serves as a solid learning foundation and can be extended with real business features later.

## What Changes

- Introduce a **Spring Boot 3.x backend** under `backend/` with Maven build, Spring Data JPA, and MySQL 8.x, following a strict layered architecture (Controller → Service → Repository).
- Introduce a **React 18 + TypeScript frontend** under `frontend/` with Vite 5 as the build tool and Axios for HTTP communication.
- Implement a **User CRUD** as the minimal business feature to demonstrate the full request-response chain: frontend UI → HTTP API → Controller → Service → Repository → Database → back to UI.
- Establish enterprise conventions from day one: unified API response format (`Result<T>`), global exception handling, CORS configuration, DTO/Entity separation, and RESTful API design.

## Capabilities

### New Capabilities

- `user-crud`: Full-stack User CRUD capability — backend REST API (create, read, update, delete users) with layered architecture, and frontend user management page with list/create/edit/delete operations.

### Modified Capabilities

_(None — this is a greenfield change.)_

## Impact

- **New directories**: `backend/` (Maven project) and `frontend/` (Vite + React project) at the repository root.
- **Dependencies**: Spring Boot 3.x, Spring Data JPA, MySQL Connector, Lombok (backend); React 18, TypeScript, Vite 5, Axios (frontend).
- **Infrastructure**: Requires a running MySQL 8.x instance (or local installation) for the backend to connect.
- **APIs**: Introduces RESTful endpoints under `/api/users` (POST, GET, PUT, DELETE).
- **Configuration**: New `application.yml` / `application-dev.yml` for backend; `vite.config.ts` with API proxy for frontend dev server.
