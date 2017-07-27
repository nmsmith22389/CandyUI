-----------------------------------------------------------------------------------------------
-- Client Lua Script for StarPanel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- StarPanel Module Definition
-----------------------------------------------------------------------------------------------
local StarPanel = {} 

--[[
USEFULL function in _G

-strRound(1.456, 2)
-TableUtil = {
    Copy = <function 1360>
  },
-RequestReloadUI()
-PlayerPathLib = <65>
-GetAbilitiesWindow = <function 590>,
  GetacterWindow = <function 591>,
  GetConColor = <function 592>,
  GetCurrentSubZoneName = <function 593>,
  GetCurrentZoneName = <function 594>,
  GetElderPoints = <function 598>,
  getfenv = <function 599>,
  GetItemInfo = <function 604>,
  GetPeriodicElderPoints = <function 610>,
  GetResourceCooldownPercent = <function 614>,
  GetRestXp = <function 615>,
  GetRestXpKillCreaturePool = <function 616>,
  GetUnit = <function 624>,
  GetWakeHereTime = <function 625>,
  GetWarCoins = <function 626>,
  GetXp = <function 627>,
  GetXpPercentToNextLevel = <function 628>,
  GetXpToCurrentLevel = <function 629>,
  GetXpToNextLevel = <function 630>,


jessica's code
--------------
eNrj/cDAwMTAwMACxIxAvByIOYCYC8pnYkDIM0NpFqgYOxBzQ9WC2AJQtiQQuwExKxD/r2cHkyAzO6I4wWyQHq8QXiBZd4YfSH42FACLCwPJ6SvEgeSGIwCjrw+H
]]

--Global CUI var
if _cui == nil then
	_cui = {}
end

-------------------
--   Sort Table
-------------------
local function pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a, f)
	local i = 0
	local iterator = function()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iterator
end

---------------
--   Round
---------------
--local round = _G.strRound
local function round(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end

local function GetProfs()
	local TradeskillIDs = {}
	for k, v in pairs(CraftingLib.GetKnownTradeskills()) do
		local info = CraftingLib.GetTradeskillInfo(v.eId)
		if not info.bIsActive or info.bIsHobby then
		else
			table.insert(TradeskillIDs, v.eId)
		end
	end
	return TradeskillIDs
end

-----------------------------
--   Copper to Money String
-----------------------------
local function CopperToMoneyString(nCopperIn)
	-- ppggsscc
	-- 01234567
	local nPlat = math.floor(nCopperIn / 1000000)
	local nGold = math.floor(nCopperIn / 10000) - (nPlat * 100)
	local nSilver = math.floor(nCopperIn / 100) - ((nPlat * 10000) + (nGold * 100))
	local nCopper = nCopperIn  - ((nPlat * 1000000) + (nGold * 10000) + (nSilver * 100))
	local string = ""
	if nPlat > 0 then
		string = string..nPlat.."p "
	end
	if nGold > 0 then
		string = string..nGold.."g "
	end
	if nSilver > 0 then
		string = string..nSilver.."s "
	end
	if nCopper > 0 then
		string = string..nCopper.."c "
	end
	if string == "" then
		string = "0c"
	end
	
	return string
end

-----------------------------
--   Shorten Money String
-----------------------------
local function ShortenMoneyString(strIn)
	if string.find(strIn, " Platinum,") then
		strIn = string.gsub(strIn, " Platinum,", "p ")
	end
	if string.find(strIn, " Gold,") then
		strIn = string.gsub(strIn, " Gold,", "g ")
	end
	if string.find(strIn, " Silver,") then
		strIn = string.gsub(strIn, " Silver,", "s ")
	end
	if string.find(strIn, " Copper") then
		strIn = string.gsub(strIn, " Copper", "c ")
	end

	return strIn
end

local function CopperToDenominations(nCopperIn)
	-- ppggsscc
	-- 01234567
	local nPlat = math.floor(nCopperIn / 1000000)
	local nGold = math.floor(nCopperIn / 10000) - (nPlat * 100)
	local nSilver = math.floor(nCopperIn / 100) - ((nPlat * 10000) + (nGold * 100))
	local nCopper = nCopperIn  - ((nPlat * 1000000) + (nGold * 10000) + (nSilver * 100))
	
	return nPlat, nGold, nSilver, nCopper
end

function StarPanel:FormatBigNumber(nArg)
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
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function StarPanel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function StarPanel:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = "StarPanel"
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- StarPanel OnLoad
-----------------------------------------------------------------------------------------------
function StarPanel:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("StarPanel.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, ktSPDefaults )
end

-----------------------------------------------------------------------------------------------
-- StarPanel OnDocLoaded
-----------------------------------------------------------------------------------------------
function StarPanel:OnDocLoaded()
    --Vars
	--CUI load status
		if _cui.tAddonLoadStatus == nil then
			_cui.tAddonLoadStatus = {}
		end
		_cui.tAddonLoadStatus["StarPanel"] = true
		
	self.DataTexts = {}
	self.DataTextOptionsUI = {}
	self.tDataTextsTop = {}
	self.tDataTextsBot = {}
	--self.strLastCheckedName
	self.nTimeSessionStart = os.time()
	self.nStartingMoney = GameLib.GetPlayerCurrency(1):GetAmount()
	self.tStartingCurrency = {
		[2] = GameLib.GetPlayerCurrency(2):GetAmount(),
		[3] = GameLib.GetPlayerCurrency(3):GetAmount(),
		[4] = GameLib.GetPlayerCurrency(4):GetAmount(),
		[5] = GameLib.GetPlayerCurrency(5):GetAmount(),
	}
	self.nXpSession = GetXp()
	self.nEpSession = GetElderPoints()
	
	self.wndTopDisplay = Apollo.LoadForm(self.xmlDoc, "TopDisplay", nil, self)
	self.wndBotDisplay = Apollo.LoadForm(self.xmlDoc, "BotDisplay", nil, self)
	
	self.wndOptions = Apollo.LoadForm(self.xmlDoc, "OptionsDialogue", nil, self)
	self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControls", self.wndOptions:FindChild("OptionsDialogueControls"), self)
	self.wndDataTexts = Apollo.LoadForm(self.xmlDoc, "DataTextsDialogue", nil, self)
	--self.DataTextOptionItem = Apollo.LoadForm(self.xmlDoc, "DataTextOptionItem", self.wndDataTexts:FindChild("OptionsDialogueControls"), self)
	self.wndConfirmAlert = Apollo.LoadForm(self.xmlDoc, "ConfirmAlert", nil, self)
	
	-- Register handlers for events, slash commands and timer, etc.
	-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
	Apollo.RegisterSlashCommand("sp", "OnStarPanelOn", self)
	
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)
	--Apollo.RegisterEventHandler("DatachronRestored", "OnDatachronRestored", self)
	--self.db:ResetProfile()
	--set curr profile
	
	--CUI Options
		if _cui.bOptionsLoaded == true then
			self:RegisterCUIOptions()
		else
			Apollo.RegisterEventHandler("CandyUI_Loaded", "RegisterCUIOptions", self)
		end
	
	local QuestTracker = nil -- Apollo.GetAddon("QuestTracker")
	if QuestTracker then
		local nQuestTrackerLeft, nQuestTrackerTop, nQuestTrackerTop, nQuestTrackerBottom = QuestTracker.wndMain:GetAnchorOffsets()
		self.nQuestTrackerBottom = nQuestTrackerBottom - 20
	end
	
	if not self.db.char.currentProfile then
		self.db.char.currentProfile = self.db:GetCurrentProfile()
	else
		self.db:SetProfile(self.db.char.currentProfile)
	end
	self:SetOptions()
	StarPanel:InitializeDataTexts(self)
end

function StarPanel:RegisterCUIOptions()
	--Load Options
	local wndOptionsControls = Apollo.GetAddon("CandyUI").wndOptions:FindChild("OptionsDialogueControls")
	local wndControls = Apollo.LoadForm(self.xmlDoc, "SPOptions", wndOptionsControls, self)
	CUI_RegisterOptions("StarPanel", wndControls, true)
end

function StarPanel:InitializeDataTexts(self)
	local dt, ops = {}, {}
	
	
	
	--SP Options
	dt = {
		["type"]		= "launcher",
		["strLabel"]	= "Options",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["imgIcon"]		= "CRB_Inventory:sprPersonaWrenchIcon",
		--["nIconSize"]	= 17,
		["OnClick"]	= function()
			self.wndOptions:Invoke()			
		end
	}

	self:RegisterDataText(self, "Options", dt)
	self:RegisterDefaultOptions(self, "Options")
	
	
	
	--FPS
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "FPS: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "CRB_Basekit:kitIcon_Holo_HazardProximity",
		["OnUpdate"]	= function()

			--what about tooltip?
			--and ops menu? <- put that in a diff part

			local text = round(GameLib.GetFrameRate(), 1)
			
			local crText = "ff00ff00" --green
			if text <= 59 then
				crText = "ffffff00" --yellow
			elseif text <= 25 then
				crText = "ffff0000" --red
			end
			self.DataTexts.FPS.crText = crText
			
			return text			
		end
	}

	self:RegisterDataText(self, "FPS", dt)
	self:RegisterDefaultOptions(self, "FPS")
	
	--Time
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "Time: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= nil,
		["bRightSide"]	= true,
		["OnUpdate"]	= function()
			local text
			local source = self.db.profile.tDTOptions["Time"]["strSource"]
			if source == "server" then
				text = GameLib.GetServerTime().strFormattedTime
			else
				text = GameLib.GetLocalTime().strFormattedTime
			end
			
			return text			
		end,
		["OnTooltip"]	= function()
			local xml = XmlDoc.new()
			
			xml:AddLine("Time", "UI_TextHoloTitle", "CRB_InterfaceLarge_O", "Left")
			xml:AddLine(" ", "UI_TextHoloTitle", "CRB_InterfaceMedium", "Left")
			xml:AddLine("Server:         ", "UI_TextHoloBody", "CRB_InterfaceMedium_O", "Left")	
			xml:AppendText(GameLib.GetServerTime().strFormattedTime, "UI_TextHoloBodyHighlight", "CRB_InterfaceMedium_O", "Right")
			xml:AddLine("Local:          ", "UI_TextHoloBody", "CRB_InterfaceMedium_O", "Left")	
			xml:AppendText(GameLib.GetLocalTime().strFormattedTime, "UI_TextHoloBodyHighlight", "CRB_InterfaceMedium_O", "Right")
			
			--:AddLine("Time", "UI_TextHoloBodyHighlight", "CRB_InterfaceMedium_O", "left")
			
			return xml			
		end,
	}

	ops = {
		["strSource"]	= "server",
	}
	self:RegisterDataText(self, "Time", dt, ops)
	self:RegisterDefaultOptions(self, "Time")
	
	local tName = {
		["strSource"] = "Source",
	}
	local tCustOps = {
		["server"] = "Server",
		["local"] = "Local",
	}
	local funcCallFunction = function(strSelection)
		--Print(strSelection)
	end
	self:RegisterMenuOption(self, "Time", tName, tCustOps, nil, 4)
	
	--Currency
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "Gold: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "CRB_CurrencySprites:sprArtTier3",
		["nIconSize"]	= 17,
		["OnUpdate"]	= function()
			local type
			if self.db.profile.tDTOptions["Gold"] then
				type = tonumber(self.db.profile.tDTOptions["Gold"]["nDisplayMode"])
			else
				type = 1
			end
			local nMoney = GameLib.GetPlayerCurrency(1):GetAmount()
			local nMoneyGained = nMoney - self.nStartingMoney
			local strMoneyGainedString = CopperToMoneyString(nMoneyGained)
			local text
			if type == 1 then
				text = ShortenMoneyString(GameLib.GetPlayerCurrency(1):GetMoneyString()) --money[1].."p, "..money[2].."g, "..money[3].."s, "..money[4].."c "
			elseif type == 2 then
				text = strMoneyGainedString.." gained"
			end
			return text			
		end
	}
	ops = {
		["nDisplayMode"] = 1,
	}

	self:RegisterDataText(self, "Gold", dt, ops)
	self:RegisterDefaultOptions(self, "Gold")

	local tName = {
		["nDisplayMode"] = "Display Mode",
	}
	local tCustOps = {
		[1] = "Total Money",
		[2] = "Gained Session",
		--[3] = "XPtoLvl",
	}
	self:RegisterMenuOption(self, "Gold", tName, tCustOps, nil, 4)
	
	local Number_of_Currencies = 14
	
	--Character Currencies (Added by Charge)
	for i = 2, Number_of_Currencies, 1 do
		if i ~= 8 then -- 8 = Gold 
			local Currency = GameLib.GetPlayerCurrency(i)
			local info =  Currency:GetDenomInfo()[1]
			local dt = {
				["type"]		= "dataFeed",
				["strLabel"]	= info.strName..": ",
				["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
				["crText"]		= ApolloColor.new("white"),
				["imgIcon"]		= info.strSprite,
				["nIconSize"]	= 17,
				["OnUpdate"]	= function()
					local nCurrency = GameLib.GetPlayerCurrency(i)
					local text = tostring(nCurrency:GetAmount())
					return text	
				end
			}
			-- For some reason it doesn'T show all essences when use inf.strName only (therefor replaced with  info.strName.." "
			self:RegisterDataText(self, info.strName.." ", dt,  nil)
			self:RegisterDefaultOptions(self, info.strName.." ")
		end
	end
	
	--Account Currencies (Added by Charge)
	for i = 1, 14, 1 do
	if i ~=10 and i ~= 4 then
		local ACurrency = AccountItemLib.GetAccountCurrency(i)
		local Ainfo =  ACurrency:GetDenomInfo()[1]	
				dt = {
				["type"]		= "dataFeed",
				["strLabel"]	= Ainfo.strName..": ",
				["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
				["crText"]		= ApolloColor.new("white"),
				["imgIcon"]		= Ainfo.strSprite,
				["nIconSize"]	= 17,
				["OnUpdate"]	= function()
					local nACurrency = AccountItemLib.GetAccountCurrency(i)
					local text = tostring(nACurrency:GetAmount())
					return text	
				end
			}
			self:RegisterDataText(self, Ainfo.strName.."  ", dt, nil)
			self:RegisterDefaultOptions(self, Ainfo.strName.."  ")
		end
	end
	--The following function is replaces by function in line 444 (from Charge) 
	--[[
	--Currency
	if self.db.profile.tDTOptions["Currency"] == nil or self.db.profile.tDTOptions["Currency"]["nDisplayMode"] == 1 then
		--self.db.profile.tDTOptions["Currency"] = {}
		--self.db.profile.tDTOptions["Currency"]["nDisplayMode"] = 3
		--self.db.profile.tDTOptions["Currency"]["nDisp"] = 1
	end

	local ddt = {
		["type"]		= "dataFeed",
		["strLabel"]	= function()
			if self.db.profile.tDTOptions["Currency"] == nil or self.db.profile.tDTOptions["Currency"]["nDisplayMode"] == 1 then
				return GameLib.GetPlayerCurrency(3):GetDenomInfo()[1].strName..": "
			else
				return GameLib.GetPlayerCurrency(tonumber(self.db.profile.tDTOptions["Currency"]["nDisplayMode"])):GetDenomInfo()[1].strName..": "
			end
		end,
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= function()
			if self.db.profile.tDTOptions["Currency"] == nil or self.db.profile.tDTOptions["Currency"]["nDisplayMode"] == 1 then
				return GameLib.GetPlayerCurrency(3):GetDenomInfo()[1].strSprite
			else
				return GameLib.GetPlayerCurrency(tonumber(self.db.profile.tDTOptions["Currency"]["nDisplayMode"])):GetDenomInfo()[1].strSprite
			end
		end,
		["nIconSize"]	= 17,
		["OnUpdate"]	= function()
			local type = self.db.profile.tDTOptions["Currency"]["nDisplayMode"]
			local tInfo =  GameLib.GetPlayerCurrency(type):GetDenomInfo()[1]
			local strName = tInfo.strName
			local strImg = tInfo.strSprite
			self.DataTexts.Currency.strLabel = strName..": "
			self.DataTexts.Currency.imgIcon = strImg
			local nMoney = GameLib.GetPlayerCurrency(type):GetAmount()
			local nMoneyGained
			if self.tStartingCurrency[type] then
				nMoneyGained = nMoney - self.tStartingCurrency[type]
			else
				nMoneyGained = 0
			end
			--local strMoneyGainedString = CopperToMoneyString(nMoneyGained)
			local text
			local dtype = tonumber(self.db.profile.tDTOptions["Currency"]["nDisp"])
			if dtype == 1 then
				text = nMoney
			elseif dtype == 2 then
				text = nMoneyGained.." gained"
			else
				text = nMoney
			end
			return text			
		end
	}
	ops = {
		["nDisplayMode"] = 3,
		["nDisp"] = 1,
	}

	self:RegisterDataText(self, "Currency", ddt, ops)
	self:RegisterDefaultOptions(self, "Currency")

	local tName = {
		["nDisplayMode"] = "Currency Type",
	}
	local tCustOps = {
		[2] = "Renown",
		[3] = "Elder Gems",
		[4] = "Crafting Vouchers",
		[5] = "Prestige",
	}
	self:RegisterMenuOption(self, "Currency", tName, tCustOps, nil, 4)
	
	local tName = {
		["nDisp"] = "Display Mode",
	}
	local tCustOps = {
		"Amount",
		"Gained",
	}
	self:RegisterMenuOption(self, "Currency", tName, tCustOps, nil, 4)
	
	]]--
		
	--Latency
	
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "Ping: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "CRB_DatachronSprites:sprDCPP_ExUplinkIconOn",
		["nIconSize"]	= nil,
		["OnUpdate"]	= function()
			local text = GameLib.GetLatency().." | "..GameLib.GetPingTime().." ms"
			return text			
		end
	}

	self:RegisterDataText(self, "Latency", dt, nil)
	self:RegisterDefaultOptions(self, "Latency")
	
	--Coords
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "Coords: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "CRB_DatachronSprites:sprDCM_CallIcon",
		["nIconSize"]	= nil,
		["OnUpdate"]	= function()
			local type
			if self.db.profile.tDTOptions["Coordinates"] then
				type = tonumber(self.db.profile.tDTOptions["Coordinates"]["nDisplayMode"])
			else
				type = 1
			end
			local coords
			local text
			if GameLib.GetPlayerUnit() then
				coords = GameLib.GetPlayerUnit():GetPosition()
			else
				coords = {x = 0, y = 0}
			end
			
			if GetCurrentZoneName() then
				if type == 1 then
					text = GetCurrentZoneName().." ("..round(coords.x, 1)..", "..round(coords.y, 1)..")"
				elseif type == 2 then
					text = "("..round(coords.x, 1)..", "..round(coords.y, 1)..")"
				elseif type == 3 then
					text = GetCurrentZoneName()
				end
			else
				text = "(-, -)"
			end
			return text			
		end
	}
	ops = {
		["nDisplayMode"] = 1,
	}
	--_G.GetCurrentSubZoneName()
	self:RegisterDataText(self, "Coordinates", dt, ops)
	self:RegisterDefaultOptions(self, "Coordinates")
	local tName = {
		["nDisplayMode"] = "Display Mode",
	}
	local tCustOps = {
		[1] = "Zone+Coords",
		[2] = "Coords",
		[3] = "Zone",
	}
	self:RegisterMenuOption(self, "Coordinates", tName, tCustOps, nil, 4)
	
	--Prof1
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "-",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "CRB_Basekit:kitIcon_Holo_Archive",
		["nIconSize"]	= nil,
		["OnUpdate"]	= function()
			local text = " "
			local type = tonumber(self.db.profile.tDTOptions["Proffesion 1"]["nDisplayMode"])
			local info = CraftingLib.GetTradeskillInfo(GetProfs()[1])
			if info then
			if type == 3 then
				local nToNext = info.nXpForNextTier - info.nXp
				if info.nXp == info.nXpMax then
					text = "Max Tier"
				else
					text = nToNext.."xp to Tier "..(info.eTier + 1)
				end
			elseif type == 2 then
				text = info.nXp.."xp"
			elseif type == 1 then
				text = info.nXp.."/"..info.nXpMax.."xp"
			end
			end
			
			return text			
		end
	}
	dt.strLabel = GetProfs() and CraftingLib.GetTradeskillInfo(GetProfs()[1]) and CraftingLib.GetTradeskillInfo(GetProfs()[1])["strName"]..": "
	ops = {
		["nDisplayMode"] = 1,
	}
	self:RegisterDataText(self, "Proffesion 1", dt, ops)
	self:RegisterDefaultOptions(self, "Proffesion 1")
	
	local tName = {
		["nDisplayMode"] = "Display Mode",
	}
	local tCustOps = {
		[1] = "Curr/Max",
		[2] = "Current",
		[3] = "XPtoLvl",
	}
	self:RegisterMenuOption(self, "Proffesion 1", tName, tCustOps, nil, 4)
	
	--Prof2
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "-",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "CRB_Basekit:kitIcon_Holo_Archive",
		["nIconSize"]	= nil,
		["OnUpdate"]	= function()
			local text = " "
			local type = tonumber(self.db.profile.tDTOptions["Proffesion 2"]["nDisplayMode"])
			local info = CraftingLib.GetTradeskillInfo(GetProfs()[2])
			if info then
			if type == 3 then
				local nToNext = info.nXpForNextTier - info.nXp
				if info.nXp == info.nXpMax then
					text = "Max Tier"
				else
					text = nToNext.."xp to Tier"..(info.eTier + 1)
				end
			elseif type == 2 then
				text = info.nXp.."xp"
			elseif type == 1 then
				text = info.nXp.."/"..info.nXpMax.."xp"
			end
			end
			
			return text			
		end,
	}
	dt.strLabel = GetProfs() and CraftingLib.GetTradeskillInfo(GetProfs()[2]) and CraftingLib.GetTradeskillInfo(GetProfs()[2])["strName"]..": "
	ops = {
		["nDisplayMode"] = 1,
	}
	self:RegisterDataText(self, "Proffesion 2", dt, ops)
	self:RegisterDefaultOptions(self, "Proffesion 2")
	
	local tName = {
		["nDisplayMode"] = "Display Mode",
	}
	local tCustOps = {
		[1] = "Curr/Max",
		[2] = "Current",
		[3] = "XPtoLvl",
	}
	self:RegisterMenuOption(self, "Proffesion 2", tName, tCustOps, nil, 4)

	local function GetPlayerPathName()
		local nPathType = PlayerPathLib.GetPlayerPathType()
		local strPathName = " - "
		if nPathType == PlayerPathLib.PlayerPathType_Explorer then
			strPathName = "Explorer"
		elseif nPathType == PlayerPathLib.PlayerPathType_Scientist then
			strPathName = "Scientist"
		elseif nPathType == PlayerPathLib.PlayerPathType_Settler then
			strPathName = "Settler"
		elseif nPathType == PlayerPathLib.PlayerPathType_Soldier then
			strPathName = "Soldier"
		end
		return strPathName
	end
	local function GetClosestPathMision()
		local tMissions
		local uEp = PlayerPathLib.GetCurrentEpisode()
		if uEp then
			tMissions = uEp:GetMissions()
		else
			return nil
		end
		local uClosestMision
		for idx, uMission in ipairs(tMissions) do
			if uMission:GetName() ~= "" and not uMission:IsComplete() then
				local nDist = uMission:GetDistance()
				if not uClosestMision then
					uClosestMision = uMission
				end
				if nDist > uClosestMision:GetDistance() then
					uClosestMision = uMission
				end
			end
		end
		return uClosestMision
	end
	local function GetPathObjNeedString(uMission)
		if uMission:GetNumCompleted() and uMission:GetNumNeeded() then
			return "("..uMission:GetNumCompleted().."/"..uMission:GetNumNeeded()..")"
		else
			return "N/A"
		end
	end
	local tPathIcons = {
		[PlayerPathLib.PlayerPathType_Explorer] = "CRB_MinimapSprites:sprMM_SmallIconExplorer",
		[PlayerPathLib.PlayerPathType_Scientist] = "CRB_MinimapSprites:sprMM_SmallIconScientist",
		[PlayerPathLib.PlayerPathType_Settler] = "CRB_MinimapSprites:sprMM_SmallIconSettler",
		[PlayerPathLib.PlayerPathType_Soldier] = "CRB_MinimapSprites:sprMM_SmallIconSoldier",
	}
	--Path
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= GetPlayerPathName()..": ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= tPathIcons[PlayerPathLib.GetPlayerPathType()],
		["nIconSize"]	= nil,
		["OnUpdate"]	= function()
			local text
			local type = tonumber(self.db.profile.tDTOptions["Path"]["nDisplayMode"])
			local strPathName = GetPlayerPathName()
			local uClosestMission = GetClosestPathMision()
			local strName, nDist, strNeed
			if uClosestMission then
				strName = uClosestMission:GetName() or "-"
				nDist = (string.find(uClosestMission:GetDistance(), "e") and 0) or round(uClosestMission:GetDistance())
				strNeed = GetPathObjNeedString(uClosestMission)
			else
				strName = "N/A"
				nDist = 0
				strNeed = "-"
			end
			local tXpData = {
				["nXp"] = PlayerPathLib.GetPathXP() or 0,
				["nXpMax"] = PlayerPathLib.GetPathXPAtLevel(PlayerPathLib.GetPathLevel()+1) or 0,
				["nXpToLvl"] = 0,
				["nNextLvl"] = PlayerPathLib.GetPathLevel()+1 or 0,
			}
			tXpData.nXpToLvl = tXpData.nXpMax - tXpData.nXp
			if type == 1 then
				if uClosestMission then
					text = strName.." - "..nDist.."m"
				else
					text = "No Missions"
				end
			elseif type == 2 then
				if uClosestMission then
					text = strName.." "..strNeed
				else
					text = "No Missions"
				end
			elseif type == 3 then
				if uClosestMission then
					text = nDist.."m "..strNeed
				else
					text = "No Missions"
				end
			elseif type == 4 then
				text = tXpData.nXp.."/"..tXpData.nXpMax.."xp"
			elseif type == 5 then
				text = tXpData.nXpToLvl.."xp to lvl "..tXpData.nNextLvl
			end
			return text			
		end,
		["OnTooltip"] = function()
			local xml = XmlDoc.new()
			local strPathName = GetPlayerPathName()
			local uClosestMission = GetClosestPathMision()
			local strName, nDist, strNeed
			if uClosestMission then
				strName = uClosestMission:GetName() or "-"
				nDist = (string.find(uClosestMission:GetDistance(), "e") and 0) or round(uClosestMission:GetDistance())
				strNeed = GetPathObjNeedString(uClosestMission)
			else
				strName = "N/A"
				nDist = 0
				strNeed = "-"
			end
			local tXpData = {
				["nXp"] = PlayerPathLib.GetPathXP() or 0,
				["nXpMax"] = PlayerPathLib.GetPathXPAtLevel(PlayerPathLib.GetPathLevel()+1) or 0,
				["nXpToLvl"] = 0,
				["nNextLvl"] = PlayerPathLib.GetPathLevel()+1 or 0,
			}
			tXpData.nXpToLvl = tXpData.nXpMax - tXpData.nXp
			xml:AddLine(strPathName, "UI_TextHoloTitle", "CRB_InterfaceLarge_O", "Left")
			xml:AddLine(" ", "UI_TextHoloTitle", "CRB_InterfaceMedium", "Left")
			xml:AddLine("Closest Mission:     ", "UI_TextHoloBody", "CRB_InterfaceMedium_O", "Left")
			xml:AddLine("          "..strName, "UI_TextHoloBodyHighlight", "CRB_InterfaceMedium_O", "Left")
			xml:AddLine("Distance:     ", "UI_TextHoloBody", "CRB_InterfaceMedium_O", "Left")
			xml:AddLine("          "..nDist, "UI_TextHoloBodyHighlight", "CRB_InterfaceMedium_O", "Left")
			xml:AddLine("Objective:     ", "UI_TextHoloBody", "CRB_InterfaceMedium_O", "Left")
			xml:AddLine("          "..strNeed, "UI_TextHoloBodyHighlight", "CRB_InterfaceMedium_O", "Left")
			xml:AddLine("Experience:     ", "UI_TextHoloBody", "CRB_InterfaceMedium_O", "Left")
			xml:AddLine("          "..tXpData.nXp.."/"..tXpData.nXpMax.."xp Lvl "..(tXpData.nNextLvl-1), "UI_TextHoloBodyHighlight", "CRB_InterfaceMedium_O", "Left")
			
			return xml
		end,
	}

	ops = {
		["nDisplayMode"] = 1,
	}
	self:RegisterDataText(self, "Path", dt, ops)
	self:RegisterDefaultOptions(self, "Path")
	
	local tName = {
		["nDisplayMode"] = "Display Mode",
	}
	local tCustOps = {
		[1] = "Distance",
		[2] = "Objective",
		[3] = "Dist+Obj",
		[4] = "Xp/Max",
		[5] = "XpToLvl",
	}
	self:RegisterMenuOption(self, "Path", tName, tCustOps, nil, 4)
	
	--XP
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "XP: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "IconSprites:Icon_Windows_UI_CRB_LevelUp_NewGeneralFeature",
		["nIconSize"]	= nil,
		["OnUpdate"]	= function()
			local text
			local nLvl				= GameLib.GetPlayerLevel()
			local nXpTotal			= GetXp()
			local nXpPercent		= GetXpPercentToNextLevel()
			local nXpMax			= GetXpToNextLevel()
			local nXpToCurrentLvl	= GetXpToCurrentLevel()
			local nXp				= (nXpTotal - nXpToCurrentLvl)
			local nXpNeeded			= (nXpMax - nXp)
			local nRestXp			= GetRestXp()
			local nRestXpPercent	= nRestXp / nXpNeeded * 100
			local nRestXpPool		= GetRestXpKillCreaturePool()
			local nRestXpEnd		= ((nRestXpPool + nXp)  / nXpMax) * 100
			-- Also do kills to level
			if nLvl == 50 then
				return "Max Level"
			end
			if not self.nXpSession then
				self.nXpSession = GetXp()
			end
			local x = self.nXpSession / (os.time() - self.nTimeSessionStart) --FINISH!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			local type = tonumber(self.db.profile.tDTOptions["XP"]["nDisplayMode"])
			
			if type == 1 then
				text = nXp.."/"..nXpMax.."xp ("..round(nXpPercent, 2).."%)"
			elseif type == 2 then
				text = nXpNeeded.."xp to Next Level"
			elseif type == 3 then
				if false then
					text = "xp/Hour"
				else
					text = "-"
				end
			elseif type == 4 then
				text = nRestXp.."xp ("..nRestXpPercent.."% of level)"
			elseif type == 5 then
				if nXp + nRestXpPool > nXpMax then 
					text = "Rest XP Ends After Level"
				else
					text = "End of Rest XP: "..nRestXpPool.." ("..nRestXpEnd.."% of level)"
				end
			end
			
			return text			
		end,
		
	}

	ops = {
		["nDisplayMode"] = 1,
	}
	self:RegisterDataText(self, "XP", dt, ops)
	self:RegisterDefaultOptions(self, "XP")
	
	local tName = {
		["nDisplayMode"] = "Display Mode",
	}
	local tCustOps = {
		[1] = "XP",
		[2] = "XP Needed",
		--[3] = "XP/Sec",
		[4] = "Rest XP",
		[5] = "End of Rest XP",
	}
	self:RegisterMenuOption(self, "XP", tName, tCustOps, nil, 4)
	--GetElderPoints = <function 598>,
--  getfenv = <function 599>,
 -- GetItemInfo = <function 604>,
  --GetPeriodicElderPoints = <function 610>,
	--ELDER
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "EP: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= nil, --"IconSprites:Icon_Windows_UI_CRB_LevelUp_NewGeneralFeature",
		["nIconSize"]	= nil,
		["OnUpdate"]	= function()
			local text
			local nLvl				= GameLib.GetPlayerLevel()
			local nCurrentEP		= GetElderPoints()
			local nCurrentToDailyMax = GetPeriodicElderPoints()
			local nEpNeeded			= nCurrentToDailyMax - nCurrentEP
			local nEPToAGem			= GameLib.ElderPointsPerGem
			local nEPDailyMax		= GameLib.ElderPointsDailyMax
			local nRestedEP 		= GetRestXp() 							-- amount of rested xp
			local nRestedEPPool		= GetRestXpKillCreaturePool() 		-- amount of rested xp remaining from creature kills
			local strEpPerc			= string.format("(%.1f%%)", math.min(99.9, nCurrentEP / nEPToAGem * 100))
			local strEpPercWeekly	= string.format("(%.1f%%)", math.min(99.9, nCurrentToDailyMax / nEPDailyMax * 100))
			local strMinMax			= string.format("%d/%d", nCurrentEP, nEPToAGem)
			local strMinMaxWeekly	= string.format("%d/%d", nCurrentToDailyMax, nEPDailyMax)
			local nRestXp			= GetRestXp()
			local nRestXpPool		= GetRestXpKillCreaturePool()
			local nRestXpEnd		= ((nRestXpPool + nCurrentEP)  / nEPToAGem) * 100
			local nRestXpPercent	= nRestXp / nEpNeeded * 100
			if not self.nEpSession then
				self.nEpSession = nCurrentEP
			end
			
			local nDiffEP = nCurrentEP - self.nEpSession 
			local nDiffTime = (os.time() - self.nTimeSessionStart) / 3600
			local nEpPerHour = round(nDiffEP / nDiffTime, 1)
			local type = tonumber(self.db.profile.tDTOptions["EP"]["nDisplayMode"])
			
			if type == 1 then
				if nCurrentEP == nEPDailyMax then
					text = "Max EP"
				else
					text = string.format("%s %s", strMinMax, strEpPerc)
				end
			elseif type == 2 then
				if nCurrentEP == nEPDailyMax then
					text = "Max EP"
				else
					text = string.format("%s %s", strMinMaxWeekly, strEpPercWeekly)
				end
			elseif type == 3 then
				if nEpPerHour ~= 0 then
					text = StarPanel:FormatBigNumber(nEpPerHour).." EP/h"
				else
					text = "n/a"
				end
			elseif type == 4 then
				text = nRestXp.." EP ("..round(nRestXpPercent).."% to gem)"
			--elseif type == 5 then
			--	if nXp + nRestXpPool > nXpMax then 
			--		text = "Rest XP Ends After Level"
			--	else
			--		text = "End of Rest XP: "..nRestXpPool.." ("..nRestXpEnd.."% of level)"
			--	end
			end
			
			return text			
		end,
		
	}

	ops = {
		["nDisplayMode"] = 1,
	}
	self:RegisterDataText(self, "EP", dt, ops)
	self:RegisterDefaultOptions(self, "EP")
	
	local tName = {
		["nDisplayMode"] = "Display Mode",
	}
	local tCustOps = {
		[1] = "Current",
		[2] = "Weekly",
		[3] = "EP/Hour",
		[4] = "Rest EP",
		--[5] = "End of Rest EP",
	}
	self:RegisterMenuOption(self, "EP", tName, tCustOps, nil, 4)
	
	--Durability
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "Durability: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "CRB_Inventory:sprPersonaWrenchIcon",
		["nIconSize"]	= nil,
		["OnUpdate"]	= function()
			local text = ""
			local player = GameLib.GetPlayerUnit()
			local type = tonumber(self.db.profile.tDTOptions["Durability"]["nDisplayMode"])
			local nRepairCost = GameLib.GetRepairAllCost()
			local aEquippedItems
			if player then
				aEquippedItems = GameLib.GetPlayerUnit():GetEquippedItems()
			else
				aEquippedItems = {}
			end
			local aItemDurabilities = {}
			local nAllDurs = 0
			local nItems = 0
			for i, item in pairs(aEquippedItems) do
				--table.insert(aItemDurabilities, item:GetDurability())
				--nAllDurs = nAllDurs + item:GetDurability()
				if item:GetMaxDurability() > 0 then
					nItems = nItems + 1
					nAllDurs = nAllDurs + (item:GetDurability()  / item:GetMaxDurability())
				end
				--Print(item:GetDurability())
			end
			local nDurAvg = (nAllDurs / nItems) * 100
			if type == 1 then
				text = round(nDurAvg).."%"
			elseif type == 2 then
				text = CopperToMoneyString(nRepairCost)
			end
			return text			
		end,
		["OnTooltip"] = function()
			local unitPlayer = GameLib.GetPlayerUnit()
			if unitPlayer == nil then
				return
			end
			local xml = XmlDoc.new()
			local aEquippedItems = unitPlayer:GetEquippedItems()
			xml:AddLine("Durability", "UI_TextHoloTitle", "CRB_InterfaceLarge_O", "Left")
			xml:AddLine(" ", "UI_TextHoloTitle", "CRB_InterfaceMedium", "Left")
			for i, item in pairs(aEquippedItems) do
				if item:GetMaxDurability() > 0 then
					xml:AddLine(item:GetItemTypeName()..":     ", "UI_TextHoloBody", "CRB_InterfaceMedium_O", "Left")
					xml:AddLine("          "..round(((item:GetDurability() / item:GetMaxDurability()) * 100)).."%", "UI_TextHoloBodyHighlight", "CRB_InterfaceMedium_O", "Left")
				end
			end
			
			return xml
		end,
	}

	ops = {
		["nDisplayMode"] = 1,
	}
	self:RegisterDataText(self, "Durability", dt, ops)
	self:RegisterDefaultOptions(self, "Durability")
	
	local tName = {
		["nDisplayMode"] = "Display Mode",
	}
	local tCustOps = {
		[1] = "Durability",
		[2] = "Repair Cost",
		--[3] = "",
		--[4] = "",
		--[5] = "",
	}
	self:RegisterMenuOption(self, "Durability", tName, tCustOps, nil, 4)
	
	--Bags
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "Bags: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "CRB_Inventory:sprPersonaBagIcon",
		["nIconSize"]	= nil,
		["OnUpdate"]	= function()
			local text = ""
			local type = tonumber(self.db.profile.tDTOptions["Bags"]["nDisplayMode"])
			local nBagSlotsFree = GameLib.GetEmptyInventorySlots()
			local nBagMaxSlots = GameLib.GetTotalInventorySlots()
			local nBagSlotsUsed = nBagMaxSlots - nBagSlotsFree
			if type == 1 then
				text = nBagSlotsFree
			elseif type == 2 then
				text = nBagSlotsUsed.."/"..nBagMaxSlots 
			end
			return text			
		end,
		["OnClick"]		= function()
			Event_FireGenericEvent("ToggleInventory")
		end
	}

	ops = {
		["nDisplayMode"] = 1,
	}
	self:RegisterDataText(self, "Bags", dt, ops)
	self:RegisterDefaultOptions(self, "Bags")
	
	local tName = {
		["nDisplayMode"] = "Display Mode",
	}
	local tCustOps = {
		[1] = "Slots Free",
		[2] = "Slots Used",
	}
	self:RegisterMenuOption(self, "Bags", tName, tCustOps, nil, 4)
	
	
	--Friends
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "Friends: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "HUD_BottomBar:spr_HUD_MenuIcons_Social",
		["nIconSize"]	= 22,
		["OnUpdate"]	= function()
			local text
			local nFriendsOn = 0
			for k, v in pairs(FriendshipLib.GetList()) do
				if v.fLastOnline == 0 then
					nFriendsOn = nFriendsOn + 1
				end
			end
			for k, v in pairs(FriendshipLib.GetAccountList()) do
				if v.fLastOnline == 0 then
					nFriendsOn = nFriendsOn + 1
				end
			end
			
			text = nFriendsOn.." online"
			return text			
		end,
		["OnClick"]		= function()
			Event_FireGenericEvent("ToggleSocialWindow")
		end
	}

	self:RegisterDataText(self, "Friends", dt)
	self:RegisterDefaultOptions(self, "Friends")
	
	--Guild
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "Guild: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "HUD_BottomBar:spr_HUD_MenuIcons_Social",
		["nIconSize"]	= 22,
		["OnUpdate"]	= function()
			local text = ""
			local userGuild
			for i, guild in pairs(GuildLib.GetGuilds()) do
				local type = guild:GetType()
				-- can i just do guild:GetType() ?
				if type == GuildLib.GuildType_Guild then
					userGuild = guild
				end
			end
			if userGuild ~= nil then
				self.DataTexts.Guild.strLabel = userGuild:GetName()..": "
				text = userGuild:GetOnlineMemberCount().." online"
			else	
				text = "No Guild"
			end
			return text			
		end,
		["OnClick"]		= function()
			Event_FireGenericEvent("ToggleGuild")
		end
	}

	self:RegisterDataText(self, "Guild", dt)
	self:RegisterDefaultOptions(self, "Guild")
	
	--WSIM
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "WSIM: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "HUD_BottomBar:spr_HUD_MenuIcons_Social",
		["nIconSize"]	= 17,
		["OnUpdate"]	= function()
			if WSIM_GetNumNewMsg == nil then return "" end
			local nNew = WSIM_GetNumNewMsg()
			local text = ""
			if nNew == 0 then
				text = "No New Msgs"
			elseif nNew == 1 then
				text = nNew.." New Msg"
			else
				text = nNew.." New Msgs"
			end
			return text			
		end,
		["OnClick"]		= function(wndControl)
			Event_FireGenericEvent("WSIM_ToggleNotificationList", wndControl)
		end
	}

	self:RegisterDataText(self, "WildStar Instant Messenger", dt)
	self:RegisterDefaultOptions(self, "WildStar Instant Messenger")
	--[[########################################################
	To Finish:
	+XP (time to lvl)
	+
	.......
	Addon move script - shift bottom ui up
	------------------------------------------------------------
	To Do:
	+Autohide --Maybe?
	+Opacity --Maybe?
	+Sound
	+Friends/Guild (Social)
	+Other Currency (Renown)
	+Quest (similar to path) --Maybe?
	+Gathered --http://www.curse.com/addons/wow/titan-gathered
	+Run Speed? Dash?
	+Spell Power --Find WS version
	############################################################]]
	--initialize
	self:SetPositionsTop(self)
	self:RefreshTopDisplay(self)
	
	self:SetPositionsBot(self)
	self:RefreshBotDisplay(self)
	
	self.timerUpdate = ApolloTimer.Create(self.db.profile.dataTexts.nUpdateInterval, true, "OnUpdate", self)
	self.timerUpdate:Start()
end

-----------------------------------------------------------------------------------------------
-- StarPanel Functions
-----------------------------------------------------------------------------------------------
--/eval Print(Apollo.GetMouseTargetWindow():GetParent():GetName())
-- on SlashCommand "/sp"

function StarPanel:CreateDataTextsTop(self)
	self.wndTopDisplay:FindChild("Container"):DestroyChildren()
	self.tDataTextsTop = {}
	local nLastPos = 0
	for name, tData in pairs(self.DataTexts) do
		nLastPos = nLastPos + 1
	end
	for i=1, nLastPos do
		for name, tData in pairs(self.DataTexts) do
			local tOptions = self.db.profile.tDTOptions[name]
			if i == tOptions.nPos.top then
				local wndCurr
				local width = 0

				if tData.type == "dataFeed" and tOptions.bShownTop then
					wndCurr = Apollo.LoadForm(self.xmlDoc, "DataFeedItem", self.wndTopDisplay:FindChild("Container"), self)
					
					--Create XML and Locals
					local xml = XmlDoc.new()
					local crLabel = tData.crLabel
					local crText = tData.crText
					local strLabel = tData.strLabel
					local strText = tData.OnUpdate()
					local nIconSize = tData.nIconSize or 20
					
					--start
					xml:AddLine("", nil, "CRB_InterfaceMedium_O", "Center")
					
					--Append image
					if tData.imgIcon and tOptions.bShowIcon then
						xml:AppendImage(tData.imgIcon, nIconSize, nIconSize)
					end
										
					--Append Label
					if strLabel and tOptions.bShowLabel then
						if type(strLabel) == "string" then
							xml:AppendText(strLabel, crLabel, "CRB_InterfaceMedium_O", "Center")
						end
					end
					
					--Append Text
					xml:AppendText(strText, crText, "CRB_InterfaceMedium_O", "Center")
					
					--Set Doc
					wndCurr:SetDoc(xml)
					
					--Set ToolTip
					if tData.OnTooltip then
						wndCurr:SetTooltipDoc(tData.OnTooltip())
					end
					
					--Set Name
					wndCurr:SetName(name)
					--wndCurr:SetText(tData.text)
					wndCurr:SetData(tData) --onUpdate and onClick functions are contained in this

					if strLabel and type(strLabel) == "string" then
						width = math.max(wndCurr:GetContentSize()+self.db.profile.topBar.nPadding, Apollo.GetTextWidth("CRB_InterfaceMedium_O", strLabel..strText)+nIconSize+self.db.profile.topBar.nPadding)
						local l, t, r, b = wndCurr:GetAnchorOffsets()
						wndCurr:SetAnchorOffsets(l, t, l+width, b)
					
						self.tDataTextsTop[tOptions.nPos.top] = wndCurr
					end
				elseif tOptions.bShownTop then
					--is launcher type
					
					wndCurr = Apollo.LoadForm(self.xmlDoc, "DataFeedItem", self.wndTopDisplay:FindChild("Container"), self)
					
					--Create XML and Locals
					local xml = XmlDoc.new()
					local crLabel = tData.crLabel
					local strLabel = tData.strLabel
					local nIconSize = tData.nIconSize or 20
					
					if not tOptions.bShowIcon and not tOptions.bShowLabel then
						--do something to stop them!
						tOptions.bShowLabel = true
					end
					
					--start
					xml:AddLine("", nil, "CRB_InterfaceMedium_O", "Center")
					
					--Append image
					if tData.imgIcon and tOptions.bShowIcon then
						xml:AppendImage(tData.imgIcon, nIconSize, nIconSize)
					end
										
					--Append Label
					if strLabel and tOptions.bShowLabel then	
						xml:AppendText(strLabel, crLabel, "CRB_InterfaceMedium_O", "Center")
					end

					--Set Doc
					wndCurr:SetDoc(xml)
					
					--Set ToolTip
					if tData.OnTooltip then
						wndCurr:SetTooltipForm(tData.OnTooltip())
					end
					
					--Set Name
					wndCurr:SetName(name)
					--wndCurr:SetText(tData.text)
					wndCurr:SetData(tData) --onUpdate and onClick functions are contained in this
					
					width = wndCurr:GetContentSize()+self.db.profile.topBar.nPadding
					local l, t, r, b = wndCurr:GetAnchorOffsets()
					wndCurr:SetAnchorOffsets(l, t, l+width, b)
					
					self.tDataTextsTop[tOptions.nPos.top] = wndCurr
				end
				
				--Print(wndCurr:GetName())
				break
			end
		end
				
	end
	
end

function StarPanel:CreateDataTextsBot(self)
	self.wndBotDisplay:FindChild("Container"):DestroyChildren()
	self.tDataTextsBot = {}
	local nLastPos = 0
	for name, tData in pairs(self.DataTexts) do
		nLastPos = nLastPos + 1
	end
	for i=1, nLastPos do
	for name, tData in pairs(self.DataTexts) do
			local tOptions = self.db.profile.tDTOptions[name]
			if i == tOptions.nPos.bot then
			local wndCurr
			local width = 0
				if tData.type == "dataFeed" and tOptions.bShownBot then
					wndCurr = Apollo.LoadForm(self.xmlDoc, "DataFeedItem", self.wndBotDisplay:FindChild("Container"), self)
					--Print(tostring(tOptions.bShownTop))
					--Create XML and Locals
					local xml = XmlDoc.new()
					local crLabel = tData.crLabel
					local crText = tData.crText
					local strLabel = tData.strLabel
					local strText = tData.OnUpdate()
					local nIconSize = tData.nIconSize or 20
					
					--start
					xml:AddLine("", nil, "CRB_InterfaceMedium_O", "Center")
					
					--Append image
					if tData.imgIcon and tOptions.bShowIcon then
						if type(tData.imgIcon) == "function" then	
							xml:AppendImage(tData.imgIcon(), nIconSize, nIconSize)
						else
							xml:AppendImage(tData.imgIcon, nIconSize, nIconSize)
						end
					end
										
					--Append Label
					if strLabel and tOptions.bShowLabel then
						if type(strLabel) == "function" then	
							xml:AppendText(strLabel(), crLabel, "CRB_InterfaceMedium_O", "Center")
						else
							xml:AppendText(strLabel, crLabel, "CRB_InterfaceMedium_O", "Center")
						end
					end
					
					--Append Text
					xml:AppendText(strText, crText, "CRB_InterfaceMedium_O", "Center")
					
					--Set Doc
					wndCurr:SetDoc(xml)
					
					--Set ToolTip
					if tData.OnTooltip then
						wndCurr:SetTooltipDoc(tData.OnTooltip())
					end
					
					--Set Name
					wndCurr:SetName(name)
					--wndCurr:SetText(tData.text)
					wndCurr:SetData(tData) --onUpdate and onClick functions are contained in this
					
					
					--optional width, otherwise default
					width = wndCurr:GetContentSize()+self.db.profile.botBar.nPadding --25 is the padding
					local l, t, r, b = wndCurr:GetAnchorOffsets()
					wndCurr:SetAnchorOffsets(l, t, l+width, b)
					
				elseif tOptions.bShownBot then
					--is launcher type
					
					wndCurr = Apollo.LoadForm(self.xmlDoc, "DataFeedItem", self.wndBotDisplay:FindChild("Container"), self)
					
					--Create XML and Locals
					local xml = XmlDoc.new()
					local crLabel = tData.crLabel
					local strLabel = tData.strLabel
					local nIconSize = tData.nIconSize or 20
					
					if not tOptions.bShowIcon and not tOptions.bShowLabel then
						--do something to stop them!
						tOptions.bShowLabel = true
					end
					
					--start
					xml:AddLine("", nil, "CRB_InterfaceMedium_O", "Center")
					
					--Append image
					if tData.imgIcon and tOptions.bShowIcon then
						xml:AppendImage(tData.imgIcon, nIconSize, nIconSize)
					end
										
					--Append Label
					if strLabel and tOptions.bShowLabel then	
						xml:AppendText(strLabel, crLabel, "CRB_InterfaceMedium_O", "Center")
					end

					--Set Doc
					wndCurr:SetDoc(xml)
					
					--Set ToolTip
					if tData.OnTooltip then
						wndCurr:SetTooltipForm(tData.OnTooltip())
					end
					
					--Set Name
					wndCurr:SetName(name)
					--wndCurr:SetText(tData.text)
					wndCurr:SetData(tData) --onUpdate and onClick functions are contained in this
					
					
					--optional width, otherwise default
					width = wndCurr:GetContentSize()+self.db.profile.botBar.nPadding --25 is the padding
					local l, t, r, b = wndCurr:GetAnchorOffsets()
					wndCurr:SetAnchorOffsets(l, t, l+width, b)
				end
				self.tDataTextsBot[tOptions.nPos.bot] = wndCurr
				break
				end
				end
				
	end
	
end

local tAddonsMove = {
	["XPBar"] = {
		"wndArt",
		"wndMain",
		"wndInvokeForm",
	},
	["InterfaceMenuList"] = {
		"wndMain",
	},
	["ActionBarFrame"] = {
		"wndArt",
		"wndBar2",
		"wndBar3",
		"wndMain",
		--"wndBar1",
		"wndMountFlyout",
	},
	["RecallFrame"] = {
		--"wndMain",
	},
	["Datachron"] = {
		"wndMinimized",
	},
	["Global"] = {
		"g_wndActionBarResources",
		"g_wndDatachron",
	}
}
function StarPanel:ShiftBottomUI(nOffset)
if true then return false end
	for strAddon, tWnds in pairs(tAddonsMove) do
		if strAddon == "Global" then
			for idx, strWnd in ipairs(tWnds) do
				local l, t, r, b = _G[strWnd]:GetAnchorOffsets()
				_G[strWnd]:SetAnchorOffsets(l, t+nOffset, r, b+nOffset)
			end
		else
			local addon = Apollo.GetAddon(strAddon)
			if addon then
				for idx, strWnd in ipairs(tWnds) do
					local l, t, r, b = addon[strWnd]:GetAnchorOffsets()
					addon[strWnd]:SetAnchorOffsets(l, t+nOffset, r, b+nOffset)
				end
			end
		end
	end
	local Recall = Apollo.GetAddon("RecallFrame")
	if Recall then
		Apollo.FindWindowByName("RecallFrameForm"):Show(false)
		Recall.wndMain:Show(true)
	end
end

--[[
RecallFrame
self.wndShadow = Apollo.LoadForm(self.xmlDoc, "Shadow", "FixedHudStratumLow", self)
	self.wndArt = Apollo.LoadForm(self.xmlDoc, "Art", "FixedHudStratumLow", self)
	self.wndBar2 = Apollo.LoadForm(self.xmlDoc, "Bar2ButtonContainer", "FixedHudStratum", self)
	self.wndBar3 = Apollo.LoadForm(self.xmlDoc, "Bar3ButtonContainer", "FixedHudStratum", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "ActionBarFrameForm", "FixedHudStratum", self)
	self.wndBar1 = self.wndMain:FindChild("Bar1ButtonContainer")

]]
function StarPanel:OnStarPanelOn()
	self.wndOptions:Invoke() -- show the window
end

function StarPanel:OnConfigure()
	self.wndOptions:Invoke()
end

function StarPanel:GetCustomOptions(strName)
	return  self.db.profile.tDTOptions[strName]
end

function StarPanel:OnUpdate()
	StarPanel:UpdateTop(self)
	StarPanel:UpdateBot(self)
end

function StarPanel:UpdateTop(self)
	for nPos, wndCurr in pairs(self.tDataTextsTop) do
		local tData = wndCurr:GetData()
		
		local xml = XmlDoc.new()
		local crLabel = tData.crLabel
		local crText = tData.crText
		local strLabel = tData.strLabel
		local imgIcon = tData.imgIcon
		local nIconSize = tData.nIconSize or 20
		local strText = ""
		local tOptions = self:GetCustomOptions(wndCurr:GetName())
 
		if tData.type ~= "launcher" then
			strText = tData.OnUpdate()
		end
		
		if tData.type == "launcher" and not tOptions.bShowIcon and not tOptions.bShowLabel then
			--do something to stop them!
			tOptions.bShowLabel = true
		end
		
		--start
		xml:AddLine("", nil, "CRB_InterfaceMedium_O", "Center")
					
		--Append image
		if imgIcon and tOptions and tOptions.bShowIcon then
			xml:AppendImage(imgIcon, nIconSize, nIconSize)
		end
		
		--Append Label
		if strLabel and tOptions and tOptions.bShowLabel then	
			xml:AppendText(strLabel, crLabel, "CRB_InterfaceMedium_O", "Center")
		end
		
		--Append Text
		xml:AppendText(strText, crText, "CRB_InterfaceMedium_O", "Center")
		--Print(strText)
		--Set Doc
		wndCurr:SetDoc(xml)
	end
end

function StarPanel:UpdateBot(self)
	for nPos, wndCurr in pairs(self.tDataTextsBot) do
		local tData = wndCurr:GetData()
		
		local xml = XmlDoc.new()
		local crLabel = tData.crLabel
		local crText = tData.crText
		local strLabel = tData.strLabel
		local imgIcon = tData.imgIcon
		local nIconSize = tData.nIconSize or 20
		local strText = ""
		local tOptions = self:GetCustomOptions(wndCurr:GetName())
		
		if tData.type ~= "launcher" then
			strText = tData.OnUpdate()
		end
		
		if tData.type == "launcher" and not tOptions.bShowIcon and not tOptions.bShowLabel then
			--do something to stop them!
			tOptions.bShowLabel = true
		end
		
		--start
		xml:AddLine("", nil, "CRB_InterfaceMedium_O", "Center")
					
		--Append image
		if imgIcon and tOptions and tOptions.bShowIcon then
			xml:AppendImage(imgIcon, nIconSize, nIconSize)
		end
		
		--Append Label
		if strLabel and tOptions and tOptions.bShowLabel then	
			xml:AppendText(strLabel, crLabel, "CRB_InterfaceMedium_O", "Center")
		end
		
		--Append Text
		xml:AppendText(strText, crText, "CRB_InterfaceMedium_O", "Center")
		
		--Set Doc
		wndCurr:SetDoc(xml)
	end
end

local tAlignmentOptions = {
	["Left"] = "0",
	["Center"] = "1",
	["Right"] = "2",
}

function StarPanel:RefreshTopDisplay(self)
	self:CreateDataTextsTop(self)
	--table.sort(self.tDataTextsTop)
	local nTotalWidth = 0
	for nPos, wndCurr in pairs(self.tDataTextsTop) do
		local tOptions = self:GetCustomOptions(wndCurr:GetName())
		local width = wndCurr:GetWidth()
		local name = wndCurr:GetName()
		--fit on screen check
		nTotalWidth = nTotalWidth + width
		local nScreenWidth = self.wndTopDisplay:FindChild("Container"):GetWidth() --Apollo.GetScreenSize() - 10 --Spacing on bar sides
		if nScreenWidth < nTotalWidth then
			if not self.strLastCheckedNameTop then
				self.strLastCheckedNameTop = wndCurr:GetName()
			end
			self.db.profile.tDTOptions[self.strLastCheckedNameTop]["bShownTop"] = false
			if self.wndDataTexts:FindChild("OptionsDialogueControls"):FindChild(self.strLastCheckedNameTop) then
				self.wndTopDisplay:FindChild("Container"):FindChild(self.strLastCheckedNameTop):Destroy()
				--self.tDataTextsTop[nPos] = nil
				self.wndDataTexts:FindChild("OptionsDialogueControls"):FindChild(self.strLastCheckedNameTop):FindChild("Top"):SetCheck(false)
			end
			break
		end
	end
	self.wndTopDisplay:FindChild("Container"):ArrangeChildrenHorz(tAlignmentOptions[self.db.profile.topBar.strAlignment])
end

function StarPanel:RefreshBotDisplay(self)
	self:CreateDataTextsBot(self)
	--table.sort(self.tDataTextsTop)
	local nTotalWidth = 0
	for nPos, wndCurr in pairs(self.tDataTextsBot) do
		local tOptions = self:GetCustomOptions(wndCurr:GetName())
		local width = wndCurr:GetWidth()
		local name = wndCurr:GetName()
		--fit on screen check
		nTotalWidth = nTotalWidth + width
		local nScreenWidth = self.wndBotDisplay:FindChild("Container"):GetWidth()
		if nScreenWidth < nTotalWidth then
			if not self.strLastCheckedNameBot then
				self.strLastCheckedNameBot = wndCurr:GetName()
			end
			self.db.profile.tDTOptions[self.strLastCheckedNameBot]["bShownBot"] = false
			if self.wndDataTexts:FindChild("OptionsDialogueControls"):FindChild(self.strLastCheckedNameBot) then
				self.wndBotDisplay:FindChild("Container"):FindChild(self.strLastCheckedNameBot):Destroy()
				--self.tDataTextsTop[nPos] = nil
				self.wndDataTexts:FindChild("OptionsDialogueControls"):FindChild(self.strLastCheckedNameBot):FindChild("Bottom"):SetCheck(false)
			end
			break
		end
	end
	self.wndBotDisplay:FindChild("Container"):ArrangeChildrenHorz(tAlignmentOptions[self.db.profile.botBar.strAlignment])
end	

function StarPanel:SetPositionsTop(self)
	local tOptions, nPos
	local nLastPosTop = 0
	local nTotal = 0
	for name, data in pairs(self.DataTexts) do
		tOptions = self:GetCustomOptions(name)
		if tOptions and tOptions.nPos.top ~= 0 then
			nTotal = nTotal + 1
		end
	end
	for name, data in pairs(self.DataTexts) do
		tOptions = self:GetCustomOptions(name)
		if tOptions then
			nPos = tOptions.nPos.top
			if nPos == 0 then
				--nLastPosTop = nLastPosTop + 1
				self.db.profile.tDTOptions[name]["nPos"]["top"] = nTotal + 1
				nTotal = nTotal + 1
			end
		end
	end
end

function StarPanel:SetPositionsBot(self)
	local tOptions, nPos
	local nLastPosTop = 0
	local nTotal = 0
	for name, data in pairs(self.DataTexts) do
		tOptions = self:GetCustomOptions(name)
		if tOptions and tOptions.nPos.bot ~= 0 then
			nTotal = nTotal + 1
		end
	end
	for name, data in pairs(self.DataTexts) do
		tOptions = self:GetCustomOptions(name)
		if tOptions then
			nPos = tOptions.nPos.bot
			if nPos == 0 then
				--nLastPosTop = nLastPosTop + 1
				self.db.profile.tDTOptions[name]["nPos"]["bot"] = nTotal + 1
				nTotal = nTotal + 1
			end
		end
	end
end

function StarPanel:SetYOffsetTop(nOffset)
	local l, t, r, b = self.wndTopDisplay:GetAnchorOffsets()
	self.wndTopDisplay:SetAnchorOffsets(l, 0+nOffset, r, 30+nOffset)
end

function StarPanel:SetYOffsetBot(nOffset)
	local l, t, r, b = self.wndBotDisplay:GetAnchorOffsets()
	self.wndBotDisplay:SetAnchorOffsets(l, -30+nOffset, r, 0+nOffset)
end

--[[
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
					ALERT!!!
					
	Need to fix the function below because you switched
	   to the auto-width style/method/whatever

	
			SHOULD JUST DELETE I THINK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
]]
function StarPanel:GetTotalWidthTop(self)
	local nTotalWidth = 0
	for nPos, wndCurr in pairs(self.tDataTextsTop) do
		local width = wndCurr:GetWidth()
		nTotalWidth = nTotalWidth + width
	end
	return nTotalWidth
end

function StarPanel:RegisterDataText(self, strName, tData, tCustOptions)
	--Print("----------------------")
	--Print(strName)
	if self.DataTexts[strName] then
		--Print("Exists")
		return
	end
	
	if not self.db.profile.tDTOptions[strName] then
		--Print("Options don't exist")
		self.db.profile.tDTOptions[strName] = {
			["bShownTop"] 	= false,
			["bShownBot"]	= false,
			["bShowIcon"]	= true,
			["bShowLabel"]	= true,
			["nPos"] = {
				top = 0,
				bot = 0
			},
		}
		--[[
		if tCustOptions then
			for k, v in pairs(tCustOptions) do
				self.db.profile.tDTOptions[strName][k] = v
			end
		end
		]]
	end
	
	if tCustOptions then
		--Print("Customs exist")
		for k, v in pairs(tCustOptions) do
			if self.db.profile.tDTOptions[strName][k] == nil then
				self.db.profile.tDTOptions[strName][k] = v
			end
		end
	end
	
	self.DataTexts[strName] = tData
	
	--Print(tostring(self.DataTexts[strName] == tData))
	
	return self.DataTexts[strName]
end

function StarPanel:RegisterDefaultOptions(self, strModName)
	local userNames = {
		["bShownTop"]	= "Show Top",
		["bShownBot"]	= "Show Bottom",
		["bShowIcon"]	= "Show Icon",
		["bShowLabel"]	= "Show Label",	
	}

	for k, v in pairs(userNames) do
		local tOpsName = {}
		tOpsName[k] = v
		self:RegisterMenuOption(self, strModName, tOpsName, nil, nil, 2)
	end
end

function StarPanel:RegisterMenuOption(self, strModName, tOptionsName, tOptions, funcCallFunction, nType, strRadioGroup)
--[[
Args:
	self = 
		AddOn Handler = StarPanel
	
	strModName = 
		The name of the Data Text PlugIn
	
	tOptionsName = NO --> (type 1 the value would be a function)
		a table containing the Option name seen by the user as the value.
			The key is the name of the variable saved in the custom options of the data text.
	
	tOptions = (only in type 4)
		value = Option seen by user (i.e. "Server")
		key = Actual option value (i.e. "server")
		
	#################################
	(for tOptions and tOptions name...
		the key is set as the item name and the value is set as the item text)
	################################
			
	funcCallFunction = 
		The function, with the var clicked as an arg, to call when a button is clicked.
		Used in type 1 but can also be used in 2, 3, and 4 as supplemental
	
	nType =
		1 = PushButton
		2 = CheckBox (Boolean)
		#DONT USE#3 = Radio (Mult Options but only 1 can be selected at a time)
		4 = Select - Expanding (Mult Options)
		
	strRadioGroup = 
		A unique string to identify the radio group
]]

	--self.db.profile.tDTOptions[strModName]
	local wndMenu
	if self.DataTextOptionsUI[strModName] then
		wndMenu = self.DataTextOptionsUI[strModName]
		wndMenu:SetData(wndMenu:GetData() + 1)
	else
		wndMenu = Apollo.LoadForm(self.xmlDoc, "ListMenu", nil, self)
		wndMenu:SetName(strModName.."Tier1")
		wndMenu:SetData(1)
	end
	
	local wndOption
	local wndExpand
	if nType == 1 then
		wndOption = Apollo.LoadForm(self.xmlDoc, "ListMenuItem", wndMenu:FindChild("Container"), self)
		wndOption:AddEventHandler("ButtonUp", "OnPushButtonClick")
	elseif nType == 2 then
		wndOption = Apollo.LoadForm(self.xmlDoc, "ListMenuItemCheck", wndMenu:FindChild("Container"), self)
		wndOption:AddEventHandler("ButtonUp", "OnBooleanClick")
		for int, use in pairs(tOptionsName) do
			if self.db.profile.tDTOptions[strModName] then --[int] then
				wndOption:SetCheck(true)
			end
		end
	elseif nType == 3 then
		wndOption = Apollo.LoadForm(self.xmlDoc, "ListMenuItemRadio", wndMenu:FindChild("Container"), self)
		wndOption:AddEventHandler("ButtonUp", "OnRadioClick")
		for int, use in pairs(tOptionsName) do
			if self.db.profile.tDTOptions[strModName][int] then
				wndOption:SetCheck(true)
			end
		end
	elseif nType == 4 then
		wndOption = Apollo.LoadForm(self.xmlDoc, "ListMenuItemExpand", wndMenu:FindChild("Container"), self)
		wndOption:AddEventHandler("ButtonUp", "OnExpandClick")
		--wndExpand = Apollo.LoadForm(self.xmlDoc, wndOption, wndMenu, self)
		local nItems = 0	
		local container = wndOption:FindChild("ListMenu"):FindChild("Container")
		for strInt, strUser in pairs(tOptions) do
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "ListMenuItemRadio", container, self)
			local tData = {
				["strModName"] = strModName,
				["funcCall"] = funcCallFunction,
				["tOptionsName"] = tOptionsName,
				["tOptions"] = tOptions,
				--["strRadioGroup"] = strRadioGroup,
			}
			local radioName
			for strMainInt, strMainUser in pairs(tOptionsName) do
				radioName = strMainInt
			end
			wndCurr:SetName(strInt) --server, local
			wndCurr:SetText(strUser) --Server, Local
			wndCurr:SetData(tData)
			--container:SetRadioSelButton(radioName, wndCurr)
			if self.db.profile.tDTOptions[tData.strModName][radioName] == strInt then
				wndCurr:SetCheck(true)
			end
			nItems = nItems + 1
			--wndCurr:rad
			wndCurr:AddEventHandler("ButtonUp", "OnRadioExpandedClick")
		end
		
		local nTotalItemHeight = nItems * 20
		local nPadding = 10 --? ... try this number
		local nTotalHeight = nTotalItemHeight + nPadding
		local l, t, r, b = wndOption:FindChild("ListMenu"):GetAnchorOffsets()
		local nWidth = r - l
		local nHeight = nTotalHeight
		
		b = t + nHeight
			
		wndOption:FindChild("ListMenu"):SetAnchorOffsets(l, t, r, b)
		
		container:ArrangeChildrenVert(1)
	end
	
	for strInt, strUser in pairs(tOptionsName) do
		wndOption:SetName(strInt)
		wndOption:SetText(strUser)
	end
	
	local tData = {
		["strModName"] = strModName,
		["funcCall"] = funcCallFunction,
		["tOptionsName"] = tOptionsName,
		["tOptions"] = tOptions,
	}
	wndOption:SetData(tData)
	
	
	wndMenu:FindChild("Container"):ArrangeChildrenVert(1)
	self.DataTextOptionsUI[strModName] = wndMenu
end

function StarPanel:OnPushButtonClick(wndHandler, wndControl, eMouseButton)
	local strInt = wndControl:GetName()
	local strUser = wndControl:GetText()
	local tData = wndControl:GetData()
		--["strModName"] = strModName,
		--["funcCall"] = funcCallFunction,
		--["tOptionsName"] = tOptionsName,
		--["tOptions"] = tOptions,
		
	tData.funcCall(strInt)
end

function StarPanel:OnBooleanClick(wndHandler, wndControl, eMouseButton)
	local tData = wndControl:GetData()

	for int, user in pairs(tData.tOptionsName) do
		self.db.profile.tDTOptions[tData.strModName][int] = wndControl:IsChecked()
	end

	if tData.funCall then
		tData.funcCall(strInt)
	end
	
	self:RefreshTopDisplay(self)
	self:RefreshBotDisplay(self)
end

function StarPanel:OnRadioClick(wndHandler, wndControl, eMouseButton)
	
end

function StarPanel:OnRadioExpandedClick(wndHandler, wndControl, eMouseButton)
	--reset buttons
	for i, wnd in pairs(wndControl:GetParent():GetChildren()) do
		if wnd:GetName() ~= wndControl:GetName() then
			wnd:SetCheck(false)
		end
	end

	local strInt = wndControl:GetName()
	local strUser = wndControl:GetText()
	local tData = wndControl:GetData()
	local strModName = tData.strModName
	local bShowTop = self.db.profile.tDTOptions[tData.strModName].bShownTop
		--["strModName"] = strModName,
		--["funcCall"] = funcCallFunction,
		--["tOptionsName"] = tOptionsName,
		--["tOptions"] = tOptions,
		
	--opsname = "strSource", ops = "server"
	
	if wndControl:IsChecked() then
		for int, user in pairs(tData.tOptionsName) do
			self.db.profile.tDTOptions[tData.strModName][int] = strInt
		end
	end
	
	if tData.funCall then
		tData.funcCall(strInt)
	end
	
	self:RefreshTopDisplay(self)
	self:RefreshBotDisplay(self)
end

function StarPanel:OnExpandClick(wndHandler, wndControl, eMouseButton)
	wndControl:FindChild("ListMenu"):Show(true)
end

function StarPanel:OnUnitEnteredCombat(uUnit, bInCombat)
	local strUnitName = uUnit:GetName()
	
	if strUnitName == GameLib.GetPlayerUnit():GetName() then
		if self.db.profile.topBar.bHideCombat then
			self.wndTopDisplay:Show(not bInCombat)
		end
		if self.db.profile.botBar.bHideCombat then
			self.wndBotDisplay:Show(not bInCombat)
		end
	end
	--local l, t, r, b = g_wndActionBarResources:GetAnchorOffsets()
	--if b == -19 and self.db.profile.botBar.bShiftUI then
	--	g_wndActionBarResources:SetAnchorOffsets(l, t, r, b-30)
	--end
end


	
function StarPanel:OnDatachronRestored(...)
	if self.db.profile.botBar.bShiftUI then
		local QuestTracker = nil --Apollo.GetAddon("QuestTracker")
		if QuestTracker then
			local nQuestTrackerLeft, nQuestTrackerTop, nQuestTrackerTop, nQuestTrackerBottom = QuestTracker.wndMain:GetAnchorOffsets()
			QuestTracker.wndMain:SetAnchorOffsets(nQuestTrackerLeft, nQuestTrackerTop, nQuestTrackerTop, self.nQuestTrackerBottom)
		end
	end
end
-------------------------------
--		RIGHT CLICK MENU
-------------------------------
function StarPanel:OnMouseUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	-- 0 = left
	-- 1 = right
	if not wndControl then
		return
	end
	local strType = wndControl:GetData()["type"]
	if eMouseButton == 0 and strType == "launcher" then
		wndControl:GetData().OnClick()
	elseif eMouseButton == 0 and strType == "dataFeed" and wndControl:GetData().OnClick ~= nil then
		wndControl:GetData().OnClick(wndControl)
	elseif eMouseButton == 1 then

		local wndCurr = self.DataTextOptionsUI[wndControl:GetName()]
		local nItems = wndCurr:GetData()
		local nTotalItemHeight = nItems * 20
		local nPadding = 10 --? ... try this number
		local nTotalHeight = nTotalItemHeight + nPadding
		local x, y = nLastRelativeMouseX, nLastRelativeMouseY
		local wl, wt, wr, wb = wndControl:GetAnchorOffsets()
		local l, t, r, b = wndCurr:GetAnchorOffsets()
		local nWidth = r - l
		local nHeight = nTotalHeight
		
		l = wl + x
		t = wt + y
		r = wl + x + nWidth
		b = wt + y + nHeight
		
		--Print("("..x..", "..y..")")
		local nScreenWidth , nScreenHeight = Apollo.GetScreenSize()
		if wndControl:GetParent():GetParent():GetName() == "TopDisplay" then
			wndCurr:SetAnchorOffsets(l, t, r, b)
		else
			t = (nScreenHeight - 30) + t - nTotalHeight - 50
			b = (nScreenHeight - 30) + b - nTotalHeight - 50
			wndCurr:SetAnchorOffsets(l, t, r, b)
		end
		
		wndCurr:FindChild("Container"):ArrangeChildrenVert(1)
		wndCurr:Show(true, true)
	end
end

---------------------------------------------------------------------------------------------------
-- DataFeedItem Functions
---------------------------------------------------------------------------------------------------
-------------------------------
--		Drag and Drop
-------------------------------
function StarPanel:SwapDataTextsTop(wndA, wndB)
	local tPosA, tPosB = self:GetCustomOptions(wndA:GetName()).nPos.top, self:GetCustomOptions(wndB:GetName()).nPos.top
	
	self.db.profile.tDTOptions[wndA:GetName()].nPos.top = tPosB
	self.db.profile.tDTOptions[wndB:GetName()].nPos.top = tPosA
	
	self:RefreshTopDisplay(self)
end

function StarPanel:SwapDataTextsBot(wndA, wndB)
	local tPosA, tPosB = self:GetCustomOptions(wndA:GetName()).nPos.bot, self:GetCustomOptions(wndB:GetName()).nPos.bot
	
	self.db.profile.tDTOptions[wndA:GetName()].nPos.bot = tPosB
	self.db.profile.tDTOptions[wndB:GetName()].nPos.bot = tPosA
	
	self:RefreshBotDisplay(self)
end

function StarPanel:OnTargetNotify( wndHandler, wndControl, bMe )
	wndControl:FindChild("Flash"):Show(bMe)
end

function StarPanel:OnMouseDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if eMouseButton > 0 or not Apollo.IsControlKeyDown() then
		return
	end
	local wndSource = wndControl
	local bIsTop = self.db.profile.tDTOptions[wndControl:GetName()].bShownTop
	local bIsBot = self.db.profile.tDTOptions[wndControl:GetName()].bShownBot
	local strWnd = wndControl:GetParent():GetParent():GetName()
	local strType
	strType = strWnd
	local strSprite = "ClientSprites:sprItem_New"
	local nData = 1
	Apollo.BeginDragDrop(wndSource, strType, strSprite, nData)	
end

function StarPanel:OnDragDrop( wndHandler, wndControl, x, y, wndSource, strType, iData, bDragDropHasBeenReset )
	wndControl:FindChild("Flash"):Show(false)
	if wndHandler and strType == "TopDisplay" then
		self:SwapDataTextsTop(wndSource, wndControl)
	elseif wndHandler and strType == "BotDisplay" then
		self:SwapDataTextsBot(wndSource, wndControl)
	end
end

function StarPanel:OnQueryDragDrop( wndHandler, wndControl, x, y, wndSource, strType, iData, eResult )
	return Apollo.DragDropQueryResult.Accept
end

function StarPanel:OnGenerateTooltip( wndHandler, wndControl, eToolTipType, x, y )
	if wndControl:GetData() == nil then
		return
	end
	
	local tData = wndControl:GetData()
	
	if tData.OnTooltip then
		wndControl:SetTooltipDoc(tData.OnTooltip())
	end
end

---------------------------------------------------------------------------------------------------
-- DataTextOptionItem Functions
---------------------------------------------------------------------------------------------------

function StarPanel:OnDataTextShowTopClick( wndHandler, wndControl, eMouseButton )
	self.strLastCheckedNameTop = wndControl:GetParent():GetName()	
	
	self.db.profile.tDTOptions[wndControl:GetParent():GetName()]["bShownTop"] = wndControl:IsChecked()
	
	self:RefreshTopDisplay(self)
end

function StarPanel:OnDataTextShowBotClick( wndHandler, wndControl, eMouseButton )
	self.strLastCheckedNameBot = wndControl:GetParent():GetName()
	
	self.db.profile.tDTOptions[wndControl:GetParent():GetName()]["bShownBot"] = wndControl:IsChecked()
 
	self:RefreshBotDisplay(self)
end
--======================================================
--[[
			StarPanel:RegisterDataText(strName, tData)
			
	Creates a new data object and adds it to storage.
			
	Args:
		strName	= The name of the Data Object.
		tData	= A table containing the attributes of the object.
	
	Returns:
		tData	= The Data Object itself.

	Examples:
	
	<dataFeed type>
		(a dataFeed type is a data object that provides some kind of
			data or information such as FPS, DPS, or latency.
			You can set the [onUpdate] attribute that can be called to
			update the [text] attribute which is what is displayed.)
			
	local data = {
		type	= "dataFeed",
		show	= true,
		text 	= "60ms",
		label	= "Ping",
		icon	= "path\\user\\ncsoft\\addons\\module\\images",
		onUpdate = function(self)
			local ping = GetLatency()
			self.text = ping.."ms"
		end
	}
	local pingObj = StarPanel:RegisterDataText("Ping", data)
	
	<launcher type>
		(a launcher type is a data object type that instead of providing
			information at an interval, displayed a text, label, and/or icon
			that can be clicked to launch a window or addon.)
			
	local data = {
		type	= "launcher",
		show	= true,
		text 	= "My Addon",
		icon	= "path\\user\\ncsoft\\addons\\module\\images",
		onClick = function() --arguments might be different
			addOn.wndMain:Show(true)
		end
	}
	local myAddOnObj = StarPanel:RegisterDataText("My AddOn", data)
	
	What attributes you use will depend on the display addon that you
		are making the object for. Check the display addon to see which
		attributes you should be using. If you are making your own
		display addon you can make your own types and even attributes
		as the system is very customizable.
		
		(The attributes and objects do nothing by themselves.
			You need to have or write and addon that handles
			the data objects. In addition you could also make
			a new data object for an existing addon as long as
			you are using the right attributes and the addon
			allows it.)
		
	Some attributes addons may use could include:
	
		type = <string> 	--The type of the data object
		show = <boolean> 	--Whether to show the object or not
		visible = <boolean> --Same as "show"
		text = <string> 	--Text that can display information or data
		label = <string> 	--Same as text but may be used more to display the name
		icon = <path> 		--An icon or image to display next to the object
		onClick = <func>	--A function that fires when you click the object
		onUpdate = <func>	--A function that can be fired at intervals to update other attributes
		onTooltip = <func>	--A function that generates a tooltip
]]
-----------------------------------------------------------------------------------------------

function StarPanel:OnSPOptionsButtonClick( wndHandler, wndControl, eMouseButton )
	--=========================================
	--					FOR CUI
	--=========================================
	Apollo.ParseInput("/sp")
	Event_FireGenericEvent("CandyUI_CloseOptions")
end

---------------------------------------------------------------------------------------------------
-- OptionsControls Functions
---------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- StarPanel Instance
-----------------------------------------------------------------------------------------------
local StarPanelInst = StarPanel:new()
StarPanelInst:Init()
