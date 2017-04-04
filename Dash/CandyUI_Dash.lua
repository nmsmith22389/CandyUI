-----------------------------------------------------------------------------------------------
-- Client Lua Script for CandyUI_Dash
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- CandyUI_Dash Module Definition
-----------------------------------------------------------------------------------------------
local CandyUI_Dash = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local knEvadeResource = 7 -- the resource hooked to dodges (TODO replace with enum)

local eEnduranceFlash =
{
	EnduranceFlashZero = 1,
	EnduranceFlashOne = 2,
	EnduranceFlashTwo = 3,
	EnduranceFlashThree = 4,
}
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CandyUI_Dash:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function CandyUI_Dash:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CandyUI_Dash OnLoad
-----------------------------------------------------------------------------------------------
function CandyUI_Dash:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CandyUI_Dash.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, kcuiDashDefaults)
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Dash OnDocLoaded
-----------------------------------------------------------------------------------------------
function CandyUI_Dash:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
		return
	end
	
	--Check for Options addon
	local bOptionsLoaded = _cui.bOptionsLoaded
	if bOptionsLoaded then
		--Load Options
		self:OnCUIOptionsLoaded()
	else
		--Schedule for later
		Apollo.RegisterEventHandler("CandyUI_Loaded", "OnCUIOptionsLoaded", self)
	end
	
	if self.db.char.currentProfile == nil and self.db:GetCurrentProfile() ~= nil then
		self.db.char.currentProfile = self.db:GetCurrentProfile()
	elseif self.db.char.currentProfile ~= nil and self.db.char.currentProfile ~= self.db:GetCurrentProfile() then
		self.db:SetProfile(self.db.char.currentProfile)
	end	
	
	Apollo.LoadSprites("Sprites.xml")
	
	Apollo.RegisterEventHandler("UnitEnteredCombat", 					"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("RefreshHealthShieldBar", 				"OnFrameUpdate", self)	
	Apollo.RegisterEventHandler("SprintEnergyUpdated",			"OnSprintEnergyUpdated", self)
	Apollo.RegisterTimerHandler("HealthShieldBarTimer", 				"OnFrameUpdate", self)
	Apollo.RegisterTimerHandler("EnduranceDisplayTimer", 				"OnEnduranceDisplayTimer", self)

	Apollo.CreateTimer("HealthShieldBarTimer", 0.5, true)
	--Apollo.CreateTimer("EnduranceDisplayTimer", 30, false) --TODO: Fix(?) This is perma-killing the display when DT dashing is disabled via the toggle

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "DashForm", "FixedHudStratum", self)

	self.bInCombat = false
	self.eEnduranceState = eEnduranceFlash.EnduranceFlashZero

	self.bEnduranceFadeTimer = false
	dashtest = self.wndMain:FindChild("Bar")
	-- For flashes
	self.nLastEnduranceValue = 0

	--self.xmlDoc = nil
	self:OnFrameUpdate()
	
	self.wndMain:SetAnchorOffsets(unpack(self.db.profile.general.tAnchorOffsets))
end

function CandyUI_Dash:OnCUIOptionsLoaded()
	--Load Options
	local wndOptionsControls = Apollo.GetAddon("CandyUI").wndOptions:FindChild("OptionsDialogueControls")
	self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControlsList", wndOptionsControls, self)
	CUI_RegisterOptions("Dash", self.wndControls)
	self:SetOptions()	
	--self:SetLooks()
end

function CandyUI_Dash:OnFrameUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then
		return
	end

	local nEvadeCurr = unitPlayer:GetResource(knEvadeResource)
	local nEvadeMax = unitPlayer:GetMaxResource(knEvadeResource)
	self:UpdateEvades(nEvadeCurr, nEvadeMax)

	local bShowDoubleTapToDash = Apollo.GetConsoleVariable("player.showDoubleTapToDash")
	local bSettingDoubleTapToDash = Apollo.GetConsoleVariable("player.doubleTapToDash")

	if self.bInCombat or nRunCurr ~= nRunMax or nEvadeCurr ~= nEvadeMax then
		Apollo.StopTimer("EnduranceDisplayTimer")
		self.bEnduranceFadeTimer = false
		self.wndMain:Show(true, true)
	elseif not self.bEnduranceFadeTimer then
		Apollo.StopTimer("EnduranceDisplayTimer")
		Apollo.StartTimer("EnduranceDisplayTimer")
		self.bEnduranceFadeTimer = true
	end
	
	--HIDE WHEN FULL
	--Think about replacing with Endurance Display Timer
	--Also add a 
	if self.db.profile.general.bHideWhenFull and nEvadeCurr == nEvadeMax then
		self.wndMain:Show(false)
	end
	
	--hide evade UI while in a vehicle.
	if unitPlayer:IsInVehicle() then
		self.wndMain:Show(false)
	end
end

function CandyUI_Dash:UpdateEvades(nEvadeValue, nEvadeMax)
	local nMaxTick = math.floor(nEvadeMax/100)
	local nMaxState = eEnduranceFlash.EnduranceFlashTwo
	
	if nMaxTick == 3 then
		--turn green
		--self.wndMain:FindChild("Bar"):SetBGColor("xkcdRadioactiveGreen")
		nMaxState = eEnduranceFlash.EnduranceFlashThree
	end
	
	local nTickValue = nEvadeValue % 100 == 0 and 100 or nEvadeValue % 100
	self.wndMain:FindChild("Bar"):SetMax(100)
	self.wndMain:FindChild("Bar"):SetFloor(0)
	self.wndMain:FindChild("Bar"):SetProgress(nTickValue)
	--Print(nTickValue.." / "..100)
	if nEvadeValue >= nEvadeMax then -- all full
		self.wndMain:FindChild("Text"):SetText(nMaxTick)
		self.wndMain:FindChild("FullCircle"):Show(true)
		--turn green
		self.wndMain:FindChild("Bar"):SetBGColor("xkcdRadioactiveGreen")
		self.wndMain:FindChild("Text"):SetTextColor("xkcdRadioactiveGreen")
		if self.nEnduranceState ~= nMaxState then
			self.nEnduranceState = nMaxState
		end
	elseif math.floor(nEvadeValue/100) < 1 then -- none ready
		self.wndMain:FindChild("Text"):SetText("0")
		self.wndMain:FindChild("FullCircle"):Show(false)
		--turn blue
		self.wndMain:FindChild("Bar"):SetBGColor("UI_BtnTextHoloListNormal")
		self.wndMain:FindChild("Text"):SetTextColor("UI_BtnTextHoloListNormal")
		if self.nEnduranceState ~= eEnduranceFlash.EnduranceFlashZero then
			self.nEnduranceState = eEnduranceFlash.EnduranceFlashZero
		end
	else -- one ready, one filling
		self.wndMain:FindChild("FullCircle"):Show(false)
		--turn blue
		self.wndMain:FindChild("Bar"):SetBGColor("UI_BtnTextHoloListNormal")
		self.wndMain:FindChild("Text"):SetTextColor("UI_BtnTextHoloListNormal")
		if nMaxState == eEnduranceFlash.EnduranceFlashThree then
			if nEvadeValue >= 200 and nEvadeValue < 300 then
				self.wndMain:FindChild("Text"):SetText("2")
				if self.nEnduranceState ~= eEnduranceFlash.EnduranceFlashTwo then
					self.nEnduranceState = eEnduranceFlash.EnduranceFlashTwo
				end
			elseif nEvadeValue >= 100 and nEvadeValue < 200 then
				self.wndMain:FindChild("Text"):SetText("1")
				if self.nEnduranceState ~= eEnduranceFlash.EnduranceFlashOne then
					self.nEnduranceState = eEnduranceFlash.EnduranceFlashOne
				end
			else
				self.wndMain:FindChild("Text"):SetText("0")
			end
		else
			self.wndMain:FindChild("Text"):SetText("1")
			if self.nEnduranceState == eEnduranceFlash.EnduranceFlashZero then
				self.nEnduranceState = eEnduranceFlash.EnduranceFlashOne
			elseif self.nEnduranceState == eEnduranceFlash.EnduranceFlashTwo then
				self.nEnduranceState = eEnduranceFlash.EnduranceFlashOne
			end
		end
	end

	--local strEvadeTooltop = Apollo.GetString(Apollo.GetConsoleVariable("player.doubleTapToDash") and "HealthBar_EvadeDoubleTapTooltip" or "HealthBar_EvadeKeyTooltip")
	--local strDisplayTooltip = String_GetWeaselString(strEvadeTooltop, math.floor(nEvadeValue / 100), math.floor(nEvadeMax / 100))
	--self.wndMain:FindChild("Text"):SetTooltip(strDisplayTooltip)

	self.nLastEnduranceValue = nEvadeValue
end

function CandyUI_Dash:OnEnteredCombat(unit, bInCombat)
	if unit == GameLib.GetPlayerUnit() then
		self.bInCombat = bInCombat
	end
end

function CandyUI_Dash:OnEnduranceDisplayTimer()
	self.bEnduranceFadeTimer = false
	self.wndMain:Show(false)
end

function CandyUI_Dash:OnMouseButtonDown(wnd, wndControl, iButton, nX, nY, bDouble)
	if iButton == 0 then -- Left Click
		GameLib.SetTargetUnit(GameLib.GetPlayerUnit())
	end
	return true -- stop propogation
end

--function HealthShieldBar:OnDisableDashToggle(wndHandler, wndControl)
	--Apollo.SetConsoleVariable("player.doubleTapToDash", not wndControl:IsChecked())
	--self.wndEndurance:FindChild("EvadeDisabledBlocker"):Show(not wndControl:IsChecked())
	--self.wndEndurance:FindChild("EvadeProgress"):Show(not wndControl:IsChecked())
	--self.wndDisableDash:FindChild("DisableDashToggleFlash"):Show(not wndControl:IsChecked())
	--self:OnFrameUpdate()
--end
---------------------------------------------------------------------------------------------------
-- Sprintbar Functions (added by Charge)
---------------------------------------------------------------------------------------------------
function CandyUI_Dash:OnSprintEnergyUpdated(nRunCurr, nRunMax)
	local bar = self.wndMain:FindChild("SprintBar")
	
	bar:SetMax(nRunMax)
	bar:SetProgress(nRunCurr)
	SendVarToRover("testing var: tItem", nRunMax)
	if (nRunCurr < 170) then 
		bar:SetBGColor("red")
		return
	end
	if (nRunCurr < 340) then 
		bar:SetBGColor("xkcdAmber")
		return
	end
	bar:SetBGColor("ChatGuild")
	
end

---------------------------------------------------------------------------------------------------
-- DashForm Functions
---------------------------------------------------------------------------------------------------

function CandyUI_Dash:OnWindowMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.db.profile.general.tAnchorOffsets = {wndControl:GetAnchorOffsets()}
end

kcuiDashDefaults = {
	char = {
		currentProfile = nil,
	},
	profile = {
		general = {
			tAnchorOffsets = { 0, 0, 60, 60},
			bHideWhenFull = false,
		},
	},
}

function CandyUI_Dash:SetOptions()
	if self.wndMain then
		self.wndMain:SetAnchorOffsets(unpack(self.db.profile.general.tAnchorOffsets))
		self.wndControls:FindChild("GeneralControls:HideWhenFullToggle"):SetCheck(self.db.profile.general.bHideWhenFull)
	end
end

function CandyUI_Dash:OnHideWhenFullClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bHideWhenFull = wndControl:IsChecked()
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Dash Instance
-----------------------------------------------------------------------------------------------
local CandyUI_DashInst = CandyUI_Dash:new()
CandyUI_DashInst:Init()
