#!/bin/bash

# 打包 Dify 插件脚本
# 用法: ./package.sh [版本号]

set -e

PLUGIN_NAME="sse_client"
VERSION=${1:-$(grep "^version:" manifest.yaml | awk '{print $2}')}
OUTPUT_FILE="${PLUGIN_NAME}-${VERSION}.difypkg"

echo "正在打包插件: ${PLUGIN_NAME} v${VERSION}"

# 检查 dify 命令是否可用
if ! command -v dify &> /dev/null; then
    echo "错误: 未找到 dify 命令"
    echo "请先安装 Dify Plugin CLI: https://github.com/dify-ai/dify-plugin/releases"
    exit 1
fi

# 清理旧的打包文件
rm -f *.difypkg

# 获取插件目录的绝对路径
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR_NAME="$(basename "${PLUGIN_DIR}")"
PARENT_DIR="$(dirname "${PLUGIN_DIR}")"

# 在父目录执行打包命令
cd "${PARENT_DIR}"
dify plugin package "${PLUGIN_DIR_NAME}" -o "${PLUGIN_DIR}/${OUTPUT_FILE}"

cd "${PLUGIN_DIR}"

echo "✓ 打包完成: ${OUTPUT_FILE}"
echo "文件大小: $(du -h ${OUTPUT_FILE} | cut -f1)"

