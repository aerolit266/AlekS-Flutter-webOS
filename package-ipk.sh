#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 ARMV7_PROBE_ARCHIVE OUTPUT_DIRECTORY" >&2
  exit 2
fi

project=$(cd -- "$(dirname -- "$0")" && pwd)
output=$(realpath -m -- "$2")
mkdir -p "$output"
staging=$(mktemp -d)
trap 'rm -rf -- "$staging"' EXIT
tar -xzf "$1" -C "$staging"
(
  cd "$staging"
  sha256sum --strict -c bundle.SHA256SUMS >/dev/null
)
install -m 0644 "$project/ipk/"{appinfo.json,icon.png} "$staging/"
install -m 0755 "$project/run-probe.sh" "$staging/"
(
  cd "$staging"
  find . -type f ! -name bundle.SHA256SUMS -print0 | LC_ALL=C sort -z |
    xargs -0 sha256sum > bundle.SHA256SUMS
  sha256sum --strict -c bundle.SHA256SUMS >/dev/null
)
arm-linux-gnueabi-gcc -std=c11 -Wall -Wextra -Werror -Os -static -s \
  -march=armv7-a -mfpu=neon -mfloat-abi=softfp "$project/ipk/launch.c" \
  -o "$staging/launch"
ares-package --outdir "$output" "$staging"
