## Purpose

Provides the community highlights section of the ChinaBuddy homepage: 3–4 featured UGC post summaries, each with an avatar, username, title, excerpt, and like count. The data is served by a read-only curated API.

## Requirements

### Requirement: Featured Posts API
The backend SHALL provide a REST API endpoint `GET /api/posts/featured` that returns the standard envelope `{code, message, data}` where `data` is an array of 3 to 4 objects, each containing `id`, `avatarUrl`, `username`, `title`, `excerpt`, and `likeCount`. The selection SHALL be curated rather than algorithmically ranked, with no infinite scrolling, and returned in a fixed curated order. The endpoint SHALL be publicly accessible without authentication in the current version; both are deliberate MVP decisions and the access decision SHALL be addressed before production use.

#### Scenario: Successful response
- **WHEN** a client sends a GET request to `/api/posts/featured`
- **THEN** the system SHALL return `code: 200` with `data` containing at least 3 and at most 4 post objects, each with all six fields (`id`, `avatarUrl`, `username`, `title`, `excerpt`, `likeCount`)

#### Scenario: Stable ordering
- **WHEN** a client sends two consecutive GET requests to `/api/posts/featured`
- **THEN** the items SHALL be returned in the same fixed order in both responses

#### Scenario: Server failure
- **WHEN** the server fails to serve the featured posts
- **THEN** the system SHALL return a non-200 `code` with a user-safe `message` that SHALL NOT expose internal implementation details (e.g., SQL errors, stack traces, class names)

### Requirement: Post Summary Rendering
The frontend SHALL fetch the featured posts on mount and render one summary per item. Each summary SHALL display the avatar image, username, title, excerpt, and like count. An excerpt longer than 80 characters SHALL be truncated to 80 characters followed by an ellipsis.

#### Scenario: Summaries rendered
- **WHEN** the API returns 4 posts
- **THEN** exactly 4 summaries SHALL render, each with avatar, username, title, excerpt, and like count

#### Scenario: Excerpt truncation
- **WHEN** a post excerpt exceeds 80 characters
- **THEN** the displayed excerpt SHALL be truncated to 80 characters followed by an ellipsis

### Requirement: Loading, Empty, and Error States
The section SHALL display skeleton placeholders while the request is pending. If the data array is empty, the section SHALL display the message "No featured posts yet". On API failure, the section SHALL display a user-safe error message and a Retry button; clicking Retry SHALL re-fetch the data.

#### Scenario: Loading state
- **WHEN** the request is pending
- **THEN** skeleton placeholders SHALL be displayed in the post summary area

#### Scenario: Empty state
- **WHEN** the API returns an empty array
- **THEN** the section SHALL display the message "No featured posts yet"

#### Scenario: Error state and retry
- **WHEN** the API request fails
- **THEN** a user-safe error message and a Retry button SHALL be displayed; clicking Retry SHALL re-fetch the data

### Requirement: Post Navigation
Clicking a post summary SHALL navigate to `/posts/{id}`. The post detail page is a separate capability unit; a placeholder route is acceptable for this unit's delivery. The homepage section SHALL be read-only: no like interaction or API call SHALL be triggered from the homepage.

#### Scenario: Navigate to detail
- **WHEN** a user clicks a post summary
- **THEN** the application SHALL navigate to `/posts/{id}` using the post's `id`

#### Scenario: Read-only like count
- **WHEN** a user clicks the like count on a homepage post summary
- **THEN** no like state change and no API call SHALL occur from the homepage

### Requirement: Out of Scope
This section SHALL NOT support infinite scrolling, algorithmic ranking, or advertising placements. These exclusions are deliberate MVP decisions.
