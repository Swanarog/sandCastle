--create addonHandler and add some utility features
local AddonName, Addon = ...
local sandCastle = _G.LibStub("AceAddon-3.0"):NewAddon(Addon, AddonName, 'AceEvent-3.0', 'AceConsole-3.0')
sandCastle.callbacks = LibStub('CallbackHandler-1.0'):New(sandCastle)
sandCastle.localize = LibStub('AceLocale-3.0'):GetLocale(AddonName)
sandCastle.FlyPaper = LibStub('LibFlyPaper-2.0')

sandCastle.utility = {}

local utility = sandCastle.utility
--many of these are only called once, but i still want them consolidated

do--table management. instead of cutting single use tables off, reuse them.
	local emptyTables = {} --let' try recycling any and all tables we make. If a table is one use only, clear it and store it.
	function utility.getTable()
		return emptyTables[1] or {}, emptyTables[1] and tremove(emptyTables, 1) or nil
	end

	local removingTables = {}
	function utility.deconstructTable(returning, initiator)
		if (not returning)
		or (type(returning) ~= "table")
		or tContains(removingTables, returning)
		or (returning == initiator) then
			return --safety measure to prevent an endless loop.
		end

		tinsert(removingTables, returning)

		for i, b in pairs(returning) do
			if type(b) == "table" then
				utility.deconstructTable(b, initiator or returning)				
			end
			returning[i] = nil
		end
		
		if not tContains(emptyTables, returning) then
			wipe(returning) --just to be sure...
			tinsert(emptyTables, returning)
		end
		
		if not initiator then
			wipe(removingTables)
		end
	end
end

do --stuff
	-- quick method to add all functions to a frame.
	utility.embed = function(source, destination)
		destination.storeForDisembed = destination.storeForDisembed or utility.getTable() -- need to restore anything rewritten when a frame is removed
		for i, b in pairs(source) do
			destination.storeForDisembed[i] = destination[i]
			if type(b) == "table" then
				destination[i] = utility.embed(b, utility.getTable())
			else
				destination[i] = b
			end
		end
		return destination
	end

	--more in depth than CopyTable
	utility.tDuplicate = function(original, duplicate) 
		duplicate = duplicate or utility.getTable()
		for i, b in pairs(original) do
			duplicate[i] = (type(b) == "table") and utility.tDuplicate(b) or b
		end
		return duplicate
	end
end

do --configMode quick adjustment functions
	local onShowBaseline, userBaseline

	function utility.storeBaseline()
		utility.deconstructTable(userBaseline)
		userBaseline = utility.tDuplicate(sandCastle.db.profile.frames)
	end

	function utility.restoreBaseline()
		if not userBaseline then
			return utility.storeBaseline()
		end

		utility.deconstructTable(sandCastle.db.profile.frames)
		sandCastle.db.profile.frames = utility.tDuplicate(userBaseline)
		
		for i, widget in pairs(sandCastle.widgets ) do
			widget.sets = sandCastle.db.profile.frames[widget.id]
			sandCastle.Setup(widget)
		end
		
		if sandCastle.lastMenu and sandCastle.lastMenu:IsShown() then
			sandCastle.lastMenu:Hide()
			sandCastle.lastMenu:Show()
		end
	end

	function utility.storeSnapshot()
		utility.deconstructTable(onShowBaseline)
		onShowBaseline = utility.tDuplicate(sandCastle.db.profile.frames)
	end

	function utility.restoreSnapshot()
		utility.deconstructTable(sandCastle.db.profile.frames)

		sandCastle.db.profile.frames = utility.tDuplicate(onShowBaseline)
		
		for i, widget in pairs(sandCastle.widgets ) do
			widget.sets = sandCastle.db.profile.frames[widget.id]
			sandCastle.Setup(widget)
		end
		
		if sandCastle.lastMenu and sandCastle.lastMenu:IsShown() then
			sandCastle.lastMenu:Hide()
			sandCastle.lastMenu:Show()
		end
	end

	utility.storedDefaults = {}

	function utility.storeDefaults()
		utility.deconstructTable(sandCastle.db.profile.frames)
		sandCastle.db.profile.frames = utility.tDuplicate(utility.storedDefaults)
		
		for i, widget in pairs(sandCastle.widgets ) do
			widget.sets = sandCastle.db.profile.frames[widget.id]
			sandCastle.Setup(widget)
		end
	end

	function utility.restoreDefaults()
		utility.deconstructTable(sandCastle.db.profile.frames)
		sandCastle.db.profile.frames = utility.tDuplicate(utility.storedDefaults)
		
		for i, widget in pairs(sandCastle.widgets ) do
			widget.sets = sandCastle.db.profile.frames[widget.id]
			sandCastle.Setup(widget)
		end
		
		if sandCastle.lastMenu and sandCastle.lastMenu:IsShown() then
			sandCastle.lastMenu:Hide()
			sandCastle.lastMenu:Show()
		end
	end
end

sandCastle.widgets = sandCastle.utility.getTable()
sandCastle.overlays = sandCastle.utility.getTable()