# Animation_App Features

## Status

Adopted 2026-08-29 (see `decisions.md`, ADR-001).

A feature being listed here does not mean it is implemented. P0 is the MVP
and is committed; P1 is planned; P2 and beyond are direction, not promises.

---

## Product goal

Animation_App is a 2D cut-out animation and simple video assembly app,
primarily for Gacha animators, usable on the phone or tablet they already
own. See `vision.md`.

---

## P0 — MVP

### Projects

- Create a project with a name, resolution (presets: 1080p landscape,
  1080p portrait/TikTok, 720p; or custom) and frame rate (24 or 30).
- Projects autosave locally; the home screen lists recent projects with
  thumbnails and lets the user open, rename, duplicate or delete them.
- Export a project as a `.animproj` file; import one. This is how a project
  moves between devices.
- Reopen a project after closing the browser and find it exactly as left.

### Assets

- Import PNG, JPEG and WebP images from the device (multiple at once).
  Transparent PNGs keep their transparency.
- See imported assets in an asset list; rename; delete (refused with an
  explanation if the asset is still in use).
- Large images are downscaled on import to keep memory in check; the user
  is told.

### Character mode

- Create a character; add parts from assets.
- Name parts. Set each part's parent by choosing from a list (or by
  dragging in the layer panel). Detach to the character origin.
- Set a part's pivot by dragging a marker on the image, or by typing
  coordinates.
- Position, rotate and scale parts to build the rest pose, with the same
  on-canvas handles used in Scene mode.
- Reorder draw order (back/front) independently of the hierarchy.
- Toggle part visibility.
- Delete a part (children are re-parented to its parent).
- A character can be used in any scene of the project.

### Scene mode

- Create, rename, reorder and delete scenes. Set scene duration in frames
  (shown as seconds too).
- Place character instances and single-image objects. Move, rotate and
  scale them with on-canvas handles; type exact values in the inspector.
- Select by tapping; the topmost object under the finger is chosen.
- Zoom (pinch, buttons) and pan (two-finger drag) the viewport; "fit to
  screen".
- Layers panel: back-to-front order, drag to reorder, visibility and lock
  toggles, expand a character instance to select its parts.
- Set a scene background colour.

### Animation

- Timeline with a playhead; scrub by dragging; tap a frame number to jump.
- Keyframe any property of any selected object or part: x, y, rotation,
  scaleX, scaleY, opacity. Changing a value with recording on creates or
  updates a keyframe at the playhead.
- Keyframes shown as markers per track; drag to move in time; tap to
  select; delete; copy/paste to another frame.
- Easing per keyframe: linear, ease in, ease out, ease in/out, hold.
- Play / pause / loop; playback at project frame rate, dropping frames on
  slow devices rather than slowing down.
- Undo / redo for every edit.

### Export

- Still image (PNG) of the current frame at project resolution.
- Video (MP4, H.264) of a scene at project resolution and frame rate, with
  a progress indicator and cancel. WebM fallback where MP4 encoding is not
  available, with a notice.

### Platform

- Works in Chrome on Android and Safari on iPadOS/iOS, and in desktop
  browsers, from a single URL.
- Touch-first layout; usable on a 10-inch tablet in landscape and, with
  stacked panels, on a phone.

---

## P1 — Important post-MVP

- **Image-swap keyframes** — a track whose value is an asset (mouth shapes,
  eye blinks, expressions). The single most-used technique in Gacha
  animation after basic movement.
- **Poses** — save the current part transforms as a named pose; apply a
  pose at the playhead (creates keyframes).
- **Audio** — import an audio file per scene, show a waveform in the
  timeline, play in sync, mux into the exported video.
- **Multi-scene export** — export all scenes in order as one video (the
  "video editor" half of the product goal).
- **Installable PWA with offline use** — icon on the home screen,
  full-screen, works without a connection.
- **Onion skin** — ghost of the previous/next keyframe on the viewport.
- **Text objects** — simple captions with font, size and colour.
- **Camera** — animate a scene-level zoom/pan/rotation.
- **Image sequence and GIF export**.
- **Alpha-aware selection** — tapping a transparent pixel selects what is
  behind it.
- **Duplicate detection** on asset import.
- **Keyboard shortcuts** for desktop users.

## P2 — Advanced animation

- Mesh warp deformers on parts.
- Inverse kinematics for two-bone chains (arm/leg).
- Draw-order keyframes (an arm passing in front of the body).
- Motion paths and graph editor for easing curves.
- Bone-less "sprite sheet" parts with frame-by-frame swapping.
- Loops and clips: reuse an animation across instances.

## P3 — Rendering and effects

- Blur, glow, drop shadow, colour adjustments per object.
- Scene transitions (cut, fade, slide) in multi-scene export.
- Simple lighting/shadow.
- Blend modes.

## P4 — Drawing and frame-by-frame

- Bitmap brush and eraser to draw parts directly.
- Frame-by-frame drawn layers alongside cut-out layers.
- Onion skinning for drawn frames.

## P5 — Productivity and reuse

- Character library shared across projects (export/import a character).
- Templates (walk cycle, blink, idle).
- Batch export of multiple projects.
- Themes; larger UI scale for phones.

## P6 — Social

- Sharing links, community character library, collaboration.
- These require a backend, accounts and moderation, and are outside the
  scope of the current architecture.

---

## Explicitly not planned

- Vector drawing.
- Video import as a layer (general video editing).
- Cloud sync and accounts (P6 would reopen this).
