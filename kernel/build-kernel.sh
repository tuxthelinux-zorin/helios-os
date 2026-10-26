#!/bin/bash
# Builds the Helios kernel as Debian packages (linux-image-<release>, linux-headers-<release>).
# Run on Debian 13 as root (or in a debian:trixie container). Needs internet unless KERNEL_TARBALL is set.
# Takes 1-3 hours on a 4-core machine.
#
#   KVER=7.3                  kernel.org version to download (default 7.3)
#   KERNEL_TARBALL=/path.tar.xz   use a local source tarball instead of downloading
#   DEBIAN_CONFIG_VER=6.12    which Debian kernel config to start from (trixie ships 6.12)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
KVER="${KVER:-7.3}"
CFGVER="${DEBIAN_CONFIG_VER:-6.12}"
OUT="${OUT:-$PWD/kernel-out}"
WORK="${WORK:-/tmp/helios-kernel-build}"

apt-get update
apt-get install -y --no-install-recommends build-essential bc bison flex libssl-dev libelf-dev \
  dwarves rsync kmod cpio debhelper fakeroot curl xz-utils ca-certificates
apt-get install -y --no-install-recommends "linux-config-${CFGVER}" || echo "WARNING: no Debian config package; falling back to defconfig (may not boot all hardware)"

rm -rf "$WORK"; mkdir -p "$OUT" "$WORK"; cd "$WORK"
if [ -n "${KERNEL_TARBALL:-}" ]; then
  tar -xf "$KERNEL_TARBALL"
else
  curl -fsSLO "https://cdn.kernel.org/pub/linux/kernel/v${KVER%%.*}.x/linux-${KVER}.tar.xz"
  tar -xf "linux-${KVER}.tar.xz"
fi
cd "$(ls -d linux-*/ | head -1)"

for p in "$HERE"/patches/*.patch; do
  [ -e "$p" ] && { echo "applying $p"; patch -p1 < "$p"; }
done

CFG="$(ls /usr/src/linux-config-${CFGVER}/config.amd64_none_amd64.xz 2>/dev/null || true)"
if [ -n "$CFG" ]; then xzcat "$CFG" > .config; else make defconfig; fi
scripts/kconfig/merge_config.sh -m .config "$HERE/helios.fragment"
make olddefconfig

RELEASE="$(make -s kernelrelease)"
echo "Building kernel release: $RELEASE"
make -j"$(nproc)" bindeb-pkg KDEB_PKGVERSION="${KVER}-1helios1"

cd "$WORK"
rm -f ./*-dbg_*.deb
cp ./linux-image-*.deb ./linux-headers-*.deb "$OUT"/
echo "$RELEASE" > "$OUT/KERNELRELEASE"
echo "Built packages in $OUT:"; ls -lh "$OUT"
