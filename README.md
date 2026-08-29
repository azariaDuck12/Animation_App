# Animation_App

A 2D cut-out ("puppet") animation editor and simple video assembler, made
for Gacha animators and anyone animating with imported images. Build a
character from image parts with pivots and a parent/child hierarchy, pose
it over time with keyframes, preview, and export a video — all in the
browser on a phone, tablet or PC.

## Status

Pre-alpha. On 2026-08-29 the project adopted a web-first TypeScript
architecture (see `docs/decisions.md`, ADR-001). The Flutter scaffold in
this repository is scheduled for removal in Phase 0 of `docs/roadmap.md`;
no application code exists yet.

## Documentation

| Read this | For |
| --- | --- |
| `docs/vision.md` | What the app is and who it is for |
| `docs/architecture.md` | Stack, layers, rendering, persistence, export, testing |
| `docs/data-model.md` · `docs/project-file-format.md` | The project document and the `.animproj` file |
| `docs/features.md` · `docs/roadmap.md` | Scope by priority; the phased plan |
| `docs/decisions.md` | Architecture Decision Records |
| `docs/dev-environment.md` | Developing on the tablet (Termux), in the cloud, or via a home PC |
| `docs/glossary.md` | Terminology |
| `AGENTS.md` | Rules for AI coding agents (also loaded by `CLAUDE.md` and `.cursor/rules/`) |

## Developing

The primary development device is an Android tablet. `docs/dev-environment.md`
has the setup for Termux (fully local), Claude Code on the web / GitHub
Codespaces, and a home PC over a VS Code tunnel. Once the Vite scaffold
lands (roadmap Phase 0):

```bash
npm install
npm run dev -- --host    # open http://localhost:5173 on the tablet
npm test
```

The app will be published at https://azariaduck12.github.io/Animation_App/
once GitHub Pages is enabled.
