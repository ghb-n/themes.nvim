# themes.nvim

A floating theme picker for Neovim with **live preview**.

Built because "I don't want to use the same theme every day" deserves better than
editing a `colorscheme` line and restarting.

```
 Themes 
────────────────────────────────────────────────────────────
●  1. catppuccin
   2. catppuccin-frappe
   3. catppuccin-latte
▸  4. catppuccin-macchiato
   5. catppuccin-mocha
   6. everforest
   7. gruvbox
   8. kanagawa
   ...
────────────────────────────────────────────────────────────
[Space] preview  [CR] apply  [q] cancel
```

## Features

- **Locked floating window.** The buffer is `nomodifiable`, so stray keystrokes
  can never edit the list. Navigating is all you can do.
- **Live preview.** Press `<Space>` and the theme changes in real time as you
  move the cursor. Press it again to turn preview off and snap back.
- **Cancel is safe.** `q` restores the theme you had *before* you opened the
  picker, so experimenting costs nothing.
- **Click to apply.** The window has `mouse = true`; clicking a line applies
  that theme.
- **Auto-discovery.** Scans your `runtimepath` for `colors/*.lua` and
  `colors/*.vim`, so themes from any plugin show up automatically.
- **Marker on your active theme.** `●` is what you're using, `▸` is what's being
  previewed, and the cursor starts on your current theme.
- Highlights are re-applied after every switch, because `colorscheme` clears
  user highlight groups.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  dir = "~/personal/themes.nvim",
  name = "themes.nvim",
  cmd = "Themes",
  dependencies = {
    "catppuccin/nvim",
    "folke/tokyonight.nvim",
  },
  config = function()
    require("themes").setup()
    vim.keymap.set("n", "<leader>u", "<cmd>Themes<cr>", { desc = "Theme picker" })
  end,
}
```

## Usage

| Key | Action |
| --- | --- |
| `:Themes` | Open the picker |
| `<leader>u` | Open the picker (if you mapped it) |
| `j` / `k`, arrows | Move through the list |
| `<Space>` | Toggle live preview on/off |
| `<CR>` | Apply the theme under the cursor and close |
| `<LeftClick>` | Same as `<CR>` |
| `q` / `<Esc>` | Cancel and restore the previous theme |

## Configuration

Everything is optional.

```lua
require("themes").setup({
  -- Restrict the list. Leave empty (the default) to auto-discover everything.
  themes = {
    "catppuccin",
    "catppuccin-mocha",
    "tokyonight-night",
    "rose-pine",
  },

  -- Hide schemes from the auto-discovered list.
  exclude = { "quiet", "delek" },

  -- Floating window.
  title = " Themes ",
  border = "rounded",
  width = 60,

  -- Markers in the list.
  icons = {
    current = "●",
    preview = "▸",
  },

  keymaps = {
    apply = "<CR>",
    close = { "q", "<Esc>" },
    toggle_preview = "<Space>",
  },
})
```

### Lua API

```lua
local themes = require("themes")

themes.setup(opts)  -- optional, called by the lazy.nvim `config` above
themes.open()       -- same as :Themes

local core = require("themes.core")
core.list()         -- every discovered colorscheme name
core.current()      -- the active theme name
core.apply("gruvbox")
```

## Auto-discovery vs. an explicit list

Auto-discovery finds everything on your `runtimepath`, which is handy when you
have many theme plugins installed. The downside is noise: Neovim ships ~30
built-in schemes (`pablo`, `morning`, `murphy`, `koehler`, ...) that will show
up alongside the ones you actually want.

Setting `themes = { ... }` gives you a short, curated list. That's what the
config in `~/personal/nvim` does with 20 schemes across catppuccin, tokyonight,
rose-pine, kanagawa, everforest, and gruvbox.

## Known limitations

Some theme plugins set `g:colors_name` to their **base** name regardless of
which variant is loaded. rose-pine hardcodes `rose-pine` even when you run
`:colorscheme rose-pine-dawn`, and kanagawa does the same.

themes.nvim remembers the name *it* applied, so the marker and the cancel-restore
are exact for anything chosen through the picker. But if you set a variant
directly from the command line, the marker falls back to `g:colors_name` and
shows the base name. This is deliberate: guessing a variant by suffix match
would sometimes be wrong, and a plainly-wrong marker is worse than an honest one.

Note that some themes are toggles rather than separate files:

- **gruvbox** exposes `gruvbox` with a `background` option, not `gruvbox-light`.
- **everforest** works the same way.
- **rose-pine** uses `rose-pine`, `rose-pine-dawn`, `rose-pine-moon`, `rose-pine-main`.

Listing a name that does not exist is harmless at setup time, but it will not
apply. Verify names against the `colors/` directory of the plugin that ships
them.

## Credits

Inspired by the idea of a scratch theme switcher, and by plugins that got the
small details right: `folke/which-key.nvim`, `folke/lazy.nvim`, `catppuccin/nvim`.