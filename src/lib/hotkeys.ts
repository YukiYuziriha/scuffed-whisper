import { register, unregister, unregisterAll } from '@tauri-apps/plugin-global-shortcut'

export type ShortcutHandler = () => void

let currentShortcut: string | null = null
let currentHandler: ShortcutHandler | null = null

export async function registerShortcut(
  shortcut: string,
  handler: ShortcutHandler,
): Promise<void> {
  await unregisterAll()
  await register(shortcut, (event) => {
    if (event.state === 'Pressed' && currentHandler) {
      currentHandler()
    }
  })
  currentShortcut = shortcut
  currentHandler = handler
}

export async function unregisterCurrentShortcut(): Promise<void> {
  if (currentShortcut) {
    await unregister(currentShortcut)
    currentShortcut = null
    currentHandler = null
  }
}

export function getCurrentShortcut(): string | null {
  return currentShortcut
}
