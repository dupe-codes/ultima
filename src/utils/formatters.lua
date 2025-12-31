local date = require "date"

local M = {}

function M.format_bytes(bytes, decimal_places)
    local units =
        { "B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB" }
    local divisor = 1024
    local i = 1
    while bytes >= divisor and i < #units do
        bytes = bytes / divisor
        i = i + 1
    end
    local format_string = "%." .. (decimal_places or 2) .. "f %s"
    return string.format(format_string, bytes, units[i])
end

function M.unix_ts_to_iso8601(timestamp)
    return os.date("!%Y-%m-%dT%H:%M:%SZ", timestamp)
end

function M.iso8601_str_to_format(iso_ts, format)
    local date_obj = date(iso_ts)
    return date_obj:fmt(format)
end

function M.shell_escape(arg)
    return "'" .. string.gsub(arg, "'", "'\\''") .. "'"
end

function M.strip_output_dir(file_path, output_dir)
    return file_path:gsub("^" .. output_dir .. "/", "")
end

function M.strip_input_dir(filepath, input_dir)
    return filepath:gsub("^" .. input_dir .. "/", "")
end

function M.generate_absolute_path(config, target)
    -- strip redundant output dir if already included in target path
    target = M.strip_output_dir(target, config.generator.output_dir)
    -- strip out input_dir if still present
    target = M.strip_input_dir(target, config.generator.input_dir)
    -- In dev mode, paths are relative to server root (output directory)
    -- In production, paths use the full site URL
    return config.generator.root_dir .. "/" .. target
end

return M
