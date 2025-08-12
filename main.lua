-- Улучшенный скрипт для скрытия GUI (Grow a Garden)
-- Вставь в консоль разработчика (F9 -> Console) или в эксплойтер.

local guiElements = {
    -- PlayerGui элементы
    'game:GetService("Players").LocalPlayer.PlayerGui.TradingUI.Main.Main.AcceptButton.Main.TextLabel',

    -- ReplicatedStorage элементы
    'game:GetService("ReplicatedStorage").Modules.FriendshipPot.FriendshipPotHandler.Gift_Notification.Holder.TextLabel',
    'game:GetService("ReplicatedStorage").Modules.FriendshipPot.FriendshipPotHandler.Gift_Notification.Holder.Notification_UI.TextLabel',
    'game:GetService("ReplicatedStorage").Modules.PetServices.PetGiftingService.Gift_Notification.Holder.Notification_UI.TextLabel',
    'game:GetService("ReplicatedStorage").Modules.PetServices.PetGiftingService.Gift_Notification.Holder.TextLabel',
    'game:GetService("ReplicatedStorage").Gift_Notification.Holder.Notification_UI.TextLabel',
    'game:GetService("ReplicatedStorage").Gift_Notification.Holder.TextLabel',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.GiftTemplate.Segment.Main.PromptText',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.GiftTemplate.Segment.Main.PromptTextShadow',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.TradeRequest.Wrapper.Canvas.Segment.Buttons.ACCEPT_BUTTON.Main.TextLabel',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.TradeRequest.Wrapper.Canvas.Segment.Buttons.DECLINE_BUTTON.Main.TextLabel',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.TradeRequest.Wrapper.Canvas.Segment.Main.PromptText',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.TradeRequest.Wrapper.Canvas.Segment.Main.PromptTextShadow',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.Trade_Notification.Frame.Buttons.ACCEPT_BUTTON.ACCEPT_BUTTON.Main.TextLabel',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.Trade_Notification.Frame.Buttons.DECLINE_BUTTON.DECLINE_BUTTON.Main.TextLabel',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.Trade_Notification.Frame.Main.PromptText',
    'game:GetService("ReplicatedStorage").Modules.TradeControllers.TradeRequestController.Trade_Notification.Frame.Main.PromptTextShadow',

    -- StarterGui элементы
    'game:GetService("StarterGui").Trading.FinalizingTrade.Text',

    -- Settings (с GetChildren() индексами)
    'game:GetService("Players").LocalPlayer.PlayerGui.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT:GetChildren()[5].Display.SETTING_TITLE',
    'game:GetService("Players").LocalPlayer.PlayerGui.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT:GetChildren()[5].Display.SETTING_DESCRIPTION',
    'game:GetService("Players").LocalPlayer.PlayerGui.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT:GetChildren()[6].Display.SETTING_DESCRIPTION',
    'game:GetService("Players").LocalPlayer.PlayerGui.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT:GetChildren()[6].Display.SETTING_TITLE',
    'game:GetService("Players").LocalPlayer.PlayerGui.TradingUI.Main.Main.Holder.Header.Title'
}

-- Утилита: безопасно исполнить "return <expr>" через loadstring/load (если доступно)
local function safeEval(expr)
    local loader = loadstring or load
    if not loader then return nil end
    local ok, f = pcall(function() return loader("return " .. expr) end)
    if not ok or type(f) ~= "function" then return nil end
    local ok2, res = pcall(f)
    if not ok2 then return nil end
    return res
end

-- Простейший ручной разбор, чтобы обработать выражения с :GetChildren()[N]
local function manualResolve(path)
    local serviceName, rest = path:match('^game:GetService%(%s*[\'"]([^\'"]+)[\'"]%s*%)%.?(.*)$')
    local current, tail = nil, rest
    if serviceName then
        current = game:GetService(serviceName)
    else
        local afterPlayers = path:match('^Players%.LocalPlayer%.?(.*)$')
        if afterPlayers then
            current = game:GetService("Players").LocalPlayer
            tail = afterPlayers
        else
            local afterStarter = path:match('^StarterGui%.?(.*)$')
            if afterStarter then
                current = game:GetService("StarterGui")
                tail = afterStarter
            else
                -- попытка взять первую часть от game, например game.SomeService...
                local first, restt = path:match('^game%.([%w_]+)%.?(.*)$')
                if first and game[first] then
                    current = game[first]
                    tail = restt
                else
                    -- если ни один вариант не подошёл, пробуем всю строку как single token
                    return nil
                end
            end
        end
    end

    if not tail or tail == "" then return current end
    for token in tail:gmatch("([^.]+)") do
        -- token вида NAME:GetChildren()[N]
        local name, idx = token:match("^([%w_]+):GetChildren%(%)%[(%d+)%]$")
        if name and idx then
            local child = current:FindFirstChild(name)
            if not child then return nil end
            local children = child:GetChildren()
            current = children[tonumber(idx)]
            if not current then return nil end
        else
            -- token вида GetChildren()[N]
            local onlyIdx = token:match("^GetChildren%(%)%[(%d+)%]$")
            if onlyIdx then
                local children = current:GetChildren()
                current = children[tonumber(onlyIdx)]
                if not current then return nil end
            else
                -- обычное имя — пытаемся найти ребёнка; если нет — возможно это свойство объекта
                local nextChild = current:FindFirstChild(token)
                if nextChild then
                    current = nextChild
                else
                    -- проверяем — может быть свойством (Text, Visible и т.п.)
                    local ok, _ = pcall(function() return current[token] end)
                    if ok then
                        -- вернём parent и имя свойства (далее скрипт поймёт, что нужно менять проперти)
                        return current, token
                    end
                    return nil
                end
            end
        end
    end
    return current
end

-- Попытка разрешить путь — сначала eval, затем fallback на родителя, затем manualResolve
local function resolveInstanceAndMaybeProp(path)
    -- 1) Попытка выполнить целиком
    local res = safeEval(path)
    if res and typeof(res) == "Instance" then
        return res, nil
    end

    -- 2) Если eval вернул не Instance (например строку) — пытаемся взять родителя и имя свойства
    local parentExpr, prop = path:match("^(.*)%.([%w_]+)$")
    if parentExpr and prop then
        local parent = safeEval(parentExpr)
        if parent and typeof(parent) == "Instance" then
            return parent, prop
        end
    end

    -- 3) Fallback ручной разбор (для случаев, когда loadstring недоступен)
    local manual = manualResolve(path)
    if manual then
        if typeof(manual) == "Instance" then
            return manual, nil
        elseif type(manual) == "table" and manual[1] and typeof(manual[1]) == "Instance" and manual[2] then
            return manual[1], manual[2]
        else
            -- manualResolve может вернуть (parent, prop)
            if type(manual) == "table" and manual[2] and typeof(manual[1]) == "Instance" then
                return manual[1], manual[2]
            end
            return manual
        end
    end

    return nil, nil
end

-- Функция, которая пытается безопасно скрыть/очистить/сделать прозрачным найденный объект или свойство
local function applyHide(path)
    local inst, prop = resolveInstanceAndMaybeProp(path)
    if not inst then
        print("❌ Не найден путь: " .. path)
        return
    end

    -- Если prop задан — это свойство последнего сегмента (например .Text)
    if prop then
        local success, err = pcall(function()
            -- если это свойство Text или TextTransparency или Visible — применяем соответствующие значения
            if prop == "Text" then
                inst.Text = ""
            elseif prop == "Visible" then
                inst.Visible = false
            elseif prop == "TextTransparency" then
                inst.TextTransparency = 1
            else
                -- общая попытка обнулить/очистить
                pcall(function() inst[prop] = "" end)
            end
        end)
        if success then
            print("✅ Обновлено свойство '"..prop.."' у: " .. path)
        else
            print("❌ Ошибка при обновлении свойства '"..prop.."' у: " .. path)
        end
        return
    end

    -- Если пришёл Instance — пробуем несколько действий
    local madeSomething = false
    pcall(function()
        if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
            inst.Visible = false
            inst.Text = ""
            inst.TextTransparency = 1
            madeSomething = true
        elseif inst:IsA("GuiObject") then
            inst.Visible = false
            madeSomething = true
        else
            -- попытаться установить свойство Text/Visible, если такое есть
            if pcall(function() inst.Visible = false end) then madeSomething = true end
            if pcall(function() inst.Text = "" end) then madeSomething = true end
        end
    end)

    if madeSomething then
        print("✅ Скрыт/очищен объект: " .. path)
    else
        print("⚠️ Найден объект, но не удалось применить изменения: " .. path)
    end
end

-- Брутфорс: пробуем каждую стратегию для каждого пути (аналог safeDisable в твоём примере)
print("🚀 Начинаю отключение GUI...")
for _, element in ipairs(guiElements) do
    -- Сначала пробуем скрыть как объект/родитель/свойство
    applyHide(element)
    -- Дополнительно: если это выражение возвращает значение, но объект — его родитель; уже учтено в applyHide
end

-- Рекурсивное скрытие для TradingUI (на всякий случай)
local function hideAllUnder(root)
    if not root then return end
    pcall(function()
        for _, c in pairs(root:GetChildren()) do
            if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then
                pcall(function()
                    c.Visible = false
                    c.Text = ""
                    c.TextTransparency = 1
                end)
            end
            hideAllUnder(c)
        end
    end)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Дополнительная проверка в PlayerGui (включая динамически появляющиеся элементы)
local function checkPlayerGui()
    local plr = Players.LocalPlayer
    if not plr then return end
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return end

    -- скрываем Trading и TradingUI если есть
    if pg:FindFirstChild("Trading") and pg.Trading:FindFirstChild("FinalizingTrade") then
        pcall(function()
            pg.Trading.FinalizingTrade.Visible = false
            pcall(function() pg.Trading.FinalizingTrade.Text = "" end)
        end)
        print("✅ Дополнительно отключен PlayerGui Trading.FinalizingTrade")
    end

    if pg:FindFirstChild("TradingUI") then
        hideAllUnder(pg.TradingUI)
        print("✅ Дополнительно скрыт весь TradingUI")
    end

    -- Settings insertion point (на случай, если элементы создаются позже)
    local ok, children = pcall(function()
        return pg.SettingsUI and pg.SettingsUI.SettingsFrame and pg.SettingsUI.SettingsFrame.Main and pg.SettingsUI.SettingsFrame.Main.Holder and pg.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT and pg.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT:GetChildren()
    end)
    if ok and children then
        for i=1,#children do
            pcall(function()
                local disp = children[i]:FindFirstChild("Display")
                if disp then
                    if disp:FindFirstChild("SETTING_TITLE") then
                        disp.SETTING_TITLE.Visible = false
                        pcall(function() disp.SETTING_TITLE.Text = "" end)
                    end
                    if disp:FindFirstChild("SETTING_DESCRIPTION") then
                        disp.SETTING_DESCRIPTION.Visible = false
                        pcall(function() disp.SETTING_DESCRIPTION.Text = "" end)
                    end
                end
            end)
        end
    end
end

-- Подписываемся на появления новых GUI (ReplicatedStorage и PlayerGui), чтобы автоматически скрывать вновь созданные
pcall(function()
    if Players.LocalPlayer then
        local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            pg.DescendantAdded:Connect(function(desc)
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    pcall(function() desc.Visible = false; desc.Text = ""; desc.TextTransparency = 1 end)
                end
            end)
        end
    end
end)

pcall(function()
    ReplicatedStorage.DescendantAdded:Connect(function(desc)
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            pcall(function() desc.Visible = false; desc.Text = ""; desc.TextTransparency = 1 end)
        end
    end)
end)

-- Запускаем периодическую проверку (каждые 4 секунды)
spawn(function()
    while wait(4) do
        checkPlayerGui()
        -- принудительно скрываем перечисленные пути ещё раз (на случай, если что-то восстановилось)
        for _, element in ipairs(guiElements) do
            applyHide(element)
        end
    end
end)

print("✨ Скрипт запущен — GUI будет скрываться автоматически (если находятся элементы).")
