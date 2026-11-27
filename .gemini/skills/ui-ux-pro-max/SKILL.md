---
name: ui-ux-pro-max
description: Use when designing, styling, building, or reviewing user interfaces across Web (Tailwind, Livewire, Blade, Alpine.js) and Mobile (Flutter, iOS Cupertino, Android Material You). Enforces premium Apple HIG design language, modern micro-interactions, responsive typography, 8-pt spatial rhythm, frosted glass/elevated surfaces, and strict anti-AI-slop quality polish.
---

# UI/UX Pro Max — Design System & Interaction Standards

## Design Philosophy

This skill enforces a **luxury, Apple Human Interface Guidelines (HIG)-inspired** aesthetic coupled with modern SaaS visual craft. Every screen, card, modal, and button must feel deliberate, responsive, tactile, and crafted by a senior product designer — never auto-generated, generic, or unfinished.

---

## 1. Core Visual Tokens

### Colors (Apple Semantic Palette)
| Token | Hex | Role & Usage |
|---|---|---|
| **Primary Accent** | `#007AFF` | Primary CTAs, active tab, key highlights |
| **System Indigo** | `#5856D6` | Gradients, secondary badges, premium accents |
| **Success / Hadir** | `#34C759` | Confirmed attendance, success toasts, verified states |
| **Warning / Izin** | `#FF9500` | Excused absence, late alerts, pending sync |
| **Danger / Alpa** | `#FF3B30` | Unexcused absence, errors, destructive actions |
| **Teal / Info** | `#5AC8FA` | Explanatory badges, secondary hints, neutral highlights |
| **Surface Dark (Text)** | `#1C1C1E` | Primary headings, readable high-contrast body text |
| **Surface Muted (Text)**| `#3C3C43` (60%) | Supporting text, descriptions, timestamps |
| **Surface Tertiary** | `#8E8E93` | Placeholders, inactive icons, subtle hints |
| **Canvas Background** | `#F2F2F7` | iOS grouped background, modern page background |
| **Elevated Card BG** | `#FFFFFF` | Primary card surfaces, bottom sheets, modals |
| **Border / Divider** | `#E5E5EA` / `#D1D1D6` | Hairline dividers (0.5px to 1px) |

### Typography Scale
- **Headlines / Display**: *Plus Jakarta Sans* or *SF Pro Display*, weights 700-800, tight negative tracking (`letter-spacing: -0.02em` to `-0.04em`).
- **Body / Interface**: *Inter* or *SF Pro Text*, weights 400-600, balanced line height (`1.4` to `1.6`).
- **Data / Numbers / Timestamps**: *JetBrains Mono* or *Inter Tight*, tabular numerals (`font-variant-numeric: tabular-nums`).

### 8-Point Spatial Grid
- Strict spacing scale: `4, 8, 12, 16, 20, 24, 32, 40, 48, 64px`.
- Card padding: `16px` (compact) or `20-24px` (spacious).
- Touch target minimum: `44x44px` (iOS standard) or `48x48px` (Android standard).

### Border Radius Hierarchy
- **Pills / Badges**: `rounded-full` / `BorderRadius.circular(999)`
- **Modals / Sheets**: `24px - 28px` (prominent top radii for bottom sheets)
- **Cards / Containers**: `16px - 22px`
- **Buttons / Form Inputs**: `12px - 14px`
- **Avatars**: `rounded-full` with subtle 1px border or ring

### Shadows & Elevated Surfaces (Apple-Style)
Never use harsh, pitch-black drop shadows. Always use multi-layered, low-opacity shadows:
```css
/* CSS / Tailwind */
.shadow-apple-subtle {
  box-shadow: 0 2px 8px -2px rgba(0, 0, 0, 0.04), 0 8px 16px -4px rgba(0, 0, 0, 0.02);
}
.shadow-apple-elevated {
  box-shadow: 0 4px 12px -2px rgba(0, 0, 0, 0.06), 0 16px 32px -6px rgba(0, 0, 0, 0.05);
}
.shadow-apple-glow {
  box-shadow: 0 8px 24px -4px rgba(0, 122, 255, 0.25);
}
```

```dart
// Flutter
final kSubtleCardShadow = [
  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
];
final kElevatedModalShadow = [
  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
];
final kGlowAccentShadow = [
  BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
];
```

---

## 2. Motion, Physics & Micro-Interactions

### Timing Curves & Durations
- **Enter / Pop In**: `easeOutCubic` (300ms - 400ms)
- **Exit / Dismiss**: `easeInCubic` (200ms - 250ms)
- **Interactive Press Feedback**: `easeOut` (100ms down, 200ms spring return)
- **Tab / View Transitions**: `easeInOutCubic` (250ms - 300ms)

### Interaction Standards
1. **Active Tap/Click Feedback**:
   - Web: `active:scale-[0.97] transition-transform duration-100`
   - Mobile: Scale animation `0.96` + `HapticFeedback.lightImpact()` on tap.
2. **Skeleton Shimmer Over Spinners**:
   - Never show a blank screen with a solitary circular spinner.
   - Use animated skeleton shimmer replicating the exact card/content silhouette.
3. **Staggered Entrance**:
   - When loading lists or dashboards, stagger item entrance by `40ms - 60ms` with a subtle fade-in + 4px upward translation.
4. **Subtle Status Pulse**:
   - Active status indicators (e.g. "Kamera Aktif", "GPS Terkunci", "MikroTik Terhubung") should pulse gently (opacity oscillating between 0.6 and 1.0 on a 2-second loop).

---

## 3. Web UI Implementation (Tailwind, Livewire, Alpine.js)

### Frosted Glassmorphism (iOS Vibrancy)
```html
<div class="bg-white/80 dark:bg-zinc-900/80 backdrop-blur-md border border-white/20 dark:border-white/10 rounded-2xl shadow-apple-subtle p-5">
  <!-- Content -->
</div>
```

### Action Buttons
```html
<!-- Primary Button -->
<button class="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-blue-600 hover:bg-blue-700 active:scale-[0.97] text-white font-semibold shadow-sm transition-all duration-150">
  <span>Presensi Sekarang</span>
</button>

<!-- Secondary Ghost Button -->
<button class="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-zinc-100 hover:bg-zinc-200 active:scale-[0.97] text-zinc-800 font-medium transition-all duration-150">
  <span>Riwayat</span>
</button>
```

### Livewire & Alpine Micro-Interactions
- Use `wire:loading.class="opacity-50 pointer-events-none"` for clean disabled states during network round-trips.
- Use `x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-y-2" x-transition:enter-end="opacity-100 translate-y-0"` on dropdowns and modals.

---

## 4. Mobile UI Implementation (Flutter)

### Key Packages
- `flutter_animate: ^4.5.0` (smooth declarative staggered animations)
- `google_fonts: ^6.2.1` (typography loading)
- `cached_network_image: ^3.3.1` (image caching with error placeholders)

### Layout & Responsive Constraints
- Always wrap mobile content in a maximum width constraint (e.g., `ConstrainedBox(constraints: BoxConstraints(maxWidth: 520))`) so tablet / iPad screens don't stretch into awkward full-width layouts.
- Always respect `SafeArea` insets for iOS Dynamic Island and bottom home indicator bar (`MediaQuery.of(context).padding.bottom + 16`).

---

## 5. Anti-AI-Slop Directives

Every design output generated must adhere strictly to these quality barriers:
1. **Zero Generic Placeholder Text**: Never use "Lorem ipsum", "Title here", "Description goes here", or "John Doe". Always use realistic Indonesian school context (e.g., "SMK Negeri 1 Beringin", "XII RPL 1", "07:15 WIB - Tepat Waktu", "M. Fajar Sidik").
2. **No Cookie-Cutter Identical Grids**: Vary information hierarchy using typography weight, accent pill badges, and distinct container elevations.
3. **Defensive UX States**: Every view must gracefully account for:
   - **Empty State**: Friendly illustration/icon + clear call to action (never an empty white box).
   - **Loading State**: Content-matched shimmer skeleton.
   - **Error / Offline State**: Human-readable error message with immediate "Coba Lagi" (Retry) action.
4. **No Raw Unformatted Data**: Format dates into Indonesian locale (`d MMMM yyyy, HH:mm 'WIB'`), status into badge components, and distance into meters (`12 m dari batas sekolah`).
5. **Zero Broken Layout Overflows**: Always configure `overflow: TextOverflow.ellipsis` with explicit `maxLines`, and wrap row elements in `Flexible` or `Expanded` where text can vary in length.

---

## 6. Pre-Shipment Quality Checklist

Before completing any UI/UX work:
- [ ] Visual hierarchy: Is the primary action obvious at first glance?
- [ ] Contrast & Readability: Does text pass WCAG AA contrast against its background?
- [ ] Touch targets: Are all clickable/tappable elements at least 44x44pt?
- [ ] Responsive layout: Does the design adapt cleanly between small mobile screens, large smartphones, and tablet/desktop views?
- [ ] Micro-animations: Do interactive elements respond with subtle spring or scale feedback?
- [ ] Loading & Error handling: Are skeleton loaders and error states in place?
- [ ] Localization: Are all labels, dates, and numbers properly formatted in Indonesian?
