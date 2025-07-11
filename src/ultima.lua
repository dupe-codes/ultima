#!/usr/bin/env lua

local argparse = require "argparse"
local date = require "date"
local inspect = require "inspect"
local json = require "dkjson"
local lfs = require "lfs"

local constants = require "utils.constants"
local file_utils = require "utils.files"
local formatters = require "utils.formatters"
local functions = require "utils.functions"
local lock_files = require "lock_files"
local template_engine = require "templates.engine"

local PANDOC_CMD_FMT = "pandoc -t html --lua-filter=%s %s"

-- TODO: set up logging with LuaLogging package

-- START: parse arguments and set parameters as globals

local parser = argparse("ultima", "the ultimate static site generator")
parser
    :argument("site", "Name of the site to build")
    :choices(file_utils.get_all_subdirs_in_target(constants.SITES_DIR))
parser:flag("-f --force", "Force write rendered files")
parser:option("-e --env", "The compilation environment", "dev")
local args = parser:parse()

local ENVIRONMENTS = {
    DEV = "dev",
    PROD = "prod",
}

local FORCE_WRITE = args.force or false
local SITE = args.site
local ENV = args.env
local CONFIG = require("config").load_config(SITE, ENV)
local LOCK_FILE = lock_files.load(CONFIG.generator.lock_file)

-- END

-- START: rendering constants and config types

local CONTENT_TYPE = {
    POST = "post",
    MEDIA = "media",
    GALLERY = "gallery",
}

local DRAFT_METADATA_FIELD = "draft"
local FONT_METADATA_FIELD = "font"
local DEFAULT_RECENTLY_UPDATED_THRESHOLD = 7

-- END

-- START: rendering logic

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

local function get_output_file_name(file_name, metadata)
    if
        not metadata
        or not metadata.content_type
        or metadata.content_type ~= CONTENT_TYPE.MEDIA
    then
        return file_name:gsub("%.md$", ".html")
    else
        -- media file names should be ripped from the static_link metadata
        assert(
            metadata.static_link,
            "Media content type must have static link metadata"
        )
        return metadata.static_link:match "^.+/(.+)$"
    end
end

local function render_post_file(
    source_path,
    output_path,
    output_file,
    pandoc_output,
    metadata
)
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
            generate_absolute_path = formatters.generate_absolute_path,
        }
    )

    local templatized_output = template_engine.compile_template_file(
        get_template_path(CONFIG.templates.default),
        {
            config = CONFIG,
            content = rendered_content,
            metadata = metadata,
            generate_absolute_path = formatters.generate_absolute_path,
        }
    )

    local output_file_path = output_path .. output_file
    local file_changed, checksum =
        lock_files.file_content_changed(LOCK_FILE, source_path, pandoc_output)
    if file_changed then
        file_utils.write_file(output_file_path, templatized_output)
        print("Wrote new rendered file: " .. output_file_path)

        local file_size =
            formatters.format_bytes(lfs.attributes(output_file_path, "size"))
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
        print("Force wrote file: " .. output_file_path)
    else
        print(string.format("%s content unchanged; skipping...", source_path))
    end

    local file_data = lock_files.get_file_data(LOCK_FILE, source_path)
    if not file_data then
        error(
            string.format("Missing file data for %s in lock file", source_path)
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
end

local function render_media_file(metadata, output_path, output_file)
    -- TODO: just get file_size and modified at from static file in
    --       source
    --       Also, add override for "link" usage in search so that
    --       displayed path is still to the media files place in
    --       the displayed file hierarchy, not its actual path
    --       in the static directory
    assert(
        metadata.static_link,
        "Media files must have static_link in metadata"
    )

    local static_file_path = CONFIG.generator.static_dir
        .. "/"
        .. metadata.static_link

    -- for static content, we determine whether they've changed based on checksums
    -- only to decide whether we must update their file attributes in the lock
    -- file. no file writing is needed - the files are already written where they
    -- need to live!
    local file_changed, checksum =
        lock_files.static_content_changed(LOCK_FILE, static_file_path)
    if file_changed then
        print(string.format("%s static content changed.", static_file_path))
        local file_size =
            formatters.format_bytes(lfs.attributes(static_file_path, "size"))
        local modified_ts = formatters.unix_ts_to_iso8601(
            lfs.attributes(static_file_path, "modification")
        )
        lock_files.set_file_data(LOCK_FILE, static_file_path, {
            last_modified_ts = modified_ts,
            file_size = file_size,
            checksum = checksum,
        })
    else
        print(string.format("%s static content unchanged.", output_file))
    end

    local file_data = lock_files.get_file_data(LOCK_FILE, static_file_path)
    if not file_data then
        error(
            string.format(
                "Missing file data for %s in lock file",
                static_file_path
            )
        )
    end

    metadata.file_size = file_data.file_size
    metadata.updated_at = file_data.last_modified_ts

    print(string.format("Adding link to %s to index.", output_file))

    return {
        link = formatters.generate_absolute_path(
            CONFIG,
            "static/" .. metadata.static_link
        ),
        search_display = formatters.generate_absolute_path(
            CONFIG,
            output_path .. output_file
        ),
        file_type = file_utils.FileType.FILE,
        display_name = output_file,
        metadata = metadata,
    }
end

local function render_file(output_path, source_path, file_name)
    local pandoc_cmd = string.format(
        PANDOC_CMD_FMT,
        "src/pandoc/metadata_processor.lua",
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

        if metadata[DRAFT_METADATA_FIELD] and ENV == ENVIRONMENTS.PROD then
            print(file_name .. " is a draft. Skipping...")
            return nil
        end

        if metadata[FONT_METADATA_FIELD] then
            assert(
                functions.contains(
                    constants.SUPPORTED_FONTS,
                    metadata[FONT_METADATA_FIELD]
                ),
                string.format(
                    "%s metadata set with unsupported font: %s",
                    file_name,
                    metadata[FONT_METADATA_FIELD]
                )
            )
        end

        local output_file = get_output_file_name(file_name, metadata)

        if metadata.content_type == CONTENT_TYPE.MEDIA then
            return render_media_file(metadata, output_path, output_file)
        else
            return render_post_file(
                source_path,
                output_path,
                output_file,
                pandoc_output,
                metadata
            )
        end
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

local function generate_recently_updated_list()
    local curr_ts = date(true)
    local threshold = CONFIG.main.recently_updated_threshold
        or DEFAULT_RECENTLY_UPDATED_THRESHOLD

    local result = {}
    for filepath, metadata in pairs(LOCK_FILE.files) do
        local modified_ts = date(metadata.last_modified_ts)
        if date.diff(curr_ts, modified_ts):spandays() <= threshold then
            local filename_with_ext =
                filepath:match("([^/]+)$"):gsub("%.md$", ".html")
            local filename = filename_with_ext:match "(.+)%..+$"

            table.insert(result, {
                link = formatters.generate_absolute_path(
                    CONFIG,
                    get_output_file_name(filepath)
                ),
                display_name = filename,
            })
        end
    end

    return #result > 0 and result or nil
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
            all_links = json.encode(all_links),
            is_table_view = true,
            description = not parent_dir and CONFIG.main.description or nil,
            recently_updated = not parent_dir
                    and generate_recently_updated_list()
                or nil,
        }
    )

    file_utils.write_file(
        file_path,
        template_engine.compile_template_file(
            get_template_path(CONFIG.templates.default),
            {
                config = CONFIG,
                content = index_page,
                generate_absolute_path = formatters.generate_absolute_path,
            }
        )
    )

    -- also compile gallery view to toggle to
    -- TODO: clean up
    --       for rendering templates, make a DEFAULT_RENDER_ENV table
    --       providing lua functions commonly used by templates
    local gallery_page = template_engine.compile_template_file(
        get_template_path "gallery.htmlua",
        {
            config = CONFIG,
            dir_name = current_dir_path,
            links = links,
            ipairs = ipairs,
            FileType = file_utils.FileType,
            get_default_icon = get_default_icon,
            all_links = json.encode(all_links),
            is_table_view = false,
            description = not parent_dir and CONFIG.main.description or nil,
            recently_updated = not parent_dir
                    and generate_recently_updated_list()
                or nil,
        }
    )

    file_utils.write_file(
        file_path:gsub("index%.html$", "gallery.html"),
        template_engine.compile_template_file(
            get_template_path(CONFIG.templates.default),
            {
                config = CONFIG,
                content = gallery_page,
                generate_absolute_path = formatters.generate_absolute_path,
            }
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
            -- TODO: run in parallel with coroutines
            for _, file in pairs(src_files) do
                local output_data =
                    render_file(output_path, file.source_path, file.file_name)
                if output_data then
                    table.insert(links, output_data)
                end
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

            -- FIXME: is this correct? should be relative to input directory path...
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
            return {
                link = entry.link,
                search_display = entry.search_display or entry.link,
            }
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

-- END

local function main()
    local content_root = find_content(CONFIG.generator.input_dir)

    file_utils.make_dir_if_not_exists(CONFIG.generator.output_dir)
    local output_path = CONFIG.generator.output_dir .. "/"
    local content_data = render_content_dir(output_path, content_root)

    lock_files.write(LOCK_FILE, CONFIG.generator.lock_file)
    compile_static_assets(
        CONFIG.generator.static_dir,
        CONFIG.generator.output_dir .. "/static"
    )
    generate_xml_feed(CONFIG.generator.output_dir, content_data)
end

main()
