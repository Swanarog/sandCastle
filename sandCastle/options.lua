local AddonName, sandCastle = ...

-- Options Menu, maybe?
local menus = sandCastle.utility.getTable()

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

	local slider = CreateFrame("Slider", "sandCastleSlider"..sliderIndex, menu, "HorizontalSliderTemplate")


	 slider:SetHitRectInsets(0, 0, 5, 5)
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
		if get and get(menu.widget) then
			slider:SetValue(get(menu.widget))
		else
			slider:SetValue(_min + ((math.abs(_min) + math.abs(_max)) /2))
		end
	end)

	local editbox = CreateFrame("EditBox", nil, slider)

	
	slider:SetScript("OnValueChanged", function(_, value)
		if set then
			set(menu.widget, value)
		end
		editbox:SetText(value)
	end)
	
	slider:SetScript("OnValueChanged", function(_, value)
		if set then
			set(menu.widget, value)
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

local dropIndex = 0
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
function sandCastle:NewMenu(widget, options)
	if sandCastle.lastMenu and sandCastle.lastMenu.id ~= widget.id then
		sandCastle.lastMenu:Hide()
	end
	if menus[widget.id] then
		sandCastle.lastMenu = menus[widget.id]
		menus[widget.id].moved = nil
		return menus[widget.id]
	end
	menus[widget.id] = CreateFrame("ScrollFrame", widget:GetName().."Menu", self.configOverlay, BackdropTemplateMixin and 'BackdropTemplate')
	local menu = menus[widget.id]
	menu:SetClampedToScreen(true)
	menu:SetFrameStrata("HIGH")
	menu:SetFrameLevel(7)
	
	
	sandCastle.lastMenu = menu
	menu:SetBackdrop(BACKDROP_TOAST_12_12)
	menu:SetBackdropColor(0, 0, 0, .45)
	menu.id = widget.id
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
	
	menu.widget = widget
	
	menu:Hide()
	menu:SetSize(150, 300)

	menu:EnableMouse(true)
	menu:SetMovable(true)
	menu.moved = nil
	menu:SetScript("OnMouseDown", function() menu:StartMoving() end)
	menu:SetScript("OnShow", function()
		if sandCastle.lastMenu and sandCastle.lastMenu.id ~= widget.id then
			sandCastle.lastMenu:Hide()
		end
		local point, oPoint = SelectProperSide(widget)
		
		menu:ClearAllPoints()
		menu:SetPoint(point, widget, oPoint)
		
		local x, y  = menu:GetRect()
		menu:ClearAllPoints()
		menu:SetPoint("BottomLeft", x, y)
		
		
		

		
		
	end)
	menu:SetScript("OnMouseUp", function() moved = true menu:StopMovingOrSizing() end)

	menu.panels = {}
	dropIndex = dropIndex + 1
	local dropDown = CreateFrame("Button", menu:GetName().."dropDown"..dropIndex, menu, "UIDropDownMenuTemplate")
	dropDown:SetPoint("TopLeft",-5, -38)
	dropDown:SetScale(.75)

	UIDropDownMenu_Initialize(dropDown, function(button, menuLevel, menuList)
		if menuLevel == nil then return end

	--	local selected = self:GetSavedValue()

		for i , panel in pairs(options) do
		
		
			local name, opts = unpack(panel)
		
			if menu.active and menu.active.id == name then
			
			else
				local info = UIDropDownMenu_CreateInfo()
				info.notCheckable = true
				info.text = name
				info.value = name
				--info.selected = name == selected
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

	menu.widgets = {}

	menu.scroller = CreateFrame("Frame", nil, menu)

	menu:SetScrollChild(menu.scroller)

		menu.paneltitle = menu:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		menu.paneltitle:SetPoint("Left", dropDown, 0, 0)
		menu.paneltitle:SetText(name)

		dropDown.Text:SetFontObject(GameFontNormal)


		menu.paneltitle:SetJustifyH("RIGHT")
	for i , panel in pairs(options) do
		local name, opts = unpack(panel)
		
		local subPanel = CreateFrame("Frame", nil, menu.scroller)

		subPanel.title = menu.paneltitle

		tinsert(menu.panels, subPanel)
		subPanel.widget = widget
		
		subPanel.id = name
		
		subPanel:SetScript("OnShow", function() menu.active = subPanel dropDown.Text:SetText(name) end)
		
		subPanel:SetPoint("TopLeft", menu, 5, -45)
		subPanel:SetSize(140, 245)
		
		subPanel:Hide()
		
		subPanel.widgets = {}
		
		local height = 0
		for i, b in pairs(opts) do
			local style, title, get, set, values = unpack(b)
			if OPTS[style] then
				local b = OPTS[style](subPanel, title, get, set, values)

				height = height + b.height
				
				b:ClearAllPoints()
				b:SetPoint("BottomLeft", b:GetParent(), "TopLeft", 5, -(height+10))
					
			end
		end
	end
	

	
	
	if menu.panels[1] then
		menu.panels[1]:Show()
	end

	return menu
end
