# Animation_App Architecture

## Status

Adopted 2026-08-29 (ADR-001). Supersedes the Flutter-era architecture,
archived at `archive/2026-08-flutter-architecture.md`.

This document keeps every architectural *principle* of that earlier
document — layered design, UI is not the source of truth,
animation data independent of the timeline, versioned project format,
reusable definitions separate from instances — and makes the concrete
decisions it left open. Where a decision is recorded in
`decisions.md`, the ADR number is given.

---

## 1. Goals

1. The complete edit → run → test loop must work on a low-specification
   tablet with no paid remote machine (ADR-001, `dev-environment.md`).
2. Keep the animation and project model independent of the UI framework
   and of the browser, so it can be tested in plain Node.
3. One renderer for viewport, playback and export.
4. Save continuously; never lose work to a discarded browser tab.
5. Versioned, migratable project format from day one.
6. Undo/redo designed in from the first command.
7. Few dependencies, each one justified.
8. Keep the MVP small.

---

## 2. Technology stack (ADR-001, ADR-002, ADR-003)

| Concern | Choice | Notes |
| --- | --- | --- |
| Language | TypeScript (strict) | Runs everywhere the tablet's browser runs; best AI-assistant fluency of any option. |
| Build / dev server | Vite | Sub-second hot reload; ~200 MB RAM; ships Android-arm64 binaries so it runs inside Termux. |
| UI panels | React | Layers, timeline, inspector, dialogs. The canvas itself is driven imperatively, outside React. |
| Rendering | HTML Canvas 2D | Hand-written renderer, ~200 lines. WebGL is not needed for hundreds of sprites. |
| State / undo | Hand-rolled store + `immer` patches | Every edit is a command producing forward and inverse patches. |
| Validation | `zod` | Schema for `project.json`; validates after migration. |
| Local storage | IndexedDB via `idb` | Autosave, recent projects, asset blobs. |
| Project file | ZIP via `fflate` | `.animproj` = `project.json` + `assets/`. |
| Video export | WebCodecs + `mp4-muxer` | Client-side MP4. `MediaRecorder` WebM fallback. |
| Tests | Vitest | Domain and application tests run in Node, no browser. |
| Formatting | Prettier | ESLint optional; keep the tool set light. |
| Delivery | Static site, installable PWA | Free static hosting; no server. |

Runtime dependencies for the MVP: `react`, `react-dom`, `immer`, `zod`,
`idb`, `fflate`, `mp4-muxer`. Nothing else without an ADR.

Explicitly *not* used for the MVP: Rust/WASM (ADR-002), a scene-graph
library such as PixiJS or Konva (ADR-004), a database (ADR-005), a backend.

---

## 3. Layers

The four conceptual layers of the earlier architecture are kept and mapped
to folders. The dependency rule is enforced by the simplest possible
mechanism: `domain/` and `app/` tests run in Node, where `window`,
`document` and `HTMLCanvasElement` do not exist, so any accidental browser
dependency fails immediately.

```text
src/
├── domain/        Pure TypeScript. Types, zod schema, transform maths,
│                  animation evaluation, migrations. No DOM, no React.
├── app/           Commands (immer), ProjectStore with undo/redo,
│                  editor state (selection, mode, playhead), playback clock.
├── render/        Canvas 2D renderer, image cache, hit-testing.
│                  Depends on domain only. Takes a CanvasRenderingContext2D.
├── infra/         IndexedDB store, .animproj import/export, image decoding,
│                  video export (WebCodecs), file pickers/downloads.
├── ui/            React components: EditorShell, Viewport, Timeline,
│                  LayersPanel, Inspector, CharacterEditor, dialogs.
└── main.tsx
```

```text
        ui
     ┌───┼──────────┐
     ▼   ▼          ▼
    app  render   infra
     │    │         │
     └────┼─────────┘
          ▼
        domain
```

- `domain` depends on nothing in the app.
- `app`, `render` and `infra` depend on `domain` only (and on each other
  never).
- `ui` may depend on all of them.

Mapping to the earlier document's layers: Presentation = `ui`;
Application = `app`; Domain = `domain`; Infrastructure = `infra` and
`render`.

---

## 4. The project document is the source of truth

The whole editable state is one immutable `Project` value (see
`data-model.md`). The store holds the current value; React components read
from it through `useSyncExternalStore`; the renderer takes it as an
argument. There is no second copy of the scene inside the canvas layer, the
timeline or anywhere else.

Transient editor state — selection, active mode, playhead frame, zoom and
pan, which panels are open — lives in a separate `EditorState` in `app/`.
It is never written to the project file.

---

## 5. Commands, undo and redo (ADR-006)

Every change to the project goes through one function:

```ts
store.dispatch(name: string, recipe: (draft: Project) => void): void
```

`dispatch` runs the recipe with `immer`'s `produceWithPatches`, stores the
inverse patches on the undo stack, clears the redo stack, bumps
`modifiedAt`, and notifies subscribers. Undo applies inverse patches; redo
applies forward patches.

Consequences:

- Commands are ordinary functions that mutate a draft. There is no command
  class hierarchy to maintain.
- Undo/redo works for every command automatically, including ones written
  later.
- Continuous gestures (dragging a part) call a separate
  `store.transient(recipe)` that updates the value without recording
  history, and commit one `dispatch` on gesture end, so a drag is one undo
  step.
- Autosave subscribes to the store and writes the project after a short
  debounce (see §8).

---

## 6. Animation evaluation

```text
Project + sceneId + frame
        ↓
evaluateScene()  →  EvaluatedScene (a flat list of draw items,
        ↓            back-to-front, each with a world matrix, asset id,
        ↓            opacity and size)
render()         →  pixels on a canvas
```

`evaluateScene` (in `domain/`) is a pure function. For each scene object it
resolves the object's transform at the given frame (base transform overridden
per property by that object's tracks), and for a character instance it
resolves each part's transform (rest transform overridden per property by
tracks targeting that instance and part), composes world matrices down the
parent hierarchy, and emits draw items in draw order.

Keyframe interpolation (`domain/animation.ts`):

- Before the first keyframe: the first keyframe's value.
- After the last: the last keyframe's value.
- Between two: `a + (b − a) · ease(t)` where `t` is the normalised frame
  position and `ease` is the *earlier* keyframe's easing. `hold` returns
  `a` until the next keyframe.
- Rotation is interpolated as a plain number (no shortest-path wrapping);
  animators control direction by choosing keyframe values.

Transform maths (`domain/transform.ts`) is a small 2-D affine matrix module
(`[a, b, c, d, e, f]`, the same layout as `CanvasRenderingContext2D
.setTransform`). See `data-model.md` §7 for the composition rule.

---

## 7. Rendering (ADR-004)

`render/renderScene.ts`:

```ts
renderScene(ctx: CanvasRenderingContext2D, evaluated: EvaluatedScene,
            images: ImageCache, options: { background?: string }): void
```

For each draw item: `ctx.setTransform(worldMatrix)`,
`ctx.globalAlpha = opacity`, `ctx.drawImage(bitmap, 0, 0)`.

The same function draws:

- the **viewport** (with an additional view matrix for zoom/pan, and a
  second, transparent **overlay canvas** on top for selection outlines,
  pivot markers and transform handles — never mixed into the scene render);
- **playback** (a `requestAnimationFrame` loop advancing the playhead);
- **still export** (an `OffscreenCanvas` at project resolution →
  `toBlob('image/png')`);
- **video export** (an `OffscreenCanvas` per frame → `VideoFrame` →
  `VideoEncoder`).

The `ImageCache` maps asset IDs to decoded `ImageBitmap`s and is the only
place image decoding happens.

Hit testing (`render/hitTest.ts`) inverts each draw item's world matrix,
transforms the pointer into image space and checks the image bounds,
testing front-to-back. Alpha-aware hit testing is a P1 refinement.

Why Canvas 2D and not WebGL or a library: a Gacha scene is a few characters
of 20–60 parts each — low hundreds of sprites. Canvas 2D on a mobile GPU
draws that comfortably at 30 fps. A scene-graph library would introduce a
second scene representation that competes with the project document as the
source of truth. If profiling later shows a need, the renderer is one
function behind one interface and can be replaced with a WebGL
implementation without touching `domain/` or `app/`.

---

## 8. Persistence (ADR-005, ADR-007, `project-file-format.md`)

Two persistence paths:

1. **Local autosave** — IndexedDB. Object stores: `projects` (project JSON
   keyed by project ID), `assets` (Blobs keyed by `projectId/assetId`),
   `recent` (ID, name, modified time, thumbnail). The store's autosave
   subscriber writes the project ~1 s after the last command. Asset blobs
   are written once at import. This is an MVP requirement, not a later
   feature: mobile browsers evict background tabs and the user would
   otherwise lose everything since the last manual save.
2. **Portable project file** — `.animproj`, a ZIP containing
   `project.json` and `assets/`. Used for backup, moving between devices
   and sharing.

Both paths carry the same `project.json` with an explicit `formatVersion`.
Loading always runs `migrate()` then `ProjectSchema.parse()`.

Storage limits: browsers grant an origin a large quota (commonly hundreds of
MB or more; Safari is the most conservative). The app requests persistent
storage (`navigator.storage.persist()`) so the OS does not clear it under
pressure, and shows remaining quota in the project list.

---

## 9. Export (ADR-008)

- **Still image**: render the current frame at project resolution to an
  `OffscreenCanvas`, `toBlob`, trigger a download.
- **Video (MP4)**: for each frame 0..duration−1, render to an
  `OffscreenCanvas`, wrap as a `VideoFrame` with the correct timestamp,
  feed a `VideoEncoder` (H.264 `avc1.42001f` or higher-level profile; fall
  back to VP9), mux with `mp4-muxer`, produce a Blob, download. Runs in a
  Web Worker so the UI stays responsive; progress is reported per frame.
- **Fallback (WebM)**: where WebCodecs is unavailable, play the scene into
  `canvas.captureStream()` and record with `MediaRecorder`. Real-time only;
  may drop frames on slow devices. The UI says so.
- **Audio**: not in the MVP. When added (P1), audio is muxed as a second
  track in the same pipeline.

Downloads on tablets: `showSaveFilePicker` is desktop-only, so the export
path uses an anchor download (`<a download>`) which works on Android Chrome
and iOS Safari. The File System Access API is an enhancement where present.

---

## 10. Tablet-first UI constraints

The primary development device is also the primary test device, so the UI
is designed for touch from the start:

- Every handle and control is at least 44 × 44 CSS px.
- Pinch to zoom and two-finger drag to pan the viewport; one finger drags
  the selected object. No behaviour depends on hover.
- Panels stack vertically on narrow screens and sit side-by-side on wide
  ones; a single layout component owns the breakpoints.
- The timeline is horizontally scrollable and pinch-zoomable.
- Pointer Events (not separate mouse/touch handlers) throughout.
- Numeric fields in the inspector accept typed values for precision.

---

## 11. Performance principles

Measure before optimising, but do not build the obvious slow thing:

- Render only when dirty: a store subscription sets a flag; one
  `requestAnimationFrame` draws.
- React components subscribe to slices (`selectScene`, `selectTrack`), not
  the whole project, so a keyframe edit does not re-render the layers panel.
- Decoded `ImageBitmap`s are cached; large imports are downscaled to the
  project resolution at import time (keeping the original file in the
  asset store).
- Video export runs in a worker.
- Playback frame = `floor((now − start) · fps / 1000) mod duration`, so a
  slow device drops frames rather than slowing the animation.

---

## 12. Error handling

Errors are typed values in `domain/` and `infra/` (`ProjectLoadError`,
`UnsupportedVersionError`, `MissingAssetError`, `ExportError`), each with a
user-facing message. `ui/` shows them in a single toast/dialog component.
The renderer draws a placeholder for a missing asset rather than throwing.

---

## 13. Testing strategy

Priority order, matching the risk ordering of the earlier architecture document:

1. `domain/` — transform composition, pivot behaviour, parent/child
   inheritance, keyframe interpolation and easing, `evaluateScene` output,
   schema validation, migrations against fixture files for every past
   format version. Plain Vitest in Node. This is where most tests live.
2. `app/` — each command, plus "dispatch then undo yields the original
   project" property tests over a set of commands.
3. `infra/` — `.animproj` round trip (export then import equals original);
   IndexedDB via `fake-indexeddb` in tests.
4. `render/` — a recording fake `CanvasRenderingContext2D` that captures
   `setTransform`/`drawImage` calls, so draw order and matrices can be
   asserted without a real canvas.
5. `ui/` — a few smoke tests with React Testing Library. End-to-end browser
   tests (Playwright) are a CI-only addition for later; they will not run on
   the tablet.

Numerical assertions use a tolerance (`toBeCloseTo`).

---

## 14. Continuous integration and delivery

GitHub Actions on every push and pull request: `npm ci`, `tsc --noEmit`,
`vitest run`, `vite build`. On `main`, deploy the built `dist/` to static
hosting so the latest app is always available at a URL the tablet can open.
The app is published with GitHub Pages at
`https://azariaduck12.github.io/Animation_App/` (see `dev-environment.md`
§6).

---

## 15. Cross-platform reach

The MVP targets the browsers on the devices Gacha animators use:

- Android: Chrome (primary test target; it is the tablet).
- iOS/iPadOS: Safari 17+.
- ChromeOS, Windows, macOS, Linux: any Chromium browser or Firefox.

The app is installable as a PWA (P1) which gives an icon, full-screen and
offline use. Native store packaging (Trusted Web Activity for Play, Capacitor
for iOS) is possible later without changing the code base, and is out of
scope.

---

## 16. What deliberately stays out of the MVP

Warp/mesh deformers, IK, audio, drawn frames, effects, camera animation,
multi-scene sequencing, poses as a runtime concept, social features. The
data model reserves nothing for them except a versioned format and a
`kind` discriminator on tracks and scene objects (see `data-model.md`),
which is the smallest structure that prevents a painful migration later.

---

## 17. Architectural changes require review

Unchanged from the earlier architecture: an AI agent must not silently change
the layering, the data model, the file format or the dependency list. It
should explain the limitation, propose the change, list affected files and
tests, and wait for approval. Small decisions inside the documented
architecture need no approval.
