-----------------------------------------------------------------------------------------------
-- Client Lua Script for CandyUI_Minimap
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
-- Needed until Carbine copies this to their WelcomeWindowLib
require "LiveEventsLib"
require "LiveEvent"
require "DialogSys"
require "Quest"
require "QuestLib"
require "MailSystemLib"
require "Sound"
require "GameLib"
require "Tooltip"
require "XmlDoc"
require "PlayerPathLib"
require "Unit"
require "PublicEvent"
require "PublicEventObjective"
require "FriendshipLib"
require "CraftingLib"
 
-----------------------------------------------------------------------------------------------
-- CandyUI_Minimap Module Definition
-----------------------------------------------------------------------------------------------
local CandyUI_Minimap = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
-- TODO: Distinguish markers for different nodes from each other
local kstrMiningNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Mining"
local kcrMiningNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrRelicNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Relic"
local kcrRelicNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrFarmingNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Plant"
local kcrFarmingNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrSurvivalNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Tree"
local kcrSurvivalNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrFishingNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Fishing"
local kcrFishingNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local ktPvPZoneTypes =
{
	[GameLib.CodeEnumZonePvpRules.None] 					= "",
	[GameLib.CodeEnumZonePvpRules.ExileStronghold]			= Apollo.GetString("MiniMap_Exile"),
	[GameLib.CodeEnumZonePvpRules.DominionStronghold] 		= Apollo.GetString("MiniMap_Dominion"),
	[GameLib.CodeEnumZonePvpRules.Sanctuary] 				= Apollo.GetString("MiniMap_Sanctuary"),
	[GameLib.CodeEnumZonePvpRules.Pvp] 						= Apollo.GetString("MiniMap_PvP"),
	[GameLib.CodeEnumZonePvpRules.ExilePVPStronghold] 		= Apollo.GetString("MiniMap_Exile"),
	[GameLib.CodeEnumZonePvpRules.DominionPVPStronghold] 	= Apollo.GetString("MiniMap_Dominion"),
}

local ktInstanceSettingTypeStrings =
{
	Veteran = Apollo.GetString("MiniMap_Veteran"),
	Rallied = Apollo.GetString("MiniMap_Rallied"),
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
function CandyUI_Minimap:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function CandyUI_Minimap:CreateOverlayObjectTypes()
	self.eObjectTypePublicEvent			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypePublicEventKill		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeChallenge			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypePing				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeCityDirection		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeHazard 				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestReward 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestReceiving 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestNew 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestNewSoon 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestTarget 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestKill	 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeTradeskills 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeVendor 				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeAuctioneer 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeCommodity 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeInstancePortal 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeBindPointActive 	= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeBindPointInactive 	= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeMiningNode 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeRelicHunterNode 	= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeSurvivalistNode 	= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeFarmingNode 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeFishingNode 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeVendorFlight 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeFlightPathNew		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeNeutral	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeHostile	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeFriend	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeRival	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeTrainer	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeGroupMember			= self.wndMiniMap:CreateOverlayType()
	self.eObjectPvPMarkers				= self.wndMiniMap:CreateOverlayType()
end

function CandyUI_Minimap:BuildCustomMarkerInfo()
	self.tMinimapMarkerInfo =
	{
		PvPExileCarry			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_ExileCarry",			bFixedSizeMedium = true	},
		PvPDominionCarry		= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_DominionCarry",			bFixedSizeMedium = true	},
		PvPNeutralCarry			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_NeutralCarry",			bFixedSizeMedium = true	},
		PvPExileCap1			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_ExileCap",			bFixedSizeMedium = true	},
		PvPDominionCap1			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_DominionCap",			bFixedSizeMedium = true	},
		PvPNeutralCap1			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_NeutralCap",			bFixedSizeMedium = true	},
		PvPExileCap2			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_ExileCap",			bFixedSizeMedium = true	},
		PvPDominionCap2			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_DominionCap",			bFixedSizeMedium = true	},
		PvPNeutralCap2			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_NeutralCap",			bFixedSizeMedium = true	},
		PvPBattleAlert			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_BattleAlert",	bFixedSizeMedium = true	},
		IronNode				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		TitaniumNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		ZephyriteNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		PlatinumNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		HydrogemNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		XenociteNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		ShadeslateNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		GalactiumNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		NovaciteNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		StandardRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		AcceleratedRelicNode	= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		AdvancedRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		DynamicRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		KineticRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		SpirovineNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		BladeleafNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		YellowbellNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		PummelgranateNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SerpentlilyNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		GoldleafNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		HoneywheatNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		CrowncornNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		CoralscaleNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LogicleafNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		StoutrootNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		GlowmelonNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		FaerybloomNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode,	crEdge = kcrFarmingNode },
		WitherwoodNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode,	crEdge = kcrFarmingNode },
		FlamefrondNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		GrimgourdNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MourningstarNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		BloodbriarNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		OctopodNode				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		HeartichokeNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SmlGrowthshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MedGrowthshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LrgGrowthshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SmlHarvestshroomNode	= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MedHarvestshroomNode	= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LrgHarvestshroomNode	= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SmlRenewshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MedRenewshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LrgRenewshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		AlgorocTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		CelestionTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		DeraduneTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		EllevarTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		GalerasTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		AuroriaTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		WhitevaleTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		DreadmoorTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		FarsideTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		CoralusTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		MurkmireTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		WilderrunTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		MalgraveTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		HalonRingTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		GrimvaultTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		SchoolOfFishNode		= { nOrder = 100, 	objectType = self.eObjectTypeFishingNode,		strIcon = kstrFishingNodeIcon,	crObject = kcrFishingNode,	crEdge = kcrFishingNode },
		Friend					= { nOrder = 2, 	objectType = self.eObjectTypeFriend, 			strIcon = "IconSprites:Icon_Windows_UI_CRB_Friend",	bNeverShowOnEdge = true, bShown, bFixedSizeMedium = true },
		Rival					= { nOrder = 3, 	objectType = self.eObjectTypeRival, 			strIcon = "IconSprites:Icon_MapNode_Map_Rival", 	bNeverShowOnEdge = true, bShown, bFixedSizeMedium = true },
		Trainer					= { nOrder = 4, 	objectType = self.eObjectTypeTrainer, 			strIcon = "IconSprites:Icon_MapNode_Map_Trainer", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		QuestKill				= { nOrder = 5, 	objectType = self.eObjectTypeQuestKill, 		strIcon = "sprMM_TargetCreature", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		QuestTarget				= { nOrder = 6,		objectType = self.eObjectTypeQuestTarget, 		strIcon = "sprMM_TargetObjective", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		PublicEventKill			= { nOrder = 7,		objectType = self.eObjectTypePublicEventKill, 	strIcon = "sprMM_TargetCreature", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		PublicEventTarget		= { nOrder = 8,		objectType = self.eObjectTypePublicEventTarget, strIcon = "sprMM_TargetObjective", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		QuestReward				= { nOrder = 9,		objectType = self.eObjectTypeQuestReward, 		strIcon = "sprMM_QuestCompleteUntracked", 	bNeverShowOnEdge = true },
		QuestRewardSoldier		= { nOrder = 10,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Soldier_Accepted", 	bNeverShowOnEdge = true },
		QuestRewardSettler		= { nOrder = 11,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Settler_Accepted", 	bNeverShowOnEdge = true },
		QuestRewardScientist	= { nOrder = 12,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Scientist_Accepted", 	bNeverShowOnEdge = true },
		QuestRewardExplorer		= { nOrder = 13,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Explorer_Accepted", 	bNeverShowOnEdge = true },
		QuestNew				= { nOrder = 14,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true },
		QuestNewSoldier			= { nOrder = 15,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestNewSettler			= { nOrder = 16,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestNewScientist		= { nOrder = 17,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestNewExplorer		= { nOrder = 18,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestNewMain			= { nOrder = 19,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true },
		QuestNewMainSoldier		= { nOrder = 20,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestNewMainSettler		= { nOrder = 21,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestNewMainScientist	= { nOrder = 22,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestNewMainExplorer	= { nOrder = 23,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestNewRepeatable		= { nOrder = 24,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true },
		QuestNewRepeatableSoldier = { nOrder = 25,	objectType = self.eObjectTypeQuestNew, 		strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestNewRepeatableSettler = { nOrder = 26,	objectType = self.eObjectTypeQuestNew, 		strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestNewRepeatableScientist = { nOrder = 27,objectType = self.eObjectTypeQuestNew, 		strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestNewRepeatableExplorer = { nOrder = 28,	objectType = self.eObjectTypeQuestNew, 		strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestReceiving			= { nOrder = 29,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "sprMM_QuestCompleteOngoing", 	bNeverShowOnEdge = true },
		QuestReceivingSoldier	= { nOrder = 30,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestReceivingSettler	= { nOrder = 31,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestReceivingScientist	= { nOrder = 32,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestReceivingExplorer	= { nOrder = 33,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestNewSoon			= { nOrder = 34,	objectType = self.eObjectTypeQuestNewSoon, 		strIcon = "IconSprites:Icon_MapNode_Map_Quest_Disabled", 	bNeverShowOnEdge = true },
		QuestNewMainSoon		= { nOrder = 35,	objectType = self.eObjectTypeQuestNewSoon, 		strIcon = "IconSprites:Icon_MapNode_Map_Quest_Disabled", 	bNeverShowOnEdge = true },
		ConvertItem				= { nOrder = 36,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_ResourceConversion", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		ConvertRep				= { nOrder = 37,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Reputation", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		Vendor					= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		Mail					= { nOrder = 39,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Mailbox", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		CityDirections			= { nOrder = 40,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_CityDirections", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		Dye						= { nOrder = 41,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_DyeSpecialist", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		FlightPathSettler		= { nOrder = 42,	objectType = self.eObjectTypeVendorFlight, 		strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Flight", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		FlightPath				= { nOrder = 43,	objectType = self.eObjectTypeVendorFlightPathNew, strIcon = "IconSprites:Icon_MapNode_Map_Taxi_Undiscovered", bNeverShowOnEdge = true, bFixedSizeMedium = true },
		FlightPathNew			= { nOrder = 44,	objectType = self.eObjectTypeVendorFlight, 		strIcon = "IconSprites:Icon_MapNode_Map_Taxi", 	bNeverShowOnEdge = true },
		TalkTo					= { nOrder = 45,	objectType = self.eObjectTypeQuestTarget, 		strIcon = "IconSprites:Icon_MapNode_Map_Chat", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		InstancePortal			= { nOrder = 46,	objectType = self.eObjectTypeInstancePortal, 	strIcon = "IconSprites:Icon_MapNode_Map_Portal", 	bNeverShowOnEdge = true },
		BindPoint				= { nOrder = 47,	objectType = self.eObjectTypeBindPointInactive, strIcon = "IconSprites:Icon_MapNode_Map_Gate", 	bNeverShowOnEdge = true },
		BindPointCurrent		= { nOrder = 48,	objectType = self.eObjectTypeBindPointActive, 	strIcon = "IconSprites:Icon_MapNode_Map_Gate", 	bNeverShowOnEdge = true },
		TradeskillTrainer		= { nOrder = 49,	objectType = self.eObjectTypeTradeskills, 		strIcon = "IconSprites:Icon_MapNode_Map_Tradeskill", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		CraftingStation			= { nOrder = 50,	objectType = self.eObjectTypeTradeskills, 		strIcon = "IconSprites:Icon_MapNode_Map_Tradeskill", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		CommodityMarketplace	= { nOrder = 51,	objectType = self.eObjectTypeCommodities, 		strIcon = "IconSprites:Icon_MapNode_Map_CommoditiesExchange", bNeverShowOnEdge = true },
		ItemAuctionhouse		= { nOrder = 52,	objectType = self.eObjectTypeAuctioneer, 		strIcon = "IconSprites:Icon_MapNode_Map_AuctionHouse", 	bNeverShowOnEdge = true },
		SettlerImprovement		= { nOrder = 53,	objectType = GameLib.CodeEnumMapOverlayType.PathObjective, strIcon = "CRB_MinimapSprites:sprMM_SmallIconSettler", bNeverShowOnEdge = true },
		Neutral					= { nOrder = 151,	objectType = self.eObjectTypeNeutral, 			strIcon = "ClientSprites:MiniMapMarkerTiny", 	bNeverShowOnEdge = true, bShown = false, crObject = ApolloColor.new("xkcdBrightYellow") },
		Hostile					= { nOrder = 150,	objectType = self.eObjectTypeHostile, 			strIcon = "ClientSprites:MiniMapMarkerTiny", 	bNeverShowOnEdge = true, bShown = false, crObject = ApolloColor.new("xkcdBrightRed") },
		GroupMember				= { nOrder = 1,		objectType = self.eObjectTypeGroupMember, 		strIcon = "IconSprites:Icon_MapNode_Map_GroupMember", 	bFixedSizeLarge = true },
		Bank					= { nOrder = 54,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Bank", 	bNeverShowOnEdge = true, bFixedSizeLarge = true },
		GuildBank				= { nOrder = 56,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Bank", 	bNeverShowOnEdge = true, bFixedSizeLarge = true, crObject = ApolloColor.new("yellow") },
		GuildRegistrar			= { nOrder = 55,	objectType = self.eObjectTypeVendor, 			strIcon = "CRB_MinimapSprites:sprMM_Group", bNeverShowOnEdge = true, bFixedSizeLarge = true, crObject = ApolloColor.new("yellow") },
		VendorGeneral			= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorArmor				= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Armor",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorConsumable		= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Consumable",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorElderGem			= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_ElderGem",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorHousing			= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Housing",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorMount				= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Mount",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorRenown			= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Renown",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorReputation		= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Reputation",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorResourceConversion= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_ResourceConversion",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorTradeskill		= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Tradeskill",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorWeapon			= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Weapon",		bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorPvPArena			= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Prestige_Arena",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorPvPBattlegrounds	= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Prestige_Battlegrounds",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorPvPWarplots		= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Prestige_Warplot",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
	}
end

function CandyUI_Minimap:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
		"CandyUI"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CandyUI_Minimap OnLoad
-----------------------------------------------------------------------------------------------
function CandyUI_Minimap:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CandyUI_Minimap.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, kcuiMMDefaults)
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Minimap OnDocLoaded
-----------------------------------------------------------------------------------------------
function CandyUI_Minimap:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	
		if self.db.char.currentProfile == nil and self.db:GetCurrentProfile() ~= nil then
			self.db.char.currentProfile = self.db:GetCurrentProfile()
		elseif self.db.char.currentProfile ~= nil and self.db.char.currentProfile ~= self.db:GetCurrentProfile() then
			self.db:SetProfile(self.db.char.currentProfile)
		end	
			
		Apollo.LoadSprites("Sprites.xml")
		
		Apollo.RegisterEventHandler("WindowManagementReady", 				"OnWindowManagementReady", self)
	
		Apollo.RegisterEventHandler("CharacterCreated", 					"OnCharacterCreated", self)
		Apollo.RegisterEventHandler("OptionsUpdated_QuestTracker", 			"OnOptionsUpdated", self)
		Apollo.RegisterEventHandler("VarChange_ZoneName", 					"OnChangeZoneName", self)
		Apollo.RegisterEventHandler("SubZoneChanged", 						"OnChangeZoneName", self)
	
		Apollo.RegisterEventHandler("QuestObjectiveUpdated", 				"OnQuestStateChanged", self)
		Apollo.RegisterEventHandler("QuestStateChanged", 					"OnQuestStateChanged", self)
		Apollo.RegisterEventHandler("GenericEvent_QuestTrackerRenumbered", 	"OnQuestStateChanged", self)

		Apollo.RegisterEventHandler("FriendshipAdd", 						"OnFriendshipAdd", self)
		Apollo.RegisterEventHandler("FriendshipRemove", 					"OnFriendshipRemove", self)
		Apollo.RegisterEventHandler("FriendshipAccountFriendsRecieved",  	"OnFriendshipAccountFriendsRecieved", self)
		Apollo.RegisterEventHandler("FriendshipAccountFriendRemoved",   	"OnFriendshipAccountFriendRemoved", self)

		Apollo.RegisterEventHandler("ReputationChanged",   					"OnReputationChanged", self)

		Apollo.RegisterEventHandler("UnitCreated", 							"OnUnitCreated", self)
		Apollo.RegisterEventHandler("UnitDestroyed", 						"OnUnitDestroyed", self)
		Apollo.RegisterEventHandler("UnitActivationTypeChanged", 			"OnUnitChanged", self)
		Apollo.RegisterEventHandler("UnitMiniMapMarkerChanged", 			"OnUnitChanged", self)
		Apollo.RegisterEventHandler("ChallengeFailArea", 					"OnFailChallenge", self)
		Apollo.RegisterEventHandler("ChallengeFailTime", 					"OnFailChallenge", self)
		Apollo.RegisterEventHandler("ChallengeAbandonConfirmed", 			"OnRemoveChallengeIcon", self)
		Apollo.RegisterEventHandler("ChallengeActivate", 					"OnAddChallengeIcon", self)
		Apollo.RegisterEventHandler("ChallengeFlashStartLocation", 			"OnFlashChallengeIcon", self)
		Apollo.RegisterEventHandler("PlayerPathMissionActivate", 			"OnPlayerPathMissionActivate", self)
		Apollo.RegisterEventHandler("PlayerPathMissionUpdate", 				"OnPlayerPathMissionActivate", self)
		Apollo.RegisterEventHandler("PlayerPathMissionDeactivate", 			"OnPlayerPathMissionDeactivate", self)
		Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapStarted", 	"OnPlayerPathMissionActivate", self)
		Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapFailed", 	"OnPlayerPathMissionActivate", self)
		Apollo.RegisterEventHandler("PublicEventStart", 					"OnPublicEventUpdate", self)
		Apollo.RegisterEventHandler("PublicEventObjectiveUpdate", 			"OnPublicEventObjectiveUpdate", self)
		Apollo.RegisterEventHandler("PublicEventEnd", 						"OnPublicEventEnd", self)
		Apollo.RegisterEventHandler("PublicEventLeave",						"OnPublicEventEnd", self)
		Apollo.RegisterEventHandler("PublicEventLocationAdded", 			"OnPublicEventUpdate", self)
		Apollo.RegisterEventHandler("PublicEventLocationRemoved", 			"OnPublicEventUpdate", self)
		Apollo.RegisterEventHandler("PublicEventObjectiveLocationAdded", 	"OnPublicEventObjectiveUpdate", self)
		Apollo.RegisterEventHandler("PublicEventObjectiveLocationRemoved", 	"OnPublicEventObjectiveUpdate", self)
	
		Apollo.RegisterEventHandler("CityDirectionMarked",					"OnCityDirectionMarked", self)
		Apollo.RegisterEventHandler("ZoneMap_TimeOutCityDirectionEvent",	"OnZoneMap_TimeOutCityDirectionEvent", self)
	
		Apollo.RegisterEventHandler("MapGhostMode", 						"OnMapGhostMode", self)
		Apollo.RegisterEventHandler("ToggleGhostModeMap",					"OnToggleGhostModeMap", self) -- for key input toggle on/off
		Apollo.RegisterEventHandler("HazardShowMinimapUnit", 				"OnHazardShowMinimapUnit", self)
		Apollo.RegisterEventHandler("HazardRemoveMinimapUnit", 				"OnHazardRemoveMinimapUnit", self)
		Apollo.RegisterEventHandler("ZoneMapPing", 							"OnMapPing", self)
		Apollo.RegisterEventHandler("UnitPvpFlagsChanged", 					"OnUnitPvpFlagsChanged", self)
	
		Apollo.RegisterEventHandler("PlayerLevelChange",					"UpdateHarvestableNodes", self)
		
		--Bag Text
		Apollo.RegisterEventHandler("UpdateInventory",						"OnUpdateInventory", self)
	
		Apollo.RegisterTimerHandler("ChallengeFlashIconTimer", 				"OnStopChallengeFlashIcon", self)
		Apollo.RegisterTimerHandler("OneSecTimer",							"OnOneSecTimer", self)
		
		Apollo.RegisterTimerHandler("PingTimer",							"OnPingTimer", self)
		Apollo.CreateTimer("PingTimer", 1, false)
		Apollo.StopTimer("PingTimer")
		
		Apollo.RegisterTimerHandler("ZoomTimer",							"OnZoomTimer", self)
		Apollo.CreateTimer("ZoomTimer", 1, true)
		Apollo.StopTimer("ZoomTimer")
	
		--Group Events
		Apollo.RegisterEventHandler("Group_Join", 							"OnGroupJoin", self)					-- ()
		Apollo.RegisterEventHandler("Group_Add", 							"OnGroupAdd", self)						-- ( name )
		Apollo.RegisterEventHandler("Group_Invite_Result",					"OnGroupInviteResult", self)			-- ( name, result )
		Apollo.RegisterEventHandler("Group_Remove", 						"OnGroupRemove", self)					-- ( name, result )
		Apollo.RegisterEventHandler("Group_Left", 							"OnGroupLeft", self)					-- ( reason )
		
		self.wndMain 			= Apollo.LoadForm(self.xmlDoc , "Minimap", "FixedHudStratum", self)
		--Size
			--local l, t, r, b = self.wndMain:GetAnchorOffsets()
			--self.wndMain:SetAnchorOffsets(r-(nValue+20), t, r, t-(self.db.profile.general.nSize+46))
		--Opacity
			self.wndMain:SetOpacity(self.db.profile.general.nOpacity)
		
		self.wndMiniMap 		= self.wndMain:FindChild("MapContent")
		self.wndZoneName 		= self.wndMain:FindChild("MapZoneName")
		self.wndPvPFlagName 	= self.wndMain:FindChild("MapZonePvPFlag")
		self.wndRangeLabel 		= self.wndMain:FindChild("RangeToTargetLabel")
		self.wndBottom			= self.wndMain:FindChild("Bottom")
		self.CommButton			= self.wndBottom:FindChild("CallButton")
		
		--Global for Datachron
		g_DatachronButton = self.wndBottom:FindChild("DatachronButton")
		--g_CommButton = self.CommButton
		--g_CommPulseBlue = self.wndBottom:FindChild("CommButtonPulse")
		
		self:UpdateZoneName(GetCurrentZoneName())
		--self.wndMinimapButtons 	= self.wndMain:FindChild("ButtonContainer")
		
		self:CreateOverlayObjectTypes() -- ** IMPORTANT ** This function must run before you do anything involving overlay types!
		self:BuildCustomMarkerInfo()

		self.tChallengeObjects 			= {}
		self.ChallengeFlashingIconId 	= nil
		self.tUnitsShown 				= {}	-- For Quests, PublicEvents, Vendors, Instance Portals, and Bind Points which all use UnitCreated/UnitDestroyed events
		self.tUnitsHidden 				= {}	-- Units that we're tracking but are out of the current subzone
		self.tObjectsShown 				= {} -- For Challenges which use their own events
		self.tObjectsShown.Challenges 	= {}
		self.tPingObjects 				= {}
		self.arResourceNodes			= {}

		self.tGroupMembers 			= {}
		self.tGroupMemberObjects 	= {}
		if not self.tQueuedUnits then
			self.tQueuedUnits = {}--necessary when characters don't have a saved file for minimap
		else
			for idx, unit in pairs(self.tQueuedUnits) do
				self.HandleUnitCreated(unit)
			end
		end
	
		self.unitPlayerDisposition = GameLib.GetPlayerUnit()
		if self.unitPlayerDisposition ~= nil then
			self:OnCharacterCreated()
		end
		
		self:ReloadPublicEvents()
		self:ReloadMissions()
		self:OnQuestStateChanged()
		self:OnUpdateInventory()
		
		
		if g_wndTheMiniMap == nil then
			g_wndTheMiniMap = self.wndMiniMap
		end
	
		GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
  		self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
		self.colorPicker:Show(false, true)
		
		--Check for Options addon
		local bOptionsLoaded = _cui.bOptionsLoaded
		if bOptionsLoaded then
			--Load Options
			self:OnCUIOptionsLoaded()
		else
			--Schedule for later
			Apollo.RegisterEventHandler("CandyUI_Loaded", "OnCUIOptionsLoaded", self)
		end
		
		self.wndMain:SetAnchorOffsets(unpack(self.db.profile.general.tAnchorOffsets))
		
		if self.db.profile.general.fSavedZoomLevel then
			self.wndMiniMap:SetZoomLevel(self.db.profile.general.fSavedZoomLevel)
		end
		
		Apollo.StartTimer("ZoomTimer")
	end
end

function CandyUI_Minimap:OnCUIOptionsLoaded()
	--Load Options
	local wndOptionsControls = Apollo.GetAddon("CandyUI").wndOptions:FindChild("OptionsDialogueControls")
	self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControlsList", wndOptionsControls, self)
	CUI_RegisterOptions("Minimap", self.wndControls)
	self:SetOptions()
end

function CandyUI_Minimap:OnZoomTimer()
	--self.wndMiniMap:SetZoomLevel(self.db.profile.general.fSavedZoomLevel)
	local fZoomLevel = self.wndMiniMap:GetZoomLevel()
	if self.db.profile.general.fSavedZoomLevel ~= fZoomLevel then
		self.db.profile.general.fSavedZoomLevel = fZoomLevel
	end
end

function CandyUI_Minimap:OnUpdateInventory()
	self.wndBottom:FindChild("BagButton:Text"):SetText(GameLib.GetEmptyInventorySlots())
end
-----------------------------------------------------------------------------------------------
-- CandyUI_Minimap Functions
-----------------------------------------------------------------------------------------------
function CandyUI_Minimap:OnCharacterCreated()
	if not self.unitPlayerDisposition then
		self.unitPlayerDisposition = GameLib.GetPlayerUnit()
	end
	local ePath = self.unitPlayerDisposition:GetPlayerPathType()
	
	--Replace these with options
	if ePath == PlayerPathLib.PlayerPathType_Soldier then
		--self.wndMinimapOptions:FindChild("Image_Soldier"):Show(true)
	elseif ePath == PlayerPathLib.PlayerPathType_Explorer then
		--self.wndMinimapOptions:FindChild("Image_Explorer"):Show(true)
	elseif ePath == PlayerPathLib.PlayerPathType_Scientist then
		--self.wndMinimapOptions:FindChild("Image_Scientist"):Show(true)
	elseif ePath == PlayerPathLib.PlayerPathType_Settler then
		--self.wndMinimapOptions:FindChild("Image_Settler"):Show(true)
	end
end

function CandyUI_Minimap:ReloadMissions()
	local epiCurrent = PlayerPathLib.GetCurrentEpisode()
	if epiCurrent then
		for idx, pmCurr in ipairs(epiCurrent:GetMissions()) do
			self:OnPlayerPathMissionActivate(pmCurr)
		end
	end
end

function CandyUI_Minimap:OnChangeZoneName(oVar, strNewZone)
	self:UpdateZoneName(strNewZone)

	-- update mission indicators
	self:ReloadMissions()

	-- update quest indicators on zone change
	self:OnQuestStateChanged()

	-- update public events
	self:ReloadPublicEvents()

	-- update all already shown units
  	if self.tUnitsShown then
		for idx, tCurr in pairs(self.tUnitsShown) do
			if tCurr.unitObject then
				self.wndMiniMap:RemoveUnit(tCurr.unitObject)
				self.tUnitsShown[tCurr.unitObject:GetId()] = nil
				self:OnUnitCreated(tCurr.unitObject)
			end
		end
	end

	-- check for any units that are now back in the subzone
  	if self.tUnitsHidden then
		for idx, tCurr in pairs(self.tUnitsHidden) do
			if tCurr.unitObject then
				self.tUnitsHidden[tCurr.unitObject:GetId()] = nil
				self:OnUnitCreated(tCurr.unitObject)
			end
		end
	end

	self:OnOneSecTimer()

end

function CandyUI_Minimap:UpdateZoneName(strZoneName)
	if strZoneName == nil then
		return
	end

	local tInstanceSettingsInfo = GameLib.GetInstanceSettings()

	local strDifficulty = nil
	if tInstanceSettingsInfo.eWorldDifficulty == GroupLib.Difficulty.Veteran then
		strDifficulty = ktInstanceSettingTypeStrings.Veteran
	end

	local strScaled = nil
	if tInstanceSettingsInfo.bWorldForcesLevelScaling == true then
		strScaled = ktInstanceSettingTypeStrings.Rallied
	end

	local strAdjustedZoneName = strZoneName
	if strDifficulty and strScaled then
		strAdjustedZoneName = strZoneName .. " (" .. strDifficulty .. "-" .. strScaled .. ")"
	elseif strDifficulty then
		strAdjustedZoneName = strZoneName .. " (" .. strDifficulty .. ")"
	elseif strScaled then
		strAdjustedZoneName = strZoneName .. " (" .. strScaled .. ")"
	end

	self.wndZoneName:SetText(strAdjustedZoneName)
	self:UpdatePvpFlag()
end

function CandyUI_Minimap:OnUnitPvpFlagsChanged(unitChanged)
	if not unitChanged:IsThePlayer() then
		return
	end
	self:UpdatePvpFlag()
end

function CandyUI_Minimap:UpdatePvpFlag()
	local nZoneRules = GameLib.GetCurrentZonePvpRules()

	if GameLib.IsPvpServer() == true then
		self.wndPvPFlagName:Show(true)
	else
		self.wndPvPFlagName:Show(nZoneRules ~= GameLib.CodeEnumZonePvpRules.DominionPVPStronghold and nZoneRules ~= GameLib.CodeEnumZonePvpRules.ExilePVPStronghold)
	end

	self.wndPvPFlagName:SetText(ktPvPZoneTypes[nZoneRules] or "")
end

function CandyUI_Minimap:OnMapPing(idUnit, tPos )

	for idx, tCur in pairs(self.tPingObjects) do
		if tCur.idUnit == idUnit then
			self.wndMiniMap:RemoveObject(tCur.objMapPing)
			self.tPingObjects[idx] = nil
		end
	end

	local tInfo =
	{
		strIcon = "sprMap_PlayerPulseFast",
		crObject = CColor.new(1, 1, 1, 1),
		strIconEdge = "",
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = true,
	}
	
	Sound.Play(Sound.PlayUIMiniMapPing)
	
	table.insert(self.tPingObjects, {["idUnit"] = idUnit, ["objMapPing"] = self.wndMiniMap:AddObject(self.eObjectTypePing, tPos, "", tInfo), ["nTime"] = GameLib.GetGameTime()})
	
	Apollo.StartTimer("PingTimer")

end

function CandyUI_Minimap:OnPingTimer()

	local nCurTime = GameLib.GetGameTime()
	local nNumUnits = 0
	for idx, tCur in pairs(self.tPingObjects) do
		if (tCur.nTime + 5) < nCurTime then
			self.wndMiniMap:RemoveObject(tCur.objMapPing)
			self.tPingObjects[idx] = nil
		else
			nNumUnits = nNumUnits + 1
		end
	end
		
	if nNumUnits == 0 then
		Apollo.StopTimer("PingTimer")
	else
		Apollo.StartTimer("PingTimer")
	end

end

function CandyUI_Minimap:OnFailChallenge(tChallengeData)
	self:OnRemoveChallengeIcon(tChallengeData:GetId())
end

function CandyUI_Minimap:OnRemoveChallengeIcon(chalOwner)
	if self.tChallengeObjects[chalOwner] ~= nil then
		self.wndMiniMap:RemoveObject(self.tChallengeObjects[chalOwner])
	end
	if self.tObjectsShown.Challenges ~= nil then
		for idx, tCurr in pairs(self.tObjectsShown.Challenges) do
			self.wndMiniMap:RemoveObject(idx)
		end
	end
	self.tObjectsShown.Challenges = {}
end

function CandyUI_Minimap:OnAddChallengeIcon(chalOwner, strDescription, tPosition)
	if self.tChallengeObjects[chalOwner:GetId()] ~= nil then
		self.wndMiniMap:RemoveObject(self.tChallengeObjects[chalOwner:GetId()])
		self.tChallengeObjects[chalOwner:GetId()] = nil

		-- make sure we turn off the flash icon just in case
		self:OnStopChallengeFlashIcon()
	end

	local tInfo =
	{
		strIcon = "MiniMapObject",
		crObject = CColor.new(1, 1, 1, 1),
		strIconEdge = "sprMM_ChallengeArrow",
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = true,
	}
	if tPosition ~= nil then
		if self.tObjectsShown.Challenges == nil then
			self.tObjectsShown.Challenges = {}
		end

		self.tChallengeObjects[chalOwner] = self.wndMiniMap:AddObject(self.eObjectTypeChallenge, tPosition, strDescription, tInfo, {}, not self.tToggledIcon[self.eObjectTypeChallenge])
		self.tObjectsShown.Challenges[self.tChallengeObjects[chalOwner]] = {tPosition = tPosition, strDescription = strDescription}
	end
end

function CandyUI_Minimap:OnFlashChallengeIcon(chalOwner, strDescription, fDuration, tPosition)
	if self.tChallengeObjects[chalOwner] ~= nil then
		self.wndMiniMap:RemoveObject(self.tChallengeObjects[chalOwner])
	end

	if self.db.profile.tToggledIcons[self.eObjectTypeChallenge] ~= false then
		-- TODO: Need to change the icon to a flashing icon
		local tInfo =
		{
			strIcon 		= "sprMM_QuestZonePulse",
			crObject 		= CColor.new(1, 1, 1, 1),
			strIconEdge 	= "sprMM_PathArrowActive",
			crEdge 			= CColor.new(1, 1, 1, 1),
			bAboveOverlay 	= true,
		}

		self.tChallengeObjects[chalOwner] = self.wndMiniMap:AddObject(self.eObjectTypeChallenge, tPosition, strDescription, tInfo, {}, false)
		self.ChallengeFlashingIconId = chalOwner

		-- create the timer to turn off this flashing icon
		Apollo.StopTimer("ChallengeFlashIconTimer")
		Apollo.CreateTimer("ChallengeFlashIconTimer", fDuration, false)
		Apollo.StartTimer("ChallengeFlashIconTimer")
	end
end

function CandyUI_Minimap:OnStopChallengeFlashIcon()

	if self.ChallengeFlashingIconId and self.tChallengeObjects[self.ChallengeFlashingIconId] then
		self.wndMiniMap:RemoveObject(self.tChallengeObjects[self.ChallengeFlashingIconId])
		self.tChallengeObjects[self.ChallengeFlashingIconId] = nil
	end

	self.ChallengeFlashingIconId = nil
end

---------------------------------------------------------------------------------------------------

function CandyUI_Minimap:OnPlayerPathMissionActivate(pmActivated)
	if self.db.profile.tToggledIcons == nil then
		return
	end

	self:OnPlayerPathMissionDeactivate(pmActivated)

	local tInfo =
	{
		strIcon 	= pmActivated:GetMapIcon(),
		crObject 	= CColor.new(1, 1, 1, 1),
		strIconEdge = "",
		crEdge 		= CColor.new(1, 1, 1, 1),
	}

	self.wndMiniMap:AddPathIndicator(pmActivated, tInfo, {bNeverShowOnEdge = true, bFixedSizeSmall = false}, not self.db.profile.tToggledIcons[GameLib.CodeEnumMapOverlayType.PathObjective])
end

function CandyUI_Minimap:OnPlayerPathMissionDeactivate(pmDeactivated)
	self.wndMiniMap:RemoveObjectsByUserData(GameLib.CodeEnumMapOverlayType.PathObjective, pmDeactivated)
end

---------------------------------------------------------------------------------------------------

function CandyUI_Minimap:ReloadPublicEvents()
	local tEvents = PublicEvent.GetActiveEvents()
	for idx, peCurr in ipairs(tEvents) do
		self:OnPublicEventUpdate(peCurr)
	end
end

function CandyUI_Minimap:OnPublicEventUpdate(peUpdated)
	self:OnPublicEventEnd(peUpdated)

	if not peUpdated:IsActive() or self.db.profile.tToggledIcons == nil then
		return
	end

	local tInfo =
	{
		strIcon = "sprMM_POI",
		crObject = CColor.new(1, 1, 1, 1),
		strIconEdge = "sprMM_QuestArrowActive",
		crEdge = CColor.new(1, 1, 1, 1),
	}

	for idx, tPos in ipairs(peUpdated:GetLocations()) do
		self.wndMiniMap:AddObject(self.eObjectTypePublicEvent, tPos, peUpdated:GetName(), tInfo, {bNeverShowOnEdge = peUpdated:ShouldShowOnMiniMapEdge(), bFixedSizeSmall = false}, not self.db.profile.tToggledIcons[self.eObjectTypePublicEvent], peUpdated)
	end

	for idx, peoCurr in ipairs(peUpdated:GetObjectives()) do
		self:OnPublicEventObjectiveUpdate(peoCurr)
	end
end

function CandyUI_Minimap:OnPublicEventEnd(peEnding)
	self.wndMiniMap:RemoveObjectsByUserData(self.eObjectTypePublicEvent, peEnding)

	for idx, peoCurr in ipairs(peEnding:GetObjectives()) do
		self:OnPublicEventObjectiveEnd(peoCurr)
	end
end

function CandyUI_Minimap:OnPublicEventObjectiveUpdate(peoUpdated)
	self:OnPublicEventObjectiveEnd(peoUpdated)

	if peoUpdated:GetStatus() ~= PublicEventObjective.PublicEventStatus_Active then
		return
	end

	local tInfo =
	{
		strIcon 	= "sprMM_POI",
		crObject 	= CColor.new(1, 1, 1, 1),
		strIconEdge = "MiniMapObjectEdge",
		crEdge 		= CColor.new(1,1, 1, 1),
	}

	bHideOnEdge = (peoUpdated:ShouldShowOnMinimapEdge() ~= true)

	for idx, tPos in ipairs(peoUpdated:GetLocations()) do
		self.wndMiniMap:AddObject(self.eObjectTypePublicEvent, tPos, peoUpdated:GetShortDescription(), tInfo, {bNeverShowOnEdge = hideOnEdge, bFixedSizeSmall = false}, not self.db.profile.tToggledIcons[self.eObjectTypePublicEvent], peoUpdated)
	end
end

function CandyUI_Minimap:OnPublicEventObjectiveEnd(peoUpdated)
	self.wndMiniMap:RemoveObjectsByUserData(self.eObjectTypePublicEvent, peoUpdated)
end

---------------------------------------------------------------------------------------------------
function CandyUI_Minimap:OnCityDirectionMarked(tLocInfo)
	if not self.wndMiniMap or not self.wndMiniMap:IsValid() then
		return
	end

	local tInfo =
	{
		strIconEdge = "",
		strIcon 	= "sprMM_QuestTrackedActivate",
		crObject 	= CColor.new(1, 1, 1, 1),
		crEdge 		= CColor.new(1, 1, 1, 1),
	}

	-- Only one city direction at a time, so stomp and remove and previous
	self.wndMiniMap:RemoveObjectsByUserData(self.eObjectTypeCityDirection, Apollo.GetString("ZoneMap_CityDirections"))
	self.wndMiniMap:AddObject(self.eObjectTypeCityDirection, tLocInfo.tLoc, tLocInfo.strName, tInfo, {bFixedSizeSmall = false}, false, Apollo.GetString("ZoneMap_CityDirections"))
	Apollo.StartTimer("ZoneMap_TimeOutCityDirectionMarker")
end

function CandyUI_Minimap:OnZoneMap_TimeOutCityDirectionEvent()
	if not self.wndMiniMap or not self.wndMiniMap:IsValid() then
		return
	end

	self.wndMiniMap:RemoveObjectsByUserData(self.eObjectTypeCityDirection, Apollo.GetString("ZoneMap_CityDirections"))
end

---------------------------------------------------------------------------------------------------
function CandyUI_Minimap:OnQuestStateChanged()
	self.tEpisodeList = QuestLib.GetTrackedEpisodes(self.bQuestTrackerByDistance)

	if self.wndMiniMap == nil or self.db.profile.tToggledIcons == nil then
		return
	end

	-- Clear episode list
	self.wndMiniMap:RemoveObjectsByType(GameLib.CodeEnumMapOverlayType.QuestObjective)

	-- Iterate over all the episodes adding the active one
	local nCount = 0
	for idx, epiCurr in ipairs(self.tEpisodeList) do

		-- Add entries for each quest in the episode
		for idx2, queCurr in ipairs(epiCurr:GetTrackedQuests(0, self.bQuestTrackerByDistance)) do
			local eQuestState = queCurr:GetState()
			nCount = nCount + 1 -- number the quest

			if queCurr:IsActiveQuest() then
				local tInfo =
				{
					strIcon 	= "ActiveQuestIcon",
					crObject 	= CColor.new(1, 1, 1, 1),
					strIconEdge = "sprMM_QuestArrowActivate",
					crEdge 		= CColor.new(1, 1, 1, 1),
				}
				-- This is a C++ call on the MiniMapWindow class
				self.wndMiniMap:AddQuestIndicator(queCurr, tostring(nCount), tInfo, {bOnlyShowOnEdge = false, bAboveOverlay = true}, not self.db.profile.tToggledIcons[GameLib.CodeEnumMapOverlayType.QuestObjective])
			elseif not queCurr:IsActiveQuest() and self.db.profile.tToggledIcons[self.eObjectTypeQuestReward] then
				local tInfo =
				{
					strIcon = "sprMM_QuestTracked",
					crObject = CColor.new(1, 1, 1, 1),
					strIconEdge = "sprMM_SolidPathArrow",
					crEdge = CColor.new(1, 1, 1, 1),
				}
				-- This is a C++ call on the MiniMapWindow class
				self.wndMiniMap:AddQuestIndicator(queCurr, tostring(nCount), tInfo, {bOnlyShowOnEdge = false, bFixedSizeMedium = false, bAboveOverlay = true}, not self.db.profile.tToggledIcons[GameLib.CodeEnumMapOverlayType.QuestObjective])
			end
		end
	end
end

---------------------------------------------------------------------------------------------------

function CandyUI_Minimap:OnOneSecTimer()
	if self.tQueuedUnits == nil then
		return
	end

	self.unitPlayerDisposition = GameLib.GetPlayerUnit()
	if self.unitPlayerDisposition == nil or not self.unitPlayerDisposition:IsValid() then
		return
	end

	for id,unit in pairs(self.tQueuedUnits) do
		if unit:IsValid() then
			self:HandleUnitCreated(unit)
		end
	end

	self.tQueuedUnits = {}
end

function CandyUI_Minimap:OnUnitCreated(unitNew)
	if unitNew == nil or not unitNew:IsValid() or unitNew == GameLib.GetPlayerUnit() then
		return
	end
	self.tQueuedUnits[unitNew:GetId()] = unitNew
end

function CandyUI_Minimap:GetDefaultUnitInfo()
	local tInfo =
	{
		strIcon = "",
		strIconEdge = "MiniMapObjectEdge",
		crObject = CColor.new(1, 1, 1, 1),
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = false,
	}
	return tInfo
end

function CandyUI_Minimap:UpdateHarvestableNodes()
	for idx, unitResource in pairs(self.arResourceNodes) do
		if unitResource:CanBeHarvestedBy(GameLib.GetPlayerUnit()) then
			self:OnUnitChanged(unitResource)
			self.arResourceNodes[unitResource:GetId()] = nil
		end
	end
end

function CandyUI_Minimap:GetOrderedMarkerInfos(tMarkerStrings)
	local tMarkerInfos = {}
	
	for nMarkerIdx, strMarker in ipairs(tMarkerStrings) do
		if strMarker then
			local tMarkerOverride = self.tMinimapMarkerInfo[strMarker]
			if tMarkerOverride then
				table.insert(tMarkerInfos, tMarkerOverride)
			end
		end
	end

	table.sort(tMarkerInfos, function(x, y) return x.nOrder < y.nOrder end)
	return tMarkerInfos
end

function CandyUI_Minimap:HandleUnitCreated(unitNew)

	if not unitNew or not unitNew:IsValid() then
		return
	end
	
	if self.tUnitsHidden and self.tUnitsHidden[unitNew:GetId()] then
		self.tUnitsHidden[unitNew:GetId()] = nil
		self.wndMiniMap:RemoveUnit(unitNew)
	end

	if self.tUnitsShown and self.tUnitsShown[unitNew:GetId()] then
		self.tUnitsShown[unitNew:GetId()] = nil
		self.wndMiniMap:RemoveUnit(unitNew)
	end

	local bShowUnit = unitNew:IsVisibleOnCurrentZoneMinimap()

	if bShowUnit == false then
		self.tUnitsHidden[unitNew:GetId()] = {unitObject = unitNew} -- valid, but different subzone. Add it to the list
		return
	end
	
	local tMarkers = unitNew:GetMiniMapMarkers()
	if tMarkers == nil then
		return
	end
	
	local tMarkerInfoList = self:GetOrderedMarkerInfos(tMarkers)
	for nIdx, tMarkerInfo in ipairs(tMarkerInfoList) do
		local tInfo = self:GetDefaultUnitInfo()
		if tMarkerInfo.strIcon  then
			tInfo.strIcon = tMarkerInfo.strIcon
		end
		if tMarkerInfo.crObject then
			tInfo.crObject = tMarkerInfo.crObject
		end
		if tMarkerInfo.crEdge   then
			tInfo.crEdge = tMarkerInfo.crEdge
		end

		local tMarkerOptions = {bNeverShowOnEdge = true}
		if tMarkerInfo.bAboveOverlay then
			tMarkerOptions.bAboveOverlay = tMarkerInfo.bAboveOverlay
		end
		if tMarkerInfo.bShown then
			tMarkerOptions.bShown = tMarkerInfo.bShown
		end
		-- only one of these should be set
		if tMarkerInfo.bFixedSizeSmall then
			tMarkerOptions.bFixedSizeSmall = tMarkerInfo.bFixedSizeSmall
		elseif tMarkerInfo.bFixedSizeMedium then
			tMarkerOptions.bFixedSizeMedium = tMarkerInfo.bFixedSizeMedium
		end

		local objectType = GameLib.CodeEnumMapOverlayType.Unit
		if tMarkerInfo.objectType then
			objectType = tMarkerInfo.objectType
		end

		self.wndMiniMap:AddUnit(unitNew, objectType, tInfo, tMarkerOptions, self.db.profile.tToggledIcons[objectType] ~= nil and not self.db.profile.tToggledIcons[objectType])
		self.tUnitsShown[unitNew:GetId()] = { tInfo = tInfo, unitObject = unitNew }
	end

end

function CandyUI_Minimap:OnHazardShowMinimapUnit(idHazard, unitHazard, bIsBeneficial)

	if unitHazard == nil then
		return
	end

	--local unit = GameLib.GetUnitById(unitId)
	local tInfo

	tInfo =
	{
		strIcon = "",
		strIconEdge = "",
		crObject = CColor.new(1, 1, 1, 1),
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = false,
	}


	if bIsBeneficial then
		tInfo.strIcon = "sprMM_ZoneBenefit"
	else
		tInfo.strIcon = "sprMM_ZoneHazard"
	end

	self.wndMiniMap:AddUnit(unitHazard, self.eObjectTypeHazard, tInfo, {bNeverShowOnEdge = true, bFixedSizeMedium = true}, false)
end

function CandyUI_Minimap:OnHazardRemoveMinimapUnit(idHazard, unitHazard)
	if unitHazard == nil then
		return
	end

	self.wndMiniMap:RemoveUnit(unitHazard)
end

function CandyUI_Minimap:OnUnitChanged(unitUpdated, eType)
	if unitUpdated == nil then
		return
	end

	self.wndMiniMap:RemoveUnit(unitUpdated)
	self.tUnitsShown[unitUpdated:GetId()] = nil
	self.tUnitsHidden[unitUpdated:GetId()] = nil
	self:OnUnitCreated(unitUpdated)
end

function CandyUI_Minimap:OnUnitDestroyed(unitDestroyed)
	self.tUnitsShown[unitDestroyed:GetId()] = nil
	self.tUnitsHidden[unitDestroyed:GetId()] = nil
	self.arResourceNodes[unitDestroyed:GetId()] = nil
end

-- GROUP EVENTS

function CandyUI_Minimap:OnGroupJoin()
	for idx = 1, GroupLib.GetMemberCount() do
		local tInfo = GroupLib.GetGroupMember(idx)
		if tInfo.bIsOnline then
			self:OnUnitCreated(GroupLib.GetUnitForGroupMember(idx))
		end
	end
end

function CandyUI_Minimap:OnGroupAdd(strName)
	for idx = 1, GroupLib.GetMemberCount() do
		local tInfo = GroupLib.GetGroupMember(idx)
		if tInfo.bIsOnline then
			self:OnUnitCreated(GroupLib.GetUnitForGroupMember(idx))
		end
	end
end

function CandyUI_Minimap:OnGroupInviteResult(strName, eResult)
	for idx = 1, GroupLib.GetMemberCount() do
		local tInfo = GroupLib.GetGroupMember(idx)
		if tInfo.bIsOnline then
			self:OnUnitCreated(GroupLib.GetUnitForGroupMember(idx))
		end
	end
end

function CandyUI_Minimap:OnGroupRemove(strName, eReason)
	self:OnRefreshRadar()
	-- need to filter to only that group member
end

function CandyUI_Minimap:OnGroupLeft(eReason)
	self:OnRefreshRadar()
	-- need to filter to only that group member
end

---------------------------------------------------------------------------------------------------
function CandyUI_Minimap:OnGenerateTooltip(wndHandler, wndControl, eType, nX, nY)
	local xml = nil
	local crWhite = CColor.new(1, 1, 1, 1)
	if eType ~= Tooltip.TooltipGenerateType_Map then
		wndControl:SetTooltipDoc(nil)
		return
	end

	local nCount = 0
	local bNeedToAddLine = true
	local tClosestObject = nil
	local nShortestDist = 0

	local tMapObjects = self.wndMiniMap:GetObjectsAtPoint(nX, nY)
	if not tMapObjects or #tMapObjects == 0 then
		wndControl:SetTooltipDoc(nil)
		return
	end

	for key, tObject in pairs(tMapObjects) do
		if tObject.unit then
			local nDistSq = (nX - tObject.ptMap.x) * (nX - tObject.ptMap.x) + (nY - tObject.ptMap.y) * (nY - tObject.ptMap.y)
			if tClosestObject == nil or nDistSq < nShortestDist then
				tClosestObject = tObject
				nShortestDist = nDistSq
			end
			nCount = nCount + 1
		end
	end

	-- Merged unit tooltips does not work at all with current lua based tooltips
	-- TODO: FIXME
	--[[
	if tClosestObject then
		tClosestObject.bMarked = true
		xml = Tooltip.GetUnitTooltipForm(self, wndControl, tClosestObject.unit)
		nCount = nCount - 1
	end]]--

	if not xml then
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		bNeedToAddLine = false
	end

	-- Iterate map objects
	local nObjectCount = 0
	local tStringsAdded = {}
	for key, tObject in pairs(tMapObjects) do
		if nObjectCount == 5 then
			nObjectCount = nObjectCount + 1

			local tInfo =
			{
				["name"] = Apollo.GetString("CRB_Unit"),
				["count"] = nCount
			}
			xml:AddLine(String_GetWeaselString(Apollo.GetString("MiniMap_OtherUnits"), tInfo), crWhite, "CRB_InterfaceMedium")
		elseif nObjectCount > 5 then
			-- Do nothing
		elseif tObject.strName == "" then
			-- Do nothing
		elseif tObject.strName and not tObject.bMarked then
			if bNeedToAddLine then
				xml:AddLine(" ")
			end
			bNeedToAddLine = false

			if not tStringsAdded[tObject.strName] then
				nObjectCount = nObjectCount + 1
				xml:AddLine(tObject.strName, crWhite, "CRB_InterfaceMedium")
				tStringsAdded[tObject.strName] = true
			end
		end
	end
	
	if nObjectCount > 0 then
		wndControl:SetTooltipDoc(xml)
	else
		wndControl:SetTooltipDoc(nil)
	end
end

function CandyUI_Minimap:OnFriendshipAccountFriendsRecieved(tFriendAccountList)
	for idx, tFriend in pairs(tFriendAccountList) do
		self:OnRefreshRadar(FriendshipLib.GetUnitById(tFriend.nId))
	end
end

function CandyUI_Minimap:OnFriendshipAdd(nFriendId)
	self:OnRefreshRadar(FriendshipLib.GetUnitById(nFriendId))
end

function CandyUI_Minimap:OnFriendshipRemove(nFriendId)
	self:OnRefreshRadar(FriendshipLib.GetUnitById(nFriendId))
end

function CandyUI_Minimap:OnFriendshipAccountFriendsRecieved(tFriendAccountList)
	self:OnRefreshRadar()
end

function CandyUI_Minimap:OnFriendshipAccountFriendRemoved(nId)
	self:OnRefreshRadar()
end

function CandyUI_Minimap:OnReputationChanged(tFaction)
	self:OnRefreshRadar()
end

function CandyUI_Minimap:OnRefreshRadar(newUnit)
	if newUnit ~= nil and newUnit:IsValid() then
		self:OnUnitCreated(newUnit)
	else
		for idx, tCur in pairs(self.tUnitsShown) do
			self:OnUnitCreated(tCur.unitObject)
		end

		for idx, tCur in pairs(self.tUnitsHidden) do
			self:OnUnitCreated(tCur.unitObject)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Minimap Functions
---------------------------------------------------------------------------------------------------

function CandyUI_Minimap:OnBagButtonClick( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("InterfaceMenu_ToggleInventory")
end

function CandyUI_Minimap:OnDatachronButtonCheck( wndHandler, wndControl, eMouseButton )	
	--wndControl:AttachWindow(g_wndDatachron)
	--local nDCWidth = g_wndDatachron:GetWidth()
	--local nDCHeight = g_wndDatachron:GetHeight()
	
	--local nMMLeft, nMMTop, nMMRight, nMMBottom = Apollo.GetAddon("CandyUI_Minimap").wndMain:GetAnchorOffsets()
	
	--g_wndDatachron:SetAnchorOffsets(nMMRight - nDCWidth, nMMBottom + 10, nMMRight, nMMBottom + nDCHeight + 10)
	
	g_wndDatachron:Show(true)
	Event_FireGenericEvent("DatachronRestored")

	Sound.Play(Sound.PlayUI37OpenRemoteWindowDigital)
end

function CandyUI_Minimap:OnDatachronButtonUncheck( wndHandler, wndControl, eMouseButton )
	--wndControl:AttachWindow(g_wndDatachron)
	g_wndDatachron:Show(false)
	Event_FireGenericEvent("DatachronMinimized")
	g_wndDatachron:FindChild("QueuedCallsContainer"):Show(false)

	Sound.Play(Sound.PlayUI38CloseRemoteWindowDigital)
end

-- This function is triggered whenever one of the windows is moved by the player.
-- When the event is triggered, we get the new anchor offsets of the control that raised the event
-- and store them inside our internal database for tracking the position and saving it.
function CandyUI_Minimap:OnMinimapMoved(wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom)
  self.db.profile.general.tAnchorOffsets = { wndControl:GetAnchorOffsets() }
end

kcuiMMDefaults = {
	char = {
		currentProfile = nil,
	},
	profile = {
		general = {
			tAnchorOffsets = { -209, 35, -5, 265},
			nSize = 184,
			nOpacity = 1.0,
			
		},
		buttonControls = {
			strAddonName = "",
			strWindowName = "",
			bUseCustomFunc = false,
			strCustFunc = "",
		},
		--tToggledIcons = {
		--	
		--},
	},
}


function CandyUI_Minimap:SetOptions()
	local Options = self.db.profile
	
	if self.db.profile.tToggledIcons == nil or self.db.profile.tToggledIcons == {} then
			self.db.profile.tToggledIcons = {
				[self.eObjectTypeHostile] 						= true,
				[self.eObjectTypeNeutral] 						= true,
				[self.eObjectTypeGroupMember] 					= true,
				[self.eObjectTypeQuestReward]					= true,
				[self.eObjectTypeVendor] 						= true,
				[self.eObjectTypeBindPointActive] 				= true,
				[self.eObjectTypeInstancePortal] 				= true,
				[self.eObjectTypePublicEvent] 					= true,
				[self.eObjectTypeQuestTarget]					= true, 
				[GameLib.CodeEnumMapOverlayType.QuestObjective] = true,
				[GameLib.CodeEnumMapOverlayType.PathObjective] 	= true,
				[self.eObjectTypeChallenge] 					= true,
				[self.eObjectTypeMiningNode] 					= true,
				[self.eObjectTypeRelicHunterNode] 				= true,
				[self.eObjectTypeSurvivalistNode] 				= true,
				[self.eObjectTypeFarmingNode] 					= true,
				[self.eObjectTypeTradeskills] 					= true,
				[self.eObjectTypeTrainer] 						= true,
				[self.eObjectTypeFriend] 						= true,
				[self.eObjectTypeRival] 						= true,
				[self.eObjectTypeCityDirection]					= true,
			}
		end
		
	local tUIElementToType = {
				["ShowQuestNPCsToggle"] 			= self.eObjectTypeQuestReward,
				["ShowTrackedQuestsToggle"] 			= GameLib.CodeEnumMapOverlayType.QuestObjective,
				["ShowMissionsToggle"] 			= GameLib.CodeEnumMapOverlayType.PathObjective,
				["ShowChallengesToggle"] 		= self.eObjectTypeChallenge,
				["ShowPublicEventsToggle"] 		= self.eObjectTypePublicEvent,
				["ShowVendorsToggle"] 			= self.eObjectTypeVendor,
				["ShowInstancePortalsToggle"] 	= self.eObjectTypeInstancePortal,
				["ShowBindPointsToggle"] 		= self.eObjectTypeBindPointActive,
				["ShowMiningNodesToggle"] 		= self.eObjectTypeMiningNode,
				["ShowRelicNodesToggle"] 		= self.eObjectTypeRelicHunterNode,
				["ShowSurvivalistNodesToggle"] 	= self.eObjectTypeSurvivalistNode,
				["ShowFarmingNodesToggle"] 		= self.eObjectTypeFarmingNode,
				["ShowTradeskillsToggle"] 		= self.eObjectTypeTradeskills,
				["ShowNeutralNPCsToggle"] 		= self.eObjectTypeNeutral,
				["ShowHostileNPCsToggle"] 		= self.eObjectTypeHostile,
				["ShowTrainersToggle"] 			= self.eObjectTypeTrainer,
				["ShowFriendsToggle"]			= self.eObjectTypeFriend,
				["ShowRivalsToggle"] 			= self.eObjectTypeRival,
				["ShowCityGuardToggle"]			= self.eObjectTypeCityDirection,
			}
			
	local wndOptionsWindow = self.wndControls:FindChild("ViewControls")
	for strWindowName, eType in pairs(tUIElementToType) do
		local wndOptionsBtn = wndOptionsWindow:FindChild(strWindowName)
		wndOptionsBtn:SetData(eType)
		wndOptionsBtn:SetCheck(self.db.profile.tToggledIcons[eType])
	end
	
	--Position
	self.wndMain:SetAnchorOffsets(unpack(self.db.profile.general.tAnchorOffsets))
	
	--General
	self.wndControls:FindChild("GeneralControls:Size:SliderBar"):SetValue(Options.general.nSize)
	self.wndControls:FindChild("GeneralControls:Size:EditBox"):SetText(Options.general.nSize)

	self.wndControls:FindChild("GeneralControls:Opacity:SliderBar"):SetValue(Options.general.nOpacity)
	self.wndControls:FindChild("GeneralControls:Opacity:EditBox"):SetText(Options.general.nOpacity)
	
	--Center Button
	self.wndControls:FindChild("ButtonControls:AddonName:Input"):SetText(Options.buttonControls.strAddonName)	
	self.wndControls:FindChild("ButtonControls:WindowName:Input"):SetText(Options.buttonControls.strWindowName)	
	self.wndControls:FindChild("ButtonControls:CustomFuncToggle"):SetCheck(Options.buttonControls.bUseCustomFunc)	
	self.wndControls:FindChild("ButtonControls:CustomFuncInput"):SetText(Options.buttonControls.strCustFunc)	
end

function CandyUI_Minimap:OnFilterOptionCheck(wndHandler, wndControl, eMouseButton)
	local data = wndControl:GetData()
	if data == nil then
		return
	end

	self.db.profile.tToggledIcons[data] = true

	if data == self.eObjectTypeQuestReward then
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestReward)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestReceiving)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestNew)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestNewSoon)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestTarget)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestKill)
	elseif data == self.eObjectTypeBindPointActive then
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeBindPointActive)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeBindPointInactive)
	elseif data == self.eObjectTypeVendor then
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeVendor)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeAuctioneer)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeCommodity)
	else
		self.wndMiniMap:ShowObjectsByType(data)
	end
end

function CandyUI_Minimap:OnFilterOptionUncheck(wndHandler, wndControl, eMouseButton)
	local data = wndControl:GetData()
	if data == nil then
		return
	end

	self.db.profile.tToggledIcons[data] = false

	if data == self.eObjectTypeQuestReward then
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestReward)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestReceiving)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestNew)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestNewSoon)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestTarget)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestKill)
	elseif data == self.eObjectTypeBindPointActive then
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeBindPointActive)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeBindPointInactive)
	elseif data == self.eObjectTypeVendor then
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeVendor)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeAuctioneer)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeCommodity)
	else
		self.wndMiniMap:HideObjectsByType(data)
	end
end

function CandyUI_Minimap:OnCenterButtonClick( wndHandler, wndControl, eMouseButton )
	if self.db.profile.buttonControls.bUseCustomFunc and (self.db.profile.buttonControls.strCustFunc ~= nil or self.db.profile.buttonControls.strCustFunc ~= "") then
		--Use the custom function
		local strFuncText = self.db.profile.buttonControls.strCustFunc
		local func, strError = loadstring(strFuncText)
		if func ~= nil then
			func()
		end
	elseif (self.db.profile.buttonControls.strWindowName ~= nil or self.db.profile.buttonControls.strWindowName ~= "") then
		--Use addon and window name
		local strAddonName = self.db.profile.buttonControls.strAddonName
		local strWindowName = self.db.profile.buttonControls.strWindowName
		local uAddon = Apollo.GetAddon(strAddonName)
		local bIsRunning = (Apollo.GetAddonInfo(strAddonName) ~= nil and Apollo.GetAddonInfo(strAddonName).bRunning) or 0 --1 = running
		if (strAddonName ~= nil or strAddonName ~= "") then
			--Use addon name
			if bIsRunning == 1 then
				local wndToggle = uAddon[strWindowName]
				if wndToggle ~= nil and wndToggle:IsValid() then
					if wndToggle:IsVisible() then
						wndToggle:Show(false)
					else
						wndToggle:Show(true)
					end
				end
			end
		else
			--Window is global
			if bIsRunning == 1 then
				local wndToggle = strWindowName
				if wndToggle ~= nil and wndToggle:IsValid() then
					if wndToggle:IsVisible() then
						wndToggle:Show(false)
					else
						wndToggle:Show(true)
					end
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- OptionsControlsList Functions
---------------------------------------------------------------------------------------------------

function CandyUI_Minimap:OnAddonNameChanged( wndHandler, wndControl, strText )
	self.db.profile.buttonControls.strAddonName = tostring(strText)
end

function CandyUI_Minimap:OnWindowNameChanged( wndHandler, wndControl, strText )
	self.db.profile.buttonControls.strWindowName = tostring(strText)
end

function CandyUI_Minimap:OnCustomFuncChanged( wndHandler, wndControl, strText )
	self.db.profile.buttonControls.strCustFunc = tostring(strText)
end

function CandyUI_Minimap:OnUseCustomFuncClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.buttonControls.bUseCustomFunc = wndControl:IsChecked()
end

function CandyUI_Minimap:OnSizeChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local nBufferY = 46
	local nBufferX = 20
	local nValue = round(fNewValue)
	
	self.db.profile.general.nSize = nValue
	wndControl:GetParent():FindChild("EditBox"):SetText(nValue)
	
	local l, t, r, b = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(r-(nValue+nBufferX), t, r, t-(nValue+nBufferY))
	self.db.profile.general.tAnchorOffsets = {r-(nValue+nBufferX), t, r, t-(nValue+nBufferY)}
end

function CandyUI_Minimap:OnOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local nValue = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(nValue)
	self.db.profile.general.nOpacity = nValue
	
	self.wndMain:SetOpacity(nValue)
end

function CandyUI_Minimap:OnRotateMapClick( wndHandler, wndControl, eMouseButton )
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Minimap Instance
-----------------------------------------------------------------------------------------------
local CandyUI_MinimapInst = CandyUI_Minimap:new()
CandyUI_MinimapInst:Init()
