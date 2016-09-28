#!/bin/bash
################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2014 Stephan Raue (stephan@openelec.tv)
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

PKG_NAME="${MEDIACENTER,,}"
PKG_VERSION=$PLEX_PMP_BRANCH
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://nightlies.plex.tv"
PKG_URL="$PKG_SITE/directdl/plex-oe-sources/$PKG_NAME-dummy.tar.gz"
PKG_DEPENDS_TARGET="toolchain systemd fontconfig qt5 libcec SDL2 libXdmcp breakpad breakpad:host samba libconnman-qt ${MEDIACENTER,,}-fonts-ttf  fc-cache mpv"
PKG_DEPENDS_HOST="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="mediacenter"
PKG_SHORTDESC="Plex Media Player"
PKG_LONGDESC="Plex is the king or PC clients for Plex :P"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

# Add eventual X11 additionnal deps
if [ "$DISPLAYSERVER" = "x11" ]; then
  PKG_DEPENDS_TARGET+=" libX11 xrandr"
fi

# Cod Options
if [ "${CODECS}" = "yes" ]; then
  COD_OPTIONS_ENABLE="on"
  COD_OPTIONS_DEPFOLDER="plexmediaplayer-openelec-codecs"
  COD_DISABLE_BUNDLE_DEPS="off"
else
  COD_OPTIONS_ENABLE="off"
  COD_DISABLE_BUNDLE_DEPS="on"
fi

# define build type 
if [ "$PLEX_DEBUG" = yes ]; then
  BUILD_TYPE="debug"
else
  BUILD_TYPE="RelWithDebInfo"
fi

# define target type if needed
case $PROJECT in
  RPi|RPi2)
    PMP_BUILD_TARGET="RPI"
  ;;

  WeTek_Hub|Odroid_C2)
    PMP_BUILD_TARGET="AML"
  ;;
esac

# generate debug symbols for this package
# if we want to
DEBUG=$PLEX_DEBUG

# define package cmake
PKG_CMAKE_OPTS_TARGET="-DCMAKE_INSTALL_PREFIX=/usr \
		       -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
		       -DQTROOT=${SYSROOT_PREFIX}/usr/local/qt5 \
		       -DOPENELEC=on \
		       -DBUILD_TARGET=${PMP_BUILD_TARGET} \
		       -DENABLE_CODECS=${COD_OPTIONS_ENABLE} \
		       -DOE_ARCH=${PLEX_CODEC_ARCH} \
		       -DDEPENDCY_FOLDER=${COD_OPTIONS_DEPFOLDER} \
		       -DDISABLE_BUNDLED_DEPS=${COD_DISABLE_BUNDLE_DEPS} \
		       -DDEPENDENCY_TOKEN=${DEPENDENCY_TOKEN} \
		       -DCRASHDUMP_SECRET=${CI_CRASHDUMP_SECRET}"

#we don't want lto
strip_lto

unpack() {
  if [ -d $BUILD/${PKG_NAME}-${PKG_VERSION} ]; then
    cd $BUILD/${PKG_NAME}-${PKG_VERSION} ; rm -rf build
    git pull ; git reset --hard
  else
    rm -rf $BUILD/${PKG_NAME}-${PKG_VERSION}
    git clone --depth 20 -b ${PLEX_PMP_BRANCH} git@github.com:plexinc/${PLEX_PMP_REPO}.git $BUILD/${PKG_NAME}-${PKG_VERSION}
  fi

  cd ${ROOT}	
}

pre_install()
{
 deploy_symbols
}

makeinstall_target() {
 # Build the cmake toolchain file
  cp  $PKG_DIR/toolchain.cmake $ROOT/$PKG_BUILD/
  sed -e "s%@SYSROOT_PREFIX@%$SYSROOT_PREFIX%g" \
      -e "s%@TARGET_PREFIX@%$TARGET_PREFIX%g" \
      -e "s%@PKG_BUILD_DIR@%$ROOT/$PKG_BUILD%g" \
      -e "s%@TARGET_CFLAGS@%$TARGET_CFLAGS%g" \
      -e "s%@TARGET_CXXFLAGS@%$TARGET_CXXFLAGS%g" \
      -e "s%@TARGET_LDFLAGS@%$TARGET_LDFLAGS%g" \
      -e "s%@MAKEFLAGS@%$MAKEFLAGS%g" \
      -e "s%@BUILD_TARGET@%$PMP_BUILD_TARGET%g" \
      -e "s%@COD_OPTIONS_ENABLE@%$COD_OPTIONS_ENABLE%g" \
      -e "s%@COD_OPTIONS_DEPFOLDER@%$COD_OPTIONS_DEPFOLDER%g" \
      -e "s%@COD_DISABLE_BUNDLE_DEPS@%$COD_DISABLE_BUNDLE_DEPS%g" \
      -e "s%@COD_OE_ARCH@%${PLEX_CODEC_ARCH}%g" \
      -e "s%@BUILD_TARGET@%${PMP_BUILD_TARGET}%g" \
      -i $ROOT/$PKG_BUILD/toolchain.cmake

  # deploy files
  mkdir -p $INSTALL/usr/bin
  cp  $ROOT/$PKG_BUILD/.$TARGET_NAME/src/${MEDIACENTER,,} ${INSTALL}/usr/bin/
  cp  $ROOT/$PKG_BUILD/.$TARGET_NAME/src/pmphelper ${INSTALL}/usr/bin/

  mkdir -p $INSTALL/usr/share/${MEDIACENTER,,} $INSTALL/usr/share/${MEDIACENTER,,}/scripts
  cp -R $ROOT/$PKG_BUILD/resources/* ${INSTALL}/usr/share/${MEDIACENTER,,}
  cp $PKG_DIR/scripts/plex_update.sh ${INSTALL}/usr/share/${MEDIACENTER,,}/scripts/
  cp -R $ROOT/$PKG_BUILD/.$TARGET_NAME/web-client* ${INSTALL}/usr/share/${MEDIACENTER,,}/

 debug_strip $INSTALL/usr/bin
}

post_install() {
  # deploy our own cert file
  mkdir -p $INSTALL/etc/ssl/certs
  cp $PKG_DIR/cert/plex-cert.pem $INSTALL/etc/ssl/certs/cert.pem

  # link default.target to plex.target
  ln -sf plex.target $INSTALL/usr/lib/systemd/system/default.target

  # enable default services
  enable_service plex-autostart.service
  enable_service plex.service
  enable_service plex.target
  enable_service plex-waitonnetwork.service
  enable_service plex-prenetwork.service

  #copy out network wait file 
  cp $PKG_DIR/system.d/network_wait $INSTALL/usr/share/plexmediaplayer/

  #echo "Generating pre-fontcache"
  export FONTCONFIG_FILE=$ROOT/$BUILD/image/system/etc/fonts/fonts.conf
  $ROOT/$TOOLCHAIN/bin/fc-cache -fv  -y ${ROOT}/${BUILD}/image/system /usr/share/fonts
}

