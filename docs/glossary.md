# Animation_App Glossary

## Status

Adopted 2026-08-29 (see `decisions.md`, ADR-001).

Terms are listed alphabetically. Use these words consistently in code,
documentation and the user interface. Where the UI should use a friendlier
word, that is noted.

---

**Asset** — An imported image file (PNG, JPEG or WebP) stored with the
project. Assets are referenced by ID; the same asset may be used by several
parts or objects.

**Autosave** — Automatic, continuous saving of the open project to the
browser's local storage (IndexedDB). Distinct from *Export project file*.

**Character** — A reusable definition made of parts, a rig (hierarchy and
pivots) and a draw order. Built in Character mode. In the UI this may be
called a *model* or, for Gacha users, an *OC*; in code it is always
`Character`.

**Character instance** — A placement of a character in a scene. It has its
own transform and its own animation; it never modifies the character
definition.

**Character mode** — The editing mode for building a character.

**Child** — A part whose transform is relative to another part (its parent).
Moving the parent moves the child.

**Draw order** — The back-to-front order in which parts of a character (or
objects in a scene) are painted. Independent of the parent/child hierarchy.

**Easing** — The curve that governs how a value changes between one
keyframe and the next (linear, ease-in, ease-out, ease-in-out, hold).

**Export** — Producing an output the user takes away: a still image (PNG),
a video (MP4 or WebM), or a portable project file (`.animproj`).

**Frame** — The unit of time on the timeline: an integer. Seconds are
derived from frames using the project's frames-per-second setting.

**FPS** — Frames per second. A project setting (typically 24 or 30).

**Hierarchy** — The parent/child tree of parts within a character.

**Keyframe** — A recorded value for one property at one frame. The
animation system interpolates between keyframes.

**Local storage** — Loosely, the browser's IndexedDB store where autosaved
projects and their assets live on the device.

**Object** — see *Scene object*.

**Parent** — A part that other parts are attached to. See *Child*.

**Part** — One image within a character, with a pivot, a parent, a rest
transform and a position in the draw order.

**Pivot** — The point of an image, in that image's own pixel coordinates,
around which it rotates and scales, and which is placed at the part's
position in its parent's space.

**Playhead** — The current frame shown in the viewport and marked on the
timeline. Transient editor state, not saved in the project.

**Pose** — A named snapshot of the transforms of a character's parts.
Applying a pose at a frame creates keyframes; poses are presets, not a
runtime concept.

**Project** — The top-level document: settings, assets, characters and
scenes. Saved locally and exportable as a `.animproj` file.

**Project file** — A `.animproj` file: a ZIP containing `project.json` and
the asset files.

**Property** — An animatable scalar on a target: `x`, `y`, `rotation`,
`scaleX`, `scaleY`, `opacity`.

**Renderer** — The code that draws a scene at a given frame onto a canvas.
The same renderer is used for the viewport, playback and export.

**Rest transform** — A part's default transform inside its character, as
set in Character mode. Animation tracks override it per property.

**Rig** — The hierarchy plus pivots of a character. In this project "rig"
is a description, not a separate entity: it is the `parentId` and `pivot`
fields on parts.

**Scene** — A composition with a duration, containing scene objects and
their animation.

**Scene mode** — The editing mode for composing and animating a scene.

**Scene object** — Anything placed in a scene: an image object (a single
asset) or a character instance.

**Timeline** — The UI that shows frames along the horizontal axis and
tracks/keyframes along the vertical axis. It edits animation data; it does
not own it.

**Track** — The list of keyframes for one property on one target.

**Transform** — Position (`x`, `y`), rotation (degrees), scale (`scaleX`,
`scaleY`) and opacity of a part or object.

**Viewport** — The canvas area of the editor that shows the scene or
character at the current frame.
