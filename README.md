# Blossom Shell ❀

A reversible **bash ⇄ zsh** switcher with a zsh that's themed to match the Blossom
desktop. You don't have to read the config to use it — `enable`, try it, and
`disable` if you don't love it. **bash is never modified.**

```
blossom-shell enable      # install the themed zsh + plugins, point kitty at it
blossom-shell try         # open a Blossom zsh subshell (no install) — `exit` to leave
blossom-shell default zsh # make zsh your login shell (asks for your password)
blossom-shell disable     # undo everything, restore your originals
blossom-shell status      # what's installed / active
blossom-shell doctor      # health checks + zsh -n lint of the config
blossom-shell build-zsh   # compile zsh into ~/.local if you don't have one (no sudo)
blossom-shell system-link # make /bin/zsh point at your zsh for tools that hard-code
                          # that path (IDEs, editors); reverse: system-unlink
```

### When an IDE can't find `/bin/zsh`

If your zsh lives in `~/.local` (anything built with `build-zsh` does), tools that
hard-code `/bin/zsh` — many IDEs and editor terminals — fail to spawn it
(`ENOENT`). Run `blossom-shell system-link` once: it symlinks `/usr/bin/zsh` (and
thus `/bin/zsh`, since `/bin` → `/usr/bin`) at your real zsh and registers it in
`/etc/shells`. Because it's a **symlink**, later `build-zsh` rebuilds are picked up
automatically, and your tweaks live in `~/.zshrc` regardless of which path launched
zsh. It's the one command that touches a system path, so it asks for your password
and is undone by `system-unlink`.

## The safe path (recommended)

```
blossom-shell build-zsh   # only if `zsh` isn't already installed
blossom-shell enable      # writes ~/.zshrc + ~/.zprofile (backing up any existing
                          # ones), clones the plugins, and makes new kitty windows
                          # open zsh — WITHOUT touching your default shell
blossom-shell try         # take it for a spin right now
```

Like it? `blossom-shell default zsh`. Don't? `blossom-shell disable` and you're
exactly where you started.

## What you get (the short version)

- **Vim at the prompt** (zsh-vi-mode): Esc into normal mode with text objects
  (`ciw`, `da"`), vim-surround (`ys`/`ds`/`cs`, `S` in visual), visual mode with
  a pink selection, and a mode-aware cursor (beam→insert, block→normal).
- Fish-style **autosuggestions** from your history, **substring history search**
  on ↑/↓, and **syntax highlighting** with **rainbow bracket matching** — all
  recoloured to the Blossom palette (pink/gold/blue on the void).
- **fzf-tab** fuzzy completion menu with **vim navigation** (Ctrl-h/j/k/l,
  Ctrl-d/u) and **live previews** (dir listings via eza, file contents via bat);
  the native zsh menu (when you `disable-fzf-tab`) gets plain h/j/k/l/g/G. Plus
  **autopair** (auto-closing quotes/brackets), **you-should-use** (alias
  reminders), and **zsh-completions** (hundreds of extra completions).
- **Smarter navigation**: zoxide makes `cd blos` jump to your most-used matching
  directory from anywhere (`cdi` = interactive picker), and fzf's Ctrl-T / Alt-C /
  Ctrl-R get bordered, previewing, ❀-pointed menus.
- **Prettier everything**: `ls`/`ll`/`la`/`lt` run on eza when installed (icons,
  git status column, grouped dirs, tree view) and man pages render in Blossom
  colours — all guarded, so nothing breaks where the tools are missing.
- A two-line, git-aware **❀ prompt**: current path in gold, branch in pink,
  staged/unstaged dots, and a petal that turns red when a command fails — and
  blue/purple/gold in vi normal/visual/replace mode.
- Menu-driven, case-insensitive, **emoji-proof** tab completion: `Doc<TAB>`
  completes `📁 Documents` — typed text may land anywhere in a name, so
  emoji-prefixed paths complete from their letters (see below); a big shared
  history; sane keys.
- **All your bash aliases/env carried over** (`ll`, `claude`, the `nexus`→hermes
  wrapper, NVM/cargo/bun/PATH, …) plus a few extras (`..`, `mkcd`, git shorthands,
  `extract`, `please`).

## Emoji in paths, first-class

Names like `📁 Documents` or `🎵 Music` start with characters you can't type,
which normally strands tab completion. Blossom's completion matches in tiers —
exact prefix first, then across `._-` word breaks, then substring — and a tier
is tried only when the one before found nothing. So `cd Doc<TAB>` reaches
`📁 Documents`, plain names keep winning wherever they exist, and you never
have to type (or delete) an emoji. This works in both menus: fzf-tab's fuzzy
list and the native h/j/k/l menu (after `disable-fzf-tab`).

Three more things keep emoji paths healthy end to end:

- **Locale self-heal** (`env.zsh`): IDE terminals and bare launchers sometimes
  spawn shells with `LANG` unset or `=C`, turning emoji to mojibake. If the
  locale isn't UTF-8, the shell repairs `LC_CTYPE` from whatever UTF-8 locale
  the system has.
- **`COMBINING_CHARS`** (`options.zsh`): multi-codepoint glyphs — ❤️, flags,
  accents — occupy one cell, so the cursor can't drift after completing them.
- **Exact parents accepted as-is** (`accept-exact-dirs`): completing *inside*
  `📁 Documents/` never re-litigates the emoji component.
- **zoxide re-wired** (`plugins.zsh`): zoxide's `cd` completion hook reports
  success even when it matched nothing, which stops the tier retry cold —
  blossom wraps it to tell the truth, so the substring tier runs through
  zoxide's `cd` too.

`blossom-shell doctor` checks that your locale is UTF-8. And it's all proven
end to end: `zsh tests/emoji-completion.zsh` types real keystrokes (literal
`<TAB>`s) into a live Blossom zsh through a pty, executes the completed lines,
and asserts the shell really landed in `🎵 Music`, `👨‍👩‍👧‍👦 family`, and
friends — in both the fzf-tab and native-menu pipelines.

## Reversibility, exactly

- `enable` backs up any existing `~/.zshrc`, `~/.zprofile`, and `kitty.conf` into
  `~/.local/state/blossom-shell/backups/<timestamp>/` before writing anything.
- The files it writes carry a `blossom-shell` marker so it only ever removes its
  own; `disable` restores your backups and strips the kitty line.
- It does **not** change your login shell unless you explicitly run
  `blossom-shell default zsh` — and `blossom-shell default bash` reverts that.

## Layout

```
blossom-shell        the CLI (bash)
shell/
  env.zsh            login PATH + locale self-heal + tool inits (mirrors bash)
  init.zsh           entrypoint sourced by ~/.zshrc
  options.zsh        options, history, completion
  plugins.zsh        plugin loading + Blossom recolouring
  keys.zsh           keybindings (after plugins: zsh-vi-mode rebuilds keymaps)
  aliases.zsh        your aliases + extras (eza ls, Blossom man pages)
  prompt.zsh         the Blossom prompt (vi-mode-aware petal)
tests/
  emoji-completion.zsh  end-to-end pty proof that emoji paths tab-complete
```

Plugins are cloned to `~/.local/share/blossom-shell/plugins/` at `enable` time.

## License

GPLv3 — see [LICENSE](LICENSE). `SPDX-License-Identifier: GPL-3.0-or-later`
