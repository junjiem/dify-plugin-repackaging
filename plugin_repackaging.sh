#!/bin/bash
# author: Junjie.M

DEFAULT_GITHUB_API_URL=https://github.com
DEFAULT_MARKETPLACE_API_URL=https://marketplace.dify.ai
DEFAULT_PIP_MIRROR_URL=https://mirrors.aliyun.com/pypi/simple

GITHUB_API_URL="${GITHUB_API_URL:-$DEFAULT_GITHUB_API_URL}"
MARKETPLACE_API_URL="${MARKETPLACE_API_URL:-$DEFAULT_MARKETPLACE_API_URL}"
PIP_MIRROR_URL="${PIP_MIRROR_URL:-$DEFAULT_PIP_MIRROR_URL}"

CURR_DIR=`dirname $0`
cd $CURR_DIR || exit 1
CURR_DIR=`pwd`
USER=`whoami`
ARCH_NAME=`uname -m`
OS_TYPE=$(uname)
OS_TYPE=$(echo "$OS_TYPE" | tr '[:upper:]' '[:lower:]')

CMD_NAME="dify-plugin-${OS_TYPE}-amd64"
if [[ "arm64" == "$ARCH_NAME" || "aarch64" == "$ARCH_NAME" ]]; then
	CMD_NAME="dify-plugin-${OS_TYPE}-arm64"
fi

PIP_PLATFORM=""
PACKAGE_SUFFIX="offline"

market(){
	if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
		echo ""
		echo "Usage: "$0" market [plugin author] [plugin name] [plugin version]"
		echo "Example:"
		echo "	"$0" market junjiem mcp_sse 0.0.1"
		echo "	"$0" market langgenius agent 0.0.9"
		echo ""
		exit 1
	fi
	echo "From the Dify Marketplace downloading ..."
	PLUGIN_AUTHOR=$2
	PLUGIN_NAME=$3
	PLUGIN_VERSION=$4
	PLUGIN_PACKAGE_PATH=${CURR_DIR}/${PLUGIN_AUTHOR}-${PLUGIN_NAME}_${PLUGIN_VERSION}.difypkg
	PLUGIN_DOWNLOAD_URL=${MARKETPLACE_API_URL}/api/v1/plugins/${PLUGIN_AUTHOR}/${PLUGIN_NAME}/${PLUGIN_VERSION}/download
	echo "Downloading ${PLUGIN_DOWNLOAD_URL} ..."
	curl -L -o ${PLUGIN_PACKAGE_PATH} ${PLUGIN_DOWNLOAD_URL}
	if [[ $? -ne 0 ]]; then
		echo "Download failed, please check the plugin author, name and version."
		exit 1
	fi
	echo "Download success."
	repackage ${PLUGIN_PACKAGE_PATH}
}

github(){
	if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
		echo ""
		echo "Usage: "$0" github [Github repo] [Release title] [Assets name (include .difypkg suffix)]"
		echo "Example:"
		echo "	"$0" github junjiem/dify-plugin-tools-dbquery v0.0.2 db_query.difypkg"
		echo "	"$0" github https://github.com/junjiem/dify-plugin-agent-mcp_sse 0.0.1 agent-mcp_see.difypkg"
		echo ""
		exit 1
	fi
	echo "From the Github downloading ..."
	GITHUB_REPO=$2
	if [[ "${GITHUB_REPO}" != "${GITHUB_API_URL}"* ]]; then
		GITHUB_REPO="${GITHUB_API_URL}/${GITHUB_REPO}"
	fi
	RELEASE_TITLE=$3
	ASSETS_NAME=$4
	PLUGIN_NAME="${ASSETS_NAME%.difypkg}"
	PLUGIN_PACKAGE_PATH=${CURR_DIR}/${PLUGIN_NAME}-${RELEASE_TITLE}.difypkg
	PLUGIN_DOWNLOAD_URL=${GITHUB_REPO}/releases/download/${RELEASE_TITLE}/${ASSETS_NAME}
	echo "Downloading ${PLUGIN_DOWNLOAD_URL} ..."
	curl -L -o ${PLUGIN_PACKAGE_PATH} ${PLUGIN_DOWNLOAD_URL}
	if [[ $? -ne 0 ]]; then
		echo "Download failed, please check the github repo, release title and assets name."
		exit 1
	fi
	echo "Download success."
	repackage ${PLUGIN_PACKAGE_PATH}
}

_local(){
	echo $2
	if [[ -z "$2" ]]; then
		echo ""
		echo "Usage: "$0" local [difypkg path]"
		echo "Example:"
		echo "	"$0" local ./db_query.difypkg"
		echo "	"$0" local /root/dify-plugin/db_query.difypkg"
		echo ""
		exit 1
	fi
	PLUGIN_PACKAGE_PATH=`realpath $2`
	repackage ${PLUGIN_PACKAGE_PATH}
}

repackage(){
	local PACKAGE_PATH=$1
	PACKAGE_NAME_WITH_EXTENSION=`basename ${PACKAGE_PATH}`
	PACKAGE_NAME="${PACKAGE_NAME_WITH_EXTENSION%.*}"
	echo "Unziping ..."
	install_unzip
	unzip -o ${PACKAGE_PATH} -d ${CURR_DIR}/${PACKAGE_NAME}
	if [[ $? -ne 0 ]]; then
		echo "Unzip failed."
		exit 1
	fi
	echo "Unzip success."
	echo "Repackaging ..."
	cd ${CURR_DIR}/${PACKAGE_NAME} || exit 1

	if python3 -m pip --version &> /dev/null 2>&1; then
		PIP_CMD="python3 -m pip"
	elif command -v pip &> /dev/null && pip --version &> /dev/null 2>&1; then
		PIP_CMD=pip
	elif command -v pip3 &> /dev/null && pip3 --version &> /dev/null 2>&1; then
		PIP_CMD=pip3
	else
		echo "pip not found. Install: python3 -m ensurepip --upgrade"
		exit 1
	fi
	echo "Using pip: ${PIP_CMD}"

	if [ -f "pyproject.toml" ] && [ ! -f "requirements.txt" ]; then
		if command -v uv &> /dev/null; then
			echo "Compiling pyproject.toml with uv..."
			uv pip compile pyproject.toml -o requirements.txt --index-url "${PIP_MIRROR_URL}" || exit 1
		else
			echo "pyproject.toml found but requirements.txt is missing and uv is not installed."
			echo "Install uv or commit requirements.txt."
			exit 1
		fi
	fi

	[ ! -f "requirements.txt" ] && echo "No requirements.txt found" && exit 1

	PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
	PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
	if [ "$PYTHON_MINOR" -ge 14 ]; then
		echo "Warning: Python $PYTHON_VERSION may have compatibility issues"
	fi

	echo "Downloading dependencies..."
	${PIP_CMD} download ${PIP_PLATFORM} --prefer-binary -r requirements.txt -d ./wheels \
		--index-url ${PIP_MIRROR_URL} --trusted-host mirrors.aliyun.com
	[ $? -ne 0 ] && exit 1

	if [[ "linux" == "$OS_TYPE" ]]; then
		sed -i '1i\--no-index --find-links=./wheels/' requirements.txt
		[ -f ".difyignore" ] && IGNORE_PATH=.difyignore || IGNORE_PATH=.gitignore
		[ -f "$IGNORE_PATH" ] && sed -i '/^wheels\//d' "${IGNORE_PATH}"
	elif [[ "darwin" == "$OS_TYPE" ]]; then
		sed -i ".bak" '1i\--no-index --find-links=./wheels/' requirements.txt && rm -f requirements.txt.bak
		[ -f ".difyignore" ] && IGNORE_PATH=.difyignore || IGNORE_PATH=.gitignore
		[ -f "$IGNORE_PATH" ] && sed -i ".bak" '/^wheels\//d' "${IGNORE_PATH}" && rm -f "${IGNORE_PATH}.bak"
	fi

	cd ${CURR_DIR} || exit 1
	chmod 755 ${CURR_DIR}/${CMD_NAME}
	${CURR_DIR}/${CMD_NAME} plugin package ${CURR_DIR}/${PACKAGE_NAME} \
		-o ${CURR_DIR}/${PACKAGE_NAME}-${PACKAGE_SUFFIX}.difypkg --max-size 5120
	[ $? -ne 0 ] && echo "Repackage failed." && exit 1
	echo "Repackage success."
}

install_unzip(){
	if ! command -v unzip &> /dev/null; then
		echo "Installing unzip ..."
		yum -y install unzip
		if [ $? -ne 0 ]; then
			echo "Install unzip failed."
			exit 1
		fi
	fi
}

print_usage() {
	echo "usage: $0 [-p platform] [-s package_suffix] {market|github|local}"
	echo "-p platform: python packages' platform. Using for crossing repacking.
        For example: -p manylinux2014_x86_64 or -p manylinux2014_aarch64"
	echo "-s package_suffix: The suffix name of the output offline package.
        For example: -s linux-amd64 or -s linux-arm64"
	exit 1
}

while getopts "p:s:" opt; do
	case "$opt" in
		p) PIP_PLATFORM="--platform ${OPTARG} --only-binary=:all:" ;;
		s) PACKAGE_SUFFIX="${OPTARG}" ;;
		*) print_usage; exit 1 ;;
	esac
done

shift $((OPTIND - 1))

echo "$1"
case "$1" in
	'market')
	market $@
	;;
	'github')
	github $@
	;;
	'local')
	_local $@
	;;
	*)

print_usage
exit 1
esac
exit 0
