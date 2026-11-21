print(">>> Running highlight-author.lua <<<")

function Inlines(inlines)
  local new_inlines = pandoc.List()
  local i = 1
  local n = #inlines

  while i <= n do
    local el = inlines[i]

    -- Check for "Barre" (catches Barreñada, Barrenada, and split accent tokens)
    if el.t == "Str" and el.text:find("Barre") then
      local author_tokens = pandoc.List({el})
      local j = i + 1

      -- Look ahead to capture any split surname parts, spaces, "Taleb", and "L."
      while j <= n do
        local next_el = inlines[j]
        local txt = pandoc.utils.stringify(next_el)

        if next_el.t == "Space" or next_el.t == "SoftBreak" or txt == "\160" then
          author_tokens:insert(next_el)
          j = j + 1
        elseif next_el.t == "Str" and (
          txt:find("^ñada") or
          txt:find("^nada") or
          txt:find("^Taleb") or
          txt:find("^L%.") or
          txt:find("^Lasai")
        ) then
          -- If "L.," has a trailing comma, keep the comma outside bold
          if txt:match("^L%.,$") then
            author_tokens:insert(pandoc.Str("L."))
            print(">>> Bolded author: " .. pandoc.utils.stringify(author_tokens))
            new_inlines:insert(pandoc.Strong(author_tokens))
            new_inlines:insert(pandoc.Str(","))
            i = j + 1
            goto continue
          else
            author_tokens:insert(next_el)
            j = j + 1
            if txt:find("^L%.") or txt:find("^Lasai") then
              break
            end
          end
        else
          break
        end
      end

      -- Also handle the case where "Barreñada,\160L." was fused into a single Str by citeproc
      print(">>> Bolded author: " .. pandoc.utils.stringify(author_tokens))
      new_inlines:insert(pandoc.Strong(author_tokens))
      i = j
      goto continue
    end

    new_inlines:insert(el)
    i = i + 1
    ::continue::
  end

  return new_inlines
end