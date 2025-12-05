-- Исправление ошибок в файле SubmittingOrders.lua

-- В строке 84: IsEvningTime -> IsEveningTime
-- В строке 85: eIsSentOrders -> IsSentOrders

-- Правильная версия функции SubmittingOrders:
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

  if (os.time(TimeEveningStart) < timeCurrent) and not IsEveningTime then  -- Исправлено: IsEvningTime -> IsEveningTime
    if IsSentOrders then  -- Исправлено: eIsSentOrders -> IsSentOrders
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