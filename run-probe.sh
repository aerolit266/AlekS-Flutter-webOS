#!/bin/sh
set -eu
if [ "$#" -gt 1 ]; then
  echo "Usage: $0 [--headless|--smoke|--self-test]" >&2
  exit 2
fi
stage=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
cd "$stage"
if ! checks=$(sha256sum -c bundle.SHA256SUMS); then
  printf '%s\n' "$checks" >&2
  exit 1
fi
umask 077
state=$(mktemp -d /tmp/aleks-flutter6-run.XXXXXXXX)
trap 'rm -rf -- "$state"' EXIT
mkdir "$state/font-cache"
printf '<fontconfig><dir>%s/fonts</dir><cachedir>%s/font-cache</cachedir></fontconfig>\n' \
  "$stage" "$state" > "$state/fonts.conf"
export FONTCONFIG_FILE="$state/fonts.conf"
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
unset LD_PRELOAD LD_LIBRARY_PATH
timeout -t 55 ./runtime/ld-linux.so.3 --inhibit-cache \
  --library-path "$stage/runtime:$stage/lib:/lib:/usr/lib" \
  ./flutter-webos6-probe "$stage/flutter_assets" "$stage/lib/icudtl.dat" \
  "$stage/app-softfp.so" "$@"
