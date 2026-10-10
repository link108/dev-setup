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

# cadquery master needs ocp 8, which moved Graphic3d_Camera.Projection_* under Projection_e; CQ-editor
# (0.7.0, and git master as of 2026-10) still reads the old names and dies on startup. Re-expose them.
site="$("$MAMBA_ROOT_PREFIX/envs/$ENV/bin/python" -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')"
viewer="$site/cq_editor/widgets/viewer.py"
if [[ -f "$viewer" ]] && ! grep -q 'ocp8-projection-shim' "$viewer"; then
  echo "patching CQ-editor for ocp 8"
  cat >> "$viewer" <<'EOF'

# ocp8-projection-shim (dev-setup linux/external/cadquery.sh)
if hasattr(Graphic3d_Camera, "Projection_e"):
    for _k, _v in Graphic3d_Camera.Projection_e.__members__.items():
        if not hasattr(Graphic3d_Camera, _k):
            setattr(Graphic3d_Camera, _k, _v)
EOF
fi

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/cq-editor.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=CQ-editor (CadQuery)
Comment=CadQuery editor with live 3D preview
Exec=$MAMBA_ROOT_PREFIX/envs/$ENV/bin/cq-editor %F
Icon=applications-engineering
Categories=Graphics;3DGraphics;Engineering;
EOF
