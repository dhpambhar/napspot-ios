# Recon map: Meowdoku! by Oakever Games (iOS / iPadOS)

Scope: the core loop: one daily puzzle plus a levelled campaign of "one cat per row, column and
colour region, no two cats touching" boards, with hearts, a timer, X marks and stats.
For: the user's own studio (DevAppStudio), a clean-room iPhone + iPad game to sell.
Date: 2026-11-02

Working name of the clone: **NapSpot** (every cat needs its own nap spot). Rename in /replica-brand.

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | App Store listing | https://apps.apple.com/us/app/meowdoku/id6761760135 | pitch, rules, IAP table, 4.8★ from 397K ratings, #1 Casual, 444 MB, iOS 15+, iPad, 62 languages |
| 2 | Top-free chart snapshot (Nov 1 2026) | https://gamedropdaily.com/mobile/ | #2 overall top free iPhone game |
| 3 | Fan rules guide | https://deskcade.pages.dev/guides/how-to-play-meowdoku-rules | controls (tap X, tap cat, tap clear), 3 hearts, timer, 6×6 early → 10×10 by ~L130, free starting cat early on |
| 4 | Android / Bluestacks page | https://www.bluestacks.com/campaign/com.oakever.meowdoku/ms/ | daily challenge, campaign, undo, restart |
| 5 | Genre reference | public "Queens" / one-star "Star Battle" puzzle rules | the logic is a classic public puzzle type; nothing proprietary in the rules |

## Core loop

Open the app → play the next board (or today's daily) → deduce where each cat goes using X marks →
solve it before losing 3 hearts → see your time → next board.

## Screens

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Home | launch | big "Level N" play button, daily card, streak, settings | PlayButton, DailyCard, StatChip | first launch, daily done, daily pending |
| S02 | Game board | Play / Daily | the puzzle | TopBar (back, level, timer), Hearts, Grid of cells, ToolBar (undo, hint, clear, mode) | fresh, in progress, wrong move (shake, heart lost), solved, out of hearts |
| S03 | Win | solve a board | time, best time, mistakes, next | ResultCard, Confetti, PrimaryButton | new best, normal, daily solved (streak +1) |
| S04 | Out of hearts | lose 3 hearts | retry | Modal, PrimaryButton, SecondaryButton | — |
| S05 | How to play | first launch, "?" button | 3 rules illustrated + controls | RuleCard, mini boards | — |
| S06 | Levels / progress | Home → levels | list of cleared boards with best times | LevelCell | locked, cleared, current |
| S07 | Daily calendar | Home → Daily | this month's dailies, streak | CalendarGrid | done, missed, today, future |
| S08 | Settings | gear | sound, haptics, auto-X, highlight conflicts, colour-blind patterns, reset | Toggle rows | — |
| S09 | Stats | Home → stats | solved count, best times per size, streak | StatCard | empty, filled |
| S10 | Paywall (original) | premium buttons | remove ads, unlimited hearts | — | skip: one Remove Ads IAP later |

## Flows

```
F01 Play the next campaign level
    S01 -> S02 -> S03 -> S02 (next)
    happy path taps: 1 to start; per board ~N double-taps + X marks
    edge: wrong cat (heart lost, cat bounces back as X), 3 hearts lost (S04), leave mid-game (resume)

F02 Daily puzzle
    S01 -> S02 (daily) -> S03 (streak +1)
    edge: already done today (show result), missed yesterday (streak resets), midnight while playing

F03 Learn the rules
    first launch -> S05 -> S02 (level 1, small board with a starting cat)

F04 Use a hint
    S02 -> hint -> board highlights a forced cell with the reason ("only spot left in the pink area")

F05 Change settings
    S01 -> S08 -> back
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| Cell | empty, X, cat, given cat | normal, highlighted, conflict, wrong (shake), solved (bounce) | S02 |
| Region border | thick between regions, thin inside | — | S02 |
| Hearts | 3 | full, lost (break animation) | S02 |
| Timer | mm:ss | running, paused, stopped | S02, S03 |
| PrimaryButton | big pill | default, pressed, disabled | S01, S03, S04 |
| DailyCard | — | pending, done | S01 |
| ToolBar button | undo, hint, clear X, input mode (X / cat) | default, disabled | S02 |
| Reason banner | hint text | shown, hidden | S02 |
| Win celebration | — | — | S03 |

## Inferred data model

```
Puzzle      size N (5…10), regions [[Int]] (N×N region index), solution [Int] (column per row),
            givens [cell], difficulty
            evidence: listing rules, guide (6×6 → 10×10, free starting cat early)
            confidence: high (rules) / guess (exact difficulty curve)

GameState   marks [[empty|x|cat]], hearts 0…3, elapsedSeconds, history (undo), finished
            evidence: guide (hearts, timer, tap cycle), Android page (undo, restart)
            confidence: high

Progress    currentLevel, bestTimes [level: seconds], dailyResults [day: seconds],
            streak, settings
            evidence: leaderboards of fastest times, daily puzzles
            confidence: medium
```

Relationships: Progress 1-n level results; each Puzzle is generated from a seed (level number or date), so
boards are never stored.

## Feature matrix

See `features.csv`. Must: 13, should: 9, could: 6, skip: 4.

## Out of scope (cannot or should not be cloned)

- Global leaderboards (Game Center can replace this later; their player network is theirs).
- The seasonal art events ("Trick or Meow!" etc.), cat artwork, sounds, name: all theirs. We draw our own cats.
- Their subscription ladder ($3.99/week …): monetization stays simple (Remove Ads / tip jar) in /replica-launch.
- 62 localisations: English first.

## Size

Screens 9, flows 5, entities 3. Hard parts: (1) generating boards that have **one** solution and are
solvable by logic alone, graded by difficulty; (2) a hint engine that explains the deduction;
(3) the feel: the tap cycle, wrong-move feedback and the win moment, on both iPhone and iPad.
No backend, no sync. Size: **S–M**.
