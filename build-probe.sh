#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 FLUTTER_HEADER_DIR SDL_HEADER_DIR ARM_SDL_LIBRARY ENGINE_LIBRARY" >&2
  exit 2
fi
project=$(cd -- "$(dirname -- "$0")" && pwd)
build_dir=${BUILD_DIR:-"$project/build"}
mkdir -p "$build_dir"
arm-linux-gnueabi-gcc -std=c11 -Wall -Wextra -Werror -O2 \
  -march=armv7-a -mfpu=neon -mfloat-abi=softfp \
  -I "$1" -I "$2" -Wl,--allow-shlib-undefined -Wl,-z,now \
  -Wl,-rpath,'$ORIGIN/lib' "$project/embedder.c" "$3" "$4" -pthread \
  -o "$build_dir/flutter-webos6-probe"
