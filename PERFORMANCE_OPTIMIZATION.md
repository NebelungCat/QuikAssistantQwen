# Оптимизация производительности торгового ассистента для QUIK

## Обзор проекта

Это система автоматической торговли, интегрированная с торговой платформой QUIK. Ассистент анализирует рыночные данные и автоматически отправляет заявки на покупку и продажу ценных бумаг.

## Проблемы производительности и рекомендации по оптимизации

### 1. Оптимизация работы с CSV-файлами

#### Проблема:
- Функция `getFromCSV` в `FileFunction.lua` читает файлы построчно, что может быть медленно для больших файлов
- Повторное чтение одних и тех же файлов без кэширования

#### Рекомендации:
- Реализовать кэширование CSV-файлов
- Добавить проверку изменений файлов перед перечитыванием
- Использовать более эффективные методы парсинга

```lua
-- Оптимизированная версия функции getFromCSV
local csv_cache = {}
local file_times = {}

function getFromCSV(nameFileCSV)
  local path = getScriptPath().. "//Data//" .. nameFileCSV
  local file_time = os.time(io.open(path, "r"):seek("end"))
  
  -- Проверяем, изменился ли файл
  if csv_cache[path] and file_times[path] == file_time then
    return csv_cache[path]
  end
  
  local result = {}
  local fileCSV = csv.open(path)
  
  if fileCSV ~= nil then
    for r in fileCSV:lines() do
      local r2 = {}
      for i, v in ipairs(r) do
        r2[#r2 + 1] = tostring(v)
      end
      result[#result + 1] = r2
    end
  end
  
  -- Кэшируем результат
  csv_cache[path] = result
  file_times[path] = file_time
  
  return result
end
```

### 2. Кэширование информации об инструментах

#### Проблема:
- Функция `GetSecurityInfo` в `Order.lua` проходит по списку классов для каждого инструмента
- Множество вызовов `getSecurityInfo` API QUIK

#### Рекомендации:
- Реализовать кэширование результатов `getSecurityInfo`
- Создать индекс по кодам инструментов

```lua
-- Кэш информации об инструментах
local security_cache = {}
local class_codes = {"TQCB", "TQBR", "SPBXM", "EQOB", "TQIR", "TQRD", "TQOB", "FQBR", "TQTF", "TQPI", "MTQR"}

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
```

### 3. Оптимизация отправки ордеров

#### Проблема:
- Функция `SubmittingOrdersRun` использует `sleep()` вызовы, блокирующие выполнение
- Повторная проверка уже отправленных ордеров

#### Рекомендации:
- Уменьшить или заменить `sleep()` на более эффективные задержки
- Использовать индексированные структуры для проверки отправленных ордеров

```lua
-- Оптимизированная структура для отслеживания отправленных ордеров
local sent_orders_index = {} -- индекс в формате "securityCode_operation" -> true

-- Проверка отправленных ордеров
function IsSendOrder(order)
  local key = order.SecurityInfo.code .. "_" .. order.Operation
  return sent_orders_index[key] == true
end

-- Добавление отправленного ордера в индекс
function AddSentOrder(order)
  local key = order.SecurityInfo.code .. "_" .. order.Operation
  sent_orders_index[key] = true
end
```

### 4. Оптимизация работы с таблицами

#### Проблема:
- Функция `RefreshTableOrdersControl` каждый раз перестраивает всю таблицу
- Множество вызовов `SetCell` по отдельности

#### Рекомендации:
- Использовать батчевые обновления таблиц
- Кэшировать результаты поиска ордеров

```lua
-- Оптимизированная функция обновления таблицы
function RefreshTableOrdersControl()
  if tableOrdersControl == nil then
    tableOrdersControl = QTable.new()
    CreateTableOrdersControl(tableOrdersControl)
    ShowTableOrdersControl(tableOrdersControl)
  end

  if tableOrdersControl:IsClosed() then
    ShowTableOrdersControl(tableOrdersControl)
  end

  -- Блокируем обновление UI во время заполнения
  tableOrdersControl:LockWindowUpdate()
  
  -- Очищаем таблицу и заполняем заново
  tableOrdersControl:Clear()
  
  local countOrders = getNumberOf("orders")
  local orders = SearchItems("orders", 0, countOrders - 1, FindOrder, "flags, sec_code, class_code")
  
  if orders ~= nil then
    for i = 1, #orders do
      local order = getItem("orders", orders[i])
      UpdateTableOrdersControl(tableOrdersControl, order)
    end
  end
  
  -- Разблокируем обновление UI
  tableOrdersControl:UnlockWindowUpdate()
end
```

### 5. Оптимизация поиска ордеров

#### Проблема:
- Функция `FindRow` в `TableOrdersControl` использует линейный поиск по всем строкам
- Повторяющиеся вызовы `FindRow` при обновлении таблицы

#### Рекомендации:
- Создать индекс по номерам ордеров
- Использовать хэш-таблицы для быстрого поиска

```lua
-- Индекс для быстрого поиска строк по номеру ордера
local order_row_index = {}

function FindRow(t, orderNum)
  if orderNum ~= nil then
    return order_row_index[tonumber(orderNum)]
  end
  return nil
end

function UpdateTableOrdersControl(t, order)
  local secInfo = GetSecurityInfo(order.sec_code)
  if secInfo == nil then
    return
  end
  
  local priceLast = GetPriceCurrent(order.class_code, order.sec_code)
  local operation = GetOrderOperation(order)
  local actuation = (tonumber(priceLast) - tonumber(order.price)) / tonumber(order.price) * 100
  local lastChange = getParamEx(order.class_code, order.sec_code, "LASTCHANGE").param_value

  local row = FindRow(t, order.order_num)
  if row == nil then
    row = t:AddLine()
    -- Обновляем индекс
    order_row_index[order.order_num] = row
  end

  -- Устанавливаем значения ячеек
  SetCell(t.t_id, row, 1, secInfo.name)
  SetCell(t.t_id, row, 2, order.sec_code)
  SetCell(t.t_id, row, 3, operation)
  SetCell(t.t_id, row, 4, string.format("%.2f", actuation))
  SetCell(t.t_id, row, 5, format_num(tonumber(priceLast), 6))
  SetCell(t.t_id, row, 6, format_num(tonumber(order.price), 6))
  SetCell(t.t_id, row, 7, format_num(tonumber(order.qty)))
  SetCell(t.t_id, row, 8, format_num(tonumber(order.value), 2))
  SetCell(t.t_id, row, 9, string.format("%.2f", lastChange))
  SetCell(t.t_id, row, 10, string.format("%i", order.order_num))

  -- Подцветка
  if (math.abs(actuation) < 2) then
    t:Red(row, 4)
  elseif (math.abs(actuation) < 5) then
    t:Yellow(row, 4)
  else
    t:Default(row, 4)
  end

  if IsOrderExecuted(order.flags) then
    t:Green(row, QTABLE_NO_INDEX)
  end
end
```

### 6. Оптимизация работы с ценами и округлением

#### Проблема:
- Множество вызовов `math.round` и `math.ceil`/`math.floor`
- Повторяющиеся вычисления при округлении цен

#### Рекомендации:
- Кэшировать результаты округления для часто используемых значений
- Оптимизировать алгоритмы округления

```lua
-- Кэш для округленных цен
local price_round_cache = {}

function Order:GetPriceRound()
  local cache_key = string.format("%.6f_%s_%s", obj.Price, obj.SecurityInfo.min_price_step, obj.Operation)
  
  if price_round_cache[cache_key] then
    obj.Price = price_round_cache[cache_key]
    return
  end
  
  local price = math.round(obj.Price, obj.SecurityInfo.scale)
  
  if price == nil then
    price = 0
  end

  if obj:IsBuy() then
    price = math.ceil(price / obj.SecurityInfo.min_price_step) * obj.SecurityInfo.min_price_step
  elseif obj:IsSell() then
    price = math.floor(price / obj.SecurityInfo.min_price_step) * obj.SecurityInfo.min_price_step
  else
    price = 0
  end
  
  -- Сохраняем в кэш
  price_round_cache[cache_key] = price
  obj.Price = price
end
```

### 7. Оптимизация строковых операций

#### Проблема:
- Повторяющиеся строковые операции при формировании логов и сообщений
- Использование `string.format` в циклах

#### Рекомендации:
- Использовать конкатенацию строк вместо `string.format` для простых случаев
- Кэшировать часто используемые строки

### 8. Оптимизация циклов и вызовов API

#### Проблема:
- Вызовы API QUIK в циклах могут быть медленными
- Повторяющиеся проверки одних и тех же условий

#### Рекомендации:
- Группировать вызовы API когда это возможно
- Кэшировать результаты вызовов API на короткий промежуток времени

## Дополнительные рекомендации

### 1. Мониторинг производительности
- Добавить тайминги к основным операциям
- Логировать время выполнения критических функций

### 2. Асинхронные операции
- Рассмотреть возможность асинхронной обработки данных
- Использовать таймеры вместо блокирующих вызовов

### 3. Оптимизация памяти
- Удалять ненужные объекты из памяти
- Использовать слабые таблицы для кэшей

### 4. Проверка ошибок
- Уменьшить количество проверок в критических путях
- Использовать более быстрые методы проверки условий

Эти оптимизации должны значительно улучшить производительность торгового ассистента, особенно при работе с большими объемами данных и частыми операциями.