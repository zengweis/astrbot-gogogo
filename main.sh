#!/bin/bash

# --- 1. 端口确认 ---
echo "========================================================="
echo "          AstrBot & NapCat 自动化部署脚本"
echo "          脚本作者：哈基米"
echo "          交流讨论：259279136"
echo "========================================================="
echo "请确保您已在云服务器后台（安全组）放通以下端口："
echo "           6185, 6099, 6199"
echo "========================================================="
read -p "确认已放通并继续安装吗？(y/n): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ 脚本已退出。"
    exit 1
fi

# --- 2. 交互询问 QQ 号 ---
echo ""
read -p "请输入您的机器人 QQ 号: " robot_qq
if [[ -z "$robot_qq" ]]; then
    echo "❌ 错误：QQ 号不能为空。"
    exit 1
fi

# --- 3. 安装 Docker ---
echo "---------------------------------------------------------"
echo "正在安装 Docker..."
sudo apt update
sudo apt install -y docker.io

# --- 4. 部署 AstrBot ---
echo "---------------------------------------------------------"
echo "正在配置 AstrBot..."
mkdir -p ~/astrbot/data
cd ~/astrbot

# 停止并删除同名容器（防止报错）
sudo docker rm -f astrbot 2>/dev/null

sudo docker run -itd \
    -p 6180-6200:6180-6200 \
    -v $(pwd)/data:/AstrBot/data \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/timezone:/etc/timezone:ro \
    --name astrbot \
    soulter/astrbot:latest

# --- 5. 部署 NapCat ---
echo "---------------------------------------------------------"
echo "正在下载并安装 NapCat (QQ: $robot_qq)..."
curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh \
    && sudo bash napcat.sh \
    --docker y \
    --qq "$robot_qq" \
    --mode ws \
    --proxy 1 \
    --confirm

# --- 6. 完成提示与日志查看 ---
echo ""
echo "========================================================="
echo "✅ 全部安装成功！"
echo "机器人 QQ: $robot_qq"
echo "5 秒后将自动跳转至 NapCat 日志查看扫码登录..."
echo "========================================================="

sleep 5

# 查看 NapCat 日志（使用 -f 持续输出直到你按 Ctrl+C）
sudo docker logs -f napcat