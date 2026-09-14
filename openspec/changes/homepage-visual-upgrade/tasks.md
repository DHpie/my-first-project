# Homepage Visual Upgrade Implementation Plan

> **For agentic workers:** Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task.

**Goal:** Replace the gray neutral theme with a Chinese Red (#C41E3A) + Gold (#D4A017) brand visual system, adding glassmorphic effects, entrance animations, and refined hover transitions across all homepage sections.

**Architecture:** CSS custom property overrides in `globals.css` drive the brand color system. A shared `useScrollReveal` Hook (IntersectionObserver) powers scroll-triggered entrance animations. New `SectionDivider` component adds geometric decoration between sections. All visual effects use Tailwind utility classes and CSS `@keyframes` — zero new dependencies.

**Tech Stack:** Next.js 15, React 19, Tailwind CSS 4, shadcn/ui 4, lucide-react, CSS custom properties, IntersectionObserver API

**Spec:** `openspec/changes/homepage-visual-upgrade/specs/homepage-visual-upgrade/spec.md`
**Design:** `openspec/changes/homepage-visual-upgrade/design.md`
**Visual Reference:** `docs/homepage-visual-upgrade-design.md`

## Global Constraints

- All color changes via `:root` CSS variables only — `.dark` block MUST remain untouched
- Animation uses only `opacity` + `transform` (GPU-accelerated) — no layout-triggering properties
- `prefers-reduced-motion: reduce` MUST disable all animations/transitions globally
- No new npm dependencies — all effects via Tailwind + native CSS
- No functional behavior changes — search logic, API calls, routing, data fetching stay identical
- All existing `aria-label`, semantic landmarks, skip-to-content MUST remain unchanged

## File Structure

```
NEW:
  frontend/src/lib/use-scroll-reveal.ts          — IntersectionObserver Hook for scroll animations
  frontend/src/components/ui/section-divider.tsx  — Gold diamond geometric section divider

MODIFIED:
  frontend/src/app/globals.css                    — Brand colors, gradients, keyframes, reduced-motion
  frontend/src/app/page.tsx                       — SectionDivider insertion, lg:max-w-[1280px]
  frontend/src/components/layout/header.tsx       — Glassmorphic bg, gradient edge, hover, dot
  frontend/src/components/layout/footer.tsx       — Dark bg, gradient top, gold hover, brand highlight
  frontend/src/components/hero/hero-section.tsx   — Heights, text shadow, entrance animations
  frontend/src/components/hero/hero-background.tsx — Gradient overlay layers
  frontend/src/components/hero/search-form.tsx    — Glassmorphic capsule redesign
  frontend/src/components/navigation/navigation-section.tsx — Accent bars, icon color, hover, animation
  frontend/src/components/destinations/destinations-section.tsx — Animation index, skeleton colors
  frontend/src/components/destinations/destination-card.tsx   — Overlay, city repositioned, accent bar
  frontend/src/components/community/community-section.tsx     — Animation index, skeleton, lg breakpoint
  frontend/src/components/community/post-card.tsx             — Avatar ring, heart color, accent bar
  frontend/src/components/ai-widget/ai-widget.tsx             — Gradient border, glow pulse
```

---

### Task 1: Brand Color System

**Files:**
- Modify: `frontend/src/app/globals.css:50-83` (`:root` block only)

**Interfaces:**
- Consumes: Nothing (foundation task)
- Produces: CSS variables consumed by all subsequent tasks

- [ ] **Step 1: Replace brand color variables in `:root`**

In `globals.css`, replace the `:root` block (lines 50–83). Change ONLY the `:root` block — do NOT touch the `.dark` block (lines 85–117).

```css
:root {
    --background: #FFFBF5;
    --foreground: #1A1A1A;
    --card: #FFFFFF;
    --card-foreground: #1A1A1A;
    --popover: #FFFFFF;
    --popover-foreground: #1A1A1A;
    --primary: #C41E3A;
    --primary-foreground: #FFFFFF;
    --secondary: #FFF5E6;
    --secondary-foreground: #8B1A2B;
    --muted: #F5F0EB;
    --muted-foreground: #6B6560;
    --accent: #D4A017;
    --accent-foreground: #1A1A1A;
    --destructive: oklch(0.577 0.245 27.325);
    --border: #E8DDD3;
    --input: #E8DDD3;
    --ring: #C41E3A;
    --chart-1: oklch(0.87 0 0);
    --chart-2: oklch(0.556 0 0);
    --chart-3: oklch(0.439 0 0);
    --chart-4: oklch(0.371 0 0);
    --chart-5: oklch(0.269 0 0);
    --radius: 0.625rem;
    --sidebar: oklch(0.985 0 0);
    --sidebar-foreground: oklch(0.145 0 0);
    --sidebar-primary: oklch(0.205 0 0);
    --sidebar-primary-foreground: oklch(0.985 0 0);
    --sidebar-accent: oklch(0.97 0 0);
    --sidebar-accent-foreground: oklch(0.205 0 0);
    --sidebar-border: oklch(0.922 0 0);
    --sidebar-ring: oklch(0.708 0 0);

    /* Brand gradient presets */
    --gradient-brand: linear-gradient(135deg, #C41E3A 0%, #D4A017 100%);
    --gradient-hero-overlay: linear-gradient(
        to bottom,
        rgba(196, 30, 58, 0.65) 0%,
        rgba(212, 160, 23, 0.35) 100%
    );
    --gradient-card-accent: linear-gradient(90deg, #C41E3A 0%, #D4A017 100%);
}
```

- [ ] **Step 2: Verify `.dark` block is untouched**

Confirm lines 85–117 (`.dark { ... }`) remain exactly as they were. Grep for `--primary` in `.dark` block — should still be `oklch(0.922 0 0)`.

- [ ] **Step 3: Build verification**

Run: `cd frontend; npm run build`
Expected: Build succeeds with no CSS parse errors.

- [ ] **Step 4: Visual spot check**

Run: `cd frontend; npm run dev`
Open `http://localhost:3000`. Verify: page background is warm white (not pure white), buttons (AI widget float button) are now Chinese Red, borders are warm beige.

- [ ] **Step 5: Commit**

```bash
git add frontend/src/app/globals.css
git commit -m "feat: replace gray theme with Chinese Red + Gold brand color system"
```

---

### Task 2: Animation Keyframes & Reduced Motion

**Files:**
- Modify: `frontend/src/app/globals.css` (append after `@layer base` block)

**Interfaces:**
- Consumes: Nothing
- Produces: `fade-slide-up` and `glow-pulse` keyframes used by Tasks 4–11

- [ ] **Step 1: Add keyframes and reduced-motion rule**

Append to the end of `globals.css` (after the `@layer base` block):

```css
/* Brand entrance animation */
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

/* AI Widget breathing glow */
@keyframes glow-pulse {
    0%, 100% {
        box-shadow: 0 0 8px rgba(196, 30, 58, 0.4), 0 0 16px rgba(196, 30, 58, 0.2);
    }
    50% {
        box-shadow: 0 0 16px rgba(196, 30, 58, 0.6), 0 0 32px rgba(196, 30, 58, 0.3);
    }
}

/* Respect user motion preferences */
@media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
    }
}
```

- [ ] **Step 2: Build verification**

Run: `cd frontend; npm run build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/app/globals.css
git commit -m "feat: add fade-slide-up and glow-pulse keyframes, prefers-reduced-motion rule"
```

---

### Task 3: useScrollReveal Hook

**Files:**
- Create: `frontend/src/lib/use-scroll-reveal.ts`

**Interfaces:**
- Consumes: Nothing
- Produces: Hook consumed by Tasks 8–10 for scroll-triggered animations

- [ ] **Step 1: Create the Hook**

Create `frontend/src/lib/use-scroll-reveal.ts`:

```typescript
"use client";

import { useEffect, useRef } from "react";

/**
 * Scroll-triggered entrance animation hook.
 * Uses IntersectionObserver (threshold: 0.15) to set data-visible="true"
 * when the target element enters the viewport, triggering CSS fade-slide-up.
 * Animation plays once only.
 */
export function useScrollReveal<T extends HTMLElement>() {
  const ref = useRef<T>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.setAttribute("data-visible", "true");
          observer.unobserve(el);
        }
      },
      { threshold: 0.15 }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return ref;
}
```

- [ ] **Step 2: TypeScript verification**

Run: `cd frontend; npx tsc --noEmit`
Expected: No new errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/lib/use-scroll-reveal.ts
git commit -m "feat: add useScrollReveal hook for IntersectionObserver animations"
```

---

### Task 4: Section Divider Component

**Files:**
- Create: `frontend/src/components/ui/section-divider.tsx`
- Modify: `frontend/src/app/page.tsx`

**Interfaces:**
- Consumes: Nothing (pure decorative Server Component)
- Produces: `<SectionDivider />` used in page layout

- [ ] **Step 1: Create SectionDivider component**

Create `frontend/src/components/ui/section-divider.tsx`:

```tsx
export default function SectionDivider() {
  return (
    <div className="flex items-center gap-3 max-w-xs mx-auto py-2" aria-hidden="true">
      <div className="h-px flex-1 bg-gradient-to-r from-transparent via-[#D4A017]/40 to-transparent" />
      <div className="h-2 w-2 rotate-45 bg-[#D4A017]/40" />
      <div className="h-px flex-1 bg-gradient-to-r from-transparent via-[#D4A017]/40 to-transparent" />
    </div>
  );
}
```

- [ ] **Step 2: Insert into page.tsx**

In `frontend/src/app/page.tsx`, add import and insert between sections:

```tsx
import SectionDivider from "@/components/ui/section-divider";

// Inside <main>, between existing sections:
<NavigationSection />
<SectionDivider />
<DestinationsSection />
<SectionDivider />
<CommunitySection />
```

Also add `lg:max-w-[1280px]` to the `<main>` className.

- [ ] **Step 3: Build + visual check**

Run: `cd frontend; npm run build`
Open browser: verify gold diamond divider appears between Navigation-Destinations and Destinations-Community, NOT between Hero-Navigation.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/ui/section-divider.tsx frontend/src/app/page.tsx
git commit -m "feat: add SectionDivider component and lg breakpoint to page layout"
```

---

### Task 5: Hero Background Gradient Overlay

**Files:**
- Modify: `frontend/src/components/hero/hero-background.tsx`
- Modify: `frontend/src/components/hero/hero-section.tsx`

**Interfaces:**
- Consumes: `--gradient-hero-overlay`, `--background` from Task 1
- Produces: Branded Hero background for subsequent tasks

- [ ] **Step 1: Rewrite hero-background.tsx with gradient overlay**

```tsx
"use client";

import { useState } from "react";
import Image from "next/image";

interface HeroBackgroundProps {
  src: string;
  alt: string;
}

export default function HeroBackground({ src, alt }: HeroBackgroundProps) {
  const [failed, setFailed] = useState(false);

  return (
    <>
      {/* Base background color for fallback */}
      <div className="absolute inset-0 bg-[var(--background)]" />

      {/* Background image */}
      {!failed && (
        <Image
          src={src}
          alt={alt}
          fill
          priority
          className="object-cover md:object-center object-top"
          onError={() => setFailed(true)}
        />
      )}

      {/* Brand gradient overlay */}
      <div
        className="absolute inset-0"
        style={{ background: "var(--gradient-hero-overlay)" }}
      />

      {/* Bottom fade to page background */}
      <div
        className="absolute inset-x-0 bottom-0 h-[30%]"
        style={{
          background: "linear-gradient(to bottom, transparent 0%, var(--background) 100%)",
        }}
      />
    </>
  );
}
```

- [ ] **Step 2: Update hero-section.tsx heights and remove old bg**

In `hero-section.tsx`:
- Remove `bg-[#1a1a2e]` from the `<section>` className
- Change `min-h-[300px]` → `min-h-[360px]`
- Change `md:min-h-[500px]` → `md:min-h-[540px]`
- Apply same changes to the content overlay div

- [ ] **Step 3: Build + visual check**

Run: `cd frontend; npm run build`
Verify: Hero has red-gold gradient over background image, smooth fade to page bg at bottom. No more `#1a1a2e` dark blue.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/hero/hero-background.tsx frontend/src/components/hero/hero-section.tsx
git commit -m "feat: add brand gradient overlay to Hero background"
```

---

### Task 6: Hero Text & Search Form

**Files:**
- Modify: `frontend/src/components/hero/hero-section.tsx`
- Modify: `frontend/src/components/hero/search-form.tsx`

**Interfaces:**
- Consumes: Brand colors from Task 1
- Produces: Branded Hero content with glassmorphic search

- [ ] **Step 1: Update hero-section.tsx text styles + entrance animations**

In `hero-section.tsx`, update the content overlay div:

```tsx
{/* Title with shadow and entrance animation */}
<h1
  className="text-3xl md:text-5xl lg:text-6xl font-bold text-white text-center mb-4"
  style={{
    textShadow: "0 2px 12px rgba(0,0,0,0.4)",
    animation: "fade-slide-up 500ms cubic-bezier(0.16, 1, 0.3, 1) both",
  }}
>
  {headline}
</h1>

{/* Subtitle with tracking and delayed animation */}
<p
  className="text-base md:text-lg text-white/95 text-center mb-8 max-w-2xl tracking-wide"
  style={{
    animation: "fade-slide-up 500ms cubic-bezier(0.16, 1, 0.3, 1) 150ms both",
  }}
>
  {subtitle}
</p>
```

- [ ] **Step 2: Rewrite search-form.tsx as glassmorphic capsule**

Replace the return JSX in `search-form.tsx` (keep all logic/state/hooks unchanged):

```tsx
return (
  <div
    className="w-full max-w-lg mx-auto"
    style={{ animation: "fade-slide-up 500ms cubic-bezier(0.16, 1, 0.3, 1) 300ms both" }}
  >
    <form onSubmit={handleSubmit} className="w-full" noValidate>
      <div className="flex items-center gap-2 rounded-full backdrop-blur-md bg-white/15 border border-white/25 px-3 py-2 focus-within:ring-2 focus-within:ring-[#D4A017]/50">
        <Input
          type="text"
          placeholder="Search destinations, tips, or ask AI..."
          value={query}
          onChange={(e) => handleChange(e.target.value)}
          maxLength={MAX_LENGTH}
          aria-label="Search destinations, tips, or ask AI"
          className="flex-1 bg-transparent border-none text-white placeholder:text-white/60 focus-visible:ring-0 focus-visible:border-none shadow-none"
          disabled={isNavigating}
        />
        <Button
          type="submit"
          size="icon"
          aria-label="Search"
          disabled={isNavigating}
          className="rounded-full bg-[#C41E3A] hover:bg-[#A01830] shrink-0"
        >
          <Search className="h-4 w-4 text-white" />
        </Button>
      </div>
      {error && (
        <p className="mt-2 text-sm text-destructive text-center" role="alert">
          {error}
        </p>
      )}
    </form>
  </div>
);
```

- [ ] **Step 3: Build + functional verification**

Run: `cd frontend; npm run build`
Browser: verify glassmorphic capsule search form, gold focus ring, brand red button. Test: type "Chengdu" → Enter → navigates to `/search?q=Chengdu`. Empty submit → shows "Please enter a search term". **Functionality must be unchanged.**

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/hero/hero-section.tsx frontend/src/components/hero/search-form.tsx
git commit -m "feat: glassmorphic search capsule, Hero text shadow, entrance animations"
```

---

### Task 7: Header Visual Upgrade

**Files:**
- Modify: `frontend/src/components/layout/header.tsx`

**Interfaces:**
- Consumes: Brand colors from Task 1
- Produces: Branded Header

- [ ] **Step 1: Rewrite header.tsx**

```tsx
import Link from "next/link";

export default function Header() {
  return (
    <header className="sticky top-0 z-50 w-full backdrop-blur-lg bg-background/80">
      {/* Brand gradient bottom edge */}
      <div className="h-px bg-gradient-to-r from-[#C41E3A] via-[#D4A017] to-[#C41E3A]" />

      <div className="mx-auto flex h-16 max-w-[1200px] items-center justify-between px-4 md:px-0">
        <Link
          href="/"
          className="text-xl font-bold tracking-tight text-foreground transition-colors hover:text-[#C41E3A]"
        >
          ChinaBuddy
        </Link>

        <a
          href="#ai-assistant"
          className="flex items-center gap-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
        >
          <span className="h-2 w-2 rounded-full bg-[#C41E3A]" />
          AI Assistant
        </a>
      </div>
    </header>
  );
}
```

- [ ] **Step 2: Build + visual check**

Run: `cd frontend; npm run build`
Browser: scroll page — content shows through Header (glassmorphic). Bottom edge is red-gold gradient. Hover "ChinaBuddy" → turns red. AI Assistant link has red dot.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/layout/header.tsx
git commit -m "feat: glassmorphic Header with brand gradient edge and AI dot indicator"
```

---

### Task 8: Footer Visual Upgrade

**Files:**
- Modify: `frontend/src/components/layout/footer.tsx`

**Interfaces:**
- Consumes: Brand colors from Task 1
- Produces: Branded Footer

- [ ] **Step 1: Rewrite footer.tsx**

```tsx
import Link from "next/link";

const footerLinks = [
  { label: "About", href: "/coming-soon" },
  { label: "Contact", href: "/coming-soon" },
  { label: "Privacy Policy", href: "/coming-soon" },
];

export default function Footer() {
  return (
    <footer className="bg-[#1A1A1A] py-8">
      {/* Brand gradient top line */}
      <div className="h-0.5 bg-gradient-to-r from-[#C41E3A] to-[#D4A017]" />

      <div className="mx-auto flex max-w-[1200px] flex-col items-center gap-4 px-4 pt-6 md:flex-row md:justify-between md:px-0">
        <p className="text-sm text-white/60">
          &copy; 2026 <span className="text-[#D4A017]">ChinaBuddy</span>. All rights reserved.
        </p>

        <nav className="flex flex-col gap-2 md:flex-row md:gap-6">
          {footerLinks.map((link) => (
            <Link
              key={link.label}
              href={link.href}
              className="text-sm text-white/70 transition-colors hover:text-[#D4A017]"
            >
              {link.label}
            </Link>
          ))}
        </nav>
      </div>
    </footer>
  );
}
```

- [ ] **Step 2: Build + visual check**

Run: `cd frontend; npm run build`
Browser: Footer is dark bg, gold gradient top line. "ChinaBuddy" in gold. Links hover → gold.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/layout/footer.tsx
git commit -m "feat: dark Footer with brand gradient top line and gold link hover"
```

---

### Task 9: Navigation Cards Visual Upgrade

**Files:**
- Modify: `frontend/src/components/navigation/navigation-section.tsx`

**Interfaces:**
- Consumes: `useScrollReveal` from Task 3, brand colors from Task 1
- Produces: Branded Navigation cards with entrance animation

- [ ] **Step 1: Rewrite navigation-section.tsx**

```tsx
"use client";

import Link from "next/link";
import { Users, Map, Bot, Globe, type LucideIcon } from "lucide-react";
import { useScrollReveal } from "@/lib/use-scroll-reveal";

interface NavigationCard {
  id: string;
  icon: LucideIcon;
  title: string;
  description: string;
  href: string;
}

const CARDS: NavigationCard[] = [
  {
    id: "community",
    icon: Users,
    title: "Travel Community",
    description: "Share experiences and discover hidden gems from fellow travelers",
    href: "/community",
  },
  {
    id: "attractions",
    icon: Map,
    title: "Attraction Guides",
    description: "Curated guides for China's top destinations and hidden treasures",
    href: "/attractions",
  },
  {
    id: "ai-assistant",
    icon: Bot,
    title: "AI Assistant",
    description: "Plan your trip with personalized AI-powered recommendations",
    href: "/ai-assistant",
  },
];

function CardIcon({ icon: Icon }: { icon: LucideIcon }) {
  try {
    return <Icon className="h-8 w-8 text-[#C41E3A] mb-3 transition-transform duration-300 group-hover:scale-110" />;
  } catch {
    return <Globe className="h-8 w-8 text-[#C41E3A] mb-3" />;
  }
}

function NavigationCardItem({ card, index }: { card: NavigationCard; index: number }) {
  const ref = useScrollReveal<HTMLAnchorElement>();

  return (
    <Link
      ref={ref}
      href={card.href}
      className="group relative flex-1 overflow-hidden rounded-xl border border-border bg-card p-6 text-card-foreground transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:border-[#D4A017]/30 focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 active:translate-y-0 outline-none opacity-0"
      style={{
        animationDelay: `${index * 100}ms`,
      }}
      data-visible="false"
    >
      <CardIcon icon={card.icon} />
      <h3 className="text-lg font-semibold mb-2 transition-colors duration-200 group-hover:text-[#C41E3A]">
        {card.title}
      </h3>
      <p className="text-sm text-muted-foreground">{card.description}</p>
      {/* Bottom accent bar */}
      <div className="absolute inset-x-0 bottom-0 h-[3px] bg-gradient-to-r from-[#C41E3A] to-[#D4A017]" />
    </Link>
  );
}

export default function NavigationSection() {
  return (
    <section aria-label="Platform navigation" className="py-8 md:py-12">
      <div className="flex flex-col space-y-4 md:flex md:flex-row md:gap-6">
        {CARDS.map((card, index) => (
          <NavigationCardItem key={card.id} card={card} index={index} />
        ))}
      </div>
    </section>
  );
}
```

Add to `globals.css` (inside the existing `@keyframes` area or after):

```css
/* Scroll reveal animation trigger */
[data-visible="true"] {
  animation: fade-slide-up 500ms cubic-bezier(0.16, 1, 0.3, 1) both;
}
```

- [ ] **Step 2: Build + visual check**

Run: `cd frontend; npm run build`
Browser: scroll to Navigation — 3 cards fade-in + slide-up sequentially (+100ms). Icons are red. Hover: card lifts, border glows gold, title turns red. Bottom gradient bar visible.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/navigation/navigation-section.tsx frontend/src/app/globals.css
git commit -m "feat: Navigation cards with brand colors, accent bars, entrance animation"
```

---

### Task 10: Destination Cards Visual Upgrade

**Files:**
- Modify: `frontend/src/components/destinations/destination-card.tsx`
- Modify: `frontend/src/components/destinations/destinations-section.tsx`

**Interfaces:**
- Consumes: `useScrollReveal` from Task 3, brand colors from Task 1
- Produces: Branded Destination cards

- [ ] **Step 1: Rewrite destination-card.tsx**

```tsx
"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import type { Destination } from "@/api/destinations";
import { useScrollReveal } from "@/lib/use-scroll-reveal";

interface DestinationCardProps {
  destination: Destination;
  index: number;
}

export default function DestinationCard({ destination, index }: DestinationCardProps) {
  const [imageFailed, setImageFailed] = useState(false);
  const ref = useScrollReveal<HTMLElement>();

  return (
    <Link
      href={`/destinations/${destination.slug}`}
      className="group block min-w-[80vw] snap-start md:min-w-0 opacity-0"
      aria-label={`Explore ${destination.cityName}`}
      ref={ref as React.Ref<HTMLAnchorElement>}
      style={{ animationDelay: `${index * 80}ms` }}
      data-visible="false"
    >
      <article className="relative overflow-hidden rounded-xl border border-border bg-card shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-xl">
        {/* Cover Image with overlay */}
        <div className="relative aspect-[4/3] w-full overflow-hidden bg-gradient-to-br from-blue-400 to-purple-600">
          {!imageFailed ? (
            <Image
              src={destination.coverImageUrl}
              alt={destination.cityName}
              fill
              className="object-cover transition-transform duration-300 group-hover:scale-[1.08]"
              onError={() => setImageFailed(true)}
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center bg-gradient-to-br from-blue-400 to-purple-600">
              <span className="text-lg font-bold text-white">{destination.cityName}</span>
            </div>
          )}

          {/* Bottom gradient overlay */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent pointer-events-none" />

          {/* City name on overlay */}
          <h3 className="absolute bottom-3 left-3 text-base font-semibold text-white">
            {destination.cityName}
          </h3>

          {/* Popularity tag - glassmorphic capsule */}
          <span className="absolute bottom-3 right-3 rounded-full backdrop-blur-sm bg-white/20 px-2 py-0.5 text-xs font-medium text-white border border-white/20">
            {destination.popularityTag}
          </span>
        </div>

        {/* Card Content */}
        <div className="p-4">
          <p className="text-sm text-muted-foreground line-clamp-2 border-l-2 border-[#C41E3A]/40 pl-3">
            {destination.highlight}
          </p>
        </div>

        {/* Bottom accent bar - visible on hover */}
        <div className="absolute inset-x-0 bottom-0 h-[3px] bg-gradient-to-r from-[#C41E3A] to-[#D4A017] opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
      </article>
    </Link>
  );
}
```

- [ ] **Step 2: Update destinations-section.tsx — pass index + warm skeleton**

In `destinations-section.tsx`:
1. Pass `index` prop to `DestinationCard`: `{destinations.map((dest, i) => <DestinationCard key={dest.id} destination={dest} index={i} />)}`
2. Change skeleton `bg-muted` → `bg-[#FFF5E6]` and inner pulse `bg-muted` → `bg-[#F0E0CC]`

- [ ] **Step 3: Build + visual check**

Run: `cd frontend; npm run build`
Browser: Destination cards show city name on image overlay, glassmorphic tag, red vertical line on description. Hover: image zooms 1.08, card lifts, bottom bar fades in. Skeleton cards are warm-toned.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/destinations/destination-card.tsx frontend/src/components/destinations/destinations-section.tsx
git commit -m "feat: Destination cards with image overlay, city repositioned, accent bars"
```

---

### Task 11: Community Cards Visual Upgrade

**Files:**
- Modify: `frontend/src/components/community/post-card.tsx`
- Modify: `frontend/src/components/community/community-section.tsx`

**Interfaces:**
- Consumes: `useScrollReveal` from Task 3, brand colors from Task 1
- Produces: Branded Community cards

- [ ] **Step 1: Rewrite post-card.tsx**

```tsx
"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { User, Heart } from "lucide-react";
import { truncateExcerpt, formatLikeCount } from "@/lib/format";
import { useScrollReveal } from "@/lib/use-scroll-reveal";
import type { CommunityPost } from "@/api/posts";

interface PostCardProps {
  post: CommunityPost;
  index: number;
}

export default function PostCard({ post, index }: PostCardProps) {
  const [avatarFailed, setAvatarFailed] = useState(false);
  const ref = useScrollReveal<HTMLAnchorElement>();

  return (
    <Link
      href={`/community/posts/${post.id}`}
      className="group relative block overflow-hidden rounded-xl border border-border bg-card p-4 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:border-[#D4A017]/30 focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 outline-none opacity-0"
      aria-label={`Read post: ${post.title}`}
      ref={ref}
      style={{ animationDelay: `${index * 100}ms` }}
      data-visible="false"
    >
      {/* Author Info */}
      <div className="mb-3 flex items-center gap-3">
        <div className="relative h-10 w-10 flex-shrink-0 overflow-hidden rounded-full bg-muted ring-2 ring-[#C41E3A]/30">
          {!avatarFailed ? (
            <Image
              src={post.authorAvatarUrl}
              alt={post.authorName}
              width={40}
              height={40}
              className="rounded-full object-cover"
              onError={() => setAvatarFailed(true)}
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center rounded-full bg-muted">
              <User className="h-5 w-5 text-muted-foreground" />
            </div>
          )}
        </div>
        <span className="text-sm font-medium text-card-foreground">{post.authorName}</span>
      </div>

      {/* Title */}
      <h3 className="mb-2 text-base font-semibold text-card-foreground line-clamp-2">{post.title}</h3>

      {/* Excerpt */}
      <p className="mb-3 text-sm text-muted-foreground">{truncateExcerpt(post.excerpt, 120)}</p>

      {/* Like Count */}
      <div className="flex items-center gap-1.5 text-sm text-[#C41E3A]/60 transition-all duration-200 group-hover:text-[#C41E3A]">
        <Heart className="h-4 w-4 transition-transform duration-200 group-hover:scale-110" />
        <span>{formatLikeCount(post.likeCount)}</span>
      </div>

      {/* Bottom accent bar */}
      <div className="absolute inset-x-0 bottom-0 h-[2px] bg-gradient-to-r from-[#C41E3A] to-[#D4A017] opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
    </Link>
  );
}
```

- [ ] **Step 2: Update community-section.tsx — pass index + warm skeleton + lg breakpoint**

In `community-section.tsx`:
1. Pass `index` to `PostCard`: `{posts.map((post, i) => <PostCard key={post.id} post={post} index={i} />)}`
2. Change skeleton colors: `bg-muted` → `bg-[#FFF5E6]`, inner `bg-muted` → `bg-[#F0E0CC]`
3. Add `lg:grid-cols-4` to grid container className (both loading and content grids)

- [ ] **Step 3: Build + visual check**

Run: `cd frontend; npm run build`
Browser: Community cards have red avatar ring, red-tinted heart. Hover: card lifts, heart scales up, bottom bar appears. At ≥1024px: 4 columns.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/community/post-card.tsx frontend/src/components/community/community-section.tsx
git commit -m "feat: Community cards with avatar ring, brand heart, accent bars, lg breakpoint"
```

---

### Task 12: AI Widget Visual Upgrade

**Files:**
- Modify: `frontend/src/components/ai-widget/ai-widget.tsx`

**Interfaces:**
- Consumes: `glow-pulse` keyframe from Task 2, brand colors from Task 1
- Produces: Branded AI Widget float button

- [ ] **Step 1: Update the floating button in ai-widget.tsx**

Find the floating button (around line 269–276) and replace:

```tsx
{/* Floating Button */}
<button
  ref={buttonRef}
  onClick={toggleOpen}
  className="relative flex h-14 w-14 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-lg transition-transform hover:scale-105 focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
  aria-label="Open AI assistant"
  style={{
    border: "2px solid transparent",
    backgroundImage: "linear-gradient(var(--primary), var(--primary)), var(--gradient-brand)",
    backgroundOrigin: "border-box",
    backgroundClip: "padding-box, border-box",
    animation: "glow-pulse 2s ease-in-out infinite",
  }}
>
  <Bot className="h-6 w-6" />
</button>
```

- [ ] **Step 2: Build + visual check**

Run: `cd frontend; npm run build`
Browser: AI Widget float button has gradient border (red→gold), breathing red glow pulsing. Enable `prefers-reduced-motion` in DevTools → glow stops.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/ai-widget/ai-widget.tsx
git commit -m "feat: AI Widget float button with gradient border and breathing glow"
```

---

### Task 13: Final Integration Verification

**Files:**
- No new changes — verification only

**Interfaces:**
- Consumes: All previous tasks
- Produces: Verified homepage

- [ ] **Step 1: Full build verification**

```bash
cd frontend
npm run build
npm run lint
npx tsc --noEmit
```

Expected: All pass with no new errors.

- [ ] **Step 2: Visual walkthrough — all sections**

Start dev server: `npm run dev`

Checklist for browser verification:
- [ ] Hero: brand gradient overlay, text shadow, glassmorphic capsule search, entrance animations (0/150/300ms)
- [ ] Header: glassmorphic bg, gradient bottom edge, brand name hover red, AI dot indicator
- [ ] Navigation: 3 cards sequential entrance (+100ms), red icons, bottom gradient bar, hover lift
- [ ] SectionDivider: gold diamond + fading lines between Nav-Dest and Dest-Comm
- [ ] Destinations: image overlay, city name on image, glassmorphic tag, red vertical line, hover 1.08 zoom, entrance (+80ms)
- [ ] Community: avatar red ring, red heart, bottom bar on hover, entrance (+100ms), 4 cols at lg
- [ ] Footer: dark bg, gradient top line, gold "ChinaBuddy", gold link hover
- [ ] AI Widget: gradient border, breathing glow

- [ ] **Step 3: Responsive verification**

Resize browser to verify:
- [ ] Mobile (< 768px): search capsule full-width, cards stacked, accent bars at top
- [ ] `md` (768px–1024px): Nav 3-across, Destinations 4-col, Community 3-col
- [ ] `lg` (≥ 1024px): container 1280px, Community 4-col

- [ ] **Step 4: Reduced motion verification**

In Chrome DevTools → Rendering → Emulate `prefers-reduced-motion: reduce`. Verify:
- [ ] All entrance animations skipped (elements visible immediately)
- [ ] AI Widget glow stopped
- [ ] Hover transitions instant

- [ ] **Step 5: Functional regression check**

- [ ] Search: type "Beijing" → Enter → navigates to `/search?q=Beijing`
- [ ] Search: empty submit → "Please enter a search term" shown
- [ ] Navigation cards: click each → correct route (`/community`, `/attractions`, `/ai-assistant`)
- [ ] Footer links: click → `/coming-soon`
- [ ] AI Widget: open → type → send → reply received → close

- [ ] **Step 6: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix: resolve integration issues from visual upgrade"
```

(If no fixes needed, skip this step.)
