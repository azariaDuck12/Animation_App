# Animation_App Data Model

## Status

Adopted 2026-08-29 (ADR-001, ADR-005).

The types below are written in TypeScript because that is the
implementation language, but the model itself is language-neutral: it is a
JSON document. The authoritative runtime definition will be the `zod`
schema in `src/domain/schema.ts`; this document must be kept in step with
it.

There is no database. The project is a single document (ADR-005).

---

## 1. Overview

```text
Project
├── settings            width, height, fps
├── assets              Record<AssetId, Asset>
├── characters          Record<CharacterId, Character>
│   └── Character
│       ├── parts       Record<PartId, CharacterPart>   (hierarchy via parentId)
│       ├── drawOrder   PartId[]                        (back → front)
│       └── poses       Record<PoseId, Pose>
├── scenes              Record<SceneId, Scene>
│   └── Scene
│       ├── objects     Record<ObjectId, SceneObject>   (image | character)
│       ├── objectOrder ObjectId[]                      (back → front)
│       └── tracks      Track[]                          (animation)
└── sceneOrder          SceneId[]
```

Three modelling rules apply throughout:

1. **Collections are records keyed by ID, with a separate order array**
   where order matters. IDs give O(1) lookup, stable references for undo
   patches and selection, and let two things be reordered without
   rewriting every entry.
2. **Hierarchy and draw order are separate.** A hand is a *child* of the
   arm (moves with it) but may be drawn *behind* the body. Professional
   cut-out tools (Spine, Moho) separate these too.
3. **Definitions and instances are separate.** A `Character` is a reusable
   definition; a `CharacterInstance` is its placement in a scene. Editing
   an instance never writes to the character.

---

## 2. Identifiers, units and conventions

```ts
type Id = string;             // crypto.randomUUID(); never an array index
type AssetId = Id; type CharacterId = Id; type PartId = Id;
type PoseId = Id;  type SceneId = Id;     type ObjectId = Id; type TrackId = Id;
```

- **Coordinates**: scene pixels, origin top-left, *y increases downward*
  (Canvas convention). Rotation in degrees; positive is clockwise on
  screen because y points down.
- **Time**: integer frames. `fps` lives in project settings. Seconds are
  derived, never stored.
- **Pivot**: a point in the image's own pixel coordinates (0..width,
  0..height).
- **Timestamps**: ISO-8601 strings in UTC.

---

## 3. Project

```ts
interface Project {
  formatVersion: 1;
  id: Id;
  name: string;
  createdAt: string;
  modifiedAt: string;
  settings: { width: number; height: number; fps: number };
  assets: Record<AssetId, Asset>;
  characters: Record<CharacterId, Character>;
  scenes: Record<SceneId, Scene>;
  sceneOrder: SceneId[];
}
```

`settings.width/height` is the output resolution and the size of every
scene's canvas. Per-scene resolution is not supported; keeping it at the
project level keeps export simple.

---

## 4. Asset

```ts
interface Asset {
  id: AssetId;
  name: string;               // user-visible, editable
  kind: 'image';              // discriminator; only 'image' in v1
  file: string;               // path inside the project file, e.g. "assets/<id>.png"
  mime: 'image/png' | 'image/jpeg' | 'image/webp';
  width: number;              // intrinsic pixel size
  height: number;
}
```

The image bytes are not in the document. In the browser they are a Blob in
IndexedDB keyed by `projectId/assetId`; in a `.animproj` file they are the
entry at `file`. Deleting an asset that is still referenced is refused by
the command layer.

---

## 5. Character and parts

```ts
interface Character {
  id: CharacterId;
  name: string;
  parts: Record<PartId, CharacterPart>;
  drawOrder: PartId[];        // every part exactly once, back → front
  poses: Record<PoseId, Pose>;
}

interface CharacterPart {
  id: PartId;
  name: string;
  assetId: AssetId;
  parentId: PartId | null;    // null = attached directly to the character origin
  pivot: Point;               // in the asset's pixel coordinates
  rest: Transform;            // default transform in Character mode
  visible: boolean;
}

interface Point { x: number; y: number }

interface Transform {
  x: number; y: number;       // position of this thing's pivot in the parent's space
  rotation: number;           // degrees
  scaleX: number; scaleY: number;
  opacity: number;            // 0..1
}
```

The "rig" of the earlier documents is not a separate entity: it is
`parentId` and `pivot` on each part. The hierarchy must be a forest (no
cycles); the command layer refuses a `parentId` change that would create
one.

**Character space**: the space in which root parts (`parentId === null`)
are positioned. Its origin is the character's anchor — the point a
`CharacterInstance` places and rotates around. Conventionally the
character is built so that the origin is between the feet.

### Pose

```ts
interface Pose {
  id: PoseId;
  name: string;
  parts: Record<PartId, Partial<Transform>>;
}
```

A pose is a preset. "Apply pose at frame N" writes keyframes; the renderer
never reads poses (ADR-009). Poses are P1 but the type is included so the
v1 format does not need a migration to add them.

---

## 6. Scene, scene objects and animation

```ts
interface Scene {
  id: SceneId;
  name: string;
  durationFrames: number;     // ≥ 1
  objects: Record<ObjectId, SceneObject>;
  objectOrder: ObjectId[];    // every object exactly once, back → front
  tracks: Track[];
}

type SceneObject = ImageObject | CharacterInstance;

interface ImageObject {
  id: ObjectId; kind: 'image';
  name: string;
  assetId: AssetId;
  pivot: Point;               // asset pixel coordinates
  transform: Transform;       // pivot → scene space
  visible: boolean;
  locked: boolean;            // editor convenience; not visible in output
}

interface CharacterInstance {
  id: ObjectId; kind: 'character';
  name: string;
  characterId: CharacterId;
  transform: Transform;       // character origin → scene space (no pivot field)
  visible: boolean;
  locked: boolean;
}
```

An instance carries no per-part overrides of its own. Everything that
differs from the character's rest pose in a particular scene is expressed
as animation tracks targeting that instance (a static override is simply a
track with one keyframe). This keeps one mechanism, not two.

### Tracks and keyframes

```ts
type Track = ScalarTrack;     // discriminated union; only one kind in v1

interface ScalarTrack {
  id: TrackId; kind: 'scalar';
  target: { objectId: ObjectId; partId?: PartId };   // partId only for character instances
  property: 'x' | 'y' | 'rotation' | 'scaleX' | 'scaleY' | 'opacity';
  keyframes: Keyframe[];      // sorted by frame, unique frames
}

interface Keyframe {
  frame: number;              // integer, 0 ≤ frame < durationFrames
  value: number;
  easing: 'linear' | 'easeIn' | 'easeOut' | 'easeInOut' | 'hold';  // curve to the NEXT keyframe
}
```

There is at most one track per (target, property). Tracks with zero
keyframes are removed by the command layer.

`kind` exists so that later track kinds can be added additively — the
first will almost certainly be a `SwapTrack` (`property: 'assetId'`, string
values, hold easing only) for the expression/mouth swapping that Gacha
animation relies on (P1). Adding it is a new union member and a
`formatVersion` bump, not a redesign.

---

## 7. Transform semantics

For any part or image object with pivot `p`, transform `T = {x, y, rotation
θ, scaleX sx, scaleY sy}`:

```text
local = Translate(x, y) · Rotate(θ) · Scale(sx, sy) · Translate(−p.x, −p.y)
world = parentWorld · local
```

Read right-to-left: move the pivot to the origin, scale, rotate, then place
the pivot at `(x, y)` in the parent's space. The image is drawn at `(0, 0)`
in its own space, so the pivot lands exactly at `(x, y)` of the parent.

**Parent space** is the parent part's *image pixel space* — so a child's
`(x, y)` is literally "which pixel of the parent image the child's pivot is
attached to". For root parts, the parent space is character space. For a
`CharacterInstance`, `local` has no pivot term (the character origin is the
pivot) and its parent space is scene space.

Consequences worth testing:

- Rotating a parent rotates its children about the parent's pivot.
- Scaling a parent by `scaleX = −1` mirrors the children (useful for
  flipping a character).
- Changing a part's pivot in Character mode does not move the image
  on screen if `(x, y)` is adjusted by the same amount — the "set pivot"
  command does this.
- Opacity multiplies down the hierarchy: `worldOpacity = parentOpacity ×
  opacity`.

---

## 8. Evaluated scene (not persisted)

`evaluateScene(project, sceneId, frame)` returns a plain list; it is the
boundary between the model and the renderer.

```ts
interface DrawItem {
  objectId: ObjectId; partId?: PartId;
  assetId: AssetId;
  world: Matrix;              // [a, b, c, d, e, f]
  opacity: number;
  width: number; height: number;
}
type EvaluatedScene = DrawItem[]; // back → front
```

Order: scene `objectOrder`; within a character instance, the character's
`drawOrder`. Invisible objects/parts are omitted.

---

## 9. Editor state (not persisted)

```ts
interface EditorState {
  mode: 'scene' | 'character';
  sceneId: SceneId | null;    // scene mode
  characterId: CharacterId | null;   // character mode
  frame: number;              // playhead
  playing: boolean; loop: boolean;
  selection: { objectId?: ObjectId; partId?: PartId } | null;
  view: { zoom: number; panX: number; panY: number };
  tool: 'select' | 'pivot' | 'pan';
}
```

Kept in `app/`, never written to `project.json`.

---

## 10. Invariants

The schema and command layer enforce:

1. Every `assetId`, `characterId`, `parentId`, `objectId`, `partId` refers
   to an existing entity.
2. `drawOrder` and `objectOrder` contain each ID exactly once.
3. The part hierarchy has no cycles.
4. Keyframes within a track are sorted by `frame` and unique; `frame` is
   an integer within the scene duration.
5. `scaleX`, `scaleY` are non-zero; `opacity` is within 0..1;
   `settings.width/height/fps` are positive integers.

`ProjectSchema.parse` (zod, with `superRefine` for the referential rules)
runs on every load. A `.animproj` that fails validation is reported, not
silently repaired.

---

## 11. Relationship to the earlier (Flutter-era) data model

The entity names of the earlier documents (see `archive/`) are kept: Project, Asset, Character, Character Part, Rig, Pose, Scene, Scene
Object, Character Instance, Transform, Animation Track, Keyframe. The
differences are all in the direction of fewer moving parts:

| Earlier documents | Adopted model | Why |
| --- | --- | --- |
| Rig as its own entity | `parentId` + `pivot` on parts | Nothing else to store in v1. |
| Poses at project level | Poses inside their character | A pose only makes sense for one character's parts. |
| "Animation" owned by scene objects | `tracks[]` on the scene, targeting objects | One timeline per scene; tracks can be listed, sorted and edited together. |
| Layers with hierarchy and ordering | Draw order arrays separate from hierarchy | See rule 2 in §1. |
| Storage "to be decided" | JSON document; no database | ADR-005. |
