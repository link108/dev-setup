


# cloud sdk for ssh'ing to jenkins
# TODO remove when able to
export CLOUDSDK_PYTHON=python2

# NVM
export NVM_DIR="$HOME/.nvm"

# GO
export GOPATH=$HOME/dev/go
export GOBIN=$GOPATH/bin
export GOARMORY=$GOPATH/src/github.com/armory-io/
export GOPRIVATE=github.com/armory-io
export GONOSUMDB=github.com/armory-io
export GO111MODULE=on

#export GOROOT=/usr/local/opt/go/libexec


# ZSH
export ZDOTDIR=.zsh


# PATH
export PATH=$HOME/bin:$PATH:$GOBIN:$GOROOT/bin


# set EOL for unterminated lines to be empty string
# instead of %
export PROMPT_EOL_MARK=""

# Not entirely sure what these do
setopt PROMPT_CR
setopt PROMPT_SP

# Kubernetes default namespace, may want to remove
export KUBERNETES_NAMESPACE=cam



# Vault address
export VAULT_ADDR='http://vault.engineering.armory.io:8200'


# Groovy location
export GROOVY_HOME=/usr/local/opt/groovy/libexec
export VAULT_ADDR=https://vault.engineering.armory.io

# Java location, default to jdk 11
export JAVA_HOME=/Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home
