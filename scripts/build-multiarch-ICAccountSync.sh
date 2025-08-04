#!/bin/bash

# Parse Dashboard ICAccountSync 多架构 Docker 构建脚本
# 支持: linux/amd64, linux/arm64, linux/arm/v7

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_TAG="parse-dashboard-icaccountsync:latest"
DEFAULT_PLATFORMS="linux/amd64,linux/arm64"
DEFAULT_REGISTRY=""
DOCKERFILE="Dockerfile.ICAccountSync"

# 帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -t, --tag TAG         指定镜像标签 (默认: $DEFAULT_TAG)"
    echo "  -p, --platforms PLAT  指定目标平台 (默认: $DEFAULT_PLATFORMS)"
    echo "  -r, --registry REG    指定镜像仓库"
    echo "  -f, --dockerfile FILE 指定 Dockerfile (默认: $DOCKERFILE)"
    echo "  --push                构建完成后推送镜像"
    echo "  --no-cache            不使用 Docker 缓存"
    echo "  -h, --help            显示此帮助信息"
    echo ""
    echo "支持的平台:"
    echo "  linux/amd64    - Intel/AMD 64位"
    echo "  linux/arm64    - ARM 64位 (Apple Silicon, ARM64 服务器)"
    echo "  linux/arm/v7   - ARM 32位 v7"
    echo ""
    echo "示例:"
    echo "  $0 -t myapp:v1.0 -p linux/amd64,linux/arm64 --push"
    echo "  $0 -r myregistry.com -t parse-dashboard-icaccountsync:v1.0 --push"
}

# 解析命令行参数
TAG="$DEFAULT_TAG"
PLATFORMS="$DEFAULT_PLATFORMS"
REGISTRY=""
PUSH=false
NO_CACHE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -p|--platforms)
            PLATFORMS="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -f|--dockerfile)
            DOCKERFILE="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知参数 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查 Dockerfile 是否存在
if [[ ! -f "$DOCKERFILE" ]]; then
    echo -e "${RED}错误: Dockerfile '$DOCKERFILE' 不存在${NC}"
    exit 1
fi

# 检查 Docker 是否支持 buildx
if ! docker buildx version >/dev/null 2>&1; then
    echo -e "${RED}错误: Docker buildx 不可用。请确保 Docker 版本 >= 19.03${NC}"
    exit 1
fi

# 检查是否启用了 buildx
if ! docker buildx inspect >/dev/null 2>&1; then
    echo -e "${YELLOW}警告: buildx 未启用，正在启用...${NC}"
    docker buildx create --use --name multiarch-builder || true
fi

# 构建完整镜像名称
if [[ -n "$REGISTRY" ]]; then
    FULL_TAG="${REGISTRY}/${TAG}"
else
    FULL_TAG="$TAG"
fi

echo -e "${BLUE}开始 Parse Dashboard ICAccountSync 多架构 Docker 构建${NC}"
echo -e "${BLUE}Dockerfile: ${GREEN}$DOCKERFILE${NC}"
echo -e "${BLUE}镜像标签: ${GREEN}$FULL_TAG${NC}"
echo -e "${BLUE}目标平台: ${GREEN}$PLATFORMS${NC}"
echo -e "${BLUE}推送镜像: ${GREEN}$PUSH${NC}"
echo ""

# 构建镜像
echo -e "${YELLOW}正在构建多架构镜像...${NC}"
docker buildx build \
    --platform "$PLATFORMS" \
    --tag "$FULL_TAG" \
    $NO_CACHE \
    --file "$DOCKERFILE" \
    .

# 如果需要推送
if [[ "$PUSH" == true ]]; then
    echo -e "${YELLOW}正在推送镜像到仓库...${NC}"
    docker buildx build \
        --platform "$PLATFORMS" \
        --tag "$FULL_TAG" \
        $NO_CACHE \
        --file "$DOCKERFILE" \
        --push \
        .
fi

echo ""
echo -e "${GREEN}✅ 构建完成!${NC}"
echo -e "${BLUE}镜像: ${GREEN}$FULL_TAG${NC}"
echo -e "${BLUE}平台: ${GREEN}$PLATFORMS${NC}"

# 显示镜像信息
if [[ "$PUSH" == false ]]; then
    echo ""
    echo -e "${BLUE}本地镜像信息:${NC}"
    docker images "$FULL_TAG" 2>/dev/null || echo "镜像未找到（可能已推送）"
fi

# 显示运行命令示例
echo ""
echo -e "${BLUE}运行示例:${NC}"
echo -e "${GREEN}docker run -d -p 4040:4040 --name parse-dashboard-icaccountsync $FULL_TAG${NC}" 