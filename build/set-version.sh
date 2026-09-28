#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <version>" >&2
    exit 1
fi

version=$1
case "$version" in
    *[![:alnum:]._-]* | '' | .* | *.)
        echo "Invalid version: $version" >&2
        exit 1
        ;;
esac

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

if [ ! -f build/.env ]; then
    cp build/.env.example build/.env
fi

printf '%s\n' "$version" > VERSION
if grep -q '^NEW_API_VERSION=' build/.env; then
    sed -i "s/^NEW_API_VERSION=.*/NEW_API_VERSION=$version/" build/.env
else
    printf '\nNEW_API_VERSION=%s\n' "$version" >> build/.env
fi
