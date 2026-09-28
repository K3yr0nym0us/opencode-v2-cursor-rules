import { Plugin } from "@opencode/plugin"
import { readdirSync, readFileSync, existsSync } from "fs"
import { join, extname } from "path"

export default Plugin.define({
  id: "cursor-rules",
  async setup(ctx) {
    const rulesDir = join(ctx.location.directory, ".cursor", "rules")
    if (!existsSync(rulesDir)) return

    const rules: string[] = []
    const loadRules = (dir: string) => {
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        const full = join(dir, entry.name)
        if (entry.isDirectory()) loadRules(full)
        else if (extname(entry.name) === ".mdc" || extname(entry.name) === ".md") {
          const content = readFileSync(full, "utf-8")
          const body = content.replace(/^---[\s\S]*?---\n/, "")
          rules.push(`## ${entry.name.replace(/\.(mdc|md)$/, "")}\n${body.trim()}`)
        }
      }
    }
    loadRules(rulesDir)

    if (rules.length === 0) return

    await ctx.session.hook("context", (event) => {
      event.system.push({ type: "text", text: `\n\n## Cursor Rules\n\n${rules.join("\n\n")}` })
    })
  },
})
