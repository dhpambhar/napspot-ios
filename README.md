# NapSpot (working name)

A cosy cat logic puzzle for iPhone and iPad, native SwiftUI. Put one cat in every row, every
column and every coloured area, and never let two cats touch, not even diagonally.

A clean-room game inspired by the "Queens" / one-star Star Battle puzzle genre that is
trending right now (Meowdoku! is #2 on the US top-free chart), with our own name, art, colours
and copy. Planning docs are in `replica/`.

## What's in it

- Boards from 5×5 up to 10×10, generated from a seed. Every board has exactly one answer and
  can be solved by logic alone; the solver proves it before you see the board.
- Campaign levels that grow in size, with a free cat on the first ten boards.
- A daily puzzle that is the same for everyone, with a streak.
- Tap once for ✕, twice for a cat; drag to paint ✕ over many cells. Three hearts: a wrong
  cat costs one. Undo, clear ✕, restart.
- Hints that do one step and explain it ("The mint area can only use spots in row 4, so the
  rest of row 4 is out").
- Optional auto-✕ around placed cats, colour patterns for colour-blind players, vibration.
- Best times, stats, and a board in progress resumes after relaunch.
- iPhone (portrait) and iPad (any orientation, the board scales up).

## Open it on the Mac

```bash
brew install xcodegen
xcodegen generate
open NapSpot.xcodeproj
```

Pick an iPhone or iPad simulator and press Run. Tests: Product → Test (Swift Testing).

## Layout

```
NapSpot/Game      generator, logic solver, level plan, game model (no UI)
NapSpot/Support   progress store, haptics
NapSpot/UI        home, game board, result cards, how to play, stats, settings
NapSpotTests      generator fairness, solver soundness, game rules, progress
replica/          recon map, feature matrix, architecture notes
```

## Before the App Store

- `/replica-brand`: a real name (check "NapSpot" for trademarks first), app icon.
- Set `bundleIdPrefix` and `DEVELOPMENT_TEAM` in `project.yml`.
- Sound effects are not in yet; haptics are.
