-- Скрипт для поиска уведомлений "Trade request sent" и "Trade completed"
-- Вставьте в консоль разработчика (F9 -> Console)

print("🔍 Ищем уведомление 'Sent gift request!' и другие торговые уведомления...")
print("=====================================")

-- Функция для поиска текста во всех GUI
local function findTextInGUI(parent, searchText, path)
    path = path or ""
    
    for _, child in pairs(parent:GetChildren()) do
        local currentPath = path .. "." .. child.Name
        
        -- Проверяем если это текстовый элемент
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            if child.Text then
                local text = string.lower(child.Text)
                -- Ищем конкретно "Sent gift request!" и другие похожие фразы
                if string.find(text, "sent gift request") or 
                   string.find(text, "gift request") or
                   string.find(text, "trade completed") or
                   string.find(text, "trade successful") or
                   string.find(text, "request sent") or
                   text == string.lower(child.Text) and string.find(child.Text, "Sent") then
                    print("📍 НАЙДЕН: " .. currentPath)
                    print("   Текст: '" .. child.Text .. "'")
                    print("   Полный путь: " .. parent.Name .. currentPath)
                    print("   Полный игровой путь: " .. child:GetFullName())
                    print("   ---")
                end
            end
        end
        
        -- Рекурсивный поиск в дочерних элементах
        if #child:GetChildren() > 0 then
            findTextInGUI(child, searchText, currentPath)
        end
    end
end

-- Функция для поиска во всех возможных местах
local function searchEverywhere()
    local places = {
        {name = "PlayerGui", location = game:GetService("Players").LocalPlayer.PlayerGui},
        {name = "StarterGui", location = game:GetService("StarterGui")},
        {name = "ReplicatedStorage", location = game:GetService("ReplicatedStorage")},
        {name = "Workspace", location = game:GetService("Workspace")},
        {name = "ServerStorage", location = game:GetService("ServerStorage")}, -- может не работать на клиенте
    }
    
    for _, place in pairs(places) do
        print("🔍 Ищем в: " .. place.name)
        local success, error = pcall(function()
            findTextInGUI(place.location, "trade")
        end)
        if not success then
            print("❌ Не удалось найти в " .. place.name .. ": " .. tostring(error))
        end
        print("")
    end
end

-- Поиск по конкретным ключевым словам
local function findSpecificNotifications()
    print("🎯 Ищем конкретные уведомления: 'Sent gift request!'...")
    
    local keywords = {"sent gift request", "gift request", "trade completed", "trade successful", "request sent"}
    
    local function searchInService(service, serviceName)
        print("Ищем в " .. serviceName .. ":")
        for _, obj in pairs(service:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                if obj.Text then
                    local text = string.lower(obj.Text)
                    for _, keyword in pairs(keywords) do
                        if string.find(text, keyword) or obj.Text == "Sent gift request!" then
                            print("  ✅ " .. obj:GetFullName())
                            print("     Текст: '" .. obj.Text .. "'")
                            print("     Видимость: " .. tostring(obj.Visible))
                            print("     Родитель: " .. obj.Parent:GetFullName())
                        end
                    end
                end
            end
        end
    end
    
    searchInService(game:GetService("Players").LocalPlayer.PlayerGui, "PlayerGui")
    searchInService(game:GetService("StarterGui"), "StarterGui")
    
    local success, _ = pcall(function()
        searchInService(game:GetService("ReplicatedStorage"), "ReplicatedStorage")
    end)
end

-- Поиск уведомлений (могут быть в CoreGui)
local function findCoreGuiNotifications()
    print("🔍 Ищем 'Sent gift request!' в CoreGui (системные уведомления)...")
    local success, error = pcall(function()
        local coreGui = game:GetService("CoreGui")
        for _, obj in pairs(coreGui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text then
                local text = string.lower(obj.Text)
                if string.find(text, "sent gift request") or 
                   string.find(text, "gift request") or 
                   obj.Text == "Sent gift request!" or
                   string.find(text, "trade completed") or
                   string.find(text, "trade successful") then
                    print("  ✅ CoreGui: " .. obj:GetFullName())
                    print("     Текст: '" .. obj.Text .. "'")
                    print("     Видимость: " .. tostring(obj.Visible))
                end
            end
        end
    end)
    if not success then
        print("❌ CoreGui недоступен: " .. tostring(error))
    end
end

-- Запускаем все поиски
searchEverywhere()
findSpecificNotifications()
findCoreGuiNotifications()

print("=====================================")
print("🎯 Дополнительные места для поиска:")
print("1. game:GetService(\"Players\").LocalPlayer.PlayerGui")
print("2. game:GetService(\"StarterGui\")")  
print("3. game:GetService(\"CoreGui\") - системные уведомления")
print("4. Могут быть в TweenService анимациях")
print("5. Могут создаваться динамически через RemoteEvents")

print("\n💡 Попробуйте также:")
print("- Сделать трейд и сразу после запустить этот скрипт")
print("- Проверить game:GetService(\"SoundService\") для звуковых уведомлений")

-- Мониторинг новых GUI элементов
print("\n🔄 Запускаю мониторинг новых GUI...")
local monitoredServices = {game:GetService("Players").LocalPlayer.PlayerGui, game:GetService("StarterGui")}

for _, service in pairs(monitoredServices) do
    service.ChildAdded:Connect(function(child)
        wait(0.1) -- небольшая задержка чтобы GUI успел загрузиться
        print("🆕 Новый GUI: " .. child.Name)
        findTextInGUI(child, "trade", "")
    end)
end

print("✅ Мониторинг активен! Попробуйте сделать трейд сейчас.")
