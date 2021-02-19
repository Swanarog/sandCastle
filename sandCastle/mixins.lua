local sandCastle = LibStub("AceAddon-3.0"):GetAddon(...)

sandCastleSecureFrameMixin = {}
local mixin = sandCastleSecureFrameMixin

local frame_UpdateShown = [[
    if self:GetAttribute("state-hidden") then
        self:Hide()
        return
    end

    local isPetBattleUIShown = self:GetAttribute('state-petbattleui') and true or false
    if isPetBattleUIShown and not self:GetAttribute('state-showinpetbattleui') then
        self:Hide()
        return
    end

    local isOverrideUIShown = self:GetAttribute('state-overrideui') and true or false
    if isOverrideUIShown and not self:GetAttribute('state-showinoverrideui') then
        self:Hide()
        return
    end

    local requiredState = self:GetAttribute('state-display')
    if requiredState == 'hide' then
        self:Hide()
        return
    end

    local userState = self:GetAttribute('state-userDisplay')
    if userState == 'hide' then
        if self:GetAttribute('state-alpha') then
            self:SetAttribute('state-alpha', nil)
        end

        self:Hide()
        return
    end

    local userAlpha = tonumber(userState)
    if self:GetAttribute('state-alpha') ~= userAlpha then
        self:SetAttribute('state-alpha', userAlpha)
    end

    self:Show()
]]

local frame_CallUpdateShown = 'self:RunAttribute("UpdateShown")'

function mixin:OnLoad()
    self:SetAttribute('_onstate-display', frame_CallUpdateShown)
    self:SetAttribute('_onstate-hidden', frame_CallUpdateShown)
    self:SetAttribute('_onstate-overrideui', frame_CallUpdateShown)
    self:SetAttribute('_onstate-petbattleui', frame_CallUpdateShown)
    self:SetAttribute('_onstate-showinoverrideui', frame_CallUpdateShown)
    self:SetAttribute('_onstate-showinpetbattleui', frame_CallUpdateShown)
    self:SetAttribute('_onstate-userDisplay', frame_CallUpdateShown)

    self:SetAttribute('UpdateShown', frame_UpdateShown)
end


--------------------------------------------------------------------------------
-- Display Conditions - Pet Battle UI
--------------------------------------------------------------------------------

function mixin:ShowInPetBattleUI(enable)
    self.sets.showInPetBattleUI = enable and true or false
    self:SetAttribute('state-showinpetbattleui', enable)
end

function mixin:ShowingInPetBattleUI()
    return self.sets.showInPetBattleUI
end

--------------------------------------------------------------------------------
-- Display Conditions
--------------------------------------------------------------------------------

function mixin:GetDisplayConditions() end

function mixin:UpdateDisplayConditions()
    local conditions = self:GetDisplayConditions()

    if conditions and conditions ~= '' then
        RegisterStateDriver(self, 'display', conditions)
    else
        UnregisterStateDriver(self, 'display')

        if self:GetAttribute('state-display') then
            self:SetAttribute('state-display', nil)
        end
    end
end

--------------------------------------------------------------------------------
-- Display Conditions - User Set
--------------------------------------------------------------------------------

function mixin:SetUserDisplayConditions(states)
    self.widget.sets.showstates = states
    self:UpdateUserDisplayConditions()
end

function mixin:GetUserDisplayConditions()
    local states =  self.widget.sets.showstates

    -- hack to convert [combat] into [combat]show;hide in case a user is using
    -- the old style of showstates
    if states then
        if states:sub(#states) == ']' then
            states = states .. 'show;hide'
             self.widget.sets.showstates = states
        end
    end

    return states or ""
end

function mixin:UpdateUserDisplayConditions()
    local states = self:GetUserDisplayConditions()

    if states and states ~= '' then
        RegisterStateDriver(self, 'userDisplay', states)
    else
        UnregisterStateDriver(self, 'userDisplay')

        if self:GetAttribute('state-userDisplay') then
            self:SetAttribute('state-userDisplay', nil)
        end
    end
end

do --advanced Display Conditions
	local showStates = {
		Hide = "hide;show",
		Show = "show;hide",
		Opacity = "100;50", --help newbies get started!
	}


	local function tIndexOf(tbl, item)
		for i, v in pairs(tbl) do
			if item == v then
				return i;
			end
		end
	end

	local function tContains(tbl, item)
		return tIndexOf(tbl, item) ~= nil;
	end

	local function capitalize(word)
		if not word then return end
		if string.match(word, '%d+') then 
			return word --don't change numbers
		end
		local first, rest = strsub(word, 1, 1) , strsub(word, 2) 		
		return strupper(first)..rest
	end

	function mixin:SplitShowStates()
		local states = self:GetUserDisplayConditions()
		if (not states) or states == "" then return end
		states = strfind(states, "]") and gsub(states, "]", "]-") or states
		local splitIndex = strfind(states, ";")
		local a, b = splitIndex and strsub(states, 1, splitIndex-1) or a, splitIndex and strsub(states, splitIndex + 1) or b
		local aStates = {strsplit("-", a )}
		local bStates = {strsplit("-", b )}
		
		local stateA = aStates[#aStates], tremove(aStates, #aStates)
		local stateB = bStates[#bStates], tremove(bStates, #bStates)
		
		return stateA, aStates, stateB, bStates
	end

	function mixin:GetCurrentUserDisplayOptions()
		local stateA, _, stateB, _ = self:SplitShowStates()
		
		if not (stateA and stateB) then
			return {
				{"Disable", "disable"},
			}	
		end
		
		return {
			{capitalize(stateA), stateA},
			{capitalize(stateB), stateB},
			{"Disable", "disable"},
		}		
	end
	
	function mixin:GetUserDisplayConditionState(condition)
		local stateA, aStates, stateB, bStates = self:SplitShowStates()
		
		if not (aStates and bStates) then return "disable" end

		
		if tContains(aStates, condition) then
			return stateA
		elseif tContains(bStates, condition) then
			return stateB
		else
			return "disable"
		end
	end

	function mixin:GetCurrentUserDisplay()
		local stateA, _, stateB, _ = self:SplitShowStates()
		
		if not (stateA and stateB) then return self:SetUserDisplayConditions(nil) end
		
		local state = strjoin(";", stateA, stateB)
		
		if tContains(showStates, state) then
			return tIndexOf(showStates, state)
		elseif string.match(state, '%d+') then
			return "Opacity"
		else
			return "disable"
		end
	end

	function mixin:SetCurrentUserDisplay(state)
		local stateA, aStates, stateB, bStates = self:SplitShowStates()
		
		local state = state and showStates[state]
		if not state then return self:SetUserDisplayConditions(nil) end
		
		local splitIndex = strfind(state, ";")
		local newStateA, newStateB = splitIndex and strsub(state, 1, splitIndex-1) or stateA, splitIndex and strsub(state, splitIndex + 1) or stateB
		local a, b = (aStates and strjoin("", unpack(aStates)) or "")..newStateA, (bStates and strjoin("", unpack(bStates)) or "")..newStateB

		return self:SetUserDisplayConditions(strjoin(";", a, b)) 
	end

	function mixin:UpdateUserDisplayCondition(condition, state)
		local stateA, aStates, stateB, bStates = self:SplitShowStates()
		
		if not (condition and stateA and stateB) then return end
		
		tDeleteItem(aStates, condition)
		tDeleteItem(bStates, condition)
		
		if state == stateA then
			tinsert(aStates, condition)
		elseif state == stateB then
			tinsert(bStates, condition)
		end
		
		if #aStates == 0 and #bStates == 0 then
			return self:SetUserDisplayConditions(nil)
		end
		
		local a, b = (strjoin("", unpack(aStates)) or "")..stateA, (strjoin("", unpack(bStates)) or "")..stateB

		return self:SetUserDisplayConditions(strjoin(";", a, b))
	end
end