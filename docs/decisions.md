# Animation_App Architecture Decision Records

## Status

Active. ADR-000 is superseded; ADR-001 to ADR-010 were accepted by the
project owner on 2026-08-29.

Each record: decision, date/stage, reasoning, alternatives, consequences.
Status is one of *Proposed*, *Accepted*, *Superseded*.

The earlier, implicit decision to use Flutter (roadmap Phase 0, "Choose
Flutter as the application foundation", 2026-08) is recorded as ADR-000 so
that it is not silently erased.

---

## ADR-000 — Flutter as the application foundation (superseded)

**Status:** Accepted 2026-08 (implicitly, via the roadmap); superseded by
ADR-001 on 2026-08-29.

**Decision:** Build the app in Flutter/Dart targeting Android, iOS,
Windows, macOS, Linux and web.

**Reasoning (as inferred from `/docs`):** one code base for every platform,
a strong canvas API (`CustomPainter`), a simple language, good AI-tool
support.

**Consequences:** the Flutter toolchain (Flutter SDK + Dart analyzer +
platform SDKs) needs a desktop-class machine. It cannot run on Android or
iPadOS and is slow with under ~8 GB of RAM. Cross-platform video export
needs a native FFmpeg dependency. See `reviews/2026-08-29-architecture-review.md` §3.

---

## ADR-001 — Web-first TypeScript application

**Status:** Accepted 2026-08-29.

**Decision:** Implement Animation_App as a TypeScript single-page web
application built with Vite and React, rendered on HTML Canvas 2D,
delivered as a static site and installable PWA.

**Reasoning:**

1. The bulk of development will happen on a low-specification tablet
   without a paid remote machine. TypeScript + Vite is the only candidate
   stack whose complete toolchain runs on an Android tablet (in Termux)
   within ~1.5 GB of RAM, and whose app can be previewed in the same
   device's browser. Cloud and home-PC workflows also work with it, so
   the choice does not depend on which tablet it is (`dev-environment.md`).
2. The audience is on phones and tablets; a URL reaches them with no store,
   no install size, no review process.
3. Video export is native to the platform (WebCodecs) rather than an
   external binary dependency.
4. AI coding assistants are strongest in TypeScript/React/Canvas, which
   matters for a vibe-coding workflow: fewer wrong guesses, better error
   explanations.
5. Fast feedback: hot reload is sub-second; tests run in Node in seconds.

**Alternatives considered:**

- *Keep Flutter, use the home PC as the build machine over a free VS Code
  tunnel* — viable and free, but the tablet can never work standalone, the
  PC must be on, rebuilds are slow, and Flutter web bundles start slowly on
  low-end devices. Was the documented fallback
  (`reviews/2026-08-29-architecture-review.md` §4, option B).
- *Rust* — see ADR-002.
- *Flutter web only* — removes the platform SDKs but keeps the Dart
  toolchain weight and the video-export problem.

**Consequences:** the Flutter scaffold is removed; all six platform folders
go; the docs in `/docs` are replaced. Native platform features (file system
access on iOS, background processing) are limited to what browsers allow.

---

## ADR-002 — No Rust for the MVP

**Status:** Accepted 2026-08-29.

**Decision:** Do not use Rust for the application. Reserve Rust → WASM for
a specific, measured hot path later (most likely mesh deformation, P2).

**Reasoning:** Rust's advantage is a small, fast *runtime*. The constraint
here is a small *development* machine, and Rust is the heaviest option to
develop with: `rust-analyzer` uses 1–3 GB, first builds of a GUI crate
take many minutes on a laptop and far longer on a tablet, and the
borrow-checker feedback loop is the most punishing for AI-generated code.
For a 2D sprite editor, the runtime work is `drawImage`, which the browser
already performs in native, GPU-accelerated code; a Rust renderer would not
be meaningfully faster on the tablet.

**Alternatives:** Rust + egui/Slint (weak touch UI story, heavy builds);
Tauri (still a web front end, plus a Rust build); Rust core + WASM from day
one (double toolchain for no MVP benefit).

**Consequences:** if profiling on the tablet ever shows `domain/`
evaluation or a deformer to be the bottleneck, that module can be ported to
WASM behind the same function signature.

---

## ADR-003 — React for panels; canvas driven imperatively

**Status:** Accepted 2026-08-29.

**Decision:** Use React for the editor's panels and dialogs. Drive the
viewport and overlay canvases imperatively from the store, outside React's
render cycle.

**Reasoning:** the editor has enough UI (layers, timeline, inspector,
dialogs, home screen) that a component framework pays for itself, and
React is the framework AI assistants get right most often. Canvas drawing
in React's render path would make every frame a React render.

**Alternatives:** Preact (a drop-in later if bundle size matters); Svelte
or Solid (smaller, less AI fluency); vanilla DOM (more code for the
panels).

**Consequences:** one dependency pair (`react`, `react-dom`). Components
read the store through `useSyncExternalStore` with selectors.

---

## ADR-004 — Hand-written Canvas 2D renderer, no scene-graph library

**Status:** Accepted 2026-08-29.

**Decision:** Write the renderer as one pure function over an evaluated
scene. Do not adopt PixiJS, Konva, Fabric or similar.

**Reasoning:** a scene-graph library keeps its own tree of display objects,
which becomes a second source of truth that must be synchronised with the
project document — exactly what the architecture forbids. The rendering
need (transform + drawImage for low hundreds of sprites) is small. One
function is easier to keep identical between viewport and export.

**Alternatives:** Konva (excellent built-in transform handles; would be
acceptable for the *overlay* only if hand-written handles prove painful —
revisit with an ADR); PixiJS (WebGL; only needed for thousands of sprites
or shader effects).

**Consequences:** transform handles and hit testing are written by hand
(~300 lines). WebGL remains possible behind the same interface.

---

## ADR-005 — The project is a JSON document; there is no database

**Status:** Accepted 2026-08-29.

**Decision:** Model the project as one JSON document with ID-keyed
collections and explicit order arrays; persist it whole. Use IndexedDB as
a key–value store for autosave and asset blobs, not as a relational store.

**Reasoning:** the data is a tree of a few thousand small objects at most;
it is always loaded and saved as a unit; undo/redo and file export both
want a single immutable value. A relational schema (tables for parts,
keyframes, tracks with foreign keys) would add joins, migrations and an ORM
for no query the app ever makes. SQLite-in-WASM would add ~1 MB and a
worker for the same result.

**Alternatives:** SQLite via `sql.js`/`wa-sqlite`; Dexie with normalised
tables; a document store such as PouchDB (sync features not needed).

**Consequences:** projects with tens of thousands of keyframes would make
autosave writes larger; measure before worrying. Cross-project sharing of
characters is by export/import, not by reference.

---

## ADR-006 — Commands as immer recipes with patch-based undo

**Status:** Accepted 2026-08-29.

**Decision:** Every edit is `dispatch(name, draft => …)`. `immer` produces
forward and inverse patches; the undo stack stores patches.

**Reasoning:** undo/redo for every command with no per-command inverse
logic; commands are readable mutations; history is small (patches, not
snapshots). The earlier architecture document (§20) asked for exactly this
property.

**Alternatives:** explicit `Command` classes with `undo()` (more code, more
bugs); snapshot-per-edit (memory heavy); event sourcing (overkill).

**Consequences:** one dependency (`immer`). Gestures use a transient path
and commit once.

---

## ADR-007 — Local autosave to IndexedDB is an MVP requirement

**Status:** Accepted 2026-08-29.

**Decision:** Autosave continuously to IndexedDB from the first editing
milestone. Portable `.animproj` export is separate.

**Reasoning:** mobile browsers discard background tabs without warning; a
manual-save model on a tablet loses work routinely. Autosave costs about
50 lines with the store design above. The earlier architecture document
(§21) deferred autosave; on this platform that would be a mistake.

**Consequences:** the app requests persistent storage; the home screen
shows quota; IndexedDB is per-origin, so the hosting URL should be stable.

---

## ADR-008 — Client-side MP4 export with WebCodecs

**Status:** Accepted 2026-08-29.

**Decision:** Export video by rendering frames to an `OffscreenCanvas`,
encoding with `VideoEncoder`, muxing with `mp4-muxer`, in a worker.
Fall back to `MediaRecorder` (WebM, real-time) where WebCodecs is missing.

**Reasoning:** no server, no FFmpeg binary, hardware encoders on most
tablets, frame-accurate output (unlike `MediaRecorder`). WebCodecs is
available in Chrome/Edge (94+), Safari (16.4+) and recent Firefox.

**Alternatives:** `ffmpeg.wasm` (~30 MB download, slow on low-end
devices); server-side rendering (needs a backend, not preferred).

**Consequences:** two export paths to test; codec availability varies by
device, so the exporter probes `VideoEncoder.isConfigSupported` and picks
H.264 → VP9 → WebM fallback.

---

## ADR-009 — Poses are presets, not a runtime concept

**Status:** Accepted 2026-08-29.

**Decision:** A pose is a saved set of part transforms. Applying it writes
keyframes at the playhead. The renderer never reads poses; instances do not
reference poses.

**Reasoning:** one animation mechanism (tracks) instead of two (tracks plus
pose references with blending rules). Matches how animators use poses in
practice ("snap to this, then tweak").

**Consequences:** poses live inside their character. Pose blending, if ever
wanted, is a P2+ feature with its own ADR.

---

## ADR-010 — Time is integer frames

**Status:** Accepted 2026-08-29.

**Decision:** Keyframes, durations and the playhead are integers in frames;
`fps` is a project setting.

**Reasoning:** no floating-point drift, exact equality for "is there a
keyframe here", trivial export (frame N is frame N). Every cut-out tool the
audience knows works in frames.

**Alternatives:** milliseconds (needs rounding at export); seconds as
floats (drift).

**Consequences:** changing a project's fps re-times the animation (frame 24
stays frame 24). A "retime to new fps" command can be added later if asked
for.
