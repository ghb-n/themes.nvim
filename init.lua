local M = {}

function M.open(themes)
    -- 1. Cria um buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- 2. Prepara as linhas
    local lines = { " Themes ", "─────────────────" }
    for i, theme in ipairs(themes) do
        table.insert(lines, string.format("%d. %s (%s)", i, theme.name, theme.colorscheme))
    end
    table.insert(lines, "")
    table.insert(lines, "[Enter] Apply  [q] Close")

    -- 3. Escreve no buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- 4. Abre janela flutuante
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = 60,
        height = #lines + 2,
        row = 5,
        col = 10,
        style = "minimal",
        border = "rounded",
    })

    -- 5. Mapeia teclas
    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })

    vim.keymap.set("n", "<CR>", function()
        -- Pega a linha atual
        local line = vim.api.nvim_get_current_line()
        -- Extrai o índice
        local idx = tonumber(line:match("^(%d+)"))
        if idx and themes[idx] then
            vim.cmd("colorscheme " .. themes[idx].colorscheme)
            vim.notify("Theme: " .. themes[idx].name)
            vim.api.nvim_win_close(win, true)
        end
    end, { buffer = buf })
end

return M
