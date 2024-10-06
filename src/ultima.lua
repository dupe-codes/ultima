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

local argparse = require "argparse"
local json = require "dkjson"
local lfs = require "lfs"

local constants = require "utils.constants"
local file_utils = require "utils.files"
local formatters = require "utils.formatters"
local functions = require "utils.functions"
local lock_files = require "lock_files"
local template_engine = require "templates.engine"

local PANDOC_CMD_FMT = "pandoc -t html --lua-filter=%s %s"
local LOCK_FILE = lock_files.load(constants.LOCK_FILE)

-- START: parse arguments and set parameters as globals

local parser = argparse("ultima", "the ultimate static site generator")
parser:flag("-f --force", "Force write rendered files")
parser:option("-e --env", "The compilation environment", "dev")
local args = parser:parse()

local FORCE_WRITE = args.force or false
local CONFIG = require("config").load_config(args.env)

-- END

local function get_template_path(tmpl_name)
    return CONFIG.templates.dir .. "/" .. tmpl_name
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

        local dir_index_path = CONFIG.generator.root_dir
            .. "/"
            .. output_path
            .. "index.html"

        local rendered_content = template_engine.compile_template_file(
            get_template_path(CONFIG.templates.post),
            {
                config = CONFIG,
                title = output_file,
                content = pandoc_output,
                directory = dir_index_path,
                metadata = metadata,
            }
        )

        local templatized_output = template_engine.compile_template_file(
            get_template_path(CONFIG.templates.default),
            {
                config = CONFIG,
                content = rendered_content,
                metadata = metadata,
            }
        )

        local output_file_path = output_path .. output_file
        local file_changed, checksum = lock_files.file_content_changed(
            LOCK_FILE,
            source_path,
            pandoc_output
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
        elseif FORCE_WRITE then
            file_utils.write_file(output_file_path, templatized_output)
            print("Force wrote unchanged file at " .. output_file_path)
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

        if metadata.enable_discussion then
            -- TODO: check if discussion link already exists in lock file; if not,
            --       create a new discussion via the github API and write it to the
            --       lock file data
        end

        metadata.file_size = file_data.file_size
        metadata.updated_at = file_data.last_modified_ts
        return {
            link = formatters.generate_absolute_path(
                CONFIG,
                output_path .. output_file
            ),
            file_type = file_utils.FileType.FILE,
            display_name = output_file,
            metadata = metadata,
        }
    else
        error("Failed to render file " .. source_path)
    end
end

local function sort_file_links(a, b)
    local file_type_priority = {
        [file_utils.FileType.DIRECTORY] = 1,
        [file_utils.FileType.RSS] = 2,
        [file_utils.FileType.FILE] = 3,
    }

    local a_priority = file_type_priority[a.file_type] or 3
    local b_priority = file_type_priority[b.file_type] or 3

    if a_priority ~= b_priority then
        return a_priority < b_priority
    else
        return a.display_name < b.display_name
    end
end

local function get_default_icon(file_type)
    if file_type == file_utils.FileType.DIRECTORY then
        return "mi-folder"
    elseif file_type == file_utils.FileType.FILE then
        return "mi-document"
    else
        return "mi-inbox"
    end
end

local function write_index_file(file_path, links, parent_dir, all_links)
    local stripped_path =
        formatters.strip_output_dir(file_path, CONFIG.generator.output_dir)
    local current_dir_path = stripped_path:match "(.*/)[^/]+$" or ""
    current_dir_path = CONFIG.main.site_name .. "/" .. current_dir_path

    if parent_dir then
        table.insert(links, 1, {
            link = formatters.generate_absolute_path(
                CONFIG,
                parent_dir .. "index.html"
            ),
            file_type = file_utils.FileType.DIRECTORY,
            display_name = "..",
            metadata = {},
        })
    else
        -- if there is no parent dir, we are at the site root; include
        -- a link to the to-be-generated feed.xml file
        table.insert(links, {
            link = formatters.generate_absolute_path(CONFIG, "feed.xml"),
            file_type = file_utils.FileType.RSS,
            display_name = "feed.xml",
            metadata = {},
        })
    end

    table.sort(links, sort_file_links)

    local index_page = template_engine.compile_template_file(
        get_template_path(CONFIG.templates.index_page),
        {
            config = CONFIG,
            dir_name = current_dir_path,
            links = links,
            ipairs = ipairs,
            FileType = file_utils.FileType,
            get_default_icon = get_default_icon,
            is_site_root = not parent_dir,
            all_links = json.encode(all_links),
        }
    )

    file_utils.write_file(
        file_path,
        template_engine.compile_template_file(
            get_template_path(CONFIG.templates.default),
            { config = CONFIG, content = index_page }
        )
    )
end

local function render_content_dir(output_path, content, parent_dir)
    -- TODO: expose file icon and display name as properties
    --       in post frontmatter configs
    local content_metadata = {}
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
            local subdir_content = render_content_dir(
                output_path .. dir .. "/",
                src_files,
                output_path
            )
            -- copy all metadata from subdir to metadata table
            table.move(
                subdir_content,
                1,
                #subdir_content,
                #content_metadata + 1,
                content_metadata
            )

            local subdir_index_file = dir .. "/index.html"
            -- TODO: support directories in lock file, only change
            --       updated_at if any file in a directory has changed; or, maybe
            --       just set subdir updated_at to most recent updated_at of all
            --       files within it
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

    table.move(links, 1, #links, #content_metadata + 1, content_metadata)
    local index_file_path = output_path .. "index.html"

    local all_file_links = functions.map(
        functions.filter(content_metadata, function(entry)
            return entry.file_type ~= file_utils.FileType.DIRECTORY
        end),
        function(entry)
            return entry.link
        end
    )
    write_index_file(index_file_path, links, parent_dir, all_file_links)
    return content_metadata
end

local function compile_static_assets(static_dir, output_dir)
    -- for now, just transfer static dir as is to output_dir
    print "Copying static assets to build directory"
    file_utils.copy_directory(static_dir, output_dir)
end

local function generate_xml_feed(output_dir, content_data)
    local feed_items = {}
    for _, content in ipairs(content_data) do
        if
            content.file_type == file_utils.FileType.FILE
            and content.metadata.publish
        then
            table.insert(feed_items, {
                title = content.display_name,
                publish_date = formatters.iso8601_str_to_format(
                    content.metadata.updated_at,
                    "%a, %d %b %Y %H:%M:%S"
                ),
                link = content.link,
                description = content.metadata.description or "a cool post",
            })
        end
    end

    local feed = template_engine.compile_template_file(
        get_template_path(CONFIG.templates.feed),
        {
            config = CONFIG,
            ipairs = ipairs,
            feed = feed_items,
        }
    )
    file_utils.write_file(output_dir .. "/feed.xml", feed)
end

local function main()
    local content_root = find_content(CONFIG.generator.input_dir)

    file_utils.make_dir_if_not_exists(CONFIG.generator.output_dir)
    local output_path = CONFIG.generator.output_dir .. "/"
    local content_data = render_content_dir(output_path, content_root)

    lock_files.write(LOCK_FILE, constants.LOCK_FILE)
    compile_static_assets(
        CONFIG.generator.static_dir,
        CONFIG.generator.output_dir .. "/static"
    )

    generate_xml_feed(CONFIG.generator.output_dir, content_data)
end

main()
