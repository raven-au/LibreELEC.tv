################################################################################
#
##  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  #  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#  #
#  This Program is distributed in the hope that it will be useful,
#  #  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  #  GNU General Public License for more details.
#
##  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  #  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
#  ################################################################################

PKG_NAME="qt5"
PKG_VERSION="5.7.0-beta"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://nightlies.plex.tv"
PKG_URL="$PKG_SITE/directdl/plex-oe-sources/qt-everywhere-opensource-src-$PKG_VERSION.tar.gz"
PKG_SOURCE_DIR="qt-everywhere-opensource-src-${PKG_VERSION}"
PKG_PRIORITY="optional"
PKG_SECTION="lib"
PKG_SHORTDESC="Qt GUI toolkit"
PKG_LONGDESC="Qt GUI toolkit"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

PKG_BASE_DEPENDS_TARGET="curl bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig glibc flex bison ruby libdrm atk"
PKG_BASE_BUILD_DEPENDS_TARGET="bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig libressl linux-headers glibc pulseaudio"

# determine QPA related packages
if [ "$DISPLAYSERVER" = "x11" ]; then
  PKG_QT_QPA="libXcursor libXtst nss libxkbcommon pciutils libXi libXScrnSaver"
elif [ ! "$OPENGLES" = "no" ]; then
  PKG_QT_QPA="$OPENGLES libevdev libwebp"
fi

# Combine packages
PKG_DEPENDS_TARGET="$PKG_BASE_DEPENDS_TARGET $PKG_QT_AUDIO $PKG_QT_QPA"
PKG_BASE_BUILD_DEPENDS_TARGET="$PKG_DEPENDS_TARGET"

# Configure the device option
QT_MKSPECS_DEVICE="linux-${PROJECT}-g++"

# Define Qt build base options
QT_BASE_OPTS="	-sysroot ${SYSROOT_PREFIX} \
		-prefix /usr/local/qt5 \
		-hostprefix ${ROOT}/${BUILD} \
		-device-option CROSS_COMPILE=${TARGET_PREFIX} \
		-device ${QT_MKSPECS_DEVICE} \
		-release -v -opensource \
		-confirm-license \
		-shared \
		-make libs \
		-no-pch \
		-no-icu \
		-qt-xkbcommon \
		-no-sql-sqlite2 \
		-nomake examples \
		-nomake tests \
		-no-libjpeg"
				
		
# Define Qt QPA options
case $PROJECT in
  Generic)
  # X11 configuration
  QT_QPA_OPTS="-qpa xcb -opengl desktop -no-kms -no-directfb -qt-xcb"
  ;;
  RPi|RPi2)

  # OpenGLES configuration
  QT_QPA_OPTS="-qpa eglfs -opengl es2 -no-kms -no-directfb -no-xcb"
  ;;
esac

PKG_CONFIGURE_OPTS="${QT_BASE_OPTS} ${QT_QPA_OPTS} ${QT_MODULES_CONFIG} ${QT_EXTRA_FLAGS}"

configure_target() {
  # QT looks for certificates in /usr/lib/ssl, so we make a link there
  mkdir -p $INSTALL/usr/lib/ssl
  ln -sf /etc/ssl/cert.pem $INSTALL/usr/lib/ssl/cert.pem
  
  # Deploy the MKSPECS files for target
  if [ -d "${PKG_DIR}/mkspecs/${PROJECT}" ]; then
    mkdir -p $ROOT/$PKG_BUILD/qtbase/mkspecs/devices/$QT_MKSPECS_DEVICE
    cp -R ${PKG_DIR}/mkspecs/${PROJECT}/* $ROOT/$PKG_BUILD/qtbase/mkspecs/devices/$QT_MKSPECS_DEVICE/
  fi 

  # Add HW jpeg decoding
  if [ -d "${PKG_DIR}/patches/${PROJECT}" ]; then
    cp -R $PKG_DIR/patches/${PROJECT}/* ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}/qtwebengine/src/3rdparty/chromium/third_party/WebKit/Source/platform/image-decoders/

    case $PROJECT in
      RPi|RPi2)
        cp $SYSROOT_PREFIX/usr/include/interface/vcos/pthreads/vcos_platform_types.h $SYSROOT_PREFIX/usr/include/interface/vcos/
        cp $SYSROOT_PREFIX/usr/include/interface/vcos/pthreads/vcos_platform.h $SYSROOT_PREFIX/usr/include/interface/vcos/
        cp $SYSROOT_PREFIX/usr/include/interface/vmcs_host/linux/vchost_config.h $SYSROOT_PREFIX/usr/include/interface/vmcs_host/
      ;;
    esac
  fi

  # Undefines compiler options
  unset CC CXX AR OBJCOPY STRIP CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LD RANLIB
  export QT_FORCE_PKGCONFIG=yes
  unset QMAKESPEC

  cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
  ./configure ${PKG_CONFIGURE_OPTS}
}

makeinstall_target() {
  # deploy to SYSROOT
  cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
  make install DESTDIR=${SYSROOT_PREFIX}/usr/local/qt5

  # Copy over to INSTALL directory
  mkdir -p $INSTALL/usr/local/qt5/
  cp -Rf ${SYSROOT_PREFIX}/usr/local/qt5/* ${INSTALL}/usr/local/qt5/

  #cleanup the plugins
  rm -rf  ${INSTALL}/usr/local/qt5/doc
  rm -rf  ${INSTALL}/usr/local/qt5/bin
  rm -rf  ${INSTALL}/usr/local/qt5/include

  case $PROJECT in
    Generic|Nvidia_Legacy)
    ;;
    RPi|RPi2)
      rm -f  ${INSTALL}/usr/local/qt5/plugins/generic/libqevdevtabletplugin.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/generic/llibqevdevtouchplugin.so

      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqdds.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqgif.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqicns.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqico.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqjp2.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqmng.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqtga.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqtiff.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqwbmp.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/imageformats/libqwebp.so
            rm -f ${INSTALL}/usr/local/qt5/plugins/imageformats/libqjpeg*

      rm -f  ${INSTALL}/usr/local/qt5/plugins/platforms/libqlinuxfb.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/platforms/libqminimal.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/platforms/libqminimalegl.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/platforms/libqoffscreen.so
      rm -f  ${INSTALL}/usr/local/qt5/plugins/platforms/libqxcb.so
      rm -f ${INSTALL}/usr/local/qt5/plugins/imageformats/libqjpeg*
    ;;
  esac

  #restore strip value
  STRIP=$TARGET_STRIP
  debug_strip ${INSTALL}/usr/local/qt5/
}


pre_install()
{
 deploy_symbols qt
}

