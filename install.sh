#!/usr/bin/env bash
#
# install.sh — Instalador automático del plugin cursor-rules para OpenCode
#
# Uso:
#   git clone <URL_DEL_REPO>
#   cd opencode-v2-cursor-rules
#   bash install.sh    # o: zsh install.sh    # o: sh install.sh
#

set -euo pipefail

# ─── Detectar shell y ajustar variables ───────────────────────────────────────
if [ -n "${BASH_VERSION:-}" ]; then
  SHELL_NAME="bash"
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  SHELL_NAME="zsh"
  SCRIPT_PATH="${(%):-%x}"
else
  SHELL_NAME="sh"
  SCRIPT_PATH="$0"
fi

# ─── Colores para output ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── Variables ────────────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
INSTALL_DIR="${HOME}/.config/opencode/plugins/cursor-rules"
OPENCODE_CONFIG="${HOME}/.config/opencode/opencode.json"

# ─── Helpers ──────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

cleanup() {
  info "Limpiando archivos residuales..."
  rm -f "${REPO_DIR}/install.sh"
  rm -f "${REPO_DIR}/index.js" "${REPO_DIR}/index.d.ts" "${REPO_DIR}/index.js.map" "${REPO_DIR}/index.d.ts.map"
  success "Limpieza completada."
}

trap cleanup EXIT

# ─── Detectar gestores de paquetes disponibles ─────────────────────────────────
AVAILABLE_PKGS=()

command -v npm &>/dev/null && AVAILABLE_PKGS+=("npm")
command -v yarn &>/dev/null && AVAILABLE_PKGS+=("yarn")
command -v pnpm &>/dev/null && AVAILABLE_PKGS+=("pnpm")

if [ ${#AVAILABLE_PKGS[@]} -eq 0 ]; then
  error "No se encontró ningún gestor de paquetes (npm, yarn, pnpm)."
  exit 1
fi

# ─── Seleccionar gestor de paquetes ────────────────────────────────────────────
SELECTED_PKG=""

if [ ${#AVAILABLE_PKGS[@]} -eq 1 ]; then
  SELECTED_PKG="${AVAILABLE_PKGS[0]}"
  info "Solo se encontró ${SELECTED_PKG}. Se usará automáticamente."
else
  echo ""
  info "Gestores de paquetes disponibles:"
  echo ""
  for i in "${!AVAILABLE_PKGS[@]}"; do
    echo "  $((i+1))) ${AVAILABLE_PKGS[$i]}"
  done
  echo ""

  while true; do
    read -r -p "¿Cuál deseas usar? (1-${#AVAILABLE_PKGS[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#AVAILABLE_PKGS[@]} ]; then
      SELECTED_PKG="${AVAILABLE_PKGS[$((choice-1))]}"
      break
    else
      warn "Opción inválida. Intenta de nuevo."
    fi
  done
fi

success "Gestor seleccionado: ${SELECTED_PKG}"

# ─── Verificaciones previas ───────────────────────────────────────────────────
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Instalador del plugin cursor-rules para OpenCode          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Shell detectado: ${SHELL_NAME}"
echo "  Gestor de paquetes: ${SELECTED_PKG}"
echo ""

info "Verificando prerequisitos..."

if [ ! -f "${REPO_DIR}/package.json" ]; then
  error "No se encontró package.json. Asegúrate de estar en la raíz del repo."
  exit 1
fi

success "Prerrequisitos OK."

# ─── Paso 1: Instalar dependencias ────────────────────────────────────────────
echo ""
info "Paso 1/3: Instalando dependencias con ${SELECTED_PKG}..."

cd "${REPO_DIR}"

case "${SELECTED_PKG}" in
  npm)
    npm install --omit=dev --no-audit --no-fund
    ;;
  yarn)
    yarn install --production
    ;;
  pnpm)
    pnpm install --prod
    ;;
esac

success "Dependencias instaladas."

# ─── Paso 2: Compilar TypeScript ──────────────────────────────────────────────
echo ""
info "Paso 2/3: Compilando TypeScript..."

if [ -f "tsconfig.json" ]; then
  case "${SELECTED_PKG}" in
    npm)
      npx tsc
      ;;
    yarn)
      yarn tsc
      ;;
    pnpm)
      pnpm exec tsc
      ;;
  esac
  success "TypeScript compilado."
else
  warn "No se encontró tsconfig.json. Saltando compilación."
fi

# ─── Paso 3: Instalar plugin y actualizar configuración ───────────────────────
echo ""
info "Paso 3/3: Instalando plugin en ${INSTALL_DIR}..."

if [ -d "${INSTALL_DIR}" ]; then
  warn "El plugin ya existe. Creando backup..."
  mv "${INSTALL_DIR}" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi

mkdir -p "$(dirname "${INSTALL_DIR}")"
cp -r "${REPO_DIR}" "${INSTALL_DIR}"

success "Plugin instalado en ${INSTALL_DIR}"

# ─── Actualizar configuración de OpenCode ─────────────────────────────────────
echo ""
info "Actualizando configuración de OpenCode..."

if [ -f "${OPENCODE_CONFIG}" ]; then
  if grep -q "cursor-rules" "${OPENCODE_CONFIG}"; then
    warn "El plugin ya está registrado en opencode.json. No se requieren cambios."
  else
    if command -v jq &>/dev/null; then
      jq --arg plugin "${INSTALL_DIR}" '.plugins += [$plugin]' "${OPENCODE_CONFIG}" > "${OPENCODE_CONFIG}.tmp" && \
        mv "${OPENCODE_CONFIG}.tmp" "${OPENCODE_CONFIG}"
      success "Plugin agregado a ${OPENCODE_CONFIG}"
    else
      warn "jq no está instalado. Agrega manualmente a ${OPENCODE_CONFIG}:"
      echo ""
      echo '  {'
      echo '    "plugins": ['
      echo "      \"${INSTALL_DIR}\""
      echo '    ]'
      echo '  }'
      echo ""
    fi
  fi
else
  mkdir -p "$(dirname "${OPENCODE_CONFIG}")"
  cat > "${OPENCODE_CONFIG}" <<EOF
{
  "plugins": [
    "${INSTALL_DIR}"
  ]
}
EOF
  success "Configuración creada en ${OPENCODE_CONFIG}"
fi

# ─── Resumen final ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ¡Instalación completada exitosamente!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Plugin:    cursor-rules"
echo "  Ubicación: ${INSTALL_DIR}"
echo "  Config:    ${OPENCODE_CONFIG}"
echo ""
echo "  Reinicia OpenCode para que los cambios surtan efecto."
echo ""
