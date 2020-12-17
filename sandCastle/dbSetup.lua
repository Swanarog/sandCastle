local AddonName, sandCastle = ...

local FlyPaper = sandCastle.FlyPaper
local L = sandCastle.localize

local utility = sandCastle.utility

do --Lifted from Dominos

	--------------------------------------------------------------------------------
	-- Database Setup
	--------------------------------------------------------------------------------

	-- db actions
	function sandCastle:CreateDatabase()
		local db = LibStub('AceDB-3.0'):New("sandCastleDB", self:GetDatabaseDefaults(), UnitClass('player'))
		db:RegisterDefaults(self:GetDatabaseDefaults())
		db.RegisterCallback(self, 'OnNewProfile')
		db.RegisterCallback(self, 'OnProfileChanged')
		db.RegisterCallback(self, 'OnProfileCopied')
		db.RegisterCallback(self, 'OnProfileDeleted')
		db.RegisterCallback(self, 'OnProfileReset')
		db.RegisterCallback(self, 'OnProfileShutdown')
		self.db = db
	end

	function sandCastle:GetDatabaseDefaults()
		return {
			profile = {
				minimap = {
					hide = false
				},

				frames = {

				},

				alignmentGrid = {
					enabled = true,
					size = 32
				},
			}
		}
	end

	function sandCastle:UpgradeDatabase()
		local configVerison = self.db.global.configVersion
		if configVerison ~= CONFIG_VERSION then
			self:OnUpgradeDatabase(configVerison, CONFIG_VERSION)
			self.db.global.configVersion = CONFIG_VERSION
		end

		local addonVersion = self.db.global.addonVersion
		if addonVersion ~= ADDON_VERSION then
			self:OnUpgradeAddon(addonVersion, ADDON_VERSION)
			self.db.global.addonVersion = ADDON_VERSION
		end
	end

	--------------------------------------------------------------------------------
	-- Profiles
	--------------------------------------------------------------------------------

	-- profile actions
	function sandCastle:SaveProfile(name)
		local toCopy = self.db:GetCurrentProfile()
		if name and name ~= toCopy then
			self.db:SetProfile(name)
			self.db:CopyProfile(toCopy)
		end
	end

	function sandCastle:SetProfile(name)
		local profile = self:MatchProfile(name)
		if profile and profile ~= self.db:GetCurrentProfile() then
			self.db:SetProfile(profile)
		else
			self:Printf(L.InvalidProfile, name or 'null')
		end
	end

	function sandCastle:DeleteProfile(name)
		local profile = self:MatchProfile(name)
		if profile and profile ~= self.db:GetCurrentProfile() then
			self.db:DeleteProfile(profile)
		else
			self:Print(L.CantDeleteCurrentProfile)
		end
	end

	function sandCastle:CopyProfile(name)
		if name and name ~= self.db:GetCurrentProfile() then
			self.db:CopyProfile(name)
		end
	end

	function sandCastle:ResetProfile()
		self.db:ResetProfile()
	end

	function sandCastle:ListProfiles()
		self:Print(L.AvailableProfiles)

		local current = self.db:GetCurrentProfile()
		for _, k in ipairs(self.db:GetProfiles()) do
			if k == current then
				print(' - ' .. k, 1, 1, 0)
			else
				print(' - ' .. k)
			end
		end
	end

	function sandCastle:MatchProfile(name)
		local name = name:lower()

		local nameRealm = name .. ' - ' .. GetRealmName():lower()
		local match

		for _, k in ipairs(self.db:GetProfiles()) do
			local key = k:lower()
			if key == name then
				return k
			elseif key == nameRealm then
				match = k
			end
		end

		return match
	end

	-- profile events
	function sandCastle:OnNewProfile(msg, db, name)
		self:Printf(L.ProfileCreated, name)
	end

	function sandCastle:OnProfileDeleted(msg, db, name)
		self:Printf(L.ProfileDeleted, name)
	end

	function sandCastle:OnProfileChanged(msg, db, name)
		self:Printf(L.ProfileLoaded, name)
		self:Load()
	end

	function sandCastle:OnProfileCopied(msg, db, name)
		self:Printf(L.ProfileCopied, name)
		self:Reload()
	end

	function sandCastle:OnProfileReset(msg, db)
		self:Printf(L.ProfileReset, db:GetCurrentProfile())
		self:Reload()
	end

	function sandCastle:OnProfileShutdown(msg, db, name)
		self:Unload()
	end
end

