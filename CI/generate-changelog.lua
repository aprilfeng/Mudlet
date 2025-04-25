-- Add near the top with other requires
local autocomplete_path
if github_workspace then
  autocomplete_path = github_workspace.."/src/autocomplete.json"
else
  autocomplete_path = "../src/autocomplete.json"
end

-- Load Mudlet's Lua function list from autocomplete.json
local function load_mudlet_functions()
  local json_data = read_file(autocomplete_path)
  if not json_data then error("Failed to load autocomplete.json") end
  local ac = lunajson.decode(json_data)
  
  local functions = {}
  for _, item in ipairs(ac) do
    if item.type == "function" then
      -- Extract function name from patterns like "send(...)"
      local name = item.text:match("^([%w_]+)%(")
      if name then functions[name:lower()] = true end
    end
  end
  return functions
end

-- Preload Mudlet functions
local mudlet_functions = load_mudlet_functions()

-- Add these helper functions
local function link_lua_functions(text)
  -- Match function names with optional parentheses, case-insensitive
  return text:gsub("([%w_]+)%(%)?", function(fn)
    if mudlet_functions[fn:lower()] then
      return string.format([[<a href="https://wiki.mudlet.org/Manual:Lua_Functions#%s">%s()</a>]], fn, fn)
    end
    return fn.."()" -- Return original if not found
  end)
end

local function link_file_references(text)
  -- Match file paths starting with src/ or similar
  return text:gsub("([%w_]+%.%w+)[:：]?", function(file)
    if file:match("^%a+%.lua$") or file:match("^src/") then
      return string.format([[<a href="https://github.com/Mudlet/Mudlet/blob/%s/%s">%s</a>]], 
                         os.getenv("GITHUB_SHA") or "development", file, file)
    end
    return file
  end)
end

-- Update the HTML converter
htmlBuilder.converter = function(text)
  local t = {}
  text = text.."\n"
  for s in string.gmatch(text, "(.-)\n") do
    s = escape_for_html(s)
    s = s:gsub("%(#(.-)%)", [[<a href='https://github.com/Mudlet/Mudlet/pull/%1'>(#%1)</a>]])
    s = link_lua_functions(s)    -- Add function linking
    s = link_file_references(s)  -- Add file linking
    t[#t+1] = string.format("<p>%s</p>", s)
  end
  return table.concat(t, "\n")
end

-- Update the Markdown converter
mdBuilder.converter = function(text)
  local t = {}
  text = text.."\n"
  for s in string.gmatch(text, "(.-)\n") do
    s = escape_for_html(s)
    s = s:gsub("%(#(.-)%)", "[#%1](https://github.com/Mudlet/Mudlet/pull/%1)")
    -- Markdown version of function linking
    s = s:gsub("([%w_]+)%(%)?", function(fn)
      if mudlet_functions[fn:lower()] then
        return string.format("[%s()](https://wiki.mudlet.org/Manual:Lua_Functions#%s)", fn, fn)
      end
      return fn.."()"
    end)
    t[#t+1] = string.format("\\%s\n", s)
  end
  return table.concat(t, "\n")
end