#!/bin/bash

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 用户权限运行此脚本。"
  exit
fi

echo "开始安装 Docker 和 Docker Compose..."

# 更新系统包
if [ -x "$(command -v apt-get)" ]; then
    # Debian/Ubuntu 系列
    echo "更新系统包..."
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release

    # 获取发行版信息
    DISTRO=$(lsb_release -is)
    CODENAME=$(lsb_release -cs)

    # 添加阿里云 Docker 源
    echo "添加阿里云 Docker 源..."
    if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/$DISTRO/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    else
        echo "GPG 密钥文件已存在，跳过更新。"
    fi

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/$DISTRO \
      $CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 更新并安装 Docker
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io

elif [ -x "$(command -v yum)" ]; then
    # CentOS/RHEL 系列
    echo "更新系统包..."
    yum update -y

    # 安装依赖
    echo "安装依赖..."
    yum install -y yum-utils

    # 使用阿里云 Docker 源
    echo "添加阿里云 Docker 源..."
    yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

    # 安装 Docker
    echo "安装 Docker..."
    yum install -y docker-ce docker-ce-cli containerd.io
else
    echo "不支持的系统。请使用基于 Ubuntu/Debian 或 CentOS/RHEL 的系统。"
    exit 1
fi

# 启动并配置 Docker 自启动
echo "启动并配置 Docker 自启动..."
systemctl enable docker
systemctl start docker

# 定义 Docker Compose 版本
DOCKER_COMPOSE_VERSION="v2.29.7"

# 安装 Docker Compose
echo "安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 赋予 Docker Compose 可执行权限
chmod +x /usr/local/bin/docker-compose

# 验证 Docker 和 Docker Compose 是否安装成功
echo "验证 Docker 和 Docker Compose 版本..."
docker --version
docker-compose --version

echo "Docker 和 Docker Compose 安装完成！"
