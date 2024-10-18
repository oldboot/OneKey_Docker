#!/bin/bash

# 定义 Docker Compose 版本
DOCKER_COMPOSE_VERSION="2.29.7"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 用户权限运行此脚本。"
  exit 1
fi

# 检查系统类型
if [ -x "$(command -v apt-get)" ]; then
    # 判断是 Debian 还是 Ubuntu
    if grep -q 'Ubuntu' /etc/os-release; then
        OS_TYPE="ubuntu"
    elif grep -q 'Debian' /etc/os-release; then
        OS_TYPE="debian"
    else
        echo "不支持的系统。请使用基于 Ubuntu 或 Debian 的系统。"
        exit 1
    fi
else
    echo "不支持的包管理器。"
    exit 1
fi

echo "检测到的操作系统类型: $OS_TYPE"
echo "开始安装 Docker 和 Docker Compose..."

# 更新系统包
echo "更新系统包..."
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

# 安装 Docker
echo "安装 Docker..."
mkdir -p /etc/apt/keyrings

# 始终覆盖 GPG 密钥
echo "添加 Docker GPG 公钥..."
curl -fsSL https://download.docker.com/linux/$OS_TYPE/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS_TYPE \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动并配置 Docker 自启动
echo "启动并配置 Docker 自启动..."
systemctl enable docker
systemctl start docker

# 安装 Docker Compose
echo "安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 赋予 Docker Compose 可执行权限
chmod +x /usr/local/bin/docker-compose

# 验证 Docker 和 Docker Compose 是否安装成功
echo "验证 Docker 和 Docker Compose 版本..."
docker --version
docker-compose --version

echo "Docker 和 Docker Compose 安装完成！"
