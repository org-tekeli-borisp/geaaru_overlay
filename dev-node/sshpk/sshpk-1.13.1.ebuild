# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# Ebuild automatically produced by node-ebuilder.

EAPI=6

DESCRIPTION="A library for finding and using SSH public keys"
HOMEPAGE="https://github.com/arekinath/node-sshpk#readme"

LICENSE="MIT"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="
	>=dev-node/asn1-0.2.3
	>=dev-node/bcrypt-pbkdf-1.0.1
	>=dev-node/dashdash-1.14.1
	>=dev-node/ecc-jsbn-0.1.1
	>=dev-node/getpass-0.1.6
	>=dev-node/jsbn-0.1.1
	>=dev-node/tweetnacl-0.14.5
"
RDEPEND="${DEPEND}"

NPM_SYSTEM_MODULES="
asn1
bcrypt-pbkdf
dashdash
ecc-jsbn
getpass
jsbn
jodid25519
tweetnacl
"

S="${WORKDIR}/package"

inherit npmv1

