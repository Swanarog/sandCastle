local AddonName, sandCastle = ...

local FlyPaper = sandCastle.FlyPaper
local L = sandCastle.localize

local utility = sandCastle.utility

--frame position handling

do-- frame settings
	function sandCastle:SetFrameSets(id, sets)
		local id = tonumber(id) or id

		self.db.profile.frames[id] =  self.db.profile.frames[id] or sets

		return self.db.profile.frames[id]
	end

	function sandCastle:GetFrameSets(id)
		return self.db.profile.frames[tonumber(id) or id]
	end

	function sandCastle:GetSets()
		return self.db.profile.frames
	end

	function sandCastle:SetSets(sets)
		self.db.profile.frames = sets
	end

	--Lifted from Dominos -- to do: Rewrite to make different Dominos
	--------------------------------------------------------------------------------
	-- Positioning
	--------------------------------------------------------------------------------

	-- how far away a frame can be from another frame/edge to trigger anchoring
	sandCastle.stickyTolerance = 8


	-- gets the scaled rect values for frame
	-- basically here to work around classic maybe not having GetScaledRect
	local function GetScaledRect(frame, xOff, yOff)
		xOff = tonumber(xOff) or 0
		yOff = tonumber(yOff) or 0

		local l, b, w, h = frame:GetRect()

		l = (l or 0) - xOff
		b = (b or 0) - yOff
		w = (w or 0) + xOff
		h = (h or 0) + yOff

		local s = frame:GetEffectiveScale()

		return l * s, b * s, w * s, h * s
	end

	-- sorted in evaluation order
	local POINTS = {
		'TOPLEFT',
		'TOPRIGHT',
		'BOTTOMRIGHT',
		'BOTTOMLEFT',
	}
	
	-- translates anchor points into x/y coordinates (bottom left, relative to screen)
	local COORDS = {
		BOTTOM = function(l, b, w, h) return l + w/2, b end,
		BOTTOMLEFT = function(l, b, w, h) return l, b end,
		BOTTOMRIGHT = function(l, b, w, h) return l + w, b end,
		CENTER = function(l, b, w, h) return l + w/2, b + h/2 end,
		LEFT = function(l, b, w, h) return l, b + h/2 end,
		RIGHT = function(l, b, w, h) return l + w, b + h/2 end,
		TOP = function(l, b, w, h) return l + w/2, b + h end,
		TOPLEFT = function(l, b, w, h) return l, b + h end,
		TOPRIGHT = function(l, b, w, h) return l + w, b + h end,
	}

	local function GetRelativeRect(frame, relFrame, xOff, yOff)
		local l, b, w, h = GetScaledRect(frame, xOff, yOff)
		local s = relFrame:GetEffectiveScale()

		return l / s, b / s, w / s, h /s
	end

	local function GetNearestMultiple(value, factor)
		return _G.Round(value / factor) * factor
	end
	
	-- two dimensional distance
	local function GetDistance(x1, y1, x2, y2)
		return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
	end

	function sandCastle.StickToAnything(widget)
		do
			local point, relFrame, relPoint = sandCastle.FlyPaper.GetBestAnchor(widget.frame, sandCastle.stickyTolerance, 0, 0)
			if point then
				sandCastle.SetAnchor(widget, relFrame, point, relPoint)
				return true
			end
		end
		
		do-- screen edge and center point anchoring
			local point, relPoint, x, y = sandCastle.FlyPaper.GetBestAnchorForParent(widget.frame)
			local eScale = widget.frame:GetEffectiveScale()
			if point then
				local stick
				if math.abs(x ) <= sandCastle.stickyTolerance then
					x, stick = 0, true
				end
				if math.abs(y ) <= sandCastle.stickyTolerance then
					y, stick = 0, true
				end
				if stick then
					sandCastle.SetAbsolutePosition(widget, point, widget.frame, relPoint, x, y)
					return true
				end
			end
		end
		
		if not sandCastle:GridShown() then return end

		local xScale, yScale, xOffset, yOffset = sandCastle:GetGridScale()

		local x, y, point

		local bestDist = math.huge

		for _, _point in pairs(POINTS) do
			local fx, fy = COORDS[_point](GetRelativeRect(widget.frame, widget.frame:GetParent(), 0, 0))

			local cx = GetNearestMultiple(fx, widget.frame:GetParent():GetWidth() / xScale)
			local cy = GetNearestMultiple(fy, widget.frame:GetParent():GetHeight() / yScale)
			
			-- return it if its within the limit
			local distance = GetDistance(fx, fy, cx, cy)
			if distance <= sandCastle.stickyTolerance*2 then
				local scale = widget.frame:GetEffectiveScale()
				if distance < bestDist then
					bestDist = distance
					point, x, y =  _point, cx / scale, cy / scale, distance
				end
			end
		end
		
		if point then
			sandCastle.SetAbsolutePosition(widget, point, widget.frame, "BOTTOMLEFT", x, y)
			return true
		end
	end

	-- bar anchoring
	function sandCastle.Stick(widget)
		sandCastle.ClearAnchor(widget)

		-- only do sticky code if the alt key is not currently down
		if not IsAltKeyDown() then
			sandCastle.StickToAnything(widget)
		end

		sandCastle.SaveFramePosition(widget, sandCastle.FlyPaper.GetBestAnchorForParent(widget.frame))
	end

	function sandCastle.Reanchor(widget)
		local relFrame, point, relPoint = sandCastle.GetAnchor(widget)

		if relFrame then
			widget.frame:ClearAllPoints()
			widget.frame:SetPoint(point, relFrame, relPoint)
		else
			sandCastle.ClearAnchor(widget)
			sandCastle.Reposition(widget)
		end
	end

	function sandCastle.SetAnchor(widget, relFrame, point, relPoint, x, y)
		sandCastle.ClearAnchor(widget)
		if relFrame.docked then
			local found = false
			for i, f in pairs(relFrame.docked) do
				if f == widget then
					found = i
					break
				end
			end
			if not found then
				table.insert(relFrame.docked, widget)
			end
		else
			relFrame.docked = sandCastle.utility.getTable() 
			tinsert(relFrame.docked, widget)
		end

		local anchor = widget.sets.position.anchor
		if not anchor then
			anchor = sandCastle.utility.getTable()

			widget.sets.position.anchor = anchor
		end

		anchor.point = point
		
		local group, groupID = sandCastle.FlyPaper.GetFrameInfo(relFrame)
		anchor.relFrameGroup = group
		anchor.relFrame = groupID
		anchor.relPoint = relPoint
		anchor.x = x
		anchor.y = y

		widget.frame:ClearAllPoints()
		widget.frame:SetPoint(point, relFrame, relPoint, x, y)
		sandCastle.SaveFramePosition(widget)
	end

	function sandCastle.ClearAnchor(widget)
		local relFrame = sandCastle.GetAnchor(widget)

		if relFrame and relFrame.docked then
			for i, f in pairs(relFrame.docked) do
				if f == widget then
					table.remove(relFrame.docked, i)
					break
				end
			end

			if not next(relFrame.docked) then
				relFrame.docked = sandCastle.utility.deconstructTable(docked)
			end
		end

		widget.sets.position.anchor = sandCastle.utility.deconstructTable(widget.sets.position.anchor)
	end

	function sandCastle.GetAnchor(widget)
		local anchor = widget.sets.position.anchor

		if type(anchor) == "table" then
			local point = anchor.point
			
			local group, groupID = anchor.relFrameGroup, anchor.relFrame
			
			local relPoint = anchor.relPoint
			local x = anchor.x or 0
			local y = anchor.y or 0

			return sandCastle.FlyPaper.GetFrame(group, groupID), point, relPoint, x, y
		end
	end

	-- absolute positioning
	function sandCastle.SetAbsolutePosition(widget, point, relFrame, relPoint, x, y)
		widget.frame:ClearAllPoints()
		local eScale = widget:GetEffectiveScale()
		widget.frame:SetPoint(point, relFrame:GetParent(), relPoint, x * eScale, y * eScale)
	end

	-- loading and positioning
	function sandCastle.Reposition(widget)
		local point, relPoint, x, y = sandCastle.GetSavedFramePosition(widget)
		sandCastle.SetAbsolutePosition(widget, point, widget:GetParent(), relPoint, x, y)
	end

	function sandCastle.SaveFramePosition(widget)
		local point, relPoint, x, y = sandCastle.FlyPaper.GetBestAnchorForParent(widget.frame)
		point = point or 'CENTER'
		relPoint = relPoint or point
		x = tonumber(x) or 0
		y = tonumber(y) or 0


		local eScale = widget:GetEffectiveScale()
		
		local sets = widget.sets.position

		if point == 'CENTER' then
			sets.point = nil
		else
			sets.point = point
		end

		if relPoint == point then
			sets.relPoint = nil
		else
			sets.relPoint = relPoint
		end

		if x == 0 then
			sets.x = nil
		else
			sets.x = x / eScale
		end

		if y == 0 then
			sets.y = nil
		else
			sets.y = y / eScale
		end

		widget.frame:SetUserPlaced(true)
	end

	function sandCastle.GetSavedFramePosition(widget)
		local sets = widget.sets.position

		if not sets then
			return 'CENTER'
		end

		local point = sets.point or 'CENTER'
		local relPoint = sets.relPoint or point
		local x = sets.x or 0
		local y = sets.y or 0

		return point, relPoint, x, y
	end

	function sandCastle.Setup(widget)
		sandCastle.Reanchor(widget)
		widget:Layout()
	end

	--frame and container sizing
	function sandCastle.Resize(widget)
		local w, h = widget:GetSize()
		local pad = widget.sets.padding or 0


		local scale = widget:GetScale()

		widget.fame:SetSize(w * scale + pad, h * scale + pad)
	end
end
