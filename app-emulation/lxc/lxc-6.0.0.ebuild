# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit bash-completion-r1 linux-info meson optfeature systemd

DESCRIPTION="A userspace interface for the Linux kernel containment features"
HOMEPAGE="https://linuxcontainers.org/ https://github.com/lxc/lxc"
SRC_URI="https://github.com/lxc/lxc/tarball/3dee5fb88c6f77496dbcab46f31bcd891c9ee4e0 -> lxc-6.0.0-3dee5fb.tar.gz"

KEYWORDS="*"

LICENSE="GPL-2 LGPL-2.1 LGPL-3"
SLOT="0"
IUSE="apparmor +caps examples io-uring man pam seccomp selinux +ssl systemd +tools +static tools-multicall lto"
RESTRICT="network-sandbox"
RDEPEND="
	sys-libs/libcap
	apparmor? ( sys-libs/libapparmor )
	caps? (
		static? (
			sys-libs/libcap[static-libs]
		)
		!static? (
			sys-libs/libcap
		)
	)
	io-uring? ( >=sys-libs/liburing-2:= )
	pam? ( sys-libs/pam )
	seccomp? ( sys-libs/libseccomp )
	selinux? ( sys-libs/libselinux )
	ssl? ( dev-libs/openssl:0= )
	systemd? ( sys-apps/systemd:= )
	"
DEPEND="${RDEPEND}
	sys-kernel/linux-headers
	apparmor? ( sys-apps/apparmor )"
BDEPEND="virtual/pkgconfig
	=dev-lang/python-3*
	man? ( app-text/docbook2X )
"

CONFIG_CHECK="~!NETPRIO_CGROUP
	~CGROUPS
	~CGROUP_CPUACCT
	~CGROUP_DEVICE
	~CGROUP_FREEZER

	~CGROUP_SCHED
	~CPUSETS
	~IPC_NS
	~MACVLAN

	~MEMCG
	~NAMESPACES
	~NET_NS
	~PID_NS

	~POSIX_MQUEUE
	~USER_NS
	~UTS_NS
	~VETH"

ERROR_CGROUP_FREEZER="CONFIG_CGROUP_FREEZER: needed to freeze containers"
ERROR_MACVLAN="CONFIG_MACVLAN: needed for internal (inter-container) networking"
ERROR_MEMCG="CONFIG_MEMCG: needed for memory resource control in containers"
ERROR_NET_NS="CONFIG_NET_NS: needed for unshared network"
ERROR_POSIX_MQUEUE="CONFIG_POSIX_MQUEUE: needed for lxc-execute command"
ERROR_UTS_NS="CONFIG_UTS_NS: needed to unshare hostnames and uname info"
ERROR_VETH="CONFIG_VETH: needed for internal (host-to-container) networking"

DOCS=( AUTHORS CONTRIBUTING MAINTAINERS README.md doc/FAQ.txt )

pkg_setup() {
	linux-info_pkg_setup
}

src_unpack() {
	unpack ${A}
	mv "${WORKDIR}"/lxc-* "${S}"
}

src_configure() {
	local emesonargs=(
		--localstatedir "${EPREFIX}/var"
		-Dcoverity-build=false
		-Doss-fuzz=false

		-Dcommands=true
		-Dmemfd-rexec=true
		-Dthread-safety=true

		$(meson_use apparmor)
		$(meson_use caps capabilities)
		$(meson_use examples)
		$(meson_use io-uring io-uring-event-loop)
		$(meson_use man)
		$(meson_use pam pam-cgroup)
		$(meson_use seccomp)
		$(meson_use selinux)
		$(meson_use ssl openssl)
		# NOTE: At the moment when b_lto is true
		#       the linking phase of lxc-monitor fails
		#       because the __hidden functions are not visible.
		#       See https://github.com/lxc/lxc/issues/4427
		$(meson_use lto b_lto)
		$(meson_use tools)
		$(meson_use tools-multicall)

		-Ddata-path=/var/lib/lxc
		-Ddoc-path=/usr/share/doc/${PF}
		-Dlog-path=/var/log/lxc
		-Drootfs-mount-path=/var/lib/lxc/rootfs
		-Druntime-path=/run
	)

	if use systemd; then
		emesonargs+=( -Dinit-script="systemd" )
	else
		emesonargs+=( -Dinit-script="sysvinit" )
	fi

	if ! use static ; then
		# b_sanitize option is a specific meson
		# option to select the Code sanitizer to use.
		# Change this option seems break linking of a lot of
		# binaries.
		# I avoid to change the value and just replace the
		# check under meson.build file about lxc-init.static
		# binary.
		sed -e "s|'none'|'false'|g" src/lxc/cmd/meson.build -i
	fi

	use tools && emesonargs+=( -Dcapabilities=true )

	if use tools-multicall ; then
		# Rename main binary to avoid conflicts with lxd
		sed -i -e "s|'lxc'|'lxcmulti'|g" src/lxc/tools/meson.build
	fi

	meson_src_configure
}

src_install() {
	meson_src_install

	# The main bash-completion file will collide with lxd, need to relocate and update symlinks.
	mkdir -p "${ED}"/$(get_bashcompdir) || die "Failed to create bashcompdir."
	# Quiet portage issue
	mv "${ED}"/$(get_bashcompdir)/_lxc "${ED}"/$(get_bashcompdir)/lxc-start

	if use tools; then
		bashcomp_alias lxc-start lxc-{attach,autostart,cgroup,checkpoint,config,console,copy,create,destroy,device,execute,freeze,info,ls,monitor,snapshot,stop,top,unfreeze,unshare,usernsexec,wait}
	else
		if use tools-multicall ; then
			bashcomp_alias lxc-start lxc-{attach,autostart,cgroup,checkpoint,config,console,copy,create,destroy,device,execute,freeze,info,ls,monitor,snapshot,stop,top,unfreeze,unshare,usernsexec,wait}
		else
			bashcomp_alias lxc-start lxc-usernsexec
		fi
	fi

	keepdir /var/lib/cache/lxc /var/lib/lib/lxc

	find "${ED}" -name '*.la' -delete -o -name '*.a' -delete || die

	# Replace upstream sysvinit/systemd files.
	if use systemd; then
		rm -r "${D}$(systemd_get_systemunitdir)" || die "Failed to remove systemd lib dir"
	else
		rm "${ED}"/etc/init.d/lxc-{containers,net} || die "Failed to remove sysvinit scripts"
	fi

	newinitd "${FILESDIR}/${PN}.initd" ${PN}

	if use systemd ; then
		systemd_newunit "${FILESDIR}"/5/lxc-monitord.service lxc-monitord.service
		systemd_newunit "${FILESDIR}"/5/lxc-net.service lxc-net.service
		systemd_newunit "${FILESDIR}"/5/lxc.service lxc.service
		systemd_newunit "${FILESDIR}"/5/lxc_at.service "lxc@.service"

		if ! use apparmor ; then
			sed -i '/lxc-apparmor-load/d' "${D}$(systemd_get_systemunitdir)/lxc.service" || die "Failed to remove apparmor references from lxc.service systemd unit."
		fi
	fi
}

pkg_postinst() {
	elog
	elog "Run 'lxc-checkconfig' to see optional kernel features."
	elog

	optfeature "automatic template scripts" app-containers/lxc-templates
	optfeature "Debian-based distribution container image support" dev-util/debootstrap
	optfeature "snapshot & restore functionality" sys-process/criu
}