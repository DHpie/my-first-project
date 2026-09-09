## Purpose

Provides a full-stack User CRUD capability that demonstrates the complete frontend-backend separated architecture. Users can create, read, update, and delete user records through a web UI backed by a RESTful API, establishing the foundational patterns for all future business features.

## ADDED Requirements

### Requirement: Create User
The system SHALL provide a REST API endpoint `POST /api/users` that accepts a JSON body with `username` (required, max 50 chars) and `email` (required, valid email format) and returns the created user with a system-generated `id` and timestamps.

#### Scenario: Successful creation
- **WHEN** a client sends a POST request to `/api/users` with valid `username` and `email`
- **THEN** the system SHALL return HTTP 200 with the created user object including `id`, `username`, `email`, `createdAt`, and `updatedAt`

#### Scenario: Missing required fields
- **WHEN** a client sends a POST request with missing `username` or `email`
- **THEN** the system SHALL return HTTP 400 with an error message indicating which field is invalid

#### Scenario: Duplicate username
- **WHEN** a client sends a POST request with a `username` that already exists
- **THEN** the system SHALL return HTTP 400 with an error message indicating the username is already taken

### Requirement: Get User by ID
The system SHALL provide a REST API endpoint `GET /api/users/{id}` that returns a single user by their ID.

#### Scenario: User exists
- **WHEN** a client sends a GET request to `/api/users/{id}` with a valid existing ID
- **THEN** the system SHALL return HTTP 200 with the user object

#### Scenario: User not found
- **WHEN** a client sends a GET request with an ID that does not exist
- **THEN** the system SHALL return HTTP 404 with an error message

### Requirement: List Users
The system SHALL provide a REST API endpoint `GET /api/users` that returns all users.

#### Scenario: List with existing users
- **WHEN** a client sends a GET request to `/api/users`
- **THEN** the system SHALL return HTTP 200 with a list of all user objects

#### Scenario: List when empty
- **WHEN** no users exist in the database
- **THEN** the system SHALL return HTTP 200 with an empty list

### Requirement: Update User
The system SHALL provide a REST API endpoint `PUT /api/users/{id}` that updates an existing user's `username` and/or `email`.

#### Scenario: Successful update
- **WHEN** a client sends a PUT request with valid fields for an existing user ID
- **THEN** the system SHALL return HTTP 200 with the updated user object and a new `updatedAt` timestamp

#### Scenario: User not found
- **WHEN** a client sends a PUT request for a non-existent user ID
- **THEN** the system SHALL return HTTP 404 with an error message

### Requirement: Delete User
The system SHALL provide a REST API endpoint `DELETE /api/users/{id}` that removes a user by ID.

#### Scenario: Successful deletion
- **WHEN** a client sends a DELETE request for an existing user ID
- **THEN** the system SHALL return HTTP 200 with a success message and the user SHALL no longer appear in list results

#### Scenario: User not found
- **WHEN** a client sends a DELETE request for a non-existent user ID
- **THEN** the system SHALL return HTTP 404 with an error message

### Requirement: Unified API Response Format
All API endpoints SHALL return responses wrapped in a standard envelope containing `code`, `message`, and `data` fields.

#### Scenario: Successful response
- **WHEN** any API call succeeds
- **THEN** the response body SHALL contain `code: 200`, `message: "success"`, and `data` with the result payload

#### Scenario: Error response
- **WHEN** an API call fails due to client or server error
- **THEN** the response body SHALL contain a non-200 `code`, a descriptive `message`, and `data: null`

### Requirement: Frontend User Management Page
The frontend SHALL provide a user management page that displays the user list and supports create, edit, and delete operations through the REST API.

#### Scenario: Display user list
- **WHEN** the user navigates to the user management page
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
