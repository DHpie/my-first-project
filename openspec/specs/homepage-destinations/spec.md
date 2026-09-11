## Purpose

Provides the hot destinations section of the ChinaBuddy homepage: 4–6 editor-picked destination cards, each with a cover image, city name, one-line highlight, and a heat tag. The data is served by a read-only curated API.

## Requirements

### Requirement: Featured Destinations API
The backend SHALL provide a REST API endpoint `GET /api/destinations/featured` that returns the standard envelope `{code, message, data}` where `data` is an array of 4 to 6 objects, each containing `id`, `cityName`, `coverUrl`, `highlight`, and `heatTag`. The list SHALL be editor-curated seed data with no personalization applied, returned in a fixed curated order. The endpoint SHALL be publicly accessible without authentication in the current version; both are deliberate MVP decisions and the access decision SHALL be addressed before production use.

#### Scenario: Successful response
- **WHEN** a client sends a GET request to `/api/destinations/featured`
- **THEN** the system SHALL return `code: 200` with `data` containing at least 4 and at most 6 destination objects, each with all five fields (`id`, `cityName`, `coverUrl`, `highlight`, `heatTag`)

#### Scenario: Stable ordering
- **WHEN** a client sends two consecutive GET requests to `/api/destinations/featured`
- **THEN** the items SHALL be returned in the same fixed order in both responses

#### Scenario: Server failure
- **WHEN** the server fails to serve the featured destinations
- **THEN** the system SHALL return a non-200 `code` with a user-safe `message` that SHALL NOT expose internal implementation details (e.g., SQL errors, stack traces, class names)

### Requirement: Card Rendering
The frontend SHALL fetch the featured destinations on mount and render one card per item. Each card SHALL display the cover image, city name, one-line highlight, and heat tag.

#### Scenario: Cards rendered
- **WHEN** the API returns 5 destinations
- **THEN** exactly 5 cards SHALL render, each showing cover image, city name, highlight, and heat tag

#### Scenario: Rendering performance
- **WHEN** the API response arrives
- **THEN** the cards SHALL render within 1 second

### Requirement: Loading, Empty, and Error States
The section SHALL display skeleton placeholders while the request is pending. If the data array is empty, the section SHALL display the message "No featured destinations yet". On API failure, the section SHALL display a user-safe error message and a Retry button; clicking Retry SHALL re-fetch the data.

#### Scenario: Loading state
- **WHEN** the request is pending
- **THEN** skeleton placeholders SHALL be displayed in the destination card area

#### Scenario: Empty state
- **WHEN** the API returns an empty array
- **THEN** the section SHALL display the message "No featured destinations yet"

#### Scenario: Error state and retry
- **WHEN** the API request fails
- **THEN** a user-safe error message and a Retry button SHALL be displayed; clicking Retry SHALL re-fetch the data

### Requirement: Destination Navigation
Clicking a destination card SHALL navigate to `/destinations/{id}`. The destination detail page is a separate capability unit; a placeholder route is acceptable for this unit's delivery.

#### Scenario: Navigate to detail
- **WHEN** a user clicks a destination card
- **THEN** the application SHALL navigate to `/destinations/{id}` using the card's `id`

### Requirement: Out of Scope
This section SHALL NOT apply personalized recommendation algorithms (no user profiling), SHALL NOT support infinite scrolling, and SHALL NOT include advertising placements. These exclusions are deliberate MVP decisions.
