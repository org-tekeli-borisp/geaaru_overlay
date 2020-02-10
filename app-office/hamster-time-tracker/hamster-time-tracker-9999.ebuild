# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

PYTHON_COMPAT=( python{2_7,3_6,3_7} )
PYTHON_REQ_USE="threads(+)"
DISTUTILS_SINGLE_IMPL=1

inherit git-r3 distutils-r1 waf-utils xdg-utils

DESCRIPTION="Time tracking for the masses"
HOMEPAGE="http://projecthamster.wordpress.com"
EGIT_REPO_URI="https://github.com/projecthamster/hamster.git"
#EGIT_REPO_URI="https://github.com/gsobczyk/hamster.git"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND="
	dev-python/gconf-python
	gnome-base/gconf[introspection]
	dev-python/pyxdg
	dev-python/jira[kerberos]
	dev-python/beaker[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}
	dev-util/intltool"

src_unpack() {
	git-r3_src_unpack
}

src_prepare() {
	# Fix python2 legacy
	sed -i -e 's:python2:python:g' po/wscript || die "Error on fix wscript"
	sed -i -e 's:python2:python:g' setup.py || die "Error on fix setup.py"
	# Disable update of the icon cache. I will do it directly.
	sed -i -e 's:bld.add_post_fun:#bld.add_post_fun:g' wscript || die "Error on block update of the icons cache"
	python_fix_shebang .
	distutils-r1_src_prepare
}

src_configure() {
	local mywafconfargs=(
		--prefix=/usr
		--datadir=/usr/share
	)
	waf-utils_src_configure ${mywafconfargs[@]}
}

src_install() {
	waf-utils_src_install
	dosym /usr/bin/hamster /usr/bin/hamster-service

	rm -rf ${D}/usr/share/glib-2.0/ || die "Error on remove glib-2.0 schemas"
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
