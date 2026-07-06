#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.6.2}"
GODOT_RELEASE="${GODOT_RELEASE:-stable}"
GODOT_PLATFORM="linux.x86_64"
GODOT_ARCHIVE="Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_${GODOT_PLATFORM}.zip"
GODOT_BINARY="Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_${GODOT_PLATFORM}"
GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/${GODOT_ARCHIVE}"

BIN_DIR="${GODOT_BIN_DIR:-${HOME}/.local/bin}"
CACHE_DIR="${GODOT_CACHE_DIR:-${XDG_CACHE_HOME:-${HOME}/.cache}/godot}"
INSTALL_DIR="${GODOT_INSTALL_DIR:-${HOME}/.local/share/godot/${GODOT_VERSION}-${GODOT_RELEASE}}"
ARCHIVE_PATH="${CACHE_DIR}/${GODOT_ARCHIVE}"
TARGET="${BIN_DIR}/godot"

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
  echo "Godot ${GODOT_VERSION} setup is intended for Codex Linux x86_64 containers; skipping on $(uname -s) $(uname -m)."
  exit 0
fi

if command -v godot >/dev/null 2>&1; then
  GODOT_VERSION_OUTPUT="$(godot --version 2>/dev/null || true)"
  if [[ "${GODOT_VERSION_OUTPUT}" == "${GODOT_VERSION}.${GODOT_RELEASE}"* ]]; then
    echo "Godot ${GODOT_VERSION} is already available at $(command -v godot)."
    exit 0
  fi
fi

mkdir -p "${BIN_DIR}" "${CACHE_DIR}" "${INSTALL_DIR}"

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
  echo "Downloading Godot ${GODOT_VERSION} headless-capable Linux binary..."
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --retry 3 --output "${ARCHIVE_PATH}" "${GODOT_URL}"
  elif command -v wget >/dev/null 2>&1; then
    wget --tries=3 --output-document="${ARCHIVE_PATH}" "${GODOT_URL}"
  else
    echo "Neither curl nor wget is installed; cannot download Godot." >&2
    exit 1
  fi
fi

python3 - "${ARCHIVE_PATH}" "${INSTALL_DIR}" "${GODOT_BINARY}" <<'PY'
import sys
import zipfile
from pathlib import Path

archive = Path(sys.argv[1])
install_dir = Path(sys.argv[2])
binary_name = sys.argv[3]
binary_path = install_dir / binary_name

if not binary_path.exists():
    with zipfile.ZipFile(archive) as zf:
        zf.extractall(install_dir)

if not binary_path.exists():
    raise SystemExit(f"Expected Godot binary was not extracted: {binary_path}")
PY

chmod +x "${INSTALL_DIR}/${GODOT_BINARY}"
ln -sf "${INSTALL_DIR}/${GODOT_BINARY}" "${TARGET}"

if ! grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "${HOME}/.bashrc"; then
  printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "${HOME}/.bashrc"
fi

"${TARGET}" --headless --version
echo "Godot ${GODOT_VERSION} is installed at ${TARGET}."
