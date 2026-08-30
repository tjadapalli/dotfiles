#!/usr/bin/env bash
# Spin up a throwaway Ubuntu container, run bootstrap.sh inside it, and drop
# you into an interactive zsh shell with the full setup applied. Exiting the
# shell (Ctrl-D / `exit`) tears the container down completely (--rm) — nothing
# persists, so it's safe to run over and over while iterating on the dotfiles.
#
# Usage:
#   ./docker-test.sh                 # ubuntu:24.04
#   ./docker-test.sh 22.04           # test against a different Ubuntu release
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
UBUNTU_TAG="${1:-24.04}"
IMAGE="ubuntu:${UBUNTU_TAG}"

if ! command -v docker >/dev/null 2>&1; then
    echo "docker is required on the host to run this." >&2
    exit 1
fi

echo "==> Building a throwaway dotfiles test image from ${IMAGE}"

# The repo is copied into the image (not bind-mounted) so the container is
# fully self-contained and stow can freely symlink from a stable in-image
# path regardless of how the host directory is mounted.
#
# IMPORTANT: the repo must live one directory *below* $HOME (e.g.
# ~/workspace/dotfiles), never directly at ~/dotfiles. create-stow runs
# `stow -d .. -t ~`, so if the repo's parent directory and the stow target
# were the same path, GNU Stow refuses to do anything (it silently prints
# "skipping target which was current stow directory ." and exits 0 without
# symlinking a single file) — which is exactly what a real checkout at
# ~/workspace/git/.../dotfiles never triggers, so keep that nesting here too.
docker build \
    --pull \
    -f - \
    -t dotfiles-test:latest \
    "$SCRIPT_DIR" <<EOF
FROM ${IMAGE}
RUN apt-get update && apt-get install -y --no-install-recommends sudo && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash tester && echo "tester ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tester
USER tester
WORKDIR /home/tester/workspace/dotfiles
COPY --chown=tester:tester . .
RUN ./bootstrap.sh
WORKDIR /home/tester
EOF

echo "==> Dropping into the container's zsh shell (exit to destroy it)"
exec docker run --rm -it dotfiles-test:latest zsh -l
