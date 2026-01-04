#!/bin/bash
# author: Junjie.M (modified by ChatGPT)

DEFAULT_GITHUB_API_URL=https://github.com
DEFAULT_MARKETPLACE_API_URL=https://marketplace.dify.ai
DEFAULT_PIP_MIRROR_URL=https://mirrors.aliyun.com/pypi/simple

GITHUB_API_URL="${GITHUB_API_URL:-$DEFAULT_GITHUB_API_URL}"
MARKETPLACE_API_URL="${MARKETPLACE_API_URL:-$DEFAULT_MARKETPLACE_API_URL}"
PIP_MIRROR_URL="${PIP_MIRROR_URL:-$DEFAULT_PIP_MIRROR_URL}"

CURR_DIR=`dirname $0`
cd $CURR_DIR
CURR_DIR=`pwd`

# 强制使用 /app/output 作为输出目录
OUTPUT_DIR="/app/output"
mkdir -p "$OUTPUT_DIR"

USER=`whoami`
ARCH_NAME=`uname -m`
OS_TYPE=$(uname | tr '[:upper:]' '[:lower:]')

CMD_NAME="dify-plugin-${OS_TYPE}-amd64"
if [[ "$ARCH_NAME" == "arm64" || "$ARCH_NAME" == "aarch64" ]]; then
    CMD_NAME="dify-plugin-${OS_TYPE}-arm64"
fi

PIP_PLATFORM=""
PACKAGE_SUFFIX="offline"

market(){
    if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
        echo ""
        echo "Usage: $0 market [plugin author] [plugin name] [plugin version]"
        exit 1
    fi
    echo "From Dify Marketplace downloading ..."
    PLUGIN_AUTHOR=$2
    PLUGIN_NAME=$3
    PLUGIN_VERSION=$4
    PACKAGE_PATH="${CURR_DIR}/${PLUGIN_AUTHOR}-${PLUGIN_NAME}_${PLUGIN_VERSION}.difypkg"
    URL="${MARKETPLACE_API_URL}/api/v1/plugins/${PLUGIN_AUTHOR}/${PLUGIN_NAME}/${PLUGIN_VERSION}/download"

    curl -L -o "$PACKAGE_PATH" "$URL"
    if [[ $? -ne 0 ]]; then
        echo "Download failed."
        exit 1
    fi
    repackage "$PACKAGE_PATH"
}

github(){
    if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
        echo ""
        echo "Usage: $0 github [repo] [release] [asset]"
        exit 1
    fi
    echo "From Github downloading ..."
    REPO=$2
    [[ "$REPO" != "$GITHUB_API_URL"* ]] && REPO="${GITHUB_API_URL}/${REPO}"
    RELEASE=$3
    ASSET=$4
    NAME="${ASSET%.difypkg}"
    PACKAGE_PATH="${CURR_DIR}/${NAME}-${RELEASE}.difypkg"
    URL="${REPO}/releases/download/${RELEASE}/${ASSET}"

    curl -L -o "$PACKAGE_PATH" "$URL"
    if [[ $? -ne 0 ]]; then
        echo "Download failed."
        exit 1
    fi
    repackage "$PACKAGE_PATH"
}

_local(){
    if [[ -z "$2" ]]; then
        echo "Usage: $0 local [difypkg path]"
        exit 1
    fi
    REAL_PATH=$(realpath "$2")
    repackage "$REAL_PATH"
}

repackage(){
    local PKG_PATH=$1
    local PKG_FULL=$(basename "$PKG_PATH")
    local PKG_NAME="${PKG_FULL%.*}"

    echo "Unziping ..."
    install_unzip
    unzip -o "$PKG_PATH" -d "${CURR_DIR}/${PKG_NAME}"
    [[ $? -ne 0 ]] && echo "Unzip failed." && exit 1

    echo "Repackaging ..."
    cd "${CURR_DIR}/${PKG_NAME}"

    pip download ${PIP_PLATFORM} -r requirements.txt -d ./wheels --index-url "${PIP_MIRROR_URL}" --trusted-host mirrors.aliyun.com
    [[ $? -ne 0 ]] && echo "Pip download failed." && exit 1

    if [[ "$OS_TYPE" == "linux" ]]; then
        sed -i '1i\--no-index --find-links=./wheels/' requirements.txt
    else
        sed -i ".bak" '1i\
--no-index --find-links=./wheels/' requirements.txt
        rm -f requirements.txt.bak
    fi

    # 修复 ignore
    IGNORE_FILE=".difyignore"
    [[ ! -f "$IGNORE_FILE" ]] && IGNORE_FILE=".gitignore"

    if [[ -f "$IGNORE_FILE" ]]; then
        if [[ "$OS_TYPE" == "linux" ]]; then
            sed -i '/^wheels\//d' "$IGNORE_FILE"
        else
            sed -i ".bak" '/^wheels\//d' "$IGNORE_FILE"
            rm -f "$IGNORE_FILE.bak"
        fi
    fi

    cd "$CURR_DIR"
    chmod 755 "${CURR_DIR}/${CMD_NAME}"

    # 这里改了！输出现在写到 /app/output
    OUTPUT_FILE="${OUTPUT_DIR}/${PKG_NAME}-${PACKAGE_SUFFIX}.difypkg"
    echo "Output => ${OUTPUT_FILE}"

    "${CURR_DIR}/${CMD_NAME}" plugin package "${CURR_DIR}/${PKG_NAME}" -o "${OUTPUT_FILE}" --max-size 5120

    [[ $? -ne 0 ]] && echo "Repackage failed." && exit 1

    echo "Repackage success."
    echo "Your output file is here:"
    echo "👉 ${OUTPUT_FILE}"
}

install_unzip(){
    if ! command -v unzip >/dev/null; then
        echo "Installing unzip ..."
        yum -y install unzip || { echo "Install unzip failed."; exit 1; }
    fi
}

print_usage(){
    echo "usage: $0 [-p platform] [-s suffix] {market|github|local}"
    exit 1
}

while getopts "p:s:" opt; do
    case "$opt" in
        p) PIP_PLATFORM="--platform ${OPTARG} --only-binary=:all:" ;;
        s) PACKAGE_SUFFIX="${OPTARG}" ;;
        *) print_usage ;;
    esac
done

shift $((OPTIND - 1))
case "$1" in
    market) market $@ ;;
    github) github $@ ;;
    local)  _local $@ ;;
    *) print_usage ;;
esac

exit 0
