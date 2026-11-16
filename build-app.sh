#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 FLUTTER_EXECUTABLE LG_ARMV7_GEN_SNAPSHOT" >&2
  exit 2
fi
flutter=$(realpath -- "$1")
snapshot=$(realpath -- "$2")
project=$(cd -- "$(dirname -- "$0")" && pwd)
output=${BUILD_DIR:-"$project/build"}
mkdir -p "$output"
output=$(realpath -- "$output")

stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
cp "$project/smoke/pubspec.yaml" "$stage/"
cp -R "$project/smoke/lib" "$stage/"
cd "$stage"
"$flutter" pub get
"$flutter" analyze
"$flutter" build bundle --release --target-platform linux-x64 --asset-dir "$output/flutter_assets"
"$flutter" assemble --output="$stage/kernel" -dBuildMode=release \
  -dTargetPlatform=linux-x64 -dTargetFile=lib/main.dart kernel_snapshot_program
mapfile -t kernels < <(find .dart_tool/flutter_build -type f -name app.dill)
if [ "${#kernels[@]}" -ne 1 ]; then
  echo "Expected one release app.dill in the clean build directory" >&2
  exit 1
fi
dill=${kernels[0]}
"$snapshot" --deterministic --no-sim-use-hardfp --no-use-integer-division \
  --snapshot_kind=app-aot-elf --elf="$output/app-softfp.so" "$dill"
export LC_ALL=C
flags=$(readelf -h "$output/app-softfp.so")
grep -q 'ELF32' <<<"$flags"
grep -q 'Machine:.*ARM' <<<"$flags"
grep -q 'soft-float ABI' <<<"$flags"
printf 'ARMv7 softfp AOT: %s\n' "$output/app-softfp.so"
