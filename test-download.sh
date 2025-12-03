#!/bin/bash

# 测试 Dify Plugin CLI 下载链接

set -e

echo "=== 测试 Dify Plugin CLI 下载配置 ==="
echo ""

PLATFORM="linux-amd64"
# 尝试两种格式
DOWNLOAD_URL1="https://github.com/langgenius/dify-plugin-daemon/releases/latest/download/dify-plugin-daemon-${PLATFORM}"
DOWNLOAD_URL2="https://github.com/langgenius/dify-plugin-daemon/releases/latest/download/dify-plugin-${PLATFORM}"
DOWNLOAD_URL="${DOWNLOAD_URL2}"

echo "1. 测试下载链接..."
echo "   格式1 (带 -daemon): ${DOWNLOAD_URL1}"
HTTP_CODE1=$(curl -sL -o /dev/null -w "%{http_code}" "${DOWNLOAD_URL1}" 2>/dev/null || echo "000")
echo "   HTTP 状态码: ${HTTP_CODE1}"

echo ""
echo "   格式2 (不带 -daemon): ${DOWNLOAD_URL2}"
HTTP_CODE2=$(curl -sL -o /dev/null -w "%{http_code}" "${DOWNLOAD_URL2}" 2>/dev/null || echo "000")
echo "   HTTP 状态码: ${HTTP_CODE2}"

if [ "${HTTP_CODE2}" = "200" ] || [ "${HTTP_CODE2}" = "302" ] || [ "${HTTP_CODE2}" = "301" ]; then
    echo "   ✓ 格式2 下载链接有效"
    DOWNLOAD_URL="${DOWNLOAD_URL2}"
elif [ "${HTTP_CODE1}" = "200" ] || [ "${HTTP_CODE1}" = "302" ] || [ "${HTTP_CODE1}" = "301" ]; then
    echo "   ✓ 格式1 下载链接有效"
    DOWNLOAD_URL="${DOWNLOAD_URL1}"
else
    echo "   ✗ 两种格式都无效，需要检查实际文件名"
fi

echo ""
echo "2. 检查实际文件名格式..."
echo "   从 GitHub Releases API 获取最新版本信息..."

RELEASE_INFO=$(curl -s "https://api.github.com/repos/langgenius/dify-plugin-daemon/releases/latest" 2>/dev/null || echo "")

if [ -n "${RELEASE_INFO}" ]; then
    VERSION=$(echo "${RELEASE_INFO}" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tag_name', 'unknown'))" 2>/dev/null || echo "unknown")
    echo "   最新版本: ${VERSION}"
    
    echo ""
    echo "   Assets 列表:"
    echo "${RELEASE_INFO}" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for asset in data.get('assets', []):
    name = asset.get('name', '')
    if 'linux' in name.lower():
        print(f'    - {name}')
" 2>/dev/null || echo "   无法解析 assets"
else
    echo "   ⚠ 无法获取 release 信息"
fi

echo ""
echo "3. 配置总结:"
echo "   仓库: langgenius/dify-plugin-daemon"
echo "   文件名格式: dify-plugin-daemon-${PLATFORM}"
echo "   下载 URL: ${DOWNLOAD_URL}"
echo "   安装后的命令: dify-plugin-daemon"
echo "   符号链接: dify -> dify-plugin-daemon"

