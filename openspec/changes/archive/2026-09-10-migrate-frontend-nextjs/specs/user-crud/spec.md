## MODIFIED Requirements

### Requirement: Frontend User Management Page
The frontend SHALL provide a user management page served via Next.js App Router that displays the user list and supports create, edit, and delete operations through the REST API.

#### Scenario: Display user list
- **WHEN** the user navigates to `/users`
- **THEN** the frontend SHALL fetch and display all users from `GET /api/users`

#### Scenario: Create user via UI
- **WHEN** the user fills in the create form with valid data and submits
- **THEN** the frontend SHALL call `POST /api/users` and refresh the list on success

#### Scenario: Edit user via UI
- **WHEN** the user modifies a user's information and submits
- **THEN** the frontend SHALL call `PUT /api/users/{id}` and refresh the list on success

#### Scenario: Delete user via UI
- **WHEN** the user clicks delete on a user record
- **THEN** the frontend SHALL call `DELETE /api/users/{id}` and refresh the list on success

#### Scenario: Client-side interactivity
- **WHEN** the user management page is rendered
- **THEN** the page SHALL be a Next.js Client Component (marked with `"use client"`) because it requires interactive state management (form inputs, editing state, loading state)

#### Scenario: API request routing
- **WHEN** the frontend makes API requests to `/api/*`
- **THEN** Next.js rewrites SHALL transparently forward these requests to the backend at `http://localhost:8080`, replacing the previous Vite dev server proxy configuration

#### Scenario: Root layout
- **WHEN** the application loads for the first time
- **THEN** the Next.js root layout (`app/layout.tsx`) SHALL provide the HTML shell, global styles, and metadata, replacing the previous `main.tsx` + `index.html` bootstrap
