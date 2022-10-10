local handlers = require('neoclip.handlers')
local settings = require('neoclip.settings').get()
local picker_utils = require('neoclip.picker_utils')

-- This needs to be filled dynamically with each call (#80)
local _storage = nil

local function get_idx(item)
    return tonumber(item:match("^%d+%."))
end

local function parse_entry(entry_str)
  local idx = get_idx(entry_str)
  assert(_storage and _storage[idx])
  return _storage[idx]
end

local function get_set_register_handler(register_names)
    return function(selected, _)
        handlers.set_registers(register_names, parse_entry(selected[1]))
    end
end

local function get_paste_handler(register_names, op)
    return function(selected, _)
        local entry = parse_entry(selected[1])
        if settings.on_paste.set_reg then
            handlers.set_registers(register_names, entry)
        end
        handlers.paste(entry, op)
    end
end

local function get_custom_action_handler(register_names, action)
    return function(selected, _)
        local entry = parse_entry(selected[1])
        action({
            register_names=register_names,
            entry = {
                contents=entry.contents,
                filetype=entry.filetype,
                regtype=entry.regtype,
            }
        })
    end
end

local function make_actions(register_names)
    local keys = settings.keys['fzf']
    local actions = {
        [keys.select] = get_set_register_handler(register_names),
        [keys.paste] = get_paste_handler(register_names, 'p'),
        [keys.paste_behind] = get_paste_handler(register_names, 'P'),
    }
    if keys.custom ~= nil then
        for key, action in pairs(keys.custom) do
            actions[key] = get_custom_action_handler(register_names, action)
        end
    end
    for key, _ in pairs(actions) do
        if not key then
            actions[key] = nil
        end
    end
    return actions
end

-- Previewer class inherits from base previewer
-- the only required method is 'populate_preview_buf'
local Previewer = require('fzf-lua.previewer.builtin').base:extend()

function Previewer:new(o, opts, fzf_win)
  self.super.new(self, o, opts, fzf_win)
  setmetatable(self, Previewer)
  return self
end

-- remove line numbering from preview buffer, comment
-- entrire function or change 'number=true' to revert
function Previewer:gen_winopts()
  local winopts = {
    wrap    = self.win.preview_wrap,
    number  = false
  }
  return vim.tbl_extend("keep", winopts, self.winopts)
end

function Previewer:populate_preview_buf(entry_str)
  local entry = parse_entry(entry_str)
  vim.api.nvim_buf_set_lines(self.preview_bufnr, 0, -1, false, entry.contents)
  vim.api.nvim_buf_set_option(self.preview_bufnr, 'filetype', entry.filetype)
  self.win:update_scrollbar()
end

-- this function feeds elements into fzf
-- each call to `fzf_cb()` equals one line
-- `fzf_cb(nil)` closes the pipe and marks EOL to fzf
local fn = function(fzf_cb)
    -- reload current _storage local var, without
    -- this call yanks are never refreshed (#80)
    _storage = require('neoclip.storage').get().yanks
    for i, e in ipairs(_storage) do
        fzf_cb(("%d. %s"):format(i, table.concat(e.contents, '\\n')))
    end
    fzf_cb(nil)
end

local function neoclip(register_names)
    if register_names == nil then
        register_names = settings.default_register
    end
    if type(register_names) == 'string' then
        register_names = {register_names}
    end
    local actions = make_actions(register_names)
    require('fzf-lua').fzf_exec(fn, {
      prompt = settings.prompt or 'Prompt❯ ',
      previewer = Previewer,
      actions = actions,
      fzf_opts = {
        ["--header"] = vim.fn.shellescape(picker_utils.make_prompt_title(register_names)),
        ["--delimiter"] = [[\\.]],
        -- comment `--nth` if you want to enable
        -- fuzzy matching the index number
        ["--with-nth"] = '2..',
      },
    })
end

return neoclip
