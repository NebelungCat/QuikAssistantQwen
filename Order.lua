-- Класс ордера
Order = {}

-- (дополняет библиотеку math)
math.round = function(num, idp)
  if num == nil then
    return nil
  end
  local mult = 10 ^ (idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

--- Функция предназначена для получения информации по инструменту.
---@param securityCode string
function GetSecurityInfo(securityCode)
  for classCode in string.gmatch("TQCB,TQBR,SPBXM,EQOB,TQIR,TQRD,TQOB,FQBR,TQTF,TQPI,MTQR,", "(%P*),") do
    local SecurityInfo = getSecurityInfo(classCode, securityCode)
    if SecurityInfo ~= nil then
      return SecurityInfo
    end
  end
  log.error("Инструмент не найден." .. securityCode)
  return nil
end

--- Функция предназначена для получения информации по инструменту.
---@param securityCode string
function GetUsdSecurityInfo(securityCode)
  for classCode in string.gmatch("TQCB,TQBD,TQBR,SPBXM,EQOB,TQIR,TQRD,TQOB,TQTF,TQPI,MTQR,", "(%P*),") do
    local SecurityInfo = getSecurityInfo(classCode, securityCode)
    if SecurityInfo ~= nil then
      return SecurityInfo
    end
  end
  --log.error("Инструмент не найден." .. securityCode)
  return nil
end

---Заявка.
---@param securityCode string
---@return table
function Order:new(securityCode)
  local obj = {}
  
  if Broker == "VTB" then
    obj.SecurityInfo = GetUsdSecurityInfo(securityCode)
  else
    obj.SecurityInfo = GetSecurityInfo(securityCode)
  end

  obj.SecurityCode = securityCode
  --obj.SecurityInfo = GetSecurityInfo(securityCode)
  obj.Operation = ""
  obj.Quantity = 0
  obj.Price = 0

  if (obj.SecurityInfo == nil) then
    return nil
  end
  
  -- Исключение инструмента из проверки на предельную доходность
  function obj:IsExceptionFromLimitActuation()
    for securityCode in string.gmatch("ENPG,RTKM,MTSS,NKNCP,UPRO,MGTSP,IRAO,MAGN,TGKA,GAZP,AFLT,ELFV,SMLT,SNGS,ALRS,MGNT,HYDR,VTBR,FEES,MVID,SGZH,AQUA,STSB,IVAT,UPRO,VKCO,", "(%P*),") do
      if (obj.SecurityCode == securityCode) then
        return true
      end
    end
    return false  
  end

  ---Это облигация.
  ---@return boolean
  function obj:IsBond()
    for classCode in string.gmatch("TQCB,EQOB,TQIR,TQRD,TQOB,", "(%P*),") do
      if (obj.SecurityInfo.class_code == classCode) then
        return true
      end
    end
    return false
  end

  function obj:IsOFZ()
    if (obj.SecurityInfo.class_code == "TQOB") then
      return true
    end
    return false
  end

  function obj:IsEtf()
    if (obj.SecurityInfo.class_code == "TQTF") then
      return true
    end
    return false
  end

  function obj:IsSpb()
    if (obj.SecurityInfo.class_code == "SPBXM") then
      return true
    end
    return false
  end

  function obj:IsForeign()
    if (obj.SecurityInfo.class_code == "SPBXM" or obj.SecurityInfo.class_code == "FQBR" or obj.SecurityInfo.class_code == "TQBD") then
      return true
    end
    return false
  end

  function obj:IsUsd()
    if (obj.SecurityInfo.class_code == "SPBXM" or obj.SecurityInfo.class_code == "TQBD") then
      return true
    end
    return false
  end

  function obj:IsBuy()
    if (obj.Operation ~= nil and obj.Operation == "B") then
      return true
    end
    return false
  end

  function obj:IsSell()
    if (obj.Operation ~= nil and obj.Operation == "S") then
      return true
    end
    return false
  end

  function obj:Clear()
    obj.Operation = ""
    obj.Quantity = 0
    obj.Price = 0
  end

  function obj:FormatPrice()
    return string.format("%." .. obj.SecurityInfo.scale .. "f", tonumber(obj.Price))
  end

  function obj:FormatQuantity(n)
    local n = (n or 0)
    return string.format("%." .. n .. "f", obj.Quantity)
  end

  function obj:GetPriceInCurrency(price)
    if obj:IsBond() then
      local nominal = obj.SecurityInfo.face_value
      return tonumber(price) * tonumber(nominal) / 100
    else
      return tonumber(price)
    end
  end

  function obj:SetOperation(operation, price, quantity)
    obj.Operation = operation
    obj.Quantity = quantity
    obj.Price = price
    obj:GetPriceRound()

    if (price == 0) then
      if obj.SecurityInfo.min_price_step <= 0.0001 then
        obj.Price = 0.0001
      else
        obj.Price = obj.SecurityInfo.min_price_step
      end
    end
  end

  function obj:SetPriceMin(operation)
    obj.Operation = operation
    if (obj:IsBuy()) then
      obj.Quantity = 1
      obj.Price = obj.SecurityInfo.min_price_step
    else
      obj.Quantity = 0
      obj.Price = 0
    end
  end

  function obj:SetQuantity(operation, price, quantityMax)
    obj.Operation = operation
    if price ~= nil and tonumber(price) > 0 and quantityMax ~= nil and tonumber(quantityMax) > 0 and obj:IsBuy() then
      obj.Price = tonumber(price)
      obj:GetPriceRound()

      if obj:IsBond() then
        local priceRub = obj:GetPriceInCurrency(price)
        obj.Quantity = math.floor(tonumber(quantityMax) / tonumber(priceRub) / tonumber(obj.SecurityInfo.lot_size))
      else
        obj.Quantity = math.floor(tonumber(quantityMax) / tonumber(obj.Price) / tonumber(obj.SecurityInfo.lot_size))
      end

      if (obj.Quantity <= 0) then
        obj.Quantity = 1
      end
    else
      obj.Quantity = 0
    end
  end

  function obj:GetVolume()
    local priceInCurrency = 0
    if obj:IsBond() then
      priceInCurrency = obj:GetPriceInCurrency(obj.Price)
    else
      priceInCurrency = obj.Price
    end
    return obj.Quantity * priceInCurrency * tonumber(obj.SecurityInfo.lot_size)
  end

  function obj:GetPriceRound()
    local price = math.round(obj.Price, obj.SecurityInfo.scale) -- Округляет число до необходимого количества знаков после запятой

    if price == nil then
      --log.error("Ошибка в округлении цены. " .. obj.Print())
      price = 0
    end

    if obj:IsBuy() then
      price = math.ceil(price / obj.SecurityInfo.min_price_step) * obj.SecurityInfo.min_price_step -- Корректирует на соответствие шагу цены
    elseif obj:IsSell() then
      price = math.floor(price / obj.SecurityInfo.min_price_step) * obj.SecurityInfo.min_price_step -- Корректирует на соответствие шагу цены
    else
      price = 0
    end
    --log.debug(string.format("Округляем цену %s до %f",obj.Price, price))
    obj.Price = price
  end

  function obj:Print()
    return string.format(
      "[Инструмент: %s; Тикет: %s; Код класса: %s; Операция: %s; Цена: %f; Количество: %u; Объём: %f;]",
      obj.SecurityInfo.name,
      obj.SecurityCode,
      obj.SecurityInfo.class_code,
      obj.Operation,
      obj.Price,
      obj.Quantity,
      obj:GetVolume()
    )
  end

  --чистая магия!
  setmetatable(obj, self)
  obj.__index = self
  return obj
end

return Order
