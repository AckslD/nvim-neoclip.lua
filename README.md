# nvim-neoclip.lua

_This is a story about Bob_ 👷.

_Bob loves vim_ ❤️.

_Bob likes to yank_ ©️.

_Bob knows about registers but sometimes forgets them_ ®️.

_This is what happens to Bob everyday_ 🚧:

* _Bob yanks some line._ 😀
* _Bob yanks another line._ 🤔
* _Bob realises he actually wanted the first._ 🙁
* _But it is gone and Bob is now sad._ 😢

_Don't be like Bob, use neoclip!_ 🎉

`neoclip` is a clipboard manager for neovim inspired by for example [`clipmenu`](https://github.com/cdown/clipmenu).
It records everything that gets yanked in your vim session (up to a limit which is by default 1000 entries but can be configured).
You can then select an entry in the history using [`telescope`](https://github.com/nvim-telescope/telescope.nvim) or [`fzf-lua`](https://github.com/ibhagwan/fzf-lua) which then gets populated in a register of your choice.

If you're on latest nightly (works if `:echo exists('##RecordingLeave')` returns `1`) `neoclip` will also keep track of any recorded macro (opt-out) which you can search for using `telescope`, put back in a register or simply replay.

That's it!

Oh, some more things, you can define an optional filter if you don't want some things to be saved and custom actions to take.

Hold on, `neoclip` optionally also supports persistent history between sessions powered by [`sqlite.lua`](https://github.com/kkharji/sqlite.lua).

![neoclip](https://user-images.githubusercontent.com/23341710/140090515-83a08f0f-85f9-4278-bcbe-48e4d8442ace.png)

## Installation

<details>
    <summary>Using <a href="https://github.com/folke/lazy.nvim">Lazy.nvim</a></summary>

```lua
require {
  "AckslD/nvim-neoclip.lua",
  dependencies = {
    -- you'll need at least one of these
    -- {'nvim-telescope/telescope.nvim'},
    -- {'ibhagwan/fzf-lua'},
  },
  config = function()
    require('neoclip').setup()
  end,
}
```
</details>

<details>
    <summary>Using <a href="https://github.com/wbthomason/packer.nvim">Packer</a></summary>

```lua
use {
  "AckslD/nvim-neoclip.lua",
  requires = {
    -- you'll need at least one of these
    -- {'nvim-telescope/telescope.nvim'},
    -- {'ibhagwan/fzf-lua'},
  },
  config = function()
    require('neoclip').setup()
  end,
}
```
</details>

<br>

When `require('neoclip').setup()` is called, only the autocommand (for `TextYankPost` event) is setup to save yanked things. This means that `telescope` is not required at this point if you lazy load it. Depending on your setup you might need to load the telescope extension before using it though, see the [troubleshooting](#troubleshooting)-section below.

If you want to use persistent history between sessions you also need [`sqlite.lua`](https://github.com/kkharji/sqlite.lua) installed, for example by:

<details>
    <summary>Using <a href="https://github.com/folke/lazy.nvim">Lazy.nvim</a></summary>

```lua
require {
  "AckslD/nvim-neoclip.lua",
  dependencies = {
    {'kkharji/sqlite.lua', module = 'sqlite'},
    -- you'll need at least one of these
    -- {'nvim-telescope/telescope.nvim'},
    -- {'ibhagwan/fzf-lua'},
  },
  config = function()
    require('neoclip').setup()
  end,
}
```

</details>

<details>
    <summary>Using <a href="https://github.com/wbthomason/packer.nvim">Packer</a></summary>

```lua
use {
  "AckslD/nvim-neoclip.lua",
  requires = {
    {'kkharji/sqlite.lua', module = 'sqlite'},
    -- you'll need at least one of these
    -- {'nvim-telescope/telescope.nvim'},
    -- {'ibhagwan/fzf-lua'},
  },
  config = function()
    require('neoclip').setup()
  end,
}
```

</details>

## Configuration
You can configure `neoclip` by passing a table to `setup` (all are optional).
The following are the defaults and the keys are explained below:
```lua
require('neoclip').setup({
  history = 1000,
  enable_persistent_history = false,
  length_limit = 1048576,
  continuous_sync = false,
  db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3",
  filter = nil,
  preview = true,
  prompt = nil,
  default_register = '"',
  default_register_macros = 'q',
  enable_macro_history = true,
  content_spec_column = false,
  disable_keycodes_parsing = false,
  picker_display_callback = nil,
  on_select = {
	move_to_front = false,
	close_telescope = true,
  },
  on_paste = {
	set_reg = false,
	move_to_front = false,
	close_telescope = true,
  },
  on_replay = {
	set_reg = false,
	move_to_front = false,
	close_telescope = true,
  },
  on_custom_action = {
	close_telescope = true,
  },
  keys = {
	telescope = {
	  i = {
		select = '<cr>',
		paste = '<c-p>',
		paste_behind = '<c-k>',
		replay = '<c-q>',  -- replay a macro
		delete = '<c-d>',  -- delete an entry
		edit = '<c-e>',  -- edit an entry
		custom = {},
	  },
	  n = {
		select = '<cr>',
		paste = 'p',
		--- It is possible to map to more than one key.
		-- paste = { 'p', '<c-p>' },
		paste_behind = 'P',
		replay = 'q',
		delete = 'd',
		edit = 'e',
		custom = {},
	  },
	},
	fzf = {
	  select = 'default',
	  paste = 'ctrl-p',
	  paste_behind = 'ctrl-k',
	  custom = {},
	},
  },
})

```
* `history`: The max number of entries to store (default 1000).
* `enable_persistent_history`: If set to `true` the history is stored on `VimLeavePre` using [`sqlite.lua`](https://github.com/kkharji/sqlite.lua) and lazy loaded when querying.
* `length_limit`: The max number of characters of an entry to be stored (default 1MiB). If the length of the yanked string is larger than the limit, it will not be stored.
* `continuous_sync`: If set to `true`, the runtime history is synced with the persistent storage everytime it's changed or queried.
  If you often use multiple sessions in parallel and wants the history synced you might want to enable this.
  Of by default cause it might cause delays since the history is written to file everytime you yank something.
  Although, I don't really notice a slowdown.
  Alternatively see `db_pull` and `db_push` functions [below](#sync-database).
* `db_path`: The path to the sqlite database to store history if `enable_persistent_history=true`.
  Defaults to `vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3` which on my system is `~/.local/share/nvim/databases/neoclip.sqlite3`
* `filter`: A function to filter what entries to store (default all are stored).
  This function filter should return `true` (include the yanked entry) or `false` (don't include it) based on a table as the only argument, which has the following keys:
  * `event`: The event from `TextYankPost` (see `:help TextYankPost` for which keys it contains).
  * `filetype`: The filetype of the buffer where the yank happened.
  * `buffer_name`: The name of the buffer where the yank happened.
* `preview`: Whether to show a preview (default) of the current entry or not.
  Useful for for example multiline yanks.
  When yanking the filetype is recorded in order to enable correct syntax highlighting in the preview.
  NOTE: in order to use the dynamic title showing the type of content and number of lines you need to configure `telescope` with the `dynamic_preview_title = true` option.
* `default_register`: What register to use by default when not specified (e.g. `Telescope neoclip`).
  Can be a string such as `'"'` (single register) or a table of strings such as `{'"', '+', '*'}`.
* `default_register_macros`: What register to use for macros by default when not specified (e.g. `Telescope macroscope`).
* `enable_macro_history`: If `true` (default) any recorded macro will be saved, see [macros](#macros).
* `content_spec_column`: Can be set to `true` (default `false`) to use instead of the preview.
* `disable_keycodes_parsing`: If set to `true` (default `false`), macroscope will display the internal byte representation, instead of a proper string that can be used in a `map`. So a macro like "`one<CR>two`" will be displayed as "`one\ntwo`"
  It will only show the type and number of lines next to the first line of the entry.
* `picker_display_callback`: Function to call to customize the display of an item in the picker (default `nil`).
* `on_select`:
  * `move_to_front`: if the entry should be set to last in the list when pressing the key to select a yank.
  * `close_telescope`: if telescope should close whenever an item is selected.
* `on_paste`:
  * `set_reg`: if the register should be populated when pressing the key to paste directly.
  * `move_to_front`: if the entry should be set to last in the list when pressing the key to paste directly.
  * `close_telescope`: if telescope should close whenever a yank is pasted
* `on_replay`:
  * `set_reg`: if the register should be populated when pressing the key to replay a recorded macro.
  * `move_to_front`: if the entry should be set to last in the list when pressing the key to replay a recorded macro.
  * `close_telescope`: if telescope should close whenever a macro is replayed
* `on_custom_action`:
  * `close_telescope`: if telescope should close whenever a custom action is executed
* `keys`: keys to use for the different pickers (`telescope` and `fzf-lua`).
  With `telescope` normal key-syntax is supported and both insert `i` and normal mode `n`.
  With `fzf-lua` only insert mode is supported and `fzf`-style key-syntax needs to be used.
  You can also use the `custom` entry to specify custom actions to take on certain key-presses, see [below](#custom-actions) for more details.
  NOTE: these are only set in the `telescope` buffer and you need to setup your own keybindings to for example open `telescope`.

See screenshot section below for how the settings above might affect the looks.

### Custom actions
You can specify custom actions in the `keys` entry in the settings.
For example you can do:
```lua
require('neoclip').setup({
  ...
  keys = {
    ...
    n = {
      ...
      custom = {
        ['<space>'] = function(opts)
          print(vim.inspect(opts))
        end,
      },
    },
  },
})
```
which when pressing `<space>` in normal mode will print something like:
```
{
  register_names = { '"' },
  typ = "yanks" -- Will be "macros" if selected from :Telescope macroscope
  entry = {
    contents = { "which when pressing `<space>` in normal mode will print something like:" },
    filetype = "markdown",
    regtype = "l"
  }
}
```
to do your custom action and also populate a register and/or paste you can call `neoclip`s built-in handlers, such as:
```lua
require('neoclip').setup({
  ...
  keys = {
    ...
    n = {
      ...
      custom = {
        ['<space>'] = function(opts)
          -- do your stuff
          -- ...
          local handlers = require('neoclip.handlers')
          -- optionally set the registers with the entry
          -- handlers.set_registers(opts.register_names, opts.entry)
          -- optionally paste entry
          -- handlers.paste(opts.entry, 'p')
          -- optionally paste entry behind
          -- handlers.paste(opts.entry, 'P')
        end,
      },
    },
  },
})
```

## Usage
### Yanks
Yank all you want and then do:
```vim
:Telescope neoclip
```
if using `telescope` or
```vim
:lua require('neoclip.fzf')()
```
if using `fzf-lua`, which will show you a history of the yanks that happened in the current session.
If you pick (default `<cr>`) one this will then replace the current `"` (unnamed) register.

If you instead want to directly paste it you can press by default `<c-p>` in insert mode and `p` in normal.
Paste behind is by default `<c-k>` and `P` respectively.

If you want to replace another register with an entry from the history you can do for example:
```vim
:Telescope neoclip a
```
if using `telescope` or
```vim
:lua require('neoclip.fzf')('a')
```
if using `fzf-lua`, which will replace register `a`.
The register `[0-9a-z]` and `default` (`"`) are supported.

The following special registers are supported:
* `"`: `Telescope neoclip unnamed`
* `*`: `Telescope neoclip star`
* `+`: `Telescope neoclip plus`

and `Telescope neoclip` (and `Telescope neoclip default`) will use what you set `default_register` in the `setup`.

You can also specify more registers to populate in a single command with the `extra` keyword argument which
supports registers separated by comma, for example:
```vim
:Telescope neoclip a extra=star,plus,b
```
if using `telescope` or
```vim
:lua require('neoclip.fzf')({'a', 'star', 'plus', 'b'})
```
if using `fzf-lua`.

### Macros
If `enable_macro_history` is set to `true` (default) in the [`setup`](#configuration) then any recorded macro will be stored and can later be accessed using:
```vim
:Telescope macroscope
```
or equivalently (which is probably the better way if you're lazy loading `telescope`):
```vim
:lua require('telescope').extensions.macroscope.default()
```
The same arguments are supported as for the `neoclip` extension.

NOTE: This feature requires latest nightly and in particular [this PR](https://github.com/neovim/neovim/pull/16684). You can check that your neovim supports this by checking that `:echo exists('##RecordingLeave')` returns `1`. If not then everything will work normally except that no macro will be saved in the history of `neoclip`.

### Start/stop
If you temporarily don't want `neoclip` to record anything you can use the following calls:
* `:lua require('neoclip').start()`
* `:lua require('neoclip').stop()`
* `:lua require('neoclip').toggle()`

### Sync database
If you don't want to use the setting `continuous_sync`, but still keep two instances of neovim synchronized in their `neoclip` history you can use the functions:
* `:lua require('neoclip').db_pull()`: Pulls the database (overwrites any local history in the current session).
* `:lua require('neoclip').db_push()`: Pushes to the database (overwrites any history previous saved in the database).

### Remove entries
You can remove entries manually using the keybinds for `delete`. You can also delete the whole history with `:lua require('neoclip').clear_history()`.

### Edit entries
You can edit the contents of an entry using the keybinds for `edit`. It'll open the contents of the entry in a separate floating buffer. When you leave the buffer (`:q`), it'll update the contents of the entry with what's in the buffer.

## Tips
* Duplicate yanks are not stored, but rather pushed forward in the history such that they are the first choice when searching for previous yanks.
  Equality is checked using content and also type (ie charwise, linewise or blockwise), so if you have to yanks with the same content but when yanked charwise and the other linewise, these are considered two different entries.
  However, the filetype in the buffer when the yanked happened is not, so if you yank `print('hello')` in a `python` file and then in a `lua` file you'll have a single entry which will be previewed using `lua` syntax.
* If you lazy load [`telescope`](https://github.com/nvim-telescope/telescope.nvim) with [`packer`](https://github.com/wbthomason/packer.nvim) with for example the key `module = telescope`, then it's better to use e.g. `:lua require('telescope').extensions.neoclip.default()` than `:Telescope neoclip` (or `:lua require('telescope').extensions.neoclip['<reg>']()` over `:Telescope neoclip <reg>`) for keybindings since it will properly load `telescope` before calling the extension.
* If you don't want to store pure whitespace yanks you could specify a filter as:
  ```lua
  local function is_whitespace(line)
    return vim.fn.match(line, [[^\s*$]]) ~= -1
  end

  local function all(tbl, check)
    for _, entry in ipairs(tbl) do
      if not check(entry) then
        return false
      end
    end
    return true
  end
  
  require('neoclip').setup{
    ...
    filter = function(data)
      return not all(data.event.regcontents, is_whitespace)
    end,
    ...
  }
  ```

## Troubleshooting
* For some plugin managers it seems necessary to do
  ```
  :lua require('telescope').load_extension('neoclip')
  ```
  before being able to call `:Telescope neoclip` (packer does not seem to need this).
  However, `:lua require('telescope').extensions.neoclip.default()` seems to work without having to load.
  It also seems that calling through `lua` seems necessary to play well with the (optional) persistent history if you're using [`vim-plug`](https://github.com/junegunn/vim-plug), see discussion [here](https://github.com/AckslD/nvim-neoclip.lua/issues/32) for details.
  If you find out what is causing this, I'd be very happy to know :)
* If using [`packer`](https://github.com/wbthomason/packer.nvim), don't forget to `PackerCompile` after adding the plugin.

## Thanks
* Thanks @cdown for the inspiration with [`clipmenu`](https://github.com/cdown/clipmenu).
* Thanks @fdschmidt93 for help understanding some [`telescope`](https://github.com/nvim-telescope/telescope.nvim) concepts.
* Thanks @ibhagwan for providing the code example to support [`fzf-lua`](https://github.com/ibhagwan/fzf-lua).
* Thanks @kkharji for all the great help getting the persistent storage with [`sqlite.lua`](https://github.com/kkharji/sqlite.lua) working.

## Screenshots
### `preview = true` and `content_spec_column = false`
![preview](https://user-images.githubusercontent.com/23341710/140090515-83a08f0f-85f9-4278-bcbe-48e4d8442ace.png)

### `preview = false` and `content_spec_column = true`
![content_spec_column](https://user-images.githubusercontent.com/23341710/140090472-3271affa-7efd-40bd-9d20-562b2074b261.png)

### `preview = false` and `content_spec_column = false`
![clean](https://user-images.githubusercontent.com/23341710/140090327-30bfff28-83ff-4695-82b8-8d4abfd68546.png)
