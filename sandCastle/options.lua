local AddonName, Addon = ...
local sandCastle = _G.LibStub("AceAddon-3.0"):GetAddon(...)

-- Options Menu, maybe?
local menus = Addon:NewModule('OptionsMenu')

local OPTS = {}

local sliderIndex = 0

function OPTS.checkButton(menu, title, get, set, values)
	local checkButton = _G.CreateFrame('CheckButton', nil, menu, "UICheckButtonTemplate")

	checkButton.text:SetText(title)
	checkButton:SetScript('OnShow', function(button)
		if get then
			checkButton:SetChecked(get(menu.widget))
		end
	end)
	checkButton:SetScript('OnClick', function(button)
		if set then
			set(menu.widget, checkButton:GetChecked())
		end
	end)
	if menu.lastItem then

		checkButton:SetPoint("TopLeft", menu.lastItem, "BottomLeft", 0, -5)

	else
		checkButton:SetPoint("TopLeft", menu, 0, -5)
	end
	
	local r = checkButton.text:GetWidth() or 0
	
	checkButton:SetHitRectInsets(0, -r, -3, -3)
	
	checkButton.height = checkButton:GetHeight() - 8
	
	menu.lastItem = checkButton
	return checkButton
end

function OPTS.slider(menu, title, get, set, values)

	sliderIndex = sliderIndex + 1

	local slider = CreateFrame("Slider", AddonName.."Slider"..sliderIndex, menu, "HorizontalSliderTemplate")

	 slider:SetHitRectInsets(0, 0, -10, 3)
	if menu.lastItem then

		slider:SetPoint("TopLeft", menu.lastItem, "BottomLeft", 5, -15)

	else
		slider:SetPoint("TopLeft", menu, -5, -15)
	end

	slider:SetSize(menu:GetWidth()-10, 18)
	
	local _min, _max, step, shiftStep = unpack(values)
	
	slider:SetMinMaxValues(_min, _max)
	slider:SetValueStep(step)
	
	slider:SetScript("OnShow", function()
		local func = slider.get or get
		if func and func(menu.widget) then
			slider:SetValue(func(menu.widget))
		else
			slider:SetValue(_min + ((math.abs(_min) + math.abs(_max)) /2))
		end
	end)

	local editbox = CreateFrame("EditBox", nil, slider)

	slider:SetScript("OnValueChanged", function(_, value)
	
		local func = slider.set or set
	
		if func then
			func(menu.widget, value)
		end
		editbox:SetText(math.floor(value))
	end)
	
	slider.title = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	slider.title:SetText(title)
	slider.title:SetPoint("BottomLeft", slider, "TopLeft")
	slider.title:SetJustifyH("LEFT")
	slider.title:SetJustifyV("TOP") 
	
	slider:SetScript("OnMouseWheel", function(_,delta)
		local _step = (IsShiftKeyDown() == true) and shiftStep
		or (IsControlKeyDown() == true) and shiftStep * 2
		or (IsAltKeyDown() == true) and shiftStep * 4
		or step
		slider:SetValue(slider:GetValue() + (delta * _step))
	end)

	editbox:SetScript("OnMouseWheel", function(_,delta)
		local _step = (IsShiftKeyDown() == true) and shiftStep
		or (IsControlKeyDown() == true) and shiftStep * 2
		or (IsAltKeyDown() == true) and shiftStep * 4
		or step
		slider:SetValue(slider:GetValue() + (delta * _step))
	end)
	
	editbox:SetAutoFocus(false)
	editbox:SetFontObject(GameFontHighlightSmall)
	editbox:SetPoint("BottomRight", slider, "TopRight", -2, 0)
	editbox:SetHeight(10)
	editbox:SetWidth(70)
	editbox:SetJustifyH("RIGHT")
	editbox:EnableMouse(true)
	editbox:SetScript("OnEnterPressed", function() slider:SetValue(tonumber(editbox:GetText())) end)
	editbox:SetScript("OnEscapePressed", function() editbox:ClearFocus() editbox:SetText(math.floor(slider:GetValue())) end)
		
	menu.lastItem = slider
	
	slider.height = slider:GetHeight() + slider.title:GetHeight() + 3
	
	return slider
end

local function tIndexOf(tbl, item)
		for i, v in pairs(tbl) do
			if item == v then
				return i;
			end
		end
	end

function OPTS.editBox(menu, title, get, set)
	local editBox = CreateFrame("EditBox", nil, menu, "BackdropTemplate")
	--editBox:SetPoint("TopLeft", 0, 0)
	editBox:SetFontObject("GameFontNormal")

	editBox.title = editBox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	editBox.title:SetText(title)
	editBox.title:SetPoint("BottomLeft", editBox, "TopLeft", 0 , 2)
	editBox.title:SetJustifyH("LEFT")
	editBox.title:SetJustifyV("TOP") 
	
	editBox:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Glues\\Common\\TextPanel-Border",
		tile = true,
		tileEdge = true,
		tileSize = 32,
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	editBox:SetTextInsets(8, 8, 5, 5)

	editBox:SetBackdropColor(0,0,0)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)

	editBox:SetScript("OnEnterPressed", function(_, text)
		local func = editBox.set or set
		if func then
			func(menu.widget, editBox:GetText())
		end
		editBox.TEXT = nil
		editBox:ClearFocus()
	end)
	
	editBox:SetScript("OnEscapePressed", function(_, text)
		editBox:ClearFocus()
	end)
	
	editBox:SetScript("OnEditFocusGained", function(_, text)
		editBox.TEXT = editBox:GetText()
	end)
	
	editBox:SetScript("OnEditFocusLost", function(_, text)
		if editBox.TEXT then
			editBox:SetText(editBox.TEXT)
		end
	end)

	editBox:SetScript("OnShow", function(_, text)
		local func = editBox.get or get
		if func then
			editBox:SetText(func(menu.widget) or "")
		end
		
	end)
	
	editBox:SetSize(menu:GetWidth()-10, 100)

	editBox.height =  editBox:GetHeight() + editBox.title:GetHeight() + 3
	
	return editBox
end

function OPTS.dropDown(menu, title, get, set, options)
	local block  = CreateFrame("Frame", nil , menu)
	local button = CreateFrame("Frame", nil, block, "UIDropDownMenuTemplate")
	
	block:SetSize(40, 45)
	button.Text:SetText(title or "")
	
	button.title = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	button.title:SetText(title)
	button.title:SetPoint("TopLeft", block, "TopLeft", 0,-2)
	button.title:SetJustifyH("LEFT")
	button.title:SetJustifyV("TOP") 
	
	button:SetPoint("BottomLeft" , -17, 0)
	button:SetPoint("Top", block, "Bottom" , 0, 32)
	
	local poo = {}
	for i , details in pairs((type(options) == "function" and options()) or menu.options or options or {}) do
		local text, value = unpack(details)
		poo[text] = value
 	end
	
	UIDropDownMenu_Initialize(button, function(button, menuLevel, menuList)
		if menuLevel == nil then return end
		for i , details in pairs((type(options) == "function" and options()) or menu.options or options or {}) do
			local info = UIDropDownMenu_CreateInfo()
			info.text, info.value = unpack(details)
	
			local func = button.get or get
			if func then
				info.selected = func(menu.widget) == info.value
			end
			
			info.func = function()
				local func = button.set or set
				if func then
					func(menu.widget, info.value)
					UIDropDownMenu_SetSelectedValue(button, info.value, useValue)
				end
			end
			UIDropDownMenu_AddButton(info, menuLevel)
		end
	
		local func = button.get or get
		if func then
			UIDropDownMenu_SetSelectedValue(button, func(menu.widget), useValue)
		end
	end)
	
	block:SetScript("OnShow", function()
		local func = button.get or get
		if func then
			UIDropDownMenu_SetText(button, tIndexOf(poo, func(menu.widget)))
		end
	end)
	
	block.height = block:GetHeight() --+ button.title:GetHeight()

	return block
end

local dropIndex = 0

local function pageHandler(menu)
	local dropDown = CreateFrame("Button", menu:GetName().."dropDown"..dropIndex, menu, "UIDropDownMenuTemplate")
	dropDown.Text:SetFontObject(GameFontNormal)
	dropDown:SetPoint("TopLeft",-5, -38)
	dropIndex = dropIndex + 1
	dropDown:SetScale(.75)

	UIDropDownMenu_Initialize(dropDown, function(button, menuLevel, menuList)
		if menuLevel == nil then return end
		for i , panel in pairs(menu.options) do
			local name, opts = unpack(panel)
			if menu.active and menu.active.id == name then
			
			else
				local info = UIDropDownMenu_CreateInfo()
				info.notCheckable = true
				info.text = name
				info.value = name
				info.func = function()
					if menu.active then
						menu.active:Hide()
					end
					menu.panels[i]:Show()
					
					UIDropDownMenu_SetText(button, name)
				end
				UIDropDownMenu_AddButton(info, menuLevel)
			end
		end
	end)


	return dropDown
end

function OPTS.panel(menu, name, options)
	local parentPanel = menu.SettingsPanel
	local widget = menu.widget
	menu.dropDown = menu.dropDown or pageHandler(menu)

	local subPanel = CreateFrame("Frame", nil, parentPanel)
	subPanel:SetPoint("TopLeft", menu, 5, -45)
	tinsert(menu.panels, subPanel)
	subPanel:SetSize(140, 245)
	subPanel.widget = widget
	subPanel.widgets = {}
	subPanel.id = name
	subPanel:Hide()

	subPanel.scoller = CreateFrame("Slider", (widget.displayID or widget.id).."Slider", menu, "HorizontalSliderTemplate")

	subPanel.scoller:SetOrientation("VERTICAL")

	subPanel.scoller:SetPoint("BottomLeft", menu, "BottomRight", -4, -2)

	subPanel.scoller:SetSize(11, menu:GetHeight() - 56)

	
	subPanel.scoller:SetScript("OnMouseWheel", function(_, delta)
		subPanel.scoller:SetValue(subPanel.scoller:GetValue() - (delta*25))
	end)

	subPanel.scoller:SetScript("OnValueChanged", function(_, value)
		subPanel:SetPoint("TopLeft", menu, 5, -44 + value)
	end)

	subPanel:SetScript("OnShow", function()
		for i, b in pairs(menu.panels) do
			if b ~= subPanel then
				b:Hide()
			end
		end
		menu.dropDown.Text:SetText(name)
		subPanel.scoller:Show()
		menu.PANEL = subPanel
	end)

	subPanel:SetScript("OnHide", function()
		subPanel.scoller:Hide()
	end)

	subPanel.scoller:Hide()

	local height = 0
	for i, b in pairs(options) do
		local style, title, get, set, values = unpack(b)
		if OPTS[style] then
			local b = OPTS[style](subPanel, title, get, set, values)

			height = height + b.height
			
			b:ClearAllPoints()
			b:SetPoint("BottomLeft", b:GetParent(), "TopLeft", 5, -(height+10))
			b:SetPoint("TopLeft", b:GetParent(), "TopLeft", 5, -((height - b:GetHeight()) + 10))
			subPanel.scoller:SetMinMaxValues(1, max(1, (height - menu:GetHeight()) + 52))
		end
	end

		subPanel.scoller:SetValue(1)
		

	return subPanel
end

local GetRelPos = function(self)
	local width, height = GetScreenWidth()/self:GetScale(), GetScreenHeight()/self:GetScale()
	local x, y = self:GetCenter()
	local xOffset, yOffset
	local Hori = (x > width/2) and 'RIGHT' or 'LEFT'
	if Hori == 'RIGHT' then
		xOffset = self:GetRight() - width
	else
		xOffset = self:GetLeft()
	end
	local Vert = (y > height/2) and 'TOP' or 'BOTTOM'
	if Vert == 'TOP' then
		yOffset = self:GetTop() - height
	else
		yOffset = self:GetBottom()
	end
	return Vert, Hori, xOffset, yOffset
end

local function SelectProperSide(self)
	local width = GetScreenWidth()

	local Vert, Hori, xOffset, yOffset = GetRelPos(self)
	local vert, hori

	if Vert == "TOP" then
		vert = "BOTTOM"
	elseif Vert == "BOTTOM" then
		vert = "TOP"
	end

	if Hori == "LEFT" then
		hori = "RIGHT"
	elseif Hori == "RIGHT" then
		hori = "LEFT"
	end

	return Hori, hori
end

local panels = {}
local mScale = 100

local states = {
		{"Bear Form",      "[bonusbar:3]"},
		{"Prowl",          "[bonusbar:1,stealth]"},
		{"Cat Form",       "[bonusbar:1]"},
		{"Moonkin Form",   "[bonusbar:4]"},
		{"Treant Form",    "[form:5]"}, 
		{"Travel Form",    "[form:3]"}, 
		{"Mount Form",     "[form:6]"},
		{"Action Page 2",  "[bar:2]"},
		{"Action Page 3",  "[bar:3]"},
		{"Action Page 4",  "[bar:4]"},
		{"Action Page 5",  "[bar:5]"},
		{"Action Page 6",  "[bar:6]"}, 
		{"Self Cast Key",  "[mod:SELFCAST]"},
		{"CTRL-ALT-SHIFT", "[mod:alt,mod:ctrl,mod:shift]"},
		{"CTRL-ALT",       "[mod:alt,mod:ctrl]"},
		{"ALT-SHIFT",      "[mod:alt,mod:shift]"}, 
		{"CTRL-SHIFT",     "[mod:ctrl,mod:shift]"}, 
		{"ALT key",        "[mod:alt]"}, 
		{"CTRL key",       "[mod:ctrl]"}, 
		{"SHIFT key",      "[mod:shift]"}, 
		{"Meta Key",       "[mod:meta]"},
		{"Help",           "[help]"}, 
		{"Harm",           "[harm]"}, 
		{"No Target",      "[noexists]"},
	 }

local comp = {}

function Addon:NewMenu(widget, options)
	if menus[widget.id] then
		return menus[widget.id]
	end

	if not IsShiftKeyDown() then
		for i, b in pairs(panels) do
			b:Hide()
		end
	end

	local menu = CreateFrame("ScrollFrame", widget:GetName().."Menu", self.configOverlay, BackdropTemplateMixin and 'BackdropTemplate')
	menu:SetBackdrop(BACKDROP_TOAST_12_12)
	menu:SetBackdropColor(0, 0, 0, .45)
	menu:SetClampedToScreen(true)
	menu:SetFrameStrata("HIGH")
	menus[widget.id] = menu
	
	menu.scroll = CreateFrame("ScrollFrame", nil, menu)
	menu.scroll:SetPoint("BottomRight",0, 5)
	menu.scroll:SetPoint("TopLeft", 0, -52)
	
	menu.SettingsPanel = CreateFrame("Frame", nil, menu.scroll)
	menu.scroll:SetScrollChild(menu.SettingsPanel)
	
	local options = Addon.utility.tDuplicate(options)
	
	local display = {
		"Display",
		{
			{
				"dropDown",
				"State",
				function(parent) --getter
					return widget.frame:GetCurrentUserDisplay()
				end,
				function(parent, value) --setter
					widget.frame:SetCurrentUserDisplay(value)
					if menu.PANEL then
						menu.PANEL:Hide()
						menu.PANEL:Show()
					end
				end,
				function()
					return {
						{_G.DISABLE, "disable"},
						{"Hide",_G.HIDE},
						{"Show",_G.SHOW},
						{"Opacity","Opacity"},
					}
				end,
			},
		
			{
				"editBox",
				"Display State",
				function(parent) --getter
					return widget.frame:GetUserDisplayConditions()
				end,
				function(widget, value) --setter
					return widget.frame:SetUserDisplayConditions(value)
					--parent:IsEnabled()
				end,
			},		
		},
	}

	for i , details in pairs(states) do
		local name, value = unpack(details)
		tinsert(display[2], {
			"dropDown",
			name,
			function(parent) --getter
				return widget.frame:GetUserDisplayConditionState(value)
			end,
			function(parent, value) --setter
				widget.frame:UpdateUserDisplayCondition(name, value)
					if menu.PANEL then
						menu.PANEL:Hide()
						menu.PANEL:Show()
					end
			end,
			function()
				return widget.frame:GetCurrentUserDisplayOptions()
			end,
		})
	end
	
	tinsert(options, 2, display)
	
	menu.options = options
	menu:SetSize(175, 300)
	menu:EnableMouse(true)
	menu:SetMovable(true)
	menu:SetFrameLevel(7)
	menu.widget = widget
	menu.id = widget.id
	menu.widgets = {}
	menu.panels = {}
	menu:Hide()
	
	menu.closeButton = CreateFrame("Button", nil, menu, "UIPanelCloseButton")
	menu.closeButton:SetPoint("TopRight", menu)
	menu.closeButton:SetFrameStrata('HIGH')
	menu.closeButton:SetFrameLevel(8)
	menu.closeButton:SetScale(.75)

	menu.title = menu:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	menu.title:SetText(widget.displayID or widget.id)
	menu.title:SetPoint("TopLeft", 8, -8)
	menu.title:SetJustifyH("LEFT")
	menu.title:SetJustifyV("TOP") 
	
	menu:SetScript("OnMouseUp", function() menu:StopMovingOrSizing() end)
	menu:SetScript("OnMouseDown", function() menu:StartMoving() end)
	menu:SetScript("OnShow", function()
		sandCastle.FlyPaper.SetScale(menu, mScale/100)
		menu:SetScale(mScale/100)
		if not IsShiftKeyDown() then
			for i, b in pairs(panels) do
				if b ~= menu then
					b:Hide()
				end
			end
		end
		
		local point, oPoint = SelectProperSide(widget)
		
		menu:ClearAllPoints()
		menu:SetPoint(point, widget, oPoint)
		
		local x, y  = menu:GetRect()
		menu:ClearAllPoints()
		menu:SetPoint("BottomLeft", x, y)
	end)

	menu:SetScript("OnMouseWheel", function(_, delta)
		if not IsShiftKeyDown() then return end
		mScale = min(250, max(100, mScale + (delta * 5)))
		sandCastle.FlyPaper.SetScale(menu, mScale/100)
	end)

	
	for i , panel in pairs(menu.options) do
		local page = OPTS.panel(menu, unpack(panel))
		if i == 1 then page:Show() end
	end

	tinsert(panels, menu)
	return menu
end
