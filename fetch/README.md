# Blossomfetch ❀

A Blossom-themed system fetch. Engine: **fastfetch**. Custom generated sakura
logo, adaptive colours, MB/GB memory, and a Steam-comment-safe spec block.

```
blossomfetch              full view — blossom logo + detailed, adaptive colours
blossomfetch -m|--mini    compact login greeter (the autostart one)
blossomfetch -b|--blossom force true pink/gold (overrides the adaptive palette)
blossomfetch -s|--steam [game]  Steam-safe spec block; the optional game name
                          tags the header  (add -c|--copy for clipboard)
```

## Palette is adaptive

Colours are ANSI palette *slots* (gold = the terminal's yellow, pink = magenta,
etc.), so the fetch borrows whatever terminal theme is active — warm in the
`1905` kitty theme, pink/gold under a Blossom terminal theme. `--blossom` forces
true pink/gold (`#db3776` / `#f1bf40`) for screenshots and the Steam block.

## Install

```
./install.sh              # deploy configs+logo to ~/.config/fastfetch, link
                          # blossomfetch onto PATH, add a guarded ~/.bashrc greeter
./install.sh --uninstall  # undo it (the ~/.bashrc block is marker-bounded)
```

Needs `fastfetch` (not in Mint's repos):
`sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch && sudo apt update && sudo apt install -y fastfetch`

## Autostart

The compact greeter fires **once per top-level interactive terminal** (quiet in
subshells via the exported `BLOSSOM_GREETED`, and silent until fastfetch exists).
Wired in two places: blossom-shell's `shell/init.zsh` (the Blossom zsh) and a
marker-bounded block in `~/.bashrc` (plain bash logins).

## Files

```
blossomfetch          the launcher (bash). Also hosts the --steam generator and
                      the --gpu-name / --host-name helpers used by the full config.
config-full.jsonc     full view. @PREFIX@ is rewritten to ~/.config/fastfetch.
config-mini.jsonc     compact greeter.
logo/blossom-art-gen.py   generates the 5-petal sakura logo (maths-symmetric)
logo/blossom.txt          full logo  ($1 petals / $2 core / $3 soft edge)
logo/blossom-mini.txt     mini logo
install.sh            deploy / --uninstall
```

## Notes for future me

- **MB/GB not MiB/GiB**: `display.size.binaryPrefix: "jedec"` (verified against
  the fastfetch maintainer's answer; CLI `--size-binary-prefix jedec`).
- fastfetch has **no GPU codename token** and its **host `{vendor}` is blank** on
  this board, so the full view drives those two lines through `command` modules
  calling `blossomfetch --gpu-name` / `--host-name` (Mesa + lspci + sysfs). That's
  how the GPU shows *both* "Radeon RX 6750 XT" and "(Navi 22)".
- GPU `{core-count}`/`{frequency}` need `"driverSpecific": true`.
- Colours only render on a tty; pipe a capture through `fastfetch --pipe false`.
