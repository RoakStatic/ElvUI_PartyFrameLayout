local addonName, addonTable = ...

-- Grab ElvUI internals
local E, L, V, P, G = unpack(ElvUI)
local EP = LibStub("LibElvUIPlugin-1.0")

-- Create the plugin module
local PFLayout = E:NewModule("ElvUI_PartyFrameLayout", "AceEvent-3.0", "AceHook-3.0")

-- Default settings
P["ElvUI_PartyFrameLayout"] = {
    enable = false,
    buttonsPerRow = 1,
}

function PFLayout:ApplyLayout()
    if not E.db.ElvUI_PartyFrameLayout.enable then return end
    if not ElvUF_PartyGroup1 then return end

    local buttons = {}
    for i = 1, 5 do
        local button = _G["ElvUF_PartyGroup1UnitButton" .. i]
        if button then
            tinsert(buttons, button)
        end
    end
    if #buttons == 0 then return end

    local layoutDB = E.db.ElvUI_PartyFrameLayout
    local partyDB = E.db.unitframe.units.party
    local spacingX = partyDB.horizontalSpacing or 4
    local spacingY = partyDB.verticalSpacing or 4
    local growthDir = partyDB.growthDirection or "DOWN_RIGHT"
    local buttonsPerRow = layoutDB.buttonsPerRow or 1

    local xMult, yMult = 1, 1
    local anchorPoint = "TOPLEFT"

    if growthDir == "DOWN_RIGHT" then
        xMult, yMult = 1, -1
        anchorPoint = "TOPLEFT"
    elseif growthDir == "DOWN_LEFT" then
        xMult, yMult = -1, -1
        anchorPoint = "TOPRIGHT"
    elseif growthDir == "UP_RIGHT" then
        xMult, yMult = 1, 1
        anchorPoint = "BOTTOMLEFT"
    elseif growthDir == "UP_LEFT" then
        xMult, yMult = -1, 1
        anchorPoint = "BOTTOMRIGHT"
    end

    for _, btn in ipairs(buttons) do
        btn:ClearAllPoints()
    end

    local btnWidth = buttons[1]:GetWidth() or 80
    local btnHeight = buttons[1]:GetHeight() or 40

    for index, btn in ipairs(buttons) do
        local row = math.floor((index - 1) / buttonsPerRow)
        local col = (index - 1) % buttonsPerRow
        local offsetX = col * (btnWidth + spacingX) * xMult
        local offsetY = row * (btnHeight + spacingY) * yMult

        if index == 1 then
            btn:SetPoint(anchorPoint, _G["ElvUF_PartyMover"], anchorPoint, 0, 0)
        elseif col == 0 then
            btn:SetPoint(anchorPoint, buttons[index - buttonsPerRow], anchorPoint, 0, (btnHeight + spacingY) * yMult)
        else
            btn:SetPoint(anchorPoint, buttons[index - 1], anchorPoint, (btnWidth + spacingX) * xMult, 0)
        end
    end
end

function PFLayout:Update()
    if E.db.ElvUI_PartyFrameLayout.enable then
        self:ApplyLayout()
    else
        if ElvUF_PartyGroup1 and ElvUF_PartyGroup1.Update then
            ElvUF_PartyGroup1:Update()
        end
    end
end

function PFLayout:InsertOptions()
    E.Options.args.ElvUI_PartyFrameLayout = {
        order = 100,
        type = "group",
        name = "Party Frame Layout",
        args = {
            enable = {
                order = 1,
                type = "toggle",
                name = "Enable Layout Override",
                get = function(info) return E.db.ElvUI_PartyFrameLayout.enable end,
                set = function(info, value)
                    E.db.ElvUI_PartyFrameLayout.enable = value
                    PFLayout:Update()
                end,
            },
            buttonsPerRow = {
                order = 2,
                type = "range",
                name = "Buttons Per Row",
                min = 1, max = 5, step = 1,
                disabled = function() return not E.db.ElvUI_PartyFrameLayout.enable end,
                get = function(info) return E.db.ElvUI_PartyFrameLayout.buttonsPerRow end,
                set = function(info, value)
                    E.db.ElvUI_PartyFrameLayout.buttonsPerRow = value
                    PFLayout:ApplyLayout()
                end,
            },
        },
    }
end

function PFLayout:Initialize()
    EP:RegisterPlugin(addonName, PFLayout.InsertOptions)

    self:RegisterEvent("GROUP_ROSTER_UPDATE", "ApplyLayout")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        C_Timer.After(1, function()
            PFLayout:ApplyLayout()
        end)
    end)

    -- Hook into ElvUI's internal update function for party frames
    if ElvUF_PartyGroup1 and not self:IsHooked(ElvUF_PartyGroup1, "Update") then
        self:SecureHook(ElvUF_PartyGroup1, "Update", "ApplyLayout")
    end
end

E:RegisterModule(PFLayout:GetName())
