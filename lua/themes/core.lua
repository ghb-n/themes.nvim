local M = {}

local api = vim.api

local group = api.nvim_create_augroup("themes_nvim", { clear = true })

---Resolve the user options against the plugin defaults.
---@param opts table?
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", require("themes.config"), opts or {})
  M.original = vim.g.colors_name
  M.selected = nil

  -- Track themes changed outside this plugin so the picker marker stays honest.
  api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      -- Our own `apply` sets `M.selected` after the event fires, so this only
      -- ever sees genuine external changes.
      M.selected = nil
    end,
    desc = "themes.nvim: forget stale selection",
  })

  return M
end

---Name of the colorscheme currently applied.
---
---Some plugins (rose-pine, kanagawa) set `g:colors_name` to their *base* name
---no matter which variant is loaded, so `g:colors_name` alone cannot tell
---`rose-pine` apart from `rose-pine-dawn`. We remember the last name we applied
---and fall back to `g:colors_name` for themes set outside this plugin.
---@return string?
function M.current()
  return M.selected or vim.g.colors_name
end

---Hook `ColorScheme` so a `:colorscheme` typed outside this plugin is not
---reported as a stale selection.
---
---We deliberately do not try to guess *which* variant loaded from
---`g:colors_name`, because plugins like rose-pine and kanagawa report only
---their base name. Picking a variant by suffix match would be a guess, and a
---wrong marker is worse than falling back to the reported name.
local function track_external()
  M.selected = nil
end

---Apply a colorscheme by name, ignoring failures.
---@param name string
---@return boolean ok
function M.apply(name)
  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify(("themes.nvim: could not apply '%s': %s"):format(name, err), vim.log.levels.WARN)
    return false
  end
  -- Only trust the name if the colorscheme actually exists, otherwise a typo
  -- would be remembered as if it worked.
  M.selected = name
  return true
end

---Forget the tracked selection, so `current()` reads `g:colors_name` again.
function M.clear()
  M.selected = nil
end

---Find every colorscheme available on the runtimepath.
---@param opts { exclude: string[], themes: string[] }?
---@return string[] names sorted alphabetically
function M.list(opts)
  opts = opts or M.config or {}

  local found, seen = {}, {}

  local function add(name)
    if not seen[name] then
      seen[name] = true
      table.insert(found, name)
    end
  end

  if opts.themes and #opts.themes > 0 then
    for _, name in ipairs(opts.themes) do
      add(name)
    end
  else
    -- Colorschemes live in `colors/<name>.{lua,vim}` somewhere on the rtp.
    for _, path in ipairs(api.nvim_list_runtime_paths()) do
      for _, ext in ipairs({ "lua", "vim" }) do
        local matches = vim.fn.glob(path .. "/colors/*." .. ext, false, true)
        for _, match in ipairs(matches) do
          local name = vim.fn.fnamemodify(match, ":t:r")
          if name ~= "" then
            add(name)
          end
        end
      end
    end
  end

  for _, name in ipairs(opts.exclude or {}) do
    seen[name] = nil
  end

  local names = vim.tbl_keys(seen)
  table.sort(names)
  return names
end

return M