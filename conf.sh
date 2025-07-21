apt update && apt install zsh tmux
cat > ~/.zshrc << EOF
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Make sure arrow key works.
WORDCHARS=''
bindkey '\e[1;5C' emacs-forward-word    # Ctrl-Right
bindkey '\e[1;5D' emacs-backward-word   # Ctrl-Left
bindkey -M emacs '^H' backward-kill-word
bindkey -M emacs '5~' kill-word

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
if [ -d ~/.zsh/zsh-autosuggestions ]; then
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
else
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
fi
# source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if [ -d ~/powerlevel10k ]; then
  source ~/powerlevel10k/powerlevel10k.zsh-theme
else
  git clone https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
alias ll='ls -l --color=auto'

bindkey -v
bindkey '^R' history-incremental-search-backward
bindkey -M viins 'jj' vi-cmd-mode
EOF

cat > ~/.tmux.conf << EOF
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

set -g default-terminal "screen-256color"


set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
run '~/.tmux/plugins/tpm/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

bind-key c new-window -a

bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel 'reattach-to-user-namespace pbcopy'
bind-key -T copy-mode-vi Enter send -X copy-pipe-and-cancel 'reattach-to-user-namespace pbcopy
EOF
