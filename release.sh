#!/bin/bash

# 自动化发布脚本
# 用法: ./release.sh [版本号]
# 如果不提供版本号，会自动从 manifest.yaml 读取当前版本并递增补丁版本号

set -e

PLUGIN_NAME="sse_client"
MANIFEST_FILE="manifest.yaml"

# 获取版本号
if [ -z "$1" ]; then
    # 如果没有提供版本号，从 manifest.yaml 读取当前版本并递增补丁版本
    CURRENT_VERSION=$(grep "^version:" "${MANIFEST_FILE}" | awk '{print $2}')
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]}
    NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
    VERSION=$NEW_VERSION
    echo "自动递增版本号: ${CURRENT_VERSION} -> ${VERSION}"
else
    VERSION=$1
    echo "使用指定版本号: ${VERSION}"
fi

# 验证版本号格式 (简单验证: 应该包含至少一个点)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo "错误: 版本号格式不正确，应为 x.y.z 格式"
    exit 1
fi

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    echo "警告: 检测到未提交的更改"
    echo "请先提交或暂存所有更改，然后再运行发布脚本"
    exit 1
fi

# 更新 manifest.yaml 中的版本号
echo "更新 manifest.yaml 中的版本号为 ${VERSION}..."
sed -i.bak "s/^version: .*/version: ${VERSION}/" "${MANIFEST_FILE}"
sed -i.bak "s/^  version: .*/  version: ${VERSION}/" "${MANIFEST_FILE}"
rm -f "${MANIFEST_FILE}.bak"

# 显示更改
echo ""
echo "版本号已更新:"
git diff "${MANIFEST_FILE}" || true
echo ""

# 确认是否继续
read -p "确认发布版本 ${VERSION}? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消发布"
    git checkout "${MANIFEST_FILE}"
    exit 1
fi

# 提交更改
echo "提交版本更新..."
git add "${MANIFEST_FILE}"
git commit -m "Bump version to ${VERSION}"

# 推送代码
echo "推送代码到 main 分支..."
git push origin main

# 创建并推送标签
TAG_NAME="v${VERSION}"
echo "创建标签 ${TAG_NAME}..."
git tag -a "${TAG_NAME}" -m "Release version ${VERSION}"
echo "推送标签到远程..."
git push origin "${TAG_NAME}"

echo ""
echo "✓ 发布流程完成！"
echo "  - 版本号已更新为: ${VERSION}"
echo "  - 代码已推送到: main"
echo "  - 标签已创建并推送: ${TAG_NAME}"
echo ""
echo "GitHub Actions 将自动："
echo "  - 提取版本号"
echo "  - 打包插件"
echo "  - 创建 GitHub Release"
echo "  - 上传 .difypkg 文件作为 Release Asset"

