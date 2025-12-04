require("TableSetting")
--- Идентификатор брокера
Broker = ""
ClientCode = ""
AccountCode = ""
AccountCodeSpb = ""
FirmId = ""
VolumeOrderMin = 0
VolumeOrderMax = 0
BondVolumeOrderMax = 0
--- Максимальный объем заявки ОФЗ
OFZVolumeOrderMax = 0
--- Максимальный объем заявки
VolumeOrderLimit = 200000
--- Максимальный объем заявки в долларах
VolumeOrderLimitUSD = 100
--- Максимальный объем заявки иностранных бумаг в рублях
VolumeOrderLimitForeign = 70000

--- Минимальная допустимая доходность в процентах
LimitActuationOrderEdge = 5
--- Минимальная допустимая доходность облигаций в процентах
LimitActuationOrderBondEdge = 60
--- Минимальная допустимая доходность иностранных бумаг в процентах
LimitActuationOrderForeignEdge = 30

FileBuyOrder = ""
FileSellOrder = ""
FileBuyOrderEdge = ""
FileBuyOrderBondsEdge = ""
FileBuyOrderSpbEdge = ""
FileBuyOrderRmUsdEdge = ""

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

--- Устанавливаем настройки для брокера
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
