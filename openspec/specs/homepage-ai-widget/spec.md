## Purpose

Provides the AI assistant floating entry of the ChinaBuddy homepage: a fixed button at the bottom-right corner that toggles a mini chat window; users can send a message and receive an AI reply.

## Requirements

### Requirement: Floating Button and Chat Window
The widget SHALL render a floating button fixed 24px from the bottom and right edges of the viewport with a z-index above all page content. Clicking the button SHALL toggle a mini chat window; the window SHALL be closed initially. The button SHALL have an accessible label.

#### Scenario: Initial state
- **WHEN** the application loads
- **THEN** the chat window SHALL be closed and only the floating button SHALL be visible

#### Scenario: Toggle open
- **WHEN** a user clicks the floating button while the window is closed
- **THEN** the mini chat window SHALL open

#### Scenario: Toggle close
- **WHEN** a user clicks the floating button while the window is open
- **THEN** the mini chat window SHALL close

#### Scenario: Positioning
- **WHEN** the widget renders
- **THEN** the floating button SHALL be fixed 24px from the bottom and right edges of the viewport and displayed above other page content

### Requirement: Sending Messages
The mini chat window SHALL contain a message list, a text input, and a send button. Sending a non-empty message SHALL call `POST /api/ai/chat` with body `{message}` and append the returned `reply` to the message list. Empty or whitespace-only messages SHALL NOT be sent.

#### Scenario: Successful exchange
- **WHEN** a user enters "Best time to visit Zhangjiajie" and clicks send
- **THEN** a POST request with body `{"message": "Best time to visit Zhangjiajie"}` SHALL be sent to `/api/ai/chat` and the returned `reply` SHALL be appended to the message list within 1 second of the response

#### Scenario: Empty message
- **WHEN** a user clicks send with an empty or whitespace-only input
- **THEN** no request SHALL be sent and the input SHALL receive focus

### Requirement: Message Validation
The `POST /api/ai/chat` endpoint SHALL reject malformed requests with HTTP 400. A request with invalid JSON or wrong Content-Type SHALL return HTTP 400 with message "Invalid request body". A request with an empty or whitespace-only `message` SHALL return HTTP 400 with a user-safe error message. Error messages SHALL NOT expose internal implementation details.

#### Scenario: Malformed request body
- **WHEN** a client sends a POST request with invalid JSON or wrong Content-Type
- **THEN** the system SHALL return HTTP 400 with message "Invalid request body"

#### Scenario: Empty message from server side
- **WHEN** a client sends a POST request with an empty or whitespace-only `message`
- **THEN** the system SHALL return HTTP 400 with a user-safe error message

### Requirement: Stateless Requests and Access Control
Each chat request SHALL be independent and stateless; the server SHALL NOT maintain conversation context between requests. The endpoint SHALL be publicly accessible without authentication in the current version. Both are deliberate MVP decisions and the access decision SHALL be addressed before production use.

#### Scenario: Independent requests
- **WHEN** a client sends two consecutive chat requests
- **THEN** the response to the second request SHALL NOT depend on any state from the first request

### Requirement: Duplicate Submission Prevention
While a chat request is in flight, the send button SHALL be disabled and no duplicate request SHALL be sent.

#### Scenario: Prevent duplicate submission
- **WHEN** the user clicks send while a request is already in progress
- **THEN** the send button SHALL remain disabled and no additional request SHALL be sent

### Requirement: Error Handling
On API failure, the widget SHALL display a user-safe error message inside the chat window, such as "AI assistant is temporarily unavailable. Please try again later." The message SHALL NOT expose internal implementation details.

#### Scenario: API failure
- **WHEN** the chat API request fails
- **THEN** a user-safe error message SHALL appear in the chat window without exposing internal details

### Requirement: Session-Only State
The open/closed state and the message list SHALL exist only for the current page session and SHALL NOT be persisted across page reloads. This is a deliberate MVP decision.

#### Scenario: State reset on reload
- **WHEN** the page is reloaded
- **THEN** the chat window SHALL be closed and the message list SHALL be empty

### Requirement: Out of Scope
The widget SHALL NOT provide real-time notifications, voice input, or cross-session chat history. These exclusions are deliberate MVP decisions.
