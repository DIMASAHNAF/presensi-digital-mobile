---
name: anti-ai-slop
description: Quality enforcement skill that prevents generic, templated, or low-effort AI output. Ensures every component, copy, and layout has intentional design decisions, realistic domain context, and production polish.
---

# Anti AI Slop — Quality Enforcement & Design Rigor

## What is "AI Slop"?

AI slop refers to generic, cookie-cutter, robotic output that looks like it was churned out by a language model without thought or contextual understanding. In code and UI, it manifests as placeholder text, default unstyled components, missing edge-case handling, and repetitive card layouts.

---

## 1. Concrete Rules & Enforcement

### No Generic Placeholder Content
- ❌ "Lorem ipsum dolor sit amet", "Sample student", "Test title", "User #123"
- ✅ Use authentic school context: **SMK Negeri 1 Beringin**, Kab. Deli Serdang, Sumatera Utara
- ✅ Use realistic Indonesian names (e.g., "M. Fajar Sidik", "Siti Rahmawati", "Rizky Pratama")
- ✅ Use actual vocational majors: **RPL** (Rekayasa Perangkat Lunak), **TKJ** (Teknik Komputer & Jaringan), **DKV**, **TP**, **TKR**, **TBSM**

### No Cookie-Cutter Layouts
- ❌ Repetitive cards with identical styling, borders, and visual weights
- ❌ Plain default Material Design or uncustomized Tailwind defaults
- ✅ Create visual hierarchy through intentional variation in container sizes, typography weight, and subtle accent pills
- ✅ Give every primary action and status a distinct semantic color and micro-interaction

### No Instant / Jarring Transitions
- ❌ Instant pop-in/disappear of elements with 0ms transition
- ❌ Solitary spinning loaders in empty white containers
- ✅ Micro-animations on interactive states (`active:scale-[0.97]` or `ScaleTransition(0.96)`)
- ✅ Content-matched skeleton shimmer during network fetch

### Comprehensive Edge Case & Defensive UX
- ❌ Missing empty states (blank screens when no data exists)
- ❌ Non-functional placeholder buttons or "Coming Soon" alerts
- ❌ Crashes or ugly overflow on long names or missing photos
- ✅ Always provide designed empty states with an actionable button (e.g. "Belum ada presensi hari ini. Presensi sekarang.")
- ✅ Defensive photo rendering with fallback initials avatar on network failure
- ✅ Text truncation (`TextOverflow.ellipsis`, `truncate`) with proper flex constraints

### Code Quality & Clean Architecture
- ✅ Zero unused imports or dead variables
- ✅ Indonesian UI copy with proper spelling and polite tone
- ✅ Separation of concerns: business logic isolated from UI presentation
- ✅ Strict compliance with security and privacy requirements (no exposed tokens or raw PII)

---

## 2. Verification Checklist

Before finalizing any screen, feature, or component:
1. [ ] Is the content authentic and contextually accurate for SMKN 1 Beringin?
2. [ ] Are loading, error, and empty states explicitly designed and tested?
3. [ ] Are interactive elements responsive to tap/click with tactile feedback?
4. [ ] Are text styles, colors, and border radii conforming to the design tokens?
5. [ ] Is error handling actionable, guiding the user toward resolution?
