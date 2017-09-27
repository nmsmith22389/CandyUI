-----------------------------------------------------------------------------------------------
-- Client Lua Script for CandyUI_Resources
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- CandyUI_Resources Module Definition
-----------------------------------------------------------------------------------------------
local CandyUI_Resources = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local knEngineerPetGroupId = 298 -- TODO Hardcoded engineer pet grouping

local ktEngineerStanceToShortString =
{
	[0] = "",
	[1] = Apollo.GetString("EngineerResource_Aggro"),
	[2] = Apollo.GetString("EngineerResource_Defend"),
	[3] = Apollo.GetString("EngineerResource_Passive"),
	[4] = Apollo.GetString("EngineerResource_Assist"),
	[5] = Apollo.GetString("EngineerResource_Stay"),
}

--%%%%%%%%%%%
--   ROUND
--%%%%%%%%%%%
local function round(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end

--%%%%%%%%%%%%%
--Key By Value
--%%%%%%%%%%%%%
local function GetKey(tTable, strValue)
	for k, v in pairs(tTable) do
		if tostring(v) == tostring(strValue) then
			return k
		end
	end
	return nil
end
----
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CandyUI_Resources:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function CandyUI_Resources:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CandyUI_Resources OnLoad
-----------------------------------------------------------------------------------------------
function CandyUI_Resources:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CandyUI_Resources.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, kcuiRDefaults)
	Apollo.RegisterEventHandler("ActionBarLoaded", "CheckIfLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Resources OnDocLoaded
-----------------------------------------------------------------------------------------------
function CandyUI_Resources:OnDocLoaded()
	if self.xmlDoc == nil then
		return
	end
	
	if self.db.char.currentProfile == nil and self.db:GetCurrentProfile() ~= nil then
		self.db.char.currentProfile = self.db:GetCurrentProfile()
	elseif self.db.char.currentProfile ~= nil and self.db.char.currentProfile ~= self.db:GetCurrentProfile() then
		self.db:SetProfile(self.db.char.currentProfile)
	end	
	
	Apollo.LoadSprites("Sprites.xml")
	
	--Check for Options addon
	local bOptionsLoaded = _cui.bOptionsLoaded
	if bOptionsLoaded then
		--Load Options
		self:OnCUIOptionsLoaded()
	else
		--Schedule for later
		Apollo.RegisterEventHandler("CandyUI_Loaded", "OnCUIOptionsLoaded", self)
	end
	
	GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
  	self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
	self.colorPicker:Show(false, true)

	self:CheckIfLoaded()
	--self:SetOptions()
end

function CandyUI_Resources:CheckIfLoaded()
	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	else
		Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	end
end

function CandyUI_Resources:OnCUIOptionsLoaded()
	--Load Options
	local wndOptionsControls = Apollo.GetAddon("CandyUI").wndOptions:FindChild("OptionsDialogueControls")
	self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControlsList", wndOptionsControls, self)
	CUI_RegisterOptions("Resources", self.wndControls)
	self:SetOptions()
end

function CandyUI_Resources:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	end
	local eClassId =  unitPlayer:GetClassId()
	if 		eClassId == GameLib.CodeEnumClass.Engineer 		then
		self:OnCreateEngineer()
	elseif 	eClassId == GameLib.CodeEnumClass.Esper 		then
		self:OnCreateEsper()
	elseif 	eClassId == GameLib.CodeEnumClass.Spellslinger 	then
		self:OnCreateSlinger()
	elseif 	eClassId == GameLib.CodeEnumClass.Medic 		then
		self:OnCreateMedic()
	elseif 	eClassId == GameLib.CodeEnumClass.Stalker 		then
		self:OnCreateStalker()
	elseif 	eClassId == GameLib.CodeEnumClass.Warrior 		then
		self:OnCreateWarrior()
	end
end

-----------------------------------------------------------------------------------------------
-- Esper
-----------------------------------------------------------------------------------------------

function CandyUI_Resources:OnCreateEsper()
	Apollo.RegisterEventHandler("NextFrame", 		"OnEsperUpdateTimer", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEsperEnteredCombat", self)
	
	
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "EsperResourceForm", "FixedHudStratum", self)
	self.wndMain:ToFront()
	
	--self.wndMain:SetAnchorOffsets(unpack(self.db.profile.esper.tAnchorOffsets))
	
	self.bPPFull = false
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self:OnEsperEnteredCombat(unitPlayer, unitPlayer:IsInCombat())
	end
	
	local l, t, r, b = unpack(self.db.profile.esper.tAnchorOffsets)
	self.wndMain:SetAnchorOffsets(l, t, l + self.db.profile.esper.nWidth, b)
end

function CandyUI_Resources:OnEsperUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()

	-- Combo Points Animation
	local nComboMax = unitPlayer:GetMaxResource(1)
	local nComboCurrent = unitPlayer:GetResource(1)
	
	self.wndEsper1 = self.wndMain:FindChild("Segment1")
	self.wndEsper2 = self.wndMain:FindChild("Segment2")
	self.wndEsper3 = self.wndMain:FindChild("Segment3")
	self.wndEsper4 = self.wndMain:FindChild("Segment4")
	self.wndEsper5 = self.wndMain:FindChild("Segment5")
	
	-- Combo Points Solid
	--Red on 5 points
	self.wndEsper1:FindChild("Full"):Show(nComboCurrent >= 1)
	self.wndEsper2:FindChild("Full"):Show(nComboCurrent >= 2)
	self.wndEsper3:FindChild("Full"):Show(nComboCurrent >= 3)
	self.wndEsper4:FindChild("Full"):Show(nComboCurrent >= 4)
	self.wndEsper5:FindChild("Full"):Show(nComboCurrent >= 5)
	
	if nComboCurrent == 5 then
		self.bPPFull = true
		for idx, wndCurr in pairs({ self.wndEsper1 , self.wndEsper2, self.wndEsper3, self.wndEsper4, self.wndEsper5}) do
			wndCurr:SetBGColor(self.db.profile.esper.crFullColor)
			wndCurr:FindChild("Full"):SetBGColor(self.db.profile.esper.crFullColor)
		end
	else
		if self.bPPFull then
			self.bPPFull = false
			for idx, wndCurr in pairs({ self.wndEsper1 , self.wndEsper2, self.wndEsper3, self.wndEsper4, self.wndEsper5}) do
				if bInCombat then
					wndCurr:SetBGColor(self.db.profile.esper.crCombatColor)
					wndCurr:FindChild("Full"):SetBGColor(self.db.profile.esper.crCombatColor)
				else
					wndCurr:SetBGColor(self.db.profile.esper.crBarColor)
					wndCurr:FindChild("Full"):SetBGColor(self.db.profile.esper.crBarColor)
				end
			end
		end
	end
	
	if self.wndMain:GetOpacity() ~= self.db.profile.esper.nOpacity then
		self.wndMain:SetOpacity(self.db.profile.esper.nOpacity)
	end

	-- Innate
	--[[
	local bInnate = GameLib.IsCurrentInnateAbilityActive()
	if bInnate and not self.wndMain:FindChild("InnateActiveGlowTop"):GetData() then
		self.wndMain:FindChild("InnateActiveGlowTop"):SetData(true)
		self.wndMain:FindChild("InnateActiveGlowTop"):SetSprite("sprEsper_Anim_OuterGlow_Top")
		self.wndMain:FindChild("InnateActiveGlowBottom"):SetSprite("sprEsper_Anim_OuterGlow_Bottom")
		self.wndMain:FindChild("InnateActiveGlowFrame"):SetSprite("sprEsper_Anim_OuterGlow_Frame")
	elseif not bInnate then
		self.wndMain:FindChild("InnateActiveGlowTop"):SetData(false)
	end
	]]
	--self:HelperToggleVisibiltyPreferences(self.wndMain, unitPlayer)
end

function CandyUI_Resources:OnEsperEnteredCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	if bInCombat then
		self.wndMain:Show(self.db.profile.esper.bInCombat)
	else
		self.wndMain:Show(self.db.profile.esper.bOutCombat)
	end
	for idx, wndCurr in pairs({ self.wndEsper1 , self.wndEsper2, self.wndEsper3, self.wndEsper4, self.wndEsper5}) do
		if not self.bPPFull then
			if bInCombat then
				wndCurr:SetBGColor(self.db.profile.esper.crCombatColor)
				wndCurr:FindChild("Full"):SetBGColor(self.db.profile.esper.crCombatColor)
			else
				wndCurr:SetBGColor(self.db.profile.esper.crBarColor)
				wndCurr:FindChild("Full"):SetBGColor(self.db.profile.esper.crBarColor)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Spellslinger
-----------------------------------------------------------------------------------------------

function CandyUI_Resources:OnCreateSlinger()

	Apollo.RegisterEventHandler("NextFrame", 		"OnSlingerUpdateTimer", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnSlingerEnteredCombat", self)

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "SpellSlingerResourceForm", "FixedHudStratum", self)
	self.wndMain:ToFront()
	--self.wndMain:SetAnchorOffsets(unpack(self.db.profile.spellslinger.tAnchorOffsets))
	
	self.wndSlinger1 = self.wndMain:FindChild("Segment1")
	self.wndSlinger2 = self.wndMain:FindChild("Segment2")
	self.wndSlinger3 = self.wndMain:FindChild("Segment3")
	self.wndSlinger4 = self.wndMain:FindChild("Segment4")
	self.wndSlinger1:FindChild("Bar"):SetProgress(250)
	self.wndSlinger2:FindChild("Bar"):SetProgress(250)
	self.wndSlinger3:FindChild("Bar"):SetProgress(250)
	self.wndSlinger4:FindChild("Bar"):SetProgress(250)

	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self:OnSlingerEnteredCombat(unitPlayer, unitPlayer:IsInCombat())
	end
	
	local l, t, r, b = unpack(self.db.profile.spellslinger.tAnchorOffsets)
	self.wndMain:SetAnchorOffsets(l, t, l + self.db.profile.spellslinger.nWidth, b)
	
end

function CandyUI_Resources:OnSlingerUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	local nResourceMax = unitPlayer:GetMaxResource(4)
	local nResourceCurrent = unitPlayer:GetResource(4)
	local nResourceMaxDivided = nResourceMax / 4
	local bSurgeActive = GameLib.IsSpellSurgeActive()
	local bInCombat = unitPlayer:IsInCombat()

	-- Nodes
	local strNodeTooltip = String_GetWeaselString(Apollo.GetString("Spellslinger_SpellSurge"), nResourceCurrent, nResourceMax)
	for idx, wndCurr in pairs({ self.wndSlinger1, self.wndSlinger2, self.wndSlinger3, self.wndSlinger4 }) do
		local nPartialProgress = nResourceCurrent - (nResourceMaxDivided * (idx - 1)) -- e.g. 250, 500, 750, 1000
		local bThisBubbleFilled = nPartialProgress >= nResourceMaxDivided
		wndCurr:FindChild("Bar"):SetMax(nResourceMaxDivided)
		wndCurr:FindChild("Bar"):SetProgress(nPartialProgress, 100)

		wndCurr:SetData(nPartialProgress)
		wndCurr:SetTooltip(strNodeTooltip)
		
		if bSurgeActive then
			wndCurr:SetBGColor(self.db.profile.spellslinger.crSurgeColor)
			wndCurr:FindChild("Bar"):SetBarColor(self.db.profile.spellslinger.crSurgeColor)
		else
			self:OnSlingerEnteredCombat(unitPlayer, bInCombat)	
		end
	end
	
	if self.wndMain:GetOpacity() ~= self.db.profile.spellslinger.nOpacity then
		self.wndMain:SetOpacity(self.db.profile.spellslinger.nOpacity)
	end
	
	-- Surge
	self.wndMain:FindChild("SpellSurge"):Show(bSurgeActive)--, bSurgeActive)
	if self.wndMain:FindChild("SpellSurge"):IsShown() and bSurgeActive then
		self.wndMain:FindChild("SpellSurge:Left"):SetBGColor(self.db.profile.spellslinger.crSurgeColor)
		self.wndMain:FindChild("SpellSurge:Right"):SetBGColor(self.db.profile.spellslinger.crSurgeColor)
	end
	--self:HelperToggleVisibiltyPreferences(self.wndMain, unitPlayer)
	
	--Ignite
	if self.db.profile.spellslinger.bIgnite then
		local unitTarget = GameLib.GetTargetUnit()
		local tBuffs = {}
		if unitTarget then 
			tBuffs = unitTarget:GetBuffs()
		end
		if self.wndMain:FindChild("IgniteDot1"):IsShown() then
			self.wndMain:FindChild("IgniteDot1"):Show(false)
		end
		if self.wndMain:FindChild("IgniteDot2"):IsShown() then
			self.wndMain:FindChild("IgniteDot2"):Show(false)
		end
		for idx, tCurrBuffData in pairs(tBuffs.arHarmful or {}) do
			if tCurrBuffData.splEffect:GetId() == 49149 and not self.wndMain:FindChild("IgniteDot1"):IsShown() then
				self.wndMain:FindChild("IgniteDot1"):Show(true)
			end
			if tCurrBuffData.splEffect:GetId() == 49158 and not self.wndMain:FindChild("IgniteDot2"):IsShown() then
				self.wndMain:FindChild("IgniteDot2"):Show(true)
			end
		end
	else
		if self.wndMain:FindChild("IgniteDot1"):IsShown() then
			self.wndMain:FindChild("IgniteDot1"):Show(false)
		end
		if self.wndMain:FindChild("IgniteDot2"):IsShown() then
			self.wndMain:FindChild("IgniteDot2"):Show(false)
		end
	end
	
	--Assassinate
	if self.db.profile.spellslinger.bAssassinate and AbilityBook.GetAbilityInfo(49054).bIsActive then
		local tSpellInfo = AbilityBook.GetAbilityInfo(49054)
		local nCurrentTier = tSpellInfo.nCurrentTier
		local splCurr = tSpellInfo.tTiers[nCurrentTier].splObject
		local nCharges = splCurr:GetAbilityCharges().nChargesRemaining or 0
		if self.wndMain:FindChild("Ass1"):IsShown() then
			self.wndMain:FindChild("Ass1"):Show(false)
		end
		if self.wndMain:FindChild("Ass2"):IsShown() then
			self.wndMain:FindChild("Ass2"):Show(false)
		end
		if self.wndMain:FindChild("Ass3"):IsShown() then
			self.wndMain:FindChild("Ass3"):Show(false)
		end
		for idx=1, nCharges do
			if not self.wndMain:FindChild("Ass"..idx):IsShown() then
				self.wndMain:FindChild("Ass"..idx):Show(true)
			end
		end
	else
		if self.wndMain:FindChild("Ass1"):IsShown() then
			self.wndMain:FindChild("Ass1"):Show(false)
		end
		if self.wndMain:FindChild("Ass2"):IsShown() then
			self.wndMain:FindChild("Ass2"):Show(false)
		end
		if self.wndMain:FindChild("Ass3"):IsShown() then
			self.wndMain:FindChild("Ass3"):Show(false)
		end
	end
end

function CandyUI_Resources:OnSlingerEnteredCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	for idx, wndCurr in pairs({ self.wndSlinger1, self.wndSlinger2, self.wndSlinger3, self.wndSlinger4 }) do
		if bInCombat then
			wndCurr:SetBGColor(self.db.profile.spellslinger.crCombatColor)
			wndCurr:FindChild("Bar"):SetBarColor(self.db.profile.spellslinger.crCombatColor)
		else
			wndCurr:SetBGColor(self.db.profile.spellslinger.crBarColor)
			wndCurr:FindChild("Bar"):SetBarColor(self.db.profile.spellslinger.crBarColor)
		end
	end
end



-----------------------------------------------------------------------------------------------
-- Medic
-----------------------------------------------------------------------------------------------

function CandyUI_Resources:OnCreateMedic()
	Apollo.RegisterEventHandler("NextFrame", 		"OnMedicUpdateTimer", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnMedicEnteredCombat", self)
	
	
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "MedicResourceForm", "FixedHudStratum", self)
	self.wndMain:ToFront()
	--self.wndMain:SetAnchorOffsets(unpack(self.db.profile.medic.tAnchorOffsets))
	
	self.wndMedic1 = self.wndMain:FindChild("Segment1")
	self.wndMedic2 = self.wndMain:FindChild("Segment2")
	self.wndMedic3 = self.wndMain:FindChild("Segment3")
	self.wndMedic4 = self.wndMain:FindChild("Segment4")

	for idx, wndCurr in pairs({ self.wndMedic1, self.wndMedic2, self.wndMedic3, self.wndMedic4 }) do
		wndCurr:FindChild("Bar"):SetMax(100)
	end
		
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self:OnMedicEnteredCombat(unitPlayer, self.bCombat)
	end
	
	
	local l, t, r, b = unpack(self.db.profile.medic.tAnchorOffsets)
	self.wndMain:SetAnchorOffsets(l, t, l + self.db.profile.medic.nWidth, b)
end

function CandyUI_Resources:OnMedicUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	local nResourceMax = unitPlayer:GetMaxResource(1)
	local nResourceCurrent = unitPlayer:GetResource(1)
	local tBuffs = unitPlayer:GetBuffs()

	-- Partial Node Count
	local nPartialCount = 0
	for idx, tCurrBuffData in pairs(tBuffs.arBeneficial or {}) do
		if tCurrBuffData.splEffect:GetId() == 42569 then
			nPartialCount = tCurrBuffData.nCount
			break
		end
	end

	-- Nodes
	for idx = 1, 4 do
		local strIndex = "wndMedic"..idx
		local bFull = nResourceCurrent >= idx
		local bFirstPartial = idx == nResourceCurrent + 1
		local bShowPartial = bFirstPartial and nPartialCount > 0

		-- Bar
		--local strSpriteToUse = ""
		if bFull then
			self[strIndex]:FindChild("Bar"):SetProgress(100)
		elseif bShowPartial and nPartialCount == 2 then
			self[strIndex]:FindChild("Bar"):SetProgress(66)
			--Print(66)
		elseif bShowPartial and nPartialCount == 1 then
			self[strIndex]:FindChild("Bar"):SetProgress(33)
			--Print(33)
		else
			self[strIndex]:FindChild("Bar"):SetProgress(0)
		end
	end
	
	--Print(nPartialCount.."   partial")
	--Print(unitPlayer:GetResource(1))
	if self.wndMain:GetOpacity() ~= self.db.profile.medic.nOpacity then
		self.wndMain:SetOpacity(self.db.profile.medic.nOpacity)
	end

	--self:HelperToggleVisibiltyPreferences(self.wndMain, unitPlayer)
end

function CandyUI_Resources:OnMedicEnteredCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	for idx, wndCurr in pairs({ self.wndMedic1, self.wndMedic2, self.wndMedic3, self.wndMedic4 }) do
		if bInCombat then
			wndCurr:SetBGColor(self.db.profile.medic.crCombatColor)
			wndCurr:FindChild("Bar"):SetBarColor(self.db.profile.medic.crCombatColor)
		else
			wndCurr:SetBGColor(self.db.profile.medic.crBarColor)
			wndCurr:FindChild("Bar"):SetBarColor(self.db.profile.medic.crBarColor)
		end
	end
end

function CandyUI_Resources:OnGeneratePetCommandTooltip(wndControl, wndHandler, eType, arg1, arg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		xml = XmlDoc.new()
		if arg1 ~= nil then
			xml:AddLine(arg1:GetTooltips()["strCasterTooltip"])
		end
		wndControl:SetTooltipDoc(xml)
	end
end


-----------------------------------------------------------------------------------------------
-- Engineer
-----------------------------------------------------------------------------------------------

function CandyUI_Resources:OnCreateEngineer()
	Apollo.RegisterEventHandler("NextFrame", 		"OnEngineerUpdateTimer", self)

	Apollo.RegisterEventHandler("ShowActionBarShortcut", 		"OnShowActionBarShortcut", self)
	Apollo.RegisterTimerHandler("EngineerOutOfCombatFade", 		"OnEngineerOutOfCombatFade", self)

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "EngineerResourceForm", "FixedHudStratum", self)
	self.wndMain:FindChild("StanceMenuOpenerBtn"):AttachWindow(self.wndMain:FindChild("StanceMenuBG"))
	--self.wndMain:SetAnchorOffsets(unpack(self.db.profile.engineer.tAnchorOffsets))
	
	self.wndPetBar = self.wndMain:FindChild("PetBarContainer")
	
	for idx = 1, 5 do
		self.wndMain:FindChild("Stance"..idx):SetData(idx)
	end
	
	--Auto Fade Option
	self.wndPetBar:SetStyle("AutoFade", self.db.profile.engineer.bPetBarUnlocked)
	self.wndPetBar:FindChild("PetBarLock"):SetCheck(self.db.profile.engineer.bPetBarUnlocked)

	self:OnShowActionBarShortcut(1, IsActionBarSetVisible(1)) -- Show petbar if active from reloadui/load screen
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self:OnEngineerEnteredCombat(unitPlayer, self.bCombat)
	end
	
	local l, t, r, b = unpack(self.db.profile.engineer.tAnchorOffsets)
	self.wndMain:SetAnchorOffsets(l, t, l + self.db.profile.engineer.nWidth, b)
end

function CandyUI_Resources:OnEngineerUpdateTimer()
	if not self.wndMain or not self.wndPetBar then
		return
	end

	local unitPlayer = GameLib.GetPlayerUnit()
	local bInCombat = unitPlayer:IsInCombat()
	local nResourceMax = unitPlayer:GetMaxResource(1)
	local nResourceCurrent = unitPlayer:GetResource(1)
	local nResourcePercent = nResourceCurrent / nResourceMax

	local wndBar = self.wndMain:FindChild("ProgressBar:Bar")
	local wndBarBG = self.wndMain:FindChild("ProgressBar")
	local wndBarText = self.wndMain:FindChild("ProgressBar:Bar:Text")
	wndBar:SetMax(nResourceMax)
	wndBar:SetProgress(nResourceCurrent)
	if self.db.profile.engineer.bShowText then
		wndBarText:SetText(String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), nResourceCurrent, nResourceMax))
	else
		wndBarText:SetText("")
	end	
	
	if self.wndMain:GetOpacity() ~= self.db.profile.engineer.nOpacity then
		self.wndMain:SetOpacity(self.db.profile.engineer.nOpacity)
	end
	
	if unitPlayer then
		self:OnEngineerEnteredCombat(unitPlayer, bInCombat)
	end
	
	--self:HelperToggleVisibiltyPreferences(self.wndMain, unitPlayer)
end

function CandyUI_Resources:OnEngineerEnteredCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	if bInCombat then
		local unitPlayer = GameLib.GetPlayerUnit()
		if unitPlayer:GetResource(1)<= 70 and  unitPlayer:GetResource(1)>= 30 then
			self.wndMain:FindChild("ProgressBar"):SetBGColor(self.db.profile.engineer.crInZone)
			self.wndMain:FindChild("ProgressBar:Bar"):SetBarColor(self.db.profile.engineer.crInZone)
		else
			self.wndMain:FindChild("ProgressBar"):SetBGColor(self.db.profile.engineer.crCombatColor)
			self.wndMain:FindChild("ProgressBar:Bar"):SetBarColor(self.db.profile.engineer.crCombatColor)
		end
	else
		self.wndMain:FindChild("ProgressBar"):SetBGColor(self.db.profile.engineer.crBarColor)
		self.wndMain:FindChild("ProgressBar:Bar"):SetBarColor(self.db.profile.engineer.crBarColor)
	end
	
	if GameLib.IsCurrentInnateAbilityActive() then
		self.wndMain:FindChild("ProgressBar"):SetBGColor(self.db.profile.engineer.crInZone)
		self.wndMain:FindChild("ProgressBar:Bar"):SetBarColor(self.db.profile.engineer.crInZone)
	end
end

function CandyUI_Resources:OnShowActionBarShortcut(eWhichBar, bIsVisible, nNumShortcuts)
	if eWhichBar ~= ActionSetLib.CodeEnumShortcutSet.PrimaryPetBar  or not self.wndMain or not self.wndMain:IsValid() then -- the engineer pet bar
		return
	end

	--self.wndMain:FindChild("PetBtn"):Show(bIsVisible)
	self.wndPetBar:Show(bIsVisible)
end

function CandyUI_Resources:OnEngineerPetBtnMouseEnter(wndHandler, wndControl)
	wndHandler:SetBGColor("white")
	local strHover = ""
	local strWindowName = wndHandler:GetName()
	if strWindowName == "ActionBarShortcut.12" then
		strHover = Apollo.GetString("ClassResources_Engineer_PetAttack")
	elseif strWindowName == "ActionBarShortcut.13" then
		strHover = Apollo.GetString("CRB_Stop")
	elseif strWindowName == "ActionBarShortcut.15" then
		strHover = Apollo.GetString("ClassResources_Engineer_GoTo")
	end
	self.wndMain:FindChild("PetText"):SetText(strHover)
end

function CandyUI_Resources:OnEngineerPetBtnMouseExit(wndHandler, wndControl)
	wndHandler:SetBGColor("UI_AlphaPercent50")
	self.wndMain:FindChild("PetText"):SetText(self.wndMain:FindChild("PetText"):GetData() or "")
end

-----------------------------------------------------------------------------------------------
-- Stalker
-----------------------------------------------------------------------------------------------

function CandyUI_Resources:OnCreateStalker()
	Apollo.RegisterEventHandler("NextFrame", 		"OnStalkerUpdateTimer", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnStalkerEnteredCombat", self)

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "StalkerResourceForm", "FixedHudStratum", self)
	self.wndMain:ToFront()
	--self.wndMain:SetAnchorOffsets(unpack(self.db.profile.stalker.tAnchorOffsets))
	

	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self:OnStalkerEnteredCombat(unitPlayer, unitPlayer:IsInCombat())
	end
	
	local l, t, r, b = unpack(self.db.profile.stalker.tAnchorOffsets)
	self.wndMain:SetAnchorOffsets(l, t, l + self.db.profile.stalker.nWidth, b)
end

function CandyUI_Resources:OnStalkerUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	local nResourceMax = unitPlayer:GetMaxResource(3)
	local nResourceCurrent = unitPlayer:GetResource(3)
	local bStealthActive = GameLib.IsCurrentInnateAbilityActive()
	local bInCombat = unitPlayer:IsInCombat()
	local wndBar = self.wndMain:FindChild("ProgressBar:Bar")
	
	wndBar:SetMax(nResourceMax)
	wndBar:SetProgress(nResourceCurrent)
	
	-- Stealth
	self.wndMain:FindChild("Stealth"):Show(bStealthActive)--, bSurgeActive)

	--self:HelperToggleVisibiltyPreferences(self.wndMain, unitPlayer)
end

function CandyUI_Resources:OnStalkerEnteredCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	if bInCombat then
		self.wndMain:FindChild("ProgressBar"):SetBGColor(ApolloColor.new("xkcdBrightOrange"))
		self.wndMain:FindChild("ProgressBar:Bar"):SetBarColor(ApolloColor.new("xkcdBrightOrange"))
	else
		self.wndMain:FindChild("ProgressBar"):SetBGColor(ApolloColor.new("UI_BtnTextHoloListNormal"))
		self.wndMain:FindChild("ProgressBar:Bar"):SetBarColor(ApolloColor.new("UI_BtnTextHoloListNormal"))
	end
end

-----------------------------------------------------------------------------------------------
-- Warrior
-----------------------------------------------------------------------------------------------
function CandyUI_Resources:OnCreateWarrior()
	local unitPlayer = GameLib:GetPlayerUnit()
	
	Apollo.RegisterTimerHandler("WarriorResource_ChargeBarOverdriveTick", "OnWarriorResource_ChargeBarOverdriveTick", self)
	Apollo.RegisterTimerHandler("WarriorResource_ChargeBarOverdriveDone", "OnWarriorResource_ChargeBarOverdriveDone", self)
	Apollo.RegisterEventHandler("NextFrame", "OnWarriorUpdateTimer", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnWarriorEnteredCombat", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "WarriorResourceForm", "FixedHudStratum", self)
	self.wndMain:FindChild("ChargeBarOverdriven:Bar"):SetMax(100)
	self.wndMain:ToFront()
	--self.wndMain:SetAnchorOffsets(unpack(self.db.profile.warrior.tAnchorOffsets))
	
	local l, t, r, b = unpack(self.db.profile.warrior.tAnchorOffsets)
	self.wndMain:SetAnchorOffsets(l, t, l + self.db.profile.warrior.nWidth, b)
	
	self.nOverdriveTick = 0
end

function CandyUI_Resources:OnWarriorUpdateTimer(strName, nCnt)
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then
		return
	end

	if not self.wndMain:IsValid() then
		return
	end

	local bOverdrive = GameLib.IsOverdriveActive()
	local nResourceCurr = unitPlayer:GetResource(1)
	local nResourceMax = unitPlayer:GetMaxResource(1)
	local wndChargeBar = self.wndMain:FindChild("ChargeBar")
	local wndOverdriveBar = self.wndMain:FindChild("ChargeBarOverdriven")

	wndChargeBar:FindChild("Bar"):SetMax(nResourceMax)
	wndChargeBar:FindChild("Bar"):SetProgress(nResourceCurr)
	wndChargeBar:FindChild("Bar:Text"):SetText(nResourceCurr.." / "..nResourceMax)

	if bOverdrive and not self.bOverDriveActive then
		self.bOverDriveActive = true
		wndOverdriveBar:FindChild("Bar"):SetProgress(100)
		Apollo.CreateTimer("WarriorResource_ChargeBarOverdriveTick", 0.01, false)
		Apollo.CreateTimer("WarriorResource_ChargeBarOverdriveDone", 10, false)
	end
		
	wndOverdriveBar:Show(bOverdrive)
	wndChargeBar:Show(not bOverdrive)
end

function CandyUI_Resources:OnWarriorEnteredCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	if bInCombat then
		self.wndMain:FindChild("ChargeBar"):SetBGColor(ApolloColor.new("xkcdBrightOrange"))
		self.wndMain:FindChild("ChargeBar:Bar"):SetBarColor(ApolloColor.new("xkcdBrightOrange"))
	else
		self.wndMain:FindChild("ChargeBar"):SetBGColor(ApolloColor.new("UI_BtnTextHoloListNormal"))
		self.wndMain:FindChild("ChargeBar:Bar"):SetBarColor(ApolloColor.new("UI_BtnTextHoloListNormal"))
	end
end

function CandyUI_Resources:OnWarriorResource_ChargeBarOverdriveTick()
	Apollo.StopTimer("WarriorResource_ChargeBarOverdriveTick")
	self.wndMain:FindChild("ChargeBarOverdriven:Bar"):SetProgress(0, 10) --:SetProgress(self.wndMain:FindChild("ChargeBarOverdriven:Bar"):GetProgress()-10)
end

function CandyUI_Resources:OnWarriorResource_ChargeBarOverdriveDone()
	Apollo.StopTimer("WarriorResource_ChargeBarOverdriveDone")
	self.bOverDriveActive = false
end

--===========================================================================
function CandyUI_Resources:HelperToggleVisibiltyPreferences(wndParent, unitPlayer)
	-- TODO: REFACTOR: Only need to update this on Combat Enter/Exit
	--Toggle Visibility based on ui preference
	local nVisibility = Apollo.GetConsoleVariable("hud.ResourceBarDisplay")

	if nVisibility == 2 then --always off
		wndParent:Show(false)
	elseif nVisibility == 3 then --on in combat
		wndParent:Show(unitPlayer:IsInCombat())
	elseif nVisibility == 4 then --on out of combat
		wndParent:Show(not unitPlayer:IsInCombat())
	else
		wndParent:Show(true)
	end
end
-----------------------------------------------------------------------------------------------
-- 								OPTIONS
-----------------------------------------------------------------------------------------------
kcuiRDefaults = {
	char = {
		currentProfile = nil,
	},
	profile = {
		general = {
			
		},
		--Class Specific
		esper = {
			--General
			bInCombat = true,
			bOutCombat = true,
			nWidth = 500,
			nOpacity = 1,
			crCombatColor = "xkcdLime",
			crBarColor = "UI_BtnTextHoloListNormal",
			bShowText = true,
			--class
			crFullColor = "xkcdRed",
			tAnchorOffsets = {-250, -13, 250, 12},
		},
		engineer = {
			--General
			bInCombat = true,
			bOutCombat = true,
			nWidth = 500,
			nOpacity = 1,
			crInZone = "xkcdBrightYellow",
			crCombatColor = "xkcdBrightOrange",
			crBarColor = "UI_BtnTextHoloListNormal",
			bShowText = true,
			--class
			bPetBarUnlocked = false,
			tAnchorOffsets = {-250, -13, 250, 12},
		},
		medic = {
			--General
			bInCombat = true,
			bOutCombat = true,
			nWidth = 500,
			nOpacity = 1,
			crCombatColor = "xkcdBrightOrange",
			crBarColor = "UI_BtnTextHoloListNormal",
			bShowText = true,
			tAnchorOffsets = {-250, -13, 250, 12},
		},
		spellslinger = {
			--General
			bInCombat = true,
			bOutCombat = true,
			nWidth = 500,
			nOpacity = 1,
			crCombatColor = "xkcdBrightOrange",
			crBarColor = "UI_BtnTextHoloListNormal",
			bShowText = true,
			--class
			bAssassinate = true,
			bIgnite = true,
			bHealingTorrent = true,
			crSurgeColor = "xkcdRed",
			tAnchorOffsets = {-250, -13, 250, 12},	
		},
		stalker = {
			--general
			bInCombat = true,
			bOutCombat = true,
			nWidth = 500,
			nOpacity = 1,
			crCombatColor = "xkcdBrightOrange",
			crBarColor = "UI_BtnTextHoloListNormal",
			bShowText = true,
			--class
			crStealthColor = "ChannelAccountWisper",
			tAnchorOffsets = {-250, -13, 250, 12},
		},
		warrior = {
			--general
			bInCombat = true,
			bOutCombat = true,
			nWidth = 500,
			nOpacity = 1,
			crCombatColor = "xkcdBrightOrange",
			crBarColor = "UI_BtnTextHoloListNormal",
			bShowText = true,
			--class
			crOverdriveColor = "xkcdRed",
			tAnchorOffsets = {-250, -13, 250, 12},
		},
	},
}


---------------------------------------------------------------------------------------------------
-- OptionsControlsList Functions
---------------------------------------------------------------------------------------------------
function CandyUI_Resources:SetOptions()
	local Options = self.db.profile
--General
	local generalControls = self.wndControls:FindChild("GeneralControls")
	local tOptionsControls = {
		"Esper",
		"SpellSlinger",
		"Medic",
		"Engineer",
		"Stalker",
		"Warrior",
	}
	for _, class in pairs(tOptionsControls) do 
		local controls = self.wndControls:FindChild(class.."Controls")
		local strClassLow = string.lower(class)
		--Show In Combat
		controls:FindChild("ShowInCombatToggle"):SetCheck(Options[strClassLow].bInCombat)
		--Show Out Combat
		controls:FindChild("ShowOutCombatToggle"):SetCheck(Options[strClassLow].bOutCombat)
		--Opacity
		controls:FindChild("Opacity:SliderBar"):SetValue(Options[strClassLow].nOpacity)
		controls:FindChild("Opacity:EditBox"):SetText(Options[strClassLow].nOpacity)
		--Show Text
		controls:FindChild("ShowTextToggle"):SetCheck(Options[strClassLow].bShowText)
		--Widht
		controls:FindChild("Width:Input"):SetText(Options[strClassLow].nWidth)
		--Bar Color
		controls:FindChild("BarColor:Swatch"):SetBGColor(Options[strClassLow].crBarColor)
		--Combat Bar Color
		controls:FindChild("CombatColor:Swatch"):SetBGColor(Options[strClassLow].crCombatColor)
	end
--Class Specific
--"Esper",
	--Full Color
	self.wndControls:FindChild("EsperControls"):FindChild("FullColor:Swatch"):SetBGColor(Options.esper.crFullColor)
--"SpellSlinger",
	--Surge Color
	self.wndControls:FindChild("SpellSlingerControls"):FindChild("SurgeBarColor:Swatch"):SetBGColor(Options.spellslinger.crSurgeColor)
	--Assassinate
	self.wndControls:FindChild("SpellSlingerControls"):FindChild("ShowAssassinateToggle"):SetCheck(Options.spellslinger.bAssassinate)
	--Ignite
	self.wndControls:FindChild("SpellSlingerControls"):FindChild("ShowIgniteToggle"):SetCheck(Options.spellslinger.bIgnite)
	--Healingn torrent
	self.wndControls:FindChild("SpellSlingerControls"):FindChild("ShowHTToggle"):SetCheck(Options.spellslinger.bHealingTorrent)
--"Medic",
--"Engineer",
	self.wndControls:FindChild("EngineerControls"):FindChild("InZone:Swatch"):SetBGColor(Options.engineer.crInZone)
--"Stalker",
	--Stealth
	self.wndControls:FindChild("StalkerControls"):FindChild("StealthBarColor:Swatch"):SetBGColor(Options.stalker.crStealthColor)
--"Warrior",
	--Overdrive
	self.wndControls:FindChild("WarriorControls"):FindChild("OverdriveBarColor:Swatch"):SetBGColor(Options.warrior.crOverdriveColor)
end

function CandyUI_Resources:ColorPickerCallback(strColor)
	local strUnit = self.strColorPickerTargetUnit
	local strUnitLower = string.lower(strUnit)
		if self.strColorPickerTargetControl == "Bar" then
			self.db.profile[strUnitLower].crBarColor = strColor
			self.wndControls:FindChild(strUnit.."Controls"):FindChild("BarColor"):FindChild("Swatch"):SetBGColor(strColor)
			return true
		elseif self.strColorPickerTargetControl == "CombatBar" then
			self.db.profile[strUnitLower].crCombatColor = strColor
			self.wndControls:FindChild(strUnit.."Controls"):FindChild("CombatColor"):FindChild("Swatch"):SetBGColor(strColor)
		elseif self.strColorPickerTargetControl == "SurgeBar" then
			self.db.profile.spellslinger.crSurgeColor = strColor
			self.wndControls:FindChild(strUnit.."Controls"):FindChild("SurgeBarColor"):FindChild("Swatch"):SetBGColor(strColor)
		elseif self.strColorPickerTargetControl == "StealthBar" then
			self.db.profile.stalker.crStealthColor = strColor
			self.wndControls:FindChild(strUnit.."Controls"):FindChild("StealthBarColor"):FindChild("Swatch"):SetBGColor(strColor)
		elseif self.strColorPickerTargetControl == "OverdriveBar" then
			self.db.profile.warrior.crOverdriveColor = strColor
			self.wndControls:FindChild(strUnit.."Controls"):FindChild("OverdriveBarColor"):FindChild("Swatch"):SetBGColor(strColor)
		elseif self.strColorPickerTargetControl == "EsperFull" then
			self.db.profile.esper.crFullColor = strColor
			self.wndControls:FindChild(strUnit.."Controls"):FindChild("FullColor"):FindChild("Swatch"):SetBGColor(strColor)
		elseif self.strColorPickerTargetControl == "InZone" then
			self.db.profile.engineer.crInZone = strColor
			self.wndControls:FindChild(strUnit.."Controls"):FindChild("InZone"):FindChild("Swatch"):SetBGColor(strColor)
		end
end

function CandyUI_Resources:OnWidthChanged( wndHandler, wndControl, strText )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	local nValue
	if not tonumber(strText) then nValue = 0 else
		nValue = round(tonumber(strText))
	end
	
	self.db.profile[strUnitLower].nWidth = nValue
	
	local l, t, r, b = self.wndMain:GetAnchorOffsets()
	local nHalfWidth = self.db.profile[strUnitLower].nWidth / 2
	self.wndMain:SetAnchorOffsets(-nHalfWidth, t, nHalfWidth, b)
end

function CandyUI_Resources:OnOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	local nValue = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(self.db.profile[strUnitLower].nOpacity)
	self.db.profile[strUnitLower]["nOpacity"] = nValue
end

function CandyUI_Resources:OnShowInCombatClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bInCombat = wndControl:IsChecked()
end

function CandyUI_Resources:OnShowOutCombatClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bOutCombat = wndControl:IsChecked()
end

function CandyUI_Resources:OnBarColorClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	--Open Color Picker
	self.strColorPickerTargetUnit = strUnit
	self.strColorPickerTargetControl = "Bar"
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
end

function CandyUI_Resources:OnCombatBarColorClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	--Open Color Picker
	self.strColorPickerTargetUnit = strUnit
	self.strColorPickerTargetControl = "CombatBar"
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
end

--Engineer 
function CandyUI_Resources:OnInZoneClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	--Open Color Picker
	self.strColorPickerTargetUnit = strUnit
	self.strColorPickerTargetControl = "InZone"
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
end

--Spellslinger
function CandyUI_Resources:OnShowAssassinateClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.spellslinger.bAssassinate = wndControl:IsChecked()
end

function CandyUI_Resources:OnShowIgniteClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.spellslinger.bIgnite = wndControl:IsChecked()
end

function CandyUI_Resources:OnShowHTClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bHealingTorrent = wndControl:IsChecked()
end

function CandyUI_Resources:OnSurgeBarColorClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	--Open Color Picker
	self.strColorPickerTargetUnit = strUnit
	self.strColorPickerTargetControl = "SurgeBar"
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
end

--Stalker
function CandyUI_Resources:OnStealthBarColorClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	--Open Color Picker
	self.strColorPickerTargetUnit = strUnit
	self.strColorPickerTargetControl = "StealthBar"
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
end

--Warrior
function CandyUI_Resources:OnOverdriveBarColorClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	--Open Color Picker
	self.strColorPickerTargetUnit = strUnit
	self.strColorPickerTargetControl = "OverdriveBar"
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
end

function CandyUI_Resources:OnFullColorClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	--Open Color Picker
	self.strColorPickerTargetUnit = strUnit
	self.strColorPickerTargetControl = "EsperFull"
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
end

function CandyUI_Resources:OnShowChargBar( wndHandler, wndControl, eMouseButton)
	self.wndCharge:Show(true)
end

---------------------------------------------------------------------------------------------------
-- EngineerResourceForm Functions
---------------------------------------------------------------------------------------------------

function CandyUI_Resources:OnStanceBtn( wndHandler, wndControl, eMouseButton )
	Pet_SetStance(0, tonumber(wndHandler:GetData()))
	self.wndMain:FindChild("StanceMenuOpenerBtn"):SetCheck(false)
	self.wndMain:FindChild("PetText"):SetText(wndHandler:GetText())
	self.wndMain:FindChild("PetText"):SetData(wndHandler:GetText())
end

function CandyUI_Resources:OnPetBarLockClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.engineer.bPetBarUnlocked = wndControl:IsChecked()
	self.wndPetBar:SetStyle("AutoFade", wndControl:IsChecked())
	if not wndControl:IsChecked() then
		self.wndPetBar:SetOpacity(1)
	end
end

function CandyUI_Resources:OnGeneratePetCommandTooltip(wndControl, wndHandler, eType, arg1, arg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		xml = XmlDoc.new()
		if arg1 ~= nil then
			xml:AddLine(arg1:GetTooltips()["strCasterTooltip"])
		end
		wndControl:SetTooltipDoc(xml)
	end
end

function CandyUI_Resources:OnStanceMenuOpenerClick( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() and self.db.profile.engineer.bPetBarUnlocked then
		self.wndPetBar:SetStyle("AutoFade", false)
	end
end

function CandyUI_Resources:OnStanceMenuHide( wndHandler, wndControl )
	if self.db.profile.engineer.bPetBarUnlocked then
		self.wndPetBar:SetStyle("AutoFade", true)
	end
end

---------------------------------------------------------------------------------------------------
-- SpellSlingerResourceForm Functions
---------------------------------------------------------------------------------------------------

function CandyUI_Resources:OnBarMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	if wndControl:GetName() == "SpellSlingerResourceForm" then
		self.db.profile.spellslinger.tAnchorOffsets = {wndControl:GetAnchorOffsets()}
	elseif wndControl:GetName() == "EsperResourceForm" then
		self.db.profile.esper.tAnchorOffsets = {wndControl:GetAnchorOffsets()}
	elseif wndControl:GetName() == "MedicResourceForm" then
		self.db.profile.medic.tAnchorOffsets = {wndControl:GetAnchorOffsets()}
	elseif wndControl:GetName() == "EngineerResourceForm" then
		self.db.profile.engineer.tAnchorOffsets = {wndControl:GetAnchorOffsets()}
	elseif wndControl:GetName() == "StalkerResourceForm" then
		self.db.profile.stalker.tAnchorOffsets = {wndControl:GetAnchorOffsets()}
	elseif wndControl:GetName() == "WarriorResourceForm" then
		self.db.profile.warrior.tAnchorOffsets = {wndControl:GetAnchorOffsets()}
	elseif wndControl:GetName() == "SpellslingerChargeForm" then
		self.db.profile.spellslinger.ChargeAnchorOffsets = {wndControl:GetAnchorOffsets()}

	end
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Resources Instance
-----------------------------------------------------------------------------------------------
local CandyUI_ResourcesInst = CandyUI_Resources:new()
CandyUI_ResourcesInst:Init()
