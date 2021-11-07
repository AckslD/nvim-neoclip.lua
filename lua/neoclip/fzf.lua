local handlers = require('neoclip.handlers')
local storage = require('neoclip.storage').get()
local settings = require('neoclip.settings').get()
local picker_utils = require('neoclip.picker_utils')

local function get_idx(item)
    return tonumber(item:match("^[(%d+)]"))
end

local function get_set_register_handler(register_names)
    return function(selected, _)
        local idx = get_idx(selected[1])
        handlers.set_registers(register_names, storage[idx])
    end
end

local function get_paste_handler(register_names, op)
    return function(selected, _)
        local idx = get_idx(selected[1])
        local entry = storage[idx]
        if settings.on_paste.set_reg then
            handlers.set_registers(register_names, entry)
        end
        handlers.paste(entry, op)
    end
end

local function get_custom_action_handler(register_names, action)
    return function(selected, _)
        local idx = get_idx(selected[1])
        local entry = storage[idx]
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
        if key == nil then
            actions[key] = nil
        end
    end
    return actions
end

-- this function defines the preview, whatever is returned
-- from this function is displayed in the fzf preview window
local prev_act = require("fzf.actions").action(function (items)
    local idx = get_idx(items[1])
    return table.concat(storage[idx].contents, '\n')
end)

-- this function feeds elements into fzf
-- each call to `fzf_cb()` equals one line
-- `fzf_cb(nil)` closes the pipe and marks EOL to fzf
local fn = function(fzf_cb)
    local i = 1
    for _, e in ipairs(storage) do
        fzf_cb(("%d. %s"):format(i, table.concat(e.contents, '\\n')))
        i = i + 1
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
    coroutine.wrap(function()
        local selected = require('fzf-lua').fzf({
            prompt = picker_utils.make_prompt_title(register_names),
            preview = prev_act,
            actions = actions,
            fzf_opts = {
                ["--delimiter"] = '.',
                -- comment `--nth` if you want to enable
                -- fuzzy matching the index number
                ["--nth"] = '3..',
            },
        }, fn)
        require('fzf-lua').actions.act(actions, selected, {})
    end)()
end

return neoclip
