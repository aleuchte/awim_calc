# awim_calc
Calculator plugin for neovim written in lua

Lazy setup:
return {
    'aleuchte/awim_calc',
    name = 'awim_calc',
    config = function()
        require('awim_calc').setup({
            max_allowed_calculation_history = 10,  -- Maximum number of calculations to store in history
            width = 100                            -- Width of the calculator window
            height = 20                            -- Height of the calculator window
            binary_prefix = 'b'                    -- Prefix for binary numbers
            decimal_prefix = 'd'                   -- Prefix for decimal numbers
            hexa_prefix = 'h'                      -- Prefix for hexadecimal numbers
            radix_conversion_string = 'convert'    -- String to use for radix conversion
            last_answer_access_string = 'ans'      -- String to use to access the last answer
        })
    end,
    cmd = { 'Calculator' },                        -- Lazy loading upon command
}
