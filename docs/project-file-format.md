# Animation_App Project File Format

## Status

Adopted 2026-08-29 (ADR-005, ADR-007). Fulfils the Phase 0 roadmap task
"Define project file format".

This is a persistent user-data format. Changing it is a high-risk change
and requires an ADR and migration tests (see `AGENTS.md`).

---

## 1. Two homes for the same document

| | Local autosave | Portable project file |
| --- | --- | --- |
| Where | IndexedDB in the browser, per device and per origin | A `.animproj` file the user downloads/uploads |
| When written | ~1 s after every command | On "Export project" |
| Purpose | Never lose work; instant reopen | Backup, move between devices, share |
| Contents | `project.json` text + asset Blobs | ZIP of the same |

The document (`project.json`) is byte-for-byte the same in both.

---

## 2. The `.animproj` file

A standard ZIP archive (deflate or store). Extension `.animproj`; MIME
`application/zip`. Layout:

```text
MyCharacterStory.animproj
├── project.json          the Project document (UTF-8, formatVersion inside)
├── assets/
│   ├── 6f1c…a2.png       one file per Asset, at the path in Asset.file
│   └── 9b30…e7.webp
└── thumbnail.png         optional; first frame of the first scene, ≤ 512 px
```

Rules:

- `project.json` must be at the root and must be the first thing the
  importer reads (to check `formatVersion` before touching anything else).
- Asset file names are `<assetId>.<ext>` so a rename in the UI never
  renames a file, and two assets never collide.
- Any other entries are ignored on import (forward compatibility).
- The archive is produced with `fflate` (`zipSync` for small projects,
  streaming `Zip` for large ones) in a worker.

Sharing note: a `.animproj` contains every image in the project. Users
should know that before sending it to someone.

---

## 3. The in-browser store

Database name `animation-app`, version 1. Object stores:

| Store | Key | Value |
| --- | --- | --- |
| `projects` | `projectId` | `project.json` as a string (not a parsed object — keeps writes cheap and the format single-sourced) |
| `assets` | `projectId/assetId` | `Blob` |
| `recent` | `projectId` | `{ id, name, modifiedAt, thumbnail?: Blob }` |

Autosave writes only `projects` and `recent`; asset blobs are written at
import and deleted with the project. On open, the app requests
`navigator.storage.persist()` and reads `navigator.storage.estimate()` to
show the user how much space is left.

Because IndexedDB is per-origin, moving the app to a different URL loses
access to local projects. Users get there through `.animproj` export. The
hosting URL is therefore fixed: `https://azariaduck12.github.io/Animation_App/`.

---

## 4. Versioning and migration

`project.json` always carries `formatVersion` (an integer, currently `1`).

```ts
// src/domain/migrations.ts
export const CURRENT_FORMAT_VERSION = 1;
const migrations: Record<number, (doc: unknown) => unknown> = {
  // 1: (doc) => ({ ...doc, formatVersion: 2, /* … */ }),   // added when v2 exists
};

export function migrate(doc: unknown): unknown {
  let v = readVersion(doc);
  if (v > CURRENT_FORMAT_VERSION) throw new UnsupportedVersionError(v);
  while (v < CURRENT_FORMAT_VERSION) { doc = migrations[v](doc); v = readVersion(doc); }
  return doc;
}
```

Loading is always: parse JSON → `migrate` → `ProjectSchema.parse` →
resolve assets. A document newer than the app produces a clear
"This project was made with a newer version of the app" error rather than a
half-loaded project.

Every format version keeps a fixture in `test/fixtures/format/v<N>/` — a
small but complete `project.json` — and a test that migrating each fixture
to the current version passes schema validation and preserves the things
that must survive (asset references, keyframe values, draw order).

When to bump the version: any change that would make an older app unable
to read a new file *or* a newer app misread an old file. Adding an optional
field with a sensible default does not require a bump if the schema
supplies the default; adding a new `kind` to a union does, because an older
app cannot render it.

---

## 5. Asset handling on import

1. The user picks one or more image files (`<input type="file"
   accept="image/*" multiple>`; on Android this opens the gallery).
2. The bytes are decoded with `createImageBitmap` to read the intrinsic
   size and to verify the image is valid.
3. If the image is larger than twice the project resolution in either
   dimension, a downscaled copy is stored *as the working asset* and the
   size in `Asset` reflects the copy. (Gacha exports are typically
   1000–3000 px tall; a 2 K image per part is far more than a 1080p output
   needs and is the main memory risk on a 3 GB tablet.) The original file
   is not kept in v1; this is documented in the import dialog.
4. `Asset` is created, the Blob written to `assets`, the command
   dispatched.

Duplicate detection (same bytes imported twice) is a P1 refinement and
would add an optional `sha256` field — a non-breaking schema change.

---

## 6. Example `project.json` (v1, minimal)

```json
{
  "formatVersion": 1,
  "id": "0f6d3c2e-4a2b-4c59-9d6e-1b2c3d4e5f60",
  "name": "Wave hello",
  "createdAt": "2026-09-01T09:00:00Z",
  "modifiedAt": "2026-09-01T09:12:30Z",
  "settings": { "width": 1920, "height": 1080, "fps": 24 },
  "assets": {
    "a-body": { "id": "a-body", "name": "body", "kind": "image", "file": "assets/a-body.png", "mime": "image/png", "width": 400, "height": 900 },
    "a-arm":  { "id": "a-arm",  "name": "arm",  "kind": "image", "file": "assets/a-arm.png",  "mime": "image/png", "width": 120, "height": 380 }
  },
  "characters": {
    "c-alex": {
      "id": "c-alex", "name": "Alex",
      "parts": {
        "p-body": { "id": "p-body", "name": "Body", "assetId": "a-body", "parentId": null,
                    "pivot": { "x": 200, "y": 880 },
                    "rest": { "x": 0, "y": 0, "rotation": 0, "scaleX": 1, "scaleY": 1, "opacity": 1 }, "visible": true },
        "p-arm":  { "id": "p-arm",  "name": "Right arm", "assetId": "a-arm", "parentId": "p-body",
                    "pivot": { "x": 60, "y": 30 },
                    "rest": { "x": 330, "y": 250, "rotation": 10, "scaleX": 1, "scaleY": 1, "opacity": 1 }, "visible": true }
      },
      "drawOrder": ["p-arm", "p-body"],
      "poses": {}
    }
  },
  "scenes": {
    "s-1": {
      "id": "s-1", "name": "Scene 1", "durationFrames": 48,
      "objects": {
        "o-alex": { "id": "o-alex", "kind": "character", "name": "Alex", "characterId": "c-alex",
                    "transform": { "x": 960, "y": 1000, "rotation": 0, "scaleX": 1, "scaleY": 1, "opacity": 1 },
                    "visible": true, "locked": false }
      },
      "objectOrder": ["o-alex"],
      "tracks": [
        { "id": "t-1", "kind": "scalar", "target": { "objectId": "o-alex", "partId": "p-arm" }, "property": "rotation",
          "keyframes": [ { "frame": 0, "value": 10, "easing": "easeInOut" }, { "frame": 24, "value": -80, "easing": "easeInOut" }, { "frame": 47, "value": 10, "easing": "linear" } ] }
      ]
    }
  },
  "sceneOrder": ["s-1"]
}
```

(IDs are shortened for readability; real IDs are UUIDs.)
