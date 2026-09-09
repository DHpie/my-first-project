## Context

This is a greenfield project with no existing application code. The project repository contains only documentation scaffolding (`openspec/`, `skills/`, `docs/`). The backend and frontend will be introduced as two new top-level directories (`backend/` and `frontend/`) within the existing repository. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- Establish a clean, layered Spring Boot backend architecture that enforces separation of concerns across Controller, Service, Repository, Entity, DTO, and Mapper layers.
- Implement a React + TypeScript frontend that communicates with the backend exclusively through RESTful JSON APIs.
- Demonstrate the full request-response chain end-to-end with a minimal User CRUD feature.
- Codify reusable conventions (unified response format, global exception handling, CORS config) that future features will follow.

**Non-Goals:**

- Authentication and authorization (no Spring Security, no JWT, no login flow).
- Pagination, sorting, or filtering on the list endpoint — return all records.
- Multi-module Maven project or microservice architecture — single Spring Boot module.
- Automated testing (unit/integration) — test infrastructure can be added later.
- CI/CD pipeline, Docker containerization, or deployment configuration.
- Production-grade frontend (no routing, no state management library, no responsive design).

## Decisions

### 1. Single-module Maven project (not multi-module)

**Decision**: Use a single `backend/` directory with one `pom.xml` and one Spring Boot application.

**Rationale**: Multi-module Maven projects add structural complexity (parent POM, module declarations, inter-module dependencies) that provides no benefit for an MVP. A single module keeps the focus on layered architecture within the application, which is the actual learning target. The monolith can be split later if needed.

**Alternatives considered**: Multi-module Maven (e.g., `api/`, `service/`, `dao/` modules) — rejected because module boundaries would duplicate what package-level layering already enforces, at the cost of significantly more POM configuration.

### 2. Spring Data JPA (not MyBatis)

**Decision**: Use Spring Data JPA with Hibernate as the ORM layer.

**Rationale**: JpaRepository provides zero-SQL CRUD out of the box, which lets the MVP focus on architecture and data flow rather than SQL writing. JPA's entity lifecycle management and convention-based query derivation align well with the "learn by clean patterns" goal.

**Alternatives considered**: MyBatis-Plus — more popular in Chinese enterprise projects and offers finer SQL control, but requires explicit SQL for every operation, adding boilerplate that doesn't serve the MVP learning goal.

### 3. DTO/Entity separation with manual mapper (not MapStruct)

**Decision**: Create separate DTO classes (request/response) and a manual mapper class that converts between Entity and DTO using plain Java code.

**Rationale**: A manual mapper makes the conversion logic explicit and easy to understand — every field mapping is visible. This is important for a learning project where understanding what happens at each layer matters more than reducing boilerplate. MapStruct can be adopted later when the pattern is well understood.

**Alternatives considered**: MapStruct (annotation-based code generation) — reduces boilerplate but hides the conversion logic behind generated code, which is counterproductive for learning.

### 4. Unified response wrapper (Result<T>)

**Decision**: All API responses are wrapped in a `Result<T>` object with `code`, `message`, and `data` fields. A `GlobalExceptionHandler` annotated with `@RestControllerAdvice` catches exceptions and returns consistent error responses.

**Rationale**: This is a near-universal pattern in Chinese enterprise Spring Boot projects. Establishing it from day one means every future endpoint automatically follows the convention without per-endpoint boilerplate.

### 5. Vite dev server proxy for CORS during development

**Decision**: Configure Vite's `server.proxy` to forward `/api` requests to `http://localhost:8080` during development. The backend also provides a `WebConfig` with CORS configuration for production or direct API access.

**Rationale**: The proxy approach eliminates CORS issues during development without requiring browser extensions or backend changes. The backend CORS config exists as a safety net for non-proxied access (e.g., Postman testing, production deployment).

### 6. MySQL as the database

**Decision**: Use MySQL 8.x with Spring Data JPA's `spring.jpa.hibernate.ddl-auto=update` for automatic table creation during development.

**Rationale**: MySQL is the most common enterprise database in the target ecosystem. Using `ddl-auto=update` avoids manual DDL scripts during MVP development while JPA generates the schema from Entity annotations.

**Alternatives considered**: H2 in-memory database — simpler setup but less realistic; PostgreSQL — excellent database but MySQL has broader familiarity in the target context.

## Risks / Trade-offs

- **[No authentication]** → The MVP has no security layer. This is acceptable for learning but must be addressed before any real deployment. Mitigation: the layered architecture is designed so that Spring Security can be added as a cross-cutting concern later without restructuring.

- **[ddl-auto=update in development]** → Hibernate auto-creates/updates tables, which can cause data loss or unexpected schema changes. Mitigation: this setting is only in `application-dev.yml`; production profiles will use explicit migration tools (e.g., Flyway) when needed.

- **[No pagination on list endpoint]** → The list-all-users endpoint will return every record. This is fine for MVP data volumes but will not scale. Mitigation: Spring Data JPA's `Pageable` support can be added to the Repository and Controller with minimal changes later.

- **[Manual DTO mapping]** → More verbose than MapStruct but more transparent for learning. Trade-off accepted for educational value.
