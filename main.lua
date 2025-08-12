-- 🔍 ДЕТЕКТОР ВСЕХ GUI ИЗМЕНЕНИЙ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

print("🚀 === СУПЕР ДЕТЕКТОР GUI ===")
print("📱 Этот скрипт покажет ВСЕ изменения в GUI!")
print("💡 Теперь нажмите кнопку передачи питомца и смотрите консоль!")

-- 📦 Хранилище состояний всех элементов
local allElements = {}

-- 🔄 Функция сканирования всех GUI элементов
local function scanAllGui()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local currentElements = {}
    
    -- Проходимся по всем GUI
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            -- Проходимся по всем элементам внутри
            for _, element in ipairs(gui:GetDescendants()) do
                local fullPath = element:GetFullName()
                currentElements[fullPath] = {
                    object = element,
                    className = element.ClassName,
                    name = element.Name,
                    visible = element:IsA("GuiObject") and element.Visible or "N/A",
                    text = (element:IsA("TextLabel") or element:IsA("TextButton")) and element.Text or "",
                    parent = element.Parent and element.Parent.Name or "nil"
                }
            end
        end
    end
    
    -- Ищем новые элементы
    for path, info in pairs(currentElements) do
        if not allElements[path] then
            -- НОВЫЙ ЭЛЕМЕНТ!
            print("🆕 НОВЫЙ GUI ЭЛЕМЕНТ ОБНАРУЖЕН:")
            print("   📍 Путь: " .. path)
            print("   📝 Класс: " .. info.className)
            print("   🏷️  Имя: " .. info.name)
            print("   👁️  Видимый: " .. tostring(info.visible))
            if info.text and info.text ~= "" then
                print("   💬 Текст: '" .. info.text .. "'")
                
                -- Проверяем цвет текста если это текст
                if info.object:IsA("TextLabel") or info.object:IsA("TextButton") then
                    local color = info.object.TextColor3
                    print(string.format("   🎨 Цвет: R=%.2f G=%.2f B=%.2f", color.R, color.G, color.B))
                    
                    -- Если белый текст - помечаем особо!
                    if color.R > 0.9 and color.G > 0.9 and color.B > 0.9 then
                        print("   ⚪ ЭТО БЕЛЫЙ ТЕКСТ! ВОЗМОЖНО ТО ЧТО ИЩЕМ!")
                    end
                end
            end
            print("   📦 Родитель: " .. info.parent)
            print("   " .. string.rep("-", 50))
        end
    end
    
    -- Ищем элементы которые стали видимыми
    for path, oldInfo in pairs(allElements) do
        local newInfo = currentElements[path]
        if newInfo then
            -- Элемент существует, проверяем изменения видимости
            if oldInfo.visible == false and newInfo.visible == true then
                print("👁️ ЭЛЕМЕНТ СТАЛ ВИДИМЫМ:")
                print("   📍 Путь: " .. path)
                print("   📝 Класс: " .. newInfo.className)
                print("   🏷️  Имя: " .. newInfo.name)
                if newInfo.text and newInfo.text ~= "" then
                    print("   💬 Текст: '" .. newInfo.text .. "'")
                end
                print("   " .. string.rep("-", 50))
            end
            
            -- Проверяем изменение текста
            if oldInfo.text ~= newInfo.text and newInfo.text ~= "" then
                print("💬 ИЗМЕНИЛСЯ ТЕКСТ:")
                print("   📍 Путь: " .. path)
                print("   📝 Старый текст: '" .. oldInfo.text .. "'")
                print("   📝 Новый текст: '" .. newInfo.text .. "'")
                print("   " .. string.rep("-", 50))
            end
        end
    end
    
    -- Обновляем наше хранилище
    allElements = currentElements
end

-- 🚀 Запуск постоянного мониторинга
local connection = RunService.Heartbeat:Connect(function()
    scanAllGui()
end)

print("✅ Детектор запущен!")
print("🎯 ИНСТРУКЦИЯ:")
print("1. Теперь нажмите кнопку передачи питомца")
print("2. Сразу смотрите в консоль - там появится информация о новых GUI")
print("3. Ищите элементы с белым текстом или текстом о передаче")
print("")
print("⏹️ Чтобы остановить детектор, выполните: connection:Disconnect()")

-- Экспортируем connection чтобы можно было остановить
_G.guiDetectorConnection = connection

-- Функция остановки
_G.stopGuiDetector = function()
    if _G.guiDetectorConnection then
        _G.guiDetectorConnection:Disconnect()
        print("🛑 Детектор остановлен!")
    end
end

print("💡 Для остановки используйте: stopGuiDetector()")

-- Делаем начальное сканирование чтобы запомнить текущие элементы
scanAllGui()
print("📊 Начальное сканирование завершено. Готов к отслеживанию изменений!")
