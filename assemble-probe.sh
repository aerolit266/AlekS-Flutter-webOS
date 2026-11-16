#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 7 ]; then
  echo "Usage: $0 OUTPUT_TAR PROBE APP_BUILD_DIR ENGINE_SO ICU_DATA ARMEL_RUNTIME_DIR FONT_TTF" >&2
  exit 2
fi
output=$(realpath -m -- "$1")
project=$(cd -- "$(dirname -- "$0")" && pwd)
staging=$(mktemp -d)
trap 'rm -rf -- "$staging"' EXIT

install -D -m 0755 "$2" "$staging/flutter-webos6-probe"
install -D -m 0755 "$project/run-probe.sh" "$staging/run-probe.sh"
install -D -m 0644 "$3/app-softfp.so" "$staging/app-softfp.so"
cp -R -- "$3/flutter_assets" "$staging/"
install -D -m 0644 "$4" "$staging/lib/libflutter_engine.so"
install -D -m 0644 "$5" "$staging/lib/icudtl.dat"
install -D -m 0644 "$7" "$staging/fonts/probe.ttf"
mkdir "$staging/runtime"
for library in ld-linux.so.3 libc.so.6 libm.so.6 libdl.so.2 libpthread.so.0 librt.so.1 libgcc_s.so.1; do
  cp -L -- "$6/$library" "$staging/runtime/"
done
chmod 0755 "$staging/runtime/ld-linux.so.3"

cd "$staging"
find . -type f ! -name bundle.SHA256SUMS -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > bundle.SHA256SUMS
sha256sum -c bundle.SHA256SUMS >/dev/null
tar -czf "$output" .
