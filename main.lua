-- Скрипт для генерации ссылки приглашения на сервер в Roblox
-- Инжектируется через Delta X или другой инжектор

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Функция для получения информации о текущем сервере
local function getServerInfo()
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    return placeId, jobId
end

-- Функция для генерации ссылки приглашения
local function generateInviteLink()
    local placeId, jobId = getServerInfo()
    
    if jobId and jobId ~= "" then
        -- Создаем ссылку для присоединения к конкретному серверу
        local inviteLink = string.format("https://www.roblox.com/games/%d?privateServerLinkCode=%s", placeId, jobId)
        return inviteLink
    else
        -- Если JobId недоступен, создаем обычную ссылку на игру
        local inviteLink = string.format("https://www.roblox.com/games/%d", placeId)
        return inviteLink
    end
end

-- Функция для отправки сообщения в чат
local function sendToChat(message)
    -- Проверяем наличие системы чата
    local chatService = nil
    
    -- Попытка найти систему чата (разные версии Roblox)
    if game:GetService("Chat"):FindFirstChild("ChatService") then
        chatService = game:GetService("Chat").ChatService
    elseif game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") then
        local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
        if playerGui:FindFirstChild("Chat") then
            -- Используем ReplicatedStorage для отправки сообщения
            local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatRemote and chatRemote:FindFirstChild("SayMessageRequest") then
                chatRemote.SayMessageRequest:FireServer(message, "All")
                return true
            end
        end
    end
    
    -- Альтернативный способ через команду
    if LocalPlayer and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            -- Попытка использовать встроенную команду чата
            pcall(function()
                game:GetService("Players"):Chat(message)
            end)
        end
    end
    
    return false
end

-- Основная функция
local function main()
    wait(2) -- Ждем загрузки игры
    
    local inviteLink = generateInviteLink()
    local message = "🎮 Ссылка для присоединения: " .. inviteLink
    
    -- Отправляем в чат
    local success = sendToChat(message)
    
    if not success then
        -- Если не удалось отправить в чат, выводим в консоль
        print("Ссылка приглашения: " .. inviteLink)
        warn("Не удалось отправить в чат, ссылка выведена в консоль")
    end
    
    -- Также копируем в буфер обмена (если возможно)
    pcall(function()
        setclipboard(inviteLink)
        print("Ссылка скопирована в буфер обмена!")
    end)
end

-- Дополнительная функция для ручного вызова
_G.generateInvite = function()
    local inviteLink = generateInviteLink()
    print("Ссылка приглашения: " .. inviteLink)
    
    pcall(function()
        setclipboard(inviteLink)
        print("Ссылка скопирована в буфер обмена!")
    end)
    
    return inviteLink
end

-- Команда в чате для генерации ссылки
Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then
        player.Chatted:Connect(function(message)
            if message:lower() == "/invite" or message:lower() == "/приглашение" then
                local inviteLink = generateInviteLink()
                sendToChat("🎮 Ссылка для присоединения: " .. inviteLink)
            end
        end)
    end
end)

-- Если игрок уже в игре
if LocalPlayer then
    LocalPlayer.Chatted:Connect(function(message)
        if message:lower() == "/invite" or message:lower() == "/приглашение" then
            local inviteLink = generateInviteLink()
            sendToChat("🎮 Ссылка для присоединения: " .. inviteLink)
        end
    end)
end

-- Запускаем основную функцию
main()

print("✅ Скрипт генерации приглашений загружен!")
print("💡 Напишите /invite или /приглашение в чат для генерации ссылки")
print("💡 Или используйте _G.generateInvite() в консоли")
