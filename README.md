# opencode-v2-cursor-rules

Plugin para OpenCode V2 que carga automáticamente las reglas de Cursor (`.cursor/rules/*.mdc`) en cada sesión.

## Instalación rápida (recomendada)

1. Clona el repo:

```bash
git clone https://github.com/K3yr0nym0us/opencode-v2-cursor-rules.git
cd opencode-v2-cursor-rules
```

2. Ejecuta el script de instalación:

```bash
bash install.sh
```

El script automáticamente:
1. Instala las dependencias y compila TypeScript
2. Copia el plugin a `~/.config/opencode/plugins/cursor-rules`
3. Actualiza tu `~/.config/opencode/opencode.json`
4. Limpia todos los archivos residuales (incluyendo el propio script)

## Instalación manual

Si prefieres instalar manualmente:

1. Clona el repo en tu configuración global de OpenCode:

```bash
git clone <URL_DEL_REPO> ~/.config/opencode/plugins/cursor-rules
```

2. Instala las dependencias y compila:

```bash
cd ~/.config/opencode/plugins/cursor-rules && npm install && npm run build
```

3. Agrega el plugin a tu configuración global (`~/.config/opencode/opencode.json`):

```json
{
  "plugins": [
    "~/.config/opencode/plugins/cursor-rules"
  ]
}
```

4. Reinicia OpenCode.

## Cómo funciona

- Lee automáticamente los archivos `.mdc` y `.md` de `.cursor/rules/` del proyecto actual
- Los inyecta en el system prompt de cada sesión
- Funciona para cualquier proyecto que tenga `.cursor/rules/`

## Estructura del proyecto

```
.cursor/rules/
├── general.mdc
├── standards.mdc
└── ...
```

## Desinstalación

```bash
rm -rf ~/.config/opencode/plugins/cursor-rules
```

Y elimina la entrada de tu `~/.config/opencode/opencode.json`.

## Licencia

MIT
