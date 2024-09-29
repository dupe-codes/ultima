local inspect = require "inspect"
local lfs = require "lfs"
local toml = require "toml"

local M = {}

function M.load_config(env)
    local decode_succeeded, config = pcall(toml.decodeFromFile, "config.toml")
    if not decode_succeeded then
        print("Failed to load config! Error: " .. inspect(config))
        return 1
    end

    -- set current working directory as project root for local dev
    -- OR site root if compiling for production
    config.generator.root_dir = env == "dev" and lfs.currentdir()
        or config.main.site_url

    config.generator.output_dir = env == "dev" and config.generator.output_dir
        or "deploy"

    return config
end

return M
