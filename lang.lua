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
if ( ngx.arg[3] ~= nil ) then
  fallback = ngx.arg[3]
end

local pname = "lang"
if ( ngx.arg[4] ~= nil ) then
  pname = ngx.arg[4]
end

-- Return if no langs are available
if ( ngx.arg[1] == nil ) then
  return fallback
end

local lang_header = ngx.var.http_accept_language -- "Accept-Language: en-US,en;q=0.8,de-DE;q=0.6,de;q=0.4"
local cookie_lang = ngx.var["cookie_" .. pname] -- "en-US", "en" or "en-US,en"
local arg_lang = ngx.var["arg_" .. pname] -- "en-US", "en" or "en-US,en"
if ( cookie_lang ~= nil ) then
  lang_header = cookie_lang
end
if ( arg_lang ~= nil ) then
  lang_header = arg_lang
end
if ( lang_header == nil ) then
  return fallback
end

-- Create map of available langs { en-US: true, en-UK:true, ...}
local langs = {};
for index, value in pairs(ngx.arg[1]:split(",")) do
  table.insert( langs, value )
end

-- Create map of defaults { en: en-US, pt: pt-BR, ...}
local lang_defaults = {}
for index, value in pairs(ngx.arg[2]:split(",")) do
  local splitLang = value:split(":")
  lang_defaults[splitLang[1]] = splitLang[2]
end

-- Sort preferred languages in order of preference
local cleaned = ngx.re.sub(lang_header, "^.*:", ""):lower() -- Remove header name "Accept-Language:"
local options = {} -- Sorted table: { en-US: 1, en: 0.8, de-DE: 0.6, de: 0.4 }

-- Create 2 match groups: language and priority
local regex = "\\s*([a-z-]*)\\s*(?:;q=([0-9]+(.[0-9]*)?))?\\s*(,|$)"
local iterator, err = ngx.re.gmatch(cleaned, regex, "i") -- i = pcre option flag - caseless match
-- have to learn why "iterator, err in" - and then "m, err in" - "m[1], m[2]"
for m, err in iterator do
  local lang = m[1]  -- "en-US" or "en"
  local priority = 1 -- value between 1 and 0 with default 1
  if m[2] ~= nil then
    priority = tonumber(m[2])
    if priority == nil then priority = 1 end
  end
  if m[1] == "" then
  else 
    table.insert(options, {lang, priority})
  end
end
table.sort(options, function(a,b) return b[2] < a[2] end)

-- Match the best language we got
for index, lang in pairs(options) do
  for value, langavail in pairs(langs) do
    if langavail:lower() == lang[1] then -- :lower() on langs - can you improve this?
      return lang[1]
    end
  end
  for value, langdef in pairs(lang_defaults) do
    if value == lang[1] then
      return langdef
    end
  end
end

return fallback
