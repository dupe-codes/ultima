local inspect = require "inspect"
local lfs = require "lfs"

local M = {}

M.FileType = {
    DIRECTORY = 0,
    FILE = 1,
    RSS = 2,
}

function M.read_file(path)
    local file = io.open(path, "r")
    if not file then
        error("Could not open file: " .. path)
    end
    local content = file:read "*a"
    file:close()
    return content
end

function M.copy_file(source, destination)
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

function M.copy_directory(src_dir, output_dir)
    lfs.mkdir(output_dir)
    for file in lfs.dir(src_dir) do
        if file ~= "." and file ~= ".." then
            local src_path = src_dir .. "/" .. file
            local target_path = output_dir .. "/" .. file

            local mode = lfs.attributes(src_path, "mode")
            if mode == "file" then
                M.copy_file(src_path, target_path)
            elseif mode == "directory" then
                M.copy_directory(src_path, target_path)
            end
        end
    end
end

function M.write_file(output_file_path, output)
    local file = io.open(output_file_path, "w")
    if not file then
        error("Could not open file: " .. output_file_path)
    end
    file:write(output)
    file:close()
end

function M.make_dir_if_not_exists(dir)
    -- split the path by directory separator
    local path_parts = {}
    for part in string.gmatch(dir, "[^/]+") do
        table.insert(path_parts, part)
    end

    local current_path = ""
    for _, part in ipairs(path_parts) do
        if current_path == "" then
            current_path = part
        else
            current_path = current_path .. "/" .. part
        end

        local dir_exists = lfs.attributes(current_path, "mode") == "directory"
        if not dir_exists then
            local success, err = lfs.mkdir(current_path)
            if not success then
                error(
                    "Failed to make directory "
                        .. current_path
                        .. ": "
                        .. tostring(err)
                )
            end
        end
    end
end

function M.get_all_subdirs_in_target(target_dir)
    local result = {}
    for file in lfs.dir(target_dir) do
        if file ~= "." and file ~= ".." then
            local full_path = target_dir .. "/" .. file
            local attributes = lfs.attributes(full_path)
            if attributes.mode == "directory" then
                table.insert(result, file)
            end
        end
    end
    return result
end

return M
