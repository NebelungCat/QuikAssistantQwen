-- Оптимизированные функции для торгового ассистента

-- Кэш информации об инструментах
local security_cache = {}
local class_codes = {"TQCB", "TQBR", "SPBXM", "EQOB", "TQIR", "TQRD", "TQOB", "FQBR", "TQTF", "TQPI", "MTQR"}

-- Оптимизированная функция получения информации об инструменте
function GetSecurityInfo(securityCode)
  if security_cache[securityCode] then
    return security_cache[securityCode]
  end
  
  for _, classCode in ipairs(class_codes) do
    local SecurityInfo = getSecurityInfo(classCode, securityCode)
    if SecurityInfo ~= nil then
      security_cache[securityCode] = SecurityInfo
      return SecurityInfo
    end
  end
  
  log.error("Инструмент не найден." .. securityCode)
  return nil
end

-- Очистка кэша при необходимости
function ClearSecurityCache()
  security_cache = {}
end

-- Кэш для округленных цен
local price_round_cache = {}

-- Оптимизированное округление цены
function GetRoundedPrice(price, min_price_step, operation)
  local cache_key = string.format("%.6f_%s_%s", price, min_price_step, operation)
  
  if price_round_cache[cache_key] then
    return price_round_cache[cache_key]
  end
  
  local rounded_price = math.round(price, 6) -- используем фиксированное количество знаков
  
  if rounded_price == nil then
    rounded_price = 0
  end

  if operation == "B" then -- покупка
    rounded_price = math.ceil(rounded_price / min_price_step) * min_price_step
  elseif operation == "S" then -- продажа
    rounded_price = math.floor(rounded_price / min_price_step) * min_price_step
  else
    rounded_price = 0
  end
  
  -- Сохраняем в кэш
  price_round_cache[cache_key] = rounded_price
  return rounded_price
end

-- Оптимизированная версия функции SetQuantity с кэшированием
function SetQuantityOptimized(obj, operation, price, quantityMax)
  obj.Operation = operation
  if price ~= nil and tonumber(price) > 0 and quantityMax ~= nil and tonumber(quantityMax) > 0 and operation == "B" then
    obj.Price = tonumber(price)
    -- Используем оптимизированное округление
    obj.Price = GetRoundedPrice(obj.Price, obj.SecurityInfo.min_price_step, operation)

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

-- Оптимизированная структура для отслеживания отправленных ордеров
local sent_orders_index = {} -- индекс в формате "securityCode_operation" -> true

-- Проверка отправленных ордеров
function IsSendOrderOptimized(order)
  local key = order.SecurityInfo.code .. "_" .. order.Operation
  return sent_orders_index[key] == true
end

-- Добавление отправленного ордера в индекс
function AddSentOrder(order)
  local key = order.SecurityInfo.code .. "_" .. order.Operation
  sent_orders_index[key] = true
end

-- Оптимизированная загрузка ордеров из файла с уменьшенным количеством вызовов API
function LoadOrdersFromFileOptimized(fileName)
  local orders = {}
  local rows = getFromCSV(fileName)
  local isEdge = fileName:find("_Edge")
  local isFileSpb = fileName:find("_BuyOrdersSpb_Edge")
  local isRmUsd = fileName:find("_BuyOrders_RmUSD_Edge")

  for i, row in ipairs(rows) do
    local securityName = row[1]
    local isComment = string.find(securityName, "--", 1, true)
    if (isComment == nil) then
      local operation = row[2]
      local securityCode = row[3]
      local quantity = tonumber(row[4])
      local price = tonumber(row[5])

      -- Используем оптимизированное создание ордера с кэшированием
      local order = Order:new(securityCode)
      if (order == nil) then
        log.error("Не удалось распознать  бумагу " .. json.encode(row))
      else
        if isRmUsd ~= nil then
          local priceMin = GetPricePrev(order) / 4
          order:SetQuantity(operation, priceMin, VolumeOrderLimitUSD)
        elseif isFileSpb ~= nil then
          local priceMin = GetPricePrev(order) / 4
          order:SetQuantity(operation, priceMin, VolumeOrderLimitUSD)
        elseif isEdge ~= nil then
          local priceMin = GetPriceMin(order)
          if tonumber(priceMin) == 0 then
            log.error("Минимально возможная цена сделки не определилась.", order:Print())
            order:SetPriceMin(operation)
          else
            local progressOrderVolumeMax = GetOrderVolumeMax(order, priceMin)
            -- Используем оптимизированную функцию
            SetQuantityOptimized(order, operation, priceMin, progressOrderVolumeMax)
          end
        else
          order:SetOperation(operation, price, quantity)
        end
        table.insert(orders, order)
      end
    end
  end

  return orders
end

-- Оптимизированная отправка ордеров
function SubmitOrdersOptimized(orders)
  for i, order in pairs(orders) do
    local isSendOrder = IsSendOrderOptimized(order)
    local isFind = IsOrderExists(order)
    local isCheck = CheckOrder(order)

    log.trace("isFind: ", isFind, "isCheck: ", isCheck, "isSendOrder: ", isSendOrder, order:Print())

    if not isFind and isCheck and not isSendOrder then
      local clientAccountCode = AccountCode
      if order:IsSpb() then
        clientAccountCode = AccountCodeSpb
      end

      local trans_id, error =
        N_SetLimitOrder(
        clientAccountCode,
        ClientCode,
        order.SecurityInfo.class_code,
        order.SecurityInfo.code,
        order.Operation,
        order:FormatPrice(),
        order:FormatQuantity()
      )
      if error ~= "" then
        log.error("Ошибка при отправки заявки на биржу: ", error, order.Print())
      else
        -- Добавляем в индекс отправленных ордеров
        AddSentOrder(order)
      end
    end
  end
end