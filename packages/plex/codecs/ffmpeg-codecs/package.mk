################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
#
#  OpenELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  OpenELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

PKG_NAME="ffmpeg-codec"
PKG_VERSION="konvergo-codecs"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="LGPLv2.1+"
PKG_SITE="https://nightlies.plex.tv"
PKG_URL="$PKG_SITE/directdl/plex-oe-sources/mpv-pmp-deps-dummy.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="service/multimedia"
PKG_SHORTDESC="Special ffmpeg sauce"
PKG_LONGDESC="Special ffmpeg sauce"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"


case $PROJECT in
  Generic)
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libva-intel-driver libvdpau"
  ;;
esac

unpack() {
  # Create build dir
  BUILD_DIR="${BUILD}/${PKG_NAME}-${PKG_VERSION}"
  if [ ! -d ${BUILD_DIR} ]; then
    mkdir -p ${BUILD_DIR} 
  fi

  # Set variables for downloads
  BUILD_TAG="linux-openelec-$PLEX_CODEC_ARCH"
  DEPS_FILE="konvergo-codecs-depends-$BUILD_TAG-release-$PLEX_CODEC_HASH.tbz2"
  DEPS_URL="$PKG_SITE/directdl/${DEPENDENCY_TOKEN}/plexmediaplayer-openelec-codecs/$PLEX_CODEC_VERSION/$DEPS_FILE"

  echo "Downloading Deps from $DEPS_URL to $BUILD_DIR"
  wget -q ${DEPS_URL} -P ${BUILD_DIR}
  FILE_HASH="`curl -s ${DEPS_URL}.sha.txt`"

  echo "Checking file hash"
  # Check file hash
  if [ "`sha1sum ${BUILD_DIR}/${DEPS_FILE} |awk '{print $1}'`" = "${FILE_HASH}" ]; then
    tar xjf ${BUILD_DIR}/${DEPS_FILE} -C ./${BUILD_DIR} --wildcards --no-anchored 'lib*so*' 'lib*pc' '*h' --exclude='*lib/components/*' --strip=1
    rm -f ${BUILD_DIR}/${DEPS_FILE}
    echo "Hash matched and files extracted"
  else
    exit 1
  fi
}

configure_target() {
  : # nothin to do here
}
make_target() {
  : # nothing to do here
}

makeinstall_target() {
  cp -R lib/* ${SYSROOT_PREFIX}/usr/lib/
  cp -R include ${SYSROOT_PREFIX}/usr/

  echo $INSTALL

  mkdir -p $INSTALL/usr/lib
  cp -R lib/lib* ${INSTALL}/usr/lib/
}
