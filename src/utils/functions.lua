local M = {}

function M.map(tbl, func)
    local new_tbl = {}
    for i, v in ipairs(tbl) do
        new_tbl[i] = func(v)
    end
    return new_tbl
end

function M.filter(tbl, func)
    local new_tbl = {}
    for _, v in ipairs(tbl) do
        if func(v) then
            table.insert(new_tbl, v)
        end
    end
    return new_tbl
end

return M
