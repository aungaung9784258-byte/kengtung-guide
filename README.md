# Kengtung Guide — Flutter (Android · iOS · Web)

Travel guide for Kengtung (Kyaing Tong), Eastern Shan State.
**English + Myanmar · Light/Dark · Free maps with GPS routing · $0 running cost.**

---

## Run it

```bash
flutter create . --platforms=android,ios,web --org com.kengtung   # generates platform folders
flutter pub get
flutter run                 # phone
flutter run -d chrome       # web
```

> `flutter create .` inside this folder keeps `lib/`, `assets/` and `pubspec.yaml`
> and only adds the missing `android/ ios/ web/` folders.

Open `design-preview.html` in a browser to see the palette and motion without Flutter.

---

## Why this map stack costs nothing

| Need | Service | Cost |
|---|---|---|
| Basemap tiles | **OpenStreetMap raster** via `flutter_map` | Free, no key, no card |
| Pins / place data | Your own `assets/data/places.json` | Free — zero Places API calls |
| GPS | `geolocator` (device) / browser Geolocation | Free |
| Find path / waypoints | **OSRM** public demo server | Free, no key |

Google Maps would require a billing account even for its free tier, so it's out.
Attribution to *OpenStreetMap contributors* is displayed on the map — this is
required by the OSM tile policy and is already wired up.

**Before launch:** the OSRM demo server is rate-limited. Self-host OSRM on a
small VPS (one township's extract is tiny) or switch `_host` in
`lib/core/services/routing_service.dart`. Same for tiles if traffic grows —
OpenFreeMap or a self-hosted Protomaps `.pmtiles` file is still $0.

---

## Design system

### Palette — "Jade & Gold"
| Token | Hex | Meaning |
|---|---|---|
| `jade` | `#0FA47F` | primary — Shan hills, Naung Tung Lake |
| `jadeDeep` | `#07634F` | gradients, pressed states |
| `gold` | `#FFB020` | accent — stupa gilding, ratings |
| `coral` | `#FF6B5A` | favourite heart |
| `danger` | `#E5484D` | **Emergency only** — never decorative |

Category pins: jade / gold / chilli `#F2762E` / indigo `#6C5CE7` / sky `#2E8BF2` / rose `#E2457A` / red.

Light = warm sand (`#F7F8F5`), not cold grey. Dark = forest night (`#0B1412`), not pure black.

### Motion — `lib/app/theme/app_motion.dart`
Every animation in the app pulls its duration and curve from this one file.

| Token | Value | Used by |
|---|---|---|
| `micro` 140ms | taps, press-scale | `PressableScale` |
| `fast` 240ms | chips, toggles | `CategoryChips`, `_Segmented` |
| `base` 380ms | page + card reveal | `RevealIn`, routes |
| `hero` 520ms | detail push | shared-element |
| `slow` 620ms | map camera fly | `_flyTo` |
| `stagger` 70ms | per-item delay | list cascades |
| `easeOutExpoCurve` | `cubic-bezier(.16,1,.3,1)` | the house curve |
| `springy` | overshoot | heart pop, map pins |

### Where the motion actually shows up
- **Parallax hero** — Home and Detail backgrounds drift at 35% of scroll speed and zoom on overscroll.
- **Parallax list photos** — `ParallaxItem` (`shared/widgets/parallax.dart`) moves each card's photo *inside* its own frame, vertically in lists and horizontally in the Popular rail. Built on `Flow` so it costs one repaint, not a rebuild.
- **Staggered reveal** — `RevealIn(index: i)` cascades cards in with a 70ms step.
- **Shared element** — the photo flies from card to detail hero (`Hero(tag: 'place-img-$id')`).
- **Collapsing top bar** — Detail's app bar fades its background and title in as you scroll.
- **Map camera** — tweened fly-to instead of a jump cut; pins scale with an overshoot; "you are here" dot pulses.
- **Tab switches** — cross-fade + subtle scale rather than a hard cut.
- **Sliding segmented control** — the Settings language/theme pill slides between options.

---

## Structure

```
lib/
  main.dart
  app/        app.dart · router.dart · shell.dart · theme/{app_colors,app_theme,app_motion}.dart
  l10n/       app_localizations.dart      <- EN + MY maps, no codegen step
  core/       providers/app_providers.dart · services/{location,routing}_service.dart
  data/       models/{place,place_category}.dart · repositories/place_repository.dart
  features/   onboarding · home · map · detail · favourites · settings
  shared/widgets/  parallax.dart · motion_widgets.dart · place_card.dart
                   category_chips.dart · place_image.dart
assets/data/places.json   <- 20 seeded Kengtung places, EN + MY
```

### Adding a place
Append to `assets/data/places.json`. No code change needed.
`images` accepts asset paths or URLs; leave it `[]` and the card renders a
category-coloured gradient placeholder instead of a broken image.

### Adding a string
Add the key to **both** `_en` and `_my` in `app_localizations.dart`,
then use `context.l10n.t('yourKey')`.

---

## Offline mode

The app is built so that **everything except live routing works with no internet.**

| Part | Offline? | Why |
|---|---|---|
| Place data, descriptions, phone numbers | ✅ always | bundled in `assets/data/places.json` |
| Photos | ✅ always | bundled in `assets/images/` |
| Favourites, language, theme | ✅ always | `shared_preferences` on device |
| GPS "you are here" | ✅ always | satellites need no internet |
| Map tiles | ✅ after download | cached on device |
| Find path (road route) | ❌ needs internet | falls back to a direct line + distance |

### How it works
* **`core/services/offline_map_service.dart`** — slippy-map tile maths, region
  definitions, a rate-limited downloader that streams `DownloadProgress`,
  cache size reporting and clearing.
* **`shared/widgets/cached_tile_provider.dart`** — the map reads tiles from the
  device cache first. Side effect: any area browsed while online is saved
  automatically.
* **`core/services/connectivity_service.dart`** — `onlineProvider` drives the
  offline banner and the routing fallback.
* **Settings → Offline maps** — two regions with tile count, size estimate, a
  live progress bar and cancel:

| Region | Zooms | Tiles | Size |
|---|---|---|---|
| Kengtung town | 11–17 | ~1,460 | ~26 MB |
| Kengtung + surroundings (incl. Loi Mwe) | 11–16 | ~3,950 | ~70 MB |

* **Offline routing fallback** — `RoutingService.straightLine()` draws a gold
  **dashed** line with straight-line distance, versus the solid jade line of a
  real road route, so the difference is never ambiguous.
* **Web** — the browser handles caching, so the download UI is hidden there.

> ⚠️ **Before publishing:** OSM's public tile servers forbid bulk downloading.
> The regions here are small and the downloader is throttled (4 at a time,
> 120 ms between batches), which is fine while you develop. For the store
> release, point `OfflineMapService.tileUrlTemplate` at your own source — a
> self-hosted Protomaps `.pmtiles` file is a single file, free, and removes
> this concern entirely.

See `docs/PLATFORM_SETUP.md` for the Android/iOS permissions this needs.

---

## Still to do

- [ ] Real photos for the 20 places (sample AI images are in place now)
- [ ] Bundle **Padauk** font and uncomment the `fonts:` block in `pubspec.yaml`
- [ ] Marker clustering at low zoom (`flutter_map_marker_cluster` is already a dependency)
- [ ] Pre-bundle the town tiles in the APK so it works offline on first launch
- [ ] Switch tile source to self-hosted Protomaps before store release
- [ ] Multi-stop trip planner UI (`RoutingService.route()` already takes a waypoint list)
- [ ] Web: responsive two-pane layout (list left, map right) at ≥1024px
- [ ] Reviews, itineraries, phrasebook, offline tile download
