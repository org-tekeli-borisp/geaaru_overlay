# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# Ebuild automatically produced by node-ebuilder.

EAPI=6

DESCRIPTION="The lodash method _.escape exported as a module."
HOMEPAGE="https://lodash.com/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="
	>=dev-node/lodash-root-3.0.1
"
RDEPEND="${DEPEND}"

NPM_PKG_NAME="lodash.escape"
NPM_NO_DEPS=1

S="${WORKDIR}/package"

inherit npmv1

