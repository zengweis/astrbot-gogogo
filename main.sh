#!/bin/bash

exec < /dev/tty
echo "========================================================="
echo "          AstrBot & NapCat 一键脚本"
echo "          脚本作者：哈基米"
echo "          github：https://github.com/zengweis/astrbot-gogogo"
echo "========================================================="
echo "请确保您已在云服务器后台（安全组）放通以下端口："
echo "           6185, 6099, 6199"
echo "========================================================="
read -p "确认已放通并继续安装吗？(y/n): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ 脚本已退出。"
    exit 1
fi


echo ""
read -p "请输入您的机器人 QQ 号: " robot_qq
if [[ -z "$robot_qq" ]]; then
    echo "❌ 错误：QQ 号不能为空。"
    exit 1
fi



echo "---------------------------------------------------------"
echo "正在检测/安装 Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt update && sudo apt install -y docker.io
else
    echo "Docker 已安装，跳过..."
fi



echo "---------------------------------------------------------"
echo "正在配置 AstrBot..."
mkdir -p ~/astrbot/data
cd ~/astrbot
sudo docker rm -f astrbot 2>/dev/null

sudo docker run -itd \
    -p 6180-6200:6180-6200 \
    -v $(pwd)/data:/AstrBot/data \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/timezone:/etc/timezone:ro \
    --name astrbot \
    soulter/astrbot:latest



echo "---------------------------------------------------------"
echo "正在通过官方脚本部署 NapCat..."


curl -o napcat_install.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh \
    && sudo bash napcat_install.sh \
    --docker y \
    --qq "$robot_qq" \
    --mode ws \
    --proxy 1 \
    --confirm



echo "---------------------------------------------------------"
echo "⏳ 正在等待 NapCat 生成 WebUI Token (约 5-10 秒)..."
sleep 8



token=$(sudo docker logs napcat 2>&1 | grep "WebUi Token" | tail -n 1 | awk -F': ' '{print $NF}')

echo ""
echo "========================================================="
echo "✅ 全部安装成功！"
echo "机器人 QQ: $robot_qq"
if [ -z "$token" ]; then
    echo "NapCat WebUI 密码：[未检测到，请在下方日志中手动查看]"
else
    echo "NapCat WebUI 密码：$token"
fi
echo "========================================================="



echo "👉 请保存好上方密码。"
read -p "按 [Enter] 回车键开始查看日志并扫码登录..." temp

echo "🚀 正在进入日志流 (查看二维码)..."
sleep 1



sudo docker logs -f napcat
