local M = {}
local calculation_history = {}
local max_allowed_calculation_history = 10
local width = 100
local height = 20
local input_height = 2
local binary_prefix = 'b'
local decimal_prefix = 'd'
local hexa_prefix = 'h'
local radix_conversion_string = 'convert'
local last_answer_access_string = 'ans'
local last_answer = '0'
local input_buf
local result_buf
local input_win
local result_win

function M.create_calculator_window()
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height - input_height) / 2)

    result_buf = vim.api.nvim_create_buf(false, true)
    input_buf = vim.api.nvim_create_buf(false, true)

    result_win = vim.api.nvim_open_win(result_buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = 'rounded'
    })

    input_win = vim.api.nvim_open_win(input_buf, true, {
        relative = 'editor',
        width = width,
        height = input_height,
        col = col,
        row = row + height,
        style = 'minimal',
        border = 'rounded'
    })

    -- Set filetype to nofile so we can exit nvim without issues
    vim.bo[input_buf].buftype = 'nofile'
    vim.bo[result_buf].buftype = 'nofile'

    local initial_result_lines = { 'Awim Calculator', '' }
    vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, initial_result_lines)

    for i = math.max(#calculation_history - (max_allowed_calculation_history - 1), 1), #calculation_history do
        vim.api.nvim_buf_set_lines(result_buf, -1, -1, false, { calculation_history[i] })
    end

    vim.cmd('startinsert')

    vim.api.nvim_buf_set_keymap(input_buf, 'n', 'q', '<Cmd>lua require("awim_calc").close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })
    vim.api.nvim_buf_set_keymap(input_buf, 'n', '<Esc>', '<Cmd>lua require("awim_calc").close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })
    vim.api.nvim_buf_set_keymap(input_buf, 'i', '<CR>', [[<Cmd>lua require('awim_calc').evaluate_calculation()<CR>]], { noremap = true, silent = true, desc = 'Enter evaluates the results and moves to the next line' })
    vim.api.nvim_buf_set_keymap(input_buf, 'i', '<A-c>', 'convert ', { noremap = false, silent = true, desc = 'Insert "convert"' })
end

function M.close_calculator()
    vim.api.nvim_buf_delete(input_buf, { force = true })
    vim.api.nvim_buf_delete(result_buf, { force = true })
end

function M.evaluate_calculation()
    local cursor_pos = vim.api.nvim_win_get_cursor(input_win)
    local line_number = cursor_pos[1]
    local lines = vim.api.nvim_buf_get_lines(input_buf, line_number - 1, line_number, false)
    local input = lines[1] or ''

    input = input:gsub(last_answer_access_string, last_answer)

    local function to_binary(num)
        local binary = ''
        while num > 0 do
            binary = (num % 2) .. binary
            num = math.floor(num / 2)
        end
        return binary == '' and '0' or binary
    end

    local function convert_number(number_input)
        local binary, decimal, hex
        if number_input:match('^' .. binary_prefix .. '[01]+$') then
            binary = number_input:sub(#binary_prefix + 1)
            decimal = tonumber(binary, 2)
            hex = string.format('%X', decimal)
        elseif number_input:match('^' .. decimal_prefix .. '[0-9]+$') then
            decimal = tonumber(number_input:sub(#decimal_prefix + 1))
            binary = to_binary(decimal)
            hex = string.format('%X', decimal)
        elseif number_input:match('^' .. hexa_prefix .. '[0-9A-Fa-f]+$') then
            hex = number_input:sub(#hexa_prefix + 1)
            decimal = tonumber(hex, 16)
            binary = to_binary(decimal)
        else
            return { 'Error: ' .. number_input .. ' Invalid number_input format. Must start with "b", "d", or "h" followed by the number in the right format.' }
        end
        return { 'bin: ' .. binary, 'dec: ' .. decimal, 'hex: ' .. hex }
    end

    local function evaluate_expression(expression)
        local env = { math = math, log2 = math.log }
        env.log2 = function(x) return math.log(x) / math.log(2) end
        local func, load_err = load('return ' .. expression, 'expression', 't', env)
        if not func then
            local result_line_count = vim.api.nvim_buf_line_count(result_buf) --  FIXME - aleuchte - 30.10.24 - make nice error here
            vim.api.nvim_buf_set_lines(result_buf, result_line_count, result_line_count, false, { load_err })
        end
        return func
    end

    local result, result_func
    if input:match('^' .. radix_conversion_string .. '%s+') then
        local number_input = input:sub(#radix_conversion_string + 1):gsub('%s+', '')
        result = convert_number(number_input)
    else
        result_func = evaluate_expression(input) --  FIXME - aleuchte - 30.10.24 - substitute the need for math in math.sqrt etc.
        -- result_func = load('return ' .. input)
        if result_func then
            local success, eval_result = pcall(result_func)
            if success then
                eval_result = eval_result ~= nil and tostring(eval_result) or 'nil'
                result = { input .. ' = ' .. eval_result }
                last_answer = eval_result
            else
                result = { 'Error: ' .. input .. ' Invalid expression'}
            end
        else
            result = { 'Error: ' .. input .. ' Invalid expression'}
        end
    end

    if result then
        local result_line_count = vim.api.nvim_buf_line_count(result_buf)
        vim.api.nvim_buf_set_lines(result_buf, result_line_count, result_line_count, false, result)

        local result_oneliner = table.concat(result, ' ')
        table.insert(calculation_history, result_oneliner)
    end

    if #calculation_history > max_allowed_calculation_history then
        table.remove(calculation_history, 1)
    end

    vim.api.nvim_buf_set_lines(input_buf, line_number - 1, line_number, false, { '' })
    vim.api.nvim_win_set_cursor(input_win, { line_number, 0 })
end

function M.setup(opts)
    opts = opts or {}
    max_allowed_calculation_history = opts.max_allowed_calculation_history or 10
    width = opts.width or 100
    height = opts.height or 20
    binary_prefix = opts.binary_prefix or 'b'
    decimal_prefix = opts.decimal_prefix or 'd'
    hexa_prefix = opts.hexa_prefix or 'h'
    radix_conversion_string = opts.radix_conversion_string or 'convert'
    last_answer_access_string = opts.last_answer_access_string or 'ans'
    vim.api.nvim_create_user_command('Calculator', M.create_calculator_window, {})
end

return M

