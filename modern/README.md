# modern

Fresh-start dev setup, replacing the legacy scripts in the repo root.

## zsh

| Repo file | Installs to | Notes |
| --- | --- | --- |
| `zsh/.zshenv` | `~/.zshenv` | Sets `ZDOTDIR=~/.zsh` so zsh finds the rc below |
| `zsh/.zshrc` | `~/.zsh/.zshrc` | |

```sh
mkdir -p ~/.zsh
cp zsh/.zshenv ~/.zshenv
cp zsh/.zshrc ~/.zsh/.zshrc
```

Expects (brew): `zsh-syntax-highlighting`, `zsh-history-substring-search`, `mise` (manages node — no nvm).

kubectl completion is cached at `~/.zsh/completions/_kubectl`; the rc regenerates it if missing. After upgrading kubectl:

```sh
kubectl completion zsh > ~/.zsh/completions/_kubectl
```
