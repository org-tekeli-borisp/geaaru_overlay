# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3+ )
DISTUTILS_USE_PEP517="setuptools"
inherit distutils-r1

DESCRIPTION="Additional functions used by other projects by developer jaraco"
HOMEPAGE="https://github.com/jaraco/jaraco.functools https://pypi.org/project/jaraco.functools/"
SRC_URI="https://files.pythonhosted.org/packages/57/7c/fe770e264913f9a49ddb9387cca2757b8d7d26f06735c1bfbb018912afce/jaraco.functools-4.0.0.tar.gz -> jaraco.functools-4.0.0.tar.gz"

DEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
	dev-python/more-itertools[${PYTHON_USEDEP}]
	dev-python/namespace-jaraco[${PYTHON_USEDEP}]"
RDEPEND="
	dev-python/more-itertools[${PYTHON_USEDEP}]
	dev-python/namespace-jaraco[${PYTHON_USEDEP}]"
IUSE=""
SLOT="0"
LICENSE="MIT"
KEYWORDS="*"
S="${WORKDIR}/jaraco-functools-4.0.0"

post_src_unpack() {
	mv jaraco.functools-* "${S}"
}
