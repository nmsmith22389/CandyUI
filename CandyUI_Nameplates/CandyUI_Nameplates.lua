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
local knTargetRange 		= 40000 -- the distance^2 that normal nameplates should draw within (max targeting range)
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
	Apollo.RegisterEventHandler("UnitCreated", 					"OnPreloadUnitCreated", self)
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CandyUI_Nameplates.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, kcuiNPDefaults)
end

function CandyUI_Nameplates:OnPreloadUnitCreated(unitNew)
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
		Apollo.RegisterEventHandler("CandyUI_NameplatesClicked", "OnOptionsHome", self)
		self.OptionsAddon = Apollo.GetAddon("CandyUI_Options")
	self.wndOptionsMain = self.OptionsAddon.wndOptions
	assert(self.wndOptionsMain ~= nil, "\n\n\nOptions Not Loaded\n\n")
	--local wndCurr = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptionsMain:FindChild("ListControls"), self)
	--wndCurr:SetText("Unit Frames")
	
	self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControlsList", self.wndOptionsMain:FindChild("OptionsDialogueControls"), self)
	
	self.wndControls:Show(false, true)
	
	if not candyUI_Cats then
		candyUI_Cats = {}
	end
	table.insert(candyUI_Cats, "Nameplates")
		self.wndOptionsMain:FindChild("ListControls"):ArrangeChildrenVert()
		
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
		self.nFrameLeft, self.nFrameTop, self.nFrameRight, self.nFrameBottom = wndTemp:FindChild("HealthBarBGNoShield"):GetAnchorOffsets()
		self.nHealthWidth = self.nFrameRight - self.nFrameLeft
		wndTemp:Destroy()
	
		self:CreateUnitsFromPreload()
	end
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
	if self.bAddonRestoredOrLoaded then
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
	local tFlags =
	{
		bVert = false,
		bHideQuests = not self.db.profile.rewards.bShowRewardTypeQuest,
		bHideChallenges = not self.db.profile.rewards.bShowRewardTypeChallenge,
		bHideMissions = not self.db.profile.rewards.bShowRewardTypeMission,
		bHidePublicEvents = not self.db.profile.rewards.bShowRewardTypePublicEvent,
		bHideRivals = not self.db.profile.rewards.bShowRivals,
		bHideFriends = not self.db.profile.rewards.bShowFriends
	}

	if RewardIcons ~= nil and RewardIcons.GetUnitRewardIconsForm ~= nil then
		RewardIcons.GetUnitRewardIconsForm(tNameplate.wnd.questRewards, tNameplate.unitOwner, tFlags)
	end
end

function CandyUI_Nameplates:UpdateAllNameplateVisibility()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
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

	if bIsMounted and unitWindow == unitOwner then
		wndNameplate:SetUnit(unitOwner:GetUnitMount(), 1)
	elseif not bIsMounted and unitWindow ~= unitOwner then
		wndNameplate:SetUnit(unitOwner, 1)
	end

	tNameplate.bOnScreen = wndNameplate:IsOnScreen()
	tNameplate.bOccluded = wndNameplate:IsOccluded()
	tNameplate.eDisposition = unitOwner:GetDispositionTo(self.unitPlayer)
	local bNewShow = self:HelperVerifyVisibilityOptions(tNameplate) and self:CheckDrawDistance(tNameplate)
	if bNewShow ~= tNameplate.bShow then
		wndNameplate:Show(bNewShow)
		tNameplate.bShow = bNewShow
	end
end

function CandyUI_Nameplates:OnUnitCreated(unitNew) -- build main options here
	if unitNew == nil
		or not unitNew:IsValid()
		or not unitNew:ShouldShowNamePlate()
		or unitNew:GetType() == "Collectible"
		or unitNew:GetType() == "PinataLoot" then
		-- Never have nameplates
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
			health = wnd:FindChild("HealthBar"),
			healthBG = wnd:FindChild("HealthBarBG"),
			healthNoShield = wnd:FindChild("HealthBarNoShield"),
			healthNoShieldBG = wnd:FindChild("HealthBarBGNoShield"),
			shield = wnd:FindChild("ShieldBar"),
			shieldBG = wnd:FindChild("ShieldBarBG"),
			absorb = wnd:FindChild("AbsorbBar"),
			castBar = wnd:FindChild("CastBar"),
			vulnerable = wnd:FindChild("Vulnerable"),
			level = wnd:FindChild("Level"),
			wndGuild = wnd:FindChild("Guild"),
			wndName = wnd:FindChild("NameRewardContainer:Name"),
			certainDeath = wnd:FindChild("TargetAndDeathContainer:CertainDeath"),
			targetScalingMark = wnd:FindChild("TargetScalingMark"),
			nameRewardContainer = wnd:FindChild("NameRewardContainer:RewardContainer"),
			healthMaxShield = wnd:FindChild("ShieldBarBG"),
			healthShieldFill = wnd:FindChild("ShieldBar"),
			healthMaxAbsorb = wnd:FindChild("Container:Health:HealthBars:MaxAbsorb"),
			healthAbsorbFill = wnd:FindChild("Container:Health:HealthBars:MaxAbsorb:AbsorbFill"),
			healthMaxHealth = wnd:FindChild("HealthBarBG"),
			healthHealthLabel = wnd:FindChild("HealthBar:Label"),
			castBarLabel = wnd:FindChild("CastBar:Label"),
			castBarCastFill = wnd:FindChild("CastBar:CastFill"),
			vulnerableVulnFill = wnd:FindChild("Vulnerable:VulnFill"),
			questRewards = wnd:FindChild("TargetIcons:TargetGoal:Img"),
			targetMarkerArrow = wnd:FindChild("TargetAndDeathContainer:TargetMarkerArrow"),
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
			tNameplate.wnd.certainDeath:Show(self.db.profile.individual.bShowCertainDeath and nCon == #karConColors and tNameplate.eDisposition ~= Unit.CodeEnumDisposition.Friendly and unitOwner:GetHealth() and unitOwner:ShouldShowNamePlate() and not unitOwner:IsDead())
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
	local unitOwner = tNameplate.unitOwner

	local wndName = tNameplate.wnd.wndName
	local bUseTarget = tNameplate.bIsTarget
	local bShow = self.db.profile.individual.bShowName
	if bUseTarget then
		bShow = self.db.profile.target.bShowName
	end

	if wndName:IsShown() ~= bShow then
		wndName:Show(bShow)
	end

	if bShow then
		local strNewName
		if self.db.profile.individual.bShowTitle then
			strNewName = unitOwner:GetTitleOrName()
		else
			strNewName = unitOwner:GetName()
		end

		if wndName:GetText() ~= strNewName then
			wndName:SetText(strNewName)

			-- Need to consider guild as well for the resize code
			local strNewGuild = unitOwner:GetAffiliationName()
			if unitOwner:GetType() == "Player" and strNewGuild ~= nil and strNewGuild ~= "" then
				strNewGuild = String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), strNewGuild)
			end

			-- Resize
			local wndNameplate = tNameplate.wndNameplate
			local nLeft, nTop, nRight, nBottom = wndNameplate:GetAnchorOffsets()
			local nHalfNameWidth = math.ceil(math.max(Apollo.GetTextWidth("Nameplates", strNewName), Apollo.GetTextWidth("CRB_Interface9_BO", strNewGuild)) / 2)
			nHalfNameWidth = math.max(nHalfNameWidth, self.nHealthWidth / 2)
			--wndNameplate:SetAnchorOffsets(-nHalfNameWidth - 15, nTop, nHalfNameWidth + tNameplate.wnd.nameRewardContainer:ArrangeChildrenHorz(0) + 15, nBottom)
		end
	end
end

function CandyUI_Nameplates:DrawGuild(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local wndGuild = tNameplate.wnd.wndGuild
	local bUseTarget = tNameplate.bIsTarget
	local bShow = self.db.profile.individual.bShowTitle
	if bUseTarget then
		bShow = self.db.profile.target.bShowGuildName
	end

	local strNewGuild = unitOwner:GetAffiliationName()
	if unitOwner:GetType() == "Player" and strNewGuild ~= nil and strNewGuild ~= "" then
		strNewGuild = String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), strNewGuild)
	end

	if bShow and strNewGuild ~= wndGuild:GetText() then
		wndGuild:SetTextRaw(strNewGuild)

		-- Need to consider name as well for the resize code
		local strNewName
		if self.db.profile.individual.bShowTitle then
			strNewName = unitOwner:GetTitleOrName()
		else
			strNewName = unitOwner:GetName()
		end

		-- Resize
		local nLeft, nTop, nRight, nBottom = wndNameplate:GetAnchorOffsets()
		local nHalfNameWidth = math.ceil(math.max(Apollo.GetTextWidth("Nameplates", strNewName), Apollo.GetTextWidth("CRB_Interface9_BO", strNewGuild)) / 2)
		nHalfNameWidth = math.max(nHalfNameWidth, self.nHealthWidth / 2)
		--wndNameplate:SetAnchorOffsets(-nHalfNameWidth - 15, nTop, nHalfNameWidth + tNameplate.wnd.nameRewardContainer:ArrangeChildrenHorz(0) + 15, nBottom)
	end

	wndGuild:Show(bShow and strNewGuild ~= nil and strNewGuild ~= "")
	--wndNameplate:ArrangeChildrenVert(2) -- Must be run if bShow is false as well
end

function CandyUI_Nameplates:DrawLevel(tNameplate)
	local unitOwner = tNameplate.unitOwner

	tNameplate.wnd.level:SetText(unitOwner:GetLevel() or "-")
end

function CandyUI_Nameplates:DrawHealth(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local wndHealth = tNameplate.wnd.health
	local wndHealthBG = tNameplate.wnd.healthBG
	local wndHealthNoShield = tNameplate.wnd.healthNoShield
	local wndHealthNoShieldBG = tNameplate.wnd.healthNoShieldBG
	local wndShield = tNameplate.wnd.shield
	local wndShieldBG = tNameplate.wnd.shieldBG

	if unitOwner:GetHealth() == nil then
		wndHealth:Show(false)
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
		
		wndHealth:Show(true, true)
		wndHealthBG:Show(true, true)
		wndShield:Show(true, true)
		wndShieldBG:Show(true, true)
		wndHealthNoShield:Show(false, true)
		wndHealthNoShieldBG:Show(false, true)
	else
		wndHealthUpdate = wndHealthNoShield
		
		wndHealth:Show(false, true)
		wndHealthBG:Show(false, true)
		wndShield:Show(false, true)
		wndShieldBG:Show(false, true)
		wndHealthNoShield:Show(true, true)
		wndHealthNoShieldBG:Show(true, true)
	end
	
	self:SetBarValue(wndHealthUpdate, 0, unitOwner:GetHealth(), unitOwner:GetMaxHealth())
	if bHasShield then
		self:SetBarValue(wndShield, 0, unitOwner:GetShieldCapacity(), unitOwner:GetShieldCapacityMax())
	end
	--[[
	local bUseTarget = tNameplate.bIsTarget
	if bUseTarget then
		wndHealth:Show(self.db.profile.target.bShowHealth)
	else
		if self.db.profile.healthbar.bShowHealth then
			wndHealth:Show(true)
		elseif self.db.profile.healthbar.bShowHealthDamaged then
			wndHealth:Show(unitOwner:GetHealth() ~= unitOwner:GetMaxHealth())
		else
			wndHealth:Show(false)
		end
	end
	if wndHealth:IsShown() then
		self:HelperDoHealthShieldBar(wndHealth, unitOwner, tNameplate.eDisposition, tNameplate)
	end
	]]
end

function CandyUI_Nameplates:DrawCastBar(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	-- Casting; has some onDraw parameters we need to check
	tNameplate.bIsCasting = unitOwner:ShouldShowCastBar()

	local bShowTarget = tNameplate.bIsTarget
	local wndCastBar = tNameplate.wnd.castBar
	local bShow = tNameplate.bIsCasting and self.db.profile.individual.bShowCastBar
	if tNameplate.bIsCasting and bShowTarget then
		bShow = self.db.profile.target.bShowCastBar
	end

	wndCastBar:Show(bShow)
	if bShow then
		tNameplate.wnd.castBarLabel:SetText(unitOwner:GetCastName())
		tNameplate.wnd.castBarCastFill:SetMax(unitOwner:GetCastDuration())
		tNameplate.wnd.castBarCastFill:SetProgress(unitOwner:GetCastElapsed())
	end
end

function CandyUI_Nameplates:DrawVulnerable(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local bUseTarget = tNameplate.bIsTarget
	local wndVulnerable = tNameplate.wnd.vulnerable

	local bIsVulnerable = false
	if (not bUseTarget and (self.db.profile.healthbar.bShowHealth or self.db.profile.healthbar.bShowHealthDamaged)) or (bUseTarget and self.db.profile.target.bShowHealth) then
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
	local unitOwner = tNameplate.unitOwner

	local bUseTarget = tNameplate.bIsTarget
	local bShow = self.db.profile.individual.bShowRewards
	if bUseTarget then
		bShow = self.db.profile.target.bShowRewards
	end

	tNameplate.wnd.questRewards:Show(bShow)
	local tRewardsData = tNameplate.wnd.questRewards:GetData()
	if bShow and tRewardsData ~= nil and tRewardsData.nIcons ~= nil and tRewardsData.nIcons > 0 then
		local strName = tNameplate.wnd.wndName:GetText()
		local nNameWidth = Apollo.GetTextWidth("CRB_Interface9_BBO", strName)
		local nHalfNameWidth = nNameWidth / 2

		local wndnameRewardContainer = tNameplate.wnd.nameRewardContainer
		local nLeft, nTop, nRight, nBottom = wndnameRewardContainer:GetAnchorOffsets()
		--wndnameRewardContainer:SetAnchorOffsets(nHalfNameWidth, nTop, nHalfNameWidth + wndnameRewardContainer:ArrangeChildrenHorz(0), nBottom)
	end
end

function CandyUI_Nameplates:DrawTargeting(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local bUseTarget = tNameplate.bIsTarget

	local bShowTargetMarkerArrow = bUseTarget and self.db.profile.target.bShowMarker and not tNameplate.wnd.health:IsShown()
	tNameplate.wnd.targetMarkerArrow:SetSprite(karDisposition.tTargetSecondary[tNameplate.eDisposition])
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
		bInRange = nDistance < (self.db.profile.general.nMaxRange * self.db.profile.general.nMaxRange) -- squaring for quick maths
		return bInRange
	end
end

function CandyUI_Nameplates:HelperVerifyVisibilityOptions(tNameplate)
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local eDisposition = tNameplate.eDisposition

	local bHiddenUnit = not unitOwner:ShouldShowNamePlate()
	if bHiddenUnit and not tNameplate.bIsTarget then
		return false
	end

	if (self.bUseOcclusion and tNameplate.bOccluded) or not tNameplate.bOnScreen then
		return false
	end

	if tNameplate.bGibbed or tNameplate.bSpeechBubble then
		return false
	end

	local bShowNameplate = false

	if self.db.profile.general.bShowMainObjective and tNameplate.bIsObjective then
		bShowNameplate = true
	end

	if self.db.profile.general.bShowMainGroup and unitOwner:IsInYourGroup() then
		bShowNameplate = true
	end

	if self.db.profile.disposition.bShowDispositionHostile and eDisposition == Unit.CodeEnumDisposition.Hostile then
		bShowNameplate = true
	end

	if self.db.profile.disposition.bShowDispositionNeutral and eDisposition == Unit.CodeEnumDisposition.Neutral then
		bShowNameplate = true
	end

	if self.db.profile.disposition.bShowDispositionFriendly and eDisposition == Unit.CodeEnumDisposition.Friendly then
		bShowNameplate = true
	end

	if self.db.profile.disposition.bShowDispositionFriendlyPlayer and eDisposition == Unit.CodeEnumDisposition.Friendly and unitOwner:GetType() == "Player" then
		bShowNameplate = true
	end

	local tActivation = unitOwner:GetActivationState()

	if self.db.profile.general.bShowVendor and tActivation.Vendor ~= nil then
		bShowNameplate = true
	end

	if self.db.profile.general.bShowTaxi and (tActivation.FlightPathSettler ~= nil or tActivation.FlightPath ~= nil or tActivation.FlightPathNew) then
		bShowNameplate = true
	end

	if self.db.profile.general.bShowOrganization and tNameplate.bIsGuildMember then
		bShowNameplate = true
	end

	if self.db.profile.general.bShowMainObjective then
		-- QuestGivers too
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

	if bShowNameplate then
		bShowNameplate = not (self.bPlayerInCombat and self.db.profile.general.bHideCombatNonTargets)
	end

	if unitOwner:IsThePlayer() then
		if self.db.profile.general.bShowMyNameplate and not unitOwner:IsDead() then
			bShowNameplate = true
		else
			bShowNameplate = false
		end
	end

	return bShowNameplate or tNameplate.bIsTarget
end

function CandyUI_Nameplates:HelperDoHealthShieldBar(wndHealth, unitOwner, eDisposition, tNameplate)
	local nVulnerabilityTime = unitOwner:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)

	if unitOwner:GetType() == "Simple" or unitOwner:GetHealth() == nil then
		tNameplate.wnd.healthMaxHealth:SetAnchorOffsets(self.nFrameLeft, self.nFrameTop, self.nFrameRight, self.nFrameBottom)
		tNameplate.wnd.healthHealthLabel:SetText("")
		return
	end

	local nHealthCurr 	= unitOwner:GetHealth()
	local nHealthMax 	= unitOwner:GetMaxHealth()
	local nShieldCurr 	= unitOwner:GetShieldCapacity()
	local nShieldMax 	= unitOwner:GetShieldCapacityMax()
	local nAbsorbCurr 	= 0
	local nAbsorbMax 	= unitOwner:GetAbsorptionMax()
	if nAbsorbMax > 0 then
		nAbsorbCurr = unitOwner:GetAbsorptionValue() -- Since it doesn't clear when the buff drops off
	end
	local nTotalMax = nHealthMax + nShieldMax + nAbsorbMax

	if unitOwner:IsDead() then
		nHealthCurr = 0
	end

	-- Scaling
	--[[local nPointHealthRight = self.nFrameR * (nHealthCurr / nTotalMax) -
	local nPointShieldRight = self.nFrameR * ((nHealthCurr + nShieldMax) / nTotalMax)
	local nPointAbsorbRight = self.nFrameR * ((nHealthCurr + nShieldMax + nAbsorbMax) / nTotalMax)--]]

	local nPointHealthRight = self.nFrameLeft + (self.nHealthWidth * (nHealthCurr / nTotalMax)) -- applied to the difference between L and R
	local nPointShieldRight = self.nFrameLeft + (self.nHealthWidth * ((nHealthCurr + nShieldMax) / nTotalMax))
	local nPointAbsorbRight = self.nFrameLeft + (self.nHealthWidth * ((nHealthCurr + nShieldMax + nAbsorbMax) / nTotalMax))


	if nShieldMax > 0 and nShieldMax / nTotalMax < 0.2 then
		local nMinShieldSize = 0.2 -- HARDCODE: Minimum shield bar length is 20% of total for formatting
		--nPointHealthRight = self.nFrameR * math.min(1-nMinShieldSize, nHealthCurr / nTotalMax) -- Health is normal, but caps at 80%
		--nPointShieldRight = self.nFrameR * math.min(1, (nHealthCurr / nTotalMax) + nMinShieldSize) -- If not 1, the size is thus healthbar + hard minimum

		nPointHealthRight = self.nFrameLeft + (self.nHealthWidth*(math.min(1 - nMinShieldSize, nHealthCurr / nTotalMax)))
		nPointShieldRight = self.nFrameLeft + (self.nHealthWidth*(math.min(1, (nHealthCurr / nTotalMax) + nMinShieldSize)))
	end

	-- Resize
	tNameplate.wnd.healthShieldFill:EnableGlow(nShieldCurr > 0 and nShieldCurr ~= nShieldMax)
	self:SetBarValue(tNameplate.wnd.healthShieldFill, 0, nShieldCurr, nShieldMax) -- Only the Curr Shield really progress fills
	self:SetBarValue(tNameplate.wnd.healthAbsorbFill, 0, nAbsorbCurr, nAbsorbMax)
	tNameplate.wnd.healthMaxHealth:SetAnchorOffsets(self.nFrameLeft, self.nFrameTop, nPointHealthRight, self.nFrameBottom)
	tNameplate.wnd.healthMaxShield:SetAnchorOffsets(nPointHealthRight - 1, self.nFrameTop, nPointShieldRight, self.nFrameBottom)
	tNameplate.wnd.healthMaxAbsorb:SetAnchorOffsets(nPointShieldRight - 1, self.nFrameTop, nPointAbsorbRight, self.nFrameBottom)

	-- Bars
	tNameplate.wnd.healthShieldFill:Show(nHealthCurr > 0)
	tNameplate.wnd.healthMaxHealth:Show(nHealthCurr > 0)
	tNameplate.wnd.healthMaxShield:Show(nHealthCurr > 0 and nShieldMax > 0)
	tNameplate.wnd.healthMaxAbsorb:Show(nHealthCurr > 0 and nAbsorbMax > 0)

	-- Text
	local strHealthMax = self:HelperFormatBigNumber(nHealthMax)
	local strHealthCurr = self:HelperFormatBigNumber(nHealthCurr)
	local strShieldCurr = self:HelperFormatBigNumber(nShieldCurr)

	local strText = nHealthMax == nHealthCurr and strHealthMax or String_GetWeaselString(Apollo.GetString("TargetFrame_HealthText"), strHealthCurr, strHealthMax)
	if nShieldMax > 0 and nShieldCurr > 0 then
		strText = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthShieldText"), strText, strShieldCurr)
	end
	tNameplate.wnd.healthHealthLabel:SetText(strText)

	-- Sprite
	if nVulnerabilityTime and nVulnerabilityTime > 0 then
		tNameplate.wnd.healthMaxHealth:SetSprite("CRB_Nameplates:sprNP_PurpleProg")
	else
		tNameplate.wnd.healthMaxHealth:SetSprite(karDisposition.tHealthBar[eDisposition])
	end

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
		},
		disposition = {
			bShowDispositionHostile = true,
			bShowDispositionNeutral = false,
			bShowDispositionFriendly = false,
			bShowDispositionFriendlyPlayer = false,
		},
		individual = {
			bShowName = true,
			bShowTitle = true,
			bShowCertainDeath = true,
			bShowCastBar = false,
			bShowRewards = true,
		},
		healthbar = {
			bShowHealth = false,
			bShowHealthDamaged = true,
		},
		target = {
			bShowMarker = true,
			bShowName = true,
			bShowRewards = true,
			bShowGuildName = true,
			bShowHealth = true,
			bShowRange = false,
			bShowCastBar = true
		},
		rewards = {
			bShowRewardTypeQuest = true,
			bShowRewardTypeMission = true,
			bShowRewardTypeAchievement = false,
			bShowRewardTypeChallenge = true,
			bShowRewardTypeReputation = false,
			bShowRewardTypePublicEvent = true,
			bShowRivals = true,
			bShowFriends = true
		},
	},
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
--General
	local generalControls = self.wndControls:FindChild("GeneralControls")
--Player
	local playerControls = nil--self.wndControls:FindChild("PlayerControls")
	
end

---------------------------------------------------------------------------------------------------
-- OptionsControlsList Functions
---------------------------------------------------------------------------------------------------
function CandyUI_Nameplates:OnShowMainObjectiveClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowMainObjective = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowMainGroupClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowMainGroup = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowOrganizationClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowOrganization = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowVendorClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowVendor = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowTaxiClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowTaxi = wndControl:IsChecked()
end
--disp
function CandyUI_Nameplates:OnShowDispositionHostileClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.disposition.bShowDispositionHostile = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowDispositionNeutralClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.disposition.bShowDispositionNeutral = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowDispositionFriendlyClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.disposition.bShowDispositionFriendly = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnShowDispositionFriendlyPlayerClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.disposition.bShowDispositionFriendlyPlayer = wndControl:IsChecked()
end
--player
function CandyUI_Nameplates:OnPlayerShowNameplateClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowMyNameplate = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnPlayerShowNameClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.individual.bShowName = wndControl:IsChecked()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawName(tNameplate)
	end
end

function CandyUI_Nameplates:OnPlayerShowTitleClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.individual.bShowTitle = wndControl:IsChecked()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawGuild(tNameplate)
	end
end

function CandyUI_Nameplates:OnPlayerShowCertainDeathClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.individual.bShowCertainDeath = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnPlayerShowCastBarClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.individual.bShowCastBar = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnPlayerShowRewardsClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.individual.bShowRewards = wndControl:IsChecked()
	self:RequestUpdateAllNameplateRewards()
end

function CandyUI_Nameplates:OnPlayerShowHealthClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.healthbar.bShowHealth = wndControl:IsChecked()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawLevel(tNameplate)
	end
end

function CandyUI_Nameplates:OnPlayerShowHealthDamagedClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.healthbar.bShowHealthDamaged = wndControl:IsChecked()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawLevel(tNameplate)
	end
end
--target
function CandyUI_Nameplates:OnTargetShowMarkerClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.target.bShowMarker = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnTargetShowNameClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.target.bShowName = wndControl:IsChecked()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawName(tNameplate)
	end
end

function CandyUI_Nameplates:OnTargetShowRewardsClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.target.bShowRewards = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnTargetShowGuildNameClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.target.bShowGuildName = wndControl:IsChecked()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawGuild(tNameplate)
	end
end

function CandyUI_Nameplates:OnTargetShowHealthClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.target.bShowHealth = wndControl:IsChecked() --Not Coded
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawLevel(tNameplate)
	end
end

function CandyUI_Nameplates:OnTargetShowRangeClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.target.bShowRange = wndControl:IsChecked() --Not Coded
end

function CandyUI_Nameplates:OnTargetShowCastBarClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.target.bShowCastBar = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnHideCombatNonTargetsClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bHideCombatNonTargets = wndControl:IsChecked()
end

function CandyUI_Nameplates:OnMaxRangeReturn( wndHandler, wndControl, strText )
	local val = round(tonumber(strText))
	self.db.profile.general.nMaxRange = val
end
--rewards
function CandyUI_Nameplates:OnRewardsShowQuestClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.rewards.bShowRewardTypeQuest = wndControl:IsChecked()
	self:RequestUpdateAllNameplateRewards()
end

function CandyUI_Nameplates:OnRewardsShowMissionClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.rewards.bShowRewardTypeMission = wndControl:IsChecked()
	self:RequestUpdateAllNameplateRewards()
end

function CandyUI_Nameplates:OnRewardsShowAchievementClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.rewards.bShowRewardTypeAchievement = wndControl:IsChecked()
	self:RequestUpdateAllNameplateRewards()
end

function CandyUI_Nameplates:OnRewardsShowChallengeClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.rewards.bShowRewardTypeChallenge = wndControl:IsChecked()
	self:RequestUpdateAllNameplateRewards()
end

function CandyUI_Nameplates:OnRewardsShowReputationClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.rewards.bShowRewardTypeReputation = wndControl:IsChecked()
	self:RequestUpdateAllNameplateRewards()
end

function CandyUI_Nameplates:OnRewardsShowPublicEventClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.rewards.bShowRewardTypePublicEvent = wndControl:IsChecked()
	self:RequestUpdateAllNameplateRewards()
end

function CandyUI_Nameplates:OnRewardsShowRivalsClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.rewards.bShowRivals = wndControl:IsChecked()
	self:RequestUpdateAllNameplateRewards()
end

function CandyUI_Nameplates:OnRewardsShowFriendsClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.rewards.bShowFriends = wndControl:IsChecked()
	self:RequestUpdateAllNameplateRewards()
end

function CandyUI_Nameplates:OnUseOcclusionClick( wndHandler, wndControl, eMouseButton )
	local bUseOcclusion = wndControl:IsChecked()
	Apollo.SetConsoleVariable("ui.occludeNameplatePositions", bUseOcclusion)
	self.bUseOcclusion = bUseOcclusion
	self.db.profile.general.bUseOcclusion = bUseOcclusion
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Nameplates Instance
-----------------------------------------------------------------------------------------------
local CandyUI_NameplatesInst = CandyUI_Nameplates:new()
CandyUI_NameplatesInst:Init()
