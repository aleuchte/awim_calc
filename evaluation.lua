local config = require('config')
local utils = require('utils')
local windows = require('windows')
local M = {
    last_answer = '0',
}

function M.convert_number(number_input)
    local binary, decimal, hex
    number_input = utils.strip_spaces(number_input)

    if number_input:match('^' .. config.settings.binary_prefix .. '[01]+$') then
        binary = number_input:sub(#config.settings.binary_prefix + 1)
        decimal = tonumber(binary, 2)
        hex = string.format('%X', decimal)
    elseif number_input:match('^' .. config.settings.decimal_prefix .. '[0-9]+$') then
        decimal = tonumber(number_input:sub(#config.settings.decimal_prefix + 1))
        binary = utils.to_binary(decimal)
        hex = string.format('%X', decimal)
    elseif number_input:match('^' .. config.settings.hexa_prefix .. '[0-9A-Fa-f]+$') then
        hex = number_input:sub(#config.settings.hexa_prefix + 1)
        decimal = tonumber(hex, 16)
        binary = utils.to_binary(decimal)
    else
        return { 'Error: ' .. number_input .. ' Invalid number_input format.', 'Must start with "b", "d", or "h" followed by the number in the right format.' }, false
    end
    return { 'bin: ' .. (binary or ''), 'dec: ' .. (decimal or ''), 'hex: ' .. (hex or '') }, true
end

function M.evaluate()
    local input = utils.handle_input()
    if input:gsub(config.settings.cmd_window_prefix, ''):gsub(' ', '') == '' then
        return
    end
    input = input:gsub(config.settings.last_answer_access_string, M.last_answer)
    local result, success, eval_result
    local error_msg = ' - Error in expression' 

    if input:match('^' .. config.settings.radix_conversion_string) then
        result, success = M.convert_number(input:gsub(config.settings.radix_conversion_string, ''))
    else
        input = input:gsub(config.settings.last_answer_access_string, M.last_answer)
        input = utils.strip_spaces(input)
        success, eval_result = pcall(utils.evaluate_math_env(input))
        result = success and eval_result and { input .. ' = ' .. eval_result } or { input .. error_msg}
        M.last_answer = result
    end

    local result_line_count = vim.api.nvim_buf_line_count(windows.result_buf)
    vim.api.nvim_buf_set_lines(windows.result_buf, result_line_count, result_line_count, false, result)

    local result_oneliner = table.concat(result, ' ')
    if success and not string.find(result_oneliner, error_msg, 1, true) then
        if #utils.calculation_history >= config.settings.max_calculation_history then
            table.remove(utils.calculation_history, 1)
        end
        table.insert(utils.calculation_history, result_oneliner)
    end

    --  FIXME - aleuchte - 02.11.24 - add command history with <up> and <down> keys

    local result_buf_line_count = vim.api.nvim_buf_line_count(windows.result_buf)
    vim.api.nvim_win_set_cursor(windows.result_win, { result_buf_line_count, 0 }) -- make sure we scroll down in the result window

    vim.api.nvim_buf_set_lines(windows.cmd_buf, 0, 1, false, { config.settings.cmd_window_prefix })
    vim.api.nvim_win_set_cursor(windows.cmd_win, { 1, #config.settings.cmd_window_prefix + 1 })

    return result
end

return M

