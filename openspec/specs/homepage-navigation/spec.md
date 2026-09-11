## Purpose

Provides the platform navigation section of the ChinaBuddy homepage: three entry cards for the three platforms — Travel Community, Attraction Guides, and AI Assistant — each with an icon, a title, and a one-line description, linking to its platform route.

## Requirements

### Requirement: Entry Cards Configuration
The navigation section SHALL render exactly three entry cards from a static frontend configuration (no API): Travel Community, Attraction Guides, and AI Assistant, in that order. Each card SHALL display an icon, a title, and a one-line description, all non-empty.

#### Scenario: Three cards render
- **WHEN** the homepage renders
- **THEN** exactly 3 cards SHALL display in the order community, guides, AI assistant

#### Scenario: Card content completeness
- **WHEN** a card renders
- **THEN** it SHALL contain an icon, a title, and a one-line description, all non-empty

### Requirement: Navigation Targets
Clicking a card SHALL navigate to its platform route: `/community` for Travel Community, `/guides` for Attraction Guides, and `/ai` for AI Assistant. The platform pages themselves are separate capability units; placeholder routes are acceptable for this unit's delivery.

#### Scenario: Navigate to community
- **WHEN** a user clicks the Travel Community card
- **THEN** the application SHALL navigate to `/community`

#### Scenario: Navigate to guides
- **WHEN** a user clicks the Attraction Guides card
- **THEN** the application SHALL navigate to `/guides`

#### Scenario: Navigate to AI assistant
- **WHEN** a user clicks the AI Assistant card
- **THEN** the application SHALL navigate to `/ai`

### Requirement: Keyboard Accessibility
Each card SHALL be keyboard-focusable and SHALL trigger navigation when the Enter key is pressed while the card has focus.

#### Scenario: Keyboard navigation
- **WHEN** a card has keyboard focus and the user presses Enter
- **THEN** navigation to the card's target route SHALL occur
