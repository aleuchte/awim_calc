local M = {}
local calculation_history = {}
local cmd_history = {}
local max_allowed_calculation_history = 10
local width = 100
local height = 20
local cmd_height = 1
local help_window_height = 5
local binary_prefix = 'b'
local decimal_prefix = 'd'
local hexa_prefix = 'h'
local radix_conversion_string = 'convert'
local last_answer_access_string = 'ans'
local last_answer = '0'
local cmd_buf
local result_buf
local help_buf
local cmd_win
local result_win
local calculator_title = 'Awim Calculator'
local title_color = '#0000FF'
local cmd_window_prefix = '> '
local key_mappings = {
    ['<A-l>'] = { func = 'log2()', desc = 'Log base 2' },
    ['<A-s>'] = { func = 'math.sqrt()', desc = 'Square root' },
}

function M.create_help_window()
    local col = 0
    local row = 0

    help_buf = vim.api.nvim_create_buf(false, true)

    help_win = vim.api.nvim_open_win(help_buf, true, {
        relative = 'editor',
        width = vim.o.columns,
        height = help_window_height,
        col = col,
        row = row,
        style = 'minimal',
        border = 'single'
    })

    -- Set filetype to nofile so we can exit nvim without issues
    vim.api.nvim_buf_set_option(help_buf, 'buftype', 'nofile')

    local help_text = ""
    for key, mapping in pairs(key_mappings) do
        help_text = help_text .. key .. ' -> ' .. mapping.func .. ' -> ' .. mapping.desc .. '\n'
    end
    vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, vim.split(help_text, "\n"))
    vim.api.nvim_buf_set_option(help_buf, 'modifiable', false)

    vim.api.nvim_buf_set_keymap(help_buf, 'n', 'q', '<Cmd>lua require("awim_calc").close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })
    vim.api.nvim_buf_set_keymap(help_buf, 'n', '<Esc>', '<Cmd>lua require("awim_calc").close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })

end

function M.create_calculator_window()
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    result_buf = vim.api.nvim_create_buf(false, true)
    cmd_buf = vim.api.nvim_create_buf(false, true)

    result_win = vim.api.nvim_open_win(result_buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = 'single'
    })

    cmd_win = vim.api.nvim_open_win(cmd_buf, true, {
        relative = 'editor',
        width = width,
        height = cmd_height,
        col = col,
        row = row + height + 2, --  FIXME - aleuchte - 31.10.24 - parametrize
        style = 'minimal',
        border = 'single'
    })

    -- Set filetype to nofile so we can exit nvim without issues
    vim.api.nvim_buf_set_option(cmd_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(result_buf, 'buftype', 'nofile')

    local centered_title = string.rep(" ", math.floor((width - #calculator_title) / 2)) .. calculator_title --  FIXME - aleuchte - 31.10.24 - make sure title stays even when window scrolls down
    local initial_result_lines = { centered_title, '' }
    vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, initial_result_lines)
    vim.api.nvim_buf_add_highlight(result_buf, -1, "CalculatorTitle", 0, 0, -1)
    vim.api.nvim_set_hl(0, "CalculatorTitle", { fg = title_color, bold = true })

    for i = math.max(#calculation_history - (max_allowed_calculation_history - 1), 1), #calculation_history do
        vim.api.nvim_buf_set_lines(result_buf, -1, -1, false, { calculation_history[i] })
    end

    vim.api.nvim_buf_set_lines(cmd_buf, 0, -1, false, { cmd_window_prefix })
    vim.cmd('startinsert')
    vim.api.nvim_win_set_cursor(cmd_win, { 1, #cmd_window_prefix + 1 }) -- Position cursor after "> "

    vim.api.nvim_buf_set_keymap(cmd_buf, 'n', 'q', '<Cmd>lua require("awim_calc").close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })
    vim.api.nvim_buf_set_keymap(cmd_buf, 'n', '<Esc>', '<Cmd>lua require("awim_calc").close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })
    vim.api.nvim_buf_set_keymap(result_buf, 'n', 'q', '<Cmd>lua require("awim_calc").close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })
    vim.api.nvim_buf_set_keymap(result_buf, 'n', '<Esc>', '<Cmd>lua require("awim_calc").close_calculator()<CR>', { noremap = true, silent = true, desc = 'Close Calculator' })
    vim.api.nvim_buf_set_keymap(cmd_buf, 'i', '<CR>', [[<Cmd>lua require('awim_calc').evaluate_calculation()<CR>]], { noremap = true, silent = true, desc = 'Enter evaluates the results and moves to the next line' })
    vim.api.nvim_buf_set_keymap(cmd_buf, 'i', '<A-c>', 'convert ', { noremap = false, silent = true, desc = 'Insert "convert"' })
    vim.api.nvim_buf_set_keymap(cmd_buf, 'i', '<A-h>', '<Esc><Cmd>Calculatorhelp<CR>', { noremap = false, silent = true, desc = 'Open Calculator help window' })
    vim.api.nvim_buf_set_keymap(cmd_buf, 'n', '<A-h>', '<Esc><Cmd>Calculatorhelp<CR>', { noremap = false, silent = true, desc = 'Open Calculator help window' })
    vim.api.nvim_buf_set_keymap(result_buf, 'i', '<A-h>', '<Esc><Cmd>Calculatorhelp<CR>', { noremap = false, silent = true, desc = 'Open Calculator help window' })
    vim.api.nvim_buf_set_keymap(result_buf, 'n', '<A-h>', '<Esc><Cmd>Calculatorhelp<CR>', { noremap = false, silent = true, desc = 'Open Calculator help window' })

    for key, mapping in pairs(key_mappings) do
        vim.api.nvim_buf_set_keymap(cmd_buf, 'i', key, mapping.func .. '<Left>', { noremap = false, silent = true })
    end
end

function M.close_calculator()
    if (help_buf and vim.api.nvim_buf_is_valid(help_buf) and (vim.api.nvim_get_current_buf() == help_buf)) then
        vim.api.nvim_buf_delete(help_buf, { force = true })
        vim.cmd('startinsert')
        vim.api.nvim_win_set_cursor(cmd_win, { 1, #cmd_window_prefix + 1 }) -- Position cursor after "> "
    else
        if cmd_buf and vim.api.nvim_buf_is_valid(cmd_buf) then vim.api.nvim_buf_delete(cmd_buf, { force = true }) end
        if result_buf and vim.api.nvim_buf_is_valid(result_buf) then vim.api.nvim_buf_delete(result_buf, { force = true }) end
        if help_buf and vim.api.nvim_buf_is_valid(help_buf) then vim.api.nvim_buf_delete(help_buf, { force = true }) end
    end
end

function M.evaluate_calculation()
    local cursor_pos = vim.api.nvim_win_get_cursor(cmd_win)
    local line_number = cursor_pos[1]
    local lines = vim.api.nvim_buf_get_lines(cmd_buf, line_number - 1, line_number, false)
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
            return { 'Error: ' .. number_input .. ' Invalid number_input format.', 'Must start with "b", "d", or "h" followed by the number in the right format.' }
        end
        return { 'bin: ' .. binary, 'dec: ' .. decimal, 'hex: ' .. hex }
    end

    local function evaluate_expression(expression)
        local env = { math = math, log2 = math.log }
        env.log2 = function(x) return math.log(x) / math.log(2) end
        return load('return ' .. expression, 'expression', 't', env)
    end

    local result, result_func, error_string
    input = input:gsub(cmd_window_prefix, '')
    if input:match('^' .. radix_conversion_string .. '%s+') then
        local number_input = input:sub(#radix_conversion_string + 1):gsub('%s+', '')
        result = convert_number(number_input)
    else
        result_func, error_string = evaluate_expression(input)
        if result_func then
            local success, eval_result = pcall(result_func)
            if success then
                eval_result = eval_result ~= nil and tostring(eval_result) or 'nil'
                if eval_result ~= 'nil' then result = { input .. ' = ' .. eval_result } else result = nil end
                last_answer = eval_result
            else
                result = { 'Error: ' .. input .. ' Invalid expression'}
            end
        else
            result = { 'Error: ' .. input .. ' threw the following exception: ' .. error_string }
        end
    end

    if result then
        local result_line_count = vim.api.nvim_buf_line_count(result_buf)
        vim.api.nvim_buf_set_lines(result_buf, result_line_count, result_line_count, false, result)

        local result_oneliner = table.concat(result, ' ') --  FIXME - aleuchte - 31.10.24 - don't save errors in history
        table.insert(calculation_history, result_oneliner)
        table.insert(cmd_history, input)
    end

    if #calculation_history > max_allowed_calculation_history then
        table.remove(calculation_history, 1)
    end

    if #cmd_history > max_allowed_calculation_history then
        table.remove(cmd_history, 1)
    end

    local result_buf_line_count = vim.api.nvim_buf_line_count(result_buf)
    vim.api.nvim_win_set_cursor(result_win, { result_buf_line_count, 0 }) -- make sure we scroll down in the result window

    vim.api.nvim_buf_set_lines(cmd_buf, line_number - 1, line_number, false, { cmd_window_prefix })
    vim.api.nvim_win_set_cursor(cmd_win, { line_number, #cmd_window_prefix + 1 })
end

function M.setup(opts)
    opts = opts or {}
    max_allowed_calculation_history = opts.max_allowed_calculation_history or 10
    width = width or 100
    height = (height - cmd_height) or 20
    binary_prefix = opts.binary_prefix or 'b'
    decimal_prefix = opts.decimal_prefix or 'd'
    hexa_prefix = opts.hexa_prefix or 'h'
    radix_conversion_string = opts.radix_conversion_string or 'convert'
    last_answer_access_string = opts.last_answer_access_string or 'ans'
    title_color = opts.title_color or '#0000FF'
    vim.api.nvim_create_user_command('Calculator', M.create_calculator_window, {})
    vim.api.nvim_create_user_command('Calculatorhelp', M.create_help_window, {})
end

return M

