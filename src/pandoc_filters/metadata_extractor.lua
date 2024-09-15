local json = require "pandoc.json"

local function meta_to_plain(value)
    local value_type = pandoc.utils.type(value)
    if value_type == "Meta" or value_type == "table" then
        local result = {}
        for k, v in pairs(value) do
            result[k] = meta_to_plain(v)
        end
        return result
    elseif value_type == "List" then
        local result = {}
        for i, v in ipairs(value) do
            result[i] = meta_to_plain(v)
        end
        return result
    elseif value_type == "Inlines" then
        -- TODO: detect & parse date types in YYYY-MM-DD format
        return pandoc.utils.stringify(value)
    elseif value_type == "boolean" then
        return value
    else
        return pandoc.utils.stringify(value)
    end
end

local function Meta(meta)
    -- write front matter metadata to temp file for
    -- reading later in the rendering pipeline
    -- TODO: avoid writing out metadata temp files
    --       for files that don't have frontmatter blocks
    local metadata = json.encode(meta_to_plain(meta))

    local source_path = PANDOC_STATE.input_files[1]
    local metadata_file = source_path .. ".meta.json"
    local file = io.open(metadata_file, "w")

    if not file then
        error "Failed to open temporary file for metadata writing!"
    end

    file:write(metadata)
    file:close()

    return meta
end

return {
    { Meta = Meta },
}
