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
  read -s -p "请输入root密码(必填): " password_input
  echo
  if [ -z "$password_input" ]; then
    echo "❌ 密码不能为空，请重新输入！"
  else
    break
  fi
done

# === 输入Swap大小 ===
read -p "请输入Swap大小(MB): " swap_input
if [ -z "$swap_input" ]; then
  swap_input="1024"
  echo "未输入swap大小，使用默认值: ${swap_input}MB"
fi

# === 执行安装脚本 ===
bash InstallNET.sh -debian 13 -port "22" -pwd "$password_input" -hostname "$hostname_input" -timezone "Asia/Shanghai" -swap "$swap_input" --bbr

# === 安装完成后自动重启 ===
echo "安装已完成，系统将在5秒后重启..."
sleep 5
reboot
EOF

# 给权限并立即执行
chmod +x /root/debian_reinstall.sh && bash /root/debian_reinstall.sh
