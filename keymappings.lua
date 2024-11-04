local utils = require('utils')

local M = {
    cmd_buf = nil,
}

function M.set_buffer_keymaps(buffer)
    vim.api.nvim_buf_set_keymap(buffer, 'n', 'q', '<Cmd>lua require("awim_calc").windows.close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })
    vim.api.nvim_buf_set_keymap(buffer, 'n', '<Esc>', '<Cmd>lua require("awim_calc").windows.close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })
    vim.api.nvim_buf_set_keymap(buffer, 'i', '<A-h>', '<Esc><Cmd>Calculatorhelp<CR>', { noremap = false, silent = true, desc = 'Open Calculator help window' })
    vim.api.nvim_buf_set_keymap(buffer, 'n', '<A-h>', '<Esc><Cmd>Calculatorhelp<CR>', { noremap = false, silent = true, desc = 'Open Calculator help window' })
end

function M.set_general_keymaps()
    for key, mapping in pairs(utils.key_mappings) do
        vim.api.nvim_buf_set_keymap(M.cmd_buf, 'i', key, mapping.func .. '<Left>', { noremap = false, silent = true })
    end
    vim.api.nvim_buf_set_keymap(M.cmd_buf, 'i', '<CR>', [[<Cmd>lua require('awim_calc').evaluation.evaluate()<CR>]], { noremap = true, silent = true, desc = 'Enter evaluates the results and moves to the next line' })
end

return M

