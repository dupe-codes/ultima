local inspect = require "inspect"
local json = require "dkjson"
local lfs = require "lfs"
local md5 = require "md5"

local file_utils = require "utils.files"

local M = {}

-- Helper to get sorted keys for deterministic JSON encoding
local function get_sorted_keys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

-- Encode with sorted keys for deterministic output
local function encode_deterministic(tbl)
    return json.encode(tbl, { keyorder = get_sorted_keys(tbl) })
end

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

function M.file_content_changed(lock_file, file_path, content, metadata)
    if not lock_file or not lock_file.files then
        error "Given incorrectly typed lock_file"
    end

    local lock_file_attrs = lock_file.files[file_path]
    local content_checksum = md5.sumhexa(content)
    local metadata_checksum = metadata and md5.sumhexa(encode_deterministic(metadata)) or nil

    if not lock_file_attrs or not lock_file_attrs.checksum then
        return true, content_checksum, metadata_checksum
    end

    local content_changed = content_checksum ~= lock_file_attrs.checksum
    local metadata_changed = metadata_checksum
        and lock_file_attrs.metadata_checksum
        and metadata_checksum ~= lock_file_attrs.metadata_checksum

    return content_changed or metadata_changed, content_checksum, metadata_checksum
end

function M.static_content_changed(lock_file, file_path)
    local file = io.open(file_path, "rb")
    if not file then
        error("Could not open file: " .. file_path)
    end

    local content = file:read "*a"
    file:close()
    return M.file_content_changed(lock_file, file_path, content)
end

function M.write(lock_file_content, output_file)
    local lock_file_data = json.encode(lock_file_content, { indent = true })
    local file = io.open(output_file, "w")

    if not file then
        error "Failed to open output file for lock file writing!"
    end

    file:write(lock_file_data)
    file:close()
end

return M
