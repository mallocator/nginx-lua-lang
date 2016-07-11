-- https://github.com/mallocator/nginx-lua-lang
-- call script by: lua local.lua <supported> <defaults> <fallback> <acceptheaders>
-- example values: lua local.lua "en-US,en-GB,en-AU,de-DE,de-AT,de-CH,it,nl" \
--                               "en:en-US,pt:pt-BR,de:de-AT" \
--                               "de-DE" \
--                               "Accept-Language: en-US,en;q=0.8,de-DE;q=0.6,de;q=0.4"

ngxre = require "rex_pcre"

-- Helper function to split a string into a table of fragments
function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = {}
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

-- Set default fallback if it's not set
local fallback = "en-US"
if ( arg[3] ~= nil ) then
  fallback = arg[3]
end

-- Return if no langs are available
if ( arg[1] == nil ) then
  return fallback
end

local lang_header = arg[4]
if ( lang_header == nil ) then
  return fallback
end

-- Create map of available langs { en-US: true, en-UK:true, ...}
local langs = {}
print( "---- map of available langs ----")
for index, value in pairs(arg[1]:split(",")) do
  print(index..","..value)
  table.insert( langs, value )
end

-- Create map of defaults { en: en-US, pt: pt-BR, ...}
--local default_list = "en:en-US,pt:pt-BR,de:de-AT"
local lang_defaults = {}
print( "---- map of defaults ----")
for index, value in pairs(arg[2]:split(",")) do
  local splitLang = value:split(":")
  lang_defaults[splitLang[1]] = splitLang[2]
  print(index..","..splitLang[1]..":"..splitLang[2])
end

-- Sort preferred languages in order of preference
local cleaned = ngxre.gsub(lang_header, "^.*:", ""):lower() -- Remove header name "Accept-Language:"
print("--- cleaned regex ---")
print(cleaned)
local options = {} -- Sorted table: { en-US: 1, en: 0.8, de-DE: 0.6, de: 0.4 }

-- Create 2 match groups: language and priority
local regex = "\\s*([a-z-]*)\\s*(?:;q=([0-9]+(.[0-9]*)?))?\\s*(,|$)"
local iterator, err = ngxre.gmatch(cleaned, regex, "i") -- i = pcre option flag - caseless match

print("---- regex match output ----")
for m, err in iterator do
  local lang = m  -- "en-US" or "en"
  print( "match: "..m)
  local priority = 1 -- value between 1 and 0 with default 1
  if err ~= nil then
    priority = tonumber(err)
    if priority == nil then priority = 1
      print("assign priority: "..priority)
    end
  end
  if m == "" then -- single out the regex "$" zero-length match to not be added to the table
  else
    table.insert(options, {lang, priority})
    print( "insert: "..lang..","..priority)
  end
end
table.sort(options, function(a,b) return b[2] < a[2] end)


print("--- options ---")
for key,value in pairs(options) do
  print(key,value[1],value[2])
end
print("--- langs ---")
for index,value in pairs(langs) do
  print(index,value)
end
print("--- lang_defaults ---")
for key,value in pairs(lang_defaults) do
  print(key,value)
end

-- Match the best language we got
for index, lang in pairs(options) do
  print("trying to match lang: "..index..","..lang[1])
  for value, langavail in pairs(langs) do
    print(value,langavail)
    if langavail:lower() == lang[1] then
      print( "output lang: "..index..","..lang[1])
      return lang[1]
    end
  end
  for value, langdef in pairs(lang_defaults) do
    print("output default: "..value,langdef)
    if value == lang[1] then
      return langdef
    end
  end
end

print( "output fallback: "..fallback)
return fallback
