# Isopleth

Set a tone for today. The year plate holds one mark per day and unions same-tone neighbors into ridges.

Isopleth is for people who want a year as terrain, not a journal feed, a pet, or a 1 to 5 heatmap.

## Architecture

Contour-union encoding. One `YearPlate` is the year document and the single `ObservableObject` every view observes. Set is the only write: it upserts one `MoodEntry` keyed as Int YYYYMMDD from `Calendar.current.startOfDay`. The plate then recomputes contour components.

Same-tone cells that share a grid edge on the week-column plate union into a `Ridge`. A component of one cell is a `Spot`. A ridge whose four-neighbor graph contains a cycle writes a `Loop`.

This pattern fits the product because every screen is a projection of one year. The plate never leaves. The well, Ridges, and Settings bind to that same object and never keep a forked map. SpriteKit bloom reads the plate after commit and owns no entries.

Persistence is UserDefaults+Codable under `ipl.store.v1`, with an atomic file projection. Views never touch UserDefaults.

## Twist

Set-then-ridge. Tap today, pick one of twelve named tones, and the plate marks that cell. Neighbors of the same tone, including a weekday column, join into a ridge. A closed ridge is a loop. A lone cell stands as a spot. Ridges lists those counts. Quiet streak is consecutive marked days ending today or yesterday. A gap restarts. There is no broken-streak theatre.

## Screens

The year plate never leaves. Tapping today opens the twelve-tone well as an overlay. Ridges and Settings arrive as sheets. `-ReviewScreen today|log|goals` are launch keys, not tabs.

## Art

Tactile watercolor on heavy cold-press paper, wet-on-wet washes that dry into raised pigment ridges, granulation along contour lines, dry-brush tooth, studio raking light, no text, no letters, no UI chrome.

| Image set | Prompt |
| --- | --- |
| `ipl_AppIcon` | Tactile watercolor emblem of a closed contour ridge on heavy paper, subject filling the canvas edge to edge, solid opaque field, no text, no letters, no rounded corners, no drop shadow, no alpha |
| `ipl_Splash` | Tall cold-press paper void with a quiet centre band, faint tactile watercolor grain at the margins, one dry contour suggestion, no text |
| `ipl_Onboarding1` | A keeper facing an empty year plate on heavy paper, tactile watercolor, solid subject, transparent corners, no text |
| `ipl_Onboarding2` | A finger setting a tone on today's cell as a radial well opens, tactile watercolor mid-gesture, solid subject, transparent corners, no text |
| `ipl_Onboarding3` | A used year plate with joined ridges and one closed loop, tactile watercolor accumulation, solid subject, transparent corners, no text |
| `ipl_EmptyHome` | A solid unglazed ceramic plate waiting for the first mark, fully opaque subject in the centre, real transparent corners, not glass, not a wire frame, tactile watercolor, no text |
| `ipl_EmptyList` | A blank contour census sheet with no ridges drawn yet, solid paper subject, transparent corners, tactile watercolor, no text |
| `ipl_CardBackdrop` | Abstract tactile watercolor wash filling the canvas, low contrast paper tooth, no subject that competes with type, no text |
| `ipl_ControlFace` | Face of a radial twelve-tone well as a tactile watercolor disc, solid opaque centre, transparent corners, no text |
| `ipl_TwistHero` | Two same-tone year cells sharing a grid edge and unioning into one raised ridge, tactile watercolor, solid subject, transparent corners, no text |
| `ipl_SuccessMark` | A small closed contour loop as a tactile watercolor seal, solid subject, transparent corners, no text |
| `ipl_HeaderDecor` | Wide decorative watercolor band of one quiet contour on paper tooth, fill the canvas, no text |

## How this differs

Washfolio paints then bleeds toward yesterday and counts wash-runs. Coaming stamps a daily impulse card onto a year grid. Isopleth paints then unions same-tone grid neighbors, including a weekday column, and counts spots, ridges, and loops. Home is the year plate, not a hatch and not a list.

## Build

```bash
cd Isopleth
xcodegen generate
xcodebuild -scheme Isopleth -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```
