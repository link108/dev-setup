alias ll='ls -ltFrh'
alias git_tree='git log --pretty=oneline --decorate --graph'
eval "$(rbenv init -)"



export PYENV_ROOT=/usr/local/var/pyenv
export PATH=$PATH:~/bin:/usr/local/sbin


export WORKON_HOME=$HOME/.virtualenvs

# Need to fix this, sourcing twice kills the shell ><
source `which virtualenvwrapper.sh`
eval "$(pyenv init -)"
export PROJECT_HOME=$HOME/projects



export NVM_DIR="$HOME/.nvm"
. "$(brew --prefix nvm)/nvm.sh"



if [ -f $(brew --prefix)/etc/bash_completion ]; then
. $(brew --prefix)/etc/bash_completion
fi


export LESSOPEN="| src-hilite-lesspipe.sh %s"
export LESS=" -R"

#alias grep="grep --color=always"
alias grep="grep --color=auto"
alias ack="ack --color"

man() {
    env \
        LESS_TERMCAP_mb=$'\e[1;31m' \
        LESS_TERMCAP_md=$'\e[1;31m' \
        LESS_TERMCAP_me=$'\e[0m' \
        LESS_TERMCAP_se=$'\e[0m' \
        LESS_TERMCAP_so=$'\e[1;44;33m' \
        LESS_TERMCAP_ue=$'\e[0m' \
        LESS_TERMCAP_us=$'\e[1;32m' \
            man "$@"
}
