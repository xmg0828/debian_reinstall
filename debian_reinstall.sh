cat > /root/debian_reinstall.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# ========= 下载 InstallNET.sh（多源 + 重试 + IPv4）=========
URL_MAIN="https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh"
URL_CDN1="https://cdn.jsdelivr.net/gh/leitbogioro/Tools@master/Linux_reinstall/InstallNET.sh"
URL_CDN2="https://github.moeyy.xyz/https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh"

download_installnet() {
  local url="$1"
  echo "⬇️  尝试下载: $url"
  for i in 1 2 3; do
    if command -v curl >/dev/null 2>&1; then
      curl -4 -fL "$url" -o InstallNET.sh && return 0
    fi
    if command -v wget >/dev/null 2>&1; then
      wget -4 -O InstallNET.sh "$url" && return 0
    fi
    echo "重试 $i/3 …"
    sleep 1
  done
  return 1
}

rm -f InstallNET.sh
download_installnet "$URL_MAIN" || download_installnet "$URL_CDN1" || download_installnet "$URL_CDN2" || {
  echo "❌ 无法下载 InstallNET.sh（主源与备用源都失败）"; exit 1;
}
chmod +x InstallNET.sh
head -n 3 InstallNET.sh || true

# ================= 交互输入 =================
# 主机名（允许默认）
read -rp "请输入主机名（留空默认 debian-server）: " hostname_input
hostname_input="${hostname_input:-debian-server}"

# 密码（必填 + 二次确认）
while true; do
  read -srp "请输入 root 密码（必填）: " password_input; echo
  [[ -z "$password_input" ]] && { echo "❌ 密码不能为空"; continue; }
  read -srp "请再次输入以确认: " password_confirm; echo
  if [[ "$password_input" != "$password_confirm" ]]; then
    echo "❌ 两次密码不一致，请重试"
  else
    break
  fi
done

# 端口（必填 + 数字 + 范围）
while true; do
  read -rp "请输入 SSH 端口（必填，1-65535）: " ssh_port
  if [[ -z "$ssh_port" ]]; then
    echo "❌ 端口不能为空"
  elif ! [[ "$ssh_port" =~ ^[0-9]+$ ]]; then
    echo "❌ 端口必须是数字"
  elif (( ssh_port < 1 || ssh_port > 65535 )); then
    echo "❌ 端口范围必须在 1-65535"
  else
    break
  fi
done

# Swap（可留空，默认为 1024）
while true; do
  read -rp "请输入 Swap 大小（MB，留空默认 1024）: " swap_input
  swap_input="${swap_input:-1024}"
  if ! [[ "$swap_input" =~ ^[0-9]+$ ]]; then
    echo "❌ Swap 必须是数字"
  else
    break
  fi
done

# ================= 执行前总览 =================
cat <<CONFIRM

即将执行重装：
  系统    : Debian 13 (bookworm)
  主机名  : $hostname_input
  SSH端口 : $ssh_port
  Swap    : ${swap_input}MB
  时区    : Asia/Shanghai
  BBR     : 开启

⚠️ 注意：该操作将清空系统并重装，SSH 将中断。
CONFIRM
read -rp "确认执行？输入 YES 继续: " go
[[ "$go" == "YES" ]] || { echo "已取消"; exit 0; }

# ================= 调用 InstallNET.sh =================
echo "🚀 执行：InstallNET.sh"
bash InstallNET.sh \
  -debian 13 \
  -port "$ssh_port" \
  -pwd "$password_input" \
  -hostname "$hostname_input" \
  -timezone "Asia/Shanghai" \
  -swap "$swap_input" \
  --bbr

echo "✅ 安装脚本执行完成，5 秒后重启..."
sleep 5
reboot
EOF

# 给权限并立即执行
chmod +x /root/debian_reinstall.sh && bash /root/debian_reinstall.sh
