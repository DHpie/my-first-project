## 1. Backend Project Setup

- [x] 1.1 Create `backend/` directory with Maven project structure (`pom.xml`, `src/main/java`, `src/main/resources`, `src/test/java`) and verify the directory layout is correct
- [x] 1.2 Configure `pom.xml` with Spring Boot 3.x parent, Java 17, and dependencies (spring-boot-starter-web, spring-boot-starter-data-jpa, spring-boot-starter-validation, mysql-connector-j, lombok) and verify `mvn clean compile` succeeds
- [x] 1.3 Create `MyFirstApplication.java` main class with `@SpringBootApplication` annotation and verify the application context loads without errors
- [x] 1.4 Create `application.yml` and `application-dev.yml` with MySQL connection config, JPA settings (`ddl-auto: update`), and server port 8080; verify the application starts and connects to MySQL successfully

## 2. Backend Common Layer

- [x] 2.1 Create `Result<T>` unified response class with `code`, `message`, `data` fields and static factory methods (`success()`, `error()`) and verify it serializes to the expected JSON structure
- [x] 2.2 Create `ResultCode` enum with standard HTTP status codes (200 SUCCESS, 400 BAD_REQUEST, 404 NOT_FOUND, 500 INTERNAL_ERROR) and verify enum values are accessible
- [x] 2.3 Create `GlobalExceptionHandler` with `@RestControllerAdvice` that catches `MethodArgumentNotValidException`, `EntityNotFoundException`, and generic `Exception`, returning `Result` responses; verify each exception type returns the correct code and message format

## 3. Backend Domain Layer — Entity, Repository, DTO, Mapper

- [x] 3.1 Create `User` entity with fields (id, username, email, createdAt, updatedAt) using JPA annotations (`@Entity`, `@Table`, `@Id`, `@GeneratedValue`, `@Column`) and lifecycle callbacks for timestamps; verify the `user` table is auto-created in MySQL on startup
- [x] 3.2 Create `UserRepository` interface extending `JpaRepository<User, Long>` and verify it is injectable and provides built-in CRUD methods
- [x] 3.3 Create DTO classes: `UserCreateRequest` (with `@NotBlank` username, `@NotBlank @Email` email), `UserUpdateRequest` (optional username, optional email with `@Email`), `UserResponse` (id, username, email, createdAt, updatedAt); verify validation annotations are recognized
- [x] 3.4 Create `UserMapper` class with static methods to convert between `User` entity and `UserResponse`/`UserCreateRequest`/`UserUpdateRequest`; verify field mappings are correct

## 4. Backend Service and Controller Layer

- [x] 4.1 Create `UserService` interface with methods: `createUser`, `getUserById`, `getAllUsers`, `updateUser`, `deleteUser`; create `UserServiceImpl` implementing all methods with proper DTO-Entity conversion via `UserMapper` and `UserRepository`; verify each method works correctly
- [x] 4.2 Create `UserController` with `@RestController` and `@RequestMapping("/api/users")`, implementing all 5 REST endpoints (POST, GET by id, GET all, PUT, DELETE); each endpoint returns `Result<T>`; verify all endpoints respond correctly via curl or Postman
- [x] 4.3 Create `WebConfig` implementing `WebMvcConfigurer` with CORS configuration allowing `http://localhost:5173` (Vite dev server); verify cross-origin requests from the frontend are accepted

## 5. Backend Verification

- [x] 5.1 Start the backend application and verify it runs on port 8080 without errors; test all 5 CRUD endpoints with curl/Postman and confirm each returns the correct `Result<T>` JSON structure with proper status codes

## 6. Frontend Project Setup

- [x] 6.1 Initialize React + TypeScript project under `frontend/` using Vite (`npm create vite@latest frontend -- --template react-ts`) and verify `npm run dev` starts the dev server on port 5173
- [x] 6.2 Configure `vite.config.ts` with API proxy (`/api` -> `http://localhost:8080`) and verify proxy forwarding works by checking a test request reaches the backend
- [x] 6.3 Create TypeScript type definitions for `User`, `Result<T>`, `UserCreateRequest`, `UserUpdateRequest` under `src/types/` and verify types compile without errors

## 7. Frontend API Layer

- [x] 7.1 Create Axios instance (`src/api/request.ts`) with base URL and response interceptor that unwraps the `Result<T>` envelope; verify the interceptor correctly extracts `data` and handles error codes
- [x] 7.2 Create User API module (`src/api/user.ts`) with functions: `getUsers()`, `getUserById(id)`, `createUser(data)`, `updateUser(id, data)`, `deleteUser(id)`; verify each function calls the correct backend endpoint

## 8. Frontend User Management Page

- [x] 8.1 Create `UserManagement.tsx` page component with user list table displaying id, username, email, createdAt; verify the page fetches and renders the user list from `GET /api/users` on mount
- [x] 8.2 Add create user form (username + email inputs + submit button) to the page; verify submitting the form calls `POST /api/users` and refreshes the list
- [x] 8.3 Add edit functionality (inline or modal form for updating username/email); verify editing calls `PUT /api/users/{id}` and refreshes the list
- [x] 8.4 Add delete functionality (delete button per row with confirmation); verify deleting calls `DELETE /api/users/{id}` and refreshes the list
- [x] 8.5 Wire up `App.tsx` to render `UserManagement` as the main page; verify the full page renders correctly in the browser

## 9. End-to-End Integration Verification

- [x] 9.1 Start both backend (port 8080) and frontend (port 5173) simultaneously; perform full CRUD cycle through the UI (create a user, view it in the list, edit it, delete it) and verify each operation completes successfully with correct data displayed
