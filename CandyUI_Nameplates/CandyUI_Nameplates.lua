-----------------------------------------------------------------------------------------------
-- Client Lua Script for CandyUI_UnitFrames
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
--DEVELOPER LICENSE
-- CandyUI - Copyright (C) 2014 Neil Smith
-- This work is licensed under the GNU GENERAL PUBLIC LICENSE.
-- A copy of this license is included with this release.
-----------------------------------------------------------------------------------------------
 
require "Window"
require "ChallengesLib"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "Quest"
require "Episode"
require "math"
require "string"
require "DialogSys"
require "PublicEvent"
require "PublicEventObjective"
require "CommunicatorLib"
require "GroupLib"
require "PlayerPathLib"
require "GuildLib"
require "GuildTypeLib"
-----------------------------------------------------------------------------------------------
-- CandyUI_Nameplates Module Definition
-----------------------------------------------------------------------------------------------
local CandyUI_Nameplates = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local karDisposition =
{
	tTextColors =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= ApolloColor.new("DispositionHostile"),
		[Unit.CodeEnumDisposition.Neutral] 	= ApolloColor.new("DispositionNeutral"),
		[Unit.CodeEnumDisposition.Friendly] = ApolloColor.new("DispositionFriendly"),
	},

	tTargetPrimary =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= "CRB_Nameplates:sprNP_BaseSelectedRed",
		[Unit.CodeEnumDisposition.Neutral] 	= "CRB_Nameplates:sprNP_BaseSelectedYellow",
		[Unit.CodeEnumDisposition.Friendly] = "CRB_Nameplates:sprNP_BaseSelectedGreen",
	},

	tTargetSecondary =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= "sprNp_Target_HostileSecondary",
		[Unit.CodeEnumDisposition.Neutral] 	= "sprNp_Target_NeutralSecondary",
		[Unit.CodeEnumDisposition.Friendly] = "sprNp_Target_FriendlySecondary",
	},

	tHealthBar =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= "CRB_Nameplates:sprNP_RedProg",
		[Unit.CodeEnumDisposition.Neutral] 	= "CRB_Nameplates:sprNP_YellowProg",
		[Unit.CodeEnumDisposition.Friendly] = "CRB_Nameplates:sprNP_GreenProg",
	},

	tHealthTextColor =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= "ffff8585",
		[Unit.CodeEnumDisposition.Neutral] 	= "ffffdb57",
		[Unit.CodeEnumDisposition.Friendly] = "ff9bff80",
	},
}

local ktHealthBarSprites =
{
	"sprNp_Health_FillGreen",
	"sprNp_Health_FillOrange",
	"sprNp_Health_FillRed"
}

local karConColors =  -- differential value, color
{
	{-4, ApolloColor.new("ConTrivial")},
	{-3, ApolloColor.new("ConInferior")},
	{-2, ApolloColor.new("ConMinor")},
	{-1, ApolloColor.new("ConEasy")},
	{0, ApolloColor.new("ConAverage")},
	{1, ApolloColor.new("ConModerate")},
	{2, ApolloColor.new("ConTough")},
	{3, ApolloColor.new("ConHard")},
	{4, ApolloColor.new("ConImpossible")}
}

local kcrScalingHex 	= "ffffbf80"
local kcrScalingCColor 	= CColor.new(1.0, 191/255, 128/255, 0.7)

local karPathSprite =
{
	[PlayerPathLib.PlayerPathType_Soldier] 		= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSol",
	[PlayerPathLib.PlayerPathType_Settler] 		= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSet",
	[PlayerPathLib.PlayerPathType_Scientist] 	= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSci",
	[PlayerPathLib.PlayerPathType_Explorer] 	= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathExp",
}

local knCharacterWidth 		= 8 -- the average width of a character in the font used. TODO: Not this.
local knRewardWidth 		= 23 -- the width of a reward icon + padding
local knTextHeight 			= 15 -- text window height
local knNameRewardWidth 	= 400 -- the width of the name/reward container
local knNameRewardHeight 	= 20 -- the width of the name/reward container
local knTargetRange 		= 50000 -- the distance^2 that normal nameplates should draw within (max targeting range)
local knNameplatePoolLimit	= 500 -- the window pool max size

-- Todo: break these out onto options
local kcrUnflaggedGroupmate				= ApolloColor.new("DispositionFriendlyUnflaggedDull")
local kcrUnflaggedGuildmate				= ApolloColor.new("DispositionGuildmateUnflagged")
local kcrUnflaggedAlly					= ApolloColor.new("DispositionFriendlyUnflagged")
local kcrFlaggedAlly					= ApolloColor.new("DispositionFriendly")
local kcrUnflaggedEnemyWhenUnflagged 	= ApolloColor.new("DispositionNeutral")
local kcrFlaggedEnemyWhenUnflagged		= ApolloColor.new("DispositionPvPFlagMismatch")
local kcrUnflaggedEnemyWhenFlagged		= ApolloColor.new("DispositionPvPFlagMismatch")
local kcrFlaggedEnemyWhenFlagged		= ApolloColor.new("DispositionHostile")
local kcrDeadColor 						= ApolloColor.new("crayGray")

local kcrDefaultTaggedColor = ApolloColor.new("crayGray")

local karUnitType = {
	Player = 1,
	NPC = 2,
	Harvest = 3,
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
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CandyUI_Nameplates:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.arPreloadUnits = {}
	o.bAddonRestoredOrLoaded = false

	o.arWindowPool = {}
	o.arUnit2Nameplate = {}
	o.arWnd2Nameplate = {}

	o.bPlayerInCombat = false
	o.guildDisplayed = nil
	o.guildWarParty = nil
	o.bRedrawRewardIcons = false

    return o
end

function CandyUI_Nameplates:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CandyUI_Nameplates OnLoad
-----------------------------------------------------------------------------------------------
function CandyUI_Nameplates:OnLoad()
	self.arPreloadUnits = {}
	Apollo.RegisterEventHandler("UnitCreated", 					"OnPreloadUnitCreated", self)
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CandyUI_Nameplates.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, kcuiNPDefaults)
end

function CandyUI_Nameplates:OnPreloadUnitCreated(unitNew)
	if self.arPreloadUnits == nil then
		self.arPreloadUnits = {}
	end
	self.arPreloadUnits[unitNew:GetId()] = unitNew
end
-----------------------------------------------------------------------------------------------
-- CandyUI_Nameplates OnDocLoaded
-----------------------------------------------------------------------------------------------
function CandyUI_Nameplates:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "CandyUI_NameplatesForm", nil, self)
		
		Apollo.LoadSprites("Sprites.xml")
		
		Apollo.RegisterEventHandler("UnitCreated", 					"OnUnitCreated", self)
		Apollo.RegisterEventHandler("UnitDestroyed", 				"OnUnitDestroyed", self)
		Apollo.RegisterEventHandler("VarChange_FrameCount", 		"OnFrame", self)
	
		Apollo.RegisterEventHandler("UnitTextBubbleCreate", 		"OnUnitTextBubbleToggled", self)
		Apollo.RegisterEventHandler("UnitTextBubblesDestroyed", 	"OnUnitTextBubbleToggled", self)
		Apollo.RegisterEventHandler("TargetUnitChanged", 			"OnTargetUnitChanged", self)
		Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEnteredCombat", self)
		Apollo.RegisterEventHandler("UnitNameChanged", 				"OnUnitNameChanged", self)
		Apollo.RegisterEventHandler("UnitTitleChanged", 			"OnUnitTitleChanged", self)
		Apollo.RegisterEventHandler("PlayerTitleChange", 			"OnPlayerTitleChanged", self)
		Apollo.RegisterEventHandler("UnitGuildNameplateChanged", 	"OnUnitGuildNameplateChanged",self)
		Apollo.RegisterEventHandler("UnitLevelChanged", 			"OnUnitLevelChanged", self)
		Apollo.RegisterEventHandler("UnitMemberOfGuildChange", 		"OnUnitMemberOfGuildChange", self)
		Apollo.RegisterEventHandler("GuildChange", 					"OnGuildChange", self)
		Apollo.RegisterEventHandler("UnitGibbed",					"OnUnitGibbed", self)
		--Apollo.RegisterEventHandler("CandyUI_NameplatesClicked", "OnOptionsHome", self)
		
		self.OptionsAddon = Apollo.GetAddon("CandyUI_Options")
	if self.OptionsAddon ~= nil then
		self.bOptionsLoaded = true
		
		self.wndOptionsMain = self.OptionsAddon.wndOptions
		
		self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControlsList", self.wndOptionsMain:FindChild("OptionsDialogueControls"), self)
		self.wndControls:Show(false, true)
		
		self.bOptionsSet = CUI_RegisterOptions("Nameplates", self.wndControls)
	else	
		self.bOptionsLoaded = false
	end
	--assert(self.wndOptionsMain ~= nil, "\n\n\nOptions Not Loaded\n\n")
	
	
	--local wndCurr = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptionsMain:FindChild("ListControls"), self)
	--wndCurr:SetText("Unit Frames")
	
	
	
	GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
  	self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
	self.colorPicker:Show(false, true)
	--[[
	if not candyUI_Cats then
		candyUI_Cats = {}
	end
	table.insert(candyUI_Cats, "Nameplates")
	self.wndOptionsMain:FindChild("ListControls"):ArrangeChildrenVert()
		]]
	
	--CandyUI_OptionsLoaded
	
	if not self.bOptionsSet or not self.bOptionsLoaded then
		Apollo.RegisterEventHandler("CandyUI_OptionsLoaded", "OnCUIOptionsLoaded", self)
	end
		
	local tRewardUpdateEvents = {
		"QuestObjectiveUpdated", "QuestStateChanged", "ChallengeAbandon", "ChallengeLeftArea",
		"ChallengeFailTime", "ChallengeFailArea", "ChallengeActivate", "ChallengeCompleted",
		"ChallengeFailGeneric", "PublicEventObjectiveUpdate", "PublicEventUnitUpdate",
		"PlayerPathMissionUpdate", "FriendshipAdd", "FriendshipPostRemove", "FriendshipUpdate"
	}
		
		for i, str in pairs(tRewardUpdateEvents) do
			Apollo.RegisterEventHandler(str, "RequestUpdateAllNameplateRewards", self)
		end

		Apollo.RegisterTimerHandler("VisibilityTimer", "OnVisibilityTimer", self)
		Apollo.CreateTimer("VisibilityTimer", 0.5, true)
		
		self.arUnit2Nameplate = {}
		self.arWnd2Nameplate = {}
		self.bUseOcclusion = Apollo.GetConsoleVariable("ui.occludeNameplatePositions")
		
		for key, guildCurr in pairs(GuildLib.GetGuilds()) do
			local eGuildType = guildCurr:GetType()
			if eGuildType == GuildLib.GuildType_Guild then
				self.guildDisplayed = guildCurr
			end
			if eGuildType == GuildLib.GuildType_WarParty then
				self.guildWarParty = guildCurr
			end
		end
		
		-- Cache defaults
		local wndTemp = Apollo.LoadForm(self.xmlDoc, "Nameplate", nil, self)
		self.nFrameLeft, self.nFrameTop, self.nFrameRight, self.nFrameBottom = wndTemp:FindChild("HealthBarNoShield"):GetAnchorOffsets()
		self.nHealthWidth = self.nFrameRight - self.nFrameLeft
		wndTemp:Destroy()
	
		self:CreateUnitsFromPreload()
	end
	
	self:SetOptions()	
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Nameplates Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function CandyUI_Nameplates:OnOptionsHome()
	self.wndOptionsMain:FindChild("ListControls"):DestroyChildren()
	for i, v in ipairs(self.wndControls:GetChildren()) do
		if v:GetName() ~= "Help" then
			local strCategory = v:FindChild("Title"):GetText()
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptionsMain:FindChild("ListControls"), self)
			wndCurr:SetText(strCategory)
		end
	end
	self.wndOptionsMain:FindChild("ListControls"):ArrangeChildrenVert()
	
	self.wndOptionsMain:FindChild("OptionsDialogueControls"):DestroyChildren()
	self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControlsList", self.wndOptionsMain:FindChild("OptionsDialogueControls"), self)
	self:SetOptions()	
end

function CandyUI_Nameplates:OnCUIOptionsLoaded()
	if not self.bOptionsLoaded then
		self.OptionsAddon = Apollo.GetAddon("CandyUI_Options")
		
		self.wndOptionsMain = self.OptionsAddon.wndOptions
		
		self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControlsList", self.wndOptionsMain:FindChild("OptionsDialogueControls"), self)
		self.wndControls:Show(false, true)
		
		self.bOptionsSet = CUI_RegisterOptions("Nameplates", self.wndControls)
	end
	CUI_RegisterOptions("Nameplates", self.wndControls)
	--Print("Resources saw Options load") --debug
end

function CandyUI_Nameplates:OnOptionsHeaderCheck(wndHandler, wndControl, eMouseButton)
	for i, v in ipairs(self.wndControls:GetChildren()) do
		if v:FindChild("Title"):GetText() == wndControl:GetText() then
			v:Show(true)
		else
			v:Show(false)
		end
	end
end

function CandyUI_Nameplates:CreateUnitsFromPreload()
	if true then --self.bAddonRestoredOrLoaded then
		self.unitPlayer = GameLib.GetPlayerUnit()

		-- Process units created while form was loading
		for idUnit, unitNew in pairs(self.arPreloadUnits) do
			self:OnUnitCreated(unitNew)
		end
		self.arPreloadUnits = nil
	end
	self.bAddonRestoredOrLoaded = true
end

function CandyUI_Nameplates:OnVisibilityTimer()
	self:UpdateAllNameplateVisibility()
end

function CandyUI_Nameplates:RequestUpdateAllNameplateRewards()
	self.bRedrawRewardIcons = true
end

function CandyUI_Nameplates:UpdateNameplateRewardInfo(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition
	local strUnitType
	if unitOwner == unitPlayer then
		strUnitType = "Player"
	elseif unitOwner == unitPlayer:GetTarget() then
		strUnitType = "Target"
	elseif eDisposition == Unit.CodeEnumDisposition.Friendly then
		strUnitType = "Friendly"
	elseif eDisposition == Unit.CodeEnumDisposition.Hostile then
		strUnitType = "Enemy"
	elseif eDisposition == Unit.CodeEnumDisposition.Neutral then
		strUnitType = "Neutral"
	elseif eDisposition == Unit.CodeEnumDisposition.Unknown then
		strUnitType = "Other"
	end
	local strUnitTypeLower = string.lower(strUnitType)
	local bHide = (not self.db.profile[strUnitTypeLower].bShowRewards and not unitOwner:IsInCombat()) or (not self.db.profile[strUnitTypeLower].bShowRewardsCombat and unitOwner:IsInCombat())
	local tFlags =
	{
		bVert = false,
		bHideQuests = bHide,
		bHideChallenges = bHide,
		bHideMissions = bHide,
		bHidePublicEvents = bHide,
		bHideRivals = bHide,
		bHideFriends = bHide
	}

	if RewardIcons ~= nil and RewardIcons.GetUnitRewardIconsForm ~= nil then
		RewardIcons.GetUnitRewardIconsForm(tNameplate.wnd.questRewards, tNameplate.unitOwner, tFlags)
	end
end

function CandyUI_Nameplates:UpdateAllNameplateVisibility()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		--Print(tNameplate.unitOwner:GetName())
		self:UpdateNameplateVisibility(tNameplate)
		if self.bRedrawRewardIcons then
			self:UpdateNameplateRewardInfo(tNameplate)
		end
	end

	self.bRedrawRewardIcons = false
end

function CandyUI_Nameplates:UpdateNameplateVisibility(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local wndNameplate = tNameplate.wndNameplate
	local bIsMounted = unitOwner:IsMounted()
	local unitWindow = wndNameplate:GetUnit()

	--if bIsMounted and unitWindow == unitOwner then
	--	wndNameplate:SetUnit(unitOwner:GetUnitMount(), 1)
	--elseif not bIsMounted and unitWindow ~= unitOwner then
		local bReposition = false
		if self.db.profile.general.bAutoPosition and unitOwner ~= self.unitPlayer then
			local locUnitOverhead = unitOwner:GetOverheadAnchor()
			if locUnitOverhead ~= nil then
				bReposition = not tNameplate.bOccluded and locUnitOverhead.y < 45
			end
		end
		wndNameplate:SetUnit(unitOwner, bReposition and 0 or 1)
	--end

	tNameplate.bOnScreen = wndNameplate:IsOnScreen()
	tNameplate.bOccluded = wndNameplate:IsOccluded()
	tNameplate.eDisposition = unitOwner:GetDispositionTo(self.unitPlayer)
	local bNewShow = self:CheckVisibilityOptions(tNameplate) and self:CheckDrawDistance(tNameplate)
	if bNewShow ~= tNameplate.bShow then
		wndNameplate:Show(bNewShow)
		tNameplate.bShow = bNewShow
	end
	
	--scale
	local nScale = wndNameplate:GetScale()
	if tNameplate.bShow and nScale ~= self.db.profile.general.nScale then
		wndNameplate:SetScale(self.db.profile.general.nScale)
	end
end

function CandyUI_Nameplates:OnUnitCreated(unitNew)
	if unitNew == nil
		or not unitNew:IsValid()
		--or not unitNew:ShouldShowNamePlate()
		or unitNew:GetType() == "Collectible"
		or unitNew:GetType() == "PinataLoot" then
		return
	end
	
	local idUnit = unitNew:GetId()
	if self.arUnit2Nameplate[idUnit] ~= nil and self.arUnit2Nameplate[idUnit].wndNameplate:IsValid() then
		return
	end

	local wnd = nil
	local wndReferences = nil
	if next(self.arWindowPool) ~= nil then
		local poolEntry = table.remove(self.arWindowPool)
		wnd = poolEntry[1]
		wndReferences = poolEntry[2]
	end

	if wnd == nil or not wnd:IsValid() then
		wnd = Apollo.LoadForm(self.xmlDoc, "Nameplate", "InWorldHudStratum", self)
		wndReferences = nil
	end

	wnd:Show(false, true)

	wnd:SetUnit(unitNew, 1)

	local tNameplate =
	{
		unitOwner 		= unitNew,
		idUnit 			= idUnit,
		wndNameplate	= wnd,
		bOnScreen 		= wnd:IsOnScreen(),
		bOccluded 		= wnd:IsOccluded(),
		bSpeechBubble 	= false,
		bIsTarget 		= false,
		bIsCluster 		= false,
		bIsCasting 		= false,
		bGibbed			= false,
		bIsGuildMember 	= self.guildDisplayed and self.guildDisplayed:IsUnitMember(unitNew) or false,
		bIsWarPartyMember = self.guildWarParty and self.guildWarParty:IsUnitMember(unitNew) or false,
		nVulnerableTime = 0,
		eDisposition	= unitNew:GetDispositionTo(self.unitPlayer),
		bShow			= false,
		wnd				= wndReferences,
	}
	
	if wndReferences == nil then
		tNameplate.wnd =
		{
			bars = wnd:FindChild("BG"), --Bars, Health, BG, etc
			health = wnd:FindChild("BG:HealthBar:Bar"),
			healthBG = wnd:FindChild("BG:HealthBar"),
			healthNoShield = wnd:FindChild("BG:HealthBarNoShield:Bar"),
			healthNoShieldBG = wnd:FindChild("BG:HealthBarNoShield"),
			shield = wnd:FindChild("BG:ShieldBar:Bar"),
			shieldBG = wnd:FindChild("BG:ShieldBar"),
			absorb = wnd:FindChild("BG:HealthBar:AbsorbBar"),
			absorbNoShield = wnd:FindChild("BG:HealthBarNoShield:AbsorbBar"),
			castBar = wnd:FindChild("CastBar"),
			vulnerable = wnd:FindChild("Vulnerable"),
			level = wnd:FindChild("Level"),
			wndGuild = wnd:FindChild("Guild"),
			wndName = wnd:FindChild("NameRewardContainer:Name"),
			certainDeath = wnd:FindChild("CertainDeath"),
			targetScalingMark = wnd:FindChild("TargetScalingMark"),
			nameRewardContainer = wnd:FindChild("NameRewardContainer:RewardContainer"),
			castBarLabel = wnd:FindChild("CastBar:Label"),
			castBarCastFill = wnd:FindChild("CastBar:CastFill"),
			vulnerableVulnFill = wnd:FindChild("Vulnerable:VulnFill"),
			questRewards = wnd:FindChild("NameRewardContainer:RewardContainer:QuestRewards"),
			targetMarkerArrow = wnd:FindChild("TargetMarkerArrow"),
			--targetMarker = wnd:FindChild("Container:TargetMarker"),
		}
	end
	
	self.arUnit2Nameplate[idUnit] = tNameplate
	self.arWnd2Nameplate[wnd:GetId()] = tNameplate


	self:DrawName(tNameplate)
	self:DrawGuild(tNameplate)
	self:DrawLevel(tNameplate)
	self:UpdateNameplateRewardInfo(tNameplate)
	self:DrawRewards(tNameplate)
end

function CandyUI_Nameplates:OnUnitDestroyed(unitOwner)
	local idUnit = unitOwner:GetId()
	if self.arUnit2Nameplate[idUnit] == nil then
		return
	end

	local tNameplate = self.arUnit2Nameplate[idUnit]
	local wndNameplate = tNameplate.wndNameplate

	self.arWnd2Nameplate[wndNameplate:GetId()] = nil
	if #self.arWindowPool < knNameplatePoolLimit then
		wndNameplate:Show(false, true)
		wndNameplate:SetUnit(nil)
		table.insert(self.arWindowPool, {wndNameplate, tNameplate.wnd})
	else
		wndNameplate:Destroy()
	end
	self.arUnit2Nameplate[idUnit] = nil
end

function CandyUI_Nameplates:OnFrame()
	self.unitPlayer = GameLib.GetPlayerUnit()

	local unitOwner
	local wndNameplate
	local nCon
	local unitWindow

	local fnDrawHealth = CandyUI_Nameplates.DrawHealth
	local fnHelperCalculateConValue = CandyUI_Nameplates.HelperCalculateConValue
	local fnDrawRewards = CandyUI_Nameplates.DrawRewards
	local fnDrawCastBar = CandyUI_Nameplates.DrawCastBar
	local fnDrawVulnerable = CandyUI_Nameplates.DrawVulnerable
	local fnDrawTargeting = CandyUI_Nameplates.DrawTargeting
	local fnColorNameplate = CandyUI_Nameplates.ColorNameplate

	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		if tNameplate.bShow then
			unitOwner = tNameplate.unitOwner
			wndNameplate = tNameplate.wndNameplate
			unitWindow = wndNameplate:GetUnit()

			fnDrawHealth(self, tNameplate)

			nCon = fnHelperCalculateConValue(self, unitOwner)
			tNameplate.wnd.certainDeath:Show(nCon == #karConColors and tNameplate.eDisposition ~= Unit.CodeEnumDisposition.Friendly and unitOwner:GetHealth() and unitOwner:ShouldShowNamePlate() and not unitOwner:IsDead()) -- replace with option --self.db.profile.individual.bShowCertainDeath and nCon == #karConColors and tNameplate.eDisposition ~= Unit.CodeEnumDisposition.Friendly and unitOwner:GetHealth() and unitOwner:ShouldShowNamePlate() and not unitOwner:IsDead())
			tNameplate.wnd.targetScalingMark:Show(unitOwner:IsScaled())

			fnDrawRewards(self, tNameplate)
			fnDrawCastBar(self, tNameplate)
			fnDrawVulnerable(self, tNameplate)
			fnDrawTargeting(self, tNameplate)
			fnColorNameplate(self, tNameplate)
		end
	end
end

function CandyUI_Nameplates:ColorNameplate(tNameplate)
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local wndNameplate = tNameplate.wndNameplate

	local eDisposition = tNameplate.eDisposition
	local nCon = self:HelperCalculateConValue(unitOwner)

	local crLevelColorToUse = karConColors[nCon][2]
	if tNameplate.wnd.targetScalingMark:IsShown() then
		crLevelColorToUse = kcrScalingCColor
	elseif unitOwner:GetLevel() == nil then
		crLevelColorToUse = karConColors[1][2]
	end

	local crColorToUse = karDisposition.tTextColors[eDisposition]
	local unitController = unitOwner:GetUnitOwner() or unitOwner
	local strUnitType = unitOwner:GetType()

	if strUnitType == "Player" or strUnitType == "Pet" or strUnitType == "Esper Pet" then
		if eDisposition == Unit.CodeEnumDisposition.Friendly or unitOwner:IsThePlayer() then
			crColorToUse = kcrUnflaggedAlly
			if unitController:IsPvpFlagged() then
				crColorToUse = kcrFlaggedAlly
			elseif unitController:IsInYourGroup() then
				crColorToUse = kcrUnflaggedGroupmate
			elseif tNameplate.bIsGuildMember then
				crColorToUse = kcrUnflaggedGuildmate
			end
		else
			local bIsUnitFlagged = unitController:IsPvpFlagged()
			local bAmIFlagged = GameLib.IsPvpFlagged()

			if not bAmIFlagged and not bIsUnitFlagged then
				crColorToUse = kcrUnflaggedEnemyWhenUnflagged
			elseif bAmIFlagged and not bIsUnitFlagged then
				crColorToUse = kcrUnflaggedEnemyWhenFlagged
			elseif not bAmIFlagged and bIsUnitFlagged then
				crColorToUse = kcrFlaggedEnemyWhenUnflagged
			elseif bAmIFlagged and bIsUnitFlagged then
				crColorToUse = kcrFlaggedEnemyWhenFlagged
			end
		end
	end

	if unitOwner:GetType() ~= "Player" and unitOwner:IsTagged() and not unitOwner:IsTaggedByMe() and not unitOwner:IsSoftKill() then
		crColorToUse = kcrDefaultTaggedColor
	end

	if unitOwner:IsDead() then
		crColorToUse = kcrDeadColor
		crLevelColorToUse = kcrDeadColor
	end

	tNameplate.wnd.level:SetTextColor(crLevelColorToUse)
	tNameplate.wnd.wndName:SetTextColor(crColorToUse)
	tNameplate.wnd.wndGuild:SetTextColor(crColorToUse)
end

function CandyUI_Nameplates:DrawName(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition
	local strUnitType
	
	if unitOwner == unitPlayer then
		strUnitType = "Player"
	elseif unitOwner == unitPlayer:GetTarget() then
		strUnitType = "Target"
	elseif eDisposition == Unit.CodeEnumDisposition.Friendly then
		strUnitType = "Friendly"
	elseif eDisposition == Unit.CodeEnumDisposition.Hostile then
		strUnitType = "Enemy"
	elseif eDisposition == Unit.CodeEnumDisposition.Neutral then
		strUnitType = "Neutral"
	elseif eDisposition == Unit.CodeEnumDisposition.Unknown then
		strUnitType = "Other"
	end
	local strUnitTypeLower = string.lower(strUnitType)
	local wndName = tNameplate.wnd.wndName
	local bUseTarget = tNameplate.bIsTarget
	local bShow = (not unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowName) or (unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowNameCombat)
	local bShowGuild = (not unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowGuildTitle) or (unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowGuildTitleCombat)
	--if bUseTarget then
	--	bShow = self.db.profile.target.bShowName
	--end

	if wndName:IsShown() ~= bShow then
		wndName:Show(bShow)
	end

	if bShow then
		local strNewName
		
		if true then --bShowGuild
			strNewName =  unitOwner:GetTitleOrName()
		else
			strNewName =  unitOwner:GetName()
		end
		--This is to show level with the name [broken]
		--if tNameplate.wnd.bars:IsVisible() == false and unitOwner:GetLevel() then
		--	strNewName = strNewName.." ["..unitOwner:GetLevel().."]"
			--wndName:SetText(strNewName)
		--end
		if wndName:GetText() ~= strNewName then
			
			wndName:SetText(strNewName)--.." = "..tostring(unitOwner:GetType()))

			-- Need to consider guild as well for the resize code
			local strNewGuild = unitOwner:GetAffiliationName()
			if unitOwner:GetType() == "Player" and strNewGuild ~= nil and strNewGuild ~= "" then
				strNewGuild = String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), strNewGuild)
			end
			
			-- Resize
			local wndNameplate = tNameplate.wndNameplate
			local nLeft, nTop, nRight, nBottom = wndName:GetAnchorOffsets()
			local nHalfNameWidth = math.ceil(math.max(Apollo.GetTextWidth("Nameplates", strNewName), Apollo.GetTextWidth("CRB_Interface9_BO", strNewGuild)) / 2)
			nHalfNameWidth = math.max(nHalfNameWidth, self.nHealthWidth / 2)
			wndName:SetAnchorOffsets(-nHalfNameWidth - 15, nTop, nHalfNameWidth + tNameplate.wnd.nameRewardContainer:ArrangeChildrenHorz(0) + 15, nBottom)
		end
	end
end

function CandyUI_Nameplates:DrawGuild(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition
	local strUnitType
	if unitOwner == unitPlayer then
		strUnitType = "Player"
	elseif unitOwner == unitPlayer:GetTarget() then
		strUnitType = "Target"
	elseif eDisposition == Unit.CodeEnumDisposition.Friendly then
		strUnitType = "Friendly"
	elseif eDisposition == Unit.CodeEnumDisposition.Hostile then
		strUnitType = "Enemy"
	elseif eDisposition == Unit.CodeEnumDisposition.Neutral then
		strUnitType = "Neutral"
	elseif eDisposition == Unit.CodeEnumDisposition.Unknown then
		strUnitType = "Other"
	end
	local strUnitTypeLower = string.lower(strUnitType)
	local wndGuild = tNameplate.wnd.wndGuild
	local bUseTarget = tNameplate.bIsTarget
	local bShow = (not unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowGuildTitle) or (unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowGuildTitleCombat)

	local strNewGuild = unitOwner:GetAffiliationName()
	if unitOwner:GetType() == "Player" and strNewGuild ~= nil and strNewGuild ~= "" then
		strNewGuild = String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), strNewGuild)
	end

	if bShow and strNewGuild ~= wndGuild:GetText() then
		wndGuild:SetTextRaw(strNewGuild)

		-- Need to consider name as well for the resize code
		local strNewName
		if bShow then
			strNewName = unitOwner:GetTitleOrName()
		else
			strNewName = unitOwner:GetName()
		end

		-- Resize
		local nLeft, nTop, nRight, nBottom = wndGuild:GetAnchorOffsets()
		local nHalfNameWidth = math.ceil(math.max(Apollo.GetTextWidth("Nameplates", strNewName), Apollo.GetTextWidth("CRB_Interface9_BO", strNewGuild)) / 2)
		nHalfNameWidth = math.max(nHalfNameWidth, self.nHealthWidth / 2)
		wndGuild:SetAnchorOffsets(-nHalfNameWidth - 15, nTop, nHalfNameWidth + tNameplate.wnd.nameRewardContainer:ArrangeChildrenHorz(0) + 15, nBottom)
	end

	wndGuild:Show(bShow and strNewGuild ~= nil and strNewGuild ~= "")
	--wndNameplate:ArrangeChildrenVert(2) -- Must be run if bShow is false as well
end

function CandyUI_Nameplates:DrawLevel(tNameplate)
	local unitOwner = tNameplate.unitOwner
	
	tNameplate.wnd.level:SetText(unitOwner:GetLevel() or "")
	
end

function CandyUI_Nameplates:DrawHealth(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition
	local strUnitType
	if unitOwner == unitPlayer then
		strUnitType = "Player"
	elseif unitOwner == unitPlayer:GetTarget() then
		strUnitType = "Target"
	elseif eDisposition == Unit.CodeEnumDisposition.Friendly then
		strUnitType = "Friendly"
	elseif eDisposition == Unit.CodeEnumDisposition.Hostile then
		strUnitType = "Enemy"
	elseif eDisposition == Unit.CodeEnumDisposition.Neutral then
		strUnitType = "Neutral"
	elseif eDisposition == Unit.CodeEnumDisposition.Unknown then
		strUnitType = "Other"
	end
	local strUnitTypeLower = string.lower(strUnitType)
	local bShow = (not unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowHealthShield) or (unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowHealthShield)
	local bShowDamaged = self.db.profile[strUnitTypeLower].bOnlyDamaged
	
	local wndHealth = tNameplate.wnd.health
	local wndHealthBG = tNameplate.wnd.healthBG
	local wndHealthNoShield = tNameplate.wnd.healthNoShield
	local wndHealthNoShieldBG = tNameplate.wnd.healthNoShieldBG
	local wndShield = tNameplate.wnd.shield
	local wndShieldBG = tNameplate.wnd.shieldBG
	local wndAbsorb = tNameplate.wnd.absorb
	local wndAbsorbNoShield = tNameplate.wnd.absorbNoShield
	local wndBars = tNameplate.wnd.bars
	
	local wndHealthText
	
	if unitOwner:GetHealth() == nil or unitOwner:IsDead() then
		wndBars:Show(false)
		return
	end
	
	local bHasShield = false
	local nShieldMax = unitOwner:GetShieldCapacityMax()
	if nShieldMax ~= nil and nShieldMax > 0 then
		bHasShield = true
	end
	
	local wndHealthUpdate
	if bHasShield then
		wndHealthUpdate = wndHealth
		wndHealthText = wndHealth:FindChild("Label")
		
		--wndHealth:Show(true, true)
		wndHealthBG:Show(true, true)
		--wndShield:Show(true, true)
		wndShieldBG:Show(true, true)
		--wndHealthNoShield:Show(false, true)
		wndHealthNoShieldBG:Show(false, true)
		wndHealthBG:SetBGColor(self.db.profile[strUnitTypeLower].crHealthBarColor)
	else
		wndHealthUpdate = wndHealthNoShield
		wndHealthText = wndHealthNoShield:FindChild("Label")

		--wndHealth:Show(false, true)
		wndHealthBG:Show(false, true)
		--wndShield:Show(false, true)
		wndShieldBG:Show(false, true)
		--wndHealthNoShield:Show(true, true)
		wndHealthNoShieldBG:Show(true, true)
		wndHealthNoShieldBG:SetBGColor(self.db.profile[strUnitTypeLower].crHealthBarColor)
	end
	
	self:SetBarValue(wndHealthUpdate, 0, unitOwner:GetHealth(), unitOwner:GetMaxHealth())
	wndHealthUpdate:SetBarColor(self.db.profile[strUnitTypeLower].crHealthBarColor)
	if bHasShield then
		self:SetBarValue(wndShield, 0, unitOwner:GetShieldCapacity(), unitOwner:GetShieldCapacityMax())
		wndShield:SetBarColor(self.db.profile[strUnitTypeLower].crShieldBarColor)
		wndShieldBG:SetBGColor(self.db.profile[strUnitTypeLower].crShieldBarColor)
	end
	
	if false then
		wndBars:Show(self.db.profile.target.bShowHealth)
	else
		if bShowDamaged then
			wndBars:Show(unitOwner:GetHealth() ~= unitOwner:GetMaxHealth())
			tNameplate.wnd.level:Show(unitOwner:GetHealth() ~= unitOwner:GetMaxHealth())
		elseif bShow then
			wndBars:Show(true)
			tNameplate.wnd.level:Show(true)
		else
			wndBars:Show(false)
			tNameplate.wnd.level:Show(false)
		end
	end
	
	if wndBars:IsShown() then
		self:HelperDoHealthShieldBar(wndHealthUpdate, unitOwner, tNameplate.eDisposition, tNameplate)
	end
	
end

function CandyUI_Nameplates:DrawCastBar(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition
	local strUnitType
	if unitOwner == unitPlayer then
		strUnitType = "Player"
	elseif unitOwner == unitPlayer:GetTarget() then
		strUnitType = "Target"
	elseif eDisposition == Unit.CodeEnumDisposition.Friendly then
		strUnitType = "Friendly"
	elseif eDisposition == Unit.CodeEnumDisposition.Hostile then
		strUnitType = "Enemy"
	elseif eDisposition == Unit.CodeEnumDisposition.Neutral then
		strUnitType = "Neutral"
	elseif eDisposition == Unit.CodeEnumDisposition.Unknown then
		strUnitType = "Other"
	end
	local strUnitTypeLower = string.lower(strUnitType)

	-- Casting; has some onDraw parameters we need to check
	tNameplate.bIsCasting = unitOwner:ShouldShowCastBar()

	local bShowTarget = tNameplate.bIsTarget
	local wndCastBar = tNameplate.wnd.castBar
	local bShow = (not unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowCastBar) or (unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowCastBar)
	--if tNameplate.bIsCasting and bShowTarget then
	--	bShow = true
	--end

	wndCastBar:Show(tNameplate.bIsCasting and bShow)
	if bShow then
		tNameplate.wnd.castBarLabel:SetText(unitOwner:GetCastName())
		tNameplate.wnd.castBarCastFill:SetMax(unitOwner:GetCastDuration())
		tNameplate.wnd.castBarCastFill:SetProgress(unitOwner:GetCastElapsed())
	end
end

function CandyUI_Nameplates:DrawVulnerable(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition
	local strUnitType
	if unitOwner == unitPlayer then
		strUnitType = "Player"
	elseif unitOwner == unitPlayer:GetTarget() then
		strUnitType = "Target"
	elseif eDisposition == Unit.CodeEnumDisposition.Friendly then
		strUnitType = "Friendly"
	elseif eDisposition == Unit.CodeEnumDisposition.Hostile then
		strUnitType = "Enemy"
	elseif eDisposition == Unit.CodeEnumDisposition.Neutral then
		strUnitType = "Neutral"
	elseif eDisposition == Unit.CodeEnumDisposition.Unknown then
		strUnitType = "Other"
	end
	local strUnitTypeLower = string.lower(strUnitType)
	
	local bShowHealth = (not unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowHealthShield) or (unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowHealthShieldCombat)
	local bShowDamaged = self.db.profile[strUnitTypeLower].bOnlyDamaged
	
	local bUseTarget = tNameplate.bIsTarget
	local wndVulnerable = tNameplate.wnd.vulnerable

	local bIsVulnerable = false
	if bShowHealth or bShowDamaged then
		local nVulnerable = unitOwner:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)
		if nVulnerable == nil then
			wndVulnerable:Show(false)
		elseif nVulnerable == 0 and nVulnerable ~= tNameplate.nVulnerableTime then
			tNameplate.nVulnerableTime = 0 -- casting done, set back to 0
			wndVulnerable:Show(false)
		elseif nVulnerable ~= 0 and nVulnerable > tNameplate.nVulnerableTime then
			tNameplate.nVulnerableTime = nVulnerable
			wndVulnerable:Show(true)
			bIsVulnerable = true
		elseif nVulnerable ~= 0 and nVulnerable < tNameplate.nVulnerableTime then
			tNameplate.wnd.vulnerableVulnFill:SetMax(tNameplate.nVulnerableTime)
			tNameplate.wnd.vulnerableVulnFill:SetProgress(nVulnerable)
			bIsVulnerable = true
		end
	end
end

function CandyUI_Nameplates:DrawRewards(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition
	local strUnitType
	if unitOwner == unitPlayer then
		strUnitType = "Player"
	elseif unitOwner == unitPlayer:GetTarget() then
		strUnitType = "Target"
	elseif eDisposition == Unit.CodeEnumDisposition.Friendly then
		strUnitType = "Friendly"
	elseif eDisposition == Unit.CodeEnumDisposition.Hostile then
		strUnitType = "Enemy"
	elseif eDisposition == Unit.CodeEnumDisposition.Neutral then
		strUnitType = "Neutral"
	elseif eDisposition == Unit.CodeEnumDisposition.Unknown then
		strUnitType = "Other"
	end
	local strUnitTypeLower = string.lower(strUnitType)

	local bUseTarget = tNameplate.bIsTarget
	local bShow = (not unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowRewards) or (unitOwner:IsInCombat() and self.db.profile[strUnitTypeLower].bShowRewardsCombat)

	tNameplate.wnd.questRewards:Show(bShow)
	local tRewardsData = tNameplate.wnd.questRewards:GetData()
	if bShow and tRewardsData ~= nil and tRewardsData.nIcons ~= nil and tRewardsData.nIcons > 0 then
		local strName = tNameplate.wnd.wndName:GetText()
		local nNameWidth = Apollo.GetTextWidth("CRB_Interface9_BBO", strName)
		local nHalfNameWidth = nNameWidth / 2

		local wndnameRewardContainer = tNameplate.wnd.nameRewardContainer
		local nLeft, nTop, nRight, nBottom = wndnameRewardContainer:GetAnchorOffsets()
		wndnameRewardContainer:SetAnchorOffsets(nHalfNameWidth, nTop, nHalfNameWidth + wndnameRewardContainer:ArrangeChildrenHorz(0), nBottom)
	end
end

function CandyUI_Nameplates:DrawTargeting(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local bUseTarget = tNameplate.bIsTarget and unitOwner ~= self.unitPlayer and unitOwner == GameLib.GetTargetUnit()

	local bShowTargetMarkerArrow = bUseTarget and ((not unitOwner:IsInCombat() and self.db.profile.target.bShowTargetMarker) or (unitOwner:IsInCombat() and self.db.profile.target.bShowTargetMarkerCombat))
	
	--tNameplate.wnd.targetMarkerArrow:SetSprite(karDisposition.tTargetSecondary[tNameplate.eDisposition])
	--tNameplate.wnd.targetMarker:SetSprite(karDisposition.tTargetPrimary[tNameplate.eDisposition])

	if tNameplate.nVulnerableTime > 0 then
		--tNameplate.wnd.targetMarker:SetSprite("sprNP_BaseSelectedPurple")
	end

	--local bShowTargetMarker = bUseTarget and self.db.profile.target.bShowMarkerTarget and tNameplate.wnd.health:IsShown()
	--if tNameplate.wnd.targetMarker:IsShown() ~= bShowTargetMarker then
	--	tNameplate.wnd.targetMarker:Show(bShowTargetMarker)
	--end
	if tNameplate.wnd.targetMarkerArrow:IsShown() ~= bShowTargetMarkerArrow then
		tNameplate.wnd.targetMarkerArrow:Show(bShowTargetMarkerArrow, not bShowTargetMarkerArrow)
	end
end

function CandyUI_Nameplates:CheckDrawDistance(tNameplate)
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner

	if not unitOwner or not unitPlayer then
	    return false
	end

	local tPosTarget = unitOwner:GetPosition()
	local tPosPlayer = unitPlayer:GetPosition()

	if tPosTarget == nil or tPosPlayer == nil then
		return
	end

	local nDeltaX = tPosTarget.x - tPosPlayer.x
	local nDeltaY = tPosTarget.y - tPosPlayer.y
	local nDeltaZ = tPosTarget.z - tPosPlayer.z

	local nDistance = (nDeltaX * nDeltaX) + (nDeltaY * nDeltaY) + (nDeltaZ * nDeltaZ)

	if tNameplate.bIsTarget or tNameplate.bIsCluster then
		bInRange = nDistance < knTargetRange
		return bInRange
	else
		bInRange = nDistance < (self.db.profile.general.nViewDistance * self.db.profile.general.nViewDistance)
		return bInRange
	end
end

function CandyUI_Nameplates:GetUnitType(unitOwner)
	local strUnitType
	if unitOwner == self.unitPlayer then
		strUnitType = "Player"
	elseif unitOwner == self.unitPlayer:GetTarget() then
		strUnitType = "Target"
	elseif unitOwner:GetType() == "Harvest" then
		strUnitType = "Harvest"
	else
		return nil
	end
	
	return strUnitType, string.lower(strUnitType)
end

function CandyUI_Nameplates:GetDispString(eDisposition)
	local strUnitType
	if eDisposition == Unit.CodeEnumDisposition.Friendly then
		strUnitType = "Friendly"
	elseif eDisposition == Unit.CodeEnumDisposition.Hostile then
		strUnitType = "Enemy"
	elseif eDisposition == Unit.CodeEnumDisposition.Neutral then
		strUnitType = "Neutral"
	elseif eDisposition == Unit.CodeEnumDisposition.Unknown then
		strUnitType = "Other"
	end
	local strUnitTypeLower = string.lower(strUnitType)
	return strUnitType, strUnitTypeLower
end

function CandyUI_Nameplates:CheckVisibilityOptions(tNameplate)
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition
	local strDisp, strDispLower = self:GetDispString(eDisposition)
	local strUnitType, strUnitTypeLower = self:GetUnitType(unitOwner)
	local strUnit, strUnitLower
	
	--if true then return true end
	--[[
	local bHiddenUnit = not unitOwner:ShouldShowNamePlate()
	if bHiddenUnit and not tNameplate.bIsTarget then
		return false
	end
	]]
	if unitOwner:GetType() == "Mount" then
		return false
	end
	
	if (self.bUseOcclusion and tNameplate.bOccluded) then
		return false
	end
	if not tNameplate.bOnScreen then
		return false
	end
	if tNameplate.bGibbed or (tNameplate.bSpeechBubble and self.db.profile.general.bHideSpeech) then
		return false
	end
	
	if unitOwner:GetType() == "Harvest" and unitOwner:CanBeHarvestedBy(self.unitPlayer) and self.db.profile.neutral.bShowHarvestNodes then
		return true
	end
	
	if strUnitType then
		strUnit = strUnitType
		strUnitLower = strUnitTypeLower
	else
		strUnit = strDisp
		strUnitLower = strDispLower
	end
	
	local bShowNameplate = false
	
	if self.db.profile[strUnitLower] and self.db.profile[strUnitLower].bShow then
		local tActivation = unitOwner:GetActivationState()
		bShowNameplate = true
		
		
		if unitOwner:GetType() == "Simple" and self.db.profile.general.bShowSimple == false then
			bShowNameplate = false
		elseif unitOwner:GetType() == "NonPlayer" and self.db.profile[strUnitLower].bShowNPCS == false then
			bShowNameplate = false
		elseif unitOwner:GetType() == "Player" and self.db.profile[strUnitLower].bShowPlayers == false then
			bShowNameplate = false
		elseif tNameplate.bIsGuildMember and self.db.profile[strUnitLower].bShowGuild == false then
			bShowNameplate = false
		elseif unitOwner:IsInYourGroup() and self.db.profile[strUnitLower].bShowGroup == false then
			bShowNameplate = false	
		end
		
		if tActivation.Vendor ~= nil and self.db.profile[strUnitLower].bShowVendors then
			bShowNameplate = true
		end
		
		if self.db.profile.general.bShowQuestItems then
			if tNameplate.bIsObjective then
				bShowNameplate = true
			end
		
			if tActivation.QuestReward ~= nil then
				bShowNameplate = true
			end

			if tActivation.QuestNew ~= nil or tActivation.QuestNewMain ~= nil then
				bShowNameplate = true
			end

			if tActivation.QuestReceiving ~= nil then
				bShowNameplate = true
			end
			if tActivation.TalkTo ~= nil then
				bShowNameplate = true
			end
		end
		
		if tActivation.Interact and tActivation.Interact.bShowOverhead ~= nil then
			bShowNameplate = true
		end
	end

	if unitOwner:IsThePlayer() then
		if not unitOwner:IsDead() then
			bShowNameplate = true
		else
			bShowNameplate = false
		end
	end

	return bShowNameplate
end

function CandyUI_Nameplates:HelperDoHealthShieldBar(wndHealthUpdate, unitOwner, eDisposition, tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition
	local strUnitType
	if unitOwner == unitPlayer then
		strUnitType = "Player"
	elseif unitOwner == unitPlayer:GetTarget() then
		strUnitType = "Target"
	elseif eDisposition == Unit.CodeEnumDisposition.Friendly then
		strUnitType = "Friendly"
	elseif eDisposition == Unit.CodeEnumDisposition.Hostile then
		strUnitType = "Enemy"
	elseif eDisposition == Unit.CodeEnumDisposition.Neutral then
		strUnitType = "Neutral"
	elseif eDisposition == Unit.CodeEnumDisposition.Unknown then
		strUnitType = "Other"
	end
	local strUnitTypeLower = string.lower(strUnitType)
	
	local wndHealth = wndHealthUpdate
	local wndHealthBG = wndHealthUpdate:GetParent()
	--local wndHealthNoShield = tNameplate.wnd.healthNoShield
	--local wndHealthNoShieldBG = tNameplate.wnd.healthNoShieldBG
	local wndShield = tNameplate.wnd.shield
	local wndShieldBG = tNameplate.wnd.shieldBG
	local wndAbsorb = wndHealthUpdate:GetParent():FindChild("AbsorbBar")
	--local wndAbsorbNoShield = tNameplate.wnd.absorbNoShield
	local wndBars = tNameplate.wnd.bars
	------------------------------------------------------------
	
	local nVulnerabilityTime = unitOwner:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)

	if unitOwner:GetType() == "Simple" or unitOwner:GetHealth() == nil then
		--tNameplate.wnd.healthMaxHealth:SetAnchorOffsets(self.nFrameLeft, self.nFrameTop, self.nFrameRight, self.nFrameBottom)
		--tNameplate.wnd.healthHealthLabel:SetText("")
		wndBars:Show(false)
		return
	end

	local nHealthCurr 	= unitOwner:GetHealth()
	local nHealthMax 	= unitOwner:GetMaxHealth()
	local nHealthPerc	= round((nHealthCurr / nHealthMax) * 100)
	local nShieldCurr 	= unitOwner:GetShieldCapacity()
	local nShieldMax 	= unitOwner:GetShieldCapacityMax()
	local nAbsorbCurr 	= 0
	local nAbsorbMax 	= unitOwner:GetAbsorptionMax()
	if nAbsorbMax > 0 then
		nAbsorbCurr = unitOwner:GetAbsorptionValue() -- Since it doesn't clear when the buff drops off
	end
	--local nTotalMax = nHealthMax + nShieldMax + nAbsorbMax

	if unitOwner:IsDead() then
		nHealthCurr = 0
	end
	
	--Health color
	if nHealthPerc > self.db.profile.general.nHealthThresholdHigh then
		wndHealth:SetBarColor(self.db.profile[strUnitTypeLower].crHealthBarColorHigh)
		wndHealthBG:SetBGColor(self.db.profile[strUnitTypeLower].crHealthBarColorHigh)
	elseif nHealthPerc > self.db.profile.general.nHealthThresholdLow then
		wndHealth:SetBarColor(self.db.profile[strUnitTypeLower].crHealthBarColorMid)
		wndHealthBG:SetBGColor(self.db.profile[strUnitTypeLower].crHealthBarColorMid)
	else
		wndHealth:SetBarColor(self.db.profile[strUnitTypeLower].crHealthBarColorLow)
		wndHealthBG:SetBGColor(self.db.profile[strUnitTypeLower].crHealthBarColorLow)
	end
	
	--Show / Hide Absorb !!!!!!!!!!!!!
	wndAbsorb:Show(nHealthCurr > 0 and nAbsorbMax > 0)

	-- Text
	local strHealthMax = self:HelperFormatBigNumber(nHealthMax)
	local strHealthCurr = self:HelperFormatBigNumber(nHealthCurr)
	local strShieldCurr = self:HelperFormatBigNumber(nShieldCurr)

	local strText = nHealthMax == nHealthCurr and strHealthMax or String_GetWeaselString(Apollo.GetString("TargetFrame_HealthText"), strHealthCurr, strHealthMax)
	if nShieldMax > 0 and nShieldCurr > 0 then
		strText = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthShieldText"), strText, strShieldCurr)
	end
	if self.db.profile[strUnitTypeLower].bShowHealthText then
		wndHealthUpdate:FindChild("Label"):SetText(strText)
	else
		wndHealthUpdate:FindChild("Label"):SetText("")
	end
	
	--[[
	--%%%%%%%%%%%%%SAVE THIS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--Maybe could use this idea of switching sprites, or better yet, colors depending on stuff like health, vuln, cast, poison etc 
	--============================================================
	-- Sprite
	if nVulnerabilityTime and nVulnerabilityTime > 0 then
		tNameplate.wnd.healthMaxHealth:SetSprite("CRB_Nameplates:sprNP_PurpleProg")
	else
		tNameplate.wnd.healthMaxHealth:SetSprite(karDisposition.tHealthBar[eDisposition])
	end
	]]
	--[[
	elseif nHealthCurr / nHealthMax < .3 then
		wndHealth:FindChild("MaxHealth"):SetSprite(ktHealthBarSprites[3])
	elseif 	nHealthCurr / nHealthMax < .5 then
		wndHealth:FindChild("MaxHealth"):SetSprite(ktHealthBarSprites[2])
	else
		wndHealth:FindChild("MaxHealth"):SetSprite(ktHealthBarSprites[1])
	end]]--
end

function CandyUI_Nameplates:HelperFormatBigNumber(nArg)
	if nArg < 1000 then
		strResult = tostring(nArg)
	elseif nArg < 1000000 then
		if math.floor(nArg%1000/100) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberWhole"), math.floor(nArg / 1000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberFloat"), nArg / 1000)
		end
	elseif nArg < 1000000000 then
		if math.floor(nArg%1000000/100000) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_MillionsNumberWhole"), math.floor(nArg / 1000000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_MillionsNumberFloat"), nArg / 1000000)
		end
	elseif nArg < 1000000000000 then
		if math.floor(nArg%1000000/100000) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_BillionsNumberWhole"), math.floor(nArg / 1000000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_BillionsNumberFloat"), nArg / 1000000)
		end
	else
		strResult = tostring(nArg)
	end
	return strResult
end

function CandyUI_Nameplates:SetBarValue(wndBar, fMin, fValue, fMax)
	wndBar:SetMax(fMax)
	wndBar:SetFloor(fMin)
	wndBar:SetProgress(fValue)
end

function CandyUI_Nameplates:HelperCalculateConValue(unitTarget)
	if unitTarget == nil or self.unitPlayer == nil then
		return 1
	end

	local nUnitCon = self.unitPlayer:GetLevelDifferential(unitTarget)

	local nCon = 1 --default setting

	if nUnitCon <= karConColors[1][1] then -- lower bound
		nCon = 1
	elseif nUnitCon >= karConColors[#karConColors][1] then -- upper bound
		nCon = #karConColors
	else
		for idx = 2, (#karConColors - 1) do -- everything in between
			if nUnitCon == karConColors[idx][1] then
				nCon = idx
			end
		end
	end

	return nCon
end

-----------------------------------------------------------------------------------------------
-- Nameplate Events
-----------------------------------------------------------------------------------------------

function CandyUI_Nameplates:OnNameplateNameClick(wndHandler, wndCtrl, eMouseButton)
	local tNameplate = self.arWnd2Nameplate[wndHandler:GetId()]
	if tNameplate == nil then
		return
	end

	local unitOwner = tNameplate.unitOwner
	if GameLib.GetTargetUnit() ~= unitOwner and eMouseButton == GameLib.CodeEnumInputMouse.Left then
		GameLib.SetTargetUnit(unitOwner)
	end
end

function CandyUI_Nameplates:OnWorldLocationOnScreen(wndHandler, wndControl, bOnScreen)
	local tNameplate = self.arWnd2Nameplate[wndHandler:GetId()]
	if tNameplate ~= nil then
		tNameplate.bOnScreen = bOnScreen
		self:UpdateNameplateVisibility(tNameplate)
	end
end

function CandyUI_Nameplates:OnUnitOcclusionChanged(wndHandler, wndControl, bOccluded)
	local tNameplate = self.arWnd2Nameplate[wndHandler:GetId()]
	if tNameplate ~= nil then
		tNameplate.bOccluded = bOccluded
		self:UpdateNameplateVisibility(tNameplate)
	end
end

-----------------------------------------------------------------------------------------------
-- System Events
-----------------------------------------------------------------------------------------------

function CandyUI_Nameplates:OnUnitTextBubbleToggled(tUnitArg, strText, nRange)
	local tNameplate = self.arUnit2Nameplate[tUnitArg:GetId()]
	if tNameplate ~= nil then
		tNameplate.bSpeechBubble = strText ~= nil and strText ~= ""
		self:UpdateNameplateVisibility(tNameplate)
	end
end

function CandyUI_Nameplates:OnEnteredCombat(unitChecked, bInCombat)
	if unitChecked == self.unitPlayer then
		self.bPlayerInCombat = bInCombat
	end
	
	self:RefreshTexts()
end

function CandyUI_Nameplates:OnUnitGibbed(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		tNameplate.bGibbed = true
		self:UpdateNameplateVisibility(tNameplate)
	end
end

function CandyUI_Nameplates:OnUnitNameChanged(unitUpdated, strNewName)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		self:DrawName(tNameplate)
	end
end

function CandyUI_Nameplates:OnUnitTitleChanged(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		self:DrawName(tNameplate)
	end
end

function CandyUI_Nameplates:OnPlayerTitleChanged()
	local tNameplate = self.arUnit2Nameplate[self.unitPlayer:GetId()]
	if tNameplate ~= nil then
		self:DrawName(tNameplate)
	end
end

function CandyUI_Nameplates:OnUnitLevelChanged(unitUpdating)
	local tNameplate = self.arUnit2Nameplate[unitUpdating:GetId()]
	if tNameplate ~= nil then
		self:DrawLevel(tNameplate)
	end
end

function CandyUI_Nameplates:OnGuildChange()
	self.guildDisplayed = nil
	self.guildWarParty = nil
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		local eGuildType = guildCurr:GetType()
		if eGuildType == GuildLib.GuildType_Guild then
			self.guildDisplayed = guildCurr
		end
		if eGuildType == GuildLib.GuildType_WarParty then
			self.guildWarParty = guildCurr
		end
	end

	for key, tNameplate in pairs(self.arUnit2Nameplate) do
		local unitOwner = tNameplate.unitOwner
		tNameplate.bIsGuildMember = self.guildDisplayed and self.guildDisplayed:IsUnitMember(unitOwner) or false
		tNameplate.bIsWarPartyMember = self.guildWarParty and self.guildWarParty:IsUnitMember(unitOwner) or false
	end
end

function CandyUI_Nameplates:OnUnitGuildNameplateChanged(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		self:DrawGuild(tNameplate)
	end
end

function CandyUI_Nameplates:OnUnitMemberOfGuildChange(unitOwner)
	local tNameplate = self.arUnit2Nameplate[unitOwner:GetId()]
	if tNameplate ~= nil then
		self:DrawGuild(tNameplate)
		tNameplate.bIsGuildMember = self.guildDisplayed and self.guildDisplayed:IsUnitMember(unitOwner) or false
		tNameplate.bIsWarPartyMember = self.guildWarParty and self.guildWarParty:IsUnitMember(unitOwner) or false
	end
end

function CandyUI_Nameplates:OnTargetUnitChanged(unitOwner) -- build targeted options here; we get this event when a creature attacks, too
	for idx, tNameplateOther in pairs(self.arUnit2Nameplate) do
		local bIsTarget = tNameplateOther.bIsTarget
		local bIsCluster = tNameplateOther.bIsCluster

		tNameplateOther.bIsTarget = false
		tNameplateOther.bIsCluster = false

		if bIsTarget or bIsCluster then
			self:DrawName(tNameplateOther)
			self:DrawGuild(tNameplateOther)
			self:DrawLevel(tNameplateOther)
			self:UpdateNameplateRewardInfo(tNameplateOther)
		end
	end

	if unitOwner == nil then
		return
	end

	local tNameplate = self.arUnit2Nameplate[unitOwner:GetId()]
	if tNameplate == nil then
		return
	end

	if GameLib.GetTargetUnit() == unitOwner then
		tNameplate.bIsTarget = true
		self:DrawName(tNameplate)
		self:DrawGuild(tNameplate)
		self:DrawLevel(tNameplate)
		self:UpdateNameplateRewardInfo(tNameplate)

		local tCluster = unitOwner:GetClusterUnits()
		if tCluster ~= nil then
			tNameplate.bIsCluster = true

			for idx, unitCluster in pairs(tCluster) do
				local tNameplateOther = self.arUnit2Nameplate[unitCluster:GetId()]
				if tNameplateOther ~= nil then
					tNameplateOther.bIsCluster = true
				end
			end
		end
	end
end

function CandyUI_Nameplates:RefreshTexts()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		if tNameplate.bShow then
			self:DrawName(tNameplate)
			self:DrawGuild(tNameplate)
			self:DrawLevel(tNameplate)
		end
	end
end
-----------------------------------------------------------------------------------------------
-- 								OPTIONS
-----------------------------------------------------------------------------------------------
--#############################################################################################
--ALL MESSED UP BECAUSE INDIVIDUAL MEANS EACH MOB NOT PLAYER
--ADD SEPERATE OPTIONS FOR ME YOU MOBS
kcuiNPDefaults = {
	char = {
		currentProfile = nil,
	},
	profile = {
		general = { --display
			bShowMainObjective = true,
			bShowMainGroup = true,
			bShowOrganization = true,
			bShowVendor = true,
			bShowTaxi = true,
			bShowMyNameplate = false,
			nMaxRange = 70,
			--non target \/
			bHideCombatNonTargets = false,
			bUseOcclusion = true,
			bShowQuestItems = true,
			
			-- new
			bHideSpeech = true,
			bShowQuestItems = true,
			nHealthThresholdHigh = 75,
			nHealthThresholdLow = 25,
			nScale = 1, ---Check?
			nViewDistance = 100, --Check?
			bAutoPosition = true,
			bShowSimple = false,
		},
		player = {
			bShow = true,
			bShowName = true,
			bShowNameCombat = true,
			bShowGuildTitle = true,
			bShowGuildTitleCombat = true,
			bShowHealthShield = false,
			bShowHealthShieldCombat = false,
			bShowCastBar = false,
			bShowCastBarCombat = false,
			bShowVulnBar = false,
			bShowVulnBarCombat = false,
			crHealthBarColor = "ffff0000",
			crHealthBarColorHigh = "ff00ff00",
			crHealthBarColorMid = "ffffff00",
			crHealthBarColorLow = "ffff0000",
			crShieldBarColor = "ff00bff3",
			bShowHealthText = false,
			bOnlyDamaged = false,
			bUseColorThreshold = false,
		},
		target = {
			bShow = true,
			bShowName = true,
			bShowNameCombat = true,
			bShowGuildTitle = true,
			bShowGuildTitleCombat = true,
			bShowHealthShield = false,
			bShowHealthShieldCombat = true,
			bShowCastBar = true,
			bShowCastBarCombat = true,
			bShowVulnBar = true,
			bShowVulnBarCombat = true,
			bShowTargetMarker = true,
			bShowTargetMarkerCombat = true,
			bShowRewards = true,
			bShowRewardsCombat = true,
			bShowIcons = true,
			bShowIconsCombat = true,
			crHealthBarColor = "ffff0000",
			crHealthBarColorHigh = "ff00ff00",
			crHealthBarColorMid = "ffffff00",
			crHealthBarColorLow = "ffff0000",
			crShieldBarColor = "ff00bff3",
			bShowHealthText = true,
			bOnlyDamaged = false,
			bUseColorThreshold = true,
		},
		friendly = {
			bShow = true,
			bShowNPCS = true,
			bShowPlayers = true,
			bShowVendors = true,
			bShowGroup = true,
			bShowGuild = true,
			bShowSimple = false,
			bShowName = true,
			bShowNameCombat = true,
			bShowGuildTitle = true,
			bShowGuildTitleCombat = true,
			bShowHealthShield = false,
			bShowHealthShieldCombat = true,
			bShowCastBar = false,
			bShowCastBarCombat = true,
			bShowVulnBar = false,
			bShowVulnBarCombat = true,
			bShowRewards = true,
			bShowRewardsCombat = true,
			bShowIcons = true,
			bShowIconsCombat = true,
			crHealthBarColor = "ffff0000",
			crHealthBarColorHigh = "ff00ff00",
			crHealthBarColorMid = "ffffff00",
			crHealthBarColorLow = "ffff0000",
			crShieldBarColor = "ff00bff3",
			bShowHealthText = false,
			bOnlyDamaged = true,
			bUseColorThreshold = true,
		},
		enemy = {
			bShow = true,
			bShowNPCS = true,
			bShowPlayers = true,
			bShowName = true,
			bShowNameCombat = true,
			bShowGuildTitle = true,
			bShowGuildTitleCombat = true,
			bShowHealthShield = true,
			bShowHealthShieldCombat = true,
			bShowCastBar = true,
			bShowCastBarCombat = true,
			bShowVulnBar = true,
			bShowVulnBarCombat = true,
			bShowRewards = true,
			bShowRewardsCombat = true,
			bShowIcons = true,
			bShowIconsCombat = true,
			crHealthBarColor = "ffff0000",
			crHealthBarColorHigh = "ff00ff00",
			crHealthBarColorMid = "ffffff00",
			crHealthBarColorLow = "ffff0000",
			crShieldBarColor = "ff00bff3",
			bShowHealthText = false,
			bOnlyDamaged = false,
			bUseColorThreshold = true,
		},
		neutral = {
			bShow = true,
			bShowNPCS = true,
			bShowPlayers = true,
			bShowHarvestNodes = true,
			bShowName = true,
			bShowNameCombat = true,
			bShowGuildTitle = true,
			bShowGuildTitleCombat = true,
			bShowHealthShield = false,
			bShowHealthShieldCombat = true,
			bShowCastBar = false,
			bShowCastBarCombat = true,
			bShowVulnBar = false,
			bShowVulnBarCombat = true,
			bShowRewards = true,
			bShowRewardsCombat = true,
			bShowIcons = true,
			bShowIconsCombat = true,
			crHealthBarColor = "ffff0000",
			crHealthBarColorHigh = "ff00ff00",
			crHealthBarColorMid = "ffffff00",
			crHealthBarColorLow = "ffff0000",
			crShieldBarColor = "ff00bff3",
			bShowHealthText = false,
			bOnlyDamaged = true,
			bUseColorThreshold = true,
		},
		other = {
			bShow = false,
			bShowHarvestNodes = true,
			bShowName = true,
			bShowNameCombat = true,
			bShowGuildTitle = true,
			bShowGuildTitleCombat = true,
			bShowHealthShield = false,
			bShowHealthShieldCombat = true,
			bShowCastBar = false,
			bShowCastBarCombat = true,
			bShowVulnBar = false,
			bShowVulnBarCombat = true,
			bShowRewards = true,
			bShowRewardsCombat = true,
			bShowIcons = true,
			bShowIconsCombat = true,
			crHealthBarColor = "ffff0000",
			crShieldBarColor = "ff00bff3",
			bShowHealthText = false,
			bOnlyDamaged = true,
			bUseColorThreshold = true,
		},
	},
}



--%%%%%%%%%%%%%%%%%
-- Create Dropdown
--%%%%%%%%%%%%%%%%%
local function CreateDropdownMenu(self, wndDropdown, tOptions, strEventHandler, bDisable)
	--wndDropdown needs to be the whole window object i.e. containing the label, button, and box
	local wndDropdownButton = wndDropdown:FindChild("Dropdown")
	local wndDropdownBox = wndDropdown:FindChild("DropdownBox")
	
	if #wndDropdownBox:FindChild("ScrollList"):GetChildren() > 0 then
		return
	end	
	for name, value in pairs(tOptions) do
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", wndDropdownBox:FindChild("ScrollList"), self)
		currButton:SetText(name)
		currButton:SetData(value)
		currButton:AddEventHandler("ButtonUp", strEventHandler)
	end
		
	wndDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	if bDisable then
	--[[
		for k, v in pairs(wndDropdown:GetParent():GetChildren()) do
			if v:GetName() ~= wndDropdown:GetName() and v:GetName() ~= "Title" and v:GetName() ~= "Description" then
				v:Enable(false)
				--Print(v:GetName())
			end
		end
		]]
	end
end

---------------------------------
--		Dropdown Options
---------------------------------


--===============================
--			Set Options
--===============================
--make sure to set dropdown box data to player/target/whatever --dont need anymore
function CandyUI_Nameplates:SetOptions()
	local Options = self.db.profile
--General
	local generalControls = self.wndControls:FindChild("GeneralControls")
	--Quest
	generalControls:FindChild("ShowQuestItemsToggle"):SetCheck(Options.general.bShowQuestItems)
	--SpeechHide
	generalControls:FindChild("SpeechHideToggle"):SetCheck(Options.general.bHideSpeech)
	--AutoPosition
	generalControls:FindChild("AutoPositionToggle"):SetCheck(Options.general.bAutoPosition )
	--Simple
	generalControls:FindChild("ShowSimpleToggle"):SetCheck(Options.general.bShowSimple)
	--Scale
	generalControls:FindChild("Scale:EditBox"):SetText(Options.general.nScale)
	generalControls:FindChild("Scale:SliderBar"):SetValue(Options.general.nScale)
	--ViewDistance
	generalControls:FindChild("ViewDistance:EditBox"):SetText(Options.general.nViewDistance)
	generalControls:FindChild("ViewDistance:SliderBar"):SetValue(Options.general.nViewDistance)
	--HealthThresholdHigh
	generalControls:FindChild("HighHealthThreshold:EditBox"):SetText(Options.general.nHealthThresholdHigh)
	generalControls:FindChild("HighHealthThreshold:SliderBar"):SetValue(Options.general.nHealthThresholdHigh)
	--HealthThresholdLow
	generalControls:FindChild("LowHealthThreshold:EditBox"):SetText(Options.general.nHealthThresholdLow)
	generalControls:FindChild("LowHealthThreshold:SliderBar"):SetValue(Options.general.nHealthThresholdLow)
--Player
	local playerControls = self.wndControls:FindChild("PlayerControls")
	--Show
	playerControls:FindChild("ShowToggle"):SetCheck(Options.player.bShow)
	--Name
	playerControls:FindChild("NameToggle"):SetCheck(Options.player.bShowName)
	playerControls:FindChild("NameCombatToggle"):SetCheck(Options.player.bShowNameCombat)
	--Guild
	playerControls:FindChild("GuildToggle"):SetCheck(Options.player.bShowGuildTitle)
	playerControls:FindChild("GuildCombatToggle"):SetCheck(Options.player.bShowGuildTitleCombat)
	--Health and Shield
	playerControls:FindChild("HealthToggle"):SetCheck(Options.player.bShowHealthShield)
	playerControls:FindChild("HealthCombatToggle"):SetCheck(Options.player.bShowHealthShieldCombat)
	--CastBar
	playerControls:FindChild("CastToggle"):SetCheck(Options.player.bShowCastBar)
	playerControls:FindChild("CastCombatToggle"):SetCheck(Options.player.bShowCastBarCombat)
	--Name
	playerControls:FindChild("VulnToggle"):SetCheck(Options.player.bShowVulnBar)
	playerControls:FindChild("VulnCombatToggle"):SetCheck(Options.player.bShowVulnBarCombat)
	--Health Bar Color
	playerControls:FindChild("HealthBarColorHigh:Swatch"):SetBGColor(Options.player.crHealthBarColorHigh)
	--Health Bar Color
	playerControls:FindChild("HealthBarColor:Swatch"):SetBGColor(Options.player.crHealthBarColorMid)
	--Health Bar Color
	playerControls:FindChild("HealthBarColorLow:Swatch"):SetBGColor(Options.player.crHealthBarColorLow)
	--Shield Bar Color
	playerControls:FindChild("ShieldBarColor:Swatch"):SetBGColor(Options.player.crShieldBarColor)
	--Show HealthT ext
	playerControls:FindChild("ShowHealthTextToggle"):SetCheck(Options.player.bShowHealthText)
	--Show
	playerControls:FindChild("ShowIfDamagedToggle"):SetCheck(Options.player.bOnlyDamaged)
	--Show
	--playerControls:FindChild("HealthColorThresholdToggle"):SetCheck(Options.player.bUseColorThreshold)
--Target
	local targetControls = self.wndControls:FindChild("TargetControls")
	--Show
	targetControls:FindChild("ShowToggle"):SetCheck(Options.target.bShow)
	--Name
	targetControls:FindChild("NameToggle"):SetCheck(Options.target.bShowName)
	targetControls:FindChild("NameCombatToggle"):SetCheck(Options.target.bShowNameCombat)
	--Guild
	targetControls:FindChild("GuildToggle"):SetCheck(Options.target.bShowGuildTitle)
	targetControls:FindChild("GuildCombatToggle"):SetCheck(Options.target.bShowGuildTitleCombat)
	--Health and Shield
	targetControls:FindChild("HealthToggle"):SetCheck(Options.target.bShowHealthShield)
	targetControls:FindChild("HealthCombatToggle"):SetCheck(Options.target.bShowHealthShieldCombat)
	--CastBar
	targetControls:FindChild("CastToggle"):SetCheck(Options.target.bShowCastBar)
	targetControls:FindChild("CastCombatToggle"):SetCheck(Options.target.bShowCastBarCombat)
	--VulnToggle
	targetControls:FindChild("VulnToggle"):SetCheck(Options.target.bShowVulnBar)
	targetControls:FindChild("VulnCombatToggle"):SetCheck(Options.target.bShowVulnBarCombat)
	--TargetMarkerToggle
	targetControls:FindChild("TargetMarkerToggle"):SetCheck(Options.target.bShowTargetMarker)
	targetControls:FindChild("TargetMarkerCombatToggle"):SetCheck(Options.target.bShowTargetMarkerCombat)
	--Rewards
	targetControls:FindChild("RewardsToggle"):SetCheck(Options.target.bShowRewards)
	targetControls:FindChild("RewardsCombatToggle"):SetCheck(Options.target.bShowRewardsCombat)
	--Icons
	targetControls:FindChild("IconsToggle"):SetCheck(Options.target.bShowIcons)
	targetControls:FindChild("IconsCombatToggle"):SetCheck(Options.target.bShowIconsCombat)
	--Health Bar Color
	targetControls:FindChild("HealthBarColorHigh:Swatch"):SetBGColor(Options.target.crHealthBarColorHigh)
	--Health Bar Color
	targetControls:FindChild("HealthBarColor:Swatch"):SetBGColor(Options.target.crHealthBarColorMid)
	--Health Bar Color
	targetControls:FindChild("HealthBarColorLow:Swatch"):SetBGColor(Options.target.crHealthBarColorLow)
	--Shield Bar Color
	targetControls:FindChild("ShieldBarColor:Swatch"):SetBGColor(Options.target.crShieldBarColor)
	--Show HealthT ext
	targetControls:FindChild("ShowHealthTextToggle"):SetCheck(Options.target.bShowHealthText)
	--ShowIfDamagedToggle
	targetControls:FindChild("ShowIfDamagedToggle"):SetCheck(Options.target.bOnlyDamaged)
	--HealthColorThresholdToggle
	--targetControls:FindChild("HealthColorThresholdToggle"):SetCheck(Options.target.bUseColorThreshold)
--Friendly
	local friendlyControls = self.wndControls:FindChild("FriendlyControls")
	--Show
	friendlyControls:FindChild("ShowToggle"):SetCheck(Options.friendly.bShow)
	--NPCs
	friendlyControls:FindChild("ShowNPCToggle"):SetCheck(Options.friendly.bShowNPCS)
	--Players
	friendlyControls:FindChild("ShowPlayersToggle"):SetCheck(Options.friendly.bShowPlayers)
	--Vendors
	friendlyControls:FindChild("ShowVendorToggle"):SetCheck(Options.friendly.bShowVendors)
	--Group
	friendlyControls:FindChild("ShowGroupToggle"):SetCheck(Options.friendly.bShowGroup)
	--Guild
	friendlyControls:FindChild("ShowGuildToggle"):SetCheck(Options.friendly.bShowGuild)
	
	--Name
	friendlyControls:FindChild("NameToggle"):SetCheck(Options.friendly.bShowName)
	friendlyControls:FindChild("NameCombatToggle"):SetCheck(Options.friendly.bShowNameCombat)
	--Guild
	friendlyControls:FindChild("GuildToggle"):SetCheck(Options.friendly.bShowGuildTitle)
	friendlyControls:FindChild("GuildCombatToggle"):SetCheck(Options.friendly.bShowGuildTitleCombat)
	--Health and Shield
	friendlyControls:FindChild("HealthToggle"):SetCheck(Options.friendly.bShowHealthShield)
	friendlyControls:FindChild("HealthCombatToggle"):SetCheck(Options.friendly.bShowHealthShieldCombat)
	--CastBar
	friendlyControls:FindChild("CastToggle"):SetCheck(Options.friendly.bShowCastBar)
	friendlyControls:FindChild("CastCombatToggle"):SetCheck(Options.friendly.bShowCastBarCombat)
	--VulnToggle
	friendlyControls:FindChild("VulnToggle"):SetCheck(Options.friendly.bShowVulnBar)
	friendlyControls:FindChild("VulnCombatToggle"):SetCheck(Options.friendly.bShowVulnBarCombat)
	--Rewards
	friendlyControls:FindChild("RewardsToggle"):SetCheck(Options.friendly.bShowRewards)
	friendlyControls:FindChild("RewardsCombatToggle"):SetCheck(Options.friendly.bShowRewardsCombat)
	--Icons
	friendlyControls:FindChild("IconsToggle"):SetCheck(Options.friendly.bShowIcons)
	friendlyControls:FindChild("IconsCombatToggle"):SetCheck(Options.friendly.bShowIconsCombat)
	--Health Bar Color
	friendlyControls:FindChild("HealthBarColorHigh:Swatch"):SetBGColor(Options.friendly.crHealthBarColorHigh)
	--Health Bar Color
	friendlyControls:FindChild("HealthBarColor:Swatch"):SetBGColor(Options.friendly.crHealthBarColorMid)
	--Health Bar Color
	friendlyControls:FindChild("HealthBarColorLow:Swatch"):SetBGColor(Options.friendly.crHealthBarColorLow)
	--Shield Bar Color
	friendlyControls:FindChild("ShieldBarColor:Swatch"):SetBGColor(Options.friendly.crShieldBarColor)
	--Show HealthT ext
	friendlyControls:FindChild("ShowHealthTextToggle"):SetCheck(Options.friendly.bShowHealthText)
	--ShowIfDamagedToggle
	friendlyControls:FindChild("ShowIfDamagedToggle"):SetCheck(Options.friendly.bOnlyDamaged)
	--HealthColorThresholdToggle
	--friendlyControls:FindChild("HealthColorThresholdToggle"):SetCheck(Options.friendly.bUseColorThreshold)
--Enemy
	local enemyControls = self.wndControls:FindChild("EnemyControls")
	--Show
	enemyControls:FindChild("ShowToggle"):SetCheck(Options.enemy.bShow)
	--NPCs
	enemyControls:FindChild("ShowNPCToggle"):SetCheck(Options.enemy.bShowNPCS)
	--Players
	enemyControls:FindChild("ShowPlayersToggle"):SetCheck(Options.enemy.bShowPlayers)
	--Name
	enemyControls:FindChild("NameToggle"):SetCheck(Options.enemy.bShowName)
	enemyControls:FindChild("NameCombatToggle"):SetCheck(Options.enemy.bShowNameCombat)
	--Guild
	enemyControls:FindChild("GuildToggle"):SetCheck(Options.enemy.bShowGuildTitle)
	enemyControls:FindChild("GuildCombatToggle"):SetCheck(Options.enemy.bShowGuildTitleCombat)
	--Health and Shield
	enemyControls:FindChild("HealthToggle"):SetCheck(Options.enemy.bShowHealthShield)
	enemyControls:FindChild("HealthCombatToggle"):SetCheck(Options.enemy.bShowHealthShieldCombat)
	--CastBar
	enemyControls:FindChild("CastToggle"):SetCheck(Options.enemy.bShowCastBar)
	enemyControls:FindChild("CastCombatToggle"):SetCheck(Options.enemy.bShowCastBarCombat)
	--VulnToggle
	enemyControls:FindChild("VulnToggle"):SetCheck(Options.enemy.bShowVulnBar)
	enemyControls:FindChild("VulnCombatToggle"):SetCheck(Options.enemy.bShowVulnBarCombat)
	--Rewards
	enemyControls:FindChild("RewardsToggle"):SetCheck(Options.enemy.bShowRewards)
	enemyControls:FindChild("RewardsCombatToggle"):SetCheck(Options.enemy.bShowRewardsCombat)
	--Icons
	enemyControls:FindChild("IconsToggle"):SetCheck(Options.enemy.bShowIcons)
	enemyControls:FindChild("IconsCombatToggle"):SetCheck(Options.enemy.bShowIconsCombat)
	--Health Bar Color
	enemyControls:FindChild("HealthBarColorHigh:Swatch"):SetBGColor(Options.enemy.crHealthBarColorHigh)
	--Health Bar Color
	enemyControls:FindChild("HealthBarColor:Swatch"):SetBGColor(Options.enemy.crHealthBarColorMid)
	--Health Bar Color
	enemyControls:FindChild("HealthBarColorLow:Swatch"):SetBGColor(Options.enemy.crHealthBarColorLow)
	--Shield Bar Color
	enemyControls:FindChild("ShieldBarColor:Swatch"):SetBGColor(Options.enemy.crShieldBarColor)
	--Show HealthT ext
	enemyControls:FindChild("ShowHealthTextToggle"):SetCheck(Options.enemy.bShowHealthText)
	--ShowIfDamagedToggle
	enemyControls:FindChild("ShowIfDamagedToggle"):SetCheck(Options.enemy.bOnlyDamaged)
	--HealthColorThresholdToggle
	--enemyControls:FindChild("HealthColorThresholdToggle"):SetCheck(Options.enemy.bUseColorThreshold)
--Neutral
	local neutralControls = self.wndControls:FindChild("NeutralControls")
	--Show
	neutralControls:FindChild("ShowToggle"):SetCheck(Options.neutral.bShow)
	--NPCs
	neutralControls:FindChild("ShowNPCToggle"):SetCheck(Options.neutral.bShowNPCS)
	--Players
	neutralControls:FindChild("ShowPlayersToggle"):SetCheck(Options.neutral.bShowPlayers)
	--Harvest Nodes
	neutralControls:FindChild("ShowHarvestNodesToggle"):SetCheck(Options.neutral.bShowHarvestNodes)
	--Name
	neutralControls:FindChild("NameToggle"):SetCheck(Options.neutral.bShowName)
	neutralControls:FindChild("NameCombatToggle"):SetCheck(Options.neutral.bShowNameCombat)
	--Guild
	neutralControls:FindChild("GuildToggle"):SetCheck(Options.neutral.bShowGuildTitle)
	neutralControls:FindChild("GuildCombatToggle"):SetCheck(Options.neutral.bShowGuildTitleCombat)
	--Health and Shield
	neutralControls:FindChild("HealthToggle"):SetCheck(Options.neutral.bShowHealthShield)
	neutralControls:FindChild("HealthCombatToggle"):SetCheck(Options.neutral.bShowHealthShieldCombat)
	--CastBar
	neutralControls:FindChild("CastToggle"):SetCheck(Options.neutral.bShowCastBar)
	neutralControls:FindChild("CastCombatToggle"):SetCheck(Options.neutral.bShowCastBarCombat)
	--VulnToggle
	neutralControls:FindChild("VulnToggle"):SetCheck(Options.neutral.bShowVulnBar)
	neutralControls:FindChild("VulnCombatToggle"):SetCheck(Options.neutral.bShowVulnBarCombat)
	--Rewards
	neutralControls:FindChild("RewardsToggle"):SetCheck(Options.neutral.bShowRewards)
	neutralControls:FindChild("RewardsCombatToggle"):SetCheck(Options.neutral.bShowRewardsCombat)
	--Icons
	neutralControls:FindChild("IconsToggle"):SetCheck(Options.neutral.bShowIcons)
	neutralControls:FindChild("IconsCombatToggle"):SetCheck(Options.neutral.bShowIconsCombat)
	--Health Bar Color
	neutralControls:FindChild("HealthBarColorHigh:Swatch"):SetBGColor(Options.neutral.crHealthBarColorHigh)
	--Health Bar Color
	neutralControls:FindChild("HealthBarColor:Swatch"):SetBGColor(Options.neutral.crHealthBarColorMid)
	--Health Bar Color
	neutralControls:FindChild("HealthBarColorLow:Swatch"):SetBGColor(Options.neutral.crHealthBarColorLow)
	--Shield Bar Color
	neutralControls:FindChild("ShieldBarColor:Swatch"):SetBGColor(Options.neutral.crShieldBarColor)
	--Show HealthT ext
	neutralControls:FindChild("ShowHealthTextToggle"):SetCheck(Options.neutral.bShowHealthText)
	--ShowIfDamagedToggle
	neutralControls:FindChild("ShowIfDamagedToggle"):SetCheck(Options.neutral.bOnlyDamaged)
	--HealthColorThresholdToggle
	--neutralControls:FindChild("HealthColorThresholdToggle"):SetCheck(Options.neutral.bUseColorThreshold)
--Other
	--[[
	local otherControls = self.wndControls:FindChild("OtherControls")
	--Show
	otherControls:FindChild("ShowToggle"):SetCheck(Options.other.bShow)
	--NPCs
	otherControls:FindChild("ShowNPCToggle"):SetCheck(Options.other.bShowNPCS)
	--Players
	otherControls:FindChild("ShowPlayersToggle"):SetCheck(Options.other.bShowPlayers)
	--Harvest Nodes
	otherControls:FindChild("ShowHarvestNodesToggle"):SetCheck(Options.other.bShowHarvestNodes)
	--Name
	otherControls:FindChild("NameToggle"):SetCheck(Options.other.bShowName)
	otherControls:FindChild("NameCombatToggle"):SetCheck(Options.other.bShowNameCombat)
	--Guild
	otherControls:FindChild("GuildToggle"):SetCheck(Options.other.bShowGuildTitle)
	otherControls:FindChild("GuildCombatToggle"):SetCheck(Options.other.bShowGuildTitleCombat)
	--Health and Shield
	otherControls:FindChild("HealthToggle"):SetCheck(Options.other.bShowHealthShield)
	otherControls:FindChild("HealthCombatToggle"):SetCheck(Options.other.bShowHealthShieldCombat)
	--CastBar
	otherControls:FindChild("CastToggle"):SetCheck(Options.other.bShowCastBar)
	otherControls:FindChild("CastCombatToggle"):SetCheck(Options.other.bShowCastBarCombat)
	--VulnToggle
	otherControls:FindChild("VulnToggle"):SetCheck(Options.other.bShowVulnBar)
	otherControls:FindChild("VulnCombatToggle"):SetCheck(Options.other.bShowVulnBarCombat)
	--Rewards
	otherControls:FindChild("RewardsToggle"):SetCheck(Options.other.bShowRewards)
	otherControls:FindChild("RewardsCombatToggle"):SetCheck(Options.other.bShowRewardsCombat)
	--Icons
	otherControls:FindChild("IconsToggle"):SetCheck(Options.other.bShowIcons)
	otherControls:FindChild("IconsCombatToggle"):SetCheck(Options.other.bShowIconsCombat)
	--Health Bar Color
	otherControls:FindChild("HealthBarColor:Swatch"):SetBGColor(Options.other.crHealthBarColor)
	--Shield Bar Color
	otherControls:FindChild("ShieldBarColor:Swatch"):SetBGColor(Options.other.crShieldBarColor)
	--Show HealthT ext
	otherControls:FindChild("ShowHealthTextToggle"):SetCheck(Options.other.bShowHealthText)
	--ShowIfDamagedToggle
	otherControls:FindChild("ShowIfDamagedToggle"):SetCheck(Options.other.bOnlyDamaged)
	--HealthColorThresholdToggle
	otherControls:FindChild("HealthColorThresholdToggle"):SetCheck(Options.other.bUseColorThreshold)
	]]
end

function CandyUI_Nameplates:ColorPickerCallback(strColor)
	local strUnit = self.strColorPickerTargetUnit
	local strUnitLower = string.lower(strUnit)
	if self.strColorPickerTargetControl == "HealthBarHigh" then
		self.db.profile[strUnitLower].crHealthBarColorHigh = strColor
		self.wndControls:FindChild(strUnit.."Controls"):FindChild("HealthBarColorHigh"):FindChild("Swatch"):SetBGColor(strColor)
	elseif self.strColorPickerTargetControl == "HealthBarMid" then
		self.db.profile[strUnitLower].crHealthBarColorMid = strColor
		self.wndControls:FindChild(strUnit.."Controls"):FindChild("HealthBarColor"):FindChild("Swatch"):SetBGColor(strColor)
	elseif self.strColorPickerTargetControl == "HealthBarLow" then
		self.db.profile[strUnitLower].crHealthBarColorLow = strColor
		self.wndControls:FindChild(strUnit.."Controls"):FindChild("HealthBarColorLow"):FindChild("Swatch"):SetBGColor(strColor)
	elseif self.strColorPickerTargetControl == "ShieldBar" then
		self.db.profile[strUnitLower].crShieldBar = strColor
		self.wndControls:FindChild(strUnit.."Controls"):FindChild("ShieldBarColor"):FindChild("Swatch"):SetBGColor(strColor)
	end
end
--NEWWWWWW =======================================================

function CandyUI_Nameplates:OnShowClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShow = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnNameToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowName = wndControl:IsChecked()
	
	if strUnit == "Player" then
		self:OnUnitNameChanged(self.unitPlayer)
	end
end

function CandyUI_Nameplates:OnNameCombatToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowNameCombat = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnGuildToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowGuildTitle = wndControl:IsChecked()
	
	self:RefreshTexts()
end

function CandyUI_Nameplates:OnGuildCombatToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowGuildTitleCombat = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnHealthToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowHealthShield = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnHealthCombatToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowHealthShieldCombat = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnCastToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowCastBar = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnCastCombatToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowCastBarCombat = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnVulnToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowVulnBar = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnVulnCombatToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowVulnBarCombat = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnHealthBarColorClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():GetParent():FindChild("Title"):GetText()
	local strControlText = wndControl:GetParent():GetText()
	if string.find(strControlText, "High") then
		self.strColorPickerTargetControl = "HealthBarHigh"
	elseif string.find(strControlText, "Mid") then
		self.strColorPickerTargetControl = "HealthBarMid"
	elseif string.find(strControlText, "Low") then
		self.strColorPickerTargetControl = "HealthBarLow"
	end
	--Open Color Picker
	self.strColorPickerTargetUnit = strUnit
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
end

function CandyUI_Nameplates:OnShieldBarColorClick( wndHandler, wndControl, eMouseButton )
end

function CandyUI_Nameplates:OnShowHealthTextClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowHealthText = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowIfDamagedClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bOnlyDamaged = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnHealthColorThresholdClick( wndHandler, wndControl, eMouseButton )
end

function CandyUI_Nameplates:OnTargetMarkerToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowTargetMarker = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnTargetMarkerCombatToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowTargetMarkerCombat = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnIconsToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowIcons = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnIconsCombatToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowIconsCombat = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnRewardsToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowRewards = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnRewardsCombatToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowRewardsCombat = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowNPCToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowNPCS = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowPlayersToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowPlayers = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowVendorToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowVendors = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowGroupToggleClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowGroup = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowGuildUnitsClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowGuild = wndControl:IsChecked()
end

---------------------------------------------------------------------------------------------------
-- OptionsControlsList Functions
---------------------------------------------------------------------------------------------------

function CandyUI_Nameplates:OnShowHarvestNodesClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile[strUnitLower].bShowHarvestNodes = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowSimpleToggleClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowSimple = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowQuestItemsClick( wndHandler, wndControl, eMouseButton )
	local strUnit = wndControl:GetParent():FindChild("Title"):GetText()
	local strUnitLower = string.lower(strUnit)
	
	self.db.profile.general.bShowQuestItems = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnScaleChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local nValue = round(fNewValue, 1)
	self.db.profile.general.nScale = nValue
	wndControl:GetParent():FindChild("EditBox"):SetText(string.format("%.1f", nValue))
end

function CandyUI_Nameplates:OnViewDistanceChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local nValue = round(fNewValue)
	self.db.profile.general.nViewDistance = nValue
	wndControl:GetParent():FindChild("EditBox"):SetText(nValue)
end

function CandyUI_Nameplates:OnHealthThresholdHighChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local nValue = round(fNewValue)
	self.db.profile.general.nHealthThresholdHigh = nValue --in percent
	wndControl:GetParent():FindChild("EditBox"):SetText(nValue)
end

function CandyUI_Nameplates:OnHealthThresholdLowChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local nValue = round(fNewValue)
	self.db.profile.general.nHealthThresholdLow = nValue --in percent
	wndControl:GetParent():FindChild("EditBox"):SetText(nValue)
end

function CandyUI_Nameplates:OnUseOcclusionClick( wndHandler, wndControl, eMouseButton )
end

function CandyUI_Nameplates:OnAutoPositionClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bAutoPosition = wndControl:IsChecked()	
end

function CandyUI_Nameplates:OnHideWithSpeechClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bHideSpeech = wndControl:IsChecked()
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Nameplates Instance
-----------------------------------------------------------------------------------------------
local CandyUI_NameplatesInst = CandyUI_Nameplates:new()
CandyUI_NameplatesInst:Init()
