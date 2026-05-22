function Div(div)
-- This targets the bibliography section specifically
if div.identifier:match("^refs") or div.classes:includes("references") then
return pandoc.walk_block(div, {
  Inlines = function(inlines)
    local result = {}
    local i = 1
    while i <= #inlines do
      -- Look for your last name
    if inlines[i].t == "Str" and inlines[i].text:find("Barreñada") then
    -- Check if the next elements are a space and your initial "L."
    if inlines[i+1] and inlines[i+1].t == "Space" and inlines[i+2] and inlines[i+2].t == "Str" and inlines[i+2].text:find("L%.") then
    -- Bold the last name, space, and initial
    table.insert(result, pandoc.Strong({inlines[i], inlines[i+1], inlines[i+2]}))
    i = i + 3
    else
      -- Just bold the last name if the initial isn't right next to it
              table.insert(result, pandoc.Strong({inlines[i]}))
              i = i + 1
            end
          else
            table.insert(result, inlines[i])
            i = i + 1
          end
        end
        return result
      end
    })
  end
end