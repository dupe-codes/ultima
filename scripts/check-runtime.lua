local unsupported_versions =
    { "Lua 5.1", "Lua 5.2", "Lua 5.3", "Lua 5.4", "Lua 5.6" }

for _, version in ipairs(unsupported_versions) do
    local paths = { path = "unchanged", cpath = "unchanged" }
    local setup = assert(loadfile("src/setup.lua", "t", {
        _VERSION = version,
        error = error,
        package = paths,
    }))
    local succeeded, message = pcall(setup)

    assert(not succeeded)
    assert(message == "Ultima requires Lua 5.5; detected " .. version)
    assert(paths.path == "unchanged")
    assert(paths.cpath == "unchanged")
end

assert(_VERSION == "Lua 5.5", "Ultima requires Lua 5.5")
dofile "src/setup.lua"
assert(package.path:match "^lua_modules/share/lua/5%.5/")
assert(package.cpath:match "^lua_modules/lib/lua/5%.5/")
print "Runtime guard checks passed"
