#!/usr/bin/env bash
# migrate-to-newmac.sh
# 在全新 Mac 上 bootstrap nix-darwin 极简配置（远程登录瘦客户端）。
#
# 使用方法（在新 Mac 上）:
#   curl -fsSL https://raw.githubusercontent.com/YuntaoLincs/nixos_config/main/migrate-to-newmac.sh -o /tmp/migrate.sh
#   bash /tmp/migrate.sh

set -euo pipefail

REPO_HTTPS="https://github.com/YuntaoLincs/nixos_config.git"
REPO_SSH="git@github.com:YuntaoLincs/nixos_config.git"
REPO_DIR="$HOME/nix-darwin"
FLAKE_KEY="newmac"
EXPECTED_USER="linyuntao"
GIT_EMAIL="stevelin314159@gmail.com"

bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }

step() {
  echo
  bold "==> $*"
}

pause() {
  read -r -p "$(yellow "$*  [按回车继续]") " _
}

# -------- 1. 前置检查 --------
step "[1/6] 前置检查"

if [ "$(uname -s)" != "Darwin" ]; then
  red "本脚本只在 macOS 上运行。"; exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  red "本脚本针对 Apple Silicon (arm64)。检测到 $(uname -m)。"; exit 1
fi

if [ "$(whoami)" != "$EXPECTED_USER" ]; then
  red "system.primaryUser 在 flake 里写死为 '$EXPECTED_USER'，但当前用户是 '$(whoami)'。"
  red "请用 $EXPECTED_USER 这个用户名登录后再跑。"
  exit 1
fi

if [ -e /opt/homebrew ]; then
  red "/opt/homebrew 已存在。nix-homebrew 需要接管这个目录，必须先卸载已有 Homebrew："
  red "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
  exit 1
fi

green "✓ 前置检查通过"

# -------- 2. 安装 Determinate Nix --------
step "[2/6] 安装 Nix (Determinate)"

if command -v nix >/dev/null 2>&1; then
  green "✓ Nix 已安装：$(nix --version)"
else
  yellow "即将通过 Determinate 安装器安装 Nix。"
  pause "安装过程会提示输入 sudo 密码"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  # shellcheck disable=SC1091
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  if ! command -v nix >/dev/null 2>&1; then
    red "Nix 安装后未能 source 进当前 shell。请新开一个终端窗口，重新跑本脚本。"
    exit 1
  fi
  green "✓ Nix 安装完成：$(nix --version)"
fi

# -------- 3. 生成 SSH key 并提示加到 GitHub --------
step "[3/6] 生成 GitHub SSH 密钥"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$HOME/.ssh/id_ed25519" ]; then
  yellow "~/.ssh/id_ed25519 已存在，跳过生成。"
else
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
  green "✓ 已生成 ed25519 密钥对"
fi

echo
bold "------------ 公钥内容（复制下面这一段） ------------"
cat "$HOME/.ssh/id_ed25519.pub"
bold "----------------------------------------------------"
echo
yellow "把上面这把公钥添加到 GitHub：https://github.com/settings/ssh/new"
yellow "Title 随便写（例如：new-mac-$(date +%Y%m%d)），Key type 选 Authentication Key。"
pause "加好后回到这里"

echo
yellow "测试 SSH 连通性（出现 'successfully authenticated' 即可，exit code 1 是正常的）："
ssh -o StrictHostKeyChecking=accept-new -T git@github.com || true

# -------- 4. Clone 仓库 --------
step "[4/6] Clone 仓库到 $REPO_DIR"

if [ -d "$REPO_DIR/.git" ]; then
  yellow "$REPO_DIR 已是 git 仓库，跳过 clone。"
else
  # 先用 HTTPS clone（即使 SSH 还没就绪也能成功），然后切到 SSH
  git clone "$REPO_HTTPS" "$REPO_DIR"
fi

git -C "$REPO_DIR" remote set-url origin "$REPO_SSH"
green "✓ 仓库 remote 已切到 SSH：$(git -C "$REPO_DIR" remote get-url origin)"

# -------- 5. Bootstrap nix-darwin --------
step "[5/6] 构建并切换 nix-darwin 配置 (#$FLAKE_KEY)"

yellow "这一步会通过 sudo 执行 darwin-rebuild bootstrap，可能需要几分钟下载和构建。"
pause "准备好后按回车"

cd "$REPO_DIR"
sudo nix run nix-darwin -- switch --flake ".#$FLAKE_KEY"

green "✓ nix-darwin 已就绪。后续日常更新命令：update（已写入 zsh shellAliases）"

# -------- 6. 收尾提示 --------
step "[6/6] 完成。还需要手动做的事："

cat <<'EOF'

  1. Tailscale 登录（用于 SSH 到老 Mac）：
       sudo tailscale up
     登录后用 `tailscale status` 看到老 Mac 的设备名/IP。

  2. SSH 到老 Mac 测试：
       ssh linyuntao@<老机的 tailscale 名或 IP>
     如果老 Mac 的 ~/.ssh/authorized_keys 没有这台新机的 ed25519 公钥，
     先在老 Mac 上把新机的 ~/.ssh/id_ed25519.pub 加进去。

  3. iTerm2 偏好（可选）：
     iTerm2 → Preferences → General → Preferences →
     勾选 "Load preferences from a custom folder or URL"，
     从老 Mac 的 ~/Library/Preferences/com.googlecode.iterm2.plist 同步过来。

  4. 已知约束：
     - /opt/homebrew 现在由 nix-homebrew 管理，不要再手动 `brew install`，
       需要装新 GUI 应用就改 flake.nix 中 newmacConfiguration.homebrew.casks。
     - default editor 已经是 helix（设置在 home-newmac.nix）。

  日常更新配置：
       update                              # zsh alias，等价于：
       sudo darwin-rebuild switch --flake ~/nix-darwin#newmac

EOF

green "==== 全部完成 ===="
