# Animation_App — architecture review and web-first proposal

**Date:** 2026-08-29
**Reviewed:** `/docs/*`, `/.cursor/rules/*`, the Flutter scaffold at
`4cf4c5a`, the dev container, and the GitHub repository settings.
**Requested by:** a collaborator, on behalf of the project owner
(`azariaDuck12`).

**Outcome (2026-08-29):** option A adopted by the project owner. The
repository will be made public and hosted on GitHub Pages; the development
tablet is a Lenovo Idea Tab Pro (Android). The proposed documents were
moved into `docs/` and this report is kept as the record of the reasoning.
File references below use the original `docs-proposed/` names.

---

## 1. Summary

The thinking in the current documents is good. The layered architecture,
"UI is not the source of truth", reusable characters versus scene
instances, versioned project files with migrations, and the MVP discipline
are exactly the right principles for an animation editor, and they are
kept unchanged in this proposal.

The problem is not the design; it is the toolchain the design is attached
to, given one fact that the documents do not mention: **most of the
development will be done, with an AI assistant, on a low-specification
tablet, and paying for a remote machine is not wanted.**

Flutter cannot run on a tablet. The Flutter SDK, the Dart analyzer and the
platform SDKs need a desktop-class machine (realistically 8 GB of RAM) and
do not exist for Android or iPadOS as *host* platforms at all. With
Flutter, the developer can never develop standalone on her own device — she
is permanently dependent on a PC or a cloud machine.

Rust would make this worse, not better. Rust's small footprint is a
*runtime* property; its *development* footprint (compile times,
`rust-analyzer` memory, borrow-checker error loops for AI-generated code)
is the heaviest of any option considered.

**Recommendation:** re-platform to a web-first TypeScript application
(Vite + React + Canvas 2D, delivered as a static site / PWA). It is the
only stack whose complete edit → run → test loop runs *on* an Android
tablet in about 1.5 GB of RAM, it also works through free cloud and
home-PC workflows (so it does not depend on which tablet it is), video
export is built into the browser rather than a native dependency, and the
audience — Gacha animators on phones and tablets — is reached with a URL.

This is a materially different direction, so, as requested, this directory
contains a complete replacement set of design documents rather than edits
to `/docs`. Section 5 lists every difference and why.

If the recommendation is rejected, the fallback that keeps Flutter is
described in §4 (option B), and §7 lists fixes to the existing documents
that apply either way.

---

## 2. Review of what exists

### 2.1 Strengths

- **Architecture principles** (`docs/architecture.md` §§1–29): clear
  layering, dependency direction, source-of-truth rule, animation data
  independent of the timeline, same evaluation path for preview and
  export, versioning and migration, undo/redo considered early, MVP
  boundary stated firmly. This is better than most professional projects
  start with. All of it survives into `architecture.md` here.
- **Domain vocabulary**: Asset ≠ Character Part ≠ Scene Object ≠
  Character Instance is the right distinction and is easy to get wrong.
- **AI-agent rules** (`.cursor/rules/03-ai-workflow.mdc`,
  `00-project-constitution.mdc`): thorough, sensible, and clearly written
  by someone who has watched agents make a mess. Kept, condensed into
  `AGENTS.md`.
- **Roadmap discipline**: Phase 0 / Phase 1 with completion criteria.

### 2.2 Gaps

- `docs/features.md` (43 lines) defines the P0–P6 levels but lists no
  features under any of them.
- `docs/data-model.md` (37 lines) is a tree diagram with no entity
  definitions. The roadmap's "Define project data model" and "Define
  project file format" remain open; the architecture leaves state
  management, rendering approach, storage and file format as "to be
  decided". For a vibe-coding workflow this matters: whatever the docs
  leave open, the AI will decide ad hoc, differently each session.
- `docs/decisions.md`, `vision.md`, `glossary.md`, `known-issues.md` are
  referenced by the rules and by `architecture.md` but do not exist.
- No "database structure" exists to review (see §6).
- Video export — a P0 feature — has no identified implementation path. In
  Flutter it needs a native FFmpeg wrapper; the most-used one
  (`ffmpeg_kit_flutter`) was retired by its maintainer in 2025.
- No CI. No `.github/`. The dev container installs Flutter, implying a
  Codespaces intention (which costs core-hours at the 4-core size Flutter
  needs).
- Six platform targets (Android, iOS, Windows, macOS, Linux, web) for an
  MVP built by one person on a tablet. iOS and macOS also require a Mac
  with Xcode to build at all.

### 2.3 Defects (mechanical)

- `.cursor/rules/01-architecture.mdc` ends mid code block at line 35
  (`Domain` with no closing fence). The file is truncated; only the
  frontmatter and layer diagram survive.
- `.cursor/rules/04-testing.mdc` ends mid-sentence at line 147
  (`- Consider`). Truncated.
- `.cursor/rules/05-documentation.mdc` has cumulative indentation: each
  section is indented further than the last, so from §2 onward Markdown
  renders it as one giant code block. Content is intact; formatting is
  corrupt.
- Rule numbering skips `02`. Rules `00`, `03`, `04`, `05` lack the
  frontmatter (`description`, `globs`, `alwaysApply`) that `01` has, so
  Cursor's attachment behaviour for them is undefined.
- `docs/architecture.md` has a stray "## 21. Architectural Changes Require
  Review" after §29, in a different heading style from the rest.
- `docs/roadmap.md` Phase 0 still shows "Set up Flutter development
  environment" and "Create initial application shell" unchecked although
  both were done in commits `4f3aee6` and `4cf4c5a`.
- Cursor rules are the only agent instructions, and Cursor does not run on
  tablets. Any agent used from the tablet (Claude Code in Termux or on the
  web, Copilot in github.dev, Codex) will not see them.

### 2.4 The scaffold

`lib/` contains a `MaterialApp` with a placeholder `EditorPage` and one
widget test. There is no domain code yet, so switching stacks now costs
nothing in written logic; the sunk cost is the platform folders, which are
generated.

---

## 3. The constraint, and the three candidate stacks

### 3.1 What "developing on a tablet" actually needs

A development loop has four parts: edit, build, run, test. On a tablet each
part has to fit in ~3–4 GB of RAM (shared with the browser and the OS),
run on an ARM CPU without a fan, and — ideally — not require anything
outside the device.

| | Flutter / Dart | Rust | TypeScript web |
| --- | --- | --- | --- |
| Toolchain runs on Android (Termux)? | **No** — no host SDK for Android | Yes, but slowly | **Yes** (Vite/esbuild ship arm64 Android binaries) |
| Toolchain runs on iPadOS? | No | No | No (use cloud or PC; only the browser is needed to *run*) |
| Toolchain runs on ChromeOS Linux / Windows tablet? | Yes, ~8 GB RAM wanted | Yes, slow builds | Yes, ~1.5 GB |
| RAM for editor + build + run | 3–6 GB (analyzer 1–2 GB alone) | 2–4 GB (`rust-analyzer` 1–3 GB) | ~1.2–2.3 GB total |
| Disk for toolchain | ~3 GB SDK + platform SDKs | ~1–2 GB + target dir (GBs) | ~350 MB |
| Change → see it | 5–90 s (web build; hot reload on web is newer and slower) | Minutes (recompile) | < 1 s (hot module reload) |
| Running the app *on* the tablet during development | Sideload APK or open web build from PC | Sideload | Open `localhost:5173` in the tablet's browser |
| Unit tests | `flutter test`, ~1 GB, seconds–minutes | `cargo test`, recompile | Vitest in Node, ~300 MB, seconds |
| AI-assistant fluency | Good | Good, but highest compile-error rate per generated change | **Best** — largest corpus, Canvas/React idioms well known |
| Video export path | Native FFmpeg wrapper; main one retired 2025 | FFmpeg bindings or own encoder; platform-specific | **WebCodecs** built into Chrome/Safari/Firefox; hardware encoders |
| Reaching the audience (phones, tablets) | Store apps or a heavy web bundle (CanvasKit ~1.5 MB WASM) | Desktop-oriented GUI crates; weak touch story | A URL; installable PWA; ~200 KB |
| Runtime performance for this workload (hundreds of sprites) | Excellent | Excellent | Fine — `drawImage` is GPU-accelerated native code in every browser |
| Future native packaging | Built in | Manual | Trusted Web Activity (Android) / Capacitor (iOS) without code changes |

### 3.2 Why not Rust

The suggestion to consider Rust comes from a true premise (Rust produces
small, fast programs) applied to the wrong bottleneck. The bottleneck is
the development machine, and Rust is the most expensive language to
*develop* in on a small machine: long compiles, a memory-hungry language
server, and a compiler that rejects a large fraction of first-draft code
— which for an AI-assisted teen developer means a longer fix-the-error
loop rather than a safety benefit. The runtime win is irrelevant for a 2D
sprite editor whose hot path is `drawImage`, which the browser already
executes in native GPU-accelerated code.

Rust keeps a place in the plan: if profiling on the tablet ever shows a
domain hot spot (mesh deformers are the likely candidate, roadmap Phase 3),
that one module can be compiled to WASM behind the same function signature
(ADR-002).

### 3.3 Why not keep Flutter with a remote machine

It works, and it is the fallback (§4 option B). But: the tablet is never
self-sufficient; every session depends on the PC being on or on cloud
hours; each iteration is 30–90 s instead of instant; the Flutter web bundle
starts slowly on the low-end devices the audience uses; six platform
folders remain to maintain; and video export still needs a native
dependency on every platform. The developer would be learning a toolchain
she cannot run on her own device.

---

## 4. Options

**A. Web-first TypeScript (recommended).** Replace the Flutter scaffold
with Vite + React + TypeScript; Canvas 2D renderer; immer-based undo; zod
schema; IndexedDB autosave; `.animproj` ZIP file; WebCodecs MP4 export;
static hosting; PWA. Development on the tablet per `dev-environment.md`
(Termux locally on Android; Claude Code on the web / Codespaces free tier
on iPad; home PC over a free VS Code tunnel from anything).
Cost: $0 recurring.

**B. Keep Flutter; home PC as the build box.** Keep `/docs`, drop the
platform folders to Android + web, run `code tunnel` on the PC and
`flutter run -d web-server` for the tablet to open, sort out video export
separately. Cost: $0 but PC-dependent; slower loop; the tablet is a thin
client forever. Choose this if there is a strong reason to stay in Dart
(for example, prior investment in learning it).

**C. Rust.** Not recommended for the reasons in §3.2.

**D. Flutter in Codespaces.** Works at the 4-core size; burns the free
allowance quickly (4 cores = 30 hours/month of the 120 core-hour
allowance); rejected as the primary path given the cost preference.

Recommendation: **A**, with B as the documented fallback.

---

## 5. Differences from `/docs`, itemised

| Topic | `/docs` (current) | This proposal | Justification |
| --- | --- | --- | --- |
| Language / framework | Flutter, Dart | TypeScript, Vite, React | Only toolchain that runs on the tablet; fastest loop; best AI fluency. ADR-001. |
| Target platforms | Android, iOS, Windows, macOS, Linux, web (6) | Any modern browser; installable PWA | One build; no Mac/Xcode; no store process. Native wrappers possible later. |
| Rendering | Undecided | Hand-written Canvas 2D; one function for viewport/playback/export | Enforces "same path for preview and export"; no second scene graph. ADR-004. |
| State management | Undecided | Single immutable `Project` in a store; React reads via `useSyncExternalStore` | Makes "UI is not the source of truth" mechanical rather than aspirational. |
| Undo/redo | "Should be possible later" | Designed in: immer patches per command | Costs ~50 lines now; retrofitting costs a rewrite. ADR-006. |
| Autosave | "Not an MVP requirement" | MVP requirement; IndexedDB | Mobile browsers evict tabs; manual save on a tablet loses work. ADR-007. |
| Data model | Tree diagram only | Concrete types, invariants, transform semantics | Removes the biggest source of ad-hoc AI decisions. |
| Rig | Separate entity | `parentId` + `pivot` on parts | Nothing else to store in v1. |
| Poses | Project-level, semantics undefined | Per-character presets that write keyframes | One animation mechanism. ADR-009. |
| Layers | Hierarchy and ordering conflated | Draw order arrays separate from hierarchy | A hand can be a child of the arm and drawn behind the body. |
| Time | Unspecified | Integer frames + project fps | No float drift; exact export. ADR-010. |
| File format | "To be defined" | `.animproj` ZIP: `project.json` + `assets/`; `formatVersion`; migration chain with fixtures | Roadmap task closed; user data protected from day one. |
| Storage / database | "May be decided later" | No database; document in IndexedDB key-value stores | See §6. ADR-005. |
| Video export | Unspecified | WebCodecs + `mp4-muxer` in a worker; MediaRecorder fallback | Built into the browser; no native binary. ADR-008. |
| Dependencies | Principle only | Named list of 7 runtime deps; anything else needs an ADR | Turns the principle into something an agent can check. |
| Testing | Priority list | Same priorities, plus concrete mechanisms (Node-only domain tests, fake canvas, format fixtures) | Testable on the tablet; enforces layer rules cheaply. |
| Agent rules | Cursor-only `.mdc` files (two truncated, one corrupt) | Root `AGENTS.md` + `CLAUDE.md`; Cursor files kept as long form | Agents used from a tablet are not Cursor. |
| Dev environment | Dev container installing Flutter | `dev-environment.md`: three free workflows with RAM budgets; Node dev container | The actual constraint, documented. |
| CI / hosting | None | GitHub Actions; free static hosting; note on private-repo Pages | "Establish CI" was an open Phase 0 task. |
| Roadmap order | Feature-area order | Re-sequenced: domain → store+autosave → render → … with tablet milestones | Something visible early; nothing lost once editing begins. |
| Features | P0–P6 headings, empty | Filled in, Gacha-specific (image-swap keyframes at P1) | The audience's most-used technique was missing. |
| Vision, glossary, decisions | Missing | Written | Referenced by the rules; needed by agents. |

Everything not in this table — the layer model, dependency direction,
definitions vs instances, animation independent of the timeline, MVP
boundary, "measure before optimising", "architectural changes require
review" — is unchanged in substance.

---

## 6. "Database structure"

There is no database structure to review, and the proposal's position is
that there should not be one.

An animation project is a tree of a few thousand small objects that is
always loaded, edited and saved as a unit; the app never runs a query
across projects. A relational schema (tables for parts, tracks, keyframes
with foreign keys) would add an ORM or SQL layer, join logic, and schema
migrations on top of format migrations, for no query the app makes. It
would also fight undo/redo and file export, both of which want one
immutable value.

What the proposal does instead (`data-model.md`, `project-file-format.md`):

- **One JSON document**, with collections as ID-keyed records plus explicit
  order arrays. This is the "normalised" shape that makes lookups O(1),
  keeps references stable for undo patches, and lets reordering be a
  one-array change.
- **Referential invariants** (every ID resolves; no hierarchy cycles;
  each ID exactly once in an order array; sorted unique keyframes)
  enforced by a zod schema with `superRefine` and by the command layer.
- **IndexedDB as a key-value store** with three object stores
  (`projects`, `assets`, `recent`). Not a query engine; a place to put
  strings and blobs that survives a page reload.
- **Explicit `formatVersion` and a migration chain** with a fixture per
  version — the part of "database design" that actually matters for user
  data.

If a future feature (P5 character library across projects, P6 social)
needs cross-project queries, that is the point to add an index or a
database — with an ADR.

---

## 7. Fixes worth applying regardless of the decision

These are direction-independent and mechanical:

1. Repair `.cursor/rules/05-documentation.mdc` — de-indent so headings and
   lists render (the content is intact).
2. Restore or rewrite the truncated tails of `01-architecture.mdc` (ends at
   line 35) and `04-testing.mdc` (ends at line 147).
3. Add frontmatter to rules `00`, `03`, `04`, `05` (`alwaysApply: true` for
   the constitution and workflow at least), or document why not.
4. Add a root `AGENTS.md` (the draft here) and `CLAUDE.md` (`@AGENTS.md`)
   so non-Cursor agents see the rules.
5. Create `docs/decisions.md` (ADR-000 records the Flutter decision so it
   is not lost even if superseded).
6. Fix the stray §21 at the end of `docs/architecture.md`.
7. Tick the completed Phase 0 items in `docs/roadmap.md`.
8. Add CI so `main` is always known to build and test.

If the proposal is rejected I can open these as one small pull request
against `/docs` and `/.cursor/rules`.

---

## 8. Assumptions and open questions

- **Which tablet?** Not recorded anywhere. The recommendation holds for
  Android, iPadOS, ChromeOS and Windows tablets, but *which* development
  workflow to set up first depends on it (`dev-environment.md` §1). On an
  iPad, no stack can be developed locally; the web stack is still the
  best because only the browser is needed to run and test.
- **Public or private repository?** GitHub Pages on the Free plan requires
  a public repository. Cloudflare Pages / Netlify free tiers deploy from
  private ones. The owner's decision; the docs describe both.
- **Which AI assistant on the tablet?** The rules are written for any.
  Claude Code runs in Termux (Node) and on the web; Codex and Copilot have
  web/CLI forms too.
- **Audio** is not in the current P0 and is not in this P0 either, but it
  is the most likely "wait, we need…" request from a Gacha animator, so it
  is first in P1 after image-swap keyframes.
- The Flutter toolchain was not run during this review (it is not
  installed on this PC); the comparison figures are typical values, not
  measurements on the target tablet. The Phase 0 milestone "Hello, canvas
  on the tablet" exists precisely to measure the real thing before
  committing further.

---

## 9. Suggested next steps

1. Decide A or B (§4). Record it in `decisions.md`.
2. Record the tablet model and OS in `dev-environment.md`.
3. If A: follow Phase 0 of `roadmap.md`. The first milestone — an imported
   image drawn on a canvas, served from the tablet or opened on it — should
   take an afternoon and will tell you whether this workflow feels right
   *before* any real code exists.
4. Either way, apply §7.
