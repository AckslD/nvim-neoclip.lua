local settings = require('neoclip.settings').get()

local M = {}

local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
    print "Couldn't find sqlite.lua. Cannot use persistent history"
    return nil
end

local function dirname(str)
    return string.match(str, '(.*[/\\])')
end

local function make_db_dir(db_path)
    os.execute('mkdir -p ' .. dirname(db_path))
end

local function get_tbl()
    local db_path = settings.db_path
    make_db_dir(db_path)
    local db = sqlite.new(db_path)
    db:open()
    local tbl = db:tbl("neoclip", {
        regtype = "text",
        contents = "luatable",
        filetype = "text",
    })

    return tbl
end

M.tbl = get_tbl()

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
    local success, entries = pcall(M.tbl.get, M.tbl, query)
    if success then
        return entries
    else
        print("Couldn't load history since:", entries)
        return {}
    end
end

M.update = function(storage)
    local success, msg = pcall(M.tbl.remove, M.tbl)
    if not success then
        print("Couldn't remove clear database since:", msg)
    end
    success, msg = pcall(M.tbl.insert, M.tbl, storage)
    if not success then
        print("Couldn't insert in database since:", msg)
    end
end

return M
