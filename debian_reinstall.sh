cat > /root/debian_reinstall.sh << 'EOF'
#!/bin/bash

# === 下载原始脚本 ===
wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh'
chmod a+x InstallNET.sh

# === 输入主机名 ===
read -p "请输入主机名: " hostname_input
if [ -z "$hostname_input" ]; then
  hostname_input="debian-server"
  echo "未输入主机名，使用默认值: $hostname_input"
fi

# === 必须输入密码 ===
while true; do
  read -s -p "请输入 root 密码 (必填): " password_input
  echo
  if [ -z "$password_input" ]; then
    echo "❌ 密码不能为空，请重新输入！"
  else
    break
  fi
done

# === 必须输入 SSH 端口 ===
while true; do
  read -p "请输入 SSH 端口 (必填): " ssh_port
  if [[ -z "$ssh_port" ]]; then
    echo "❌ 端口不能为空，请重新输入！"
  elif ! [[ "$ssh_port" =~ ^[0-9]+$ ]]; then
    echo "❌ 端口必须是数字，请重新输入！"
  elif (( ssh_port < 1 || ssh_port > 65535 )); then
    echo "❌ 端口范围必须在 1-65535，请重新输入！"
  else
    break
  fi
done

# === 输入 Swap 大小 ===
read -p "请输入 Swap 大小 (MB): " swap_input
if [ -z "$swap_input" ]; then
  swap_input="1024"
  echo "未输入 Swap 大小，使用默认值: ${swap_input}MB"
fi

# === 执行安装脚本 ===
bash InstallNET.sh -debian 13 -port "$ssh_port" -pwd "$password_input" -hostname "$hostname_input" -timezone "Asia/Shanghai" -swap "$swap_input" --bbr

# === 安装完成后自动重启 ===
echo "安装已完成，系统将在 5 秒后重启..."
sleep 5
reboot
EOF

# 给权限并立即执行
chmod +x /root/debian_reinstall.sh && bash /root/debian_reinstall.sh
