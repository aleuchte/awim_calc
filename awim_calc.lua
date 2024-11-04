local M = {}

M.config = require('config')
M.windows = require('windows')
M.evaluation = require('evaluation')

function M.setup(opts)
    M.config.setup(opts)
    M.windows.setup_commands()
end

return M

