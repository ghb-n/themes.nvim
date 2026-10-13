---Default configuration for themes.nvim.
return {
  -- Floating window look.
  title = " Themes ",
  border = "rounded",
  width = 60,

  -- Markers used in the list.
  icons = {
    current = "●", -- the theme that is active right now
    preview = "▸", -- the theme under the cursor while previewing
  },

  keymaps = {
    apply = "<CR>",
    close = { "q", "<Esc>" },
    toggle_preview = "<Space>",
  },

  -- Color scheme names to hide from the list.
  exclude = {},

  -- Restrict the list to these schemes. Leave empty to auto-discover every
  -- colorscheme found on the runtimepath.
  themes = {},
}