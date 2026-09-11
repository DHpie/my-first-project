## Purpose

Defines the page-level structure of the ChinaBuddy homepage: section composition and ordering, shared container constraints, page metadata, and mount points for the five homepage region units. The shell is the integration host delivered first with placeholder sections, so every region unit can be developed, tested, and delivered independently.

## Requirements

### Requirement: Homepage Route
The frontend SHALL serve the ChinaBuddy homepage at the root route `/` via Next.js App Router (`src/app/page.tsx`), replacing the current redirect to `/users`. The existing `/users` page SHALL remain accessible at its own route.

#### Scenario: Visit root route
- **WHEN** a user visits `/`
- **THEN** the homepage SHALL render instead of redirecting to `/users`

### Requirement: Page Metadata
The homepage SHALL declare page metadata with `title: "ChinaBuddy — Discover China Like a Local"` and `description: "Your AI-powered travel companion for exploring China"`, replacing the current "My First Project" metadata in the root layout.

#### Scenario: Metadata rendered
- **WHEN** the homepage loads
- **THEN** the document title SHALL contain "Discover China Like a Local" and the meta description SHALL contain "AI-powered travel companion"

### Requirement: Section Composition and Order
The homepage body SHALL compose the following region units in order from top to bottom: Hero (`homepage-hero`), Platform navigation cards (`homepage-navigation`), Hot destinations (`homepage-destinations`), and Featured community posts (`homepage-community`). Each region unit SHALL be a self-contained component with a single default export. The AI assistant widget (`homepage-ai-widget`) SHALL be excluded from the vertical flow and mounted globally in the root layout with fixed positioning.

#### Scenario: Section order
- **WHEN** the homepage renders
- **THEN** the four regions SHALL appear in the order Hero, navigation, destinations, community

#### Scenario: AI widget mounting
- **WHEN** the application loads
- **THEN** the AI widget SHALL be mounted in the root layout (`src/app/layout.tsx`), not inside the homepage page component

### Requirement: Placeholder-First Delivery
Before any region unit is implemented, the shell SHALL render a lightweight placeholder at each mount point, consisting of a fixed minimum height and the region name, so the shell can be delivered and tested independently.

#### Scenario: Region not implemented
- **WHEN** a region unit is not yet implemented
- **THEN** the shell SHALL render its placeholder without breaking page rendering

### Requirement: Shared Container Constraints
The homepage SHALL support three responsive breakpoints: mobile (< 768px), tablet (768px – 1023px), and desktop (≥ 1024px). All content regions SHALL be constrained to a maximum width of 1200px and centered within the viewport. Grid layout per breakpoint for each region is defined in that region unit's spec.

#### Scenario: Shared container
- **WHEN** the homepage renders at any viewport width
- **THEN** all content regions SHALL be centered and no wider than 1200px

### Requirement: Cross-Cutting Out of Scope
The homepage SHALL NOT include, in any region unit, personalized recommendation algorithms (no user profiling), infinite-scroll feeds or algorithmic ranking, advertising placements, or a real-time notification center. These exclusions are deliberate MVP decisions.

#### Scenario: No out-of-scope features
- **WHEN** the homepage renders in any region
- **THEN** none of the four excluded capabilities SHALL be present
