# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3+ )
inherit distutils-r1

DESCRIPTION="Async boto3 wrapper"
HOMEPAGE="https://github.com/terrycain/aioboto3 https://pypi.org/project/aioboto3/"
SRC_URI="https://files.pythonhosted.org/packages/1c/3d/e3ac3c73fe5a7dc39791365907df3ac4a9898d02491b04a61094c90d3b75/aioboto3-13.0.1.tar.gz -> aioboto3-13.0.1.tar.gz"

DEPEND=""
RDEPEND="dev-python/aiobotocore[${PYTHON_USEDEP}]"
IUSE=""
SLOT="0"
LICENSE="Apache-2.0"
KEYWORDS="*"
S="${WORKDIR}/aioboto3-13.0.1"