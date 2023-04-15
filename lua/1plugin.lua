local M = {}

-- nvim --cmd "set rtp+=." /path/to/file
M.setup = function()
  print('plugin setup')
  vim.keymap.set('n', '<localleader>r', M.runcursor, {noremap = true})
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

M.runfile = function()
  local query_string =
    '((ranged_verbatim_tag (tag_parameters ((tag_param) @tag (#match? @tag "fennel"))) content: (ranged_verbatim_tag_content) @content) @block)'
  local parser = require('nvim-treesitter.parsers').get_parser()
  local ok, query = pcall(vim.treesitter.query.parse, parser:lang(), query_string)
  if not ok then
    print('Not inside .fnl')
    return
  end
  local tree = parser:parse()[1]
  for id, node, metadata in query:iter_captures(tree:root(), 0, 0, -1) do
    print(id, node, metadata)
    if node and node:type() == 'ranged_verbatim_tag_content' then
      local capture = vim.treesitter.get_node_text(node, 0)
      for line in capture:gmatch('([^\n]*)\n?') do
        line = line:gsub('^%s+', ''):gsub('%s+$', '')
        if line ~= '' then
          M.replit(line)
        end
      end
    end
  end
end

M.runcursor = function()
  local node = vim.treesitter.get_node()
  if node ~= nil then
    local runit = false
    for cnode in node:iter_children() do
      print(cnode)
      if cnode and cnode:type() == 'tag_parameters' then
        local capture = vim.treesitter.get_node_text(cnode, 0)
        if capture == 'fennel' then
          runit = true
        end
      end
      if cnode and cnode:type() == 'ranged_verbatim_tag_content' and runit then
        local capture = vim.treesitter.get_node_text(cnode, 0)
        for line in capture:gmatch('([^\n]*)\n?') do
          line = line:gsub('^%s+', ''):gsub('%s+$', '')
          if line ~= '' then
            M.replit(line)
          end
        end
      end
    end
  end
end

M.replit = function(code)
  local eval = require('conjure.eval')
  local client = require('conjure.client')
  local text = require('conjure.text')

  client['with-filetype']('fennel', eval['eval-str'], {
    origin = 'my-awesome-plugin',
    code = code, -- Use the captured body as the code to be evaluated
    ['on-result'] = function(r)
      local clean = text['strip-ansi-escape-sequences'](r)
      print('RESULT:', r)
      print('CLEANED:', clean)
    end,
  })
end
return M
