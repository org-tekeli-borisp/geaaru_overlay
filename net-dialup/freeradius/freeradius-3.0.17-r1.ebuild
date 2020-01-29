# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=7

PYTHON_COMPAT=( python{2_7} )
inherit autotools pam python-single-r1 systemd

MY_P="${PN}-server-${PV}"

DESCRIPTION="Highly configurable free RADIUS server"
SRC_URI="
	ftp://ftp.freeradius.org/pub/radius/${MY_P}.tar.gz
	ftp://ftp.freeradius.org/pub/radius/old/${MY_P}.tar.gz
"
HOMEPAGE="http://www.freeradius.org/"

KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
LICENSE="GPL-2"
SLOT="0"

IUSE="
	debug firebird iodbc kerberos ldap libressl mysql odbc oracle pam pcap
	postgres python readline sqlite ssl redis memcache
"
RESTRICT="test firebird? ( bindist )"

RDEPEND="acct-group/radius
	acct-user/radius
	!net-dialup/cistronradius
	sys-devel/libtool
	dev-lang/perl:=
	sys-libs/gdbm
	sys-libs/talloc
	python? ( ${PYTHON_DEPS} )
	readline? ( sys-libs/readline:0= )
	pcap? ( net-libs/libpcap )
	mysql? ( dev-db/mysql-connector-c )
	postgres? ( dev-db/postgresql:= )
	firebird? ( dev-db/firebird )
	pam? ( sys-libs/pam )
	ssl? (
		!libressl? ( dev-libs/openssl:0= )
		libressl? ( dev-libs/libressl:0= )
	)
	ldap? ( net-nds/openldap )
	kerberos? ( virtual/krb5 )
	sqlite? ( dev-db/sqlite:3 )
	odbc? ( dev-db/unixODBC )
	iodbc? ( dev-db/libiodbc )
	redis? ( dev-db/redis )
	memcache? ( dev-libs/libmemcached )
	oracle? ( dev-db/oracle-instantclient-basic )"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	${FILESDIR}/freeradius-3.0.14-proxy-timestamp.patch
)

pkg_setup() {
	if use python ; then
		python-any-r1_pkg_setup
		export PYTHONBIN="${EPYTHON}"
	fi
}

src_prepare() {
	# most of the configuration options do not appear as ./configure
	# switches. Instead it identifies the directories that are available
	# and run through them. These might check for the presence of
	# various libraries, in which case they are not built.  To avoid
	# automagic dependencies, we just remove all the modules that we're
	# not interested in using.

	eapply_user

	use ssl || { rm -r src/modules/rlm_eap/types/rlm_eap_{tls,ttls,peap} || die ; }
	use ldap || { rm -r src/modules/rlm_ldap || die ; }
	use kerberos || { rm -r src/modules/rlm_krb5 || die ; }
	use pam || { rm -r src/modules/rlm_pam || die ; }
	use python || { rm -r src/modules/rlm_python || die ; }
	# Do not install ruby rlm module, bug #483108
	rm -r src/modules/rlm_ruby || die

	# these are all things we don't have in portage/I don't want to deal
	# with myself
	rm -r src/modules/rlm_eap/types/rlm_eap_tnc || die # requires TNCS library
	rm -r src/modules/rlm_eap/types/rlm_eap_ikev2 || die # requires libeap-ikev2
	rm -r src/modules/rlm_opendirectory || die # requires some membership.h

	if ! use redis ; then
		rm -r src/modules/rlm_redis{,who} # requires redis
	fi
	rm -r src/modules/rlm_sql/drivers/rlm_sql_{db2,freetds} || die

	# sql drivers that are not part of experimental are loaded from a
	# file, so we have to remove them from the file itself when we
	# remove them.
	usesqldriver() {
		local flag=$1
		local driver=rlm_sql_${2:-${flag}}

		if ! use ${flag}; then
			rm -r src/modules/rlm_sql/drivers/${driver} || die
			sed -i -e /${driver}/d src/modules/rlm_sql/stable || die
		fi
	}

	sed -i \
		-e 's:^#\tuser = :\tuser = :g' \
		-e 's:^#\tgroup = :\tgroup = :g' \
		-e 's:/var/run/radiusd:/run/radiusd:g' \
		-e '/^run_dir/s:${localstatedir}::g' \
		raddb/radiusd.conf.in || die

	# verbosity
	# build shared libraries using jlibtool --shared
	sed -i \
		-e '/$(LIBTOOL)/s|--quiet ||g' \
		-e 's:--mode=\(compile\|link\):& --shared:g' \
		Make.inc.in || die

	sed -i \
		-e 's|--silent ||g' \
		-e 's:--mode=\(compile\|link\):& --shared:g' \
		scripts/libtool.mk || die

	# crude measure to stop jlibtool from running ranlib and ar
	sed -i \
		-e '/LIBRARIAN/s|".*"|"true"|g' \
		-e '/RANLIB/s|".*"|"true"|g' \
		scripts/jlibtool.c || die

	usesqldriver mysql
	usesqldriver postgres postgresql
	usesqldriver firebird
	usesqldriver iodbc
	usesqldriver odbc unixodbc
	usesqldriver oracle
	usesqldriver sqlite

	default

	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--enable-shared
		--disable-static
		--disable-ltdl-install
		--with-system-libtool
		--with-system-libltdl
		--with-ascend-binary
		--with-udpfromto
		--with-dhcp
		--with-iodbc-include-dir=/usr/include/iodbc
		--with-experimental-modules
		--with-docdir=/usr/share/doc/${PF}
		--with-logdir=/var/log/radius
		$(use_enable debug developer)
		$(use_with ldap edir)
		$(use_with ssl openssl)
	)

	# fix bug #77613
	if has_version app-crypt/heimdal; then
		myeconfargs+=( --enable-heimdal-krb5 )
	fi

	use readline || export ac_cv_lib_readline=no
	use pcap || export ac_cv_lib_pcap_pcap_open_live=no

	# do not try to enable static with static-libs; upstream is a
	# massacre of libtool best practices so you also have to make sure
	# to --enable-shared explicitly.
	econf "${myeconfargs[@]}"
}

src_compile() {
	# verbose, do not generate certificates
	emake \
		Q='' ECHO=true \
		LOCAL_CERT_PRODUCTS=''
}

src_install() {
	dodir /etc
	diropts -m0750 -o root -g radius
	dodir /etc/raddb
	diropts -m0750 -o radius -g radius
	dodir /var/log/radius
	keepdir /var/log/radius/radacct
	diropts

	# verbose, do not install certificates
	emake -j1 \
		Q='' ECHO=true \
		LOCAL_CERT_PRODUCTS='' \
		R="${D}" \
		install

	fowners -R radius:radius /etc/raddb
	fowners -R radius:radius /var/log/radius

	pamd_mimic_system radiusd auth account password session

	dodoc CREDITS

	rm "${D}/usr/sbin/rc.radiusd" || die

	newinitd "${FILESDIR}/radius.init-r3" radiusd
	newconfd "${FILESDIR}/radius.conf-r4" radiusd

	# Systemd stuff
	systemd_newtmpfilesd "${FILESDIR}"/freeradius.tmpfiles freeradius.conf
	systemd_dounit "${FILESDIR}"/freeradius.service
	systemd_install_serviced "${FILESDIR}"/freeradius.service.conf

	# Remove all default sites under site-enables.
	# Administrator install all sites when configure freeradius.
	rm ${D}/etc/raddb/sites-enabled/{inner-tunnel,default}
	# Remove part of modules that require a configuration
	# from mods-enabled directory.
	rm ${D}/etc/raddb/mods-enabled/{cache_eap,digest,eap,mschap,ntlm_auth}

	find "${ED}" \( -name "*.a" -o -name "*.la" \) -delete || die
}

pkg_config() {
	if use ssl; then
		cd "${ROOT}"/etc/raddb/certs
		./bootstrap

		fowners -R root:radius "${ROOT}"/etc/raddb/certs
	fi
}

pkg_preinst() {
	if ! has_version ${CATEGORY}/${PN} && use ssl; then
		elog "You have to run \`emerge --config =${CATEGORY}/${PF}\` to be able"
		elog "to start the radiusd service."
	fi
}
