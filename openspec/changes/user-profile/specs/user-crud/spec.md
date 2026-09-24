## MODIFIED Requirements

### Requirement: Get User by ID
The system SHALL provide a REST API endpoint `GET /api/users/{id}` that returns a single user by their ID.

#### Scenario: User exists
- **WHEN** a client sends a GET request to `/api/users/{id}` with a valid existing ID
- **THEN** the system SHALL return HTTP 200 with the user object including `id`, `username`, `email`, `nickname`, `bio`, `avatarUrl`, `interestTags`, `createdAt`, and `updatedAt`

#### Scenario: User not found
- **WHEN** a client sends a GET request with an ID that does not exist
- **THEN** the system SHALL return HTTP 404 with an error message

### Requirement: List Users
The system SHALL provide a REST API endpoint `GET /api/users` that returns all users.

#### Scenario: List with existing users
- **WHEN** a client sends a GET request to `/api/users`
- **THEN** the system SHALL return HTTP 200 with a list of all user objects, each including `id`, `username`, `email`, `nickname`, `bio`, `avatarUrl`, `interestTags`, `createdAt`, and `updatedAt`

#### Scenario: List when empty
- **WHEN** no users exist in the database
- **THEN** the system SHALL return HTTP 200 with an empty list

### Requirement: Update User
The system SHALL provide a REST API endpoint `PUT /api/users/{id}` that updates an existing user's `username` and/or `email`.

#### Scenario: Successful update
- **WHEN** a client sends a PUT request with valid fields for an existing user ID
- **THEN** the system SHALL return HTTP 200 with the updated user object including `id`, `username`, `email`, `nickname`, `bio`, `avatarUrl`, `interestTags`, `createdAt`, and a new `updatedAt` timestamp

#### Scenario: User not found
- **WHEN** a client sends a PUT request for a non-existent user ID
- **THEN** the system SHALL return HTTP 404 with an error message
