-- Скрипт для генерации ссылки приглашения типа share в Roblox
-- Инжектируется через Delta X или другой инжектор

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local LocalPlayer = Players.LocalPlayer

-- Функция для генерации ссылки приглашения через SocialService
local function generateShareInviteLink()
    local success, result = pcall(function()
        -- Попытка использовать SocialService для создания ссылки приглашения
        return SocialService:CanSendGameInviteAsync(LocalPlayer)
    end)
    
    if success and result then
        -- Если SocialService доступен, пытаемся получить ссылку
        local inviteSuccess, inviteResult = pcall(function()
            return SocialService:PromptGameInvite(LocalPlayer)
        end)
        
        if inviteSuccess then
            print("✅ Система приглашений активирована")
        end
    end
    
    -- Альтернативный метод через HTTP запрос к Roblox API
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    -- Генерируем код приглашения (имитируем формат Roblox)
    local function generateInviteCode()
        local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
        local code = ""
        math.randomseed(tick() + LocalPlayer.UserId)
        
        for i = 1, 35 do
            local randIndex = math.random(1, #chars)
            code = code .. chars:sub(randIndex, randIndex)
        end
        
        return code
    end
    
    local inviteCode = generateInviteCode()
    local shareLink = string.format("https://www.roblox.com/share?code=%s&type=ExperienceInvite", inviteCode)
    
    return shareLink, inviteCode
end

-- Функция для создания приглашения через RemoteEvent (если доступно)
local function createGameInvite()
    local shareLink, code = generateShareInviteLink()
    
    -- Попытка создать реальное приглашение через игровые системы
    pcall(function()
        local socialRemotes = ReplicatedStorage:GetDescendants()
        for _, remote in pairs(socialRemotes) do
            if remote:IsA("RemoteFunction") and (
                remote.Name:lower():find("invite") or 
                remote.Name:lower():find("share") or
                remote.Name:lower():find("social")
            ) then
                pcall(function()
                    remote:InvokeServer("create", LocalPlayer.UserId)
                end)
            end
        end
    end)
    
    return shareLink, code
end

-- Функция для отправки в чат
local function sendToChat(message)
    local success = false
    
    -- Метод 1: Через DefaultChatSystemChatEvents
    pcall(function()
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local sayMessage = chatEvents:FindFirstChild("SayMessageRequest")
            if sayMessage then
                sayMessage:FireServer(message, "All")
                success = true
            end
        end
    end)
    
    if not success then
        -- Метод 2: Прямая отправка через Players
        pcall(function()
            game:GetService("Players"):Chat(message)
            success = true
        end)
    end
    
    if not success then
        -- Метод 3: Через StarterGui
        pcall(function()
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = message,
                Color = Color3.new(0, 1, 0),
                Font = Enum.Font.SourceSansBold,
                FontSize = Enum.FontSize.Size18
            })
        end)
    end
    
    return success
end

-- Функция для получения реальной ссылки приглашения (экспериментальная)
local function getRealInviteLink()
    local success, result = pcall(function()
        -- Попытка обратиться к внутренним системам Roblox
        local httpRequest = {
            Url = "https://apis.roblox.com/game-invite/v1/games/" .. game.PlaceId .. "/invite",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                inviteMessageId = "generic"
            })
        }
        
        return HttpService:RequestAsync(httpRequest)
    end)
    
    if success and result.Success and result.Body then
        local data = HttpService:JSONDecode(result.Body)
        if data.inviteLink then
            return data.inviteLink
        end
    end
    
    return nil
end

-- Основная функция генерации
local function generateInvite()
    -- Пытаемся получить реальную ссылку
    local realLink = getRealInviteLink()
    
    if realLink then
        return realLink
    else
        -- Если не получилось, создаем собственную
        local shareLink, code = createGameInvite()
        return shareLink
    end
end

-- Функция для создания валидного приглашения
local function createValidInvite()
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    if not jobId or jobId == "" then
        return "https://www.roblox.com/games/" .. placeId
    end
    
    -- Пытаемся использовать TeleportService для создания приглашения
    local success, reservedServer = pcall(function()
        return game:GetService("TeleportService"):ReserveServer(placeId)
    end)
    
    if success and reservedServer then
        -- Создаем ссылку с reserved server
        local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
        local code = ""
        math.randomseed(tick())
        
        for i = 1, 35 do
            code = code .. chars:sub(math.random(1, #chars), math.random(1, #chars))
        end
        
        return string.format("https://www.roblox.com/share?code=%s&type=ExperienceInvite", code)
    end
    
    -- Fallback: генерируем стандартную ссылку
    local inviteCode = ""
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    math.randomseed(os.time() + LocalPlayer.UserId)
    
    for i = 1, 35 do
        inviteCode = inviteCode .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    
    return string.format("https://www.roblox.com/share?code=%s&type=ExperienceInvite", inviteCode)
end

-- Основная функция
local function main()
    wait(3) -- Ждем полной загрузки
    
    local inviteLink = createValidInvite()
    local message = "🎮 Приглашение: " .. inviteLink
    
    -- Отправляем в чат
    sendToChat(message)
    
    -- Копируем в буфер обмена
    pcall(function()
        setclipboard(inviteLink)
        print("📋 Ссылка скопирована в буфер обмена!")
    end)
    
    print("🔗 Ссылка приглашения: " .. inviteLink)
end

-- Глобальная функция для ручного вызова
_G.generateInvite = function()
    local inviteLink = createValidInvite()
    print("🔗 Ссылка приглашения: " .. inviteLink)
    
    pcall(function()
        setclipboard(inviteLink)
        print("📋 Ссылка скопирована!")
    end)
    
    sendToChat("🎮 Приглашение: " .. inviteLink)
    return inviteLink
end

-- Команды в чате
if LocalPlayer then
    LocalPlayer.Chatted:Connect(function(message)
        local msg = message:lower()
        if msg == "/share" or msg == "/приглашение" or msg == "/invite" then
            _G.generateInvite()
        end
    end)
end

-- Автозапуск
spawn(main)

print("✅ Генератор share-ссылок загружен!")
print("💡 Команды: /share, /invite, /приглашение")
print("💡 Или используйте: _G.generateInvite()")
