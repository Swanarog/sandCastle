-- lancher.lua - The Dominos minimap button
local AddonName, Addon = ...
local Launcher = Addon:NewModule('Launcher')
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local DBIcon = LibStub('LibDBIcon-1.0')

function Launcher:OnInitialize()
    DBIcon:Register(AddonName, self:CreateDataBrokerObject(), self:GetSettings())
end

function Launcher:Load()
    self:Update()
end

function Launcher:Update()
    DBIcon:Refresh(AddonName, self:GetSettings())
end

function Launcher:GetSettings()
    return Addon.db.profile.minimap
end

function Launcher:CreateDataBrokerObject()
    return LibStub('LibDataBroker-1.1'):NewDataObject(
        AddonName,
        {
            type = 'launcher',
            icon = ([[Interface\Addons\%s\%s]]):format(AddonName, AddonName),
            OnClick = function(_, button)
                if button == 'LeftButton' then
					Addon:ToggleConfig()
                elseif button == 'RightButton' then
                    --Addon:ShowOptionsFrame()
                end
            end,
            OnTooltipShow = function(tooltip)
                if not tooltip or not tooltip.AddLine then
                    return
                end

                GameTooltip_SetTitle(tooltip, AddonName)

                if Addon:Locked() then
                    GameTooltip_AddInstructionLine(tooltip, L.ConfigExitTip)
                else
                    GameTooltip_AddInstructionLine(tooltip, L.ConfigEnterTip)
                end
            end
        }
    )
end
