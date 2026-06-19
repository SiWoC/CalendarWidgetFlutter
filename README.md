# Calendar Widget

Android home-screen calendar widget with a Flutter companion app.

Shows upcoming events from calendars synced on the device (including Google Calendar).
UI labels are Dutch (`VANDAAG`, `MORGEN`, `vrijdag, 12 juni`, …).

**Package:** `nl.siwoc.calendarwidget`

---

## Architecture

The home-screen widget is Kotlin/Glance. 
The Flutter app is the **companion**: permissions, settings, preview, and manual refresh.

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter app (companion)                                        │
│  • Request calendar permission                                  │
│  • Settings (calendar selection, font size, colors …)           │
│  • In-app preview (same layout as widget)                       │
│  • MethodChannel.refresh() → triggers Kotlin refresh            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Kotlin — CalendarRefreshWorker (single implementation)         │
│  • WorkManager: periodic refresh (30 min) + boot reschedule     │
│  • On-demand: same code path from MethodChannel.refresh()       │
│  • CalendarContract → format JSON → SharedPreferences           │
│  • Trigger Glance widget update                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
              SharedPreferences key: calendar_widget_data
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
┌──────────────────────────┐   ┌──────────────────────────┐
│  Glance home-screen      │   │ Flutter preview          │
│  widget (Kotlin)         │   │ (reads JSON from refresh │
│  reads JSON, draws UI    │   │  response or same prefs) │
└──────────────────────────┘   └──────────────────────────┘
```

**Single source of truth:** JSON in app-private SharedPreferences. The worker writes it; the Glance widget and Flutter preview only read it.

---

## Components


| Layer                    | Technology                    | Role                                                      |
| ------------------------ | ----------------------------- | --------------------------------------------------------- |
| Home-screen widget       | Kotlin + Jetpack Glance       | Draw widget on launcher; read JSON from prefs             |
| Widget receiver          | `CalendarWidgetReceiver`      | Android entry point for widget updates                    |
| Refresh worker           | Kotlin + WorkManager          | CalendarContract, format JSON, write prefs, update widget |
| Refresh trigger (manual) | Flutter `MethodChannel`       | Calls same Kotlin refresh as WorkManager                  |
| Companion app            | Flutter                       | Permissions, settings, preview, pin widget                |
| Data contract            | JSON (`calendar_widget_data`) | Shared between Kotlin widget and Flutter preview          |


---

## JSON contract

**Key:** `calendar_widget_data`  
**Format:** JSON string in SharedPreferences.

```json
{
  "schemaVersion": 1,
  "error": null,
  "headerDate": "Vrijdag 12 juni 2026",
  "headerColor": "#FF000000",
  "headerFontsize": 14,
  "sections": [
    {
      "title": "VANDAAG",
      "events": [
        {
          "color": "#FFCC0000",
          "fontsize": 14,
          "time": "19:00-21:00",
          "title": "TNH Meetup",
          "location": "Pub",
          "isAllDay": false
        },
        {
          "color": "#FF008000",
          "fontsize": 14,
          "title": "Vakantie",
          "isAllDay": true
        }

      ]
    },
    {
      "title": "MORGEN",
      "events": [
        {
          "color": "#FFCC0000",
          "fontsize": 14,
          "time": "19:00-21:00",
          "title": "Quinn helpen",
          "location": "Pub",
          "isAllDay": false
        },
        {
          "color": "#FF008000",
          "fontsize": 14,
          "title": "Vakantie",
          "isAllDay": true
        }
      ]
    },
    {
      "title": "Maandag 14 juni",
      "events": [
        {
          "color": "#FF008000",
          "fontsize": 14,
          "title": "Vakantie",
          "isAllDay": true
        }
      ]
    }
  ]
}
```


| Field               | Description                                                                             |
| ------------------- | --------------------------------------------------------------------------------------- |
| `schemaVersion`     | Snapshot format version (currently `1`)                                                 |
| `error`             | `null` on success; `{ "code", "message" }` when refresh failed (e.g. permission denied) |
| `headerDate`        | Centered date line                                                                      |
| `headerColor`       | `#AARRGGBB` hex (e.g. `#FF000000`); copied from `header_color` setting                  |
| `headerFontsize`    | Header font size (sp); always present, copied from `header_font_size` setting           |
| `sections[].title`  | `VANDAAG`, `MORGEN`, or `EEEE d MMM`                                                    |
| `events[].color`    | `#AARRGGBB` hex from `CalendarContract`; worker writes via `Utils.argbToHex`            |
| `events[].fontsize` | Event font size (sp); always present, copied from `event_font_size` setting             |
| `events[].time`     | `HH:mm-HH:mm` for timed events; omitted when all-day                                    |
| `events[].isAllDay` | `true` → headerColor bullet in stead of time                                            |


### Event selection rules

- Query range: today through `fetchDays` ahead (settings, default 7).
- Multiday events are shown on all active days.
- Locale: (settings, default `nl_NL`; 24-hour times).

---

## Permissions

Declared in `AndroidManifest.xml`:

- `READ_CALENDAR`
- `WRITE_CALENDAR` (required by some calendar APIs even for read-only use)
- `READ_EXTERNAL_STORAGE` (max SDK 32) and `READ_MEDIA_IMAGES` — read the home-screen wallpaper for the **companion app preview** (`WallpaperReader` / `getWallpaper` on the MethodChannel). The preview mimics how the Glance widget looks on the launcher (wallpaper behind a semi-transparent card). The home-screen widget itself does not embed the wallpaper image; it draws on top of the launcher background.

**Flow:**

1. Flutter app requests permission on first launch (user must grant before background refresh works).
2. WorkManager **cannot** show a dialog — if permission is missing, worker writes empty/error state and widget shows fallback text.
3. Optional: “Open settings” in Flutter app if permanently denied.

---

## WorkManager


| Job            | Purpose                                                     |
| -------------- | ----------------------------------------------------------- |
| **Periodic**   | Refresh calendar data on a schedule (interval 30 minutes)   |
| **One-time**   | Enqueued by `MethodChannel.refresh()` for immediate update  |
| **After boot** | Re-register periodic work (Application or `BOOT_COMPLETED`) |


Periodic widget updates via `updatePeriodMillis` in `calendar_widget_info.xml` only **redraw** existing JSON — they do **not** fetch new calendar data. WorkManager owns data refresh.

---

## Flutter ↔ Kotlin API

Single MethodChannel: `nl.siwoc.calendarwidget/calendar` (`WidgetConstants.METHOD_CHANNEL`).


| Method                      | Description                                                                                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `refresh()`                 | Run `CalendarRefreshWorker` logic: read calendars → JSON → prefs → update widget. **Returns** JSON string for preview (no separate read call required). |
| `schedulePeriodicRefresh()` | Register / update WorkManager periodic job (e.g. after settings change).                                                                                |


Settings stored in SharedPreferences file `nl.siwoc.calendarwidget` — read by Flutter (settings UI) and the Kotlin worker. Glance reads only the snapshot JSON.


| Key                     | Type         | Default     | Used by                                        | Description                                                                          |
| ----------------------- | ------------ | ----------- | ---------------------------------------------- | ------------------------------------------------------------------------------------ |
| `calendar_widget_data`  | JSON string  | —           | Worker (write), Glance, Flutter preview (read) | Render snapshot produced by the worker                                               |
| `header_color`          | string (hex) | `#FF000000` | Worker, settings UI                            | Hex string; use [Utils.hexToColor] at render time                                    |
| `header_font_size`      | int (sp)     | `14`        | Worker                                         | Header font size; copied into snapshot JSON                                          |
| `event_font_size`       | int (sp)     | `14`        | Worker                                         | Event font size; copied into each `events[].fontsize` in JSON                        |
| `fetch_days`            | int          | `7`         | Worker                                         | Days ahead to query (today + N)                                                      |
| `locale`                | string       | `nl-NL`     | Worker                                         | Date/time formatting (`VANDAAG`, 24h times)                                          |
| `selected_calendar_ids` | string (CSV) | `""` (all)  | Worker                                         | Comma-separated calendar IDs; empty = all visible                                    |


**Kotlin:** `WidgetConstants.kt`, `WidgetSettings.kt`, `Utils.kt`, `CalendarWidgetData.kt`, `CalendarPlatformChannel.kt`  
**Dart:** `widget_constants.dart`, `widget_settings.dart`, `utils.dart`, `calendar_widget_data.dart`, `calendar_platform_channel.dart`

Event colors are **not** settings — they come from `CalendarContract` and are written per event in the snapshot JSON.

---

## Implementation

Build in this order (check off as done):

- [x] **Scaffold** — `flutter create`, package `nl.siwoc.calendarwidget`, manifest permissions
- [x] **Contracts** — prefs keys, settings keys
- [x] **DataModel** — JSON schema (`schemaVersion`, error state)
- [x] **CalendarRefreshWorker** — `CalendarContract` → JSON → SharedPreferences
- [x] **MethodChannel** — `refresh()` runs worker, returns JSON for Flutter preview
- [x] **Flutter companion** — permission flow,  data preview
- [x] **Glance widget** — `CalendarWidgetReceiver`, read prefs, draw UI; `updatePeriodMillis="0"`
- [ ] **WorkManager** — periodic (30 min), one-time (manual refresh), boot reschedule
- [ ] **Flutter companion** — settings UI, pin widget
- [ ] **Edge cases** — permission denied fallback, midnight / day rollover refresh

---

## Conventions

Decisions that apply across layers (for implementers and fresh context):

- **Settings → snapshot:** `CalendarRefreshWorker` always starts with `WidgetSettings.load()`. Display fields (`headerColor`, `headerFontsize`, each `events[].fontsize`) are copied from settings into `CalendarWidgetData`. The worker does not read `WidgetConstants.DEFAULT_*` for those — defaults apply only when loading settings (empty prefs).
- **Strict JSON read:** `CalendarWidgetData.fromJson` expects every contract field. Missing keys are a writer bug, not something readers paper over with defaults.
- **Hex strings only:** `WidgetSettings` and `CalendarWidgetData` store colors as hex `String`. No `Color` type in those layers. Use `Utils.hexToColor()` only when drawing (Glance, Flutter UI).
- **Hex format:** `#AARRGGBB` everywhere (settings prefs, snapshot JSON, worker output). `Utils` accepts `#` or `0x` on read; writers always emit `#` via `Utils.argbToHex`.
- **Complete snapshot JSON:** Always write `headerFontsize` and every event’s `fontsize` — even when they match defaults. Same-app contract; omission is a bug.
- **Error snapshots:** `CalendarWidgetData.error(code, message, settings)` — pass the same `WidgetSettings` instance as the happy path so fallback UI matches user prefs.
- **Constants naming:** Dart `WidgetConstants` mirrors Kotlin: `UPPER_SNAKE_CASE` (`KEY_HEADER_COLOR`, `DEFAULT_HEADER_FONT_SIZE`, …).
- **Event colors:** Come from `CalendarContract`, converted to `#AARRGGBB` by the worker — not from user settings.

---

## Notes

- **Don’t add `android/` as a separate workspace root.** The Android module depends on the Flutter project (`flutter.sdk`, Flutter Gradle plugin). Opening it alone breaks Gradle import and causes IDE errors in Cursor.

---

