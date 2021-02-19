--General structure for handling frames of all types!
local sandCastle = LibStub("AceAddon-3.0"):GetAddon(...)

sandCastle.callbacks = LibStub('CallbackHandler-1.0'):New(sandCastle)

function sandCastle:OnInitialize()
    -- setup db
    self:CreateDatabase()
    self:UpgradeDatabase()

	self.frame = CreateFrame("Frame", "sandCastle_Frame", UIParent)
		--all frames handled by sandCastele are parented to this frame.
	self.frame:SetAllPoints(UIParent)
	
	self.configOverlay = CreateFrame("Frame", "sandCastle_configOverlay", self.frame)
	tinsert(UISpecialFrames, self.configOverlay:GetName())
	--make a frame disappear on entering combat or on escape pressed, taint free ~Thanks Blizzard!
		--I'm sure this will be disabled for addons one day...
	
	self.configOverlay:SetFrameStrata("HIGH")
	self.configOverlay:SetAllPoints(UIParent)
	self.configOverlay:Hide()

	
	--Consolidated OnUpdate and OnEvent functions for ALL frames handled by sandCastle.
	self.scripts = sandCastle.utility.getTable()
	self.scripts.OnUpdate = sandCastle.utility.getTable()
	self.scripts.OnEvent = sandCastle.utility.getTable()
	
	self.hookedScripts = sandCastle.utility.getTable()
	self.hookedScripts.OnUpdate = sandCastle.utility.getTable()
	self.hookedScripts.OnEvent = sandCastle.utility.getTable()
	
	self.eventRegistration = sandCastle.utility.getTable()

	self.frame:SetScript("OnUpdate", function(_, ...)
		for i, func in pairs(self.scripts.OnUpdate) do
			func(_G[i], ...)
			
			local hooks = self.hookedScripts.OnUpdate[i]
			if hooks then
				for k, hookFunc in pairs(hooks) do
					hookFunc(_G[i], ...)
				end
			end
		end
	end)

	self.frame:SetScript("OnEvent", function(_, event, ...)
		local frames = self.eventRegistration[event]
		for frameName in pairs(frames) do
			 if self.scripts.OnEvent[frameName] then
				self.scripts.OnEvent[frameName](_G[frameName], event, ...)
				
				local hooks = self.hookedScripts.OnEvent[frameName]
				if hooks then
					for k, hookFunc in pairs(hooks) do
						hookFunc(_G[frameName], event, ...)
					end
				end
			 end
		end
	end)
end

function sandCastle:CreateOverlay(widget)


end

function sandCastle:Register(AddonName, widget, widgetHandler, defaults, options)
	local frameName = widget:GetName()
	local _frameName = AddonName.."_"..frameName

	if parent and ((parent:GetObjectType() == "FontString") or (parent:GetObjectType() == "Texture")) then
		parent = nil
	end

	if _G[_frameName] then
		return _G[_frameName]
	end

	local container = CreateFrame("Frame", nil, widget:GetParent() or self.frame, "sandCastleSecureFrameTemplate")

	container.widget = widget
	container:SetMovable(true)
	container:EnableMouse(false)
	container:SetUserPlaced(true)
	container:SetClampedToScreen(true)
	
	
	local w, h = widget:GetSize()
	container:SetSize(w, h)
	widget.frame = container
	
	widget:ClearAllPoints()
	widget:SetPoint("Center", container)
	
	widget:SetAllPoints(container)
	self.widgets[_frameName] = widget
	
	
	widget:SetParent(container)

	
	do --hook scripts on widget to control container instead.

		function widget:GetPoint(...)
			return container:GetPoint(...)
		end

		hooksecurefunc(widget, "SetPoint", function(...)
			--yes, i know, possible taint issue. I'll fix it, if it actually causes issues.
			widget:ClearAllPoints()
			widget:SetPoint("Center", container)
			if not tContains({...}, container) then
				container:SetPoint(...)
			end
		end)
		
		hooksecurefunc(widget, "SetSize", function(_, w, h)
			sandCastle.Resize(widget)
		end)
		hooksecurefunc(widget, "SetWidth", function(_, w)
			sandCastle.Resize(widget)
		end)
		hooksecurefunc(widget, "SetHeight", function(_, h)
			sandCastle.Resize(widget)
		end)
		hooksecurefunc(widget, "SetScale", function(_, s)
			sandCastle.Resize(widget)	
		end)
		
		hooksecurefunc(widget, "ClearAllPoints", function()
			widget:SetPoint("Center", container)
			container:ClearAllPoints()
		end)
		
		local sentBySelf
		hooksecurefunc(widget, "SetAllPoints", function(...)
			if not sentBySelf then
				sentBySelf = true
				widget:SetPoint("Center", container)
				container:SetAllPoints(...)
			else
				sentBySelf = nil
			end
		end)
	end

	if sandCastleDB then
		widget.id = frameName
		widget.sets = sandCastle:SetFrameSets(widget.id, defaults)
		sandCastle.utility.storedDefaults[widget.id] = sandCastle.utility.tDuplicate(defaults)
	end
	
	sandCastle.FlyPaper.AddFrame("sandCastle", frameName, container)
		
	if not widget.SetScript then
		--make fontstrings and texture behave like frames
		function widget:SetMovable(enable)
			container:SetMovable(enable)
		end

		function widget:SetResizable(enable)
			container:SetResizable(enable)
		end
		
		function widget:EnableMouse(enable)
			container:EnableMouse(enable)
		end

		function widget:SetScript(script, func)
			local scriptHandler = self.scripts[script]
			if scriptHandler then
				scriptHandler[_frameName] = func
			else
				container:SetScript(script, function(_,...)
					func(widget, ...)
				end)
			end
		end

		function widget:HookScript(script, func)
			local scriptHandler = self.hookedScripts[script]
			if scriptHandler then
				scriptHandler[_frameName] = scriptHandler[_frameName] or sandCastle.utility.getTable()
				if not tContains(scriptHandler[_frameName], func) then
					tinsert(scriptHandler[_frameName], func)
				end
			else
				container:HookScript(script, function(_, ...)
					func(widget, ...)
				end)
			end
		end
		
		--reroute events onto sandCastle!
		function widget:RegisterEvent(event, ...)
			self.eventRegistration[event] = self.eventRegistration[event] or sandCastle.utility.getTable()
			self.eventRegistration[event][_frameName] = true
			self.frame:RegisterEvent(event, ...)
		end

		function widget:UnregisterEvent(event, ...)
			self.eventRegistration[event] = self.eventRegistration[event] or sandCastle.utility.getTable()
			self.eventRegistration[event][_frameName] = nil
			
			if #self.eventRegistration[event] == 0 then
				self.frame:UnregisterEvent(event, ...)
			end
		end
		
	else
		do --reroute OnUpdate and OnEvent to sandCastle for consolidation
			local sentLocally
			hooksecurefunc(widget, "SetScript", function(_, script, func)
				if sentLocal then sentLocal = nil return end
				sentLocal = true			
				local scriptHandler = self.scripts[script]
				if scriptHandler then
					scriptHandler[_frameName] = func
					
					widget:SetScript(script, nil)
				else
					widget:SetScript(script, function(_, ...)
						func(widget, ...)
					end)
				end
			end)
		
			hooksecurefunc(widget, "HookScript", function(_, script, func)
				if sentLocal then sentLocal = nil return end
				sentLocal = true			

				local scriptHandler = self.hookedScripts[script]
				if scriptHandler then
					scriptHandler[_frameName] = scriptHandler[_frameName] or sandCastle.utility.getTable()
					if not tContains(scriptHandler[_frameName], func) then
						tinsert(scriptHandler[_frameName], func)
					end
				else
					widget:HookScript(script, function(_, ...)
						func(widget, ...)
					end)
				end
			end)
		end
		--reroute events onto sandCastle!
		local sentLocally
		hooksecurefunc(widget, "RegisterEvent", function(_, event, ...)
			sentLocal = true
			widget:UnregisterEvent(event, ...)
			self.eventRegistration[event] = self.eventRegistration[event] or sandCastle.utility.getTable()
			self.eventRegistration[event][_frameName] = true
			self.frame:RegisterEvent(event, ...)
		end)

		hooksecurefunc(widget, "UnregisterEvent", function(_, event, ...)
			if sentLocal then sentLocal = nil return end
			self.eventRegistration[event] = self.eventRegistration[event] or sandCastle.utility.getTable()
			self.eventRegistration[event][_frameName] = nil
			if #self.eventRegistration[event] == 0 then
				self.frame:UnregisterEvent(event, ...)
			end
		end)
	end

	function widget:ClearAllHooks(script)
		local scriptHandler = self.hookedScripts[script]
		if scriptHandler and scriptHandler[_frameName] then
			wipe(scriptHandler[_frameName])
		end
	end

	do --add settings and positioning overlay
		local overlay = self.overlays[_frameName] or CreateFrame("Button", nil, self.configOverlay, BackdropTemplateMixin and "BackdropTemplate" or nil)
		overlay.text = overlay.text or overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		overlay.text:SetText(widget.displayID or frameName)
		overlay:RegisterForClicks("RightButtonUp")
		self.overlays[_frameName] = overlay
		overlay.text:SetAllPoints(overlay)
		overlay:SetAllPoints(container)
		
		widget.overlay = overlay
		
		local font = overlay.text:GetFont()
		
		overlay:SetScript("OnShow", function()			
			local length = overlay.text:GetStringWidth()
			overlay.text:SetFont(font, 15)
			local width = overlay:GetWidth()
			if length > width then
				local size = 59
				while length > width do
					if size/4 < 5 then
						break
					end
					overlay.text:SetFont(font, size/4)
					length = overlay.text:GetStringWidth()
					size = size - .25
				end
			end
			overlay:SetScript("OnShow", nil)
		end)

		overlay:Show()

		overlay:SetBackdrop({
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeSize = 2,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		})
		overlay:SetBackdropColor(139/255, 89/255, 29/255, .35)
		overlay:SetBackdropBorderColor(112/255, 69/255, 19/255, .55)

		overlay:SetScript("OnEnter", function()
			overlay:SetBackdropBorderColor(200/255, 100/255, 19/255, .85)
		end)

		overlay:SetScript("OnLeave", function()
			overlay:SetBackdropBorderColor(112/255, 69/255, 19/255, .55)
		end)

		overlay:SetScript("OnMouseDown", function(_,btn)
			if btn == "LeftButton" then
				container:SetMovable(true)
				container:ClearAllPoints()
				container:StartMoving()
			end
		end)

		overlay:SetScript("OnMouseUp", function(_,btn)
			if btn == "LeftButton" then
				container:StopMovingOrSizing()
			end
		end)

		local X, Y = container:GetCenter()
		hooksecurefunc(container, "StartMoving", function()
			X, Y = container:GetCenter()
		end)
		
		hooksecurefunc(container, "StopMovingOrSizing", function()
			local x, y = container:GetCenter()
			if x ~= X or y ~= Y then --only update if a change was made.
				sandCastle.Stick(widget)
			end
		end)

		overlay:SetScript("OnClick", function(_, btn, ...)
			--toggle Options
			if IsAltKeyDown() then
				sandCastle.utility.deconstructTable(sandCastle.db.profile.frames[widget.id])
				sandCastle.db.profile.frames[widget.id] = sandCastle.utility.tDuplicate(sandCastle.utility.storedDefaults[widget.id])
				widget.sets = sandCastle.db.profile.frames[widget.id]
				sandCastle.Setup(widget)
			else
				ToggleFrame(sandCastle:NewMenu(widget, options))
			end
		end)
	end
	
	if widgetHandler then
		sandCastle.utility.embed(widgetHandler, widget)
	end
	
	sandCastle.Reanchor(widget)
	
	
	container:UpdateUserDisplayConditions()
	
	return container
end

function sandCastle:GetScrollContainer(name)
	local scrollFrame = CreateFrame("Frame", name, sandCastle.frame)
	scrollFrame.wrapper = CreateFrame("ScrollFrame", nil, scrollFrame)
	scrollFrame.wrapper.ScrollChild = CreateFrame("Frame", nil, scrollFrame.wrapper)
	scrollFrame.wrapper:SetScrollChild(scrollFrame.wrapper.ScrollChild)
	scrollFrame.wrapper.ScrollChild:SetAllPoints(scrollFrame.wrapper)
	scrollFrame.wrapper:SetPoint("BottomRight", 0, 0)
	scrollFrame.wrapper:SetPoint("TopLeft", 0, 0)
	
	function scrollFrame:SetChild(child)		
		hooksecurefunc(child, "SetParent", function(_, parent)
			if parent ~= scrollFrame.wrapper.ScrollChild then
				child:SetParent(scrollFrame.wrapper.ScrollChild)
			end
		end)
		child:SetParent(scrollFrame.wrapper.ScrollChild)
	end
	
	return scrollFrame
end

function sandCastle:GetContainer()

end


--alignment grid --inspired by the fact that Dominos now uses one, but designed from scratch.
local Griddle = {_lines = {}}

local green, blue = {0,.75,0,.5}, {0,.5,.5,.5}

function Griddle:GetGridScale()
	sandCastleDB.gridSize = not tonumber(sandCastleDB.gridSize) and 50 or sandCastleDB.gridSize
	
    local xlines = _G.Round( Dominos and Dominos:GetAlignmentGridSize()
		or (sandCastleDB.gridSize or 50)) * 2
    local width, height = GetScreenWidth(), GetScreenHeight()
    local ylines = _G.Round((xlines / (width / height)) / 2) * 2
    return xlines, ylines, width / xlines, height / ylines
end

sandCastle.GetGridScale = Griddle.GetGridScale
function sandCastle:GridShown()
	return Griddle.lineHandler:IsShown()
end

function Griddle:UpdateGrid()
	self.lineHandler = self.lineHandler or CreateFrame("Frame", nil, sandCastle.configOverlay)

	if not Griddle.lineHandler:IsShown() then
		return
	end

	local xScale, yScale, xOffset, yOffset = Griddle:GetGridScale()
		
	for i = 1, max(xScale + yScale, #self._lines) do
		self._lines[i] = self._lines[i] or self.lineHandler:CreateLine(nil, 'BACKGROUND')
		local line = self._lines[i]
		if not line.setup then
			line:SetThickness(1)
			line:SetNonBlocking(true)
			line.setup = true
		end
		if i > (xScale + yScale) then
			line:Hide()
		else
			line:Show()
			local point = i > xScale and "BottomRight" or "TopLeft"
			local _i = (i > xScale) and (i - xScale) or i
			local x = i > xScale and 0 or xOffset * i		
			local y = i > xScale and yOffset * _i or 0
			local color = ((i>xScale and (_i == yScale/2)) or(i == xScale/2)) and green or blue 
			
			line:SetStartPoint(point, UIParent, x, y)
			line:SetEndPoint("BottomLeft", UIParent, x, y)
			line:SetColorTexture(unpack(color))
		end
	end
end

local function slider(menu)
	local slider = CreateFrame("Slider", "sandCastleGridSizeSlider", menu, "HorizontalSliderTemplate")
		slider:SetPoint("Left", menu, "Center", 0, -25)
		slider:SetMinMaxValues(1, 100)
		slider:SetStepsPerPage(10)
		slider:SetObeyStepOnDrag(true)--no decimals!
		slider:SetValueStep(1)
		slider:SetSize(150, 18)

	local editbox = CreateFrame("EditBox", nil, slider)
		editbox:SetScript("OnEscapePressed", function() editbox:ClearFocus() editbox:SetText(math.floor(slider:GetValue())) end)
		editbox:SetScript("OnEnterPressed", function() slider:SetValue(tonumber(editbox:GetText())) end)
		editbox:SetPoint("BottomRight", slider, "TopRight", -2, 0)
		editbox:SetFontObject(GameFontHighlightSmall)
		editbox:SetJustifyH("RIGHT")
		editbox:SetAutoFocus(false)
		editbox:EnableMouse(true)
		editbox:SetHeight(10)
		editbox:SetWidth(70)
	
	local title = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		title:SetPoint("BottomLeft", slider, "TopLeft")
		title:SetPoint("TopRight", editbox, "TopLeft")
		title:SetText("Grid Density")
		title:SetJustifyH("LEFT")
		title:SetJustifyV("TOP") 

		if Dominos then
			hooksecurefunc(Dominos, "SetAlignmentGridSize", function(_, value)	
				slider:SetValue(value)
			end)
		end

	slider:SetScript("OnValueChanged", function(_, value)
		sandCastleDB.gridSize = value
		
		if Dominos then
			Dominos:SetAlignmentGridSize(value)
		end
		
		Griddle:UpdateGrid()
		editbox:SetText(value)
	end)

	slider:SetScript("OnMouseWheel", function(_,delta)
		slider:SetValue(slider:GetValue() + (delta))
	end)

	editbox:SetScript("OnMouseWheel", function(_,delta)
		slider:SetValue(slider:GetValue() + (delta))
	end)

	slider:SetScript("OnShow", function()
		slider:SetValue(sandCastleDB.gridSize or 50)
	end)

	slider:SetValue(sandCastleDB.gridSize or 50)
	
	return slider
end

function sandCastle:Locked()
	return self.configOverlay:IsVisible()
end

function sandCastle:ToggleConfig()
	ToggleFrame(self.configOverlay)
	
	Griddle:UpdateGrid()
	
	if self.configOverlay:IsVisible() and not self.configOverlay.info then
		Griddle.lineHandler:Hide()
		--config explanation and settings
		
		self.configOverlay.info = CreateFrame("Frame", "sandCastle_configOverlay_Details", self.configOverlay,BackdropTemplateMixin and 'BackdropTemplate')
		local infoPanel = self.configOverlay.info
		
		infoPanel:SetMovable(true)
		infoPanel:EnableMouse(true)
		infoPanel:SetSize(325, 140)
		infoPanel:SetFrameStrata('HIGH')
		infoPanel:SetClampedToScreen(true)
		infoPanel:SetPoint("Center", 0, 340)
		infoPanel:RegisterForDrag('LeftButton')
		infoPanel:SetScript("OnDragStart", function() infoPanel:StartMoving() end)
		infoPanel:SetScript("OnDragStop", function() infoPanel:StopMovingOrSizing() end)
		
		infoPanel:SetBackdrop(BACKDROP_TOAST_12_12)
		infoPanel:SetBackdropColor(0, 0, 0, .45)
		
		infoPanel.closeButton = CreateFrame("Button", infoPanel:GetName().."_closeButton", self.configOverlay, "UIPanelCloseButton")
		infoPanel.closeButton:SetPoint("TopRight", infoPanel)
		infoPanel.closeButton:SetFrameStrata('HIGH')
		infoPanel.closeButton:SetFrameLevel(8)
		infoPanel.closeButton:SetScale(.75)

		infoPanel.title = infoPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		infoPanel.title:SetText("Build your Sand Castle!")
		infoPanel.title:SetPoint("TopLeft", 8, -8)
		infoPanel.title:SetJustifyH("LEFT")
		infoPanel.title:SetJustifyV("TOP") 
		
		infoPanel.details = infoPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		infoPanel.details:SetText("- Right click on an orange overlay for more options." ..
		"|n" .. "- Left click and drag your mouse to move a frame."..
		"|n".. "- Alt+Right-Click a frame to reset it to default.")
		infoPanel.details:SetPoint("BottomRight", -8, 50)
		infoPanel.details:SetPoint("TopLeft", 15, -28)
		infoPanel.details:SetJustifyH("LEFT")
		infoPanel.details:SetJustifyV("TOP")

		sandCastle.utility.storeSnapshot()
		infoPanel:SetScript("OnShow", function()
			infoPanel:SetPoint("Center", 0, 340)
			sandCastle.utility.storeSnapshot()
		end)

		local cancel = _G.CreateFrame('Button', nil, infoPanel, 'UIPanelButtonNoTooltipResizeToFitTemplate')
		--restore all frames to their states before config mode was activated.
		cancel:SetWidth(125)
		cancel.Text:SetText("Cancel Changes")
		cancel:SetPoint('BOTTOMRIGHT', -8, 8)
		cancel:SetScript('OnClick', function() sandCastle.utility.restoreSnapshot() end)

		local baseLine = _G.CreateFrame('Button', nil, infoPanel, 'UIPanelButtonNoTooltipResizeToFitTemplate')
		--nothing is saved, current state is stored, baseLine text changes to "Restore Baseline". Left Click to reset, right click to baseline again.
		baseLine.Text:SetText("Baseline")
		baseLine:SetWidth(116.82053375244)
		baseLine:SetPoint('Right', cancel, "Left", -5, 0)
		baseLine:RegisterForClicks("AnyUp")
		baseLine:SetScript('OnClick', function(_, btn)
			if (btn == "RightButton") then
				sandCastle.utility.storeBaseline()
			else
				sandCastle.utility.restoreBaseline()
			end
				baseLine:SetText("Restore Baseline") 
		end)
		
		local reset = _G.CreateFrame('Button', nil, infoPanel, 'UIPanelButtonNoTooltipResizeToFitTemplate')
		reset:SetScript('OnClick', function(_, btn) sandCastle.utility.restoreDefaults() end)
		reset:SetPoint('Right', baseLine, "Left", -5, 0)
		reset.Text:SetText("Reset")
		reset:SetWidth(55)
		
		local checkButton = _G.CreateFrame('CheckButton', nil, infoPanel, "UICheckButtonTemplate")
		checkButton.text:SetText("Show Grid")
		checkButton:SetPoint("Left", infoPanel, 35, -15)
		checkButton:SetHitRectInsets(0, -(checkButton.text:GetWidth() or 0), 0, 0)
		
		checkButton:SetScript('OnShow', function(button)
			Griddle.lineHandler:SetShown(checkButton:GetChecked())
		end)
		checkButton:SetScript('OnClick', function(button)
			Griddle.lineHandler:SetShown(checkButton:GetChecked())
		end)
		
		slider(infoPanel)
	end
	
	return self.configOverlay:IsVisible()
end

do-- slash commands
	local SlashCommands = sandCastle:NewModule('SlashCommands', 'AceConsole-3.0')

	local function printCommand(cmd, desc)
		print((' - |cFF33FF99%s|r: %s'):format(cmd, desc))
	end

	function SlashCommands:OnEnable()
		self:RegisterChatCommand('sandcastle', 'OnCmd')
		self:RegisterChatCommand('sand', 'OnCmd')
	end

	local cmds = {
		--["title"] = {text = {text, description}, func = function(args) end}
		["config"]  = {text = {'config', sandCastle.localize.ConfigDesc}, 
			func    = function(args) sandCastle:ToggleConfig() end},
		["lock"]  = { 
			func    = function(args) sandCastle:ToggleConfig() end},
		["save"]    = {text = {'save <profile>', sandCastle.localize.SaveDesc}, 
			func    = function(args) sandCastle:SaveProfile(string.join(' ', args)) end},
		["set"]     = {text = {'set <profile>', sandCastle.localize.SetDesc}, 
			func    = function(args) sandCastle:SetProfile(string.join(' ', args)) end},
		["copy"]    = {text = {'copy <profile>', sandCastle.localize.CopyDesc}, 
			func    = function(args) sandCastle:CopyProfile(string.join(' ', args)) end},
		["delete"]  = {text = {'delete <profile>', sandCastle.localize.DeleteDesc}, 
			func    = function(args) sandCastle:DeleteProfile(string.join(' ', args)) end},
		["reset"]   = {text = {'reset', sandCastle.localize.ResetDesc}, 
			func    = function(args) sandCastle:ResetProfile() end},
		["list"]    = {text = {'list', sandCastle.localize.ListDesc}, 
			func    = function(args) sandCastle:ListProfiles() end},
		["version"] = {text = {'version', sandCastle.localize.PrintVersionDesc}, 
			func    = function(args) sandCastle:PrintVersion() end},
		["help"] = {
			func    = function(args) sandCastle:PrintVersion() end},
		["?"] = {
			func    = function(args) SlashCommands:PrintHelp() end},
		[""] = {
			func    = function(args) if not sandCastle.configOverlay:IsVisible() then SlashCommands:PrintHelp() end end},
	}

	function SlashCommands:OnCmd(args)
		args = args and {string.split(' ', string.lower(args))}

		local cmd = args[1] or ""
		tremove(args, 1)

		if string.len(cmd) > 1 then
			for _cmd, info in pairs(cmds) do
				if info.func and strmatch(_cmd, cmd, 1) then
					return info.func(args)
				end
			end
		end


		if cmds[cmd] and cmds[cmd].func then
			return cmds[cmd].func(args)
		end
	end

	function SlashCommands:PrintHelp(cmd)
		sandCastle:Print('Commands (/sand, /sandcastle)')

		for i, b in pairs(cmds) do
			if b.text then
				printCommand(unpack(b.text))
			end
		end
	end
end

--local widgets = {}

function sandCastle.New(func)
	func()
end