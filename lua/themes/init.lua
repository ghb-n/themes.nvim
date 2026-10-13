local core = require("themes.core")

local M = {}

local api = vim.api

local state = {
  win = nil,
  buf = nil,
  previewing = false,
  saved = nil, -- colorscheme to restore if the picker is cancelled
  entries = {}, -- line number -> theme name
}

local function hl(name, link)
  api.nvim_set_hl(0, name, { link = link, default = true })
end

---Highlight groups for the picker, re-applied after every colorscheme change
---because `colorscheme` clears user highlights.
local function apply_highlights()
  hl("ThemesNormal", "NormalFloat")
  hl("ThemesBorder", "FloatBorder")
  hl("ThemesTitle", "Title")
  hl("ThemesCurrent", "DiagnosticOk")
  hl("ThemesPreview", "DiagnosticWarn")
  hl("ThemesHint", "Comment")
  hl("ThemesIndex", "NonText")
end

---Theme name shown on the cursor line, if any.
---@return string?
local function theme_under_cursor()
  local line = api.nvim_win_get_cursor(state.win)[1]
  return state.entries[line]
end

---Draw the list, marking the active and previewed themes.
local function render()
  local cfg = core.config
  local current = core.current()

  local lines, entries = {}, {}
  local width = cfg.width

  lines[#lines + 1] = cfg.title
  lines[#lines + 1] = string.rep("─", width)

  for i, name in ipairs(cfg._names) do
    local marker = "  "
    if name == state.previewing and (state.previewed or "") == name then
      marker = cfg.icons.preview .. " "
    elseif name == current then
      marker = cfg.icons.current .. " "
    end
    lines[#lines + 1] = ("%s%2d. %s"):format(marker, i, name)
    entries[#lines] = name
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = ("[Space] preview  [%s] apply  [q] cancel"):format(
    cfg.keymaps.apply:gsub("[<>]", "")
  )

  state.entries = entries
  -- The buffer is locked so stray keys cannot edit it; rendering has to unlock
  -- it first.
  api.nvim_set_option_value("modifiable", true, { buf = state.buf })
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = state.buf })
end

---Restore the colorscheme that was active before the picker opened.
local function restore()
  if state.saved and state.saved ~= "" then
    if core.apply(state.saved) then
      return
    end
    -- The saved name no longer resolves; stop tracking a stale selection.
    core.clear()
  end
end

local function close()
  if not state.win or not api.nvim_win_is_valid(state.win) then
    return
  end

  api.nvim_win_close(state.win, true)
  state.win = nil
  state.buf = nil
  state.previewing = false
  state.previewed = nil
  state.saved = nil
end

---Open the theme picker.
function M.open()
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_set_current_win(state.win)
    return
  end

  if not core.config then
    core.setup()
  end

  core.config._names = core.list()
  if #core.config._names == 0 then
    vim.notify("themes.nvim: no colorschemes found", vim.log.levels.WARN)
    return
  end

  state.saved = core.current()
  state.buf = api.nvim_create_buf(false, true)

  local lines = #core.config._names + 5
  local height = math.min(lines, math.floor(vim.o.lines * 0.8))
  local width = math.min(core.config.width, vim.o.columns - 4)

  state.win = api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = core.config.border,
    mouse = true, -- so clicking a line moves the cursor onto it
    noautocmd = true,
  })

  api.nvim_set_option_value("modifiable", false, { buf = state.buf })
  api.nvim_set_option_value("filetype", "themes", { buf = state.buf })
  api.nvim_set_option_value("bufhidden", "wipe", { buf = state.buf })
  -- cursorline is window-local, so it must be set on the window.
  api.nvim_set_option_value("cursorline", true, { win = state.win })

  render()
  apply_highlights()

  local function apply_and_close()
    local name = theme_under_cursor()
    if name then
      core.apply(name)
      state.previewing = false
      state.previewed = nil
      close()
    end
  end

  local function preview()
    local name = theme_under_cursor()
    if not name then
      return
    end
    state.previewed = name
    core.apply(name)
    -- `colorscheme` wipes user highlights, so put them back.
    apply_highlights()
    render()
  end

  local function toggle_preview()
    state.previewing = not state.previewing
    if state.previewing then
      preview()
    else
      state.previewed = nil
      restore()
      render()
    end
  end

  local function cancel()
    if state.previewing then
      state.previewing = false
      state.previewed = nil
      restore()
    end
    close()
  end

  local map = function(keys, fn, desc)
    -- Config values may be a single key or a list of them.
    if type(keys) == "string" then
      keys = { keys }
    end
    for _, lhs in ipairs(keys) do
      vim.keymap.set("n", lhs, fn, {
        buffer = state.buf,
        noremap = true,
        silent = true,
        nowait = true,
        desc = desc,
      })
    end
  end

  map(core.config.keymaps.close, cancel, "Close theme picker")
  map(core.config.keymaps.apply, apply_and_close, "Apply theme")
  map(core.config.keymaps.toggle_preview, toggle_preview, "Toggle live preview")
  map({ "<LeftRelease>", "<LeftClick>" }, apply_and_close, "Apply theme (click)")

  -- Live preview while navigating. `j`/`k`/arrows work without extra mappings
  -- because the buffer stays in normal mode with the cursorline visible.
  api.nvim_create_autocmd("CursorMoved", {
    buffer = state.buf,
    callback = function()
      if state.previewing then
        preview()
      end
    end,
    desc = "themes.nvim live preview",
  })

  -- A click moves the cursor first, then fires CursorMoved, so clicking a line
  -- previews it just like moving there with the keyboard.

  -- Park the cursor on the active theme when there is one.
  for line, name in pairs(state.entries) do
    if name == state.saved then
      api.nvim_win_set_cursor(state.win, { line, 0 })
      break
    end
  end
end

---Set up the plugin. Safe to call more than once.
function M.setup(opts)
  core.setup(opts)

  vim.api.nvim_create_user_command("Themes", function()
    M.open()
  end, { desc = "Open the themes.nvim picker" })

  return M
end

return M