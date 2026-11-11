# phpenv

> If docker-compose manages containers, **phpenv manages multiple docker-compose projects.**

A Docker-based PHP runtime for **many projects on one machine** — each project gets its own `.env`, ports, services, and web stack, while you keep the **same** commands: `./link`, `./start`, `./console build`.

```text
  envs/project-a   →  DEFAULT + SERVICES + ports  →  compose stack A
  envs/project-b   →  DEFAULT + SERVICES + ports  →  compose stack B
                         ↑
              one mental model, many projects
```

## Why phpenv

Most setups stop at “one `docker-compose.yml` for one app.”  
phpenv adds an **environment router** on top:

| Idea | What you get |
| --- | --- |
| **Per-project `envs/`** | Isolate `PROJECT`, ports, `FOLDER`, UID/GID without copying the whole repo |
| **`./link`** | Switch the active project by symlinking `.env` |
| **`DEFAULT`** | Swap Nginx socket / Nginx TCP / Apache — **same** start/build/reload flow |
| **`SERVICES`** | Opt-in MariaDB, Redis, SSH, drive… via compose overlays |
| **Split `etc*` trees** | Config stays tied to how PHP-FPM talks to the web server |

You do **not** learn a second workflow when you change stacks. Change one line in `.env`, rebuild, restart.

## Features

- Multi-project isolation via `envs/` + `./link`
- Web stacks via `DEFAULT`: Nginx (unix socket), Nginx (TCP `:9000`), Apache (unix socket, **`.htaccess`**)
- Optional services from `services/*.yml` (`SERVICES="mariadb redis"`)
- PHP images based on [`deviny/fpm`](https://hub.docker.com/r/deviny/fpm) (8.2–8.5 pins, plus legacy 7.4)
- SSH-friendly containers for VS Code Remote-SSH / editors
- Auto-sync PHP-FPM `user`/`group` from `USER_ID` / `GROUP_ID`
- Batch ops across all linked projects: `./all start` / `./all stop`

## Getting Started

### 1. Initialize

```bash
./link
```

Creates `envs/default` and links it as `.env` if needed.

### 2. Configure `.env`

```ini
# Enabled services (space-separated)
SERVICES="mariadb redis"
APP_URL=http://127.0.0.1:1050
PROJECT=my-awesome-project
FOLDER=..
HTTP_PORT=1050
HTTPS_PORT=1150
DB_PORT=1250
SSH_PORT=2222
USER_ID=1000
GROUP_ID=1000

# Web stack (optional; default is docker-compose)
# DEFAULT=docker-compose
# DEFAULT=docker-compose-tcp
# DEFAULT=docker-compose-apache
```

### 3. Choose web stack (`DEFAULT`)

| `DEFAULT=` | Compose file | Web | PHP-FPM | Config |
| --- | --- | --- | --- | --- |
| `docker-compose` (default) | `docker-compose.yml` | Nginx | unix socket | `etc/` |
| `docker-compose-tcp` | `docker-compose-tcp.yml` | Nginx | TCP `:9000` | `etc-tcp/` |
| `docker-compose-apache` | `docker-compose-apache.yml` | Apache | unix socket | `etc-apache/` (+ shared `etc/php`, `etc/supervisor`, `etc/cache`) |

**Apache** enables project **`.htaccess`** (`AllowOverride All`).  
If TLS terminates in front of the container, prefer `X-Forwarded-Proto` in rewrite rules instead of only `%{HTTPS}` (avoids redirect loops).

After changing `DEFAULT`:

```bash
./console build
./restart
```

### 4. Optional services

Add names from `services/` to `SERVICES` in `.env` (e.g. `mariadb`, `redis`, `drive`).

### 5. Build and start

```bash
./console build   # once, or after UID/GID / DEFAULT / PHP image changes
./start
```

## Command Reference

| Command | Description |
| --- | --- |
| `./link` | Select or initialize an environment in `envs/` |
| `./link <project>` | Quickly link a specific `envs/<project>` |
| `./start` | Start the current project containers |
| `./stop` | Stop the current project containers |
| `./restart` | Restart the current project containers |
| `./reload` | Reload Nginx or Apache (follows `DEFAULT`) |
| `./info` | Show current `.env` |
| `./stats` | Status of all projects in `envs/` |
| `./artisan` | Run Laravel Artisan inside the PHP container |
| `./console` | Docker / project CLI (`build`, `ps`, `exec`, …) |

### Many projects

```bash
./all          # status of every env
./all start    # start all
./all stop     # stop all
```

### Console

```bash
./console                 # enter PHP workspace
./console exec db bash    # enter DB container
./console help            # subcommands
./console build           # build images for current DEFAULT stack
```

## Updates

Refresh core bash helpers without touching your project trees:

```bash
./update_bash.sh
```

PHP base images: see tags on [deviny/fpm](https://hub.docker.com/r/deviny/fpm/tags). Pin versions live under `dockerfiles/Dockerfile-php*`.
