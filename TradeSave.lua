
--Делаем запись в файле о новой сделке
function TradeSave(trade)
  -- Создает, или открывает для чтения/добавления файл CSV в той же папке, где находится данный скрипт
  fileMyTrades = io.open(getScriptPath().."//Data//MyTrades.csv", "a+");

  -- Вычисляет операцию сделки
  local Operation = "";
  if CheckBit(trade.flags, 2) == 1 then Operation = "-"; else Operation = ""; end;

  -- Создает строку сделки для записи в файл ("Дата и время;Код класса;Код бумаги;Номер сделки;Номер заявки;Операция;Цена;Количество\n")
  local TradeLine = 	os.date("%Y-%m-%d") .. " " .. os.date("%X",os.time()) ..";"..
    trade.sec_code..";"..
    Operation..trade.qty..";"..
    trade.price..";"..
    Broker.."\n";

  -- Записывает строку в файл
  fileMyTrades:write(TradeLine);

  -- Сохраняет изменения в файле
  fileMyTrades:flush();

  -- Закрывает открытый CSV-файл
  fileMyTrades:close();
end;


-- Функция возвращает значение бита (число 0, или 1) под номером bit (начинаются с 0) в числе flags, если такого бита нет, возвращает nil
function CheckBit(flags, bit)
  -- Проверяет, что переданные аргументы являются числами
  if type(flags) ~= "number" then error("Ошибка!!! Checkbit: 1-й аргумент не число!"); end;
  if type(bit) ~= "number" then error("Ошибка!!! Checkbit: 2-й аргумент не число!"); end;
  local RevBitsStr  = ""; -- Перевернутое (задом наперед) строковое представление двоичного представления переданного десятичного числа (flags)
  local Fmod = 0; -- Остаток от деления
  local Go = true; -- Флаг работы цикла
  while Go do
    Fmod = math.fmod(flags, 2); -- Остаток от деления
    flags = math.floor(flags/2); -- Оставляет для следующей итерации цикла только целую часть от деления
    RevBitsStr = RevBitsStr ..tostring(Fmod); -- Добавляет справа остаток от деления
    if flags == 0 then Go = false; end; -- Если был последний бит, завершает цикл
  end;
  -- Возвращает значение бита
  local Result = RevBitsStr :sub(bit+1,bit+1);
  if Result == "0" then return 0;
  elseif Result == "1" then return 1;
  else return nil;
  end;
end;
