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

PKG_NAME="conan"
PKG_VERSION="0.15.0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://conan.io"
PKG_URL="https://github.com/conan-io/conan/archive/release/$PKG_VERSION.tar.gz"
PKG_SOURCE_DIR="conan-release-$PKG_VERSION"
PKG_DEPENDS_HOST="toolchain Python:host setuptools:host"
PKG_PRIORITY="optional"
PKG_SECTION="system"
PKG_SHORTDESC="Conan.io - The open-source C/C++ package manager"
PKG_LONGDESC="Conan.io - The open-source C/C++ package manager"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

make_host() {
 : # nothing todo
}

makeinstall_host() {
  python setup.py install --prefix=$ROOT/$TOOLCHAIN
}

pre_make_target() {
  export PYTHONXCPREFIX="$SYSROOT_PREFIX/usr"
  export LDSHARED="$CC -shared"
}

make_target() {
  python setup.py build
}

makeinstall_target() {
  python setup.py install --root=$INSTALL --prefix=/usr
}
