assert(_VERSION == "Lua 5.5", "Ultima requires Lua 5.5")

for _, module in ipairs { "argparse", "dkjson", "date", "toml", "md5", "inspect" } do
    local path = assert(package.searchpath(module, package.path))
    assert(path:match "^lua_modules/share/lua/5%.5/")
end

for _, module in ipairs { "lfs", "md5.core" } do
    local path = assert(package.searchpath(module, package.cpath))
    assert(path:match "^lua_modules/lib/lua/5%.5/")
end

local argparse = require "argparse"
local date = require "date"
local inspect = require "inspect"
local json = require "dkjson"
local lfs = require "lfs"
local md5 = require "md5"
local toml = require "toml"

local parser = argparse("smoke", "Dependency check")
parser:argument "site"
parser:flag "--force"
local arguments = parser:parse { "dupe_sh", "--force" }
assert(inspect(arguments) == inspect { site = "dupe_sh", force = true })

local payload = { site = "dupe_sh", count = 2, enabled = true }
local encoded = assert(json.encode(payload))
local decoded, position, decode_error = json.decode(encoded)
assert(decode_error == nil)
assert(position == #encoded + 1)
assert(
    inspect(decoded)
        == inspect(
            setmetatable(
                { site = "dupe_sh", count = 2, enabled = true },
                { __jsontype = "object" }
            )
        )
)
assert(
    date("2026-11-14T12:30:00"):fmt "%Y-%m-%d %H:%M:%S" == "2026-11-14 12:30:00"
)
assert(
    inspect(toml.parse '[main]\nsite = "dupe_sh"\ncount = 2\nenabled = true\n')
        == inspect { main = payload }
)
assert(lfs.attributes("src/setup.lua", "mode") == "file")
assert(lfs.attributes("lua_modules/lib/lua/5.5", "mode") == "directory")
assert(md5.sumhexa "abc" == "900150983cd24fb0d6963f7d28e17f72")
print "Dependency smoke checks passed"
