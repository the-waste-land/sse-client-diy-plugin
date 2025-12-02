#!/bin/bash

# 重新触发失败的 Release 构建
# 用法: ./retry-release.sh <tag_name>
# 例如: ./retry-release.sh v0.0.2

set -e

if [ -z "$1" ]; then
    echo "用法: $0 <tag_name>"
    echo "例如: $0 v0.0.2"
    exit 1
fi

TAG_NAME=$1

echo "重新触发标签 ${TAG_NAME} 的构建..."

# 删除本地标签（如果存在）
git tag -d "${TAG_NAME}" 2>/dev/null || true

# 删除远程标签
echo "删除远程标签 ${TAG_NAME}..."
git push origin ":refs/tags/${TAG_NAME}" || {
    echo "警告: 删除远程标签失败，可能标签不存在"
}

# 重新创建标签（指向当前 HEAD）
echo "重新创建标签 ${TAG_NAME}..."
git tag -a "${TAG_NAME}" -m "Release ${TAG_NAME}"

# 推送标签
echo "推送标签到远程..."
git push origin "${TAG_NAME}"

echo ""
echo "✓ 标签 ${TAG_NAME} 已重新推送"
echo "GitHub Actions 将自动触发新的构建"

