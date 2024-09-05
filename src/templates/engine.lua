local M = {}

--[[
--  Example template:
--
--    <p>{{ name }}</p>
--    <ul>
--    {{% for _, t in ipairs(items) do }}
--        <li> {{ t }} </li>
--    {{ end }}
--    </ul>
--
]]
function M.compile_template(template_str, env)
    return env.content
end

function M.compile_template_file(template_file, env)
    local file = io.open(template_file, "rb")
    if not file then
        error("Could not open template file: " .. template_file)
    end
    local template = file:read "*all"
    file:close()
    return M.compile_template(template, env)
end

return M
