# Keybinding convention

One grammar across the stack so muscle memory transfers. If a new binding
breaks these rules, change the binding — not the rules.

Notation in this file: `C-b` = Ctrl+b, `SPC` = Space, `C-w` = Ctrl+w.
Keys after a prefix are pressed in sequence (release Ctrl unless written
as a chord).

*(custom)* = defined in this repo. Everything else is a stock default worth
memorizing.

## Layers (who owns what)

```
WezTerm     →  renderer only. No leader. No pane/split keys.
tmux        →  multiplexing. Prefix = Ctrl+b.
Neovim      →  editing. Leader = Space. Window focus = Ctrl+hjkl.
```

| Intent | Owner | Chord family |
|---|---|---|
| OS window / font / quit app | WezTerm / OS defaults | leave alone |
| Sessions, windows, panes | tmux | `Ctrl+b` then … |
| Edit buffer, splits inside editor | Neovim | `Space` … or `Ctrl+hjkl` |
| Escape insert mode | Neovim | `jk` *(custom)* or `Esc` |

## Hard rules

1. **hjkl means direction** everywhere (tmux panes, Neovim windows, motions).
   On QWERTY they sit on one row (`H J K L`); the mapping is:
   `h` ← left, `j` ↓ down, `k` ↑ up, `l` → right.
   Left/right follow position (h leftmost, l rightmost); remember **j = down**,
   **k = up**.
2. **tmux prefix is `Ctrl+b`** — never remap; never steal it in WezTerm.
3. **Neovim leader is `Space`** — all custom commands are `Space` + mnemonic.
4. **Lowercase = navigate / act; uppercase = resize / stronger variant**
   (tmux: `h` focus, `H` resize).
5. **Splits: `|` vertical bar → side-by-side; `-` → stacked** (tmux).
6. **New bindings need a home** in this file before they land in config.
7. **GUI IDEs (Cursor / VS Code / CLion) are exempt** — use their defaults.

## Why tmux panes and Neovim windows differ

| Context | Move focus |
|---|---|
| Between **tmux panes** | `C-b` then `h/j/k/l` *(custom)* |
| Between **Neovim splits** | `C-h/j/k/l` *(custom)* |

Inside Neovim, `C-h` moves an editor split — not a tmux pane. To change tmux
panes, always hit the prefix first.

---

## Commonly used commands

Reach for this section when you forget how to do a basic thing.

### Neovim — modes (you must know this)

Neovim is **modal**. Most keys do different things depending on the mode.

| Mode | How you get there | What it’s for |
|---|---|---|
| Normal | start here; `Esc` or `jk` *(custom)* from insert | move, delete, yank, run commands |
| Insert | `i` / `a` / `o` / `O` from normal | type text |
| Visual | `v` (char), `V` (line), `C-v` (block) | select, then operate |
| Command-line | `:` from normal | ex commands (`:w`, `:q`, …) |

If keys seem “broken”, you are probably in the wrong mode — hit `Esc`.

### Neovim — save, quit, files

| Chord / command | Action |
|---|---|
| `SPC w` *(custom)* or `:w` `Enter` | Save |
| `:w filename` `Enter` | Save as |
| `SPC q` *(custom)* or `:q` `Enter` | Quit (fails if unsaved) |
| `:q!` `Enter` | Quit **without** saving |
| `:wq` / `:x` `Enter` | Save and quit |
| `:e path` `Enter` | Open file |
| `:e!` `Enter` | Reload file from disk (discard buffer changes) |

### Neovim — leave insert / undo / clipboard

| Chord | Action |
|---|---|
| `jk` *(custom)* or `Esc` | Back to normal mode |
| `u` | Undo |
| `C-r` | Redo |
| `y` (after a motion or visual select) | Yank (copy) |
| `p` / `P` | Paste after / before cursor |
| `d` + motion | Delete (also yanks) |
| `c` + motion | Change (delete + insert) |
| `x` | Delete character under cursor |
| `dd` | Delete line |
| `yy` | Yank line |

System clipboard is enabled (`unnamedplus`) — `y`/`p` talk to the OS pasteboard.

### Neovim — motion (normal mode)

| Chord | Action |
|---|---|
| `h/j/k/l` | Left / down / up / right |
| `w` / `b` | Next / previous word |
| `e` | End of word |
| `0` / `^` / `$` | Start of line / first non-blank / end of line |
| `gg` / `G` | Top / bottom of file |
| `{n}G` or `:{n}` | Go to line *n* |
| `C-d` / `C-u` | Half-page down / up |
| `C-f` / `C-b` | Page down / up |
| `%` | Jump matching `()` / `[]` / `{}` |
| `*` / `#` | Next / previous occurrence of word under cursor |

Relative line numbers are on — `10j` means “down 10 lines”.

### Neovim — search and replace

| Chord / command | Action |
|---|---|
| `/pattern` `Enter` | Search forward |
| `?pattern` `Enter` | Search backward |
| `n` / `N` | Next / previous match |
| `Esc` *(custom)* | Clear search highlight |
| `:nohlsearch` | Same, via command |
| `:s/old/new/` | Replace first on line |
| `:s/old/new/g` | Replace all on line |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all, confirm each |

### Neovim — windows and buffers

| Chord / command | Action |
|---|---|
| `C-h/j/k/l` *(custom)* | Focus window left / down / up / right |
| `C-w v` / `C-w s` | Split vertical / horizontal (defaults) |
| `C-w c` / `:close` | Close current window |
| `C-w o` | Close other windows |
| `:bn` / `:bp` | Next / previous buffer |
| `:bd` | Delete (close) buffer |

### Neovim — help

| Command | Action |
|---|---|
| `:help topic` | Built-in help (`:help :w`, `:help motion`) |
| `:help index` | Huge default key index |
| `K` | (stock) look up keyword — useful later with LSP |

Config: [`home/.config/nvim/init.lua`](../home/.config/nvim/init.lua).

---

### tmux — prefix is always `C-b` first

Press `Ctrl+b`, release, then the next key.

#### Session / attach

| Chord / command | Action |
|---|---|
| `C-b d` | **Detach** (keep session alive — prefer this over `exit`) |
| `tmux attach -t main` | Re-attach from a bare shell |
| `tmux ls` | List sessions |
| `C-b s` | Interactive session picker |
| `C-b $` | Rename session |

This setup starts WezTerm in `tmux new-session -A -s main`, so you usually
live in one `main` session.

#### tmux windows (tabs)

| Chord | Action |
|---|---|
| `C-b c` *(cwd preserved)* | New window |
| `C-b ,` | Rename window |
| `C-b n` / `C-b p` | Next / previous window |
| `C-b 1`…`9` | Jump to window N (we number from 1) |
| `C-b w` | Interactive window list |
| `C-b &` | Kill window (asks to confirm) |

#### Panes (splits)

| Chord | Action |
|---|---|
| `C-b \|` *(custom)* | Split left/right |
| `C-b -` *(custom)* | Split up/down |
| `C-b h/j/k/l` *(custom)* | Focus pane |
| `C-b H/J/K/L` *(custom)* | Resize pane (repeatable) |
| `C-b x` | Kill pane (asks to confirm) |
| `C-b z` | Zoom pane (toggle fullscreen) |
| `C-b ;` | Toggle last pane |
| `C-b q` | Show pane numbers (type a number to jump) |
| `C-b {` / `C-b }` | Swap pane with previous / next |
| `C-b SPC` | Cycle pane layouts |

#### Scroll / copy

| Chord | Action |
|---|---|
| `C-b [` | Copy / scroll mode (use `hjkl`, `C-u`/`C-d`, `q` to quit) |
| `C-b ]` | Paste tmux buffer |
| Mouse | Scroll, select, drag borders (mouse is on). Selection syncs to the system clipboard via OSC 52 (`set-clipboard on` in `.tmux.conf`). |

After a mouse selection (or a yank in copy mode), paste with the host terminal shortcut (`Cmd+V` on macOS).

#### Meta

| Chord | Action |
|---|---|
| `C-b r` *(custom)* | Reload `~/.tmux.conf` |
| `C-b ?` | List all key bindings |
| `C-b t` | Big clock |

Config: [`home/.tmux.conf`](../home/.tmux.conf).

---

### WezTerm

No custom leader or splits — multiplexing is tmux’s job. Useful **defaults**
(macOS `Cmd`; on Linux many of these use `Super` / the OS terminal bindings):

| Chord (macOS) | Action |
|---|---|
| `Cmd+N` | New window (joins tmux `main` via `default_prog`) |
| `Cmd+Q` | Quit WezTerm |
| `Cmd++` / `Cmd+-` | Font size up / down |
| `Cmd+0` | Reset font size |
| `Cmd+F` | Search scrollback |
| `Cmd+C` / `Cmd+V` | Copy / paste (WezTerm defaults). Prefer mouse-select in tmux — that path syncs to the system clipboard via OSC 52. Hold **Option** while dragging to select in WezTerm instead of tmux. |
| `Cmd+Enter` | Toggle fullscreen |

If a chord you expect is “eaten”, check you are not fighting tmux — pane
splits are `C-b |` / `C-b -`, not WezTerm keys.

Config: [`home/.wezterm.lua`](../home/.wezterm.lua).

---

## Custom bindings only (quick index)

### tmux *(custom)*

| Chord | Action |
|---|---|
| `C-b \|` / `C-b -` | Splits |
| `C-b h/j/k/l` | Focus pane |
| `C-b H/J/K/L` | Resize pane |
| `C-b r` | Reload config |

### Neovim *(custom)*

| Chord | Action |
|---|---|
| `jk` | Exit insert |
| `Esc` | Clear search highlight |
| `C-h/j/k/l` | Focus window |
| `SPC w` / `SPC q` | Save / quit |

### Reserved `SPC` namespaces (future plugins)

| Prefix | Meaning |
|---|---|
| `SPC f` | Find / files |
| `SPC b` | Buffers |
| `SPC g` | Git |
| `SPC c` | Code / LSP |
| `SPC t` | Toggles |
| `SPC s` | Search / session |
| `SPC w` / `SPC q` | Save / quit (taken) |

---

## Adding a binding

1. Pick the layer (tmux vs Neovim).
2. Fit the hard rules and a reserved namespace.
3. Update **this file** in the same change as the config.
4. Prefer a mnemonic letter (`f` find, `g` git) over clever chords.

If two tools want the same chord, WezTerm loses, then Neovim defers to tmux
for multiplexing, then Neovim keeps editing keys.
