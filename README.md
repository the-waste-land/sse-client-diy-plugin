# SSE Client Plugin

This plugin provides a tool to make SSE (Server-Sent Events) requests and stream the output.

## Tools

### SSE Client

Makes an HTTP request to an SSE endpoint and streams the `data` field of the received events.

#### Parameters

- **URL**: The URL to make the request to.
- **Method**: HTTP method (GET or POST). Default is GET.
- **Headers**: JSON string of headers to include in the request.
- **Body**: JSON string of the body to include in the request (for POST).

#### Output

Streams the content of the `data` field from the SSE events.

## 本地打包

### 前置要求

需要先安装 [Dify Plugin CLI](https://github.com/dify-ai/dify-plugin/releases)：

```bash
# macOS (根据你的架构选择)
# Apple Silicon
wget https://github.com/dify-ai/dify-plugin/releases/latest/download/dify-plugin-darwin-arm64 -O dify
# Intel
wget https://github.com/dify-ai/dify-plugin/releases/latest/download/dify-plugin-darwin-amd64 -O dify

chmod +x dify
sudo mv dify /usr/local/bin/
```

### 使用打包脚本

使用提供的打包脚本进行本地打包（脚本内部使用 `dify plugin package` 命令）：

```bash
./package.sh
```

或者指定版本号：

```bash
./package.sh 0.0.2
```

打包完成后会生成 `sse_client-<version>.difypkg` 文件。

### 直接使用 Dify CLI

也可以直接使用 Dify CLI 命令打包：

```bash
# 在插件目录的父目录执行
cd ..
dify plugin package sse_client -o sse_client/sse_client.difypkg
```

## 发布到 GitHub

### 手动发布

1. **提交代码到 GitHub**：
   ```bash
   git add .
   git commit -m "Update plugin"
   git push origin main
   ```

2. **创建版本标签**：
   ```bash
   git tag -a v0.0.1 -m "Release version 0.0.1"
   git push origin v0.0.1
   ```

3. **在 GitHub 上创建 Release**：
   - 访问仓库的 Releases 页面
   - 点击 "Draft a new release"
   - 选择刚才创建的标签
   - 填写发布说明
   - 上传打包好的 `.difypkg` 文件
   - 点击 "Publish release"

### 自动发布（推荐）

项目已配置 GitHub Actions 工作流，当推送版本标签时会自动打包并创建 Release：

1. **更新版本号**（在 `manifest.yaml` 中）：
   ```yaml
   version: 0.0.2
   ```

2. **提交并推送代码**：
   ```bash
   git add .
   git commit -m "Bump version to 0.0.2"
   git push origin main
   ```

3. **创建并推送标签**：
   ```bash
   git tag -a v0.0.2 -m "Release version 0.0.2"
   git push origin v0.0.2
   ```

GitHub Actions 会自动：
- 提取版本号
- 打包插件
- 创建 GitHub Release
- 上传 `.difypkg` 文件作为 Release Asset
