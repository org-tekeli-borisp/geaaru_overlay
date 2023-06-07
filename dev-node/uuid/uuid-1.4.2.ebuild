# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# Ebuild automatically produced by node-ebuilder.

EAPI=6

DESCRIPTION="Rigorous implementation of RFC4122 (v1 and v4) UUIDs."
HOMEPAGE="https://github.com/shtylman/node-uuid#readme"

SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="
"
RDEPEND="${DEPEND}"
# To many node-uuid implementations!!
NPM_BINS="
uuid => node-uuid-kelektiv
"
NPM_NO_DEPS=1

S="${WORKDIR}/package"

inherit npmv1

