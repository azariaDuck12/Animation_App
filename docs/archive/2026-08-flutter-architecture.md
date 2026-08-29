Animation_App Architecture

Status

This document defines the technical architecture for Animation_App.

It establishes the boundaries between the user interface, application logic,
domain model, and infrastructure.

The architecture is intended to support the MVP while allowing the application
to grow into the larger feature set described in "docs/features.md".

The architecture should not be interpreted as a requirement to implement
future features early.

---

1. Architecture Goals

The architecture should:

1. Keep the core animation and project model independent from Flutter UI.
2. Keep UI components from becoming the source of truth for project data.
3. Support project saving and loading.
4. Support versioned project formats and future migrations.
5. Make animation logic independently testable.
6. Separate rendering from persistent project data.
7. Support multiple platforms.
8. Allow future features without requiring unnecessary rewrites.
9. Avoid unnecessary dependencies and abstractions.
10. Keep the MVP implementation as simple as reasonably possible.

---

2. Architectural Overview

The application is organised into four conceptual layers:

┌─────────────────────────────────────────┐
│              Presentation               │
│                                         │
│ Canvas • Timeline • Layers • Inspector  │
│ Project screens • Controls • Navigation │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│              Application                │
│                                         │
│ Editing • Project operations            │
│ Animation playback • Commands           │
│ Export orchestration                    │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│                 Domain                  │
│                                         │
│ Project • Scene • Character • Rig       │
│ Asset • Pose • Animation • Keyframe     │
│ Transform • Other core concepts         │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│             Infrastructure              │
│                                         │
│ File storage • Asset loading            │
│ Rendering • Export • Platform services  │
└─────────────────────────────────────────┘

The exact Dart package/file organisation may evolve, but these conceptual
boundaries should remain clear.

---

3. Presentation Layer

The presentation layer contains Flutter UI.

Examples include:

- Project screens
- Editor screen
- Canvas UI
- Timeline UI
- Layer panel
- Inspector
- Buttons and controls
- Navigation
- Dialogs
- Touch and mouse interaction

The presentation layer is responsible for:

- Displaying application state
- Collecting user input
- Requesting application operations
- Presenting errors and feedback

The presentation layer must not contain core project or animation business
logic.

---

4. Application Layer

The application layer coordinates user-facing operations.

Examples include:

- Creating a project
- Opening a project
- Saving a project
- Adding an asset
- Creating a character
- Editing transforms
- Creating keyframes
- Playing an animation
- Exporting a scene

The application layer may coordinate domain objects and infrastructure
services.

It should not contain unnecessary UI-specific implementation details.

---

5. Domain Layer

The domain layer contains the core concepts and rules of Animation_App.

Examples include:

- Project
- Scene
- Asset
- SceneObject
- Character
- CharacterPart
- CharacterInstance
- Rig
- Pose
- Transform
- Animation
- AnimationTrack
- Keyframe

The domain layer should be independent from Flutter widgets.

The animation system should be usable in automated tests without requiring
the Flutter UI to be rendered.

---

6. Infrastructure Layer

The infrastructure layer handles external systems and implementation
details.

Potential responsibilities include:

- Project file storage
- Asset file storage
- Image loading
- Image import
- Rendering backends
- Video export
- Platform-specific services
- File-system access
- Other external integrations

Infrastructure implementations should be replaceable where practical.

---

7. Dependency Direction

Dependencies should generally point toward the more stable/core parts of the
application.

Conceptually:

Presentation
     ↓
Application
     ↓
Domain

Infrastructure provides implementations for services required by the
application or domain without forcing the domain to depend on infrastructure
details.

The domain should not depend directly on Flutter widgets, screen classes, or
platform-specific APIs.

---

8. UI Is Not the Source of Truth

The persistent project model is the source of truth.

For example:

                 Project Data
                     ↑
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
     Canvas       Timeline      Inspector
        UI            UI            UI

The UI displays and edits project state.

It must not maintain a separate hidden version of:

- The project
- The scene hierarchy
- The character hierarchy
- Animation data
- Keyframes
- Asset relationships

This principle is especially important because multiple UI surfaces may edit
the same underlying data.

---

9. Domain Model

The conceptual domain model is defined in:

"docs/data-model.md"

The architecture should follow the distinctions defined there.

Important distinctions include:

Asset
  ≠
Character Part
  ≠
Scene Object
  ≠
Character Instance

Reusable definitions should be separated from scene-specific instances.

---

10. Project and Scene Structure

A project conceptually contains:

Project
├── Metadata
├── Assets
├── Characters
├── Poses
└── Scenes

A scene conceptually contains:

Scene
├── Scene Objects
└── Animation Data

A project may contain multiple scenes.

Characters and other reusable resources should not be permanently tied to one
scene unless a future feature explicitly requires that behaviour.

---

11. Character Architecture

Characters are reusable definitions.

A character contains visual parts and rig information.

Conceptually:

Character
├── Character Parts
└── Rig

A character can be instantiated into a scene:

Project
├── Characters
│   └── Alex
│
└── Scene
    ├── Alex Instance
    └── Alex Instance

Each instance can have its own scene-specific:

- Position
- Rotation
- Scale
- Pose
- Animation
- Other state

Changing an instance must not unexpectedly modify the reusable character
definition.

---

12. Rig and Hierarchy

The rig defines relationships between character parts.

Example:

Root
└── Body
    ├── Head
    ├── Upper Arm
    │   └── Lower Arm
    │       └── Hand
    └── Leg
        └── Lower Leg

The rig should contain structural relationships and pivot information.

It should not be responsible for storing image files.

Character parts should reference assets.

---

13. Transform System

The MVP transform system supports:

- Position
- Rotation
- Scale

Opacity may be supported if practical.

Transforms should be represented in a way that supports hierarchical
parent/child relationships.

The exact mathematical representation is an implementation detail and should
not be exposed unnecessarily throughout the application.

---

14. Animation Architecture

Animation data must be independent of the timeline UI.

Conceptually:

Animation
└── Animation Track
    ├── Target
    ├── Property
    └── Keyframes

Example:

Animation Track
├── Target: Upper Arm
├── Property: Rotation
└── Keyframes
    ├── Time: 0
    │   Value: 0°
    └── Time: 20
        Value: 45°

The animation system evaluates this data during playback and rendering.

The timeline is an editor for this data, not its owner.

---

15. Playback

Playback should use the same underlying animation model used by export.

Conceptually:

Project Data
     ↓
Animation Evaluation
     ↓
Scene State at Time T
     ↓
Rendering

This helps reduce differences between:

- Editor preview
- Playback
- Export

Temporary playback state such as the current playhead position should remain
separate from persistent project content unless explicitly saved.

---

16. Rendering

Rendering should be treated as a separate concern from project data.

Conceptually:

Project Data
     ↓
Animation Evaluation
     ↓
Renderable Scene State
     ↓
Rendering Backend
     ↓
Display / Export

The project model should describe what exists.

The rendering system determines how it is displayed.

This separation is important for future features such as:

- Warp deformers
- Lighting
- Shadows
- Filters
- Video
- Effects
- Rendering optimisation

These features should not be implemented merely because the architecture
allows them.

---

17. Asset Management

Assets should be stored/referenced separately from scene objects.

For example:

Asset
└── arm.png

A character part may reference that asset:

CharacterPart
└── Asset → arm.png

The same asset may be reused where appropriate.

The exact storage mechanism is an implementation decision.

---

18. Project Serialization

Project data must be serializable.

The project format should have an explicit version identifier.

Conceptually:

Project File
├── formatVersion
└── project data

The application must not assume that the current project structure will remain
unchanged forever.

Future versions may require migrations.

---

19. Project Format Migration

When the project format changes, the application should be able to recognise
older supported versions and migrate them to the current format where
practical.

Conceptually:

Project v1
   ↓
Migration
   ↓
Current Project Model
   ↓
Project v2

Migration logic should be tested.

A project format change should be treated as an important architectural
change and documented in "docs/decisions.md" when that document is created.

---

20. Undo and Redo

Undo/redo is an important architectural consideration for the editor.

Editing operations should be structured so that undo/redo can be added without
rewriting the core data model.

Where practical, editing operations should eventually be represented as
explicit commands or reversible operations.

A complete undo/redo system is not required before the MVP editing workflow is
proven.

---

21. Autosave

The architecture should allow autosave to be added later.

Autosave is not an MVP requirement.

The project state and persistence system should therefore avoid designs that
make future autosave unnecessarily difficult.

---

22. Error Handling

Errors should be represented and handled deliberately.

Examples include:

- Invalid project data
- Unsupported project version
- Missing asset
- Failed asset import
- Failed save
- Failed load
- Failed export

Low-level infrastructure errors should not leak unnecessarily into the UI.

User-facing errors should be understandable.

---

23. Testing Architecture

Core domain and application logic should be testable without requiring a
fully rendered application.

Priority testing areas include:

- Project creation
- Project serialization
- Project loading
- Project migration
- Transform calculations
- Parent/child transformations
- Pivot behaviour
- Keyframe evaluation
- Interpolation
- Animation playback calculations
- Asset references

UI tests should be added where they provide meaningful protection for
important workflows.

---

24. Cross-Platform Architecture

Flutter is the application framework.

The architecture should support:

- Android
- iOS
- Windows
- macOS
- Linux
- Web

However, "supports a platform" should mean more than merely compiling.

Important workflows should eventually be tested on supported platforms.

Platform-specific functionality should be isolated behind appropriate
boundaries rather than spread throughout the domain model.

---

25. Performance Principles

Animation editors can become computationally expensive.

The MVP should therefore avoid unnecessary complexity and premature
optimisation.

However, the architecture should avoid obvious designs that require the
entire application to rebuild for every small animation change.

Performance-sensitive systems may eventually include:

- Rendering
- Animation evaluation
- Timeline updates
- Large layer hierarchies
- Asset loading
- Video processing

Optimisation should be guided by measurement rather than speculation.

---

26. Dependencies

Dependencies should be kept to a reasonable minimum.

Before adding a dependency, the implementation should consider:

1. Whether the functionality is actually required.
2. Whether Flutter/Dart already provides the required capability.
3. Whether the dependency is maintained.
4. Whether it supports required platforms.
5. Whether its licensing is appropriate.
6. Whether it introduces unnecessary architectural coupling.

Dependencies should not be added merely because they make a small task
slightly easier.

---

27. MVP Boundary

The architecture must not become an excuse to implement future features
prematurely.

The MVP focuses on:

Project
  ↓
Import image assets
  ↓
Scene
  ↓
Layers / objects
  ↓
Character parts
  ↓
Pivots / hierarchy
  ↓
Transforms
  ↓
Keyframes
  ↓
Timeline
  ↓
Playback
  ↓
Image / video export

Features such as:

- Warp deformers
- Advanced lighting
- Shadows
- Drawing
- Social features
- Advanced rigging
- Complex effects

remain outside the MVP unless the roadmap is deliberately changed.

---

28. Architecture Evolution

This architecture is expected to evolve as the application is developed.

However, architectural changes should be deliberate.

Before making a major architectural change, consider:

- What problem does it solve?
- What existing code does it affect?
- Does it simplify or complicate the project?
- Does it support an actual requirement?
- Can the change be tested?
- Does it require a documentation update?
- Does it require a decision record?

Major architectural changes should be recorded in "docs/decisions.md" once
that document exists.

---

29. Core Architecture Principles

The following principles are authoritative:

1. Keep domain logic independent from Flutter UI.
2. Keep business logic out of UI widgets.
3. Treat persistent project data as the source of truth.
4. Keep animation data independent from the timeline UI.
5. Separate reusable definitions from scene instances.
6. Separate rendering from persistent project data.
7. Version project formats.
8. Plan for project migrations.
9. Keep platform-specific concerns isolated.
10. Prefer testable, small components.
11. Avoid unnecessary dependencies.
12. Do not implement future features prematurely.
13. Prefer measured optimisation over speculative optimisation.
14. Document major architectural changes.
15. Preserve the ability to save, load, test, preview, and export using the
    underlying project model rather than UI-specific state.
    ---

## 21. Architectural Changes Require Review

AI agents must not silently introduce major architectural changes.

If the current architecture prevents a required feature from being implemented
correctly, the agent should:

1. Explain the limitation.
2. Describe the proposed architectural change.
3. Identify affected components and documentation.
4. Identify relevant tests.
5. Ask for approval before making a major architectural change.

Small implementation decisions that remain within the documented architecture
do not require approval.

When in doubt, prefer preserving the existing architecture and asking rather
than silently expanding it.