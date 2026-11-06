---
name: Clinical Clarity
colors:
  surface: '#f8f9fb'
  surface-dim: '#d9dadc'
  surface-bright: '#f8f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#edeef0'
  surface-container-high: '#e7e8ea'
  surface-container-highest: '#e1e2e4'
  on-surface: '#191c1e'
  on-surface-variant: '#3e4947'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f3'
  outline: '#6e7977'
  outline-variant: '#bdc9c6'
  surface-tint: '#006a61'
  primary: '#005b52'
  on-primary: '#ffffff'
  primary-container: '#0f756b'
  on-primary-container: '#a2f8eb'
  inverse-primary: '#80d6c9'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#684b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#876200'
  on-tertiary-container: '#ffe5b9'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9cf2e5'
  primary-fixed-dim: '#80d6c9'
  on-primary-fixed: '#00201d'
  on-primary-fixed-variant: '#005049'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdea3'
  tertiary-fixed-dim: '#fabc2a'
  on-tertiary-fixed: '#261900'
  on-tertiary-fixed-variant: '#5d4200'
  background: '#f8f9fb'
  on-background: '#191c1e'
  surface-variant: '#e1e2e4'
  primary-dark: '#0A5A52'
  teal-light: '#14B8A6'
  scaffold-base: '#F7FBF9'
  surface-white: '#FFFFFF'
  line-border: '#E5E7EB'
  status-open: '#1B8A5A'
  status-closed: '#C0392B'
  destructive-red: '#DC2626'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 21px
    fontWeight: '700'
    lineHeight: 28px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.03em
  caption:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 12px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-desktop: 1.5rem
  margin: 1.25rem
  margin-mobile: 1.25rem
  margin-tablet: 1.5rem
  margin-desktop: 2rem
  space-xs: 0.375rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.375rem
  space-xl: 1.75rem
---

## Brand & Style

The brand personality centers on calm reassurance, medical precision, and effortless accessibility. The target audience encompasses patients, caregivers, and everyday individuals seeking immediate pharmacy access, medicine availability, and preliminary AI healthcare guidance under stressful or time-sensitive conditions. The emotional response must evoke safety, instant clarity, and clinical trust—eradicating confusion through immaculate visual structure.

The design system adopts a **Minimalist Healthcare** aesthetic with subtle tactile warmth. It rejects cold, clinical sterility through deep botanical teal tones while avoiding frivolous visual noise. Layered white and muted off-white surfaces float over deep oceanic teal canvases, pairing structural cleanliness with high-legibility typographic scale. The interaction language is direct and ergonomic, optimized for single-handed mobile navigation with thumb-accessible controls and prominent visual markers.

## Colors

The color architecture creates a dual-layer hierarchy: deep botanical anchor tones for structural frames and navigation chrome, contrasted against pristine high-readability surfaces for core clinical data.

- **Primary (`#0F756B`) & Primary Dark (`#0A5A52`)**: Form the structural spine of the application. Used across page backdrops, primary CTAs, active navigation items, and brand headers. The gradient from Primary to Primary Dark creates anchored visual weight without overwhelming screen real estate.
- **Secondary (`#10B981`) & Light Teal (`#14B8A6`)**: Represent vitality, operational health, and intelligent actions (such as the conversational AI node). They provide energetic feedback for positive states and bot interactions.
- **Tertiary (`#FDBF2D`)**: A warm, high-contrast amber accent dedicated specifically to high-value actions such as visiting the physical pharmacy, navigation routing, and high-priority alerts.
- **Neutral (`#F6F7F9`) & Line (`#E5E7EB`)**: Structural neutral tones that isolate content blocks, define subtle container boundaries, and prevent card clutter on nested lists.

Status signifiers (`status-open: #1B8A5A`, `status-closed: #C0392B`, `destructive-red: #DC2626`) are strictly functional, never decorative, and must always pair with clear textual descriptors for universal accessibility.

## Typography

The typographic hierarchy is driven by **Plus Jakarta Sans**, providing balanced geometric curves and open counterforms that remain legible across compact mobile displays and high-stress informational contexts.

- **Headline XL & XL-Mobile**: Used exclusively on splash entry, major onboarding milestones, and top-tier modal authentication headings.
- **Headline LG & LG-Mobile**: Serves as the primary section header across tabs (`Beranda`, `Cari Apotek`, `Profil`), providing a clear starting point for eye tracking.
- **Headline MD & Title MD**: Tuned for card titles, pharmacy titles (`ApotekCard`), and dialog titles. Maximum display limit is enforced at 2 lines before truncation.
- **Body Tokens (LG, MD, SM)**: Structured for high readability. Body MD (`14px` / `22px`) handles addresses, operating hours, and standard descriptions, while Body LG (`16px`) handles primary CTA labels.
- **Label & Caption (MD, SM, Caption)**: Tailored for metadata pills, operational badges, distance tags, and the fixed 5-tab bottom navigation labels.

## Layout & Spacing

The layout operates on a flexible 4-column system on mobile devices (up to 599px), reflowing to 8 columns on tablet viewports (600px to 1023px) and 12 columns on desktop viewports (1024px+). The system enforces explicit safe areas for hardware notches and gesture bars.

- **Canvas Insets & Margins**: Default horizontal margin for mobile views is `1.25rem` (20px), extending to `1.5rem` (24px) for tablet and centered layouts.
- **Internal Spacing**: Component stack flow utilizes `space-sm` (8px) for tightly coupled metadata, `space-md` (16px) for intra-card content grouping, and `space-lg` (22px) for hero and intro card insets.
- **Form Constraints**: Authentication stacks and interactive input flows are strictly capped at a max-width of `420px` to maintain thumb comfort. Detailed pharmacy views restrict main content wrappers to `800px` centered on larger devices.
- **Product Grids**: Medicine grids conform to a 2-column model by default with a `12px` gutter, automatically reflowing into 3 columns once the grid canvas surpasses `500px`.

## Elevation & Depth

Visual hierarchy is constructed via a clean combination of **tonal layering** and **diffused ambient shadows**, creating floating tactile cards over teal base scaffolds without distracting heavy borders.

- **Surface Layer 0 (Foundation)**: Linear background gradient running `primary` (`#0F756B`) to `primaryDark` (`#0A5A52`) for the shell base, or flat `#F7FBF9` for conversational surfaces.
- **Surface Layer 1 (Floating Translucency - Intro Cards)**: White tinted overlay using `rgba(255, 255, 255, 0.18)` running to `rgba(255, 255, 255, 0.10)` bounded by a microscopic outline of `rgba(255, 255, 255, 0.12)`.
- **Surface Layer 2 (Standard Content Cards & Panels)**: Solid white `#FFFFFF` resting at elevation level 1. Uses an extra-diffused ambient shadow: `0 6px 16px -2px rgba(10, 90, 82, 0.06)`, producing an organic teal-tinted lift.
- **Surface Layer 3 (Floating Bars & Modals)**: App navigation bars, floating action buttons, and modal sheets sit at elevation level 2, utilizing `0 12px 28px -4px rgba(15, 117, 107, 0.12)`.
- **Surface Layer 4 (AI Floating Trigger)**: MediBot floating central navigation node sits above the standard bar with an ambient elevation shadow of `0 8px 20px 0 rgba(20, 184, 166, 0.35)`.

## Shapes

The design system employs a soft, human-centered geometric curvature (Level 2 Roundedness) that visually softens dense medical records and pharmacy catalogs.

- **Micro Elements (Chips, Operational Badges, Floating Pills)**: Fully pill-shaped with `999px` corner radius (`rounded-full`) to immediately distinguish them from interactive card surfaces.
- **Form Inputs & Action Buttons**: Standardized at `0.75rem` to `1rem` (12px–16px) corner radius, matching finger-pad contours during tactile engagement.
- **Standard Content & Product Cards**: Utilize `1.5rem` (24px) corner radius, ensuring distinct separation against darker background canvases.
- **Intro Modules & Hero Banners**: Utilize `1.625rem` (26px) radius to establish large visual focus anchors.

## Components

### Buttons
- **Primary Action**: 56px height, background `#0F756B`, text `#FFFFFF`, font-weight 600, border-radius 16px. Pressed state dims to `#0A5A52`.
- **Visit Pharmacy CTA (Special)**: Height 48px, background `#FDBF2D`, text `#0A5A52`, font-weight 700, border-radius 14px. Used exclusively to prompt physical pharmacy actions or map triggers.
- **Secondary / Outlined**: Height 48px, background transparent, border 1.5px solid `#E5E7EB`, text `#0F756B`, hover background `#F6F7F9`.

### Chips & Quick Filters
- Filter chips have a height of 36px, horizontal padding of 14px, and a pill radius of 999px.
- Unselected state: surface `#FFFFFF` with `#E5E7EB` outline, text color `#0A5A52`.
- Selected state: background `#0F756B`, border color transparent, text `#FFFFFF`, font-weight 600.

### Input Fields
- Minimum target height of 52px, background `#FFFFFF`, rounded 14px, bordered with 1px `#E5E7EB`.
- Active focus state switches border to 2px `#0F756B` with a subtle 3px outer ring of `rgba(15, 117, 107, 0.15)`.
- Error state switches border to 1.5px `#DC2626` and pairs with an immediate helper label.

### Cards (`ApotekCard` & Catalog)
- Background `#FFFFFF`, radius 24px, padding 16px, ambient shadow applied.
- Hero media container within card features a fixed height of 185px with a top inner radius of 18px and `object-fit: cover`.
- Content stack contains pharmacy status pill (`Buka` in `#1B8A5A`, `Tutup` in `#C0392B`), followed by the pharmacy name (Title MD, 2-line clamp), distance metric, and primary tertiary CTA button.

### Bottom Navigation Bar & AI Node
- Nav bar height is 64px plus device safe area insets, colored `#FFFFFF` with an upper border of 1px `#E5E7EB`.
- Active tabs display a primary teal icon, 10px label in weight 700, and an active dot marker.
- Center AI Node: 52px circular element suspended inside a 68px white circular cradle, featuring a teal gradient (`#14B8A6` to `#0F756B`) and a persistent elevation glow.

### Status Indicators & Badges
- Pill shape (height 24px, padding 4px 10px).
- Open status uses a background of `rgba(27, 138, 90, 0.12)` with `#1B8A5A` text.
- Closed status uses a background of `rgba(192, 57, 43, 0.12)` with `#C0392B` text.
- Never rely solely on color: always display clear text alongside status dots.