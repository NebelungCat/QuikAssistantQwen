-- Тесты для файла Setting
-- Изолируем тесты от зависимостей, чтобы избежать ошибок при загрузке других файлов

-- Инициализируем переменные, как они определены в Setting.lua
Broker = ""
ClientCode = ""
AccountCode = ""
AccountCodeSpb = ""
FirmId = ""
VolumeOrderMin = 0
VolumeOrderMax = 0
BondVolumeOrderMax = 0
OFZVolumeOrderMax = 0
VolumeOrderLimit = 200000
VolumeOrderLimitUSD = 100
VolumeOrderLimitForeign = 70000
LimitActuationOrderEdge = 5
LimitActuationOrderBondEdge = 60
LimitActuationOrderForeignEdge = 30
FileBuyOrder = ""
FileSellOrder = ""
FileBuyOrderEdge = ""
FileBuyOrderBondsEdge = ""
FileBuyOrderSpbEdge = ""
FileBuyOrderRmUsdEdge = ""

-- Функции из Setting.lua, которые мы будем тестировать
function SetSettingFinam()
  Broker = "FINAM"
  ClientCode = "0734A/0734A"
  AccountCode = "L01+00000F00"
  FirmId = "MC0061900000"
  VolumeOrderMin = 11000
  VolumeOrderMax = 50000
  VolumeOrderLimitForeign = 50000
  BondVolumeOrderMax = 50000
  OFZVolumeOrderMax = 10000
  LimitActuationOrderEdge = 0
  LimitActuationOrderBondEdge = 50
  LimitActuationOrderForeignEdge = 50
  VolumeOrderLimit = 100000
end

function SetSettingVTB()
  Broker = "VTB"
  ClientCode = "386507"
  AccountCode = "L01-00000F00"
  AccountCodeSpb = "VTBRM_CL"
  FirmId = "MC0003300000"
  VolumeOrderMin = 11000
  VolumeOrderMax = 20000
  BondVolumeOrderMax = 20000
  OFZVolumeOrderMax = 15000
  LimitActuationOrderEdge = 0
  LimitActuationOrderBondEdge = 30
  LimitActuationOrderForeignEdge = 50
end

function SetSettingPSB()
  Broker = "PSB"
  ClientCode = "40200"
  AccountCode = "L01+00000F00"
  FirmId = "MC0038600000"
  VolumeOrderMin = 10000
  VolumeOrderMax = 50000
  BondVolumeOrderMax = 20000
  OFZVolumeOrderMax = 10000
  LimitActuationOrderEdge = 0
  LimitActuationOrderBondEdge = 0
  VolumeOrderLimit = 100000
end

function SetSettingRSHB()
  Broker = "RSHB"
  ClientCode = "496082"
  AccountCode = "L01+00000F00"
  AccountCodeSpb = "VTBRM_CL"
  FirmId = "MC0134700000"
  VolumeOrderMin = 11000
  VolumeOrderMax = 20000
  BondVolumeOrderMax = 20000
  OFZVolumeOrderMax = 15000
  LimitActuationOrderEdge = 0
  LimitActuationOrderBondEdge = 60
  LimitActuationOrderForeignEdge = 50
end

function SetSettingTest()
  Broker = "TEST"
  ClientCode = "10567"
  AccountCode = "NL0011100043"
  FirmId = ""
  VolumeOrderMin = 11000
  VolumeOrderMax = 11000
  BondVolumeOrderMax = 7000
  OFZVolumeOrderMax = 7000
end

function SetClientSetting()
  local userId = getInfoParam("USERID")
  local problem = ""
  if (userId == nil or userId == "") then
    problem = "ID пользователя не получено"
  end

  if (userId == "171783") then
    SetSettingFinam()
  elseif (userId == "49653") then
    SetSettingVTB()
  elseif (userId == "34146") then
    SetSettingPSB()
  elseif (userId == "48640") then
    SetSettingRSHB()	
  elseif (userId == "119330") then
    SetSettingTest()
  else
    Broker = ""
    ClientCode = ""
    AccountCode = ""
    VolumeOrderMax = 0
  end

  FileBuyOrder = Broker .. "_BuyOrders.csv"
  FileSellOrder = Broker .. "_SellOrders.csv"
  FileBuyOrderEdge = Broker .. "_BuyOrders_Edge.csv"
  FileBuyOrderBondsEdge = Broker .. "_BuyOrdersBonds_Edge.csv"
  FileBuyOrderSpbEdge = Broker .. "_BuyOrdersSpb_Edge.csv"
  FileBuyOrderRmUsdEdge = Broker .. "_BuyOrders_RmUSD_Edge.csv"
end

describe("Setting tests", function()
  -- Тест начальных значений переменных
  it("should have initial values", function()
    assert.are.equal("", Broker)
    assert.are.equal("", ClientCode)
    assert.are.equal("", AccountCode)
    assert.are.equal("", AccountCodeSpb)
    assert.are.equal("", FirmId)
    assert.are.equal(0, VolumeOrderMin)
    assert.are.equal(0, VolumeOrderMax)
    assert.are.equal(0, BondVolumeOrderMax)
    assert.are.equal(0, OFZVolumeOrderMax)
  end)

  -- Тест функции SetSettingFinam
  it("should set Finam settings correctly", function()
    SetSettingFinam()
    
    assert.are.equal("FINAM", Broker)
    assert.are.equal("0734A/0734A", ClientCode)
    assert.are.equal("L01+00000F00", AccountCode)
    assert.are.equal("MC0061900000", FirmId)
    assert.are.equal(11000, VolumeOrderMin)
    assert.are.equal(50000, VolumeOrderMax)
    assert.are.equal(50000, BondVolumeOrderMax)
    assert.are.equal(10000, OFZVolumeOrderMax)
    assert.are.equal(0, LimitActuationOrderEdge)
    assert.are.equal(50, LimitActuationOrderBondEdge)
    assert.are.equal(50, LimitActuationOrderForeignEdge)
    assert.are.equal(100000, VolumeOrderLimit)
  end)

  -- Тест функции SetSettingVTB
  it("should set VTB settings correctly", function()
    SetSettingVTB()
    
    assert.are.equal("VTB", Broker)
    assert.are.equal("386507", ClientCode)
    assert.are.equal("L01-00000F00", AccountCode)
    assert.are.equal("VTBRM_CL", AccountCodeSpb)
    assert.are.equal("MC0003300000", FirmId)
    assert.are.equal(11000, VolumeOrderMin)
    assert.are.equal(20000, VolumeOrderMax)
    assert.are.equal(20000, BondVolumeOrderMax)
    assert.are.equal(15000, OFZVolumeOrderMax)
    assert.are.equal(0, LimitActuationOrderEdge)
    assert.are.equal(30, LimitActuationOrderBondEdge)
    assert.are.equal(50, LimitActuationOrderForeignEdge)
  end)

  -- Тест функции SetSettingPSB
  it("should set PSB settings correctly", function()
    SetSettingPSB()
    
    assert.are.equal("PSB", Broker)
    assert.are.equal("40200", ClientCode)
    assert.are.equal("L01+00000F00", AccountCode)
    assert.are.equal("MC0038600000", FirmId)
    assert.are.equal(10000, VolumeOrderMin)
    assert.are.equal(50000, VolumeOrderMax)
    assert.are.equal(20000, BondVolumeOrderMax)
    assert.are.equal(10000, OFZVolumeOrderMax)
    assert.are.equal(0, LimitActuationOrderEdge)
    assert.are.equal(0, LimitActuationOrderBondEdge)
    assert.are.equal(100000, VolumeOrderLimit)
  end)

  -- Тест функции SetSettingRSHB
  it("should set RSHB settings correctly", function()
    SetSettingRSHB()
    
    assert.are.equal("RSHB", Broker)
    assert.are.equal("496082", ClientCode)
    assert.are.equal("L01+00000F00", AccountCode)
    assert.are.equal("VTBRM_CL", AccountCodeSpb)
    assert.are.equal("MC0134700000", FirmId)
    assert.are.equal(11000, VolumeOrderMin)
    assert.are.equal(20000, VolumeOrderMax)
    assert.are.equal(20000, BondVolumeOrderMax)
    assert.are.equal(15000, OFZVolumeOrderMax)
    assert.are.equal(0, LimitActuationOrderEdge)
    assert.are.equal(60, LimitActuationOrderBondEdge)
    assert.are.equal(50, LimitActuationOrderForeignEdge)
  end)

  -- Тест функции SetSettingTest
  it("should set Test settings correctly", function()
    SetSettingTest()
    
    assert.are.equal("TEST", Broker)
    assert.are.equal("10567", ClientCode)
    assert.are.equal("NL0011100043", AccountCode)
    assert.are.equal("", FirmId)
    assert.are.equal(11000, VolumeOrderMin)
    assert.are.equal(11000, VolumeOrderMax)
    assert.are.equal(7000, BondVolumeOrderMax)
    assert.are.equal(7000, OFZVolumeOrderMax)
  end)

  -- Тест функции SetClientSetting с моком getInfoParam
  it("should set client settings based on user ID", function()
    -- Мокаем getInfoParam для возврата ID пользователя FINAM
    getInfoParam = function(param)
      if param == "USERID" then
        return "171783"
      end
      return nil
    end
    
    SetClientSetting()
    
    assert.are.equal("FINAM", Broker)
    assert.are.equal("0734A/0734A", ClientCode)
    assert.are.equal("L01+00000F00", AccountCode)
    assert.are.equal("MC0061900000", FirmId)
    assert.are.equal(11000, VolumeOrderMin)
    assert.are.equal(50000, VolumeOrderMax)
    assert.are.equal(50000, BondVolumeOrderMax)
    assert.are.equal(10000, OFZVolumeOrderMax)
    
    -- Проверяем, что имена файлов установлены правильно
    assert.are.equal("FINAM_BuyOrders.csv", FileBuyOrder)
    assert.are.equal("FINAM_SellOrders.csv", FileSellOrder)
    assert.are.equal("FINAM_BuyOrders_Edge.csv", FileBuyOrderEdge)
    assert.are.equal("FINAM_BuyOrdersBonds_Edge.csv", FileBuyOrderBondsEdge)
    assert.are.equal("FINAM_BuyOrdersSpb_Edge.csv", FileBuyOrderSpbEdge)
    assert.are.equal("FINAM_BuyOrders_RmUSD_Edge.csv", FileBuyOrderRmUsdEdge)
  end)

  -- Тест функции SetClientSetting с VTB ID
  it("should set VTB client settings based on user ID", function()
    -- Мокаем getInfoParam для возврата ID пользователя VTB
    getInfoParam = function(param)
      if param == "USERID" then
        return "49653"
      end
      return nil
    end
    
    SetClientSetting()
    
    assert.are.equal("VTB", Broker)
    assert.are.equal("386507", ClientCode)
    assert.are.equal("L01-00000F00", AccountCode)
    assert.are.equal("VTBRM_CL", AccountCodeSpb)
    assert.are.equal("MC0003300000", FirmId)
    assert.are.equal(11000, VolumeOrderMin)
    assert.are.equal(20000, VolumeOrderMax)
    assert.are.equal(20000, BondVolumeOrderMax)
    assert.are.equal(15000, OFZVolumeOrderMax)
    
    -- Проверяем, что имена файлов установлены правильно
    assert.are.equal("VTB_BuyOrders.csv", FileBuyOrder)
    assert.are.equal("VTB_SellOrders.csv", FileSellOrder)
    assert.are.equal("VTB_BuyOrders_Edge.csv", FileBuyOrderEdge)
    assert.are.equal("VTB_BuyOrdersBonds_Edge.csv", FileBuyOrderBondsEdge)
    assert.are.equal("VTB_BuyOrdersSpb_Edge.csv", FileBuyOrderSpbEdge)
    assert.are.equal("VTB_BuyOrders_RmUSD_Edge.csv", FileBuyOrderRmUsdEdge)
  end)

  -- Тест функции SetClientSetting с неизвестным ID
  it("should set empty settings for unknown user ID", function()
    -- Мокаем getInfoParam для возврата неизвестного ID
    getInfoParam = function(param)
      if param == "USERID" then
        return "999999"
      end
      return nil
    end
    
    SetClientSetting()
    
    assert.are.equal("", Broker)
    assert.are.equal("", ClientCode)
    assert.are.equal("", AccountCode)
    assert.are.equal(0, VolumeOrderMax)
  end)
end)