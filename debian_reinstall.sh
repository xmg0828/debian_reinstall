cat > /root/debian_reinstall.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# === 先下载 bin456789 的脚本 ===
curl -4 -fL -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh \
  || wget -4 -O reinstall.sh https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
chmod +x reinstall.sh

# === 输入主机名（安装后再设置） ===
read -p "请输入主机名: " hostname_input
hostname_input="${hostname_input:-debian-server}"

# === 必须输入密码 ===
while true; do
  read -s -p "请输入 root 密码 (必填): " password_input; echo
  [[ -z "$password_input" ]] && { echo "❌ 密码不能为空，请重新输入！"; continue; }
  break
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

# === 输入 Swap 大小（安装后再设置） ===
read -p "请输入 Swap 大小 (MB): " swap_input
swap_input="${swap_input:-1024}"
if ! [[ "$swap_input" =~ ^[0-9]+$ ]]; then
  echo "❌ Swap 必须是数字"; exit 1
fi

echo "🚀 开始重装：reinstall.sh debian13（仅传支持的参数）"
bash ./reinstall.sh debian13 \
  --password "$password_input" \
  --ssh-port "$ssh_port"

# 系统将重启；以下为重启后应执行的收尾命令（供参考）
cat >/root/_post_install_notes.txt <<POST
# 登录后执行以设置主机名与 Swap：
hostnamectl set-hostname "$hostname_input"
echo "127.0.1.1 $hostname_input" >> /etc/hosts

swapoff -a || true
fallocate -l ${swap_input}M /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=${swap_input}
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
POST

echo "✅ 安装脚本执行完成。将于 5 秒后重启..."
sleep 5
reboot
EOF

chmod +x /root/debian_reinstall.sh && bash /root/debian_reinstall.sh
