#!/bin/bash

# 定义 Docker Compose 版本
DOCKER_COMPOSE_VERSION="2.29.7"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 用户权限运行此脚本。"
  exit 1
fi

# 选择镜像源
echo "请选择镜像源："
echo "1) 阿里镜像 (默认)"
echo "2) 官方镜像"
read -p "请输入选择 (1 或 2，回车默认 1): " choice
choice=${choice:-1}  # 默认选择 1

# 获取系统信息
if command -v lsb_release &> /dev/null; then
    DISTRO=$(lsb_release -si)
    CODENAME=$(lsb_release -cs)
else
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        CODENAME=$VERSION_ID
    else
        echo "不支持的系统。"
        exit 1
    fi
fi

echo "检测到的发行版: $DISTRO, 版本: $CODENAME"

# 检查系统类型并安装 Docker
install_docker() {
    echo "更新系统包..."
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release

    mkdir -p /etc/apt/keyrings

    if [ "$choice" -eq 1 ]; then
        echo "检查阿里云 Docker 源是否已存在..."
        if ! grep -q "mirrors.aliyun.com" /etc/apt/sources.list.d/docker.list; then
            echo "添加阿里云 Docker 源..."
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/$DISTRO/gpg -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/$DISTRO/ $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        else
            echo "阿里云 Docker 源已存在，跳过添加。"
        fi
    elif [ "$choice" -eq 2 ]; then
        echo "检查官方 Docker 源是否已存在..."
        if ! grep -q "download.docker.com" /etc/apt/sources.list.d/docker.list; then
            echo "添加官方 Docker 源..."
            curl -fsSL https://download.docker.com/linux/$DISTRO/gpg -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO/ $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        else
            echo "官方 Docker 源已存在，跳过添加。"
        fi
    else
        echo "无效选择。请重新运行脚本。"
        exit 1
    fi

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# 检查系统类型并调用相应的安装函数
if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Debian" ]]; then
    install_docker
elif [[ "$DISTRO" == "CentOS" || "$DISTRO" == "RHEL" ]]; then
    # 你可以在这里添加 CentOS/RHEL 的安装逻辑
    echo "CentOS/RHEL 的安装逻辑尚未实现。"
    exit 1
else
    echo "不支持的系统。请使用基于 Ubuntu/Debian 或 CentOS/RHEL 的系统。"
    exit 1
fi

# 启动并配置 Docker 自启动
echo "启动并配置 Docker 自启动..."
systemctl enable docker
systemctl start docker

# 安装 Docker Compose
echo "安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 验证 Docker 和 Docker Compose 版本
echo "验证 Docker 和 Docker Compose 版本..."
docker --version
docker-compose --version

echo "Docker 和 Docker Compose 安装完成！"
