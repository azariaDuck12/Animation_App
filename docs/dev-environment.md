# Developing Animation_App on a tablet

## Status

Adopted 2026-08-29 (ADR-001). This document is the reason the web-first
architecture was chosen: the bulk of development is done, with AI
assistance, on a tablet, and a paid remote machine is not wanted.

**The development device is a Lenovo Idea Tab Pro (Android).** Workflow A
below (fully local, in Termux) is therefore the primary workflow; B and C
are complements. Check the installed RAM under Settings → About tablet; the
common configuration has 8 GB, which is comfortable against the budget in
§2. The rows for other operating systems are kept for contributors on
other devices.

---

## 1. Which workflow fits which tablet

| Tablet | Fully local (A) | Cloud agent (B) | Home PC as build box (C) |
| --- | --- | --- | --- |
| Android (3 GB+ RAM) | **Yes — recommended** (Termux) | Yes | Yes |
| iPad | No (no shell that can run Node usefully) | **Yes — recommended** | Yes |
| Chromebook (Linux enabled) | **Yes** (Crostini container) | Yes | Yes |
| Windows tablet | **Yes** (it is a small PC) | Yes | Yes |

All three workflows are free of recurring cost within their free tiers.
All three work with the adopted TypeScript stack. Only C (and a paid,
larger B) work with Flutter, and none of them work well with Rust on a
tablet — that difference is the core of `reviews/2026-08-29-architecture-review.md`.

Whatever the workflow, the app is always *tested* on the tablet: it is the
target device.

---

## 2. Memory and disk budget

Approximate resident memory of the toolchain (Linux/Termux):

| Process | RAM |
| --- | --- |
| Vite dev server (`npm run dev`) | 150–300 MB |
| `tsc --watch` (optional; Vite does not type-check) | 300–600 MB |
| Vitest, one run | 200–400 MB |
| Claude Code CLI (Node) | 200–400 MB |
| Browser tab with the app and a few 2 K images | 300–600 MB |
| **Total, everything at once** | **≈ 1.2–2.3 GB** |

Disk: Node ≈ 100 MB, `node_modules` ≈ 250 MB, project ≈ small.

For comparison, the Dart analyzer alone commonly sits at 1–2 GB, the
Flutter SDK is ~3 GB on disk, and an Android build wants 4–8 GB of RAM.
`rust-analyzer` on a GUI crate is 1–3 GB and a first `cargo build` can
take 10+ minutes on a laptop.

Practical tips on a 3–4 GB tablet: run Vite and the browser, and run
`tsc`/tests only when needed rather than in watch mode; close other apps;
keep imported test images small.

---

## 3. Workflow A — fully local on an Android tablet (Termux)

Everything runs on the tablet; nothing leaves it; works offline. This is
the workflow that makes the tablet a self-sufficient development machine.

Setup (once):

```bash
# 1. Install Termux from F-Droid (the Play Store build is outdated).
# 2. In Termux:
pkg update && pkg upgrade
pkg install nodejs-lts git openssh
git config --global user.name "…" && git config --global user.email "…"
# 3. GitHub auth: either `pkg install gh && gh auth login`, or an SSH key:
ssh-keygen -t ed25519 && cat ~/.ssh/id_ed25519.pub   # add to GitHub
# 4. Clone
git clone git@github.com:azariaDuck12/Animation_App.git && cd Animation_App
npm install
# 5. AI assistant (whichever the developer uses; Claude Code is a Node package):
npm install -g @anthropic-ai/claude-code && claude
```

Daily loop:

```bash
npm run dev -- --host    # Vite on http://localhost:5173
# open Chrome on the same tablet → localhost:5173 (split-screen with Termux)
npm test                 # Vitest, when needed
npm run typecheck        # tsc --noEmit, before committing
```

Notes:

- Vite, esbuild and Rollup all publish `android-arm64` binaries, so
  `npm install` works in Termux without compiling anything.
- Termux has to stay alive in the background: acquire a wake lock from
  its notification and exclude Termux from battery optimisation.
- Editing: the AI assistant does most of the typing. For manual edits,
  a code editor app (e.g. Acode) can open the Termux project folder via
  `termux-setup-storage`, or run `code-server` in Termux for VS Code in the
  browser (adds ~500 MB RAM; optional).
- An external keyboard makes this dramatically more pleasant.

---

## 4. Workflow B — cloud agent, tablet as a thin client

The code is edited and run on a machine in the cloud that is included with
a subscription or free tier the developer already has; the tablet only needs
a browser.

Options, in order of least effort:

1. **Claude Code on the web** (`claude.ai/code`) — describe the change, the
   agent works in a cloud sandbox on a branch, opens a pull request; CI
   builds and deploys a preview; open the preview URL on the tablet. Included with Claude plans that include Claude Code (check the
   current plan). No toolchain on the tablet at all.
2. **GitHub Codespaces** — VS Code in the browser on a 2-core cloud
   machine, `npm run dev`, forwarded port opened on the tablet. Personal
   accounts get a monthly free allowance of core-hours (120 at the time of
   writing; check GitHub's current pricing page). The repository's
   `.devcontainer` should be switched to a Node image for this. Stop the
   codespace when done to preserve the allowance.
3. **github.dev / vscode.dev** — browser editor with no runtime; useful for
   reading and small edits with CI doing the building.

This is the only workflow available on an iPad, and it is also a good
complement to Workflow A on Android (bigger changes in the cloud, quick
tweaks locally).

---

## 5. Workflow C — the home PC as a free build box

The home PC (the one this review ran on: 6 cores, ~6 GB RAM in WSL2) runs
the toolchain; the tablet connects to it.

- **VS Code Remote Tunnels** (free): on the PC, `code tunnel`; on the
  tablet, open `vscode.dev` and connect to the tunnel. Full VS Code in the
  tablet's browser, terminal included. Run `npm run dev -- --host` and open
  `http://<pc-lan-ip>:5173` on the tablet.
- Or plain SSH from Termux/Blink/Prompt to the PC.

Works with any stack, including Flutter, which is why it was the documented fallback
option: `flutter run -d web-server --web-hostname
0.0.0.0` serves a Flutter web build the tablet can open. Expect
30–90-second rebuilds and ~2 GB RAM on the PC for Flutter versus
sub-second and ~300 MB for Vite.

Limits: the PC must be on and on the same network (or a Tailscale-style
free mesh VPN for away-from-home use); the tablet is never self-sufficient.

---

## 6. Hosting the built app (free)

`main` is built by CI and published so the app has a stable URL. Because
IndexedDB is per-origin (`project-file-format.md` §3), choose the URL once.

- **GitHub Pages** (chosen 2026-08-29) — free for public repositories,
  which this one is. The app lives at
  `https://azariaduck12.github.io/Animation_App/`, so Vite is built with
  `base: '/Animation_App/'`. Deployment is the second job in the CI
  workflow below.
- **Cloudflare Pages** or **Netlify** free tier — alternatives if Pages
  ever becomes unsuitable.
- Until any of this is set up, Workflow A serves the app locally on the
  tablet and nothing needs hosting.

---

## 7. Continuous integration

`.github/workflows/ci.yml` (sketch):

```yaml
name: ci
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npm run typecheck
      - run: npm test -- --run
      - run: npm run build
      - uses: actions/upload-pages-artifact@v3
        with: { path: dist }
  deploy:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: ubuntu-latest
    permissions: { pages: write, id-token: write }
    environment: github-pages
    steps:
      - uses: actions/deploy-pages@v4
```

GitHub Actions is free for public repositories and includes 2,000
minutes/month for private ones on the Free plan; this job takes ~1 minute.

---

## 8. Dev container (optional)

Replace the Flutter-installing `.devcontainer` with the stock Node image;
this is all Codespaces or a local Docker setup needs:

```json
{
  "name": "Animation App",
  "image": "mcr.microsoft.com/devcontainers/typescript-node:22",
  "postCreateCommand": "npm ci",
  "forwardPorts": [5173],
  "customizations": { "vscode": { "extensions": ["esbenp.prettier-vscode", "vitest.explorer"] } }
}
```

---

## 9. Testing on the tablet — checklist

Before calling a feature done, on the tablet:

- [ ] Pinch zoom and two-finger pan work in the viewport.
- [ ] Every handle can be grabbed with a finger.
- [ ] Rotate the tablet; the layout still works.
- [ ] Background the browser for a minute, return: nothing lost.
- [ ] Export an MP4 and open it in the gallery.
