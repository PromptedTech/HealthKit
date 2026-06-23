# AbsCountdown — Nutrition & Weekly Averages (v3)

## Context

AbsCountdown today is a single screen: an earned "days to abs" countdown driven by
Apple Watch Move + Exercise rings, a streak/stats/history section, a mascot, and a
home-screen widget. It tracks *training* but is blind to *food* — and abs are mostly
made by a **calorie deficit + enough protein**, not just closing rings.

This update adds a **second page: Nutrition**, plus weekly/average summaries across the
whole app. The user wants it to feel **modern and genuinely useful for cutting toward abs**,
not a generic calorie diary. Confirmed decisions:

- **Logging engine: built-in offline food library** — search a bundled list of common
  foods (Indian + Western), tap to add, adjust portion. No API key, no internet, instant.
- **Goals: both modes** — an **Auto "cut for abs"** target (computed from body stats →
  maintenance calories minus a deficit, plus a protein goal), AND a **Manual** override.
  A toggle in Settings switches between them.
- **Integration: side-by-side but separate** — Nutrition is its own page and a small
  summary strip appears at the top of the app, but the **countdown stays driven purely by
  rings**. Logging food never silently changes the day count (no surprises).
- **Averages**: the top of the app shows the **7-day daily average** kcal + protein; the
  workout page gains a **weekly average** (Move cal / Exercise min). A **weekend
  notification** delivers the week's summary.

Everything stays within free-Apple-ID limits — local data in the existing App Group,
local notifications only, no new paid capabilities.

---

## 1. Navigation — introduce a TabView

Today `ContentView` is one `NavigationStack` + `ScrollView`. Convert the root into a
**2-tab `TabView`** so "Nutrition" is a real second page:

- **Tab 1 — "Countdown"** (`flame.fill`): the existing screen, refactored into
  `CountdownScreen` (move current `ContentView` body verbatim into it), plus the new
  averages header and weekly-workout-average card.
- **Tab 2 — "Nutrition"** (`fork.knife`): new `NutritionScreen`.

Each tab keeps its own `NavigationStack`. The Settings gear stays in the Countdown tab's
toolbar (Settings gains the nutrition-goal section). `.preferredColorScheme(.dark)` and the
black background move to the `TabView`. `onOpenURL` handling in `AbsCountdownApp` is unchanged.

**Files:** `Sources/App/ContentView.swift` (refactor root → TabView + `CountdownScreen`),
new `Sources/App/NutritionScreen.swift`.

---

## 2. Data layer — new `NutritionStore`, plus ring snapshots

### New file: `Sources/Shared/NutritionStore.swift`
Same App-Group pattern as `CountdownStore` (suite `group.com.nakul.abscountdown`,
`Keys` enum, getters/setters). Kept in `Shared` so a future nutrition widget could read it.

Types (Codable, in this file):
```swift
struct FoodEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var kcal: Double          // per single serving
    var protein: Double       // grams per serving
    var servings: Double      // 1.0, 0.5, 2.0 …
    var date: Date            // when logged
    var totalKcal: Double { kcal * servings }
    var totalProtein: Double { protein * servings }
}

enum NutritionGoalMode: String { case auto, manual }
enum Sex: String { case male, female }
enum ActivityLevel: String { case sedentary, light, moderate, active } // 1.2 / 1.375 / 1.55 / 1.725
```

Stored keys / accessors:
- `foodLog: [FoodEntry]` — encoded as JSON `Data` under one key. Helpers:
  `addEntry(_:)`, `removeEntry(id:)`, `entries(on date:) -> [FoodEntry]`,
  `pruneOlderThan(days: 120)` to keep storage small.
- Day rollups: `totals(on date:) -> (kcal: Double, protein: Double)` and
  `dailyAverage(days: 7) -> (kcal: Double, protein: Double)` (averaged over days that
  actually have entries, so a fresh install doesn't read 0).
- Goal config: `goalMode`, plus body stats `weightKg`, `heightCm`, `age`, `sex`,
  `activityLevel`, `deficitPercent` (default 20), and manual `manualCalorieGoal`,
  `manualProteinGoal`.
- Computed targets (see §4): `calorieTarget: Double`, `proteinTarget: Double`.
- Each mutating setter calls `reloadWidgets()` (reuse the existing private helper pattern).

### Add to `Sources/Shared/CountdownStore.swift` — per-day ring snapshots
For the weekly *workout* average we need each day's Move/Exercise values, which aren't
stored today (only good/bad in `dayHistory`). Add:
- `ringHistory: [String: [String: Double]]` keyed `yyyy-MM-dd` → `{move, moveGoal,
  exercise, exerciseGoal}` (plist-safe nested dict).
- `recordRing(_ date:, _ ring: RingData)` — written from the catch-up loop.
- `weeklyRingAverage(days: 7) -> (move: Double, exercise: Double)`.

`EvaluationEngine.runCatchUp()` already iterates each past day and fetches its `RingData`;
add a `CountdownStore.recordRing(day, ring)` call right beside the existing
`recordDay(day, good:)` so history fills in naturally. (Reuse the same `yyyy-MM-dd`
formatter already in `CountdownStore`.)

---

## 3. Food library — `Sources/App/FoodLibrary.swift` (app target only)

A static, bundled dataset — no network. ~150 foods skewed to what the user eats
(paneer, dal, roti, rice, curd, eggs, chicken, whey, oats, banana, milk…) plus common
Western items.

```swift
struct FoodItem: Identifiable, Hashable {
    let id: Int
    let name: String
    let serving: String      // "100 g", "1 cup", "1 scoop", "1 roti"
    let kcal: Double
    let protein: Double
    let category: Category   // protein, carbs, dairy, fruit, snack, drink, meal
}
enum Category: String, CaseIterable { case protein, carbs, dairy, fruit, snack, drink, meal }
static let all: [FoodItem] = [ … ]
static func search(_ q: String) -> [FoodItem]   // case/diacritic-insensitive name match
```

Adding a food creates a `FoodEntry` from the selected `FoodItem` (carrying its `kcal`/
`protein`) with a chosen `servings` multiplier.

---

## 4. Goals engine — Auto "cut for abs" + Manual

Computed inside `NutritionStore` so both the UI and the weekend notification share one
source of truth.

- **Auto mode** (Mifflin–St Jeor):
  - `BMR = 10*weightKg + 6.25*heightCm − 5*age + (sex == .male ? 5 : −161)`
  - `TDEE = BMR * activityFactor(activityLevel)`
  - `calorieTarget = round(TDEE * (1 − deficitPercent/100))`, floored at a safe minimum
    (≈1500 male / 1200 female) so it never recommends something unsafe.
  - `proteinTarget = round(weightKg * 1.8)` g (good for muscle retention on a cut).
- **Manual mode**: `calorieTarget = manualCalorieGoal`, `proteinTarget = manualProteinGoal`.
- If Auto is selected but body stats are blank, the screen shows a friendly "Set your
  stats" prompt instead of a number.

**Settings** (`Sources/App/SettingsView.swift`) gains a **"Nutrition goals"** section:
a `Picker` for mode (Auto / Manual); Auto shows steppers/fields for weight, height, age,
sex, activity level, deficit %; Manual shows calorie + protein fields. Changing any value
just writes to `NutritionStore` (targets recompute live — no evaluation needed).

---

## 5. Nutrition screen UI — `Sources/App/NutritionScreen.swift`

Driven by a new `NutritionViewModel` (`@Published` today's entries, today's kcal/protein,
7-day averages, `calorieTarget`, `proteinTarget`). Reuses ContentView's styling helpers
(`cardBackground`, `stat`, `actionButton`, the progress-bar + gradient look).

Top-to-bottom:
1. **"Fuel today" hero card** — two progress bars in the rings visual language:
   **Calories** (you want to stay *under* target → bar fills toward the cap, turns
   amber/red past it) and **Protein** (fill toward goal → turns green when hit). Big
   `1,420 / 1,750 kcal` and `88 / 130 g protein` numbers via the existing `stat` helper.
   A one-line status: "330 under — on track to lean out" / "Protein goal hit 💪".
2. **7-day average card** — avg daily kcal + protein (the same figure shown app-top),
   with a 7-bar mini trend (reuse the `historyStrip` dot/bar pattern) so the user sees the
   week at a glance.
3. **Today's log list** — each `FoodEntry` row (name, servings, kcal · protein) with
   swipe-to-delete. Empty state nudge when nothing logged.
4. **"Add food" button** (`actionButton` style) → presents an **add sheet**: a search
   field over `FoodLibrary`, category chips, a recents row (last ~8 distinct foods), and a
   portion stepper (0.5× steps). Tap to log → returns to the screen, totals update instantly.

---

## 6. Countdown screen additions

In `CountdownScreen` (the refactored existing screen):
- **Averages header strip** at the very top (under the title): compact
  "Ø 1,610 kcal · 102 g protein / day" pulled from `NutritionStore.dailyAverage(7)` — this
  is the "top of the app shows my daily average" request. Tapping it switches to the
  Nutrition tab.
- **Weekly workout average card** near the activity card: "This week — avg Ø 540 cal move ·
  38 min exercise" from `CountdownStore.weeklyRingAverage(7)`, styled with the existing
  `stat`/`metric` helpers and the Move/Exercise gradient colors.

---

## 7. Weekend summary notification

Extend `Sources/App/NotificationManager.swift` (mirror the existing `syncReminder` style):
- `scheduleWeeklySummary(kcalAvg:proteinAvg:moveAvg:exerciseAvg:)` — builds a body like
  *"This week: Ø 1,610 kcal · 102 g protein/day · 540 cal move · 38 min ex. Keep cutting 🔥"*
  and schedules a one-shot `UNCalendarNotificationTrigger` for the **upcoming Sunday 19:00**
  (id `"weekend-summary"`); removes any stale pending one first.
- Called at the end of `EvaluationEngine.runCatchUp()` (and on app foreground refresh) with
  freshly computed averages, so each run re-arms next Sunday's note with current numbers.
- Authorization already covered by the existing `requestAuthorization()` path.

---

## File Summary

**New files**
- `Sources/Shared/NutritionStore.swift` — App-Group store, `FoodEntry`, goal math (both targets).
- `Sources/App/FoodLibrary.swift` — bundled `FoodItem` dataset + search (app target only).
- `Sources/App/NutritionScreen.swift` — the page + add-food sheet.
- `Sources/App/NutritionViewModel.swift` — `@Published` totals, averages, targets; add/remove.

**Edited files**
- `Sources/App/ContentView.swift` — root becomes a `TabView`; existing body → `CountdownScreen`
  with averages header + weekly workout-average card.
- `Sources/Shared/CountdownStore.swift` — `ringHistory`, `recordRing`, `weeklyRingAverage`.
- `Sources/App/EvaluationEngine.swift` — `recordRing` in the catch-up loop; call
  `scheduleWeeklySummary(...)` with computed averages.
- `Sources/App/NotificationManager.swift` — `scheduleWeeklySummary(...)`.
- `Sources/App/SettingsView.swift` — "Nutrition goals" section (mode + body stats / manual).
- (No widget or entitlement changes — nutrition is in-app only for now.)

After adding files: **`xcodegen generate`**, then build in Xcode (folder-based sources pick
up the new files automatically).

---

## Verification

- **Build & run on the physical iPhone** (rings need the paired Watch).
- **Logging**: Nutrition tab → Add food → search "paneer" → add 1.5 servings → today's
  kcal/protein totals jump by the right amount; row appears; swipe-delete removes it and
  totals drop back.
- **Auto goal**: Settings → Nutrition goals → Auto → enter weight/height/age → target shows
  a sensible deficit number + ~1.8 g/kg protein; the "Fuel today" bars/status reflect it.
- **Manual goal**: switch to Manual, set 1800 / 140 → targets and bars update immediately.
- **Averages**: log a few days (or seed entries) → top-of-app strip and the Nutrition 7-day
  card show the daily average; the Countdown weekly workout-average card shows avg Move/Exercise.
- **Separation**: logging food never changes the "days to abs" count — only rings do.
- **Weekend note**: a `"weekend-summary"` notification is scheduled for the next Sunday 19:00
  with current averages in its body (cancel/re-arm verified across runs).

## Caveats
- The weekend notification's numbers are a **snapshot from the last app/background run**
  (free-account background limits) — same best-effort model as the existing 7 PM reminder.
- Food-library values are **approximate per standard serving** — fine for trend/deficit
  tracking, not lab-grade. Portions are user-adjustable to compensate.
- App still must be **re-signed every 7 days** via Xcode (free personal team) — unchanged.
