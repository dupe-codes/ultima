local inspect = require "inspect"
local json = require "dkjson"
local lfs = require "lfs"

local file_utils = require "utils.files"

local M = {}

function M.load(lock_file_path)
    local lock_file_exists = lfs.attributes(lock_file_path)
    if not lock_file_exists then
        return M.new()
    end

    local lock_file_content = file_utils.read_file(lock_file_path)
    local result, _, err = json.decode(lock_file_content)
    if not result then
        error(
            string.format(
                "Failed to load lock_file at %s. Cause: %s",
                lock_file_path,
                err
            )
        )
    end
    require "debugger"()
    return result
end

function M.new()
    return {
        files = {},
    }
end

function M.get_file_data(lock_file, target_file)
    if lock_file and lock_file.files then
        return lock_file.files[target_file]
    else
        return nil
    end
end

function M.set_file_data(lock_file, target_file, data)
    if lock_file and lock_file.files then
        lock_file.files[target_file] = data
    else
        error(
            string.format("Given an invalid lock_file: %s", inspect(lock_file))
        )
    end
end

function M.write(lock_file_content, output_file)
    local lock_file_data = json.encode(lock_file_content.files)
    local file = io.open(output_file, "w")

    if not file then
        error "Failed to open output file for lock file writing!"
    end

    file:write(lock_file_data)
    file:close()
end

return M
