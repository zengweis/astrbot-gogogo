#!/bin/bash

# --- 1. 环境准备与大陆代理配置 ---
exec < /dev/tty
clear
echo "========================================================="
echo "          AstrBot & NapCat 自动化部署脚本"
echo "          脚本作者：哈基米 | 交流讨论：259279136"
echo "========================================================="

# 询问是否在国内
read -p "❓ 服务器是否处于中国大陆境内？(y/n): " is_china

PROXY_PREFIX=""
if [[ "$is_china" == "y" || "$is_china" == "Y" ]]; then
    echo "💡 已开启大陆加速模式..."
    PROXY_PREFIX="https://ghproxy.net/"
    
    # 配置 Docker 镜像加速 (针对系统级安装后)
    sudo mkdir -p /etc/docker
    echo '{
      "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://huecker.io",
        "https://dockerhub.timeweb.cloud",
        "https://noohub.ru"
      ]
    }' | sudo tee /etc/docker/daemon.json > /dev/null
fi

# --- 2. 端口确认 ---
echo "---------------------------------------------------------"
echo "请确保云服务器安全组已放通端口：6185, 6099, 6199"
read -p "确认已放通并继续安装吗？(y/n): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && echo "❌ 脚本已退出。" && exit 1

# --- 3. 交互询问 QQ 号 ---
read -p "请输入您的机器人 QQ 号: " robot_qq
[[ -z "$robot_qq" ]] && echo "❌ 错误：QQ 号不能为空。" && exit 1

# --- 4. 安装 Docker ---
echo "---------------------------------------------------------"
echo "正在检测/安装 Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt update && sudo apt install -y docker.io
    # 如果是大陆机器，安装后重启 docker 使刚才配置的 daemon.json 生效
    [[ "$is_china" == "y" ]] && sudo systemctl restart docker
else
    echo "Docker 已安装，跳过..."
fi

# --- 5. 部署 AstrBot ---
echo "---------------------------------------------------------"
echo "正在配置 AstrBot..."
mkdir -p ~/astrbot/data
cd ~/astrbot
sudo docker rm -f astrbot 2>/dev/null

# 拉取镜像（若是大陆则手动指定 prefix 尝试，或依赖 daemon.json）
sudo docker run -itd \
    -p 6180-6200:6180-6200 \
    -v $(pwd)/data:/AstrBot/data \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/timezone:/etc/timezone:ro \
    --name astrbot \
    soulter/astrbot:latest

# --- 6. 部署 NapCat ---
echo "---------------------------------------------------------"
echo "正在部署 NapCat..."
# 使用 PROXY_PREFIX 下载脚本
curl -o napcat_install.sh "${PROXY_PREFIX}https://raw.githubusercontent.com/NapNeko/NapCat-Installer/main/script/install.sh" \
    && sudo bash napcat_install.sh \
    --docker y \
    --qq "$robot_qq" \
    --mode ws \
    --proxy $( [[ "$is_china" == "y" ]] && echo "1" || echo "0" ) \
    --confirm

# --- 7. 提取 WebUi Token ---
echo "---------------------------------------------------------"
echo "⏳ 正在等待 NapCat 生成 WebUI Token..."
sleep 10
token=$(sudo docker logs napcat 2>&1 | grep "WebUi Token" | tail -n 1 | awk -F': ' '{print $NF}')

# --- 8. 清理工作 ---
if [[ "$is_china" == "y" ]]; then
    echo "🧹 正在清理大陆代理配置..."
    sudo rm -f /etc/docker/daemon.json
    sudo systemctl restart docker
fi

echo ""
echo "========================================================="
echo "✅ 全部安装成功！"
echo "机器人 QQ: $robot_qq"
echo "NapCat WebUI 密码：${token:-[请在下方日志中手动查看]}"
echo "========================================================="

read -p "👉 按 [Enter] 键开始查看日志并扫码登录..." temp
sudo docker logs -f napcat
