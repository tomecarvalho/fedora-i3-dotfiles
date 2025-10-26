-- Disable unused providers
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
