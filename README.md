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

- Fish-style **autosuggestions** from your history, **substring history search**
  on ↑/↓, and **syntax highlighting** as you type — all recoloured to the Blossom
  palette (pink/gold/blue on the void).
- **fzf-tab** fuzzy completion menu with **vim navigation** (Ctrl-h/j/k/l,
  Ctrl-d/u); the native zsh menu (when you `disable-fzf-tab`) gets plain
  h/j/k/l/g/G. Plus **autopair** (auto-closing quotes/brackets), **you-should-use**
  (alias reminders), and **zsh-completions** (hundreds of extra completions).
- A two-line, git-aware **❀ prompt**: current path in gold, branch in pink,
  staged/unstaged dots, and a petal that turns red when a command fails.
- Menu-driven, case-insensitive tab completion; a big shared history; sane keys.
- **All your bash aliases/env carried over** (`ll`, `claude`, the `nexus`→hermes
  wrapper, NVM/cargo/bun/PATH, …) plus a few extras (`..`, `mkcd`, git shorthands,
  `extract`, `please`).

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
  env.zsh            login PATH + tool inits (mirrors your bash env)
  init.zsh           entrypoint sourced by ~/.zshrc
  options.zsh        options, history, completion, keybindings
  aliases.zsh        your aliases + extras
  prompt.zsh         the Blossom prompt
  plugins.zsh        plugin loading + Blossom recolouring
```

Plugins are cloned to `~/.local/share/blossom-shell/plugins/` at `enable` time.

## License

GPLv3 — see [LICENSE](LICENSE). `SPDX-License-Identifier: GPL-3.0-or-later`
