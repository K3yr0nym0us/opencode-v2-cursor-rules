#!/usr/bin/env bash
#
# install.sh — Instalador automático del plugin cursor-rules para OpenCode
#
# Uso:
#   git clone https://github.com/TU_USUARIO/opencode-v2-cursor-rules.git
#   cd opencode-v2-cursor-rules
#   bash install.sh
#

set -euo pipefail

# ─── Colores para output ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── Variables ────────────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.config/opencode/plugins/cursor-rules"
OPENCODE_CONFIG="${HOME}/.config/opencode/opencode.json"

# ─── Helpers ──────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

cleanup() {
  info "Limpiando archivos residuales..."
  # Eliminar el propio script
  rm -f "${REPO_DIR}/install.sh"
  # Eliminar archivos de build de TypeScript si existen
  rm -f "${REPO_DIR}/index.js" "${REPO_DIR}/index.d.ts" "${REPO_DIR}/index.js.map" "${REPO_DIR}/index.d.ts.map"
  success "Limpieza completada."
}

trap cleanup EXIT

# ─── Verificaciones previas ───────────────────────────────────────────────────
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Instalador del plugin cursor-rules para OpenCode          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

info "Verificando prerequisitos..."

if ! command -v npm &>/dev/null; then
  error "npm no está instalado. Instálalo primero."
  exit 1
fi

if [ ! -f "${REPO_DIR}/package.json" ]; then
  error "No se encontró package.json. Asegúrate de estar en la raíz del repo."
  exit 1
fi

success "Prerrequisitos OK."

# ─── Paso 1: Instalar dependencias ────────────────────────────────────────────
echo ""
info "Paso 1/3: Instalando dependencias..."

cd "${REPO_DIR}"
npm install --omit=dev --no-audit --no-fund

success "Dependencias instaladas."

# ─── Paso 2: Compilar TypeScript ──────────────────────────────────────────────
echo ""
info "Paso 2/3: Compilando TypeScript..."

if [ -f "tsconfig.json" ]; then
  npx tsc
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
