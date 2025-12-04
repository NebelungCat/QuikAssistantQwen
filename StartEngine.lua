package.path = getScriptPath() .. "\\?.lua;"

require("Assistant")

log = require "log"

isRun = true
transId = os.time() -- Текущие дата и время в секундах хорошо подходят для уникальных номеров транзакций

N_TransReplies = {} -- Массив для хранения ответов по транзакциям
N_LastTransID = 0 -- Последний ID транзакции, ответ по которой был обработан и удален из массива
N_Orders = {} -- Массив для хранения информации о заявках
N_LastOrderNum = 0 -- Последний номер заявки, которая была обработана и удалена из массива
N_Trades = {} -- Массив для хранения информации о сделках
N_LastTradeNum = 0 -- Последний номер сделки, которая была обработана и удалена из массива

function main()
  -- Основной цикл
  while isRun do
    -- Выполняет предопределенную функцию итераций, если она объявлена
    if N_OnMainLoop ~= nil then
      N_OnMainLoop()
    end

    -- МОНИТОРИТ ИЗМЕНЕНИЯ

    -- Перебирает ОТВЕТЫ ПО ТРАНЗАКЦИЯМ
    for i, TransReplie in ipairs(N_TransReplies) do
      -- Если ответ еще не был учтен
      if N_TransReplies[i].checked == nil then
        -- Проверяет на наличие ошибок по транзакции
        if N_TransReplies[i].status > 1 and N_TransReplies[i].status ~= 3 then
          -- Если транзакция выполнена
          -- Вызывает функцию обратного вызова (если она объявлена)
          if N_OnTransExecutionError ~= nil then
            N_OnTransExecutionError(N_TransReplies[i])
          end
          -- Запоминает, что ответ был учтен
          N_TransReplies[i].checked = true
        elseif N_TransReplies[i].status == 3 then
          -- Вызывает функцию обратного вызова (если она объявлена)
          if N_OnTransOK ~= nil then
            N_OnTransOK(N_TransReplies[i])
          end
          -- Запоминает, что ответ был учтен
          N_TransReplies[i].checked = true
        end
      end
    end

    -- Перебирает ЗАЯВКИ
    for i, Order in ipairs(N_Orders) do
      -- Если выставление заявки еще не было учтено
      if N_Orders[i].checked == nil then
        -- Вызывает функцию обратного вызова (если она объявлена)
        if N_OnNewOrder ~= nil then
          N_OnNewOrder(N_Orders[i])
        end
        N_Orders[i].checked = true
      end
      -- Проверяет какое количество в заявке исполнено
      local ExecutionCount = N_Orders[i].qty - N_Orders[i].balance
      -- Если это первая проверка, или с предыдущей проверки количество изменилось и заявка частично, или полностью исполнена
      if
        (N_Orders[i].last_execution_count == nil or N_Orders[i].last_execution_count ~= ExecutionCount) and
          ExecutionCount > 0
      then
        -- Вызывает функцию обратного вызова (если она объявлена)
        if N_OnExecutionOrder ~= nil then
          N_OnExecutionOrder(N_Orders[i])
          -- Запоминает исполненное количество для последующего сравнения
          N_Orders[i].last_execution_count = ExecutionCount
        end
      end
    end

    -- Перебирает СДЕЛКИ
    for i, Trade in ipairs(N_Trades) do
      -- Если в сделке уже появилось поле с номером заявки, по которой она была совершена
      if N_Trades[i].order_num ~= nil then
        -- Перебирает заявки
        for j, Order in ipairs(N_Orders) do
          -- Если найдена заявка, по которой совершена сделка
          if N_Trades[i].order_num == N_Orders[j].order_num then
            -- Добавляет таблице сделки номер транзакции, которая инициировала данную сделку
            N_Trades[i].trans_id = N_Orders[j].trans_id
            -- Вызывает функцию обратного вызова (если она объявлена)
            if N_OnNewTrade ~= nil then
              N_OnNewTrade(N_Trades[i])
            end
            -- Запоминает номер последней обработанной сделки
            N_LastTradeNum = N_Trades[i].trade_num
            -- Удаляет сделку из массива, чтобы больше ее не обрабатывать
            table.sremove(N_Trades, i)
            -- Если заявка сделки полностью исполнена и обработана
            if N_Orders[j].last_execution_count ~= nil and N_Orders[j].last_execution_count == N_Orders[j].qty then
              -- Запоминает номер последней обработанной транзакции
              N_LastTransID = N_Orders[j].trans_id
              -- Удаляет ответ по транзакции из массива, чтобы больше ее не обрабатывать
              for k, TransReply in ipairs(N_TransReplies) do
                if TransReply.trans_id == N_Orders[j].trans_id then
                  table.sremove(N_TransReplies, k)
                  break
                end
              end
              -- Запоминает номер последней обработанной заявки
              N_LastOrderNum = N_Orders[j].order_num
              -- Удаляет заявку из массива, чтобы больше ее не обрабатывать
              table.sremove(N_Orders, j)
              -- Прерывает цикл по заявкам
              break
            end
          end
        end
      end
    end

    sleep(1000)
  end
end

-- Функция вызывается терминалом когда с сервера приходит ответ по транзакции
function OnTransReply(trans_reply)
  -- Если не относится к движку, выходит из функции
  --  if trans_reply.brokerref:find('N_'..SEC_CODE) == nil then return end
  -- Перебирает массив ответов по транзакциям
  for i, TransReply in ipairs(N_TransReplies) do
    -- Если если ответ по данной транзакции уже занесен в массив
    if N_TransReplies[i].trans_id == trans_reply.trans_id then
      -- Если появление ответа уже было учтено, сохраняет эту информацию
      if N_TransReplies[i].checked ~= nil then
        trans_reply.checked = true
      end
      -- Заменяет его в массиве
      table.sremove(N_TransReplies, i)
      table.sinsert(N_TransReplies, trans_reply)
      -- Выходит из функции
      return
    end
  end
  -- Ответ еще не был добавлен в массив, добавляет
  if N_LastTransID < trans_reply.trans_id then
    table.sinsert(N_TransReplies, trans_reply)
  end
end

-- Функция вызывается терминалом когда с сервера приходит информация по заявке
function OnOrder(order)
  -- Если не относится к движку, выходит из функции
  --  if order.brokerref:find('N_'..SEC_CODE) == nil then return end
  -- Перебирает массив заявок
  for i, Order in ipairs(N_Orders) do
    -- Если заявка уже занесена в массив
    if N_Orders[i].trans_id == order.trans_id then
      -- Если появление заявки уже было учтено, сохраняет эту информацию
      if N_Orders[i].checked ~= nil then
        order.checked = true
      end
      -- Если исполненное количество уже учитывалось, сохраняет эту информацию
      if N_Orders[i].last_execution_count ~= nil then
        order.last_execution_count = N_Orders[i].last_execution_count
      end
      -- Заменяет ее
      table.sremove(N_Orders, i)
      table.sinsert(N_Orders, order)
      -- Выходит из функции
      return
    end
  end
  -- Заявка еще не была добавлена в массив, добавляет
  if N_LastOrderNum < order.order_num then
    table.sinsert(N_Orders, order)
  end
end

-- Функция вызывается терминалом когда с сервера приходит информация по сделке
function OnTrade(trade)
  -- Если не относится к движку, выходит из функции
  --  if trade.brokerref:find('N_'..SEC_CODE) == nil then return end
  -- Перебирает массив сделок
  for i, Trade in ipairs(N_Trades) do
    -- Если данная сделка уже занесена в массив
    if N_Trades[i].trade_num == trade.trade_num then
      -- Если появление сделки уже было учтено, сохраняет эту информацию
      if N_Trades[i].checked ~= nil then
        trade.checked = true
      end
      -- Заменяет ее
      table.sremove(N_Trades, i)
      table.sinsert(N_Trades, trade)
      -- Выходит из функции
      return
    end
  end
  -- Сделка еще не была добавлена в массив, добавляет
  if N_LastTradeNum < trade.trade_num then
    table.sinsert(N_Trades, trade)
  end
end

function OnInit()
  if N_OnInit ~= nil then
    N_OnInit()
  end
end

-- Функция вызывается когда пользователь останавливает скрипт
function OnStop()
  isRun = false

  if N_OnStop ~= nil then
    N_OnStop()
  end
end

function OnClose()
  if N_OnClose ~= nil then
    N_OnClose()
    sleep(1000)
  end
end
