local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["ru"] = {
            ["WINDUI_EXAMPLE"] = "WindUI Пример",
            ["WELCOME"] = "Добро пожаловать в WindUI!",
            ["LIB_DESC"] = "Библиотека для создания красивых интерфейсов",
            ["SETTINGS"] = "Настройки",
            ["APPEARANCE"] = "Внешний вид",
            ["FEATURES"] = "Функционал",
            ["UTILITIES"] = "Инструменты",
            ["UI_ELEMENTS"] = "UI Элементы",
            ["CONFIGURATION"] = "Конфигурация",
            ["SAVE_CONFIG"] = "Сохранить конфигурацию",
            ["LOAD_CONFIG"] = "Загрузить конфигурацию",
            ["THEME_SELECT"] = "Выберите тему",
            ["TRANSPARENCY"] = "Прозрачность окна"
        },
        ["en"] = {
            ["WINDUI_EXAMPLE"] = "WindUI Example",
            ["WELCOME"] = "Welcome to WindUI!",
            ["LIB_DESC"] = "Beautiful UI library for Roblox",
            ["SETTINGS"] = "Settings",
            ["APPEARANCE"] = "Appearance",
            ["FEATURES"] = "Features",
            ["UTILITIES"] = "Utilities",
            ["UI_ELEMENTS"] = "UI Elements",
            ["CONFIGURATION"] = "Configuration",
            ["SAVE_CONFIG"] = "Save Configuration",
            ["LOAD_CONFIG"] = "Load Configuration",
            ["THEME_SELECT"] = "Select Theme",
            ["TRANSPARENCY"] = "Window Transparency"
        }
    }
})

WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

local function gradient(text, startColor, endColor)
    local result = ""
    for i = 1, #text do
        local t = (i - 1) / (#text - 1)
        local r = math.floor((startColor.R + (endColor.R - startColor.R) * t) * 255)
        local g = math.floor((startColor.G + (endColor.G - startColor.G) * t) * 255)
        local b = math.floor((startColor.B + (endColor.B - startColor.B) * t) * 255)
        result = result .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, text:sub(i, i))
    end
    return result
end

WindUI:Popup({
    Title = gradient("KNock-hub Demo", Color3.fromHex("#6A11CB"), Color3.fromHex("#2575FC")),
    Icon = "sparkles",
    Content = "loc:LIB_DESC",
    Buttons = {
        {
            Title = "Get Started",
            Icon = "arrow-right",
            Variant = "Primary",
            Callback = function() end
        }
    }
})

local Window = WindUI:CreateWindow({
    Title = "KNock-hub",
    Icon = "palette",
    Folder = "KNock-hub",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    User = {
        Enabled = true,
        Anonymous = true,
        Callback = function()
            WindUI:Notify({
                Title = "User Profile",
                Content = "User profile clicked!",
                Duration = 3
            })
        end
    },
    SideBarWidth = 200,
})

Window:Tag({
    Title = "v1.0",
    Color = Color3.fromHex("#30ff6a")
})

-- главные заголовки
local Tabs = {
    Auto = Window:Section({ Title = "Automation", Opened = true }),
}

-- подзаголовки
local TabHandles = {
    Elements = Tabs.Auto:Tab({ Title = "Auto buy", Icon = "layout-grid"}),
    Sellements = Tabs.Auto:Tab({ Title = "Auto sell", Icon = "layout-grid"}),
}

-- Сервисы и RemoteEvents
local RS = game:GetService("ReplicatedStorage")
local BuySeedRE = RS:WaitForChild("GameEvents"):WaitForChild("BuySeedStock")
local BuyGearRE = RS:WaitForChild("GameEvents"):WaitForChild("BuyGearStock")
local BuyEggRE = RS:WaitForChild("GameEvents"):WaitForChild("BuyPetEgg")
local SellItemRE = RS:WaitForChild("GameEvents"):WaitForChild("Sell_Item")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayers
local backpack = LocalPlayer:WaitForChild("Backpack")

-- Функции для нормализации
local function normalizeSelection(option)
    if typeof(option) == "string" then
        return { option }
    elseif typeof(option) == "table" then
        if option[1] ~= nil then
            return option
        end
        local out = {}
        for k, v in pairs(option) do
            if v then table.insert(out, k) end
        end
        return out
    end
    return {}
end

-- Функции покупки
local function BuySeed(seedName)
    if type(seedName) ~= "string" or seedName == "" or seedName == "not" then return end
    BuySeedRE:FireServer(seedName)
end

local function BuyGear(gearName)
    if type(gearName) ~= "string" or gearName == "" or gearName == "not" then return end
    BuyGearRE:FireServer(gearName)
end

local function BuyEgg(eggName)
    if type(eggName) ~= "string" or eggName == "" or eggName == "not" then return end
    BuyEggRE:FireServer(eggName)
end

local function SellItem(seedsName)
        if type(seedsName) ~= "string" or seedsName == "" or seedsName == "not" then return end
    SellItemRE:FireServer(seedsName)
end

-- ПЕРЕМЕННЫЕ ДЛЯ SEEDS
local selectedSeeds = {}
local seedAutoRunning = false
local seedLoopThread = nil
local seedInterval = 0.5

-- ПЕРЕМЕННЫЕ ДЛЯ GEARS
local selectedGears = {}
local gearAutoRunning = false
local gearLoopThread = nil
local gearInterval = 0.5

-- ПЕРЕМЕННЫЕ ДЛЯ EGG
local selectedEggs = {}
local eggAutoRunning = false
local eggLoopThread = nil
local eggInterval = 0.5

-- ПЕРЕМЕННЫЕ ДЛЯ SELL ONE
local selectedItems = {}
local sellAutoRunning = false
local sellLoopThread = nil
local sellInterval = 0.5

-- SEED DROPDOWN
local SeedDropdown = TabHandles.Elements:Dropdown({
    Title = "Seed Shop",
    Values = { "Carrot", "Tomato", "Strawberry", "Blueberry", "Orange Tulip",
    "Corn", "Daffodil", "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut",
    "Cactus", "Dragon Fruit", "Mango", "Grape", "Mushroom", "Pepper", "Cacao",
    "Beanstalk", "Ember Lily", "Sugar Apple", "Burning Bud", "Giant Pinecone",
    "Elder Strawberry", "Romanesco"
    },
    Value = { "not" },
    Multi = true,
    AllowNone = true,
    Callback = function(option)
        selectedSeeds = normalizeSelection(option)
        print("Seeds selected: " .. game:GetService("HttpService"):JSONEncode(selectedSeeds)) 
    end
})

-- SEED TOGGLE
local SeedToggle = TabHandles.Elements:Toggle({
    Title = "Auto buy Seeds",
    Value = false,
    Callback = function(state)
        seedAutoRunning = state
        if seedAutoRunning then
            if seedLoopThread and coroutine.status(seedLoopThread) ~= "dead" then return end
            seedLoopThread = coroutine.create(function()
                while seedAutoRunning do
                    for _, seed in ipairs(selectedSeeds) do
                        BuySeed(seed)
                        task.wait(0.05)
                    end
                    task.wait(seedInterval)
                end
            end)
            coroutine.resume(seedLoopThread)
            WindUI:Notify({ Title = "Auto Buy Seeds", Content = "Started", Duration = 2 })
        else
            WindUI:Notify({ Title = "Auto Buy Seeds", Content = "Stopped", Duration = 2 })
        end
    end
})

TabHandles.Elements:Divider()

-- GEAR DROPDOWN
local GearDropdown = TabHandles.Elements:Dropdown({
    Title = "Gear Shop",
    Values = { "Watering Can", "Trowel", "Trading Ticket", "Recall Wrench", "Basic Sprinkler",
    "Firework", "Advanced Sprinkler", "Medium Treat", "Medium Toy", "Godly Sprinkler", "Magnifying Glass",
    "Master Sprinkler", "Cleaning Spray", "Favorite Tool", "Harvest Tool", "Friendship Pot", "Level Up Lollipop",
    "Grandmaster Sprinkler", "Lightning Rod", "Tanning Mirror"
    },
    Value = { "not" },
    Multi = true,
    AllowNone = true,
    Callback = function(option)
        selectedGears = normalizeSelection(option)
        print("Gears selected: " .. game:GetService("HttpService"):JSONEncode(selectedGears)) 
    end
})

-- GEAR TOGGLE
local GearToggle = TabHandles.Elements:Toggle({
    Title = "Auto buy Gears",
    Value = false,
    Callback = function(state)
        gearAutoRunning = state
        if gearAutoRunning then
            if gearLoopThread and coroutine.status(gearLoopThread) ~= "dead" then return end
            gearLoopThread = coroutine.create(function()
                while gearAutoRunning do
                    for _, gear in ipairs(selectedGears) do
                        BuyGear(gear)
                        task.wait(0.05)
                    end
                    task.wait(gearInterval)
                end
            end)
            coroutine.resume(gearLoopThread)
            WindUI:Notify({ Title = "Auto Buy Gears", Content = "Started", Duration = 2 })
        else
            WindUI:Notify({ Title = "Auto Buy Gears", Content = "Stopped", Duration = 2 })
        end
    end
})

TabHandles.Elements:Divider()

-- EGG DROPDOWN
local EggDropdown = TabHandles.Elements:Dropdown({
    Title = "Pet Shop",
    Values = { "Common Egg", "Uncommon Egg", "Rare Egg", "Legendary Egg", "Mythical Egg",
    "Bug Egg",
    },
    Value = { "not" },
    Multi = true,
    AllowNone = true,
    Callback = function(option)
        selectedEggs = normalizeSelection(option)
        print("Eggs selected: " .. game:GetService("HttpService"):JSONEncode(selectedEggs)) 
    end
})

-- EGG TOGGLE
local EggToggle = TabHandles.Elements:Toggle({
    Title = "Auto buy Egg",
    Value = false,
    Callback = function(state)
        eggAutoRunning = state
        if eggAutoRunning then
            if eggLoopThread and coroutine.status(eggLoopThread) ~= "dead" then return end
            eggLoopThread = coroutine.create(function()
                while eggAutoRunning do
                    for _, egg in ipairs(selectedEggs) do
                        BuyEgg(egg)
                        task.wait(0.05)
                    end
                    task.wait(eggInterval)
                end
            end)
            coroutine.resume(eggLoopThread)
            WindUI:Notify({ Title = "Auto Buy Eggs", Content = "Started", Duration = 2 })
        else
            WindUI:Notify({ Title = "Auto Buy Eggs", Content = "Stopped", Duration = 2 })
        end
    end
})

-- SELL DROPDOWN
local SellDropdown = TabHandles.Sellements:Dropdown({
    Title = "Sell Fruit",
    Values = { "Carrot", "Tomato", "Strawberry", "Blueberry", "Orange Tulip",
    "Corn", "Daffodil", "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut",
    "Cactus", "Dragon Fruit", "Mango", "Grape", "Mushroom", "Pepper", "Cacao",
    "Beanstalk", "Ember Lily", "Sugar Apple", "Burning Bud", "Giant Pinecone",
    "Elder Strawberry", "Romanesco"
    },
    Value = { "not" },
    Multi = true,
    AllowNone = true,
    Callback = function(option)
        selectedSeeds = normalizeSelection(option)
        print("Sell selected: " .. game:GetService("HttpService"):JSONEncode(selectedSellItems)) 
    end
})

-- SELL TOGGLE
local SellToggle = TabHandles.Sellements:Toggle({
    Title = "Auto Sell Items",
    Value = false,
    Callback = function(state)
        sellAutoRunning = state
        if sellAutoRunning then
            if sellLoopThread and coroutine.status(sellLoopThread) ~= "dead" then return end
            sellLoopThread = coroutine.create(function()
                while sellAutoRunning do
                    for _, item in ipairs(backpack:GetChildren()) do
                        for _, selectedItems in ipairs(selectedItems) do
                            if item.Name == selectedItems then
                                SellItem(item.Name)
                                task.wait(0.05)
                                break
                            end
                        end
                    end    
                    task.wait(sellInterval)
                end
            end)
            coroutine.resume(sellLoopThread)
            WindUI:Notify({ Title = "Auto Sell Items", Content = "Started", Duration = 2 })
        else
            WindUI:Notify({ Title = "Auto Sell Items", Content = "Stopped", Duration = 2 })
        end
    end
})
