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

local function run_snippet(snippet)
    local cmd = string.format(
        "nvim --headless -c 'GenerateSnippet %s' -c 'q' 2>&1",
        snippet
    )

    local handle = io.popen(cmd)
    if not handle then
        io.stderr:write "Error: Unable to run Neovim command\n"
        return "<p>Error running snippet</p>"
    end

    local result = handle:read "*all"
    handle:close()
    return "<pre>" .. pandoc.utils.stringify(result) .. "</pre>"
end

local function CodeBlock(block)
    local snippet = block.attributes["snippet"]
    return nil
    --[[
    if snippet then
        local html_output = run_snippet(snippet)
        return pandoc.RawBlock("html", html_output)
    else
        return nil
    end
    ]]
    --
end

-- Process wiki-style links: [[path]] or [[path|display text]]
-- Paths are relative to the site's content root (input_dir)
local function process_wiki_links(text)
    local result = {}
    local last_end = 1

    -- Pattern: [[path]] or [[path|display]]
    for link_start, link_content, link_end in text:gmatch("()%[%[(.-)%]%]()") do
        -- Add text before this link
        if link_start > last_end then
            table.insert(result, pandoc.Str(text:sub(last_end, link_start - 1)))
        end

        -- Parse the link content
        local path, display = link_content:match("^(.-)%|(.+)$")
        if not path then
            path = link_content
            -- Use the last part of the path as display (filename without extension)
            display = path:match("([^/]+)/?$") or path
        end

        -- Ensure path starts with /
        if not path:match("^/") then
            path = "/" .. path
        end

        -- Check if this is a directory link (ends with /)
        if path:match("/$") then
            path = path .. "index.html"
        elseif not path:match("%.html$") and not path:match("%.%w+$") then
            path = path .. ".html"
        end

        -- Create the link
        table.insert(result, pandoc.Link(display, path))
        last_end = link_end
    end

    -- Add remaining text after last link
    if last_end <= #text then
        table.insert(result, pandoc.Str(text:sub(last_end)))
    end

    return result
end

local function Str(el)
    -- Check if this string contains wiki links
    if el.text:match("%[%[.-%]%]") then
        return process_wiki_links(el.text)
    end
    return nil
end

-- Process at Inlines level to handle wiki links that might be split across elements
local function Inlines(inlines)
    -- First, concatenate all text to find wiki links
    local full_text = pandoc.utils.stringify(inlines)
    if not full_text:match("%[%[.-%]%]") then
        return nil
    end

    -- Rebuild the inlines, processing wiki links
    local new_inlines = pandoc.List()
    local i = 1
    while i <= #inlines do
        local el = inlines[i]
        if el.tag == "Str" and el.text:match("%[%[") then
            -- Collect text until we find the closing ]]
            local collected = el.text
            local j = i + 1
            while j <= #inlines and not collected:match("%]%]") do
                collected = collected .. pandoc.utils.stringify(inlines[j])
                j = j + 1
            end

            if collected:match("%[%[.-%]%]") then
                -- Process the wiki links
                local processed = process_wiki_links(collected)
                for _, item in ipairs(processed) do
                    new_inlines:insert(item)
                end
                i = j
            else
                new_inlines:insert(el)
                i = i + 1
            end
        else
            new_inlines:insert(el)
            i = i + 1
        end
    end

    return new_inlines
end

return {
    { Meta = Meta, CodeBlock = CodeBlock, Inlines = Inlines },
}
