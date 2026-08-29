# Animation_App Vision

## Status

Adopted 2026-08-29 (see `decisions.md`, ADR-001).

---

## What it is

Animation_App is a 2D cut-out ("puppet") animation editor and simple video
assembler. A user imports flat images (a head, a torso, an arm, a prop),
joins them into a character with pivots and a parent/child hierarchy, poses
the character over time with keyframes, previews the result, and exports a
video or still image.

It runs in a web browser on the device the user already has — a phone, a
tablet, a Chromebook or a PC — and can be installed as an app.

## Who it is for

The primary audience is Gacha animators: people (many of them young) who
build characters in games such as Gacha Club or Gacha Life, export the
character art as transparent PNGs, and animate those images into short
stories for YouTube and TikTok.

Today that workflow usually means a general-purpose mobile video editor
(Alight Motion, CapCut, KineMaster). Those tools are powerful but they do
not understand *characters*: every arm is just another layer, there is no
reusable rig, and animating a walk means re-keyframing a dozen unrelated
layers.

Animation_App should understand characters as first-class things.

The secondary audience is anyone doing image-based 2D animation: stop-motion
assembly, simple puppet animation, animated stickers.

## The core experience

```text
Import images
    ↓
Build a character (parts, pivots, parent/child, draw order)
    ↓
Place characters and props in a scene
    ↓
Animate with keyframes on a timeline
    ↓
Preview
    ↓
Export a video or image
```

Two modes make this concrete, and they mirror the workflow Gacha users
already know ("make the character, then go to the studio"):

- **Character mode** — build and edit a reusable character.
- **Scene mode** — place character instances and props, and animate them.

## Design principles

1. **The device is a phone or a tablet first.** Touch targets, pinch zoom
   and small screens are the default, not an afterthought. Mouse and
   keyboard are supported, not required.
2. **Never lose work.** Mobile browsers discard background tabs. Projects
   autosave locally, continuously.
3. **Characters are reusable.** A character is built once and instanced
   many times. Editing an instance never silently changes the definition.
4. **The project file is the truth.** Every panel is a view of the same
   project document. Preview, playback and export all render from the same
   data with the same renderer.
5. **Runs on low-end hardware.** The app should be usable on a
   several-year-old Android tablet with 3 GB of RAM.
6. **Files belong to the user.** A project can be exported as a single
   portable file, shared, and re-imported on another device with no account.
7. **Small, testable, boring core.** The animation model is plain data and
   pure functions, testable without a browser.

## Long-term direction

Once the core cut-out workflow is solid, the roadmap grows toward what Gacha
animators actually use: audio and lip-sync-style image swapping, expression
swaps, camera moves, multi-scene videos, simple effects, and eventually
drawn frames and mesh deformation. Social and community features are a
distant possibility and would require a backend the project does not
currently have.

## Non-goals (for now)

- Vector drawing tools.
- A general-purpose video editor competing with CapCut.
- Accounts, cloud sync, or any server-side component.
- Native app-store distribution (a PWA is the delivery mechanism).
