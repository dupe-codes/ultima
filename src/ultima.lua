#!/usr/bin/env lua

local inspect = require "inspect"
local lfs = require "lfs"
local toml = require "toml"

local succeeded, config = pcall(toml.decodeFromFile, "./src/config.toml")

if not succeeded then
    print("Failed to load config! Error: " .. inspect(config))
    return 1
end

local find_content = function(content_dir)
    local result = {}
    for file in lfs.dir(content_dir) do
        if file ~= "." and file ~= ".." then
            local full_path = content_dir .. "/" .. file
            local attributes = lfs.attributes(full_path)
            if attributes.mode == "directory" then
                print "directories not yet supported"
            else
                print("Found file " .. full_path)
                table.insert(
                    result,
                    { full_path = full_path, file_name = file }
                )
            end
        end
    end
    return result
end

local render_content = function(source_path, file_name, output_dir)
    local output_file = file_name:gsub("%.md$", ".html")
    local pandoc_cmd = string.format(
        "pandoc %s -o %s",
        source_path,
        output_dir .. "/" .. output_file
    )
    local _ = os.execute(pandoc_cmd)
end

local main = function()
    local content = find_content(config.generator.input_dir)

    local output_dir_exists = lfs.attributes(config.generator.output_dir)
    if not output_dir_exists then
        local success, err = lfs.mkdir(config.generator.output_dir)
        if not success then
            print("failed to make output dir: " .. inspect(err))
        end
    end

    for _, src in pairs(content) do
        render_content(
            src.full_path,
            src.file_name,
            config.generator.output_dir
        )
    end
end

main()
