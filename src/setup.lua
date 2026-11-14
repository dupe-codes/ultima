local version = _VERSION:match "%d+%.%d+"

if version ~= "5.5" then
    error("Ultima requires Lua 5.5; detected " .. _VERSION, 0)
end

package.path = "lua_modules/share/lua/"
    .. version
    .. "/?.lua;lua_modules/share/lua/"
    .. version
    .. "/?/init.lua;"
    .. "src/?.lua;"
    .. "src/?/init.lua;"
    .. package.path
package.cpath = "lua_modules/lib/lua/" .. version .. "/?.so;" .. package.cpath
