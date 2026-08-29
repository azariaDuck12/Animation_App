# AGENTS.md — rules for AI coding agents working on Animation_App

> Adopted 2026-08-29. `CLAUDE.md` contains the single line `@AGENTS.md` so
> Claude Code, Cursor, Codex, Copilot and others all read the same rules.
> The files in `.cursor/rules/` are the long-form source; this is the
> condensed, tool-agnostic version. Cursor is not available on a tablet, so
> the rules must not live only there.

## Read first

- `docs/vision.md` — what and for whom.
- `docs/architecture.md` — layers, folder layout, stack, testing.
- `docs/data-model.md` and `docs/project-file-format.md` — the data; the
  file format is user data and is high-risk to change.
- `docs/decisions.md` — why things are the way they are. Add an ADR before
  changing anything recorded there.
- `docs/roadmap.md` — what is next; do not build later phases early.

## Stack (do not change without an ADR)

TypeScript (strict) · Vite · React · Canvas 2D · immer · zod · idb ·
fflate · mp4-muxer · Vitest · Prettier. No other runtime dependency
without explaining why in the PR and adding an ADR.

## Layer rules

```text
src/domain  ← pure TS: no DOM, no React, no browser APIs. Tests run in Node.
src/app     ← commands, store, editor state. Depends on domain only.
src/render  ← canvas drawing + hit testing. Depends on domain only.
src/infra   ← IndexedDB, files, video export. Depends on domain only.
src/ui      ← React. May depend on everything above.
```

- The `Project` value in the store is the only source of truth. Never keep
  a second copy of scene, character or animation data in a component, the
  canvas layer or a library's scene graph.
- Every edit goes through `store.dispatch(name, draft => …)`. Never mutate
  the project outside a command. Continuous gestures use
  `store.transient` and commit once.
- The renderer is one function used by viewport, playback and export. Do
  not add an export-only or preview-only drawing path.
- Editor state (selection, playhead, zoom) is not project data and is never
  saved to the file.

## Working method

1. Understand the request; read the code and docs it touches.
2. For anything beyond a small change, state a short plan: what changes,
   which files, risks, how it will be tested. Then do it.
3. Smallest change that solves the problem. Do not refactor or "tidy"
   unrelated code.
4. Preserve existing behaviour and tests. A failing test is investigated,
   not deleted or weakened.
5. Verify: `npm run typecheck`, `npm test`, and for UI changes, run the app
   on the tablet. Say what was and was not verified. Never claim a test
   passed that was not run.
6. Report: what changed, why, how it was verified, what is left.

## Tests

- `domain/` changes need unit tests (transforms, interpolation,
  evaluation, schema, migrations). Use `toBeCloseTo` for floats.
- Every command gets a "dispatch then undo restores the original" test.
- A `formatVersion` bump needs a new fixture in `test/fixtures/format/` and
  a migration test from every earlier fixture.
- Bug fixes include a regression test when practical.

## Touch and low-end devices

- Pointer Events only; 44 px minimum targets; no hover-only behaviour.
- Avoid work per frame that is not needed; render only when dirty.
- Large images are downscaled on import; do not hold full-size copies.

## Ask before

- Changing the data model, file format or storage layout.
- Adding a dependency.
- Changing the layer rules or folder layout.
- Removing a feature or a test.
- Anything that touches how projects are saved.

## Never

- Commit secrets or personal data.
- Force-push or rewrite history unless explicitly asked.
- Add a backend, accounts or analytics.
- Present a guess about the project as a fact; say "assumption" or ask.
