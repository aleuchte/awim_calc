local M = {}

M.settings = {
    max_calculation_history = 10,
    width = 100,
    height = 20,
    cmd_height = 1,
    help_window_height = 5,
    binary_prefix = 'b',
    decimal_prefix = 'd',
    hexa_prefix = 'h',
    radix_conversion_string = 'convert ',
    last_answer_access_string = 'ans',
    calculator_title = 'Awim Calculator',
    title_color = '#0000FF',
    cmd_window_prefix = '> ',
}

function M.setup(opts)
    M.settings = vim.tbl_deep_extend("force", M.settings, opts or {})
end

return M

