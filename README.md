# Xonotic Gaming Server (ARM64)

This repository hosts a **Xonotic 0.8.6 dedicated game server** for **ARM64** using Docker. The official Xonotic release only ships x86_64 server binaries, so the Dockerfile **compiles the engine from the official release source** (included in the 0.8.6 archive) — no binaries are cross-downloaded. Only client-only binaries are trimmed from the image; everything the server uses is kept.

Built as a standalone project, inspired by existing Xonotic server images — see [License and Acknowledgments](#license-and-acknowledgments).

---

## Requirements

- Docker on an **ARM64** machine (Raspberry Pi 4/5, ARM cloud instance such as Oracle Ampere, Apple Silicon with Docker Desktop).
- At least 2 GB of RAM and 4 GB of free disk are recommended (the image contains the full game data, ~2 GB).

## 1. Install Docker

Depending on your machine: Docker Desktop, `apt install docker.io`, or your distribution's package.

## 2. Start Your Server

**Easiest way:** download and run the setup script:

```bash
curl -O https://raw.githubusercontent.com/dr4vs/xonotic-server-arm64/main/setup.sh
bash setup.sh
```

This works from any folder — if `Dockerfile` is not in the current directory, the script downloads it automatically before building.

**Or build and run manually** (from the repository root):

```bash
docker build -t xonotic-server:arm64 .
docker run -d \
  --name xonotic-server \
  --restart unless-stopped \
  -p 26000:26000/udp \
  -p 26000:26000 \
  -v xonotic-data:/opt/Xonotic/data \
  xonotic-server:arm64
```

That's it. Your server is now running.

**Using docker compose:**

```bash
docker compose up -d --build
```

The first build compiles the engine from source and can take 10–20 minutes depending on your CPU.

## 3. Connect and Play

Open Xonotic on your computer, press the **`~`** key to open the console, and type:

```
connect your-server-ip:26000
```

Replace `your-server-ip` with your IP address.

---

## Stop or Restart

To stop your server:

```bash
docker stop xonotic-server
```

To start it again later:

```bash
docker start xonotic-server
```

To remove it completely:

```bash
docker rm xonotic-server
```

---

## Change Server Settings

Server settings live in `/opt/Xonotic/data/server.cfg`:

- If you started the server with `setup.sh`, edit the `server.cfg` it created in your folder and restart:
  ```bash
  docker restart xonotic-server
  ```
- If you run the container yourself, mount your own config:
  ```bash
  docker run -d --name xonotic-server \
    --restart unless-stopped \
    -p 26000:26000/udp -p 26000:26000 \
    -v "$(pwd)/server.cfg:/opt/Xonotic/data/server.cfg:ro" \
    xonotic-server:arm64
  ```
- Long-term storage (maps, scores, config) persists in the named volume `xonotic-data` through `docker compose`.

## Keep Your Data Safe (Backups)

To back up your server data:

```bash
docker run --rm -v xonotic-data:/data -v .:/backup ubuntu tar czf /backup/xonotic-backup.tar.gz -C /data .
```

---

## Building for ARM64 from another architecture

To produce the ARM64 image on an x86_64 machine, use Docker Buildx with QEMU emulation:

```bash
docker buildx create --use
docker buildx build --platform linux/arm64 -t xonotic-server:arm64 .
docker save xonotic-server:arm64 | gzip > xonotic-server-arm64.tar.gz
```

Transfer the archive to your ARM64 machine and load it:

```bash
docker load -i xonotic-server-arm64.tar.gz
```

---

## License and Acknowledgments

This repository is licensed under the **GPL-3.0** license (see `LICENSE`). The Xonotic game itself is GPL-licensed and compiled from its official 0.8.6 release sources.

References:
- [Umair-khurshid/Xonotic-Server](https://github.com/Umair-khurshid/Xonotic-Server) (GPL-3.0) — basis for the Docker/Compose structure, setup script and smoke test.
- [ballerburg9005/docker-arm64-xonotic-server-git](https://github.com/ballerburg9005/docker-arm64-xonotic-server-git) — inspiration for compiling the engine from source for ARM64.