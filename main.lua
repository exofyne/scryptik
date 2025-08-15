-- Скрипт для автоматического вызова системы приглашений и извлечения ссылки
-- Инжектируется через Delta X или другой инжектор

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local SocialService = game:GetService("SocialService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Переменная для хранения найденной ссылки
local foundInviteLink = nil

-- Функция для мониторинга изменений в GUI
local function monitorGuiForInviteLink()
    local function scanForLinks(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local text = obj.Text
            -- Ищем ссылки типа share с ExperienceInvite
            if text:find("roblox%.com/share%?code=") and text:find("type=ExperienceInvite") then
                foundInviteLink = text
                print("🎯 НАЙДЕНА ССЫЛКА ПРИГЛАШЕНИЯ: " .. foundInviteLink)
                return true
            end
            -- Также ищем другие форматы ссылок
            if text:find("roblox%.com") and (text:find("invite") or text:find("share")) then
                foundInviteLink = text
                print("🎯 НАЙДЕНА ССЫЛКА: " .. foundInviteLink)
                return true
            end
        end
        return false
    end
    
    -- Сканируем весь PlayerGui
    local function scanAllGui()
        for _, gui in pairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, obj in pairs(gui:GetDescendants()) do
                    if scanForLinks(obj) then
                        return true
                    end
                end
            end
        end
        return false
    end
    
    -- Мониторим новые объекты
    PlayerGui.DescendantAdded:Connect(function(obj)
        wait(0.1) -- Даем время объекту загрузиться
        scanForLinks(obj)
    end)
    
    -- Мониторим изменения текста
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    obj:GetPropertyChangedSignal("Text"):Connect(function()
                        scanForLinks(obj)
                    end)
                end
            end
        end
    end
    
    return scanAllGui()
end

-- Функция для перехвата HTTP запросов (экспериментальная)
local function interceptHttpRequests()
    local originalRequest = HttpService.RequestAsync
    
    HttpService.RequestAsync = function(self, requestOptions)
        local result = originalRequest(self, requestOptions)
        
        -- Проверяем ответ на наличие ссылок приглашения
        if result.Body and type(result.Body) == "string" then
            if result.Body:find("share%?code=") and result.Body:find("ExperienceInvite") then
                local link = result.Body:match("(https://[^%s\"']+share%?code=[^%s\"']+)")
                if link then
                    foundInviteLink = link
                    print("🎯 ПЕРЕХВАЧЕНА ССЫЛКА ПРИГЛАШЕНИЯ: " .. foundInviteLink)
                end
            end
        end
        
        return result
    end
end

-- Функция для активации системы приглашений через SocialService
local function activateSocialService()
    print("🔄 Попытка активации SocialService...")
    
    local success, canInvite = pcall(function()
        return SocialService:CanSendGameInviteAsync(LocalPlayer)
    end)
    
    if success and canInvite then
        print("✅ SocialService доступен!")
        
        -- Активируем окно приглашений
        pcall(function()
            SocialService:PromptGameInvite(LocalPlayer)
        end)
        
        return true
    end
    
    return false
end

-- Функция для поиска и клика кнопок приглашения
local function findAndClickInviteButtons()
    print("🔄 Поиск кнопок приглашения...")
    
    local keywords = {
        "invite", "приглас", "share", "поделить", "друзья", "friends",
        "send", "отправить", "create", "создать", "link", "ссылка"
    }
    
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local text = obj.Name:lower()
                    if obj:IsA("TextButton") then
                        text = text .. " " .. obj.Text:lower()
                    end
                    
                    for _, keyword in pairs(keywords) do
                        if text:find(keyword) then
                            print("🎯 Найдена кнопка: " .. obj.Name .. " (" .. (obj.Text or "ImageButton") .. ")")
                            
                            -- Кликаем кнопку
                            pcall(function()
                                firesignal(obj.MouseButton1Click)
                            end)
                            pcall(function()
                                firesignal(obj.Activated)
                            end)
                            
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

-- Функция для активации через GuiService
local function activateGuiService()
    print("🔄 Попытка активации через GuiService...")
    
    local guiMethods = {
        function() GuiService:SetMenuIsOpen(true, "InviteFriends") end,
        function() GuiService:SetMenuIsOpen(true, "GameInvite") end,
        function() GuiService:SetMenuIsOpen(true, "Social") end,
        function() GuiService:SetMenuIsOpen(true, "ShareGame") end
    }
    
    for i, method in ipairs(guiMethods) do
        pcall(function()
            method()
            print("✅ Активирован метод GuiService #" .. i)
        end)
    end
end

-- Функция для поиска через StarterGui
local function activateStarterGui()
    print("🔄 Попытка активации через StarterGui...")
    
    local starterGuiMethods = {
        function() 
            game:GetService("StarterGui"):SetCore("PromptGameInvite", {})
        end,
        function()
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = "Активация системы приглашений...",
                Color = Color3.new(0, 1, 0)
            })
        end
    }
    
    for i, method in ipairs(starterGuiMethods) do
        pcall(method)
    end
end

-- Функция для эмуляции клавиш
local function tryKeyboardShortcuts()
    print("🔄 Попытка горячих клавиш...")
    
    local shortcuts = {
        {Enum.KeyCode.Tab, Enum.KeyCode.I}, -- Tab+I
        {Enum.KeyCode.LeftControl, Enum.KeyCode.I}, -- Ctrl+I
        {Enum.KeyCode.LeftShift, Enum.KeyCode.F}, -- Shift+F
    }
    
    for _, combo in ipairs(shortcuts) do
        pcall(function()
            for _, key in ipairs(combo) do
                UserInputService:GetService("UserInputService"):SendKeyEvent(true, key, false, game)
                wait(0.1)
                UserInputService:GetService("UserInputService"):SendKeyEvent(false, key, false, game)
            end
        end)
        wait(0.5)
    end
end

-- Функция отправки в чат
local function sendToChat(message)
    pcall(function()
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
            chatEvents.SayMessageRequest:FireServer(message, "All")
        end
    end)
end

-- Главная функция
local function generateInviteLink()
    foundInviteLink = nil
    
    print("🚀 Запуск автоматического получения ссылки приглашения...")
    
    -- Начинаем мониторинг GUI
    monitorGuiForInviteLink()
    
    -- Перехватываем HTTP запросы
    interceptHttpRequests()
    
    -- Пробуем все методы активации
    activateSocialService()
    wait(1)
    
    activateGuiService()
    wait(1)
    
    activateStarterGui()
    wait(1)
    
    findAndClickInviteButtons()
    wait(1)
    
    tryKeyboardShortcuts()
    
    -- Ждем результата
    local attempts = 0
    while not foundInviteLink and attempts < 30 do
        wait(1)
        attempts = attempts + 1
        print("⏳ Ожидание ссылки... (" .. attempts .. "/30)")
        
        -- Повторно сканируем GUI
        monitorGuiForInviteLink()
    end
    
    if foundInviteLink then
        print("🎉 УСПЕХ! Получена ссылка: " .. foundInviteLink)
        
        -- Отправляем в чат
        sendToChat("🎮 Приглашение: " .. foundInviteLink)
        
        -- Копируем в буфер обмена
        pcall(function()
            setclipboard(foundInviteLink)
            print("📋 Ссылка скопирована в буфер обмена!")
        end)
        
        return foundInviteLink
    else
        print("❌ Не удалось получить ссылку приглашения")
        print("💡 Попробуйте активировать систему приглашений вручную")
        return nil
    end
end

-- Глобальные функции
_G.getInviteLink = generateInviteLink
_G.foundLink = function() return foundInviteLink end

-- Команды чата
LocalPlayer.Chatted:Connect(function(message)
    local msg = message:lower()
    if msg == "/getlink" or msg == "/автоинвайт" or msg == "/получитьссылку" then
        spawn(generateInviteLink)
    end
end)

-- Автозапуск
spawn(function()
    wait(5)
    generateInviteLink()
end)

print("✅ Автоматический извлекатель ссылок приглашения загружен!")
print("💡 Команды: /getlink, /автоинвайт, /получитьссылку")
print("💡 Функция: _G.getInviteLink()")
print("🔍 Скрипт автоматически найдет и извлечет реальную ссылку приглашения!")
