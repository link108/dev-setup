# Portable zshrc (Linux + macOS). Machine-specific bits go in ~/.zshrc.local

# PATH
typeset -U path
path=("$HOME/.local/bin" "$HOME/bin" $path)

# Completion
autoload -Uz compinit && compinit
autoload -Uz bashcompinit && bashcompinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt hist_ignore_dups
setopt extended_glob

# make shell stop beeping
unsetopt beep
unsetopt autocd

# set EOL for unterminated lines to be empty string instead of %
PROMPT_EOL_MARK=""

# ZSH Line Editor use emacs settings, bash word style (ie meta+delete)
bindkey -e
autoload -U select-word-style
select-word-style bash

# ^p / ^n search history for lines starting with what's already typed
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^p" up-line-or-beginning-search
bindkey "^n" down-line-or-beginning-search

# alt(option)+left/right jump words (alt+b/f/backspace already work via emacs mode)
bindkey "^[[1;3D" backward-word
bindkey "^[[1;3C" forward-word

# Prompt with VC info
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' actionformats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f '
setopt prompt_subst
precmd() { vcs_info }
PS1='%~ ${vcs_info_msg_0_}$ '

# Aliases
alias ll='ls -alh'
alias grep='grep --color=auto'
alias less='less -R'
alias k='kubectl'
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
  # Debian/Ubuntu ship fd as fdfind
  (( $+commands[fdfind] && ! $+commands[fd] )) && alias fd='fdfind'
fi
export EDITOR=vim VISUAL=vim

# Tools
(( $+commands[mise] )) && eval "$(mise activate zsh)"
(( $+commands[kubectl] )) && source <(kubectl completion zsh)
if (( $+commands[fzf] )); then
  # fzf >= 0.48 has --zsh; older apt versions ship the scripts as examples
  if fzf --zsh &>/dev/null; then
    source <(fzf --zsh)
  elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  fi
fi

reload_zsh() {
  source ~/.zshrc
}

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Plugins (apt: zsh-autosuggestions zsh-syntax-highlighting). syntax-highlighting must be last.
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  for dir in /usr/share/$plugin /usr/share/zsh/plugins/$plugin /opt/homebrew/share/$plugin /usr/local/share/$plugin; do
    if [[ -f $dir/$plugin.zsh ]]; then
      source $dir/$plugin.zsh
      break
    fi
  done
done
unset plugin dir
