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

function M.shell_escape(arg)
    return "'" .. string.gsub(arg, "'", "'\\''") .. "'"
end

function M.strip_output_dir(file_path, output_dir)
    return file_path:gsub("^" .. output_dir .. "/", "")
end

return M
