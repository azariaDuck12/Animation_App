# Animation_App Features

## Status

This document defines the current feature scope of Animation_App.

Features are divided into priority levels:

- P0 — MVP / required for the first usable release
- P1 — Important post-MVP features
- P2 — Advanced animation features
- P3 — Advanced rendering and visual effects
- P4 — Drawing and frame-by-frame tools
- P5 — Productivity and reuse features
- P6 — Social features

A feature being documented here does not automatically mean it is currently
implemented.

---

# Product Goal

Animation_App is a cross-platform 2D animation and video-editing application
primarily intended for Gacha animators, while remaining useful for other
2D puppet animation, stop-motion, keyframe animation, and image-based
animation workflows.

The core experience is:

```text
Import assets
    ↓
    Build a character/model
        ↓
        Create a hierarchy and pivots
            ↓
            Create poses
                ↓
                Animate with keyframes
                    ↓
                    Preview
                        ↓
                        Export