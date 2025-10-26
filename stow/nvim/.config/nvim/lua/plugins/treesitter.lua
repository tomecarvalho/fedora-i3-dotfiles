return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua",
        "html", "css",
        "javascript", "tsx",
        "markdown", "markdown_inline",
        "latex",
        "norg",
        "scss",
        "svelte",
        "typst",
        "vue",
      },
      auto_install = true,
    },
  },
}
