# Changelog

Each entry is one version of this Railway template. Breaking changes come first.
Updates reach deployed projects as Railway's "update available" notice when a
change is merged to `main`; you choose when to apply it.

## 3000.22.0-3 (2026-11-23)

- Fix: **Replace config.yaml** and **Restore previous config.yaml** now swap the file in with an atomic rename. Before, OliveTin could reload a half-written file and keep running the old actions until the next redeploy. Same OliveTin version (3000.22.0); nothing to do after applying the update.
- Note for existing deploys: the starter `config.yaml` on your volume is never overwritten, so the *Restore previous config.yaml* action in it keeps its old command. Replace it from the README's example if you use it.

## 3000.22.0-2 (2026-11-23)

- README only: Deploy on Railway button linking to the published template (`olivetin`). No change to the running app.

## 3000.22.0-1 (2026-11-23)

- First release: OliveTin 3000.22.0 (`ghcr.io/olivetin/olivetin:3000.22.0@sha256:e8441343ab8e3d13daa83f4cb2a00d9fa3510953a6040a556a805918f5636264`).
- Login required from the first boot: an `admin` user with a generated password (`OLIVETIN_ADMIN_PASSWORD`), hashed with argon2id at every start.
- `/config` on a Railway volume: `config.yaml`, login sessions and saved action logs survive redeploys. The starter `config.yaml` is written once and never overwritten.
- Starter actions: disk space, website check, and show, replace or restore `config.yaml` from the web UI.
