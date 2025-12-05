---------------------------------------------------------------------------
-- ??????? ??? ?????? ? ???????
--
-- @author Nebelung (Nebelung.Programming@mail.ru)
--
-- @copyright 2021 Nebelung Project
---------------------------------------------------------------------------

local csv = require("csv")

function getFromCSV(nameFileCSV)
  local result = {}
  local path = getScriptPath().. "//Data//" .. nameFileCSV;
  --local path = "c://Users//Nebelung//Documents//QuikAssistant//Data//" .. nameFileCSV
  local fileCSV = csv.open(path)

  if fileCSV ~= nil then
    for r in fileCSV:lines() do
      local r2 = {}
      for i, v in ipairs(r) do
        r2[#r2 + 1] = tostring(v)
        -- print(i, v)
      end
      result[#result + 1] = r2
    end
  end

  return result
end
