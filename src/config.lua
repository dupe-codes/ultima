local inspect = require "inspect"
local lfs = require "lfs"
local toml = require "toml"

local M = {}

function M.load_config()
    local decode_succeeded, config = pcall(toml.decodeFromFile, "config.toml")
    if not decode_succeeded then
        print("Failed to load config! Error: " .. inspect(config))
        return 1
    end

    -- set current working directory as project root
    config.generator.root_dir = lfs.currentdir()
    return config
end

return M
