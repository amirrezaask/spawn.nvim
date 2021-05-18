local function spawn(opts)
  assert(opts, 'You should pass opts')
  assert(opts.command, 'You should pass opts.command')
  if opts.stdout and opts.sync then
    assert(false, 'cannot specify both stdout and sync')
    return
  end
  local stdout_done = false
  local stderr_done = false
  local process_done = false
  local stdout = {}
  local stderr = {}


  local function is_eof_stdout(data)
    if data[1] == '' then
      stdout_done = true
    end
  end

  local function is_eof_stderr(data)
    if data[1] == '' then
      stderr_done = true
    end
  end

  local function on_stdout_buffer(buf)
    return function(_, data, _)
      if is_eof_stdout(data) then
        stdout_done = true
        return
      end
      local c = vim.api.nvim_buf_get_lines(buf)
      vim.api.nvim_buf_set_lines(buf, c, -1, false, data)
    end
  end

  local function on_stderr_buffer(buf)
    return function(_, data, _)
      if is_eof_stderr(data) then
        stderr_done = true
        return
      end
      local c = vim.api.nvim_buf_get_lines(buf)
      vim.api.nvim_buf_set_lines(buf, c, -1, false, data)

    end
  end

  if type(opts.stdout) == "number" then
    opts.stdout = on_stdout_buffer(opts.stdout)
  end

  if type(opts.stderr) == "number" then
    opts.stdout = on_stderr_buffer(opts.stderr)
  end

  local function on_stdout_sync()
    return function(_, data,_ )
      if is_eof_stdout(data) then
        stdout_done = true
      end
      for _, l in ipairs(data) do
        if l ~= '' then
          table.insert(stdout, l)
        end
      end
    end
  end

  local function on_stderr_sync()
    return function(_, data,_ )
      if is_eof_stderr(data) then
        stderr_done = true
      end
      for _, l in ipairs(data) do
        if l ~= '' then
          table.insert(stderr, l)
        end
      end
    end
  end

  local function on_exit(id, code, event)
    if code ~= 0 then 
      success = false
    end
    process_done = true
    if opts.on_exit then opts.on_exit(id, code, event) end
  end

  local on_stdout
  local on_stderr

  if type(opts.stdout) == 'number' then
    on_stdout = on_stdout_buffer(opts.stdout)
  end

  if type(opts.stderr) == 'number' then
    on_stderr = on_stdout_buffer(opts.stderr)
  end

  if opts.sync then
    on_stdout = on_stdout_sync()
    on_stderr = on_stderr_sync()
  end

  local success = true

  local stdin_id = vim.fn.jobstart(opts.command, {
    cwd = opts.cwd or '.',
    on_exit = on_exit,
    on_stdout = on_stdout,
    on_stderr = on_stderr
  })
  if type(opts.stdin) == 'table' or type(opts.stdin) == 'string' then
    vim.fn.chansend(stdin_id, opts.stdin)
  end
  if opts.sync then
    vim.wait(2000, function()
      return process_done and stdout_done and stderr_done 
    end, 10)
    return stdout, stderr, success
  end
end
