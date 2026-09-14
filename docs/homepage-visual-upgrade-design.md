# Homepage Visual Upgrade Design

> Full brand theme overhaul for ChinaBuddy homepage — Chinese Red + Gold color system, glassmorphic effects, scroll-triggered entrance animations, and refined hover transitions. Light mode only.

## 1. Color System & Theme Variables

### 1.1 Brand Colors

| Semantic Role | Value | Usage |
|--------------|-------|-------|
| `--primary` | `#C41E3A` (Chinese Red) | Buttons, links, key CTAs, Header bottom edge gradient |
| `--primary-foreground` | `#FFFFFF` | White text on primary |
| `--accent` | `#D4A017` (Gold) | Tag highlights, icon emphasis, hover glow, decorative lines |
| `--accent-foreground` | `#1A1A1A` | Dark text on gold background |
| `--secondary` | `#FFF5E6` (Warm apricot white) | Card backgrounds, alternating section backgrounds |
| `--secondary-foreground` | `#8B1A2B` (Deep red) | Secondary text |

### 1.2 Neutral Color Adjustments

| Semantic Role | Value | Description |
|--------------|-------|-------------|
| `--background` | `#FFFBF5` (Warm white) | Page base — warm tone instead of pure white |
| `--foreground` | `#1A1A1A` | Primary text color |
| `--muted` | `#F5F0EB` (Warm gray) | Secondary section backgrounds |
| `--muted-foreground` | `#6B6560` (Warm gray text) | Secondary text |
| `--border` | `#E8DDD3` (Warm beige) | Border color, replacing cold gray |
| `--card` | `#FFFFFF` | Card white background |

### 1.3 Gradient Presets (CSS Custom Properties)

```css
/* Brand gradient — Hero overlay, decorative bars */
--gradient-brand: linear-gradient(135deg, #C41E3A 0%, #D4A017 100%);

/* Hero overlay — red-to-gold with transparency over background image */
--gradient-hero-overlay: linear-gradient(
  to bottom,
  rgba(196, 30, 58, 0.65) 0%,
  rgba(212, 160, 23, 0.35) 100%
);

/* Card accent bar gradient — bottom decoration on cards */
--gradient-card-accent: linear-gradient(90deg, #C41E3A 0%, #D4A017 100%);
```

### 1.4 Implementation

- Modify `:root` CSS variables in `globals.css` (light mode only; `.dark` retains existing values unchanged)
- Add `--gradient-brand`, `--gradient-hero-overlay`, `--gradient-card-accent` as CSS custom properties in `:root`
- Components reference gradients via Tailwind arbitrary values (e.g., `bg-[var(--gradient-brand)]`) or inline `style` attributes

---

## 2. Hero Section Visual Upgrade

Preserve existing layout structure (background image + centered content + search form). Enhance depth and impact through visual details.

### 2.1 Background Image Overlay

- **Remove** current `bg-[#1a1a2e]` solid background
- Add **dual-layer gradient overlay** on top of background image:
  - **Bottom layer**: Brand gradient overlay using `var(--gradient-hero-overlay)` (red → gold, top to bottom, opacity 65% → 35%), allowing background image to show through with brand color tint
  - **Top layer**: Transparent-to-`bg-background` gradient fade over the bottom 30% height, creating a smooth visual transition to content below (avoids hard cut)

### 2.2 Title Text

- Headline: Keep white, add subtle `text-shadow: 0 2px 12px rgba(0,0,0,0.4)` for readability over gradient overlay
- Subtitle: Change to `text-white/95`, add `tracking-wide` for typographic refinement
- Entrance animation: Title and subtitle have **fade-in + slight slide-up** on page load (CSS `@keyframes`, staggered delays — headline 0ms, subtitle 150ms, search form 300ms)

### 2.3 Search Form Upgrade

- **Container**: Wrap search form in a glassmorphic capsule — `backdrop-blur-md bg-white/15 border border-white/25 rounded-full`
- **Input**: Transparent background, white text, `placeholder:text-white/60`
- **Button**: Brand red background `bg-[#C41E3A]`, hover `bg-[#A01830]`, white Search icon
- **Focus state**: Gold glow ring `ring-2 ring-[#D4A017]/50` on focus
- **Width**: Adjust from `max-w-xl` to `max-w-lg` (capsule shape suits narrower width)

### 2.4 Hero Height Adjustment

- Mobile `min-h`: `300px` → `360px`
- Desktop `md:min-h`: `500px` → `540px`

### 2.5 Files Involved

| File | Changes |
|------|---------|
| `hero-section.tsx` | Remove `bg-[#1a1e2e]`, adjust min-height, add entrance animation classNames |
| `hero-background.tsx` | Add gradient overlay layers (absolutely positioned divs) |
| `search-form.tsx` | Refactor to glassmorphic capsule style |

---

## 3. Header, Footer & Section Separation

### 3.1 Header Visual Upgrade

Preserve minimal structure (brand name + AI Assistant link), enhance visuals only:

- **Background**: Change from solid `bg-background` to glassmorphic — `backdrop-blur-lg bg-background/80`, content shows through on scroll for depth
- **Bottom edge**: Remove `border-b border-border`, replace with **brand gradient bottom edge** — 1px `bg-gradient-to-r from-[#C41E3A] via-[#D4A017] to-[#C41E3A]`
- **Brand name**: Keep `text-foreground`, hover changes to `text-[#C41E3A]` with `transition-colors`
- **AI Assistant link**: Add a small brand red dot indicator (`h-2 w-2 rounded-full bg-[#C41E3A]`) before the text, suggesting "online/available"

### 3.2 Footer Visual Upgrade

- **Background**: Change to dark `bg-[#1A1A1A]` (near-black), strong contrast with warm white page background for a weighted "closing"
- **Copyright text**: `text-white/60`
- **Links**: `text-white/70`, hover `text-[#D4A017]` (gold) with `transition-colors`
- **Top border**: Remove `border-t border-border`, replace with 2px brand gradient line `bg-gradient-to-r from-[#C41E3A] to-[#D4A017]`, echoing Header bottom edge
- **Brand accent**: `ChinaBuddy` in copyright line highlighted with `text-[#D4A017]` (gold)

### 3.3 Section Divider Component

Insert a geometric divider between Navigation, Destinations, and Community sections:

- Pure CSS implementation — centered thin line (`h-px`), fading to transparent at both ends, with a small diamond decoration in the center
- Line color: `from-transparent via-[#D4A017]/40 to-transparent`
- Decoration: `h-2 w-2 rotate-45 bg-[#D4A017]/40` (gold diamond)
- Width: `max-w-xs mx-auto`

New shared component: `components/ui/section-divider.tsx`

### 3.4 Files Involved

| File | Changes |
|------|---------|
| `header.tsx` | Glassmorphic background + brand gradient bottom edge + brand name hover + AI link dot |
| `footer.tsx` | Dark background + brand gradient top line + gold link hover + brand name highlight |
| `components/ui/section-divider.tsx` | **New** — geometric divider component |
| `page.tsx` | Insert `<SectionDivider />` between Navigation, Destinations, Community |

---

## 4. Card Component Visual Upgrade

### 4.1 Navigation Cards

- **Bottom accent bar**: 3px brand gradient bar at card bottom (`bg-gradient-to-r from-[#C41E3A] to-[#D4A017]`)
- **Icons**: Change from `text-primary` (gray) to `text-[#C41E3A]`, hover `scale-110` with `transition-transform duration-300`
- **Hover**: `hover:-translate-y-1 hover:shadow-xl hover:border-[#D4A017]/30`
- **Active**: `active:translate-y-0` press-back effect
- **Title**: Hover text color changes to `text-[#C41E3A]` with `transition-colors`

### 4.2 Destination Cards

- **Image overlay**: Add subtle bottom gradient `linear-gradient(to top, rgba(0,0,0,0.3) 0%, transparent 50%)` over cover image
- **City name repositioned**: Move from card content area to overlay on cover image, white `font-semibold`
- **Popularity tag**: Change to glassmorphic capsule — `backdrop-blur-sm bg-white/20 text-white border border-white/20`, positioned at cover image bottom-right
- **Card content**: Keep `highlight` text with left 2px brand red vertical line decoration (`border-l-2 border-[#C41E3A]/40 pl-3`)
- **Hover**: Image `scale(1.08)` + card `-translate-y-1 shadow-xl`, bottom accent bar fades in from `opacity-0` to `opacity-100`
- **Entrance animation**: 6 cards staggered fade-in + slide-up, 80ms delay increment per card

### 4.3 Community Post Cards

- **Avatar border**: Add 2px brand red ring `ring-2 ring-[#C41E3A]/30`
- **Like count**: Heart icon from `text-muted-foreground` to `text-[#C41E3A]/60`, hover card changes to `text-[#C41E3A]` with `scale-110` micro-animation
- **Hover**: `hover:-translate-y-1 hover:shadow-xl hover:border-[#D4A017]/30`, consistent with Navigation card interaction language
- **Bottom decoration**: 2px brand gradient bar, fades in on hover
- **Entrance animation**: Staggered fade-in + slide-up, 100ms delay increment

### 4.4 Skeleton Screen Update

- Skeleton base color: `bg-[#FFF5E6]` (warm apricot white), pulse color `bg-[#F0E0CC]`
- Loading state consistent with brand warm tone

### 4.5 Files Involved

| File | Changes |
|------|---------|
| `navigation-section.tsx` | Accent bar + icon color + hover lift |
| `destination-card.tsx` | Image overlay + city name repositioned + vertical line + bottom gradient bar |
| `destinations-section.tsx` | Entrance animation index passing + skeleton colors |
| `post-card.tsx` | Avatar ring + like color + bottom bar + hover lift |
| `community-section.tsx` | Entrance animation index passing + skeleton colors |

---

## 5. Animation System & Responsive Strategy

### 5.1 Scroll-Triggered Entrance Animations

**Implementation**: CSS `@keyframes` + `IntersectionObserver` combination. No additional animation library.

**Shared Hook**: `frontend/src/lib/use-scroll-reveal.ts`

- Wraps `IntersectionObserver` with `threshold: 0.15`
- Adds `data-visible="true"` attribute when element enters viewport
- Components trigger CSS animation via `[data-visible="true"]`

**Animation Definition** (added to `globals.css`):

```css
@keyframes fade-slide-up {
  from {
    opacity: 0;
    transform: translateY(24px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

**Application per Section**:

| Section | Animation | Delay Strategy |
|---------|-----------|----------------|
| Hero headline | fade-slide-up | 0ms (CSS animation on page load) |
| Hero subtitle | fade-slide-up | 150ms |
| Hero search form | fade-slide-up | 300ms |
| Navigation cards (each) | fade-slide-up | +100ms stagger |
| Destinations heading | fade-slide-up | 0ms on viewport entry |
| Destination cards (each) | fade-slide-up | +80ms stagger |
| Community heading | fade-slide-up | 0ms on viewport entry |
| Community cards (each) | fade-slide-up | +100ms stagger |

**Duration**: Uniform `500ms`, `easing: cubic-bezier(0.16, 1, 0.3, 1)` (ease-out-quint)

**Performance**: Only animate `opacity` and `transform` (GPU-accelerated properties), no layout thrashing.

### 5.2 Hover Transition Standards

Unified hover transition language across all cards:

| Property | Duration | Easing |
|----------|----------|--------|
| `transform` (translate-y / scale) | `300ms` | `cubic-bezier(0.16, 1, 0.3, 1)` |
| `box-shadow` | `300ms` | `ease-out` |
| `border-color` | `200ms` | `ease-out` |
| `color` (text/icon) | `200ms` | `ease-out` |
| `opacity` (accent bar reveal) | `300ms` | `ease-out` |

### 5.3 Responsive Strategy

**Preserved**:
- `md:max-w-[1200px] md:mx-auto` container constraint
- Destinations mobile horizontal scroll → desktop 4-column grid
- Community mobile stack → desktop 3/4 column grid

**Enhanced**:

| Breakpoint | Adjustment |
|------------|------------|
| Mobile (< 768px) | Hero search capsule full-width; Navigation cards full-width stack; card accent bars moved to top |
| `md` (768px–1024px) | Navigation 3 cards row; Destinations 4 columns; Community 3 columns |
| `lg` (1024px+) | Container max-width from 1200px to 1280px (`lg:max-w-[1280px]`); Community upgrades to 4 columns |

**Hero Search Responsive**:
- Mobile: Capsule full-width, `mx-3`
- Desktop: `max-w-lg` centered

### 5.4 `prefers-reduced-motion` Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### 5.5 Files Involved

| File | Changes |
|------|---------|
| `globals.css` | Add `@keyframes fade-slide-up`, `prefers-reduced-motion` rules |
| `lib/use-scroll-reveal.ts` | **New** — IntersectionObserver hook |
| `hero-section.tsx` | Hero entrance animation classNames |
| `navigation-section.tsx` | Card entrance animation (useScrollReveal + delay) |
| `destinations-section.tsx` | Card entrance animation (index delay passing) |
| `community-section.tsx` | Card entrance animation (index delay passing) |
| `page.tsx` | Add `lg:max-w-[1280px]` |

---

## 6. File Change Summary

### New Files (2)

| File | Purpose |
|------|---------|
| `frontend/src/lib/use-scroll-reveal.ts` | IntersectionObserver hook for scroll-triggered animations |
| `frontend/src/components/ui/section-divider.tsx` | Gold diamond geometric section divider |

### Modified Files (12)

| File | Changes |
|------|---------|
| `frontend/src/app/globals.css` | Brand color variables, gradients, keyframes, reduced-motion |
| `frontend/src/app/page.tsx` | SectionDivider insertion, lg breakpoint |
| `frontend/src/components/layout/header.tsx` | Glassmorphic bg, brand gradient edge, hover colors |
| `frontend/src/components/layout/footer.tsx` | Dark bg, brand gradient top, gold hover, brand highlight |
| `frontend/src/components/hero/hero-section.tsx` | Remove solid bg, adjust heights, entrance animations |
| `frontend/src/components/hero/hero-background.tsx` | Gradient overlay layers |
| `frontend/src/components/hero/search-form.tsx` | Glassmorphic capsule redesign |
| `frontend/src/components/navigation/navigation-section.tsx` | Accent bars, icon colors, hover lift, entrance animation |
| `frontend/src/components/destinations/destinations-section.tsx` | Entrance animation index, skeleton colors |
| `frontend/src/components/destinations/destination-card.tsx` | Image overlay, repositioned city name, accent bar |
| `frontend/src/components/community/community-section.tsx` | Entrance animation index, skeleton colors |
| `frontend/src/components/community/post-card.tsx` | Avatar ring, like color, accent bar, hover lift |

### Unchanged

`layout.tsx`, `skip-to-content.tsx`, `ai-widget.tsx`, `button.tsx`, `input.tsx`, all API layer files, all backend files.
