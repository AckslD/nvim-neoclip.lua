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
You can then select an entry in the history using [`telescope`](https://github.com/nvim-telescope/telescope.nvim) which then gets populated in a register of your choice.

That's it!

Oh, one more thing, you can define an optional filter if you don't want some things to be saved.

![neoclip](https://user-images.githubusercontent.com/23341710/129557093-7724e7eb-7427-4c53-aa98-55e624843589.png)


## Installation
```lua
use {
    "AckslD/nvim-neoclip.lua",
    config = function()
        require('neoclip').setup()
    end,
}
```
When `require('neoclip').setup()` is called, only the autocommand (for `TextYankPost` event) is setup to save yanked things. This means that `telescope` is not required at this point if you lazy load it.

## Configuration
You can configure `neoclip` by passing a table to `setup`. The following are the defaults and the keys are explained below:
```lua
use {
    "AckslD/nvim-neoclip.lua",
    config = function()
        require('neoclip').setup({
            history = 1000,
            filter = nil,
        })
    end,
}
```
* `history` (optional): The max number of entries to store (default 1000).
* `filter` (optional): A function to filter what entries to store (default all are stored).
  This function filter should return `true` (include the yanked entry) or `false` (don't include it) based on a table as the only argument, which has the following keys:
  * `event`: The event from `TextYankPost` (see `:help TextYankPost` for which keys it contains).
  * `filetype`: The filetype of the buffer where the yank happened.
  * `buffer_name`: The name of the buffer where the yank happened.

## Usage
Yank all you want and then do:
```vim
:Telescope neoclip
```
which will show you a history of the yanks that happened in the current session.
If you pick one this will then replace the current `"` (unnamed) register.

If you want to replace another register with an entry from the history you can do for example:
```vim
:Telescope neoclip a
```
which will replace register `a`.
The register `[0-9a-z]` and `default` (`"`) are supported.

### Start/stop
If you temporarily don't want `neoclip` to record anything you can use the following calls:
* `:lua require('neoclip').start()`
* `:lua require('neoclip').stop()`
* `:lua require('neoclip').toggle()`

## Tips
* If you lazy load [`telescope`](https://github.com/nvim-telescope/telescope.nvim) with [`packer`](https://github.com/wbthomason/packer.nvim) with for example the key `module = telescope`, then it's better to use e.g. `:lua require('telescope').extensions.neoclip.default()` than `:Telescope neoclip` (or `:lua require('telescope').extensions.neoclip['<reg>']()` over `:Telescope neoclip <reg>`) for keybindings since it will properly load `telescope` before calling the extension.

## Troubleshooting
* For some plugin managers it seems necessary to do
  ```
  :lua require('telescope').load_extension('neoclip')
  ```
  before being able to call `:Telescope neoclip` (packer does not seem to need this).
  However, `:lua require('telescope').extensions.neoclip.default()` seems to work without having to load.
* If using [`packer`](https://github.com/wbthomason/packer.nvim), don't forget to `PackerCompile` after adding the plugin.

## Thanks
* Thanks @cdown for the inspiration with [`clipmenu`](https://github.com/cdown/clipmenu).
* Thanks @fdschmidt93 for help understanding some [`telescope`](https://github.com/nvim-telescope/telescope.nvim) concepts.
