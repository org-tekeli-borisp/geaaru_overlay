# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

#PYTHON_REQ_USE=xml
#PYTHON_COMPAT=( python{3_2,3_3,3_4} )

USE_RUBY="ruby22 ruby23"
PYTHON_REQ_USE=xml
PYTHON_COMPAT=( python{3_2,3_3,3_4} )

inherit cmake-utils eutils python


DESCRIPTION="Openshot Library"
HOMEPAGE="http://www.openshot.org/"
SRC_URI="https://launchpad.net/libopenshot/0.0/${PV}/+download/libopenshot-${PV}.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="
	>=media-libs/libopenshot-audio-0.0.6
	dev-lang/swig
	media-gfx/imagemagick
	dev-lang/python
"
RDEPEND="${DEPEND}"

src_unpack() {

	mkdir ${S}
	cd ${S}
	unpack ${A}

}

# vim: ts=4 sw=4
