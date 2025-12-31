local inspect = require "inspect"
local lfs = require "lfs"
local toml = require "toml"
local file_utils = require "utils.files"

local constants = require "utils.constants"

local M = {}

local function prepend_with_sites_dir(site, target)
    return constants.SITES_DIR .. "/" .. site .. "/" .. target
end

function M.load_config(site, env)
    local config_file = prepend_with_sites_dir(site, "config.toml")
    local content = file_utils.read_file(config_file)
    if not content then
        print("Failed to read config file: " .. config_file)
        return 1
    end
    local decode_succeeded, config = pcall(toml.parse, content)
    if not decode_succeeded then
        print("Failed to load config! Error: " .. inspect(config))
        return 1
    end

    -- In dev mode, use empty root since we serve from the output directory
    -- In production, use the configured site URL
    config.generator.root_dir = env == "dev" and "" or config.main.site_url

    config.generator.output_dir = (
        env == "dev" and constants.BUILD_DIR or constants.DEPLOY_DIR
    )
        .. "/"
        .. site

    config.generator.lock_file =
        prepend_with_sites_dir(site, config.generator.lock_file)
    config.generator.input_dir =
        prepend_with_sites_dir(site, config.generator.input_dir)
    config.generator.snippets_dir =
        prepend_with_sites_dir(site, config.generator.snippets_dir)
    config.generator.static_dir =
        prepend_with_sites_dir(site, config.generator.static_dir)
    config.templates.dir = prepend_with_sites_dir(site, config.templates.dir)

    config.env = env
    config.site = site

    return config
end

return M
