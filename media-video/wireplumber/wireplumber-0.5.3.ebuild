# Distributed under the terms of the GNU General Public License v2

EAPI=7

LUA_COMPAT=( lua5-{1,3} )

inherit lua-single meson systemd user

SRC_URI="https://github.com/PipeWire/wireplumber/tarball/65e4ae83b994616401fc5859e00d5051b72518ba -> wireplumber-0.5.3-65e4ae8.tar.gz"
KEYWORDS="*"
DESCRIPTION="Session and policy manager for Pipewire"
HOMEPAGE="https://gitlab.freedesktop.org/pipewire/wireplumber"

LICENSE="MIT"
SLOT="0"
IUSE="elogind systemd test"

REQUIRED_USE="
	${LUA_REQUIRED_USE}
	?? ( elogind systemd )
"

BDEPEND="
	dev-libs/glib
	dev-util/gdbus-codegen
	dev-util/glib-utils
	sys-devel/gettext
	test? ( sys-apps/dbus )
"

DEPEND="
	${LUA_DEPS}
	>=dev-libs/glib-2.62
	>=media-video/pipewire-0.3.68:=
	virtual/libintl
	elogind? ( sys-auth/elogind )
	systemd? ( sys-apps/systemd )
"
RDEPEND="${DEPEND}"

DOCS=( {NEWS,README}.rst )

pkg_setup() {
	lua-single_pkg_setup

	enewgroup pipewire
	enewuser pipewire -1 -1 /var/run/pipewire "pipewire,audio"
}

post_src_unpack() {
	mv PipeWire-wireplumber-* "${S}"
}

src_configure() {
	local emesonargs=(
		-Ddaemon=true
		-Dtools=true
		-Dmodules=true
		-Ddoc=disabled
		-Dintrospection=disabled # Only used for Sphinx doc generation
		-Dsystem-lua=true # We always unbundle everything we can
		-Dsystem-lua-version=$(ver_cut 1-2 $(lua_get_version))
		$(meson_feature elogind)
		$(meson_feature systemd)
		$(meson_use systemd systemd-system-service)
		$(meson_use systemd systemd-user-service)
		-Dsystemd-system-unit-dir=$(systemd_get_systemunitdir)
		-Dsystemd-user-unit-dir=$(systemd_get_userunitdir)
		-Dtests=false
		-Ddbus-tests=false
	)

	meson_src_configure
}

# vim: ft=ebuild