require("utils")

DEFAULT_SAVEDATA = {
    page_id = 1,
    bookmarks = {},
}

SAVE_FILE = "save.lua"

function load_savedata()
    Savedata = table.load(SAVE_FILE)
    if not Savedata then
        Savedata = DEFAULT_SAVEDATA
        table.save(Savedata, SAVE_FILE)
    end
end

function save_savedata() 
    table.save(Savedata, SAVE_FILE)
end

load_savedata()