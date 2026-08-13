# Animation_App Roadmap

## Status

This roadmap describes the intended development order for Animation_App.

The roadmap is a planning document, not a promise that every future feature
will be implemented.

Priorities may change as development reveals new technical information.

---

# Phase 0 — Project Foundation

## Goal

Establish a stable development foundation before implementing application
features.

### Tasks

- [x] Create GitHub repository
- [x] Establish project documentation structure
- [x] Establish Cursor AI rules
- [x] Define project constitution
- [x] Define AI development workflow
- [x] Define testing standards
- [x] Define documentation standards
- [x] Choose Flutter as the application foundation
- [ ] Finalise technical architecture
- [ ] Define project data model
- [ ] Define project file format
- [ ] Define initial testing strategy
- [ ] Set up Flutter development environment
- [ ] Create initial application shell
- [ ] Establish CI/build verification

---

# Phase 1 — Core MVP

## Goal

Prove the fundamental Animation_App workflow.

The user should be able to create a simple animated character from imported
image parts, animate it, preview it, save the project, and export the result.

---

## 1. Project System

- [ ] Create project
- [ ] Open project
- [ ] Save project
- [ ] Reopen project
- [ ] Project metadata
- [ ] Project format version
- [ ] Basic project migration strategy

---

## 2. Scene

- [ ] Create scene
- [ ] Canvas
- [ ] Zoom
- [ ] Pan
- [ ] Select objects
- [ ] Basic scene composition

---

## 3. Asset Import

- [ ] Import image assets
- [ ] Import transparent PNG assets
- [ ] Store/reference imported assets
- [ ] Display imported assets in scenes

---

## 4. Layers

- [ ] Layer list
- [ ] Layer selection
- [ ] Reordering
- [ ] Visibility
- [ ] Locking
- [ ] Hierarchical organisation
- [ ] Front/back ordering

---

## 5. Transforms

- [ ] Position
- [ ] Rotation
- [ ] Scale
- [ ] Pivot points
- [ ] Basic transform controls

---

## 6. Character / Model System

- [ ] Create character/model
- [ ] Add image parts
- [ ] Name parts
- [ ] Set parent/child relationships
- [ ] Set pivots
- [ ] Move parts through hierarchy
- [ ] Save reusable model

---

## 7. Animation

- [ ] Timeline
- [ ] Playhead
- [ ] Scrubbing
- [ ] Keyframes
- [ ] Position animation
- [ ] Rotation animation
- [ ] Scale animation
- [ ] Basic interpolation
- [ ] Basic easing
- [ ] Play
- [ ] Pause
- [ ] Preview

---

## 8. Export

- [ ] Export still image
- [ ] Basic video export
- [ ] Basic resolution setting
- [ ] Basic frame-rate setting

---

# Phase 1 Completion Criteria

The MVP should be considered functionally complete when a user can:

```text
Create project
      ↓
      Import image parts
            ↓
            Build a simple character
                  ↓
                  Set pivots
                        ↓
                        Create parent/child relationships
                              ↓
                              Animate position/rotation/scale
                                    ↓
                                    Preview animation
                                          ↓
                                          Save project
                                                ↓
                                                Close application
                                                      ↓
                                                      Reopen project
                                                            ↓
                                                            Export image/video