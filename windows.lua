local M = {
    result_buf = nil,
    cmd_buf = nil,
    result_win = nil,
    cmd_win = nil,
    help_buf = nil,
    help_win = nil,
}
local config = require('config')
local utils = require('utils')
local keymappings = require('keymappings')

function M.create_help_window()
    if M.help_buf and vim.api.nvim_buf_is_valid(M.help_buf) then
        vim.api.nvim_set_current_buf(M.help_buf)
        return
    end

    M.help_buf, M.help_win = utils.create_buffer_window(vim.o.columns, config.settings.help_window_height, 0, 0)

    keymappings.set_buffer_keymaps(M.help_buf)

    local help_text = utils.build_help_text()
    vim.api.nvim_buf_set_lines(M.help_buf, 0, -1, false, vim.split(help_text, '\n'))
    vim.api.nvim_buf_set_option(M.help_buf, 'modifiable', false) -- help window should not be modified after printing help messages
end

function M.create_calculator_window()
    if M.cmd_buf and vim.api.nvim_buf_is_valid(M.cmd_buf) then --  FIXME - aleuchte - 03.11.24 - find better solution for if only one of the buffers is open
        vim.api.nvim_set_current_buf(M.cmd_buf)
        return
    elseif M.result_buf and vim.api.nvim_buf_is_valid(M.result_buf) then
        vim.api.nvim_set_current_buf(M.result_buf)
        return
    end

    local col = math.floor((vim.o.columns - config.settings.width) / 2)
    local row = math.floor((vim.o.lines - config.settings.height) / 2)
    local calculator_title = string.rep('-', math.floor((config.settings.width - #config.settings.calculator_title) / 2)) .. config.settings.calculator_title
    M.result_buf, M.result_win = utils.create_buffer_window(config.settings.width, config.settings.height, row, col, calculator_title)
    M.cmd_buf, M.cmd_win = utils.create_buffer_window(config.settings.width, config.settings.cmd_height, row + config.settings.height + 2, col)


    for i = math.max(#utils.calculation_history - (config.settings.max_allowed_calculation_history - 1), 1), #utils.calculation_history do --  FIXME - aleuchte - 03.11.24 - is this needed?
        vim.api.nvim_buf_set_lines(M.result_buf, -1, -1, false, { utils.calculation_history[i] })
    end

    vim.api.nvim_buf_set_lines(M.cmd_buf, 0, -1, false, { config.settings.cmd_window_prefix })
    vim.cmd('startinsert')
    vim.api.nvim_win_set_cursor(M.cmd_win, { 1, #config.settings.cmd_window_prefix + 1 }) -- Position cursor after "> "

    keymappings.cmd_buf = M.cmd_buf
    keymappings.set_general_keymaps()
    keymappings.set_buffer_keymaps(M.cmd_buf)
    keymappings.set_buffer_keymaps(M.result_buf)
    -- vim.api.nvim_create_autocmd("BufLeave", { buffer = M.cmd_buf, callback = function() M.close_calculator() end, })
end

function M.close_calculator()
    if (M.help_buf and vim.api.nvim_buf_is_valid(M.help_buf) and (vim.api.nvim_get_current_buf() == M.help_buf)) then
        vim.api.nvim_buf_delete(M.help_buf, { force = true })
        vim.cmd('startinsert')
        vim.api.nvim_win_set_cursor(M.cmd_win, { 1, #config.settings.cmd_window_prefix + 1 }) -- Position cursor after "> "
    else
        for _, buf in ipairs({ M.result_buf, M.cmd_buf, M.help_buf, }) do
            if buf and vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile') -- filetype nofile so we can close it without saving
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
    end
end

function M.setup_commands()
    vim.api.nvim_create_user_command('Calculator', M.create_calculator_window, {})
    vim.api.nvim_create_user_command('Calculatorhelp', M.create_help_window, {})
end

return M

