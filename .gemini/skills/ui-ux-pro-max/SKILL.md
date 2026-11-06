---
name: ui-ux-pro-max
description: Premium iOS/Apple-style mobile UI/UX design system for the Presensi SMKN 1 Beringin Flutter app. Enforces Apple HIG principles, animation standards, and premium design patterns.
---

# UI/UX Pro Max — Apple Design Language for Presensi Mobile

## Design Philosophy

This skill enforces a **premium iOS/Apple Human Interface Guidelines (HIG)** design language across the entire Presensi mobile app. Every component should feel like it belongs on an iPhone — smooth, refined, and intentional.

## Core Design Tokens

### Colors (Apple System Colors)
| Token | Hex | Usage |
|-------|-----|-------|
| Primary Blue | `#007AFF` | CTAs, links, active states |
| System Indigo | `#5856D6` | Gradient accents |
| System Green | `#34C759` | Success, hadir, active |
| System Orange | `#FF9500` | Warnings, izin |
| System Red | `#FF3B30` | Errors, alpa, danger |
| System Teal | `#5AC8FA` | Info, secondary actions |
| Label Primary | `#000000` | Main text |
| Label Secondary | `#3C3C43` (60% opacity feel) | Body text |
| Label Tertiary | `#8E8E93` | Muted, placeholder |
| Separator | `#D1D1D6` | Borders, dividers |
| System BG | `#F2F2F7` | Page background |
| Elevated Surface | `#FFFFFF` | Cards, modals |

### Typography
- **Headlines**: Plus Jakarta Sans, weight 700-800, negative letter-spacing (-0.3 to -0.8)
- **Body/Labels**: Inter, weight 400-600, normal spacing
- **Mono/Data**: JetBrains Mono or Inter Tight for numbers/codes

### Spacing Scale
- `4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 40, 48`
- Prefer **8-point grid** alignment

### Border Radius Scale
- Small elements (badges, pills): R20-R24
- Cards: R16-R22
- Modals/Sheets: R24-R28
- Buttons: R12-R14
- Inputs: R12-R14
- Full circle: R999 (avatar)

### Shadows (Apple-style)
```dart
// Subtle card shadow
BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: Offset(0, 4))

// Elevated shadow (modals, floating nav)
BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: Offset(0, 8))

// Glow shadow (colored elements like session card)
BoxShadow(color: primaryBlue.withOpacity(0.25), blurRadius: 20, offset: Offset(0, 8))
```

## Animation Standards

### Timing Curves
| Type | Curve | Duration |
|------|-------|----------|
| Enter/Appear | `Curves.easeOutCubic` | 300-500ms |
| Exit/Disappear | `Curves.easeInCubic` | 200-300ms |
| Spring/Bounce | `Curves.easeOutBack` | 400-600ms |
| Tab switch | `Curves.easeInOut` | 250ms |
| Press feedback | `Curves.easeOut` | 100ms down, 200ms up |

### Animation Patterns
1. **Page Enter**: Staggered fadeIn + slideY (begin: 0.03-0.05, end: 0), 50-100ms stagger between elements
2. **Press Effect**: Scale to 0.96 on press, spring back to 1.0 on release
3. **Tab Switch**: CrossFade with 250ms duration
4. **List Items**: Staggered fadeIn + slideX (begin: 0.02), 40-60ms stagger
5. **Modals**: SlideUp from bottom with spring physics
6. **Shimmer Loading**: Use flutter_animate's shimmer for skeleton placeholders
7. **Pulse**: Green status dots should pulse subtly (opacity 0.6-1.0, 2s cycle)

### Required Packages
```yaml
flutter_animate: ^4.5.0  # Primary animation toolkit
```

## Component Patterns

### Cards
- White background, R16-R22 corners
- 0.5px border in `#E5E5EA` OR no border with subtle shadow
- Never both heavy border AND heavy shadow
- Content padding: 16-20px

### Buttons
- Primary: Filled `#007AFF`, white text, R14, height 48-52
- Secondary: Outlined with `#D1D1D6` border, dark text
- Destructive: Filled `#FF3B30` or outlined with red text
- Press: Scale 0.96 + opacity 0.8

### Input Fields
- Filled background `#F2F2F7`
- No visible border in resting state
- Blue border (`#007AFF`, 1.5px) on focus
- R12-R14 corners
- Prefix icons in `#8E8E93`
- Placeholder in `#C7C7CC`

### Pills/Badges
- Active: Filled primary color, white text
- Inactive: `#F2F2F7` bg, `#8E8E93` text
- R20-R24 corners
- Padding: horizontal 12-16, vertical 6-8

### Bottom Navigation
- Floating pill design, R28
- White bg with subtle shadow
- Active tab: blue pill bg with white icon + label
- Inactive: gray icon only
- Spring animation on tab change

## References & Inspiration
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [21st.dev](https://21st.dev) — Premium UI component blocks
- [Magic UI](https://magicui.design) — Animated components (shimmer, spotlight, aurora)
- [Aceternity UI](https://ui.aceternity.com) — Parallax, 3D effects, spotlight
- Flutter Cupertino widgets for authentic iOS feel

## Anti-Patterns (DO NOT)
- ❌ Heavy drop shadows (elevation > 4)
- ❌ Hard borders > 1px
- ❌ Abrupt state changes without animation
- ❌ Dense padding (< 8px)
- ❌ Flat/generic Material Design defaults
- ❌ Spinner-only loading (use skeleton shimmer)
- ❌ Non-rounded corners on cards
- ❌ Inconsistent color usage

