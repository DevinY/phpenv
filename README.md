# phpenv
Docker-based PHP containerized project execution environment.

This project allows you to manage multiple PHP projects easily using Docker. By specifying project paths via `.env` files and utilizing SSH services, you can seamlessly connect to your containers using VSCode's Remote-SSH.

## Features
- Multi-project support via isolated `.env` files in the `envs/` directory.
- Easy SSH access to containers.
- Configurable services (MariaDB, Redis, Nginx, PHP, etc.).
- Automated user/group ID syncing for Linux environments.

## Getting Started

### Step 1: Initialize Environment
Run the `link` script to create a default `.env` configuration template.
```bash
./link
```

### Step 2: Configure Environment
Edit the generated `.env` file to match your project requirements. You can set the project name, ports, and enabled services.

**Example `.env` Settings:**
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
```

### Step 3: Manage Services
Check the `services/` directory for available services (e.g., `mariadb`, `redis`, `drive`). Enable them by adding them to the `SERVICES` variable in your `.env`.

### Step 4: Build and Start
Build the containers (required only once or when changing user/group IDs).
```bash
./console build
```

## Command Reference

| Command | Description |
| --- | --- |
| `./link` | Select or initialize an environment template. |
| `./link <project>` | Quickly link to a specific project in `envs/`. |
| `./start` | Start the current project containers. |
| `./stop` | Stop the current project containers. |
| `./restart` | Restart the current project containers. |
| `./reload` | Reload Nginx configuration without restarting. |
| `./info` | Display current `.env` information. |
| `./stats` | View running status of all projects in `envs/`. |
| `./artisan` | Run Laravel artisan commands in the PHP container. |
| `./console` | Main CLI for Docker operations and project management. |

### Advanced: Multiple Environments
```bash
./all        # Check status of all projects in envs/
./all start  # Start all projects in envs/
./all stop   # Stop all projects in envs/
```

### Using Console
The `./console` script is the primary entry point. Running it without arguments will enter the PHP container workspace.
```bash
./console             # Enter PHP workspace
./console exec db bash # Enter DB container
./console help        # Show all subcommands
```

## Updates
To update only the core Bash scripts and get the latest fixes:
```bash
./update_bash.sh
```
