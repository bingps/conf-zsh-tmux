#!/usr/bin/env bash
# macOS 版本：一键配置 zsh + tmux 开发环境
# 用法： bash conf-mac.sh

set -e

# ---------------------------------------------------------------------------
# 1. 安装 Homebrew（若未安装）以及基础软件
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo ">>> Homebrew 未安装，正在安装..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apple Silicon 上 brew 默认在 /opt/homebrew，Intel 上在 /usr/local
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

brew update
# macOS 自带 zsh，但 brew 版本更新；tmux、git、python 一并安装
brew install zsh tmux git python

# ---------------------------------------------------------------------------
# 2. 写入 ~/.zshrc
# ---------------------------------------------------------------------------
cat > ~/.zshrc << 'EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew 路径（Apple Silicon / Intel 兼容）
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Make sure arrow key works.
WORDCHARS=''
bindkey '\e[1;5C' emacs-forward-word    # Ctrl-Right
bindkey '\e[1;5D' emacs-backward-word   # Ctrl-Left
bindkey '\e\e[C'  emacs-forward-word    # Option-Right (macOS Terminal)
bindkey '\e\e[D'  emacs-backward-word   # Option-Left  (macOS Terminal)
bindkey -M emacs '^H' backward-kill-word
bindkey -M emacs '^[[3~' kill-word      # Delete 键

# History
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
unsetopt SHARE_HISTORY
unsetopt INC_APPEND_HISTORY
bindkey -e

# Completion
zstyle :compinstall filename '~/.zshrc'
autoload -Uz compinit
compinit

# Plugins (auto clone on first run)
if [ -z "${ZSH}" ]; then
  if [ -d ~/.zsh/zsh-autosuggestions ]; then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
  else
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
  fi

  if [ -d ~/.zsh/zsh-syntax-highlighting ]; then
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
  fi

  if [ -d ~/powerlevel10k ]; then
    source ~/powerlevel10k/powerlevel10k.zsh-theme
  else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  fi
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# macOS 的 ls 使用 -G 来显示颜色（BSD 风格）
alias ll='ls -lG'
alias ls='ls -G'

# vi 模式（zsh 内置）
bindkey -v
bindkey '^R' history-incremental-search-backward
bindkey -M viins 'jj' vi-cmd-mode

# 个人环境变量（按需修改）
export GIT_SSH_COMMAND='ssh -i ~/.ssh/id_rsa'
export HF_HOME="$HOME/.cache/huggingface"
EOF

# ---------------------------------------------------------------------------
# 3. 写入 ~/.tmux.conf
# ---------------------------------------------------------------------------
cat > ~/.tmux.conf << 'EOF'
unbind C-b
set-option -g prefix M-s
bind-key M-s send-prefix

unbind '"'
unbind %
bind - split-window -v
bind | split-window -h

# vim-like pane resizing
bind -r C-k resize-pane -U
bind -r C-j resize-pane -D
bind -r C-h resize-pane -L
bind -r C-l resize-pane -R

# vim-like pane switching
bind -r k select-pane -U
bind -r j select-pane -D
bind -r h select-pane -L
bind -r l select-pane -R

set -g mouse on
setw -g mode-keys vi

# macOS 下 tmux 通常用 screen-256color；如想要 truecolor 可改 tmux-256color
set -g default-terminal "screen-256color"

bind-key c new-window -a

# 默认 shell 指向 brew 安装的 zsh（Apple Silicon / Intel 兼容）
if-shell "[ -x /opt/homebrew/bin/zsh ]" \
  "set-option -g default-shell /opt/homebrew/bin/zsh" \
  "set-option -g default-shell /usr/local/bin/zsh"

# Plugins —— 所有 @plugin 必须在 run tpm 之前声明
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
run '~/.tmux/plugins/tpm/tpm'
EOF

# ---------------------------------------------------------------------------
# 4. TPM（Tmux Plugin Manager）首次自动安装
# ---------------------------------------------------------------------------
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ---------------------------------------------------------------------------
# 5. readline 也使用 vi 模式
# ---------------------------------------------------------------------------
if ! grep -q "set editing-mode vi" ~/.inputrc 2>/dev/null; then
  echo "set editing-mode vi" >> ~/.inputrc
fi

# ---------------------------------------------------------------------------
# 6. 把 brew 安装的 zsh 设为默认 shell
# ---------------------------------------------------------------------------
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [ -x "$BREW_ZSH" ]; then
  if ! grep -q "$BREW_ZSH" /etc/shells; then
    echo ">>> 将 $BREW_ZSH 添加到 /etc/shells（需要 sudo 密码）"
    echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
  fi
  chsh -s "$BREW_ZSH"
fi

# ---------------------------------------------------------------------------
# 7. Git 全局配置
# ---------------------------------------------------------------------------
git config --global user.name "Guangda Liu"
git config --global user.email "bingps@users.noreply.github.com"

echo ""
echo ">>> 配置完成。请重启终端，或执行：exec zsh"
echo ">>> 进入 tmux 后按 prefix(M-s) + I 安装 tmux 插件"
