# opencode-v2-cursor-rules

Plugin para OpenCode V2 que carga automáticamente las reglas de Cursor (`.cursor/rules/*.mdc`) en cada sesión.

## Instalación

1. Clona el repo en tu configuración global de OpenCode:

```bash
git clone https://github.com/TU_USUARIO/opencode-v2-cursor-rules.git ~/.config/opencode/plugins/cursor-rules
```

2. Instala las dependencias:

```bash
cd ~/.config/opencode/plugins/cursor-rules && npm install
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
├── kyp-development-standards.mdc
└── ...
```

## Licencia

MIT
