#!/usr/bin/env lua

local inspect = require "inspect"
local lfs = require "lfs"

local config = require("config").load_config()
local template_engine = require "templates.engine"

local FileType = {
    DIRECTORY = 0,
    FILE = 1,
}

local function strip_output_dir(file_path)
    return file_path:gsub("^" .. config.generator.output_dir .. "/", "")
end

local function get_template_path(tmpl_name)
    return config.templates.dir .. "/" .. tmpl_name
end

local function write_file(output_file_path, output)
    local file = io.open(output_file_path, "w")
    if not file then
        error("Could not open file: " .. output_file_path)
    end
    file:write(output)
    file:close()
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

local function render_file(output_path, source_path, file_name)
    local output_file = file_name:gsub("%.md$", ".html")
    local pandoc_cmd = string.format("pandoc -t html %s", source_path)

    local pipe = io.popen(pandoc_cmd, "r")
    if not pipe then
        error "Failed to open pipe to run pandoc"
    end

    local pandoc_output = pipe:read "*a"
    local succeeded, exit_type, code = pipe:close()

    if succeeded and exit_type == "exit" and code == 0 then
        local dir_index_path = config.generator.root_dir
            .. "/"
            .. output_path
            .. "index.html"
        local rendered_content = template_engine.compile_template_file(
            get_template_path(config.templates.post),
            {
                content = pandoc_output,
                directory = dir_index_path,
            }
        )

        local templatized_output = template_engine.compile_template_file(
            get_template_path(config.templates.default),
            {
                config = config,
                content = rendered_content,
            }
        )
        local output_file_path = output_path .. output_file
        write_file(output_file_path, templatized_output)
        print("Wrote rendered file at " .. output_file_path)
    else
        print("Failed to render file " .. source_path)
    end

    return output_file
end

local function sort_file_links(a, b)
    local a_is_dir = a.file_type == FileType.DIRECTORY
    local b_is_dir = b.file_type == FileType.DIRECTORY

    if a_is_dir ~= b_is_dir then
        return a_is_dir
    else
        return a.display_name < b.display_name
    end
end

local function write_index_file(file_path, links, parent_dir)
    -- get directory name
    -- TODO: break full path down and display as clickable breadcrumbs for
    --      index file title
    --      e.g. blog > posts > personal
    --      that makes navigation easier
    local stripped_path = strip_output_dir(file_path)
    local current_dir = stripped_path:match "([^/]+)/[^/]+$"
    if not current_dir then
        current_dir = config.main.site_name
    end

    if parent_dir then
        table.insert(links, 1, {
            link = config.generator.root_dir
                .. "/"
                .. parent_dir
                .. "/index.html",
            file_type = FileType.DIRECTORY,
            display_name = "..",
        })
    end

    table.sort(links, sort_file_links)

    local index_page = template_engine.compile_template_file(
        get_template_path(config.templates.index_page),
        {
            dir_name = current_dir,
            links = links,
            ipairs = ipairs,
            FileType = FileType,
        }
    )

    write_file(
        file_path,
        template_engine.compile_template_file(
            get_template_path(config.templates.default),
            { config = config, content = index_page }
        )
    )
end

local function render_content_dir(output_path, content, parent_dir)
    -- TODO: expose file icon and display name as properties
    --       in post frontmatter configs
    local links = {}
    for dir, src_files in pairs(content) do
        if dir == "" then
            -- list of files in the current directory to render
            for _, file in pairs(src_files) do
                local output_file =
                    render_file(output_path, file.source_path, file.file_name)
                table.insert(links, {
                    link = output_file,
                    file_type = FileType.FILE,
                    display_name = output_file,
                })
            end
        else
            -- directory to recursively render
            local nested_dir = output_path .. dir .. "/"
            make_dir_if_not_exists(nested_dir)
            render_content_dir(
                output_path .. dir .. "/",
                src_files,
                output_path
            )
            table.insert(links, {
                link = dir .. "/index.html",
                file_type = FileType.DIRECTORY,
                display_name = dir,
            })
        end
    end
    local index_file_path = output_path .. "index.html"
    write_index_file(index_file_path, links, parent_dir)
end

local function copy_file(source, destination)
    local source_file = io.open(source, "rb")
    if not source_file then
        error("Could not open source file: " .. source)
    end

    local content = source_file:read "*a"
    source_file:close()

    local destination_file = io.open(destination, "wb")
    if not destination_file then
        error("Could not open destination file: " .. destination)
    end
    destination_file:write(content)
    destination_file:close()
end

local function copy_directory(src_dir, output_dir)
    lfs.mkdir(output_dir)
    for file in lfs.dir(src_dir) do
        if file ~= "." and file ~= ".." then
            local src_path = src_dir .. "/" .. file
            local target_path = output_dir .. "/" .. file

            local mode = lfs.attributes(src_path, "mode")
            if mode == "file" then
                copy_file(src_path, target_path)
            elseif mode == "directory" then
                copy_directory(src_path, target_path)
            end
        end
    end
end

local function compile_static_assets(static_dir, output_dir)
    -- for now, just transfer static dir as is to output_dir
    print "Copying static assets to build directory"
    copy_directory(static_dir, output_dir)
end

local function main()
    local content_root = find_content(config.generator.input_dir)
    make_dir_if_not_exists(config.generator.output_dir)
    local output_path = config.generator.output_dir .. "/"
    render_content_dir(output_path, content_root)
    compile_static_assets(
        config.generator.static_dir,
        config.generator.output_dir .. "/static"
    )
end

main()
