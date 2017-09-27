-----------------------------------------------------------------------------------------------
-- Client Lua Script for CandyUI_CastBar
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- CandyUI_CastBar Module Definition
-----------------------------------------------------------------------------------------------
local CandyUI_CastBar = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local kcuiCBDefaults = {
	char = {
		currentProfile = nil,
	},
	profile = {
		general = {
			id = nil,
			nCurrentTier = nil,
			nMaxThresholds = nil,
			eCastMethod = nil,
			tAnchorOffsetCharge = {347, 169, 599, 192},
			color = {"AcidGreen", "AttributeName", "BrightRed" },
			},
		}
	}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CandyUI_CastBar:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function CandyUI_CastBar:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CandyUI_CastBar OnLoad
-----------------------------------------------------------------------------------------------
function CandyUI_CastBar:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CandyUI_CastBar.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, kcuiCBDefaults)
end

-----------------------------------------------------------------------------------------------
-- CandyUI_CastBar OnDocLoaded
-----------------------------------------------------------------------------------------------
function CandyUI_CastBar:OnDocLoaded()
		if self.xmlDoc == nil then
			return
		end
	
		if self.db.char.currentProfile == nil and self.db:GetCurrentProfile() ~= nil then
			self.db.char.currentProfile = self.db:GetCurrentProfile()
		elseif self.db.char.currentProfile ~= nil and self.db.char.currentProfile ~= self.db:GetCurrentProfile() then
			self.db:SetProfile(self.db.char.currentProfile)
		end
		--Spites
		Apollo.LoadSprites("NewSprite.xml")
		
		--Windows
		self.wndCharge = Apollo.LoadForm(self.xmlDoc,"CandyUI_ChargeBar", nil , self)
		self.wndHide   = Apollo.LoadForm(self.xmlDoc,"HideCastBars", nil , self)
		self.wndHide:Show(false)
		self.wndCharge:Show(false)
		
		--Events
		Apollo.RegisterEventHandler("StartSpellThreshold", 	"OnStartSpellThreshold" , self)
		Apollo.RegisterEventHandler("ClearSpellThreshold", 	"OnClearSpellThreshold" , self)
		Apollo.RegisterEventHandler("UpdateSpellThreshold", "OnUpdateSpellThreshold", self)
		Apollo.RegisterEventHandler("NextFrame",			"OnFrameUpdate"			, self)
		
		--Slashcommands
		Apollo.RegisterSlashCommand("CastBar", "ShowCastBar", self)
		
		--WindowCOntrols
		self:SetWindows()
	
		--Check for Options addon
		local bOptionsLoaded = _cui.bOptionsLoaded
		if bOptionsLoaded then
			--Load Options
			self:OnCUIOptionsLoaded()
		else
			--Schedule for later
			Apollo.RegisterEventHandler("CandyUI_Loaded", "OnCUIOptionsLoaded", self)
		end
		
end

-----------------------------------------------------------------------------------------------
-- CandyUI_CastBar Functions
-----------------------------------------------------------------------------------------------
function CandyUI_CastBar:OnCUIOptionsLoaded()
	--Load Options
	local wndOptionsControls = Apollo.GetAddon("CandyUI").wndOptions:FindChild("OptionsDialogueControls")
	self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControlsList", wndOptionsControls, self)
	CUI_RegisterOptions("CastBar", self.wndControls)
end


-- Define general functions here
function CandyUI_CastBar:OnFrameUpdate()
	if self.wndCharge:IsShown() then
		local fPercentDone = GameLib.GetSpellThresholdTimePrcntDone(self.db.profile.general.id)
		self.wndCharge:FindChild("ChargeBarP"):SetMax(1)
		self.wndCharge:FindChild("ChargeBarP"):SetProgress(fPercentDone)
	else
		local time =  GameLib.GetSpellThresholdTimePrcntDone(self.db.profile.general.id)
		self.wndCharge:FindChild("ChargeBarP"):SetMax(1)
		self.wndCharge:FindChild("ChargeBarP"):SetProgress(1 - time)
	end
	
end


function CandyUI_CastBar:OnStartSpellThreshold(idSpell, nMaxThresholds, eCastMethod)

	if ( self.db.profile.general.id == idSpell) then 
		self.db.profile.general.nCurrentTier = self.db.profile.general.nCurrentTier +1
		return
	end
	--if u start attacking while "show" is active
	self.wndHide:Show(false)
	
	
	self.db.profile.general.id = idSpell
	self.db.profile.general.nCurrentTier = 1
	self.db.profile.general.eCastMethod = eCastMethod
	self.db.profile.general.nMaxThresholds = nMaxThresholds
	
	self.wndCharge:Show(true)
	self.wndCharge:FindChild("ChargeBarP"):SetBarColor(self.db.profile.general.color[1])
	self.wndCharge:FindChild("ChargeCount"):SetText(tostring(1).." / "..tostring(nMaxThresholds))

end

function CandyUI_CastBar:OnClearSpellThreshold(idSpell)
	if self.db.profile.general.id ~= idSpell then
		return
	end
	self.db.profile.general.id = nil
	self.db.profile.general.nCurrentTier = 0
	self.db.profile.general.nMaxThresholds = nil
	self.db.profile.general.eCastMethod = nil

	self.wndCharge:Show(false)
end

function CandyUI_CastBar:OnUpdateSpellThreshold(idSpell, nNewThreshold)
	if self.db.profile.general.id ~= idSpell and self.db.profile.general.id ~= nil then
		return
	end
	self.db.profile.general.nCurrentTier = nNewThreshold
	self.wndCharge:FindChild("ChargeBarP"):SetBarColor(self.db.profile.general.color[nNewThreshold])
	self.wndCharge:FindChild("ChargeCount"):SetText(tostring(nNewThreshold).." / "..tostring(self.db.profile.general.nMaxThresholds))
end

function CandyUI_CastBar:ShowCastBar()
	if self.wndCharge:IsShown() then
		self.wndCharge:Show(false)
		self.wndHide:Show(false)
	else
		self.wndCharge:Show(true)
		self.wndHide:Show(true)
	end
end

-----------------------------------------------------------------------------------------------
-- Window Controls
-----------------------------------------------------------------------------------------------

function CandyUI_CastBar:SetWindows()
	local l , t, r, b = unpack(self.db.profile.general.tAnchorOffsetCharge)
	self.wndCharge:SetAnchorOffsets(l , t, r, b)
end

function CandyUI_CastBar:OnBarMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	if wndControl:GetName() == "CandyUI_ChargeBar" then
		self.db.profile.general.tAnchorOffsetCharge = {wndControl:GetAnchorOffsets()}
	end
end
---

-----------------------------------------------------------------------------------------------
-- CandyUI_CastBar Instance
-----------------------------------------------------------------------------------------------
local CandyUI_CastBarInst = CandyUI_CastBar:new()
CandyUI_CastBarInst:Init()
