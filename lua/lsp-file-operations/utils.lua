local Path = require("plenary").path

local log = require("lsp-file-operations.log")

local M = {}

---@param T table
---@param keys (string|integer)[]
---@return table|nil
function M.get_nested_path(T, keys)
  if #keys == 0 then
    return T
  end
  local key = keys[1]
  if T[key] == nil then
    return
  end
  return M.get_nested_path(T[key], { unpack(keys, 2) })
end

-- needed for globs like `**/`
---@param path string
---@param is_dir boolean
---@return string path
local function ensure_dir_trailing_slash(path, is_dir)
  return (is_dir and not path:match("/$")) and (path .. "/") or path
end

---@param name string
---@return string absolute_path
---@return boolean is_dir
local function get_absolute_path(name)
  local path = Path:new(name)
  local is_dir = path:is_dir()
  local absolute_path = ensure_dir_trailing_slash(path:absolute(), is_dir)
  return absolute_path, is_dir
end

---@param pattern lsp.FileOperationPattern
---@return string regex
local function get_regex(pattern)
  local regex = vim.fn.glob2regpat(pattern.glob)
  return (pattern.options and pattern.options.ignoreCase) and ("\\c" .. regex) or regex
end

-- filter: FileOperationFilter
---@param filter lsp.FileOperationFilter
---@param name string
---@param is_dir boolean
local function match_filter(filter, name, is_dir)
  local match_type = filter.pattern.matches
  if
    not match_type
    or (match_type == "folder" and is_dir)
    or (match_type == "file" and not is_dir)
  then
    local regex = get_regex(filter.pattern)
    log.debug("Matching name", name, "to pattern", regex)
    local previous_ignorecase = vim.o.ignorecase
    vim.o.ignorecase = false
    local matched = vim.fn.match(name, regex) ~= -1
    vim.o.ignorecase = previous_ignorecase
    return matched
  end

  return false
end

-- filters: FileOperationFilter[]
---@param filters lsp.FileOperationFilter[]
---@param name string
function M.matches_filters(filters, name)
  local absolute_path, is_dir = get_absolute_path(name)
  for _, filter in pairs(filters) do
    if match_filter(filter, absolute_path, is_dir) then
      log.debug("Path did match the filter", absolute_path, filter)
      return true
    end
  end
  log.debug("Path didn't match any filters", absolute_path, filters)
  return false
end

return M
