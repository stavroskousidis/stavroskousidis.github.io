-- One-page thesis announcement: create a research-question section from metadata,
-- display the publication date, and normalize internal links for downloadable PDFs.
local function text(value)
  if value == nil then
    return ""
  end
  return pandoc.utils.stringify(value)
end

function Meta(meta)
  local degree = text(meta.level)
  local date = text(meta.published)
  local updated = text(meta.updated)
  local prefix = degree ~= "" and (degree .. " thesis · ") or ""
  local label = prefix .. "Published: " .. date
  if updated ~= "" and updated ~= date then
    label = label .. " · Last updated: " .. updated
  end
  meta.date = pandoc.MetaString(label)
  return meta
end

function Link(link)
  if link.target:sub(1, 1) == "/" then
    link.target = "https://stavroskousidis.github.io" .. link.target
  end
  return link
end

function Pandoc(doc)
  local question = text(doc.meta.researchQuestion)
  assert(question ~= "", "Missing thesis research question")
  local blocks = {
    pandoc.Header(2, "Research question"),
    pandoc.Para(pandoc.read(question, "markdown").blocks[1].content),
  }
  for _, block in ipairs(doc.blocks) do
    table.insert(blocks, block)
  end
  local footer = pandoc.read(
    "**Contact:** [stavros.kousidis@th-koeln.de](mailto:stavros.kousidis@th-koeln.de)  " ..
    "\\n**Thesis opportunities:** [stavroskousidis.github.io/theses](https://stavroskousidis.github.io/theses/)",
    "markdown"
  )
  for _, block in ipairs(footer.blocks) do
    table.insert(blocks, block)
  end
  doc.blocks = blocks
  return doc
end
