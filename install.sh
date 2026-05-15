#!/usr/bin/env bash
# cbsave installer — drops scripts/cbsave on $PATH.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/danyiimp/cbsave/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/danyiimp/cbsave/main/install.sh | bash -s -- /usr/local/bin
set -euo pipefail

REPO="danyiimp/cbsave"
REF="${CBSAVE_REF:-main}"
PREFIX="${1:-${CBSAVE_PREFIX:-$HOME/.local/bin}}"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "cbsave: macOS only (uname says: $(uname -s))" >&2
  exit 1
fi

mkdir -p "$PREFIX"
URL="https://raw.githubusercontent.com/$REPO/$REF/plugins/cbsave/skills/cbsave/scripts/cbsave"
echo "→ downloading $URL"
curl -fsSL "$URL" -o "$PREFIX/cbsave"
chmod +x "$PREFIX/cbsave"

echo "✓ installed: $PREFIX/cbsave"

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *)
    echo
    echo "ℹ︎ $PREFIX is not on your PATH. Add it to your shell rc:"
    echo "    echo 'export PATH=\"$PREFIX:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    ;;
esac

echo
echo "Quick test:"
echo "    echo hello | $PREFIX/cbsave"
