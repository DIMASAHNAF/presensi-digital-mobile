---
name: anti-ai-slop
description: Quality enforcement skill that prevents generic, templated, or low-effort AI output. Ensures every component has intentional design decisions, unique character, and production polish.
---

# Anti AI Slop — Quality Enforcement for Presensi Mobile

## What is "AI Slop"?

AI slop refers to generic, templated, cookie-cutter output that looks like it was churned out by a language model without thought. It's the equivalent of stock photography in code — technically correct but soulless.

## Rules

### 1. No Generic Placeholder Content
- ❌ "Lorem ipsum dolor sit amet"
- ❌ "Your content here"
- ❌ "Example text"
- ✅ Use real Indonesian text from the actual Presensi system
- ✅ Reference actual school data (SMKN 1 Beringin, Kab. Deli Serdang)
- ✅ Use realistic student names, NISN numbers, class names

### 2. No Cookie-Cutter Layouts
- ❌ Generic card grids with identical styling
- ❌ Default Material Design with no customization
- ❌ "I'll add a simple list view here"
- ✅ Every section should have a unique visual identity
- ✅ Mix card sizes, layouts, and visual weights
- ✅ Create visual hierarchy through intentional variation

### 3. No Lazy Color Choices
- ❌ Using `Colors.blue`, `Colors.red`, `Colors.green` directly
- ❌ Random hex colors not from the design system
- ✅ Always use AppColors or explicitly defined Apple system colors
- ✅ Every color choice should be intentional and documented

### 4. No Boring Transitions
- ❌ Instant state changes with no animation
- ❌ Default MaterialPageRoute transitions
- ❌ Static loading spinners as the only loading state
- ✅ Every state change should have a micro-animation
- ✅ Staggered reveals for list items
- ✅ Spring physics for interactive elements
- ✅ Skeleton shimmer for loading states

### 5. No Redundant Comments
- ❌ `// This is a button` above a button widget
- ❌ `// TODO: implement later` with no plan
- ✅ Comments only for non-obvious logic
- ✅ Section headers that describe the UX purpose, not the widget type

### 6. No Half-Baked Features
- ❌ Placeholder screens with "Coming Soon"
- ❌ Non-functional buttons
- ❌ Hardcoded data that should be dynamic
- ✅ Every visible element must be functional
- ✅ Error states must be handled gracefully
- ✅ Edge cases (empty lists, long text, no avatar) must be designed for

### 7. Attention to Detail
- ✅ Proper text overflow handling (maxLines + ellipsis)
- ✅ Safe area insets respected
- ✅ Keyboard-aware layouts
- ✅ Pull-to-refresh on all scrollable views
- ✅ Network image error builders with fallback UI
- ✅ Responsive max-width constraints (520px for tablet)
- ✅ Loading states for async operations
- ✅ Haptic-feel press effects on all interactive elements

### 8. Code Quality Standards
- ✅ No unused imports
- ✅ No unused variables
- ✅ `flutter analyze` must pass with 0 issues
- ✅ Consistent naming conventions
- ✅ Proper widget extraction (no 500-line build methods)
- ✅ const constructors where possible
- ✅ Proper dispose() for controllers and timers

## Quality Checklist (Before Every Commit)

1. [ ] Does every screen have entrance animations?
2. [ ] Are all interactive elements responsive to press?
3. [ ] Are loading states using skeleton shimmer (not just spinners)?
4. [ ] Are all colors from the design system?
5. [ ] Are all text styles using GoogleFonts?
6. [ ] Are network images handled with errorBuilder?
7. [ ] Are empty states designed (not just blank)?
8. [ ] Does `flutter analyze` pass clean?
9. [ ] Are all strings in Indonesian (for UI text)?
10. [ ] Is the bottom nav bar not overlapping content (enough bottom padding)?

## The Presensi Identity

This isn't a generic school app. It's the **official digital presence system** for SMK Negeri 1 Beringin, built with:
- Biometric face recognition
- Satellite geofencing
- Real-time WhatsApp parent notifications
- Anti-joki (anti-cheating) measures

Every pixel should reflect this level of sophistication. The app should feel like it was designed by a professional studio, not auto-generated.

