# Animation_App Architecture

## Status

This document describes the current proposed architecture for Animation_App.

The architecture is intentionally designed for incremental development.

Major architectural changes should be recorded in `docs/decisions.md`.

---

# 1. Product Overview

Animation_App is a cross-platform 2D animation and video-editing application
primarily intended for Gacha animators, while remaining useful for other
2D puppet animation, stop-motion, keyframe animation, and image-based
animation workflows.

The application is intended to support:

- Android
- iOS
- Windows
- macOS
- Linux
- Web

The application should work on both touch-oriented devices and traditional
desktop computers.

---

# 2. Technology Foundation

The primary application framework is:

**Flutter**

Flutter is responsible primarily for:

- Application UI
- Navigation
- Panels
- Menus
- Timeline controls
- Asset browsers
- Property inspectors
- Settings
- Touch interaction
- Mouse interaction
- Keyboard interaction
- Platform integration

The animation and project systems should not become tightly coupled to
Flutter UI code.

---

# 3. High-Level Architecture

The application is divided into several major systems:

```text
Flutter Application
        │
                ▼
                Application/UI Layer
                        │
                                ▼
                                Core Animation Engine
                                        │
                                                ├── Scene System
                                                        ├── Layer System
                                                                ├── Character/Rig System
                                                                        ├── Timeline System
                                                                                ├── Pose System
                                                                                        └── Animation System
                                                                                                │
                                                                                                        ▼
                                                                                                        Rendering Layer
                                                                                                                │
                                                                                                                        ▼
                                                                                                                        Asset / Project System