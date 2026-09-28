#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

if [ ! -f build/.env ]; then
    cp build/.env.example build/.env
fi

set -a
. ./build/.env
set +a

if [ -z "${NEW_API_VERSION:-}" ]; then
    NEW_API_VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo dev)
fi
if [ -z "${GIT_COMMIT:-}" ]; then
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || true)
fi
if [ -z "${BUILD_DATE:-}" ]; then
    BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
fi
if [ -z "${SOURCE_URL:-}" ]; then
    SOURCE_URL=$(git remote get-url origin 2>/dev/null || true)
fi
if [ -z "${POSTGRES_PASSWORD:-}" ]; then
    echo "POSTGRES_PASSWORD is empty. Set it in build/.env, then run this script again." >&2
    exit 1
fi
export NEW_API_VERSION GIT_COMMIT BUILD_DATE SOURCE_URL POSTGRES_PASSWORD

command=${1:-deploy}
shift || true

case "$command" in
    deploy)
        docker compose --env-file build/.env -f build/compose.yaml up -d --build "$@"
        ;;
    rebuild)
        docker compose --env-file build/.env -f build/compose.yaml build --no-cache new-api
        docker compose --env-file build/.env -f build/compose.yaml up -d --no-build new-api
        ;;
    restart)
        docker compose --env-file build/.env -f build/compose.yaml restart new-api
        ;;
    stop)
        docker compose --env-file build/.env -f build/compose.yaml stop new-api
        ;;
    logs)
        docker compose --env-file build/.env -f build/compose.yaml logs -f new-api
        ;;
    down)
        docker compose --env-file build/.env -f build/compose.yaml down "$@"
        ;;
    reset-data)
        docker compose --env-file build/.env -f build/compose.yaml down -v
        ;;
    status)
        docker compose --env-file build/.env -f build/compose.yaml ps
        docker inspect new-api-build \
            --format 'Health: {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}  Version: {{index .Config.Labels "org.opencontainers.image.version"}}  Commit: {{index .Config.Labels "org.opencontainers.image.revision"}}' \
            2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 [deploy|rebuild|restart|stop|logs|down|reset-data|status]" >&2
        echo "Extra arguments are passed to Compose." >&2
        exit 1
        ;;
esac
