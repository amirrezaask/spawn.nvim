local function exists(tbl, keys)
  for _, k in pairs(keys) do
    if not tbl[k] then
      return k
    end
  end
  return nil
end

local function spawn(opts)
  if not opts then
    print('Please pass a table with something in it, i dont know what to do')
  end
  local keys_missing = exists(opts, { 'command' })
  if keys_missing then
    print('key ' .. keys_missing(' is missing.'))
  end
  local uv = vim.loop
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  if opts.stdin then
    if type(opts.stdin) == 'table' then
      uv.write(stdin, table.concat(opts.stdin))
    end
    if type(opts.stdin) == 'string' then
      uv.write(stdin, table.concat(opts.stdin))
    end
  end
  local handle, _ = uv.spawn(opts.command, {
    args = opts.args,
    stdio = { stdin, stdout, stderr },
    cwd = '/home/amirreza/src/github.com/amirrezaask/spawn.nvim/lua/spawn',
  }, function(code, signal)
    assert(code == 0, 'process ' .. opts.command .. ' exited with code ' .. code)
    if opts.on_exit and type(opts.on_exit) == 'function' then
      opts.on_exit()
    end
  end)
  if not handle then
    print('could not spawn the process')
    return
  end
  local output_data
  if opts.stdout then
    if type(opts.stdout) == 'function' then
      uv.read_start(stdout, function(err, data)
        assert(not err, 'error in reading from stdout')
        -- TODO: maybe split this by newline
        if data then
          output_data = vim.split(data, '\n')
          opts.stdout(vim.split(data, '\n'))
        end
      end)
    end

    if type(opts.stdout) == 'number' then
      uv.read_start(stdout, function(err, data)
        assert(not err, 'error in reading from stdout')
        if data then
          output_data = vim.split(data, '\n')
          vim.schedule(function()
            vim.api.nvim_buf_set_lines(opts.stdout, 0, -1, false, vim.split(data, '\n'))
          end)
        end
      end)
    end
  end
  uv.shutdown(stdin, function()
    uv.close(handle, function()
    end)
  end)
  if opts.sync then
    vim.wait(opts.sync.timeout, function()
      if output_data then
        return output_data
      end
      return false
    end)
  end
end

spawn({
  command = 'bash',
  args = { 'lazy.sh' },
  stdout = 6,
  on_exit = function()
    print('on_exit callback')
  end,
  sync = { timeout = 10000, interval = 100 },
})

return spawn
