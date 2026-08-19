#!/usr/bin/env bash
set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

IMAGE="xonotic-server:arm64"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Xonotic Game Server - Quick Setup   ${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

if ! command -v docker &>/dev/null; then
  echo -e "${YELLOW}Docker is not installed.${NC}"
  echo "Install it first: https://www.docker.com/products/docker-desktop/"
  echo "Then run this script again."
  exit 1
fi

if ! docker info &>/dev/null; then
  echo -e "${YELLOW}Docker is installed but not running.${NC}"
  echo "Start Docker and try again."
  exit 1
fi

SERVER_NAME="Xonotic Server"
read -p "$(echo -e "${BOLD}Server name${NC} (press Enter for 'Xonotic Server'): ")" input
SERVER_NAME="${input:-$SERVER_NAME}"

SERVER_VERSION="0.8.6"
read -p "$(echo -e "${BOLD}Xonotic version${NC} (press Enter for '0.8.6'): ")" input
SERVER_VERSION="${input:-$SERVER_VERSION}"

SERVER_PASSWORD=""
read -s -p "$(echo -e "${BOLD}Server password (RCON)${NC} (press Enter for no password): ")" input
echo ""
SERVER_PASSWORD="$input"

SERVER_PUBLIC=0
read -p "$(echo -e "${BOLD}Make this server public${NC}? (visible in Xonotic's server list) [y/N]: ")" input
case "${input:-n}" in
  [yY]*) SERVER_PUBLIC=1 ;;
  *)     SERVER_PUBLIC=0 ;;
esac

echo ""
REPO_RAW="https://raw.githubusercontent.com/dr4vs/xonotic-server-arm64/main"
BUILD_DIR="."

echo -e "${GREEN}[1/4] Building image (first build compiles the engine, it can take a while)...${NC}"

if [ ! -f Dockerfile ]; then
  echo -e "${YELLOW}Dockerfile not found here, downloading it from the repository...${NC}"
  BUILD_DIR="$(mktemp -d)"
  trap 'rm -rf "$BUILD_DIR"' EXIT
  if ! curl -fsSL "$REPO_RAW/Dockerfile" -o "$BUILD_DIR/Dockerfile"; then
    echo -e "${YELLOW}Failed to download the Dockerfile.${NC}"
    echo "Clone the repository and run this script from its root instead."
    exit 1
  fi
fi

docker build --build-arg XONOTIC_VERSION="$SERVER_VERSION" -t "$IMAGE" "$BUILD_DIR"

echo -e "${GREEN}[2/4] Writing server config...${NC}"
{
  echo "hostname \"$SERVER_NAME\""
  echo "sv_public $SERVER_PUBLIC"
  if [ -n "$SERVER_PASSWORD" ]; then
    echo "rcon_password \"$SERVER_PASSWORD\""
  fi
} > server.cfg

echo -e "${GREEN}[3/4] Starting server...${NC}"

docker rm -f xonotic-server 2>/dev/null || true

docker run -d \
  --name xonotic-server \
  --restart unless-stopped \
  -p 26000:26000/udp \
  -p 26000:26000 \
  -v "$(pwd)/server.cfg:/opt/Xonotic/data/server.cfg:ro" \
  "$IMAGE" \
  > /dev/null

echo -e "${GREEN}[4/4] Done!${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}         Your Server Is Ready!          ${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

if command -v curl &>/dev/null; then
  PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "localhost")
else
  PUBLIC_IP="your-server-ip"
fi

echo -e "  ${BOLD}Server name:${NC}  $SERVER_NAME"
if [ "$SERVER_PUBLIC" -eq 1 ]; then
  echo -e "  ${BOLD}Public:${NC}       yes (listed on the master server)"
else
  echo -e "  ${BOLD}Public:${NC}       no (only accessible by direct connect)"
fi
echo -e "  ${BOLD}Connect at:${NC}   ${PUBLIC_IP}:26000"
echo ""

echo -e "  To connect:"
echo -e "    1. Open Xonotic"
echo -e "    2. Press ${BOLD}~${NC} key to open console"
echo -e "    3. Type: ${BOLD}connect ${PUBLIC_IP}:26000${NC}"
echo ""

if [ -n "$SERVER_PASSWORD" ]; then
  echo -e "  RCON password: ${BOLD}$SERVER_PASSWORD${NC}"
  echo ""
fi

echo -e "  Commands:"
echo -e "    Stop:      ${BOLD}docker stop xonotic-server${NC}"
echo -e "    Restart:   ${BOLD}docker restart xonotic-server${NC}"
echo -e "    View logs: ${BOLD}docker logs xonotic-server${NC}"
echo -e "    Remove:    ${BOLD}docker rm -f xonotic-server${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Built from Xonotic ${SERVER_VERSION} source    ${NC}"
echo -e "${CYAN}   (GPL-3.0, see Acknowledgments)       ${NC}"
echo -e "${CYAN}========================================${NC}"