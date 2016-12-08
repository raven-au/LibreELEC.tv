################################################################################
#      This file is part of LibreELEC - http://www.libreelec.tv
#      Copyright (C) 2016 Team LibreELEC
#
#  LibreELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  LibreELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with LibreELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

PKG_NAME="uchardet"
PKG_VERSION="0.0.6"
PKG_REV="0"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://cgit.freedesktop.org/uchardet/"
PKG_URL="http://cgit.freedesktop.org/uchardet/uchardet/snapshot/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="multimedia"
PKG_SHORTDESC="uchardet is an encoding detector library."
PKG_LONGDESC="uchardet is an encoding detector library."
PKG_AUTORECONF="no"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=1 \
                       -DCMAKE_INSTALL_PREFIX=$SYSROOT_PREFIX/usr"
