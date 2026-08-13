# Animation_App Data Model

## Status

This document defines the conceptual data model for Animation_App.

It describes the major entities in the application and the relationships
between them.

This is a conceptual model rather than a final implementation specification.

Exact programming classes, database structures, serialization formats, and
storage mechanisms may be decided later.

Major changes to the data model should be recorded in `docs/decisions.md`.

---

# 1. Core Model

The core application model is:

```text
Project
│
├── Assets
│
├── Characters
│   └── Character
│       ├── Character Parts
│       └── Rig
│
├── Poses
│
└── Scenes
    └── Scene
            ├── Scene Objects
                    └── Animation / Timeline