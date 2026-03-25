# Design System: The Atelier
**Project ID:** 6355380338520694291

## 1. Visual Theme & Atmosphere
The Atelier embraces an **editorial luxury fashion editorial** aesthetic — minimalist but warm, sophisticated yet approachable. The mood is **Airy, Quiet Luxury, Brutalist-editorial**. Large amounts of breathing room, generous whitespace, and muted, organic tones create a premium environment that feels both modern and timeless.

## 2. Color Palette & Roles

| Descriptive Name | Hex | Role |
|---|---|---|
| Warm Off-White | `#fafaf5` | Primary Background & App Surface |
| Editorial Ink | `#1a1c19` | Primary text, headers |
| Sage Olive | `#5a614f` | Primary action color (buttons, active state, borders) |
| Muted Sage Container | `#dee5cf` | Primary container, chip backgrounds |
| Pale Stone | `#eeeee9` | Surface container (cards, slightly elevated) |
| Paper White | `#f4f4ef` | Surface container low (image backgrounds) |
| Dust Gray Border | `#c6c8b8` | Outline variant, dividers, ghost borders |
| Warm Parchment | `#ece0dc` | Secondary container, wishlists tags |
| Clay Gray | `#46483c` | On-surface variant, secondary text |

## 3. Typography Rules

- **Headlines / Display**: `Manrope` — weights: 800 (Extrabold), 700 (Bold). Used for page titles, section headers.
- **Body / Labels / Input**: `Work Sans` — weights: 400 (Regular), 500 (Medium), 600 (SemiBold). Used for body text, labels, meta info.
- **Tracking**: Headlines use tight tracking (`tracking-tighter`, ~-0.02em). Labels often use wide tracking (`tracking-widest`, uppercase, ~0.15–0.2em).
- **Label Style**: Uppercase, small size (10–12px), extra-wide letter-spacing. Used as eyebrow labels above headers.

## 4. Component Styling

- **Buttons:**
  - **Primary CTA**: Sage Olive (`#5a614f`) background, white text, `rounded-xl` (12px), no border. Padding: `px-8 py-2.5`.
  - **Ghost / Secondary**: Surface container high background, on-surface text, same radius. No border.
  - **FAB / Add**: Same olive primary color, `rounded-[16px]`, icon only.
- **Cards / Item Tiles**: Rounded corners `(12px)`, elevation 0. Image area is white / paper-white background with `contain` fit. Text below with brand in uppercase, small tracking. Category in a `secondaryContainer`-colored pill tag.
- **Chips / Filter Tabs**: Pill shape (`rounded-full`), `surfaceContainerHigh` when unselected, `primaryContainer` / primary when selected. Small font, uppercase.
- **Input Fields**: Ghost underline style — `UnderlineInputBorder`, no fill. Focus changes border to Sage Olive. Hint text in muted clay gray.
- **Navigation Bar**: Frosted glass pill, centered, fixed to bottom. `backdrop-blur`, warm off-white with opacity. Icon + label in `Manrope`, 10px uppercase wide tracking.

## 5. Layout Principles

- **Padding**: Generous horizontal padding — `24px` on sides. Avoid cramped layouts.
- **Section Gaps**: Large gaps between sections (`48–64px`). Let content breathe.
- **Headers**: Always an eyebrow label (uppercase, wide tracking, muted) above main headline.
- **Asymmetry**: Slight visual asymmetry gives an editorial feel (e.g., text aligned left, CTA floated right).
- **Grid**: 2-column wardrobe grid with `aspect-[3/4]` or `0.65` ratio for card height.
- **Lists**: For wishlist items, prefer large-card lists over tight grids. Each card has a prominent image, brand, item name, material, and price pill.
