local utils = require("lsp-file-operations.utils")
local log = require("lsp-file-operations.log")

local M = {}

function M.callback(data)
  local clients = vim.fn.has("nvim-0.10") == 1 and vim.lsp.get_clients()
    or vim.lsp.get_active_clients()
  for _, client in pairs(clients) do
    if client.initialized ~= nil and client.initialized then
      local did_rename = utils.get_nested_path(
        client,
        { "server_capabilities", "workspace", "fileOperations", "didRename" }
      )
      if did_rename then
        local filters = did_rename.filters or {}
        if utils.matches_filters(filters, data.old_name) then
          local params = {
            files = {
              {
                oldUri = vim.uri_from_fname(data.old_name),
                newUri = vim.uri_from_fname(data.new_name),
              },
            },
          }
          if vim.fn.has("nvim-0.11") == 1 then
            client:notify("workspace/didRenameFiles", params)
          else
            client.notify("workspace/didRenameFiles", params)
          end
          log.debug("Sending workspace/didRenameFiles notification", params)
        end
      end
    end
  end
end

return M
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
