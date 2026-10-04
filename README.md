# pinokio-docker

[Pinokio](https://github.com/pinokiocomputer/pinokio) in a container, accessible from any web browser.

Pinokio is a 1-click launcher for open-source AI apps: browse, install, run and manage tools like Stable Diffusion WebUIs, ComfyUI, LLM front ends or voice cloning without touching a terminal. This image runs the Pinokio desktop app on a Linux desktop that is streamed to your browser, so you can host it on a server (Unraid, a NAS, a home lab box) and use it from anywhere on your network.

[![Docker Hub](https://img.shields.io/docker/pulls/joly0/pinokio-docker?logo=docker)](https://hub.docker.com/r/joly0/pinokio-docker)
[![Image version](https://img.shields.io/docker/v/joly0/pinokio-docker?sort=semver&logo=docker)](https://hub.docker.com/r/joly0/pinokio-docker/tags)
[![License](https://img.shields.io/github/license/Joly0/pinokio-docker)](LICENSE)

## Features

- **Pinokio in the browser**: the desktop app runs on [linuxserver.io's Selkies base image](https://github.com/linuxserver/docker-baseimage-selkies) and is streamed to the browser over HTTP and HTTPS
- **Always up to date**: new Pinokio releases are picked up automatically within a few hours, and the image is rebuilt weekly for base image and security updates
- **Persistent data**: everything (Pinokio home, installed apps, models, settings) lives in `/config`
- **Configurable through environment variables**: any `PINOKIO_*` variable is written into Pinokio's own settings on first start
- **Local network sharing**: apps started in Pinokio can be reached from other devices through a fixed port
- **Self-healing**: Pinokio is restarted automatically if it crashes or is closed

## Quick start

### docker run

```bash
docker run -d \
  --name=pinokio \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/London \
  -p 3000:3000 \
  -p 3001:3001 \
  -p 50000:50000 \
  -v /path/to/config:/config \
  --shm-size=1gb \
  --security-opt seccomp=unconfined \
  --restart unless-stopped \
  joly0/pinokio-docker:latest
```

### docker compose

```yaml
services:
  pinokio:
    image: joly0/pinokio-docker:latest
    container_name: pinokio
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - /path/to/config:/config
    ports:
      - 3000:3000
      - 3001:3001
      - 50000:50000
    shm_size: "1gb"
    security_opt:
      - seccomp:unconfined
    restart: unless-stopped
```

Then open **https://yourhost:3001/** (or http://yourhost:3000/) in your browser. Pinokio starts maximised in the streamed desktop.

> [!NOTE]
> Pinokio installs apps, Python environments and models into `/config`, so plan for plenty of disk space there (often tens to hundreds of GB).

## Parameters

| Parameter | Description |
| --- | --- |
| `-p 3000` | Web desktop over HTTP |
| `-p 3001` | Web desktop over HTTPS (self-signed certificate) |
| `-p 50000` | Pinokio local network sharing port, see `PINOKIO_SHARE_LOCAL_PORT` |
| `-e PUID=1000` | User ID the app runs as, see [user and group IDs](https://docs.linuxserver.io/general/understanding-puid-and-pgid/) |
| `-e PGID=1000` | Group ID the app runs as |
| `-e TZ=Europe/London` | Timezone, e.g. `Europe/Berlin` |
| `-v /config` | Home directory of the container user: Pinokio's data, installed apps and settings |
| `--shm-size=1gb` | Shared memory for the Electron based Pinokio app; required for it to work reliably |
| `--security-opt seccomp=unconfined` | Allows newer system calls that many GUI apps need on older Docker hosts |

### Pinokio settings

Pinokio keeps its settings in `/config/pinokio/ENVIRONMENT`. Any environment variable starting with `PINOKIO_` that matches a key in that file is written into it once Pinokio has created the file on first start. Each key is only applied once: changes you make later in the Pinokio settings are kept across restarts, and a key is never overwritten again. To reapply a variable, remove its line from `/config/pinokio/.pinokio_env_applied`.

| Variable | Default in this image | Description |
| --- | --- | --- |
| `PINOKIO_SHARE_LOCAL` | `true` | Share apps started in Pinokio on the local network |
| `PINOKIO_SHARE_LOCAL_PORT` | `50000` | Fixed port for local network sharing (publish the same port on the container) |
| `PINOKIO_CLI` | | Extra command line arguments passed to the Pinokio binary |

All other keys in the `ENVIRONMENT` file work the same way, see the comments in that file for what each one does.

### Desktop options

The [Selkies base image](https://github.com/linuxserver/docker-baseimage-selkies) offers further options, for example:

| Variable | Description |
| --- | --- |
| `CUSTOM_USER` | HTTP basic auth user name, `abc` by default |
| `PASSWORD` | HTTP basic auth password; no authentication when unset |
| `CUSTOM_PORT` / `CUSTOM_HTTPS_PORT` | Change the internal ports from `3000` / `3001` |
| `SUBFOLDER` | Serve under a subfolder when behind a reverse proxy, e.g. `/pinokio/` |
| `TITLE` | Browser tab title, `Pinokio` by default |

See the [Selkies configuration docs](https://docs.linuxserver.io/selkies/user-guide/configuration/) for the full list, including [GPU acceleration](https://docs.linuxserver.io/selkies/user-guide/gpu/).

> [!WARNING]
> Without `PASSWORD` there is no authentication, and the desktop includes a terminal with passwordless `sudo`: anyone who can reach the ports gets root inside the container. Basic auth is only suitable for a trusted local network; for internet access, put the container behind a reverse proxy with proper authentication.

## Image tags

Images are published to [Docker Hub](https://hub.docker.com/r/joly0/pinokio-docker) and the [GitHub Container Registry](https://github.com/Joly0/pinokio-docker/pkgs/container/pinokio-docker) as `joly0/pinokio-docker` and `ghcr.io/joly0/pinokio-docker`.

| Tag | Meaning |
| --- | --- |
| `latest` | Newest build |
| `8`, `8.2` | Newest build of that Pinokio major or minor version |
| `8.2.0` | Newest build of that exact Pinokio version |
| `8.2.0-J49` | One specific build; pin this to never change unexpectedly |

Only `linux/amd64` is built.

## Building locally

```bash
git clone https://github.com/Joly0/pinokio-docker.git
cd pinokio-docker
docker build -t pinokio-docker .
```

The build installs the newest Pinokio release. Pass `--build-arg PINOKIO_VERSION=<release tag>` to build a specific one.

## Support

Bugs and feature requests go to the [issue tracker](https://github.com/Joly0/pinokio-docker/issues). Problems with Pinokio itself (rather than with the container) belong in the [Pinokio repository](https://github.com/pinokiocomputer/pinokio/issues).

## License

[AGPL-3.0](LICENSE). Pinokio itself is developed by [pinokiocomputer](https://github.com/pinokiocomputer/pinokio) under its own license.
