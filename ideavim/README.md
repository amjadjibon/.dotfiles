# IdeaVim Cheatsheet

Reference for `~/.ideavimrc`. **Leader is `<Space>`** (same as your Neovim config).

Reload after editing: `:source ~/.ideavimrc` or `<Space>vr`.
Find an action name to map: `:actionlist <pattern>` (e.g. `:actionlist Git`).

---

## Setup checklist

| Step | Why |
| --- | --- |
| Install **IdeaVim** plugin | The base plugin |
| Install **IdeaVim-Which-Key**, then uncomment `set which-key` | Popup showing what's under `<Space>` |
| Settings → Editor → Vim → check keys marked "IDE" | Resolve shortcuts the IDE steals before Vim sees them |

If a mapping does nothing, it's almost always an IDE keymap conflict — that Vim settings panel is where you switch a key from "IDE" to "Vim".

---

## Leader mappings

### `<Space>f` — Find

| Key | Action |
| --- | --- |
| `<Space>ff` | Go to File |
| `<Space>fs` | Go to Symbol |
| `<Space>fc` | Go to Class |
| `<Space>fa` | Go to Action (the command palette) |
| `<Space>fg` | Find in Path (grep the project) |
| `<Space>fr` | Recent Files |
| `<Space>e` | Reveal current file in Project view |

### `<Space>c` / `<Space>o` — Code

| Key | Action |
| --- | --- |
| `<Space>ca` | Show intention actions (quick fixes / "code actions") |
| `<Space>cf` | Reformat file |
| `<Space>oi` | Optimize imports |

### `<Space>r` — Refactor & Run

| Key | Action |
| --- | --- |
| `<Space>rn` | Rename symbol |
| `<Space>rm` | Extract method |
| `<Space>rv` | Introduce variable |
| `<Space>rr` | Run |
| `<Space>rd` | Debug |
| `<Space>rc` | Run the class/test under the cursor |
| `<Space>rt` | Rerun tests |

> `r` is doing double duty (refactor + run). If that bothers you, move run/debug to `<Space>d`.

### `<Space>b` — Breakpoints

| Key | Action |
| --- | --- |
| `<Space>b` | Toggle line breakpoint |
| `<Space>B` | View all breakpoints |

### `<Space>g` — Git

| Key | Action |
| --- | --- |
| `<Space>gs` | Local changes (status) |
| `<Space>gb` | Annotate / blame gutter |
| `<Space>gh` | File history |
| `<Space>gd` | Diff against last committed version |

### `<Space>w` — Windows

| Key | Action |
| --- | --- |
| `<Space>ws` | Split horizontally |
| `<Space>wv` | Split vertically |
| `<Space>wc` | Close current tab |

### Misc

| Key | Action |
| --- | --- |
| `<Space>p` (visual) | Paste over selection **without** clobbering your yank |
| `<Space>vr` | Reload `.ideavimrc` |

---

## Navigation (no leader)

| Key | Action |
| --- | --- |
| `gd` | Go to declaration |
| `gy` | Go to type declaration |
| `gi` | Go to implementation |
| `gr` | Show usages |
| `gh` | Show error description under cursor |
| `K` | Quick documentation |
| `[d` / `]d` | Previous / next error |
| `[m` / `]m` | Previous / next method |
| `<C-o>` / `<C-i>` | Navigate back / forward through history |
| `<C-h/j/k/l>` | Move between splits |
| `<Tab>` / `<S-Tab>` | Next / previous editor tab |
| `<Esc>` | Clear search highlight |

Search and half-page jumps auto-center: `n`, `N`, `<C-d>`, `<C-u>` all end with the cursor mid-screen.

---

## Editing

| Key | Action |
| --- | --- |
| `<A-j>` / `<A-k>` | Move line down / up (IntelliJ's smart move — fixes indentation) |
| `J` / `K` in visual | Move the selected block down / up and re-indent |
| `<` / `>` in visual | Indent, **keeping the selection** so you can repeat |
| `J` in normal | Join lines using IntelliJ's smart join (`set ideajoin`) |

Yanking goes straight to the system clipboard (`clipboard+=unnamedplus`) — no `"+y` needed.

---

## Emulated Vim plugins

### surround (`tpope/vim-surround`)
```
ysiw"     surround the word in quotes
cs"'      change surrounding " to '
ds(       delete surrounding parens
S<tag>    in visual mode, wrap the selection
```

### commentary (`tpope/vim-commentary`)
```
gcc       toggle comment on the line
gc{motion} comment a motion, e.g. gcap for a paragraph
gc        in visual mode
```

### Text objects
```
ia / aa   argument      — cia to change one function argument
ii / ai   indent block  — dii to delete an indented body
ie / ae   entire buffer — yae to yank the whole file
```

### exchange (`tommcdo/vim-exchange`)
```
cxiw      mark a word, then cxiw on another to swap the two
cxx       same, line-wise
cxc       cancel a pending exchange
```

### ReplaceWithRegister
```
gRiw      replace a word with the register contents
gRR       replace the whole line
gR        in visual mode
```
(Mapped to `gR` rather than the plugin's default `gr`, since `gr` is Show Usages here.)

### multiple-cursors
```
<A-n>     add a cursor at the next occurrence of the word
<A-x>     skip this occurrence, move to the next
<A-p>     remove the last cursor
```

### sneak
```
s{char}{char}   jump forward to a two-char pair
S{char}{char}   jump backward
;  /  ,         repeat forward / backward
```
**This overrides `s` (substitute char).** Use `cl` instead, or delete the `sneak` Plug line.

### highlightedyank
Flashes the region you just yanked. No keys.

### NERDTree
```
:NERDTree     open the tree
o             open      s / i  open in vertical / horizontal split
x             collapse the parent
```

---

## IdeaVim-specific options in use

| Option | Effect |
| --- | --- |
| `ideajoin` | `J` uses IntelliJ's language-aware join (merges string concatenations, collapses `if` bodies) |
| `ideamarks` | Vim marks and IDE bookmarks are the same thing |
| `idearefactormode=keep` | Stay in normal mode during refactors instead of being dumped into insert |
| `ideaput` | `p` respects IDE paste behavior (auto-import, reindent) |
| `notimeout` | Leader sequences wait indefinitely — needed for Which-Key to be usable |

---

## Known collisions

- **`s`** → taken by sneak. `cl` does the same thing.
- **`gr`** → Show Usages, not ReplaceWithRegister (that's on `gR`).
- **`K`** → Quick Documentation in normal mode, move-lines-up in visual mode. Different modes, so both work.
- **`<Tab>`** → switches editor tabs, so it no longer indents in normal mode.
- **`<A-j>/<A-k>`** on macOS may be intercepted by the system or by IntelliJ's own keymap; check the Vim settings panel if they misfire.

---

## Gotcha when editing this config

`<Action>(...)` mappings **must** use the recursive forms — `map`, `nmap`, `vmap`.
With `nnoremap` they silently fail:

```vim
nmap     <leader>ff <Action>(GotoFile)   " works
nnoremap <leader>ff <Action>(GotoFile)   " does nothing
```

Plain Vim remaps should still use `nnoremap`/`vnoremap`. Same rule applies to `<Plug>` mappings.
