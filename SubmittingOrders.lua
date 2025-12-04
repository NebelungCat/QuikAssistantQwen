require("Setting")
require("FileFunction")
require("Order")
require("QuikFunction")
require("TableOrders")

--- Время основной сессии выставления заявок
TimeMainStart = nil

--- Время утреннего выставления заявок
TimeMorningStart = nil

--- Время вечернего выставления заявок
TimeEveningStart = nil

--- Флаг, что заявки уже выставлены
IsSentOrders = false

--- Флаг, что сейчас происходит процесс выставления заявок
IsSendingOrders = false

--- Время утренней сессии
IsMorningTime = false

--- Время основной сессии
IsMainTime = false

--- Время вечерней сессии
IsEveningTime = false

sendOrders = {}


--- Начальное выставление параметров
function Initialization()
  SetClientSetting()

  TimeMainStart = os.date("!*t", os.time())
  TimeMainStart.hour = 10
  TimeMainStart.min = 0
  TimeMainStart.sec = 30

  TimeMorningStart = os.date("!*t", os.time())
  TimeMorningStart.hour = 7
  TimeMorningStart.min = 0
  TimeMorningStart.sec = 30

  TimeEveningStart = os.date("!*t", os.time())
  TimeEveningStart.hour = 19
  TimeEveningStart.min = 2
  TimeEveningStart.sec = 10

  IsSentOrders = false
  IsSendingOrders = false
  IsMorningTime = false
  IsMainTime = false
  IsEveningTime = false
end



--- Определяем время запуска процесса выставления заявок.
function SubmittingOrders()
  local timeCurrent = os.time()

  --log.info(string.format("%d:%d:%d", timeMorningStart.hour, timeMorningStart.min, timeMorningStart.sec))

  if (os.time(TimeMorningStart) < timeCurrent) and not IsMorningTime then
    if IsSentOrders then
      N_CloseAllOrder()
    end
    IsMorningTime = true
    IsSentOrders = false
  end

  if (os.time(TimeMainStart) < timeCurrent) and not IsMainTime then
    if IsSentOrders then
      N_CloseAllOrder()
    end
    IsMainTime = true
    IsSentOrders = false
  end

  if (os.time(TimeEveningStart) < timeCurrent) and not IsEvningTime then
    if eIsSentOrders then
      N_CloseAllOrder()
    end
    IsEveningTime = true
    IsSentOrders = false
  end

  if not IsSentOrders then
    if (os.time(TimeMorningStart) < timeCurrent) then
      log.debug("Начинаем процесс выставления заявок.")
      SubmittingOrdersRun()
    end
  end
end

--- Запускаем процесс выставления заявок.
function SubmittingOrdersRun()

  if (IsSendingOrders) then
    return
  end

  isSubmittingOrdersRun = true
  
--- В утреннюю сессию заявки не выставляем. 
  if IsMorningTime and not IsMainTime and not IsEveningTime then
    isSubmittingOrdersRun = false
  end  

  --- В вечернюю сессию заявки не выставляем. 
  if IsMorningTime and IsMainTime and IsEveningTime then
    isSubmittingOrdersRun = false
  end  

  IsSendingOrders = true

  -- log.debug("1. Считываем из QUIK уже имеющиеся заявки.")
  -- GetQuikOrders()

  log.debug("2. Выставляем заявки.")

  if isSubmittingOrdersRun then
    log.debug("2.1 Из файла с заявками ", FileBuyOrder)
    local orders = LoadOrdersFromFile(FileBuyOrder)
    SubmitOrders(orders)
    sleep(3000)
  end


  if isSubmittingOrdersRun then
    log.debug("2.2 Из файла с облигациями", FileBuyOrderBondsEdge)
    local orders = LoadOrdersFromFile(FileBuyOrderBondsEdge)
    SubmitOrders(orders)
    sleep(3000)
  end  
  

  if isSubmittingOrdersRun then
    local orders = LoadOrdersFromFile(FileBuyOrderEdge)
    log.debug("2.3 Из файла по минимальным ценам", FileBuyOrderEdge)
    SubmitOrders(orders)
    sleep(1000)
  end      

  
---  log.debug("2.4 Из файла с иностранными бумагами Мосбиржи", FileBuyOrderRmUsdEdge)
---  local orders = LoadOrdersFromFile(FileBuyOrderRmUsdEdge)
---  SubmitOrders(orders)
---
---  log.debug("2.5 Из файла с иностранными бумагами СПБ-биржи", FileBuyOrderSpbEdge)
---  local orders = LoadOrdersFromFile(FileBuyOrderSpbEdge)
---  SubmitOrders(orders)

  log.debug("2.7 Из файла с продажами", FileSellOrder)
  local orders = LoadOrdersFromFile(FileSellOrder)
  SubmitOrders(orders)

  IsSentOrders = true
  IsSendingOrders = false

  for k in pairs (sendOrders) do
    sendOrders[k] = nil
  end

end

---Считываем заявки из файла.
function LoadOrdersFromFile(fileName)
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
            order:SetQuantity(operation, priceMin, progressOrderVolumeMax)
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

--- Отправка заявок на биржу
function SubmitOrders(orders)
  for i, order in pairs(orders) do
    --log.debug(i, order:FormatPrice(), order:FormatQuantity(), order.Print())
    local isSendOrder = IsSendOrder(order)
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
        local logOrder = {}
        logOrder.SecurityCode = order.SecurityInfo.code
        logOrder.Operation = order.Operation
        logOrder.Quantity = order:FormatQuantity()
        logOrder.Price = order:FormatPrice()
        --log.error("Сохраняем заявку в буфере: ", logOrder.Print())
        table.insert(sendOrders, logOrder)  
      end
    end
  end
end


--Проверяем отправляли ли уже ордер
function IsSendOrder(order)
  for i = 1, #sendOrders do
    local sendOrder = sendOrders[i]
    if 
      order.SecurityInfo.code == sendOrder.SecurityCode and 
      order.Operation == sendOrder.Operation --and
      --tonumber(order.Quantity) == tonumber(sendOrder.Quantity) and
      --tonumber(order.Price) == tonumber(sendOrder.Price) 
    then
      log.error("Нашли заявку в буфере: ", order.Print())
      return true
    end
  end    
  return false
end

-- Выставляет заявку на продажу только что купленной по минимальной цене бумаге
function TradeClosePosition(trade)
  local orders = {}
  local operation = "S"
  local securityCode = trade.seccode
  local quantity = tonumber(trade.qty)
  local price = tonumber(trade.price) * 100
  local order = Order:new(securityCode)

  log.info("Выставляем заявку на продажу только что купленной бумаги ", order:Print())

  if (order == nil) then
    log.error("Не удалось распознать  бумагу " .. json.encode(trade))
  else
      -- local priceMin = GetPriceMin(order)
      -- if tonumber(priceMin) ~= 0 and tonumber(trade.price) == tonumber(priceMin) then
        order:SetOperation(operation, price, quantity)
        table.insert(orders, order)
      -- else  
      --   log.info("Обратную заявку не выставляем, т.к. сделка была не по минимальной цене ", trade.price, priceMin)
      -- end
  end

  SubmitOrders(orders)
end
