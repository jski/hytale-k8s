#!/usr/bin/env bash
set -euo pipefail

TOOL_URL="https://downloader.hytale.com/hytale-downloader.zip"
TOOL_BIN="hytale-downloader-linux-amd64"
WORK_DIR="/work"
OUTPUT_DIR="/output"

mkdir -p "${WORK_DIR}" "${OUTPUT_DIR}"

curl -fsSL "${TOOL_URL}" -o "${WORK_DIR}/hytale-downloader.zip"
unzip -oq "${WORK_DIR}/hytale-downloader.zip" -d "${WORK_DIR}"
chmod +x "${WORK_DIR}/${TOOL_BIN}"

cd "${OUTPUT_DIR}"
"${WORK_DIR}/${TOOL_BIN}"
