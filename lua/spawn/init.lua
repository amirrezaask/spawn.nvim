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

  if opts.sync and opts.stdout then
    print('you can specify only one of stdout or sync')
    return
  end

  local done = false
  local handle, _ = uv.spawn(opts.command, {
    args = opts.args,
    stdio = { stdin, stdout, stderr },
  }, function(code, _)
    -- assert(code == 0, 'process ' .. opts.command .. ' exited with code ' .. code)
    if opts.on_exit and type(opts.on_exit) == 'function' then
      opts.on_exit()
    end
  end)
  if not handle then
    print('could not spawn the process')
    return
  end
  if opts.stdin then
    if type(opts.stdin) == 'table' then
      uv.write(stdin, table.concat(opts.stdin, '\n'), function()
        stdin:close()
      end)
    end
    if type(opts.stdin) == 'string' then
      uv.write(stdin, opts.stdin, function()
        stdin:close()
      end)
    end
  end
  uv.read_start(stderr, function(err, data)
    assert(not err, 'cannot read from stderr')
    if data then
      print('err: ' .. data)
    end
  end)
  if opts.stdout then
    if type(opts.stdout) == 'function' then
      uv.read_start(stdout, function(err, data)
        assert(not err, 'error in reading from stdout')
        -- TODO: maybe split this by newline
        if data then
          opts.stdout(vim.split(data, '\n'))
        end
      end)
    end

    if type(opts.stdout) == 'number' then
      uv.read_start(stdout, function(err, data)
        assert(not err, 'error in reading from stdout')
        if data then
          vim.schedule(function()
            vim.api.nvim_buf_set_lines(opts.stdout, 0, -1, false, vim.split(data, '\n'))
          end)
        end
      end)
    end
  end
  if opts.sync then
    local output = {}
    uv.read_start(stdout, function(err, data)
      assert(not err, 'error in reading from stdout: ')
      if data then
        local tmp = vim.split(data, '\n')
        for _, v in pairs(tmp) do
          if v ~= '' then
            table.insert(output, v)
          end
        end
      end
      if data == nil then
        stdout:close()
        done = true
      end
    end)
    vim.wait(opts.sync.timeout, function()
      return done
    end, opts.sync.interval, false)
    return output
  end
end

-- P(spawn({
--   command = 'bash',
--   args = { 'lazy.sh' },
--   -- stdout = 9,
--   sync = { timeout = 4000, interval = 10 },
-- }))

return spawn
