local utils = require("lsp-file-operations.utils")
local log = require("lsp-file-operations.log")

local M = {}

function M.callback(data)
  local clients = vim.fn.has("nvim-0.10") == 1 and vim.lsp.get_clients()
    or vim.lsp.get_active_clients()
  for _, client in pairs(clients) do
    if client.initialized ~= nil and client.initialized then
      local did_create = utils.get_nested_path(
        client,
        { "server_capabilities", "workspace", "fileOperations", "didCreate" }
      )
      if did_create then
        local filters = did_create.filters or {}
        if utils.matches_filters(filters, data.fname) then
          local params = {
            files = {
              { uri = vim.uri_from_fname(data.fname) },
            },
          }
          if vim.fn.has("nvim-0.11") == 1 then
            client:notify("workspace/didCreateFiles", params)
          else
            client.notify("workspace/didCreateFiles", params)
          end
          log.debug("Sending workspace/didCreateFiles notification", params)
        end
      end
    end
  end
end

return M
