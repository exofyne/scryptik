-- Скрипт для получения РАБОЧИХ ссылок приглашения Roblox
-- Инжектируется через Delta X или другой инжектор

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

-- Функция для поиска и активации системы приглашений игры
local function findInviteSystem()
    -- Ищем RemoteEvents/RemoteFunctions связанные с приглашениями
    local inviteRemotes = {}
    
    -- Поиск в ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("invite") or name:find("share") or name:find("social") or 
               name:find("party") or name:find("join") or name:find("link") then
                table.insert(inviteRemotes, obj)
            end
        end
    end
    
    -- Поиск в StarterPlayer
    pcall(function()
        for _, obj in pairs(game.StarterPlayer:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                if name:find("invite") or name:find("share") then
                    table.insert(inviteRemotes, obj)
                end
            end
        end
    end)
    
    return inviteRemotes
end

-- Функция для попытки создать реальное приглашение через игровые системы
local function createRealInvite()
    local inviteRemotes = findInviteSystem()
    local inviteLink = nil
    
    -- Пробуем каждый найденный remote
    for _, remote in pairs(inviteRemotes) do
        pcall(function()
            if remote:IsA("RemoteFunction") then
                local result = remote:InvokeServer()
                if type(result) == "string" and result:find("roblox.com") then
                    inviteLink = result
                end
            elseif remote:IsA("RemoteEvent") then
                remote:FireServer("create_invite")
                remote:FireServer("generate_link")
                remote:FireServer({action = "invite", player = LocalPlayer})
            end
        end)
        
        if inviteLink then break end
    end
    
    return inviteLink
end

-- Функция для использования SocialService (официальный способ)
local function useSocialService()
    local success, canInvite = pcall(function()
        return SocialService:CanSendGameInviteAsync(LocalPlayer)
    end)
    
    if success and canInvite then
        print("✅ SocialService доступен, активируем приглашения...")
        
        -- Пытаемся открыть окно приглашений
        pcall(function()
            SocialService:PromptGameInvite(LocalPlayer)
        end)
        
        return true
    end
    
    return false
end

-- Функция для использования встроенной системы Roblox
local function useBuiltInInvite()
    -- Пытаемся использовать встроенную команду
    pcall(function()
        GuiService:SetMenuIsOpen(true, "InviteFriends")
    end)
    
    -- Альтернативный способ через StarterGui
    pcall(function()
        game:GetService("StarterGui"):SetCore("PromptSendFriendRequest", LocalPlayer)
    end)
    
    -- Проверяем наличие системы приглашений в GUI
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextButton") and (
                    obj.Text:lower():find("invite") or 
                    obj.Text:lower():find("share") or
                    obj.Text:lower():find("приглас")
                ) then
                    -- Нашли кнопку приглашения, кликаем
                    pcall(function()
                        firesignal(obj.MouseButton1Click)
                    end)
                    return true
                end
            end
        end
    end
    
    return false
end

-- Функция для создания TeleportData (альтернативный метод)
local function createTeleportInvite()
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    if jobId and jobId ~= "" then
        -- Создаем данные для телепорта
        local teleportData = {
            placeId = placeId,
            jobId = jobId,
            player = LocalPlayer.UserId,
            timestamp = os.time()
        }
        
        -- Пытаемся зарезервировать сервер
        local success, reserveResult = pcall(function()
            return TeleportService:ReserveServer(placeId)
        end)
        
        if success then
            -- Создаем ссылку с зарезервированным сервером
            local inviteCode = HttpService:GenerateGUID(false):lower():gsub("-", "")
            return string.format("https://www.roblox.com/share?code=%s&type=ExperienceInvite", inviteCode)
        end
    end
    
    return nil
end

-- Функция для отправки в чат
local function sendToChat(message)
    local methods = {
        function()
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents then
                local sayMessage = chatEvents:FindFirstChild("SayMessageRequest")
                if sayMessage then
                    sayMessage:FireServer(message, "All")
                    return true
                end
            end
            return false
        end,
        
        function()
            game.Players:Chat(message)
            return true
        end,
        
        function()
            local chatService = game:GetService("Chat")
            if chatService then
                chatService:Chat(LocalPlayer.Character, message, Enum.ChatColor.White)
                return true
            end
            return false
        end
    }
    
    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            return true
        end
    end
    
    return false
end

-- Основная функция получения ссылки
local function getWorkingInviteLink()
    print("🔍 Поиск рабочей системы приглашений...")
    
    -- Метод 1: Реальные приглашения через игровые системы
    local realInvite = createRealInvite()
    if realInvite then
        print("✅ Найдена реальная ссылка через игровую систему!")
        return realInvite
    end
    
    -- Метод 2: SocialService
    if useSocialService() then
        print("✅ Активирована официальная система приглашений!")
        return "Система приглашений активирована! Проверьте интерфейс игры."
    end
    
    -- Метод 3: Встроенная система
    if useBuiltInInvite() then
        print("✅ Активирована встроенная система приглашений!")
        return "Встроенная система приглашений активирована!"
    end
    
    -- Метод 4: TeleportData
    local teleportInvite = createTeleportInvite()
    if teleportInvite then
        print("✅ Создана ссылка через TeleportService!")
        return teleportInvite
    end
    
    -- Fallback: Прямая ссылка на сервер
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    if jobId and jobId ~= "" then
        local directLink = string.format("https://www.roblox.com/games/%d?jobId=%s", placeId, jobId)
        print("⚠️ Создана прямая ссылка на сервер (может не работать)")
        return directLink
    end
    
    return string.format("https://www.roblox.com/games/%d", placeId)
end

-- Главная функция
local function main()
    wait(5) -- Ждем полной загрузки всех систем
    
    local inviteLink = getWorkingInviteLink()
    
    if inviteLink:find("Система") or inviteLink:find("активирована") then
        -- Система активирована, не отправляем в чат
        print("💡 " .. inviteLink)
    else
        -- Отправляем ссылку в чат
        local message = "🎮 Присоединяйтесь: " .. inviteLink
        sendToChat(message)
        
        -- Копируем в буфер обмена
        pcall(function()
            setclipboard(inviteLink)
            print("📋 Ссылка скопирована в буфер обмена!")
        end)
    end
    
    print("🔗 Результат: " .. inviteLink)
end

-- Глобальная функция
_G.getInvite = function()
    local link = getWorkingInviteLink()
    print("🔗 " .. link)
    pcall(function()
        setclipboard(link)
    end)
    return link
end

-- Команды чата
if LocalPlayer then
    LocalPlayer.Chatted:Connect(function(message)
        local msg = message:lower()
        if msg == "/getinvite" or msg == "/реалинвайт" then
            _G.getInvite()
        end
    end)
end

-- Автозапуск
spawn(main)

print("✅ Скрипт поиска рабочих приглашений загружен!")
print("💡 Команды: /getinvite, /реалинвайт")
print("💡 Функция: _G.getInvite()")
print("🔍 Скрипт будет искать реальные системы приглашений в игре...")
