require("SubmittingOrders")
require("TableConstructor")
require("TradeSave")

json = require "json"

function N_OnInit()
  if isConnected() == 0 then
    log.error("N_OnInit() Клиентское место не подключено")
    return
  end
  -- Здесь Ваш код
  Initialization()
  UpdateTableSetting()
  RefreshTableOrdersControl()
  log.debug("N_OnInit() Инициализация скрипта")
end

-- Функция выполняется при каждой итерации цикла while в функции main
function N_OnMainLoop()
  if not isConnected() == 0 then
    log.error("N_OnMainLoop() Клиентское место не подключено")
    return
  end
  SubmittingOrders()
  RefreshDataToTableSetting(tableSetting)
  RefreshTableOrdersControl()
end

-- Функция вызывается когда пользователь останавливает скрипт
function N_OnStop()
  -- Здесь Ваш код
  tableSetting:Delete()
  tableOrdersControl:Delete()
  -- Выводит сообщение
  log.debug("N_OnStop() Пользователь останавливает скрипт")
end

function N_OnClose()
  -- Здесь Ваш код
  -- ...
  -- Выводит сообщение
  log.debug("N_OnClose() Терминал закрывается")
end

-- Вызывается движком при ОШИБКЕ отправки ТРАНЗАКЦИИ
function N_OnTransSendError(trans)
  -- Здесь Ваш код для действий при ошибке отправки транзакции (возможно повторная отправка транзакции)
  -- ...
  -- Выводит сообщение
  log.debug("N_OnTransSendError() ОШИБКА отправки транзакции №" .. trans.trans_id .. ": " .. trans.result_msg)
  log.trace(json.encode(trans))
end

-- Вызывается движком при ОШИБКЕ выполнения ТРАНЗАКЦИИ
function N_OnTransExecutionError(trans)
  -- Здесь Ваш код для действий при ошибке выполнения транзакции (возможно повторная отправка транзакции)
  SetLimitOrdersWithError(trans)
  -- Выводит сообщение
  log.debug(
    "N_OnTransExecutionError() ОШИБКА выполнения транзакции №" ..
      trans.trans_id ..
        ": " ..
          trans.result_msg ..
            " (Код бумаги " .. trans.sec_code .. ", Количество " .. trans.quantity .. ", Цена " .. trans.price .. ")"
  )
  log.trace(json.encode(trans))
end

-- Вызывается движком при успешном ВЫПОЛНЕНИИ ТРАНЗАКЦИИ
function N_OnTransOK(trans)
  -- Здесь Ваш код для действий при успешном выполнении транзакции
  -- ...
  -- Выводит сообщение
  log.debug("N_OnTransOK() Транзакция №" .. trans.trans_id .. " УСПЕШНО выполнена")
  log.trace(json.encode(trans))
end

-- Вызывается движком при появлении НОВОЙ ЗАЯВКИ
function N_OnNewOrder(order)
  -- Здесь Ваш код для действий при появлении новой заявки
  -- ...
  -- Выводит сообщение
  log.debug(
    "N_OnNewOrder() Выставлена новая заявка №" ..
      order.order_num ..
        " по транзакции №" ..
          order.trans_id ..
            ", инструмент: " .. order.sec_code .. ", цена: " .. order.price .. ", количество: " .. order.qty
  )
  log.trace(json.encode(order))
end

-- Вызывается движком при полном, или частичном ИСПОЛНЕНИИ ЗАЯВКИ
function N_OnExecutionOrder(order)
  -- Здесь Ваш код для действий при полном, или частичном исполнении заявки
  -- ...
  -- Выводит сообщение
  log.debug(
    "N_OnExecutionOrder() БАЛАНС заявки №" ..
      order.order_num .. " изменился с " .. (order.qty - (order.last_execution_count or 0)) .. " на " .. order.balance
  )
  log.trace(json.encode(order))
end

-- Вызывается движком при появлении НОВОЙ СДЕЛКИ
function N_OnNewTrade(trade)
  -- Здесь Ваш код для действий при появлении новой сделки
  TradeSave(trade)

  --Создать заявку на зарытие позиции
  TradeClosePosition(trade)

  -- Выводит сообщение
  log.debug(
    "N_OnNewTrade() Новая СДЕЛКА №" ..
      trade.trade_num .. " по транзакции №" .. trade.trans_id .. " по цене " .. trade.price .. " объемом " .. trade.qty
  )
  log.trace(json.encode(trade))
end

-- Выставляет лимитированную заявку
function N_SetLimitOrder(
  accountCode,
  clientCode,
  classCode,
  securiyCode,
  operation, -- Операция ('B' - buy, 'S' - sell)
  price,
  quantity)
  -- Выставляет лимитированную заявку
  -- Получает ID для следующей транзакции
  transId = transId + 1
  -- Заполняет структуру для отправки транзакции
  local Transaction = {
    ["TRANS_ID"] = tostring(transId), -- Номер транзакции
    ["ACCOUNT"] = accountCode, -- Код счета
    ["CLASSCODE"] = classCode, -- Код класса
    ["SECCODE"] = securiyCode, -- Код инструмента
    ["ACTION"] = "NEW_ORDER", -- Тип транзакции ('NEW_ORDER' - новая заявка)
    ["TYPE"] = "L", -- Тип ('L' - лимитированная, 'M' - рыночная)
    ["OPERATION"] = operation, -- Операция ('B' - buy, или 'S' - sell)
    ["PRICE"] = price, -- Цена
    ["QUANTITY"] = quantity, -- Количество
    ["CLIENT_CODE"] = clientCode -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках в поле brokerref
  }

  log.trace(json.encode(Transaction))

  -- Отправляет транзакцию
  local Res = sendTransaction(Transaction)
  -- Если при отправке транзакции возникла ошибка
  if Res ~= "" then
    -- Вызывает функцию обратного вызова (если она объявлена)
    if N_OnTransSendError ~= nil then
      local trans = {}
      trans.trans_id = transId
      trans.transaction = Transaction
      trans.result_msg = Res
      N_OnTransSendError(trans)
    end
    -- Возвращает номер транзакции и сообщение об ошибке
    return transId, Res
  end
  -- Если транзакция отправлена, возвращает ее номер
  return transId, Res
end

--- Снятие всех заявок
function N_CloseAllOrder()
  function myFind(F)
    return (bit.band(F, 0x1) ~= 0)
  end
  local ord = "orders"
  local orders = SearchItems(ord, 0, getNumberOf(ord) - 1, myFind, "flags")
  if (orders ~= nil) and (#orders > 0) then
    for i = 1, #orders do
      local transaction = {
        TRANS_ID = tostring(transId),
        ACTION = "KILL_ORDER",
        CLASSCODE = getItem(ord, orders[i]).class_code,
        SECCODE = getItem(ord, orders[i]).sec_code,
        ORDER_KEY = tostring(getItem(ord, orders[i]).order_num)
      }
      local res = sendTransaction(transaction)
    end
  end
  tableOrdersControl:Clear()
end
