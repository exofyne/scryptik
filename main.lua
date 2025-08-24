local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()


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

-- Создание вкладок (исправлено)
local AutoBuyTab = Window:Tab({ 
    Title = "Auto Buy", 
    Icon = "shopping-cart" 
})

local AutoSellTab = Window:Tab({ 
    Title = "Auto Sell", 
    Icon = "dollar-sign" 
})

-- Добавляем элементы в вкладку Auto Buy
local SeedDropdown = AutoBuyTab:Dropdown({
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

local SeedToggle = AutoBuyTab:Toggle({
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

AutoBuyTab:Divider()

local GearDropdown = AutoBuyTab:Dropdown({
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

local GearToggle = AutoBuyTab:Toggle({
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

AutoBuyTab:Divider()

local EggDropdown = AutoBuyTab:Dropdown({
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

local EggToggle = AutoBuyTab:Toggle({
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

-- Добавляем элементы в вкладку Auto Sell
local SellDropdown = AutoSellTab:Dropdown({
    Title = "Sell Items",
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
        selectedSellItems = normalizeSelection(option)
        print("Sell selected: " .. game:GetService("HttpService"):JSONEncode(selectedSellItems)) 
    end
})

local SellToggle = AutoSellTab:Toggle({
    Title = "Auto Sell Items",
    Value = false,
    Callback = function(state)
        sellAutoRunning = state
        if sellAutoRunning then
            if sellLoopThread and coroutine.status(sellLoopThread) ~= "dead" then return end
            sellLoopThread = coroutine.create(function()
                while sellAutoRunning do
                    for _, item in ipairs(backpack:GetChildren()) do
                        for _, selectedItem in ipairs(selectedSellItems) do
                            if item.Name == selectedItem then
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
