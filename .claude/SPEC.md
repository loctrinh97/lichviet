# SPEC — Lunar-Solar Calendar App (4 tabs, no backend)

## 1. Overview

A calendar app for Vietnamese users that displays the **solar and lunar calendars side by side**, plus weather and horoscope. Architecture is **local-first, no backend**: the app works fully even offline or when external services aren't configured. Only Google Drive sync is optional and requires sign-in.

**Target users:** general Vietnamese audience.

**Primary language:** Vietnamese (UI copy in Vietnamese).

**Platform:** responsive web/mobile-friendly.

---

## 2. Design principles

- **Local-first:** all user data is stored locally first; external services are an optional overlay.
- **No backend:** no dedicated server. Only client-callable APIs (Open-Meteo, Google Drive client-side OAuth).
- **App must never break** when the network or Google config is missing — only the dependent feature stops; everything else keeps working.
- **Separate logic from UI:** computation (lunar conversion, Can Chi, horoscope) and content (interpretations) are separate modules, easy to swap or upgrade.

---

## 3. UI style

- Modern, minimal, readable, generous spacing, clear typography.
- **Light/dark mode** (persist choice to localStorage).
- Navigation: **bottom tab bar** with 4 tabs: **Calendar · Weather · Horoscope · Profile**.

---

## 4. Data model

### 4.1 Event
```
Event {
  id: string          // UUID generated on creation, permanent
  title: string
  date: string        // solar date (ISO)
  isLunar: boolean    // recurs by lunar date vs solar date
  note?: string
  source: 'local' | 'ics' | 'drive'
  updatedAt: number   // timestamp, used for sync merge
  deleted: boolean    // tombstone flag (never hard-delete)
}
```

### 4.2 Profile
```
Profile {
  name?: string
  birthDate?: string      // solar birth date
  birthTime?: string      // birth time (for horoscope / Can Chi)
  gender?: 'male' | 'female' | 'other'
}
```

### 4.3 Settings
```
Settings {
  theme: 'light' | 'dark'
  language: string
  defaultCity?: { name: string, lat: number, lon: number }
}
```

---

## 5. Storage architecture

Two clearly separated layers:

- **LocalStore** — IndexedDB (in production; in-memory state in the demo). **Always used.** The app talks only to this layer directly.
- **SyncProvider** — Google Drive (scope `drive.appdata`). Activated only when the user signs in. Runs in the background, pushes/pulls a JSON file.

This separation lets you swap Drive for another provider later without touching the rest.

### Sync (merge) rules
- Match by `id`; the record with the newer `updatedAt` wins.
- Deletion uses a **tombstone** (`deleted: true`) so other devices know to delete too.
- Sync is **manual** (user taps a button) **and automatic on app open**. **No** silent continuous auto-sync (client-side OAuth tokens expire in ~1 hour with no long-lived refresh token).

---

## 6. Tabs

### 6.1 Calendar tab (lunar-solar)

**Main screen — monthly grid:**
- Each cell shows the **solar day** (large, prominent) and the **lunar day** (small, muted, bottom corner).
- Today is highlighted. Saturday / Sunday use a different color.
- Full/new moon days (15th / 1st lunar), holidays, and important lunar days (Tết, Vu Lan, Mid-Autumn…) carry a distinct marker (colored dot or small label).
- **Previous / next month** buttons and a **"Today"** button.
- Cells with events show an indicator (dot).

**Day detail (on tapping a cell):**
- Full solar date (weekday, DD/MM/YYYY).
- Corresponding lunar date.
- **Can Chi** for day / month / year.
- **Auspicious hours** (giờ hoàng đạo).
- Good/bad day (**hoàng đạo / hắc đạo**).
- Current **solar term** (tiết khí).
- Event list for the day (if any); add/edit/delete.

**Event management:**
- Add/edit/delete events (via LocalStore).
- Events may recur by **lunar date** (e.g. death anniversary) or solar date (e.g. birthday).
- **Import .ics** (drag-and-drop). **Export .ics / JSON**.

> **Production note:** requires an accurate Vietnamese lunar-calendar library (e.g. Hồ Ngọc Đức's algorithm). The demo uses sample data.

---

### 6.2 Weather tab

- Get location via `navigator.geolocation` (ask once) + a **city search** fallback.
- Show **current weather** + **hourly forecast** + **daily forecast**.
- **API: Open-Meteo** — free, **no API key required**, CORS-enabled → call directly from the client. (Avoid key-based APIs since a no-backend app would expose the key.)
- **Cache** results in local storage with a timestamp → viewable offline / on flaky networks.
- Persist the **default city** to localStorage (shared with the Profile tab).

---

### 6.3 Horoscope tab (fully offline)

**Computation (algorithm, client-side):**
- Based on the **birth date/time** from the Profile tab, compute: zodiac animal, Five-Elements destiny (ngũ hành), Can Chi, compatible/conflicting ages, ruling stars, favorable directions.

**Interpretation (static content):**
- Map computed results to **pre-written** passages bundled in the app (a JSON content file). No AI, no server, works offline.
- Show: **today's horoscope by age**, zodiac of the year, **good/bad days**, **compatible/conflicting ages**, favorable direction.
- A **"View detailed analysis"** button → longer interpretation (still from static content).

**Future extension (not now):**
- Keep the interpretation as a **separate module** (content decoupled from UI).
- Reserve space + small note: *"AI analysis: optional, configure later."*
- Technical note for later: if AI is added, computation still stays algorithmic; feed the model **pre-computed data** for interpretation only (LLMs are unreliable at Can Chi / lunar math). Calling AI needs a proxy to hide the key + rate limiting → no longer truly no-backend, so defer it.

---

### 6.4 Profile tab

**This is a local profile, NOT a login account.**

- **Info:** name, birth date/time (used for horoscope and Can Chi), gender.
- **Settings:** light/dark, language, default city (shared with Weather tab).
- **Data management:**
  - **Import .ics** button.
  - **Export .ics / JSON** button.
  - **"Sync with Google Drive"** button (scope `drive.appdata`):
    - Google sign-in appears only on tap.
    - Sync via merge (newer `updatedAt` wins, tombstone for deletes).
    - Manual sync + auto on app open; no silent continuous sync.
    - Sign-in serves sync only — the app runs fully without signing in.

---

## 7. External dependencies & no-backend constraints

| Feature | Approach | Constraint |
|---|---|---|
| Weather | Open-Meteo | No key, direct calls, works for real |
| Data storage | IndexedDB / localStorage | On the user's device |
| Sync | Google Drive `appdata`, client-side OAuth | Needs OAuth Client ID + a **fixed hosting domain**; token expires ~1h, user re-signs each sync session |
| Lunar / horoscope | Client algorithm + static content | Needs a lunar-calendar library in production |
| AI horoscope | (not built) | Deferred; needs a key-hiding proxy + quota |

---

## 8. Prototype notes (Claude Design)

- Build the **full UI for all 4 tabs**.
- The Weather tab **can call Open-Meteo for real**.
- Accurate lunar/horoscope computation and Google Drive sync: **simulate with sample data**, annotated in the app.
- Since the demo sandbox disallows localStorage → use **in-memory state**; switch to IndexedDB in production.
- If output gets overloaded, **build one tab at a time** (Calendar first, then the rest) for tighter, more reliable results.

---

## 9. Implementation priority (suggested order)

1. Calendar tab (core lunar-solar + events + import/export).
2. Profile tab (profile + settings + storage layer).
3. Weather tab (Open-Meteo).
4. Horoscope tab (algorithm + static content).
5. Google Drive sync (optional, do last).
