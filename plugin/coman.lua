local api = vim.api
local coman = require('coman')

api.nvim_create_user_command('ComComment', function(args)
  coman:gen_comment(args.line1, args.line2)
end, {
  range = true,
  desc = 'Coman.nvim comment command',
})

api.nvim_create_user_command('ComAnnotation', function()
  coman:gen_annotation()
end, {})
