

autoload -Uz +X promptinit && promptinit
autoload -Uz +X bashcompinit && bashcompinit
autoload -Uz +X compinit && compinit

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
setopt append_history
#setopt share_history

# make shell stop beeping
unsetopt beep

# Do not turn on auto-cd
unsetopt autocd

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
    #Set options
    setopt PROMPT_SUBST     #Used to set certain variables without recreating prompt
    #setopt correctall    #Spelling corrections for commands and arguments
    setopt histignoredups    #Ignore duplicate commands in storing commands
    setopt extendedglob    #weird & wacky pattern matching

    vcs_info
}

# TODO add this as part of setup script
# https://docs.brew.sh/Shell-Completion
# ZSH-Completions
# fpath=(/usr/local/share/zsh-completions $fpath)
#MOVED export PATH=$HOME/bin:$PATH

# NVM
#MOVED export NVM_DIR="$HOME/.nvm"
#. "/usr/local/opt/nvm/nvm.sh"
## OLD
#source "/usr/local/opt/nvm/nvm.sh"
export NVM_DIR="$HOME/.nvm"
source $(brew --prefix nvm)/nvm.sh
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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
source <(kubectl completion zsh)



# TODO add these as part of setup
# Source scripts
source $(brew --prefix zsh-syntax-highlighting)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix zsh-history-substring-search)/share/zsh-history-substring-search/zsh-history-substring-search.zsh
# TODO determine if sdkman is the right way to go, currently using brew to download different jdks
#source "$HOME/.sdkman/bin/sdkman-init.sh"


#bindkey "$terminfo[kcuu1]" history-substring-search-up
#bindkey "$terminfo[kcud1]" history-substring-search-down

bindkey "^p" history-substring-search-up
bindkey "^n" history-substring-search-down
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/cmotevasselani/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/cmotevasselani/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/cmotevasselani/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/cmotevasselani/Downloads/google-cloud-sdk/completion.zsh.inc'; fi




# Go development

#MOVED export GOPATH=$HOME/go
#MOVED export GOROOT=/usr/local/opt/go/libexec
#MOVED export PATH=$PATH:$GOPATH/bin:$GOROOT/bin

export PATH="/usr/local/opt/go@1.12/bin:$PATH"

# add option to take in hal config location
alias start_armory_docker='docker run --name armory-halyard --rm \
    -v ~/.hal:/home/spinnaker/.hal \
    -v ~/.kube:/home/spinnaker/.kube \
    -v ~/.aws:/home/spinnaker/.aws \
    -it docker.io/armory/halyard-armory:1.8.2'

alias kill_halyard="kill $(ps -ef | grep halyard | grep -v grep | head -1 | awk '{print $2}')"

complete -C /usr/local/bin/vault vault

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
vault_login() {
  vault login -method=okta username=cameron.motevasselani@armory.io
}


goto_jenkins() {
  INTERNAL_CONTEXT=gke-internal
  kubectl --context=$INTERNAL_CONTEXT --namespace=jenkins exec -it  $(kubectl --context=$INTERNAL_CONTEXT --namespace=jenkins get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' --sort-by=".status.startTime" | grep --color=none jenkins | tail -n 1) --container jenkins bash
}


run_last_docker_build() {
  docker run $(docker images -q | head -n 1)
}

exec_last_docker_run() {
  docker exec -it $(docker ps  -q) /bin/bash
}


