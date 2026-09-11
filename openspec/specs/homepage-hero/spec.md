## Purpose

Provides the brand hero region of the ChinaBuddy homepage: a full-width brand background image, the slogan "Discover China Like a Local", the subtitle "Your AI-powered travel companion for exploring China", and a search box with placeholder "Search destinations, tips, or ask AI...". The search box performs client-side routing only and calls no API.

## Requirements

### Requirement: Hero Visual Content
The hero region SHALL render a full-width background image with vertically centered content containing the slogan "Discover China Like a Local" and the subtitle "Your AI-powered travel companion for exploring China". All copy and imagery SHALL be static assets bundled with the frontend; no API SHALL be called by this unit.

#### Scenario: Exact copy rendering
- **WHEN** the hero renders
- **THEN** the slogan text SHALL equal exactly "Discover China Like a Local" and the subtitle SHALL equal exactly "Your AI-powered travel companion for exploring China"

#### Scenario: Background image
- **WHEN** the hero renders
- **THEN** the background image SHALL cover the full width of the viewport with the text content vertically centered

### Requirement: Search Box Rendering
The hero SHALL contain a single-line text input with the placeholder "Search destinations, tips, or ask AI...".

#### Scenario: Placeholder text
- **WHEN** the hero renders
- **THEN** the search input placeholder SHALL equal exactly "Search destinations, tips, or ask AI..."

### Requirement: Search Submission
The search box SHALL accept submission via the Enter key or a submit button. Submitting a non-empty query SHALL navigate to `/search?q=<URL-encoded query>`. Submitting an empty or whitespace-only query SHALL NOT navigate.

#### Scenario: Valid submission
- **WHEN** a user types "Beijing food" and presses Enter
- **THEN** the browser SHALL navigate to `/search?q=Beijing%20food`

#### Scenario: Empty submission
- **WHEN** a user presses Enter with an empty or whitespace-only input
- **THEN** no navigation SHALL occur, the input SHALL receive focus, and a visible hint message SHALL be displayed

### Requirement: Client-Side Only Behavior
The homepage search box SHALL NOT call any backend API; it performs client-side routing only. Search suggestions, autocomplete, and AI direct-answer behavior are owned by the search results capability, not the homepage. This is a deliberate MVP decision.

#### Scenario: No network requests
- **WHEN** a user interacts with the search box on the homepage
- **THEN** no network request SHALL be sent by the hero unit
