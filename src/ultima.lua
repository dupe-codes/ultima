#!/usr/bin/env lua

local inspect = require "inspect"
local lfs = require "lfs"
local toml = require "toml"

local decode_succeeded, config = pcall(toml.decodeFromFile, "config.toml")

if not decode_succeeded then
    print("Failed to load config! Error: " .. inspect(config))
    return 1
end

local make_dir_if_not_exists = function(dir)
    local output_dir_exists = lfs.attributes(dir)
    if not output_dir_exists then
        local success, err = lfs.mkdir(dir)
        if not success then
            print("failed to make directory " .. dir .. ": " .. inspect(err))
        end
    end
end

local function find_content(content_dir)
    local result = {
        [""] = {},
    }
    for file in lfs.dir(content_dir) do
        if file ~= "." and file ~= ".." then
            local full_path = content_dir .. "/" .. file
            local attributes = lfs.attributes(full_path)
            if attributes.mode == "directory" then
                result[file] = find_content(full_path)
            else
                table.insert(
                    result[""],
                    { source_path = full_path, file_name = file }
                )
            end
        end
    end
    return result
end

local render_file = function(output_path, source_path, file_name)
    local output_file = file_name:gsub("%.md$", ".html")

    -- TODO: write to and capture stdout, write to file using
    --       lua
    local pandoc_cmd = string.format(
        "pandoc -t html %s -o %s",
        source_path,
        output_path .. output_file
    )

    local succeeded = os.execute(pandoc_cmd)
    if succeeded then
        print("Wrote rendered file at " .. output_path .. output_file)
    else
        print("Failed to render file " .. source_path)
    end

    return output_file
end

local write_index_file = function(file_path, links)
    -- TODO: replace with a template once the template engine is
    --       implemented
    local file = io.open(file_path, "w")
    if not file then
        error("Could not open file: " .. file_path)
    end

    file:write "<!DOCTYPE html>\n<html>\n<head>\n<title>Index</title>\n</head>\n<body>\n"
    file:write "<h1>Index of Files</h1>\n<ul>\n"

    for _, link in ipairs(links) do
        file:write(string.format('<li><a href="%s">%s</a></li>\n', link, link))
    end
    file:write "</ul>\n</body>\n</html>"
    file:close()
end

local function render_content_dir(output_path, content)
    local links = {}
    for dir, src_files in pairs(content) do
        if dir == "" then
            -- list of files in the current directory to render
            for _, file in pairs(src_files) do
                local output_file =
                    render_file(output_path, file.source_path, file.file_name)
                table.insert(links, output_file)
            end
        else
            -- directory to recursively render
            local nested_dir = output_path .. dir .. "/"
            make_dir_if_not_exists(nested_dir)
            render_content_dir(output_path .. dir .. "/", src_files)
            table.insert(links, dir .. "/index.html")
        end
    end
    local index_file_path = output_path .. "/index.html"
    write_index_file(index_file_path, links)
end

local main = function()
    local content_root = find_content(config.generator.input_dir)
    make_dir_if_not_exists(config.generator.output_dir)
    local output_path = config.generator.output_dir .. "/"
    render_content_dir(output_path, content_root)
end

main()
