# spawn.nvim
Simple wrapper around libuv.spawn which makes it easy to use in neovim, specially when you want sync behaviour.

# Usage
spawn exposes just a simple function that get some options:
- command: name of the program you want to run
- args: arguments to pass to program [ table like uv.spawn itself ]
- stdin: can be either a table or a string, both will be written in stdin pipe.
- stdout: can be either a number or a callback ( see below )
- sync: table that defines a timeout ( in milis ) and an interval ( in milis ).
remember that sync and stdout cannot be defined together since sync mode assumes your output is going
to be spawn return value.
## Sync mode
Sync mode returns the output of program splitted based on `\n` char.
```lua
local spawn = require'spawn'

spawn {
    command = 'find',
    args = { '--type', 's,f' },
    sync = { timeout = 1000, interval = 100 }
}
```
## Async mode
in async mode you need to specify stdout which can be either a number or a callback, number should
represent a neovim buffer and callback should get a chunk of data and handle it.
### Buffer Stdout
```lua
spawn {
    command = 'find',
    args = { '--type', 's,f' },
    stdout = 5, -- results are going to be written in buffer number 5
}
```

### callback stdout
```lua
spawn {
    command = 'find',
    args = { '--type', 's,f' },
    stdout = function(chunk)
        -- handle data
    end
}
```


