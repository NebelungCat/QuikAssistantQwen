function GetParamInfo(order, param)
  local value = getParamEx(order.SecurityInfo.class_code, order.SecurityInfo.code, param)
  if value.result == "0" then
    log.error("Параметр не найден.", param, order.Print())
  end
  return value.param_value
end

--- Узнаем последнюю цену
function GetPriceLast(order)
  local priceLast = GetParamInfo(order, "LAST")
  if (tonumber(priceLast) == 0) then
    priceLast = GetPricePrev(order)
  end
  return priceLast
end

--- Минимально возможная цена
function GetPriceMin(order)
  local priceMin = GetParamInfo(order, "PRICEMIN")
  return priceMin
end

--- Максимально возможная цена
function GetPriceMax(order)
  local priceMin = GetParamInfo(order, "PRICEMAX")
  return priceMin
end

---Цена закрытия
function GetPricePrev(order)
  local pricePrev = GetParamInfo(order, "PREVPRICE")
  return pricePrev
end

-- Чем больше планка, тем на большее значение увеличиваем VolumeOrderMax
function GetKoeffVolumeOrderMax(order, priceMin)
  local priceLast = GetPriceLast(order)
  local koeff = (tonumber(priceLast) - tonumber(priceMin)) / tonumber(priceMin) * 10
  if koeff ~= nil and tonumber(koeff) > 1 then
    return koeff
  end
  return 1
end

-- Вычисляем объем заявки
function GetOrderVolumeMax(order, priceMin)
  local progressOrderVolumeMax = 0
  local koeff = GetKoeffVolumeOrderMax(order, priceMin)
  if order:IsBond() then
    progressOrderVolumeMax = BondVolumeOrderMax * tonumber(koeff)
    if progressOrderVolumeMax > VolumeOrderLimit then
      progressOrderVolumeMax = VolumeOrderLimit
    end

    return progressOrderVolumeMax
  end

  progressOrderVolumeMax = VolumeOrderMax

  if order:IsForeign() then
    progressOrderVolumeMax = VolumeOrderLimitForeign
  end

  if order:IsUsd() then
    progressOrderVolumeMax = VolumeOrderLimitUSD
  end

  if progressOrderVolumeMax > VolumeOrderLimit then
    progressOrderVolumeMax = VolumeOrderLimit
  end

  return progressOrderVolumeMax
end


function GetOperation(flags)
  if (bit.band(flags, 4) > 0) then
    return "S"
  else
    return "B"
  end
end

--- Проверем что заявка исполнена
function IsOrderExecuted(flags)
  return bit.band(flags, 1) == 0 and bit.band(flags, 2) == 0 -- не активна -- исполнена
end

--Поисковая функция
function FindOrder(flags, sec_code, class_code)
  if bit.band(flags, 1) > 0 or IsOrderExecuted(flags) then -- активна
    return true
  else
    return false
  end
end

--- Считываем из QUIK уже имеющиеся заявки
function GetQuikOrders()
  local countOrders = getNumberOf("orders")

  log.debug(string.format("Уже выставлено %d заявок.", countOrders))
  local orders = SearchItems("orders", 0, countOrders - 1, FindOrder, "flags, sec_code, class_code")
  if orders ~= nil then
    for i = 1, #orders do
      local order = getItem("orders", orders[i])
      OnOrder(order)
    end
  end
end

-- Проверем может заявка по данной бумаги уже выставлена
function IsOrderExists(newOrder)
  local countOrders = getNumberOf("orders")

  local orders = SearchItems("orders", 0, countOrders - 1, FindOrder, "flags, sec_code, class_code")
  if orders ~= nil then
    for i = 1, #orders do
      local order = getItem("orders", orders[i])

      --log.trace(json.encode(order))

      local operation
      if (bit.band(order.flags, 4) > 0) then
        operation = "S"
      else
        operation = "B"
      end

      --log.trace(order.sec_code, newOrder.SecurityCode, operation, newOrder.Operation, tostring(tonumber(order.qty)), tostring(tonumber(newOrder.Quantity)), bit.band(order.flags, 1) , IsOrderExecuted(order.flags))

      if
        order.sec_code == newOrder.SecurityCode and operation == newOrder.Operation and
          --tonumber(order.qty) == tonumber(newOrder.Quantity) and
          string.format("%." .. newOrder.SecurityInfo.scale .. "f", tonumber(order.price)) ==
            string.format("%." .. newOrder.SecurityInfo.scale .. "f", tonumber(newOrder.Price)) and
          --tonumber(order.price) == tonumber(newOrder.Price) and
          (bit.band(order.flags, 1) > 0 or --Заявка активна
            IsOrderExecuted(order.flags))
      then
        return true
      end
    end
  end

  return false
end

function FindPosition(limit_kind, currentbal)
  if limit_kind == 2 and tonumber(currentbal) ~= 0 then
    return true
  end
  return false
end

--- Позиция в портфеле
function GetPosition(securityCode)
  local countPositions = getNumberOf("depo_limits")

  local positions = SearchItems("depo_limits", 0, countPositions - 1, FindPosition, "limit_kind, currentbal")
  if positions ~= nil then
    for i = 1, #positions do
      local position = getItem("depo_limits", positions[i])

      if position.sec_code == securityCode then
        log.debug("Существует позиция. ", securityCode)
        log.trace(json.encode(position))
        return position
      end
    end
  end

  return nil
end

--- Проверяем заявку на корректность
function CheckOrder(order)
  local priceLast = GetPriceLast(order)

  if order == nil or order.Price == nil or order.Quantity == nil or order.Operation == nil
    or tonumber(order.Price) <= 0 or tonumber(order.Quantity) <= 0 or order.Operation == "" then
      log.error("Некорректная заявка.", order.Print())
      return false
  end

  -- Меняем цену в заявке если выставляемая хуже текущей
  if order:IsBuy() then
    if tonumber(priceLast) < tonumber(order.Price) and tonumber(priceLast) ~= 0 then
      log.info(
        "Поменяли цену заявки на рыночную. Рыночная цена " ..
          tostring(priceLast) .. " меньше цены заявки. " .. order.Print()
      )
      order.Price = priceLast - 10 * order.SecurityInfo.min_price_step
    end
  end

  -- Меняем цену в заявке если выставляемая хуже текущей
  if order:IsSell() then
    if tonumber(priceLast) > tonumber(order.Price) and tonumber(priceLast) ~= 0 then
      log.info(
        "Поменяли цену заявки на рыночную. Рыночная цена " ..
          tostring(priceLast) .. " меньше цены заявки. " .. order.Print()
      )
      order.Price = priceLast + 10 * order.SecurityInfo.min_price_step
    end
  end

  --- Не выставляем заявку на продажу
  if order:IsSell() then
    local position = GetPosition(order.SecurityCode)
    if position == nil or position.currentbal < order.Quantity then
      log.info("Заблокировано выставление заявки на продажу. " .. order.Print())
      return false   
    end
  end

  --- Не выставляем заявку если объем заявки больше разрешенного лимита
  if order:IsBuy() then
    local limit = VolumeOrderLimit
    if order:IsSpb() then
      limit = VolumeOrderLimitUSD
    end
    if order:IsUsd() then
      limit = VolumeOrderLimitUSD
    end
    if order:GetVolume() > limit then
      log.info("Лимит заявки больше разрешенного ", limit, order.SecurityInfo.face_unit, order.Print())
      order:Clear()
      return false
    end
  end

  --- Не выставляем заявку если доходность меньше ожидаемого
  if order:IsBuy() then

    if order:IsExceptionFromLimitActuation() then 	    
      return true	  
    end
	
    local actuation = (tonumber(priceLast) - tonumber(order.Price)) / tonumber(order.Price) * 100
    local limit = LimitActuationOrderEdge
    if order:IsBond() and not order:IsOFZ() then
      limit = LimitActuationOrderBondEdge
    elseif order:IsForeign() then
      limit = LimitActuationOrderForeignEdge
    end

    if actuation ~= nil and tonumber(actuation) < tonumber(limit) then
      log.info(
        "Доходность инструмента меньше ",
        tostring(limit),
        "% (" .. string.format("%.2f", actuation) .. "%) : ",
        order.Print()
      )
      return false
    end
  end

  -- Не выставляем заявку если цена облигации больше номинала (100%)
  if order:IsBuy() then
    if order:IsBond() then
      local nominal = 100.0
      if tonumber(order.Price) > tonumber(nominal) then
        log.info("Цена облигации больше 100%. " .. order.Print())
        return false
      end
    end
  end
  
  
    -- Не выставляем заявку если последняя цена облигации больше номинала (100%)
  if order:IsBuy() then
    if order:IsBond() then
      local nominal = 100.0
      if tonumber(order.Price) > tonumber(nominal) then
        log.info("Последняя цена облигации больше 100%. " .. order.Print())
        return false
      end
    end
  end
  

  --- Не выставляем заявку если цена больше средней цены покупки по портфелю для не облигаций
  if order:IsBuy() and not order:IsBond() then
    local position = GetPosition(order.SecurityCode)
    if position ~= nil and tonumber(position.wa_position_price) < tonumber(order.Price) then
      if tonumber(position.wa_position_price) < tonumber(order.Price) then
        log.info(
          "Цена акции больше средней по портфелю " ..
            string.format("%.2f", position.wa_position_price) .. " " .. order.Print()
        )
        return false
      end
    end
  end

  --- Не выставляем заявку если цена больше средней цены покупки по портфелю для ОФЗ
  -- if order:IsBuy() and order:IsOFZ() then
    -- local position = GetPosition(order.SecurityCode)
    -- if position ~= nil and tonumber(position.wa_position_price) < tonumber(order.Price) then
      -- if tonumber(position.wa_position_price) < tonumber(order.Price) then
        -- log.info(
          -- "Цена ОФЗ больше средней по портфелю " ..
            -- string.format("%.2f", position.wa_position_price) .. " " .. order.Print()
        -- )
        -- return false
      -- end
    -- end
  -- end

  return true
end

function SetLimitOrdersWithError(trans)
  -- ОШИБКА: (579) Для выбранного финансового инструмента цена должна быть не меньше 916.0
  local error579 = string.find(trans.result_msg, ": (579)", 1, true)
  if (error579 ~= nil) then
    local priceMin = string.match(trans.result_msg, "%d+[%.]?%d+", -12)
    local operation = "B"
    local order = Order:new(trans.sec_code)
    local progressOrderVolumeMax = GetOrderVolumeMax(order, priceMin)
    order:SetQuantity(operation, priceMin, progressOrderVolumeMax)

    log.info("Повторно выставляем заявку на покупку с минимальной ценой: " .. order.Print())

    local orders = {}
    table.insert(orders, order)
    SubmitOrders(orders)

    return
  end

  -- ОШИБКА: (580) Для выбранного финансового инструмента цена должна быть не больше 0.08047
  local error580 = string.find(trans.result_msg, ": (580)", 1, true)
  if (error580 ~= nil) then
    local maxPrice = string.match(trans.result_msg, "%d+[%.]?%d+", -12)
    local operation = "S"
    local order = Order:new(trans.sec_code)
    order:SetOperation(operation, maxPrice, trans.quantity)
    log.info("Повторно выставляем заявку на продажу с максимльной ценой: " .. order.Print())

    local orders = {}
    table.insert(orders, order)
    SubmitOrders(orders)

    return
  end

  -- ОШИБКА: Цена заявки 5.000 не соответствует установленному диапазону от 2.967 до 4.943
  local errorTest = string.find(trans.result_msg, "не соответствует установленному диапазону", 1, true)
  if (errorTest ~= nil) then
    local minPrice = string.match(trans.result_msg, "%d+[%.]?%d+", -30)
    local operation = "B"
    local order = Order:new(trans.sec_code)
    order:SetOperation(operation, minPrice, 0)

    log.info("Выставляем заявку на покупку с минимальной ценой: " .. order.Print())

    return
  end

  log.error(string.format('Ошибка не обрабатывается. "%s', trans.result_msg))
  log.error(json.encode(trans))
end