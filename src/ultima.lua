#!/usr/bin/env lua

-- TODO LIST:
--  1. figure out how to support links between posts within posts
--  2. support static assets (images, videos, etc.) embedded in posts
--  3. style posts
--  4. auto generate xml feed with "publish: true" front matter tag
--     on posts, copy to build directory
--  5. render code snippets with syntax highlighting extracted from
--     neovim
--  6. ...

local inspect = require "inspect"
local json = require "dkjson"
local lfs = require "lfs"

local config = require("config").load_config()
local constants = require "utils.constants"
local file_utils = require "utils.files"
local formatters = require "utils.formatters"
local lock_files = require "lock_files"
local template_engine = require "templates.engine"

local PANDOC_CMD_FMT = "pandoc -t html --lua-filter=%s %s"
local LOCK_FILE = lock_files.load(constants.LOCK_FILE)

local function get_template_path(tmpl_name)
    return config.templates.dir .. "/" .. tmpl_name
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

local function read_metadata(source_path)
    local metadata_file = source_path .. ".meta.json"

    local mode = lfs.attributes(metadata_file, "mode")
    if mode ~= "file" then
        return {}
    end

    local metadata_content = file_utils.read_file(metadata_file)
    local metadata = json.decode(metadata_content)
    os.remove(metadata_file)
    return metadata
end

local function render_file(output_path, source_path, file_name)
    local output_file = file_name:gsub("%.md$", ".html")
    local pandoc_cmd = string.format(
        PANDOC_CMD_FMT,
        "src/pandoc/metadata_extractor.lua",
        formatters.shell_escape(source_path)
    )

    local pipe = io.popen(pandoc_cmd, "r")
    if not pipe then
        error "Failed to open pipe to run pandoc"
    end

    local pandoc_output = pipe:read "*a"
    local succeeded, exit_type, code = pipe:close()

    if succeeded and exit_type == "exit" and code == 0 then
        local metadata = read_metadata(source_path)

        local dir_index_path = config.generator.root_dir
            .. "/"
            .. output_path
            .. "index.html"
        local rendered_content = template_engine.compile_template_file(
            get_template_path(config.templates.post),
            {
                config = config,
                content = pandoc_output,
                directory = dir_index_path,
                metadata = metadata,
            }
        )

        local templatized_output = template_engine.compile_template_file(
            get_template_path(config.templates.default),
            {
                config = config,
                content = rendered_content,
                metadata = metadata,
            }
        )

        local output_file_path = output_path .. output_file
        local file_changed, checksum = lock_files.file_content_changed(
            LOCK_FILE,
            source_path,
            rendered_content
        )
        if file_changed then
            file_utils.write_file(output_file_path, templatized_output)
            print("Wrote rendered file at " .. output_file_path)

            local file_size = formatters.format_bytes(
                lfs.attributes(output_file_path, "size")
            )
            local modified_ts = formatters.unix_ts_to_iso8601(
                lfs.attributes(output_file_path, "modification")
            )
            lock_files.set_file_data(LOCK_FILE, source_path, {
                last_modified_ts = modified_ts,
                file_size = file_size,
                checksum = checksum,
            })
        else
            print(
                string.format("%s content unchanged; skipping...", source_path)
            )
        end

        local file_data = lock_files.get_file_data(LOCK_FILE, source_path)
        if not file_data then
            error(
                string.format(
                    "Missing file data for %s in lock file",
                    source_path
                )
            )
        end

        metadata.file_size = file_data.file_size
        metadata.updated_at = file_data.last_modified_ts
        return {
            link = output_file,
            file_type = file_utils.FileType.FILE,
            display_name = output_file,
            metadata = metadata,
        }
    else
        error("Failed to render file " .. source_path)
    end
end

local function sort_file_links(a, b)
    local a_is_dir = a.file_type == file_utils.FileType.DIRECTORY
    local b_is_dir = b.file_type == file_utils.FileType.DIRECTORY

    if a_is_dir ~= b_is_dir then
        return a_is_dir
    else
        return a.display_name < b.display_name
    end
end

local function write_index_file(file_path, links, parent_dir)
    local stripped_path =
        formatters.strip_output_dir(file_path, config.generator.output_dir)
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
            file_type = file_utils.FileType.DIRECTORY,
            display_name = "..",
            metadata = {},
        })
    end

    table.sort(links, sort_file_links)

    local index_page = template_engine.compile_template_file(
        get_template_path(config.templates.index_page),
        {
            config = config,
            dir_name = current_dir,
            links = links,
            ipairs = ipairs,
            FileType = file_utils.FileType,
        }
    )

    file_utils.write_file(
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
            -- TODO: run in parallel
            for _, file in pairs(src_files) do
                local output_data =
                    render_file(output_path, file.source_path, file.file_name)
                table.insert(links, output_data)
            end
        else
            -- directory to recursively render
            local nested_dir = output_path .. dir .. "/"
            file_utils.make_dir_if_not_exists(nested_dir)
            render_content_dir(
                output_path .. dir .. "/",
                src_files,
                output_path
            )
            local subdir_index_file = dir .. "/index.html"
            local subdir_metadata = {
                updated_at = formatters.unix_ts_to_iso8601(
                    lfs.attributes(subdir_index_file, "modification")
                ),
            }
            table.insert(links, {
                link = dir .. "/index.html",
                file_type = file_utils.FileType.DIRECTORY,
                display_name = dir .. "/",
                metadata = subdir_metadata,
            })
        end
    end
    local index_file_path = output_path .. "index.html"
    write_index_file(index_file_path, links, parent_dir)
end

local function compile_static_assets(static_dir, output_dir)
    -- for now, just transfer static dir as is to output_dir
    print "Copying static assets to build directory"
    file_utils.copy_directory(static_dir, output_dir)
end

local function generate_xml_feed(src_dir, output_dir)
    -- TODO: dynamically generate this feed file direct in
    --       the output dir from posts with publish = true
    file_utils.copy_file(
        src_dir .. "/" .. "feed.xml",
        output_dir .. "/feed.xml"
    )
end

local function main()
    local content_root = find_content(config.generator.input_dir)
    file_utils.make_dir_if_not_exists(config.generator.output_dir)
    local output_path = config.generator.output_dir .. "/"
    render_content_dir(output_path, content_root)
    lock_files.write(LOCK_FILE, constants.LOCK_FILE)
    compile_static_assets(
        config.generator.static_dir,
        config.generator.output_dir .. "/static"
    )
    generate_xml_feed("src", config.generator.output_dir)
end

main()
