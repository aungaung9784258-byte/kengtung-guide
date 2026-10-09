# Kengtung Travel Guide — Project Frame

**One product, three targets:** Android, iOS, Web — from a single codebase.

---

## 1. Recommended stack

| Layer | Choice | Why |
|---|---|---|
| App framework | **Flutter** (mobile + web) | Truly one codebase for Android/iOS/Web, excellent offline + map support, strong Myanmar font/text shaping |
| Alternative | React Native + Expo (with Expo Web / Next.js) | Pick this if you're stronger in JS/TypeScript |
| Maps | **MapLibre + OpenStreetMap tiles** (free) or Google Maps | OSM has good Kengtung coverage, no billing. Google only if you want its Directions quality |
| Routing / waypoints | OSRM or GraphHopper (free) / Google Directions | "Find path" + multi-stop waypoint trip |
| Location | GPS via `geolocator` (mobile) + browser Geolocation API (web) | Same API surface in Flutter |
| State | Riverpod (Flutter) / Zustand (RN) | Simple, testable |
| i18n | Flutter `intl` ARB files — `en.arb`, `my.arb` | English default, Myanmar switchable |
| Data | **Phase 1:** bundled local JSON (works fully offline) → **Phase 2:** Supabase/Firebase sync | Visitors often have weak data signal in Shan State |
| Admin | Lightweight web form writing to the same DB | So you can add places without a release |

> If you'd rather I use React Native/Next.js instead of Flutter, say so and I'll re-frame — everything below stays the same.

---

## 2. Categories (data model top level)

1. **Places to Visit** — viewpoints, Loi Mwe, Naung Tung Lake, One Tree Hill, heritage sites
2. **Pagodas & Temples** — Wat Jong Kham, Standing Buddha, etc.
3. **Markets** — Central Market, morning market, hill-tribe market days
4. **Transportation** — bus station, airport, taxi/motorbike/tuk-tuk stands, car rental
5. **Hotels & Guesthouses**
6. **Restaurants & Cafés**
7. **Emergency** — hospital, clinic, pharmacy, police station, fire station *(always shown, with one-tap call)*

Each category: icon + colour + EN/MY name. Sub-filters allowed (e.g. Transportation → Bus / Taxi / Airport).

---

## 3. Screen frame (what I will build)

### A. Onboarding / Splash
- `01` Splash (logo, Kengtung hero image)
- `02` Welcome — "Journey to Kengtung" + **language picker (English / မြန်မာ)** + Let's Tour button
- `03` Location permission request (skippable)

### B. Main tabs (bottom nav — 4 tabs)
**Tab 1 — Home / Explore**
- `04` Home: search bar, "Popular Places" horizontal cards, category chips row, nearby list
- `05` Search & results (text + filter by category, open now, distance)
- `06` Category listing (grid/list, sort by distance or rating)

**Tab 2 — Map**
- `07` Full map with coloured category pins + clustering
- `08` Map filtered by category
- `09` Pin tapped → bottom place card (photo, distance, Find Path / View Detail)
- `10` **Route view** — path drawn, distance + ETA, walk/drive/bike mode
- `11` **Trip planner** — add multiple places as waypoints, reorder, start navigation

**Tab 3 — Favourites**
- `12` Saved places grouped by category
- `13` Saved trips/itineraries

**Tab 4 — Profile / More**
- `14` Settings: Language (EN/MY), Theme (Light/Dark/System), Units, Offline map download
- `15` Emergency quick dial sheet
- `16` About Kengtung / credits / feedback

### C. Place detail
- `17` Detail: photo gallery, name, rating, category tag, description (EN/MY), address, phone, opening hours, price range, amenities, **View in Map / Find Path / Favourite / Share**
- `18` Reviews & ratings (list + write review)
- `19` Photo viewer (full screen)

### D. Extra value screens
- `20` Suggested itineraries — "Kengtung in 1 day / 3 days"
- `21` Festival & market-day calendar
- `22` Useful phrases EN ↔ Myanmar ↔ Shan (travel phrasebook)
- `23` Offline mode banner / downloaded area manager

### E. Web-specific
- Same screens, responsive: ≥1024px shows **two-pane layout** (list left, map right), proper URLs (`/place/wat-jong-kham`), SEO meta — so it also works as the town's public tourism site.

---

## 4. Design system

- **Colours:** primary teal/green `#17A47C`, accent amber `#F5B301`, emergency red `#E5484D`; neutral greys. Full light + dark token set.
- **Type:** Inter / Poppins for English, **Padauk or Pyidaungsu** for Myanmar (must be bundled — don't rely on device fonts).
- **Components:** PlaceCard, CategoryChip, MapPin, BottomSheetCard, SearchBar, RatingStars, SectionHeader, EmptyState, LanguageToggle, ThemeToggle.
- Rounded 16–24px cards, soft shadows, big photos — same mood as your reference shots.

---

## 5. Folder structure (Flutter)

```
lib/
  main.dart
  app/            app.dart, router.dart, theme/ (colors, typography, light, dark)
  l10n/           app_en.arb, app_my.arb
  core/           constants, utils, services/ (location, storage, connectivity)
  data/
    models/       place.dart, category.dart, review.dart, itinerary.dart
    sources/      local_json_source.dart, remote_source.dart
    repositories/ place_repository.dart, favourite_repository.dart
  features/
    onboarding/ home/ search/ category/ map/ route/ detail/ favourites/
    settings/ emergency/ itinerary/ phrasebook/
  shared/widgets/ place_card.dart, category_chip.dart, ...
assets/
  data/places.json  images/  icons/  fonts/
```

### Place JSON shape
```json
{
  "id": "wat-jong-kham",
  "name": { "en": "Wat Jong Kham", "my": "ဝပ်ကျုံးခမ်းဘုရား" },
  "category": "pagoda",
  "description": { "en": "...", "my": "..." },
  "address": { "en": "...", "my": "..." },
  "lat": 21.2896, "lng": 99.6031,
  "phone": "+95...", "openHours": "06:00-18:00",
  "images": ["assets/images/wat_jong_kham_1.jpg"],
  "rating": 4.7, "tags": ["heritage", "viewpoint"],
  "isEmergency": false
}
```

---

## 6. Build roadmap

| Phase | Deliverable |
|---|---|
| **0** | Repo scaffold, theme (light/dark), i18n EN/MY, routing, bottom nav shell |
| **1** | Data model + places.json seed (~20 real Kengtung places) + repositories |
| **2** | Home, Category list, Search, Place detail |
| **3** | Map: pins, clustering, filters, place bottom sheet |
| **4** | GPS, Find Path routing, waypoint trip planner |
| **5** | Favourites, Settings (language/theme), Emergency quick dial |
| **6** | Web responsive two-pane + deep links |
| **7** | Reviews, itineraries, phrasebook, offline maps |
| **8** | Polish, icons, store listing, deploy web |

---

## 7. What I need from you to start Phase 0

1. **Stack confirm:** Flutter (my recommendation) or React Native/Next.js?
2. **App name + logo** (or I'll draft one)
3. **Map provider:** free OSM/MapLibre or Google Maps (needs API key + billing)?
4. **Do you have place data/photos** already, or should I seed from public info?
5. **Reviews:** do you want user accounts (login), or keep v1 account-free?
