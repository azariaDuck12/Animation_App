# Animation_App Roadmap

## Status

Adopted 2026-08-29 (ADR-001). Phase 0 and Phase 1 are committed; later
phases are direction.

The order is chosen so that something visible runs on the tablet as early
as possible, and so that work cannot be lost once real editing begins.

---

## Phase 0 — Foundation

Goal: the app can be edited, run and tested on the tablet; nothing else is
built until this is true.

- [x] Decide: adopt the web-first architecture (option A of
      `reviews/2026-08-29-architecture-review.md`) — 2026-08-29.
- [x] Record the decision in `decisions.md` (ADR-001).
- [x] Record the development tablet (Lenovo Idea Tab Pro, Android) in
      `dev-environment.md`.
- [ ] Make the repository public and enable GitHub Pages (decided
      2026-08-29; owner to do).
- [ ] Archive the Flutter scaffold: remove `lib/`, `android/`, `ios/`,
      `linux/`, `macos/`, `windows/`, `web/`, `pubspec.*`, `.metadata`,
      `analysis_options.yaml` in one commit titled so it is easy to find.
- [ ] Scaffold: `npm create vite@latest -- --template react-ts`, strict
      TypeScript, Vitest, Prettier. Folder layout from `architecture.md` §3.
- [ ] Replace `.devcontainer` with the Node dev container (optional,
      enables Codespaces).
- [x] Add `AGENTS.md` at the root and `CLAUDE.md` containing `@AGENTS.md`;
      fix the truncated Cursor rule files.
- [x] Move adopted docs into `docs/`; archive the old architecture doc.
- [ ] **Milestone: "Hello, canvas" on the tablet** — a page that draws an
      imported image on a canvas, served from the tablet itself (Termux) or
      from the chosen cloud/PC workflow, opened in the tablet's browser.
      This proves the development loop (`dev-environment.md`).
- [ ] GitHub Actions: typecheck, test, build on every push.
- [ ] Deploy `main` to GitHub Pages (`base: '/Animation_App/'`); open the
      URL on the tablet.

## Phase 1 — Core MVP

Goal: the Phase 1 completion criteria below.

### 1. Domain model (no UI)

- [ ] Types and zod schema for `Project` (`data-model.md`).
- [ ] Transform matrix module; composition with pivot; tests.
- [ ] Keyframe interpolation and easing; tests.
- [ ] `evaluateScene`; tests for hierarchy, draw order, visibility.
- [ ] `migrate()` with the v1 fixture; test.

### 2. Store, commands, autosave

- [ ] `ProjectStore` with `dispatch`, `transient`, undo, redo.
- [ ] Commands: create/rename/delete for assets, characters, parts,
      scenes, objects; set transform; set pivot; set parent; reorder.
- [ ] IndexedDB persistence; autosave; recent projects list.
- [ ] Home screen: new / open / delete project.

### 3. Renderer and viewport

- [ ] Image import → `Asset` + Blob; `ImageCache`.
- [ ] `renderScene`; viewport canvas with zoom/pan; overlay canvas.
- [ ] **Milestone: an imported image appears in a scene on the tablet.**

### 4. Selection and transform handles

- [ ] Hit testing; tap to select; layers panel selection sync.
- [ ] Move / rotate / scale handles (Pointer Events, 44 px targets).
- [ ] Inspector with numeric fields.

### 5. Layers panel

- [ ] Back-to-front list; drag reorder; visibility; lock.
- [ ] Expand a character instance to its parts.

### 6. Character mode

- [ ] Character list; create; open in Character mode.
- [ ] Add parts from assets; parent picker; pivot tool; rest transforms.
- [ ] Draw order editing.
- [ ] Place an instance in a scene.
- [ ] **Milestone: a two-part character (body + arm) built and placed.**

### 7. Timeline and playback

- [ ] Timeline component: frames, playhead, scrub, zoom.
- [ ] Record keyframes from inspector/handles; keyframe markers; move,
      delete, copy/paste.
- [ ] Easing picker.
- [ ] Play / pause / loop with the rAF clock.
- [ ] **Milestone: the arm waves.**

### 8. Export

- [ ] PNG still export.
- [ ] MP4 export via WebCodecs in a worker; progress; cancel.
- [ ] WebM fallback via MediaRecorder.
- [ ] **Milestone: an MP4 opens in the tablet's gallery.**

### 9. Project file and polish

- [ ] `.animproj` export/import; round-trip test.
- [ ] Error messages for missing assets, unsupported versions, quota.
- [ ] Touch polish: pinch zoom, stacked layout on phones.
- [ ] Storage usage indicator; `storage.persist()`.

### Phase 1 completion criteria

```text
Create project
  ↓ Import image parts
  ↓ Build a character (parts, pivots, parent/child, draw order)
  ↓ Place it in a scene
  ↓ Animate position / rotation / scale / opacity with keyframes
  ↓ Preview at full speed
  ↓ Close the browser; reopen; everything is still there
  ↓ Export .animproj, delete the project, import it back
  ↓ Export PNG and MP4 and view them on the tablet
```

All of the above performed on the low-specification tablet, not only on a
PC.

## Phase 2 — P1 features

In rough order of value to Gacha animators: image-swap keyframes; poses;
audio with waveform and muxed export; multi-scene export; PWA install and
offline; onion skin; camera; text; GIF/image-sequence export; alpha-aware
selection; keyboard shortcuts.

## Phase 3 and beyond

P2–P5 from `features.md` as interest and time allow. Each large item (mesh
deformers, IK, drawing) gets its own ADR before work starts; deformers are
the first place where a Rust → WASM module might be justified by
measurement (ADR-002).

---

## Things this roadmap deliberately does not schedule

- iOS/Android store packaging.
- A backend of any kind.
- Performance work before profiling on the tablet shows a need.
