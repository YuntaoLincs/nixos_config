return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "pyright",
      },
    },
    config = function(_, opts)
      require("mason").setup({
        ui = {
          check_outdated_packages_on_open = true,
          border = "none",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
      local mr = require("mason-registry")
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        automatic_installation = false,
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'saghen/blink.cmp', "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },

    -- example calling setup directly for each LSP
    config = function()
      vim.diagnostic.config({
        underline = false,
        signs = false,
        update_in_insert = false,
        virtual_text = { spacing = 2, prefix = "●" },
        severity_sort = true,
        float = {
          border = "rounded",
        },
      })

      local capabilities = require('blink.cmp').get_lsp_capabilities()
      
      -- Auto-start lua_ls for Lua files
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'lua',
        callback = function(args)
          vim.lsp.start({
            name = 'lua_ls',
            cmd = { 'lua-language-server' },
            root_dir = vim.fs.root(args.buf, { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' }),
            capabilities = capabilities,
            settings = {
              Lua = {
                runtime = {
                  version = 'LuaJIT',
                },
                diagnostics = {
                  globals = {'vim'},
                },
                workspace = {
                  library = vim.api.nvim_get_runtime_file("", true),
                },
                telemetry = {
                  enable = false,
                },
              },
            },
          })
        end,
      })

      -- Auto-start pyright for Python files
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'python',
        callback = function(args)
          vim.lsp.start({
            name = 'pyright',
            cmd = { 'pyright-langserver', '--stdio' },
            root_dir = vim.fs.root(args.buf, { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' }),
            capabilities = capabilities,
            settings = {
              python = {
                analysis = {
                  autoSearchPaths = true,
                  useLibraryCodeForTypes = true,
                  diagnosticMode = 'workspace',
                },
              },
            },
          })
        end,
      })

      -- Use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover)
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, {
            buffer = ev.buf,
            desc = "[LSP] Show diagnostic",
          })
          vim.keymap.set("n", "<leader>gk", vim.lsp.buf.signature_help, { desc = "[LSP] Signature help" })
          vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, { desc = "[LSP] Add workspace folder" })
          vim.keymap.set(
            "n",
            "<leader>wr",
            vim.lsp.buf.remove_workspace_folder,
            { desc = "[LSP] Remove workspace folder" }
          )
          vim.keymap.set("n", "<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, { desc = "[LSP] List workspace folders" })
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = ev.buf, desc = "[LSP] Rename" })
          -- Mason keymap
          vim.keymap.set('n', '<leader>lm', '<cmd>Mason<cr>', { desc = 'Open Mason' })
        end,
      })

    end
  }
}
