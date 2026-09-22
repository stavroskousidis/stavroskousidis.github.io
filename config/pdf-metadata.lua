local function stringify(value)
  if value == nil then
    return ""
  end

  return pandoc.utils.stringify(value)
end

local function stringify_list(value)
  if value == nil then
    return ""
  end

  if type(value) ~= "table" or #value == 0 then
    return stringify(value)
  end

  local items = {}
  for _, item in ipairs(value) do
    table.insert(items, stringify(item))
  end

  return table.concat(items, " · ")
end

local function append_field(inlines, label, value, add_break)
  if value == "" then
    return
  end

  table.insert(inlines, pandoc.Strong({ pandoc.Str(label) }))
  table.insert(inlines, pandoc.Space())
  table.insert(inlines, pandoc.Str(value))

  if add_break then
    table.insert(inlines, pandoc.LineBreak())
  end
end

function Meta(meta)
  local published = stringify(meta.published)
  local updated = stringify(meta.updated)
  local tested_on = stringify_list(meta.testedOn)
  local date_lines = {}

  append_field(date_lines, "Published", published, true)
  append_field(date_lines, "Updated", updated, true)
  append_field(date_lines, "Tested on", tested_on, false)

  if #date_lines > 0 then
    meta.date = pandoc.MetaInlines(date_lines)
  end

  return meta
end
