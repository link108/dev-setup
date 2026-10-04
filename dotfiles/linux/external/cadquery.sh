#!/usr/bin/env bash
set -euo pipefail

# CadQuery + CQ-editor (its GUI) in a micromamba env, the route CadQuery recommends since it
# bundles the OpenCASCADE kernel. cq-editor=master (cadquery channel) pulls cadquery master; projects
# pinning a release keep their own env (reliquary-works: `micromamba env create -f environment.yml`).
# Use: CQ-editor from the menu, or `micromamba run -n cadquery python model.py`.

BIN="$HOME/.local/bin/micromamba"
export MAMBA_ROOT_PREFIX="$HOME/micromamba"
ENV=cadquery

if [[ ! -x "$BIN" ]]; then
  echo "installing micromamba to $BIN"
  mkdir -p "$(dirname "$BIN")"
  curl -fsSL https://micro.mamba.pm/api/micromamba/linux-64/latest \
    | tar -xj -C "$(dirname "$BIN")" --strip-components=1 bin/micromamba
fi

if [[ -d "$MAMBA_ROOT_PREFIX/envs/$ENV" ]]; then
  echo "micromamba env '$ENV' already exists"
else
  "$BIN" create -y -n "$ENV" -c cadquery -c conda-forge python=3.12 cq-editor=master
fi

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/cq-editor.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=CQ-editor
Comment=CadQuery editor with live 3D preview
Exec=$MAMBA_ROOT_PREFIX/envs/$ENV/bin/cq-editor %F
Icon=applications-engineering
Categories=Graphics;3DGraphics;Engineering;
EOF
