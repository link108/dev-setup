# Options
setopt PROMPT_SUBST      # Allow variable substitution in the prompt (vcs_info)
setopt append_history
setopt histignoredups    # Ignore duplicate commands in storing commands
setopt extendedglob      # weird & wacky pattern matching (also needed for the compinit dump-age check below)
unsetopt beep
unsetopt autocd

# Cached completions (e.g. _kubectl) must be in fpath before compinit runs.
# Self-heals if the cache is missing; regenerate manually after upgrading kubectl:
#   kubectl completion zsh > ~/.zsh/completions/_kubectl
if [[ ! -f ~/.zsh/completions/_kubectl ]] && command -v kubectl >/dev/null; then
  mkdir -p ~/.zsh/completions
  kubectl completion zsh > ~/.zsh/completions/_kubectl
fi
fpath=(~/.zsh/completions $fpath)

autoload -Uz +X promptinit && promptinit
autoload -Uz +X bashcompinit && bashcompinit

# compinit: skip the (slow) security audit when the dump was refreshed in the last 24h
autoload -Uz +X compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh-24) ]]; then
  compinit -C
else
  compinit
fi

#Right hand side of prompt
#RPROMPT=$'%.%'
#Left hand side of prompt

#PS1='%F{blue}%B%K{blue}█▓▒░%F{white}%K{blue}%B%n@%m%b%F{blue}%K{black}█▓▒░%F{white}%K{black}%B %D{%a %b %d} %D{%I:%M:%S%P}
#%}%F{fadebar_cwd}%K{black}%B%/%b%k%f${vcs_info_msg_0_} '
PS1='%~ ${vcs_info_msg_0_}$ '

# History
# Histfile and size
HISTFILE=~/.zsh_histfile
HISTSIZE=10000
SAVEHIST=10000

# Share history between terminals right away
#setopt inc_append_history
#setopt share_history

# ZSH Line Editor use emacs settings
bindkey -e

# Use bash word style (ie meta+delete)
# http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#ZLE-Functions
autoload -U select-word-style
select-word-style bash


# The following lines were added by compinstall
zstyle :compinstall filename '/Users/cmotevasselani/.zshrc'


if [[ $TERM == "xterm-kitty" ]]
then
  kitty + complete setup zsh | source /dev/stdin
fi


# VC Info
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' actionformats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f '
zstyle ':vcs_info:(git):*' branchformat '%b%F{1}:%F{3}%r'

#Things to execute before each command
precmd () {
    vcs_info
}

# TODO add this as part of setup script
# https://docs.brew.sh/Shell-Completion
# ZSH-Completions
# fpath=(/usr/local/share/zsh-completions $fpath)
#MOVED export PATH=$HOME/bin:$PATH

# Node is managed by mise (see `mise activate` at the bottom of this file)

# Aliases


# Emacs
alias em='emacsclient -nw'

alias ll='ls -alh'

# Searching aliases
#alias ls='ls --color=auto'
alias ls='ls -G'
alias grep='grep --color=auto'
alias ack='ack --color'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias less='less -R'


# TODO Git aliases
#cool log/graph: log --pretty=oneline -n 20 --graph --abbrev-commit

# Kubectl functions/aliases
alias k='kubectl'
# kubectl completion loads from the cached ~/.zsh/completions/_kubectl (see fpath above)



# TODO add these as part of setup
# Source scripts
source /opt/homebrew/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/opt/zsh-history-substring-search/share/zsh-history-substring-search/zsh-history-substring-search.zsh
# TODO determine if sdkman is the right way to go, currently using brew to download different jdks
#source "$HOME/.sdkman/bin/sdkman-init.sh"


#bindkey "$terminfo[kcuu1]" history-substring-search-up
#bindkey "$terminfo[kcud1]" history-substring-search-down

bindkey "^p" history-substring-search-up
bindkey "^n" history-substring-search-down


# TOOD rbenv vs rvm?
# rbenv init
# eval "$(rbenv init -)"

# TODO is this useful? haven't been using it
# . /usr/local/etc/profile.d/z.sh

tail_pods() {
  if (( # != 2 )); then
    echo "Usage: tail_pods <context> <namespace>"
    return -1
  fi
  CMD="multitail $(k --context $1 --namespace $2 get pods -o json | jq ".items[].metadata.name" | jq --slurp | jq -r 'map("-l \"kubectl --context $1 --namespace $2 logs -f " + . + "\"") | join(" ")')"
  eval $CMD
}

build_slim() {
  docker build -t compile -f Dockerfile.compile . && docker build -f Dockerfile.slim .
}

reload_zsh() {
  source ~/.zshenv
  source ~/.zsh/.zshrc
}

#if [ -f $(brew --prefix)/share/bash_completion ]; then
#  . $(brew --prefix)/etc/bash_completion
#fi
run_last_docker_build() {
  docker run $(docker images -q | head -n 1)
}

exec_last_docker_run() {
  docker exec -it $(docker ps  -q) /bin/bash
}


eval "$(mise activate zsh)"
