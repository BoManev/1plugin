local M = {}

-- nvim --cmd "set rtp+=." /path/to/file
M.setup = function()
  print('plugin setup')
end

-- TODO: test
M.todolist = function()
  local query_string = '((comment) @comment (#match? @comment "TODO"))'
  local parser = require('nvim-treesitter.parsers').get_parser()
  local ok, query = pcall(vim.treesitter.query.parse, parser:lang(), query_string)
  if not ok then
    print('no comment nodes')
    return
  end
  local tree = parser:parse()[1]
  local qf_list = {}
  for id, node, metadata in query:iter_captures(tree:root(), 0, 0, -1) do
    print(id, node, metadata)
    local text = vim.treesitter.get_node_text(node, 0)
    local lnum, col = node:range()
    table.insert(qf_list, {
      bufnr = vim.api.nvim_get_current_buf(),
      text = text,
      lnum = lnum + 1,
      col = col + 1,
    })
  end
  vim.fn.setqflist(qf_list)
  vim.cmd.copen()
end

M.runsmt = function()
  vim.fn.jobstart({ 'echo', 'test' }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), -1, -1, false, data)
      end
    end,
  })
end

return M
