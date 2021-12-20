local settings = require('neoclip.settings').get()
local warn = require('neoclip.warn').warn

local M = {}

local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
    warn("Couldn't find sqlite.lua. Cannot use persistent history")
    return nil
end

local function dirname(str)
    return string.match(str, '(.*[/\\])')
end

local function make_db_dir(db_path)
    os.execute('mkdir -p ' .. dirname(db_path))
end

local function get_tbl(name)
    local db_path = settings.db_path
    make_db_dir(db_path)
    local db = sqlite.new(db_path)
    db:open()
    local tbl = db:tbl(name, {
        regtype = "text",
        contents = "luatable",
        filetype = "text",
    })

    return tbl
end

M.tables = {
    yanks = get_tbl('neoclip'),
    macros = get_tbl('macros'),
}

local function copy(t)
    local new = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            new[k] = copy(v)
        else
            new[k] = v
        end
    end
    return new
end

M.get = function(query)
    local storage = {}
    for key, tbl in pairs(M.tables) do
        local success, entries = pcall(tbl.get, tbl, query)
        if success then
            storage[key] = entries
            return entries
        else
            warn(string.format("Couldn't load (%s) history since: %s", key, entries))
            return {}
        end
    end
    return storage
end

M.update = function(storage)
    for key, tbl in pairs(M.tables) do
        local success, msg = pcall(tbl.remove, tbl)
        if not success then
            warn(string.format("Couldn't remove clear database since: %s", msg))
            return
        end
        success, msg = pcall(tbl.insert, tbl, storage[key])
        if not success then
            warn(string.format("Couldn't insert in database since: %s", msg))
            return
        end
    end
end

return M
