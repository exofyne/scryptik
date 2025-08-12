-- Скрипт для отключения всех торговых GUI элементов в Grow a Garden
-- Вставьте этот код в консоль разработчика (F9 -> Console)

local function safeDisable(path, property, value)
    local success, result = pcall(function()
        local obj = loadstring("return " .. path)()
        if obj then
            if property == "Visible" then
                obj.Visible = value
            elseif property == "Text" then
                obj.Text = value
            elseif property == "TextTransparency" then
                obj.TextTransparency = value
            end
            print("✅ Отключен: " .. path)
        else
            print("❌ Не найден: " .. path)
        end
    end)
    
    if not success then
        print("❌ Ошибка с: " .. path)
    end
end

-- Список всех GUI элементов для отключения
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

    'game:GetService("Players").LocalPlayer.PlayerGui.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT:GetChildren()[5].Display.SETTING_TITLE',
    'game:GetService("Players").LocalPlayer.PlayerGui.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT:GetChildren()[5].Display.SETTING_DESCRIPTION',
    'game:GetService("Players").LocalPlayer.PlayerGui.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT:GetChildren()[6].Display.SETTING_DESCRIPTION',
    'game:GetService("Players").LocalPlayer.PlayerGui.SettingsUI.SettingsFrame.Main.Holder.SETTING_INSERTION_POINT:GetChildren()[6].Display.SETTING_TITLE',
    'game:GetService("Players").LocalPlayer.PlayerGui.TradingUI.Main.Main.Holder.Header.Title',
    -- StarterGui элементы
    'game:GetService("StarterGui").Trading.FinalizingTrade.Text'
}

print("🚀 Начинаем отключение торговых GUI...")
print("===========================================")

-- Отключаем все элементы
for i, element in pairs(guiElements) do
    -- Пробуем разные методы отключения
    safeDisable(element, "Visible", false)  -- Делаем невидимым
    safeDisable(element, "Text", "")        -- Очищаем текст
    safeDisable(element, "TextTransparency", 1)  -- Делаем прозрачным
end

print("===========================================")
print("✨ Готово! Все торговые GUI отключены")

-- Дополнительная проверка для PlayerGui (может появиться позже)
local function checkPlayerGui()
    local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
    
    -- Проверяем Trading GUI
    if playerGui:FindFirstChild("Trading") then
        local trading = playerGui.Trading
        if trading:FindFirstChild("FinalizingTrade") then
            trading.FinalizingTrade.Visible = false
            trading.FinalizingTrade.Text = ""
            print("✅ Дополнительно отключен PlayerGui Trading")
        end
    end
    
    -- Проверяем TradingUI
    if playerGui:FindFirstChild("TradingUI") then
        local tradingUI = playerGui.TradingUI
        -- Рекурсивно скрываем все элементы
        local function hideAll(parent)
            for _, child in pairs(parent:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    child.Visible = false
                    if child:FindFirstChild("Text") then
                        child.Text = ""
                    end
                end
                hideAll(child)
            end
        end
        hideAll(tradingUI)
        print("✅ Дополнительно отключен весь TradingUI")
    end
end

-- Запускаем дополнительную проверку
checkPlayerGui()

-- Устанавливаем проверку каждые 5 секунд на случай появления новых GUI
spawn(function()
    while wait(5) do
        checkPlayerGui()
    end
end)
