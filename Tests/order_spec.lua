-- Тесты для класса Order
local Order = require("../Order")

describe("Order tests", function()
  -- Тест создания нового объекта Order
  it("should create a new Order object", function()
    -- Создаем мок-объект для SecurityInfo, так как функция getSecurityInfo не будет работать в тесте
    local mockSecurityInfo = {
      class_code = "TQBR",
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    -- Мокаем функцию GetSecurityInfo, чтобы она возвращала наш мок
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("SBER")
    
    assert.truthy(order)
    assert.are.equal("SBER", order.SecurityCode)
    assert.are.equal("", order.Operation)
    assert.are.equal(0, order.Quantity)
    assert.are.equal(0, order.Price)
  end)

  -- Тест проверки, является ли бумага облигацией
  it("should identify if security is a bond", function()
    local mockSecurityInfo = {
      class_code = "TQOB", -- Класс облигаций
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("SU24019RMFS0")
    
    assert.truthy(order)
    assert.truthy(order:IsBond())
  end)

  -- Тест проверки, является ли бумага ETF
  it("should identify if security is an ETF", function()
    local mockSecurityInfo = {
      class_code = "TQTF", -- Класс ETF
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("FXUS")
    
    assert.truthy(order)
    assert.truthy(order:IsEtf())
  end)

  -- Тест проверки, является ли бумага SPB инструментом
  it("should identify if security is a SPB instrument", function()
    local mockSecurityInfo = {
      class_code = "SPBXM", -- Класс SPB
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("AAPL")
    
    assert.truthy(order)
    assert.truthy(order:IsSpb())
  end)

  -- Тест проверки операции покупки
  it("should identify if operation is buy", function()
    local mockSecurityInfo = {
      class_code = "TQBR",
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("SBER")
    order:SetOperation("B", 250.0, 10)
    
    assert.truthy(order)
    assert.truthy(order:IsBuy())
    assert.falsy(order:IsSell())
  end)

  -- Тест проверки операции продажи
  it("should identify if operation is sell", function()
    local mockSecurityInfo = {
      class_code = "TQBR",
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("SBER")
    order:SetOperation("S", 260.0, 10)
    
    assert.truthy(order)
    assert.truthy(order:IsSell())
    assert.falsy(order:IsBuy())
  end)

  -- Тест форматирования цены
  it("should format price correctly", function()
    local mockSecurityInfo = {
      class_code = "TQBR",
      scale = 2, -- 2 знака после запятой
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("SBER")
    order:SetOperation("B", 250.789, 10)
    
    assert.truthy(order)
    assert.are.equal("250.79", order:FormatPrice())
  end)

  -- Тест форматирования количества
  it("should format quantity correctly", function()
    local mockSecurityInfo = {
      class_code = "TQBR",
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("SBER")
    order.Quantity = 15.678
    
    assert.truthy(order)
    assert.are.equal("15.678", order:FormatQuantity(3))
    assert.are.equal("15.68", order:FormatQuantity(2))
    assert.are.equal("15.7", order:FormatQuantity(1))
    assert.are.equal("16", order:FormatQuantity(0))
  end)

  -- Тест расчета объема для акций
  it("should calculate volume for stocks correctly", function()
    local mockSecurityInfo = {
      class_code = "TQBR",
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("SBER")
    order:SetOperation("B", 250.0, 10) -- 10 лотов по 250 рублей
    
    assert.truthy(order)
    assert.are.equal(2500, order:GetVolume()) -- 10 лотов * 1 акция в лоте * 250 рублей = 2500
  end)

  -- Тест расчета объема для облигаций
  it("should calculate volume for bonds correctly", function()
    local mockSecurityInfo = {
      class_code = "TQOB",
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000 -- номинал облигации 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("SU24019RMFS0")
    order:SetOperation("B", 95.0, 5) -- 5 лотов по 95% от номинала
    
    assert.truthy(order)
    assert.are.equal(4750, order:GetVolume()) -- 5 лотов * 1 облигация в лоте * (95% * 1000 номинал) = 4750
  end)

  -- Тест метода SetOperation
  it("should set operation, price and quantity correctly", function()
    local mockSecurityInfo = {
      class_code = "TQBR",
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("SBER")
    
    assert.truthy(order)
    
    order:SetOperation("B", 250.567, 15)
    
    assert.are.equal("B", order.Operation)
    assert.are.equal(15, order.Quantity)
    assert.are.equal(250.57, order.Price) -- цена округлена до 2 знаков после запятой
  end)

  -- Тест проверки исключения из лимита доходности
  it("should identify if security is exception from limit actuation", function()
    local mockSecurityInfo = {
      class_code = "TQBR",
      scale = 2,
      min_price_step = 0.01,
      lot_size = 1,
      face_value = 1000
    }
    
    _G.GetSecurityInfo = function(securityCode)
      return mockSecurityInfo
    end
    
    _G.log = {
      error = function(msg) print("ERROR: " .. msg) end,
      debug = function(msg) print("DEBUG: " .. msg) end,
      info = function(msg) print("INFO: " .. msg) end,
      trace = function(msg) print("TRACE: " .. msg) end
    }
    
    local order = Order:new("GAZP")
    
    assert.truthy(order)
    assert.truthy(order:IsExceptionFromLimitActuation())
    
    local order2 = Order:new("AAPL")
    assert.truthy(order2)
    assert.falsy(order2:IsExceptionFromLimitActuation())
  end)
end)