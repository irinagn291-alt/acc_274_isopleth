<!-- gf-brief source=3c9569f0ec2504c0e8cd7af7c44975de52d195ed840e58f090465b8f4d9bba67 written=2026-09-26T02:07:32+03:00 -->
# Isopleth

## What it is
Isopleth is a year plate for marking each day with one of twelve named tones. It treats the year as terrain rather than a journal, for anyone who wants a quiet daily mark, a quiet-days streak, and runs of the same tone over time.

## Launch and onboarding
1. Cold launch shows a blank dark screen for a short wait (often a few seconds).
2. The system may show the notifications permission alert (Allow / Don’t Allow). There is no in-app button that steers that grant.
3. **First launch on a real device (empty plate):** a four-page cover.

| Page | Title | Body |
|------|--------|------|
| 1 | The year plate | One mark for each day. Terrain, not a journal. |
| 2 | Set the tone | Tap today. Twelve named tones. Colour is never the only signal. |
| 3 | Ridges join | Same-tone cells that share an edge become a ridge. A close is a loop. A lone cell is a spot. |
| 4 | Quiet days | Consecutive marks ending today or yesterday. A gap starts over. |

Buttons on every page: **"SKIP"** (finishes the cover). Pages 1–3: **"Next"**. Page 4: **"Open the plate"**. Skip and Open the plate both open the year plate; later launches skip the cover.
4. **Returning launch:** the year plate home (no cover), unless Settings → **"Replay the cover"**.
5. **Simulator note:** the first empty Simulator run may already show sample past marks with the cover already finished, so the cover may not appear.

## Screens

### Year plate (home — no tab bar)
Portrait home for the current year. Dark appearance.

**Masthead**
- Year number at the top (device locale, e.g. `2026`).
- **"Mark today"**
- **"Tap today's cell, then Set the tone."**
- **"QUIET DAYS"** with a streak number (consecutive marked days ending today or yesterday).

**Day-by-day log**
- Weekday letters (locale short symbols).
- Week rows labeled with a localized week-start date (e.g. `Sep 22`).
- Recent weeks ending at today (about six weeks of weeks that have marks, plus today).
- **Today** cell: **"Today"**; if unmarked also **"Open"**; outlined. Tap → Set the tone well. Disabled while saving or if today cannot be marked.
- Marked past days: day number + tone name. Tap → Tone runs.
- Future days: dimmed, not tappable.
- Past unmarked days: day number only, not tappable.

**Legend — "ON THIS LOG"**
- Empty: **"No tones yet. Today is the outlined cell."**
- With marks: **"Today is outlined. Each marked day names its tone."** then the tone names in use, separated by periods.

**Footer**
- **"Set the tone"** — opens the well. Muted/disabled when today cannot be marked; while saving shows a spinner (accessibility **"Saving"**).
- **"TONE RUNS"** — opens Tone runs.
- **"SETTINGS"** — opens Settings.

**Banners (when shown)**
| Message | Control |
|---------|---------|
| That tone is not in the well. | **"TRY AGAIN"** (reopens the well) |
| The well is not twelve tones. | **"TRY AGAIN"** |
| Today is outside this plate. | **"TRY AGAIN"** |
| Tomorrow is still closed. | **"TRY AGAIN"** |
| Recovered from a spare copy. | **"RELOAD"** |
| Could not read the plate. Started empty. | **"RELOAD"** |

Loading overlay accessibility: **"Loading the plate"**.

**iPad / wide layout extras**
- Side rail **"TODAY'S TONE"**: **"Tap a name to mark today. The figure is how many cells already wear that tone."** — twelve named tone buttons with counts (same effect as the well).
- **"DAYS ALREADY MARKED"**: empty **"No marks yet. Today is the outlined cell."**; else date + tone rows that open Tone runs.

### Set the tone (overlay)
- Title: **"Set the tone"**
- **"Twelve named tones. Not a score."**
- Close control (X) / tap dimmed backdrop — accessibility **"Close the well"**
- Twelve tone buttons by spoken name (radial layout, or a list at large Dynamic Type).

Factory spoken names: **Still**, **Drift**, **Lift**, **Crest**, **Fold**, **Spur**, **Scarp**, **Bench**, **Sill**, **Notch**, **Rim**, **Peak**.

Tapping a name marks today, closes the well, and gives a brief success haptic. Marking again replaces today’s tone.

### Tone runs
- Title: **"Tone runs"**
- Intro: **"This view counts each unbroken stretch of consecutive days on the same tone, and single isolated days. One card is one stretch. Open a run to go back to those days."**
- **"DONE"** closes.

**Empty:** **"No runs yet."** / **"Mark today so a neighbor day can join it."** / **"Set the tone"** (dismisses and opens the well).

**Error empty:** **"Recovered from a spare copy."** or **"Started from a blank year."** / **"Reload the year, then count again."** / **"Reload"**

**Phone groups**
- **"SAME-TONE RUNS"** — **"Each card is one unbroken stretch of consecutive days on the same tone."** (or **"None yet."**)
- **"SINGLE DAYS"** — **"A marked day with no same-tone day on either side."** (or **"None yet."**)

**Each run card:** kind (**"SAME-TONE RUN"** / **"SINGLE DAY"**), tone name, count + **"DAY"**/**"DAYS"**, listed dates, then **"Mark today"** (if the run includes today → closes and opens the well) or **"Show these days"** (closes and returns to the log).

**Wide layout:** run cards plus **"MARKED DAYS"** — **"Date and tone only. Run lengths live in the cards above."** Rows of date + tone use the same open behaviour as the cards.

### Settings
- Navigation title: **"Settings"**
- **"DONE"** closes; keyboard **"DONE"** dismisses the keyboard.

**Empty marks (phone):** **"No marks yet."** / **"Tones are ready before the first stroke."**

**Twelve tones**
- **"Twelve tones"**
- **"Pick a tone, then rewrite its name or ink. Colour is never the only signal."**
- Rows: tone spoken name + cell count. Tap a row to edit it.

**Editor**
- **"SPOKEN NAME"** field (placeholder **"Spoken name"**)
- **"Shift ink"** — cycles the wash name beside the swatch: Cobalt, Ash, Cornflower, Mist, Periwinkle, Pearl, Ice, Silver, Powder, Fog, Lilac, Snow (or **Custom** if the colour does not match the factory ladder)
- Error: **"Could not rewrite the well. Names must stay unique."**

**Actions**
- **"Restore factory tones"** — restores the twelve factory names and inks
- **"Contact"** — opens the support/contact page outside the app
- **"Replay the cover"** — closes Settings and shows the cover again
- **"Reset all data"** → confirm **"Erase every mark on this plate?"** → **"Reset all data"** / **"Cancel"**

**Wide “ON THIS PLATE”:** selected tone name, count, **"cell marked."** / **"cells marked."**

**Save failure:** **"Could not save."** / **"The plate stayed in memory. Try again."** / **"Try again"**

## Features
- Year plate for the current year
- Mark today / Set the tone
- Twelve named tones (spoken names); colour is never the only signal
- Quiet days streak
- Tone runs (same-tone runs and single days)
- Day-by-day log with “On this log” legend
- Rename spoken names and Shift ink in Settings
- Restore factory tones
- Replay the cover
- Reset all data
- Contact
- Cover vocabulary also names ridge, loop, and spot (Tone runs lists runs and single days)

## Behaviours that can look like bugs
- **Blank screen on cold launch** — wait a few seconds; the plate or cover follows.
- **System notifications alert** — Allow or Don’t Allow; the app continues either way.
- **"Set the tone" muted / today’s cell disabled** — rare (today not on this year’s plate). Wait until a day that belongs on the plate; usually today works.
- **Future days not tappable** — expected; only today can be set.
- **Past unmarked days not tappable** — expected; only today and already-marked days respond.
- **Tone runs "No runs yet."** — mark today with **"Set the tone"** (from the empty state or the home footer).
- **Cover says ridge / loop / spot; Tone runs says runs / single days** — same app; open **"TONE RUNS"** for the list.
- **Duplicate spoken names** — rename fails with **"Could not rewrite the well. Names must stay unique."**; pick a unique name.
- **Empty spoken name** — blank/whitespace name is ignored; keep a non-empty name.
- **After "Reset all data"** — marks clear and Settings closes; the cover returns on the **next** cold launch (or use **"Replay the cover"**).
- **Simulator already has marks / no cover** — expected one-time sample content on first Simulator seed.

## Starter content and resume
- **Device:** empty plate after the cover; marks and tone renames persist across launches for the current year.
- **Simulator:** one-time sample past marks (factory tones Lift, Fold, Bench, Notch on various past days; today left open; cover treated as already finished).
- Cover completion and plate marks resume after relaunch; backgrounding keeps progress.
- Unfinished “draft” work beyond today’s replaceable mark: None.

## Permissions
- **Notifications** — near cold launch; system Allow / Don’t Allow. No custom in-app Continue/Allow screen for this.
- **Camera** — usage description in the build: **"This app does not use the camera."** The app never presents a camera permission dialog and has no camera UI.
- Mic, Photos, Location, App Tracking Transparency: not asked.

## Absent
Login or accounts; in-app purchase; ads; analytics screens; public user-generated content feeds; account deletion flow; App Tracking Transparency prompt. (Local **"Reset all data"** clears marks on the plate; there is no account to delete.)

## Data and support
Marks and tone names are kept on this device and return after relaunch. The UI does not show an “on this device” line. On-screen support control: **"Contact"** (opens the support/contact page outside the app).

## Scanning and health
None. The app does not scan barcodes or QR codes. It does not show health, medical, or product-health information.

## Platform
English development language; dates, weekday letters, and numbers follow the device locale. Portrait only on iPhone and iPad. Dark interface. Minimum iOS 17.0. iPhone and iPad.

## Category
Lifestyle
