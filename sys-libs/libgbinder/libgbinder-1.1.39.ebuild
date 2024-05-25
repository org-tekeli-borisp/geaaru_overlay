# Distributed under the terms of the GNU General Public License v2

EAPI=7
AUTOTOOLS_AUTO_DEPEND="no"

inherit autotools toolchain-funcs

DESCRIPTION="GLib-style interface to binder (Android IPC mechanism)"
HOMEPAGE="https://github.com/mer-hybris/libgbinder"
SRC_URI="https://github.com/mer-hybris/libgbinder/tarball/545f5bc28d8e72f88be21f9e31518a9275cf3a48 -> libgbinder-1.1.39-545f5bc.tar.gz"

LICENSE="BSD-3-Clause"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="sys-libs/libglibutil"
RDEPEND="$DEPEND"

post_src_unpack() {
	mv mer-hybris-libgbinder-* "${S}"
}

src_prepare() {
	default
}

src_compile() {
	emake LIBDIR=/usr/$(get_libdir)
}

src_install() {
	# Using install-dev instead of install
	# to install includes files.
	emake install-dev \
		LIBDIR=/usr/$(get_libdir) \
		DESTDIR="${D}"

	dodir /usr/share/pkgconfig
	insinto /usr/share/pkgconfig
	newins "${S}"/build/${PN}.pc "${PN}.pc"
}