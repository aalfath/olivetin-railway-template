[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/olivetin?utm_medium=integration&utm_source=button&utm_campaign=olivetin)

# OliveTin on Railway

This repo is the source of the **OliveTin** template on Railway's marketplace. [OliveTin](https://github.com/OliveTin/OliveTin) gives safe and simple access to predefined shell commands from a web interface: you write the commands in `config.yaml`, and people with access click a button to run them.

## What the template deploys

- **OliveTin 3000.22.0**, built from this repo's `Dockerfile` (official image `ghcr.io/olivetin/olivetin:3000.22.0`, pinned by digest), one service with a public Railway domain.
- A **Railway volume at `/config`** for `config.yaml`, login sessions and saved action logs (logs older than 30 days are pruned).
- **Login required from the first boot.** The starter config sets `authRequireGuestsToLogin: true` and one local user, `admin`, in the `admins` group. Guests see only the login page.
- Health check: `GET /readyz`.

## Variables

| Variable | Default | What it is |
|---|---|---|
| `OLIVETIN_ADMIN_PASSWORD` | generated (`${{secret(24)}}`) | Password of the `admin` user. Read it in the service's Variables tab. Change it and redeploy to rotate it. |
| `OLIVETIN_ADMIN_USERNAME` | `admin` | User name of the admin login. |
| `PORT` | `1337` | Port OliveTin listens on. Railway's domain points at it. |

The start script hashes the password with argon2id (using OliveTin's own hashing) every time the service starts and passes the hash to `config.yaml` as `${{ OLIVETIN_ADMIN_PASSWORD_HASH }}`. The plain password never lands on the volume.

## Adding your own commands

`/config/config.yaml` is written once, on the first boot, and is never overwritten afterwards. OliveTin reloads it by itself when it changes. Two ways to edit it:

1. **From OliveTin:** log in, open the *Settings* dashboard, run **Show config.yaml**, edit a copy, and paste the whole file into **Replace config.yaml**. The action checks the new file with `OliveTin -syntaxcheck`, refuses configs without `authRequireGuestsToLogin: true`, keeps the old file as `config.yaml.bak`, and swaps the new one in. **Restore previous config.yaml** brings the backup back.
2. **From a terminal:** `railway ssh` into the service and edit `/config/config.yaml`.

Commands run inside the OliveTin container as the unprivileged `olivetin` user. The image includes `bash`, `curl`, `jq`, `git`, `ssh`, `kubectl`, `apprise` and `python3`. To control other machines, use `ssh` or HTTP APIs from your actions; Railway has no Docker socket to mount. See the [OliveTin docs](https://docs.olivetin.app) for actions, arguments, dashboards, users, OAuth2 and API keys.

## How updates reach you

Your Railway project builds from this repo. When a new OliveTin version is merged to `main`, Railway shows an "update available" notice on your project, and you choose when to apply it. Read [`CHANGELOG.md`](CHANGELOG.md) first: breaking changes are listed at the top of each entry. Your `config.yaml` on the volume is kept across updates.

## Files

- `Dockerfile`: the pinned upstream image plus the start script.
- `railway-start.sh`: prepares the volume, hashes the admin password, writes the starter config once, and starts OliveTin as the `olivetin` user.
- `config.default.yaml`: the starter config (login required, example actions).
- `replace-config.sh`: the checked config replacement used by the *Replace config.yaml* action.

OliveTin is AGPL-3.0, by James Read and contributors. This wrapper is not affiliated with the OliveTin project.
