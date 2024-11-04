local config = require('config')
local M = {
    cmd_history = {},
    calculation_history = {},
    key_mappings = {
        ['<A-l>'] = { func = 'log2()', desc = 'Log base 2' },
        ['<A-s>'] = { func = 'math.sqrt()', desc = 'Square root' },
        ['<A-c>'] = { func = config.settings.radix_conversion_string .. ' ', desc = 'Insert "convert"' }, -- need two spaces after convert because cursor moves one to the left
    }
}

function M.evaluate_math_env(expression)
    local env = { math = math, log2 = math.log }
    env.log2 = function(x) return math.log(x) / math.log(2) end
    return load('return ' .. expression, 'expression', 't', env)
end

function M.create_buffer_window(width, height, row, col, title)
    local buffer = vim.api.nvim_create_buf(false, true)
    title = title or ''
    local window = vim.api.nvim_open_win(buffer, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'single',
        title = title,
    })

    return buffer, window
end

function M.handle_input()
    local line = vim.api.nvim_get_current_line()
    local input = line:gsub(config.settings.cmd_window_prefix, '')
    return input
end

function M.strip_spaces(input)
    return input:gsub('%s+', '')
end

function M.to_binary(num)
    local binary = ''
    while num > 0 do
        binary = (num % 2) .. binary
        num = math.floor(num / 2)
    end
    return binary == '' and '0' or binary
end

function M.build_help_text()
    local help_text = ""
    for key, mapping in pairs(M.key_mappings) do
        help_text = help_text .. key .. ' -> ' .. mapping.func .. ' -> ' .. mapping.desc .. '\n'
    end
    return help_text
end

return M

