import {
  Box,
  SelectRenderable,
  SelectRenderableEvents,
  Text,
  createCliRenderer,
  type KeyEvent,
} from "@opentui/core"

const home = process.env.HOME ?? "~"
const core = process.env.DEVHUB_CORE ?? `${home}/.local/bin/devhub-core`

const actions = [
  { name: "Projekt-Workspace", description: "Session für das aktuelle Projekt öffnen", value: "sessions" },
  { name: "System prüfen", description: "Tools, Konfiguration und Logins prüfen", value: "doctor" },
  { name: "tmux lernen", description: "Shortcuts und Remote-Workflow anzeigen", value: "tmux" },
  { name: "Kurzlektionen", description: "Geführte Übungen für deinen Workflow", value: "learn" },
  { name: "Command-Bibliothek", description: "Seltene Befehle und Erinnerungen", value: "tips" },
  { name: "Auth-Zentrale", description: "Sichere Login-Anleitungen", value: "auth" },
  { name: "Setup aktualisieren", description: "Repository laden und Installer starten", value: "update" },
  { name: "Beenden", description: "devhub schliessen", value: "quit" },
]

const tips = [
  ["Ctrl-a s", "Alle tmux-Sessions und Fenster auswählen"],
  ["Ctrl-a d", "Trennen; Prozesse laufen remote weiter"],
  ["t", "Projekt-Session automatisch öffnen"],
  ["Ctrl-r", "Shell-History mit fzf durchsuchen"],
  ["rg TEXT", "Projektdateien schnell durchsuchen"],
  ["git switch -", "Zum vorherigen Branch zurückwechseln"],
]
const tip = tips[Math.floor(Date.now() / 86_400_000) % tips.length]!

const renderer = await createCliRenderer({ exitOnCtrlC: true })

const menu = new SelectRenderable(renderer, {
  id: "main-menu",
  width: "100%",
  height: "100%",
  options: actions,
  showDescription: true,
  wrapSelection: true,
  selectedBackgroundColor: "#45475a",
  selectedTextColor: "#89b4fa",
  selectedDescriptionColor: "#cdd6f4",
  textColor: "#cdd6f4",
  descriptionColor: "#7f849c",
})

const detailTitle = Text({ content: actions[0]!.name, fg: "#cba6f7" })
const detailBody = Text({ content: actions[0]!.description, fg: "#bac2de" })

const root = Box(
  { width: "100%", height: "100%", flexDirection: "column", backgroundColor: "#11111b", padding: 1, gap: 1 },
  Box(
    { height: 3, width: "100%", borderStyle: "rounded", borderColor: "#89b4fa", paddingLeft: 2, paddingRight: 2, justifyContent: "space-between", flexDirection: "row" },
    Text({ content: "devhub", fg: "#89b4fa" }),
    Text({ content: `${process.env.HOSTNAME ?? "device"}  ·  ${process.cwd().replace(home, "~")}`, fg: "#7f849c" }),
  ),
  Box(
    { flexGrow: 1, width: "100%", flexDirection: "row", gap: 1 },
    Box({ width: "45%", height: "100%", borderStyle: "rounded", borderColor: "#313244", padding: 1 }, menu),
    Box(
      { flexGrow: 1, height: "100%", flexDirection: "column", borderStyle: "rounded", borderColor: "#313244", padding: 2, gap: 1 },
      detailTitle,
      detailBody,
      Text({ content: "\nTipp des Tages", fg: "#a6e3a1" }),
      Text({ content: tip[0], fg: "#f9e2af" }),
      Text({ content: tip[1], fg: "#a6adc8" }),
    ),
  ),
  Text({ content: " ↑/↓ oder j/k navigieren  ·  Enter auswählen  ·  q beenden ", fg: "#6c7086" }),
)

async function runAction(command: string) {
  renderer.destroy()
  if (command === "quit") return
  const argv = process.platform === "win32"
    ? ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", core, command]
    : [core, command]
  const child = Bun.spawn(argv, { stdin: "inherit", stdout: "inherit", stderr: "inherit" })
  await child.exited
}

menu.on(SelectRenderableEvents.SELECTION_CHANGED, (_index, option) => {
  detailTitle.content = option.name
  detailBody.content = option.description
})
menu.on(SelectRenderableEvents.ITEM_SELECTED, async (_index, option) => {
  await runAction(String(option.value))
})
renderer.keyInput.on("keypress", async (key: KeyEvent) => {
  if (key.name === "q" || key.name === "escape") await runAction("quit")
})

renderer.root.add(root)
menu.focus()
