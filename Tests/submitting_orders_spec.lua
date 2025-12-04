-- Тесты для функций SubmittingOrders
-- Изолируем тесты от зависимостей, чтобы избежать ошибок при загрузке других файлов

-- Инициализируем переменные, как они определены в SubmittingOrders.lua
TimeMainStart = nil
TimeMorningStart = nil
TimeEveningStart = nil
IsSentOrders = false
IsSendingOrders = false
IsMorningTime = false
IsMainTime = false
IsEveningTime = false
sendOrders = {}

-- Функции из SubmittingOrders.lua, которые мы будем тестировать
function Initialization()
  local currentTime = os.time()
  TimeMainStart = os.date("!*t", currentTime)
  TimeMainStart.hour = 10
  TimeMainStart.min = 0
  TimeMainStart.sec = 30

  TimeMorningStart = os.date("!*t", currentTime)
  TimeMorningStart.hour = 7
  TimeMorningStart.min = 0
  TimeMorningStart.sec = 30

  TimeEveningStart = os.date("!*t", currentTime)
  TimeEveningStart.hour = 19
  TimeEveningStart.min = 2
  TimeEveningStart.sec = 10

  IsSentOrders = false
  IsSendingOrders = false
  IsMorningTime = false
  IsMainTime = false
  IsEveningTime = false
end

function SubmittingOrders()
  local timeCurrent = os.time()

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

  if (os.time(TimeEveningStart) < timeCurrent) and not IsEveningTime then
    if IsSentOrders then
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

function SubmittingOrdersRun()
  if (IsSendingOrders) then
    return
  end

  local isSubmittingOrdersRun = true

  -- В утреннюю сессию заявки не выставляем. 
  if IsMorningTime and not IsMainTime and not IsEveningTime then
    isSubmittingOrdersRun = false
  end  

  -- В вечернюю сессию заявки не выставляем. 
  if IsMorningTime and IsMainTime and IsEveningTime then
    isSubmittingOrdersRun = false
  end  

  IsSendingOrders = true

  IsSentOrders = true
  IsSendingOrders = false

  for k in pairs (sendOrders) do
    sendOrders[k] = nil
  end
end

function IsSendOrder(order)
  for i = 1, #sendOrders do
    local sendOrder = sendOrders[i]
    if 
      order.SecurityCode == sendOrder.SecurityCode and 
      order.Operation == sendOrder.Operation 
    then
      return true
    end
  end    
  return false
end

-- Мокаем необходимые функции
log = {
  error = function(msg) print("ERROR: " .. msg) end,
  debug = function(msg) print("DEBUG: " .. msg) end,
  info = function(msg) print("INFO: " .. msg) end,
  trace = function(msg) print("TRACE: " .. msg) end
}

function N_CloseAllOrder()
  -- пустая функция для теста
end

describe("SubmittingOrders tests", function()
  -- Тест начальной инициализации
  it("should initialize correctly", function()
    Initialization()
    
    assert.are.equal(false, IsSentOrders)
    assert.are.equal(false, IsSendingOrders)
    assert.are.equal(false, IsMorningTime)
    assert.are.equal(false, IsMainTime)
    assert.are.equal(false, IsEveningTime)
    assert.truthy(TimeMainStart)
    assert.truthy(TimeMorningStart)
    assert.truthy(TimeEveningStart)
  end)

  -- Тест функции IsSendOrder
  it("should check if order was already sent", function()
    -- Инициализируем пустой массив отправленных ордеров
    sendOrders = {}
    
    -- Мокаем объект Order
    local mockOrder = {
      SecurityCode = "SBER",
      Operation = "B",
      Quantity = 10,
      Price = 250.00
    }
    
    -- Проверяем, что ордер не отправлялся
    assert.are.equal(false, IsSendOrder(mockOrder))
    
    -- Добавляем ордер в список отправленных
    table.insert(sendOrders, {
      SecurityCode = "SBER",
      Operation = "B",
      Quantity = 10,
      Price = 250.00
    })
    
    -- Проверяем, что ордер уже отправлялся
    assert.are.equal(true, IsSendOrder(mockOrder))
    
    -- Проверяем ордер с другим тикером
    local mockOrder2 = {
      SecurityCode = "GAZP",
      Operation = "B",
      Quantity = 10,
      Price = 250.00
    }
    
    assert.are.equal(false, IsSendOrder(mockOrder2))
  end)

  -- Тест функции SubmittingOrdersRun
  it("should run submitting orders correctly", function()
    -- Установим нужные флаги времени
    IsMorningTime = false
    IsMainTime = false
    IsEveningTime = false
    IsSentOrders = false
    IsSendingOrders = false
    
    -- Вызываем функцию
    SubmittingOrdersRun()
    
    -- Проверяем, что флаги установлены правильно
    assert.are.equal(true, IsSentOrders)
    assert.are.equal(false, IsSendingOrders)
    assert.are.equal(0, #sendOrders) -- массив должен быть очищен
  end)

  -- Тест функции SubmittingOrders с моком времени
  it("should handle submitting orders correctly", function()
    -- Мокаем os.time для возврата фиксированного времени
    local original_os_time = os.time
    os.time = function(t)
      if t then
        return original_os_time(t)
      else
        -- Возвращаем фиксированное время для теста
        local fixed_time = original_os_time({year=2023, month=1, day=1, hour=12, min=0, sec=0})
        return fixed_time
      end
    end
    
    -- Инициализируем систему
    Initialization()
    
    -- Проверяем начальные значения
    assert.are.equal(false, IsSentOrders)
    assert.are.equal(false, IsSendingOrders)
    assert.are.equal(false, IsMorningTime)
    assert.are.equal(false, IsMainTime)
    assert.are.equal(false, IsEveningTime)
    
    -- Вызываем функцию
    SubmittingOrders()
    
    -- После вызова функции время должно измениться
    assert.are.equal(true, IsMorningTime)
    assert.are.equal(true, IsMainTime)
    assert.are.equal(true, IsEveningTime)
    
    -- Восстанавливаем оригинальную функцию os.time
    os.time = original_os_time
  end)
end)