-----------------------------------------------------------------------------------------------
-- Client Lua Script for CandyUI_InterfaceMenu
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
--DEVELOPER LICENSE
-- CandyUI - Copyright (C) 2014 Neil Smith
-- This work is licensed under the GNU GENERAL PUBLIC LICENSE.
-- A copy of this license is included with this release.
-----------------------------------------------------------------------------------------------
require "Window"
require "GameLib"
require "Apollo"
 
local CandyUI_InterfaceMenu = {} 

--%%%%%%%%%%%
--   ROUND
--%%%%%%%%%%%
local function round(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
kcuiIMDefaults = {
	char = {
		currentProfile = nil,
		tPinnedAddons = {
			Apollo.GetString("InterfaceMenu_AccountInventory"),
			Apollo.GetString("InterfaceMenu_Character"),
			Apollo.GetString("InterfaceMenu_AbilityBuilder"),
			Apollo.GetString("InterfaceMenu_QuestLog"),
			Apollo.GetString("InterfaceMenu_GroupFinder"),
			Apollo.GetString("InterfaceMenu_Social"),
			Apollo.GetString("InterfaceMenu_Mail"),
			Apollo.GetString("InterfaceMenu_Lore"),
		},
	},
}
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CandyUI_InterfaceMenu:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function CandyUI_InterfaceMenu:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CandyUI_InterfaceMenu OnLoad
-----------------------------------------------------------------------------------------------
function CandyUI_InterfaceMenu:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CandyUI_InterfaceMenu.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, kcuiIMDefaults)
end

-----------------------------------------------------------------------------------------------
-- CandyUI_InterfaceMenu OnDocLoaded
-----------------------------------------------------------------------------------------------
function CandyUI_InterfaceMenu:OnDocLoaded()
	if  self.xmlDoc == nil then
		return
	end
	
	if self.db.char.currentProfile == nil and self.db:GetCurrentProfile() ~= nil then
		self.db.char.currentProfile = self.db:GetCurrentProfile()
	elseif self.db.char.currentProfile ~= nil and self.db.char.currentProfile ~= self.db:GetCurrentProfile() then
		self.db:SetProfile(self.db.char.currentProfile)
	end	
	
	Apollo.LoadSprites("Sprites.xml")
	
	Apollo.RegisterEventHandler("InterfaceMenuList_NewAddOn", 			"OnNewAddonListed", self)
	Apollo.RegisterEventHandler("InterfaceMenuList_AlertAddOn", 		"OnDrawAlert", self)
	Apollo.RegisterEventHandler("CharacterCreated", 					"OnCharacterCreated", self)
	Apollo.RegisterTimerHandler("TimeUpdateTimer", 						"OnUpdateTimer", self)
	Apollo.RegisterTimerHandler("QueueRedrawTimer", 					"OnQueuedRedraw", self)
	Apollo.RegisterEventHandler("ApplicationWindowSizeChanged", 		"ButtonListRedraw", self)
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc , "InterfaceMenuListForm", "FixedHudStratumHigh", self)
	self.wndList = Apollo.LoadForm(self.xmlDoc , "FullListFrame", nil, self)
	
	if self.db.char.tAnchorOffsets then
		local l, t, r, b = unpack(self.db.char.tAnchorOffsets)
		local nWidth = self.wndList:GetWidth()
		local nHeight = self.wndList:GetHeight()
		self.wndMain:SetAnchorOffsets(l, t, r, b)
		self.wndList:SetAnchorOffsets(l, b, l+nWidth, b+nHeight)
	end
	
	self.wndMain:FindChild("OpenFullListBtn"):AttachWindow(self.wndList)
	self.wndMain:FindChild("OpenFullListBtn"):Enable(false)

	Apollo.CreateTimer("QueueRedrawTimer", 0.3, false)
	
	Apollo.RegisterSlashCommand("redrawbuttonlist", "OnRedrawButtonListCommand", self)
	
	self.tMenuData = {
		[Apollo.GetString("InterfaceMenu_SystemMenu")] = { "", "", "Icon_Windows32_UI_CRB_InterfaceMenu_EscMenu" },
	}
	
	self.tMenuTooltips = {}
	self.tMenuAlerts = {}
	
	-----------------------------------------
	-- StarPanel and CUI_DataTexts check
	-----------------------------------------
	local bStarPanelLoaded = Apollo.GetAddon("StarPanel") ~= nil
	local bCUIDataTextsLoaded = Apollo.GetAddon("CandyUI_DataTexts") ~= nil
	
	if bStarPanelLoaded or bCUIDataTextsLoaded then
		if not self.db.char.tAnchorOffsets then
			local l, t, r, b = self.wndMain:GetAnchorOffsets()
			self.wndMain:SetAnchorOffsets(l, t+30, r, b+30)
		end
	end
	-----------------------------------------
	
	self:ButtonListRedraw()

	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	end	
end

-- This function toggles the "Edit Mode" for the UnitFrames on or off.
-- The "Edit Mode" allows the windows to be dragged across the screen by the User.
function CandyUI_InterfaceMenu:ToggleEditMode(bEnabled)
  self.wndMain:SetStyle("Moveable", bEnabled)
  self.wndList:SetStyle("Moveable", bEnabled)

  self.wndMain:SetStyle("IgnoreMouse", not bEnabled)
  self.wndList:SetStyle("IgnoreMouse", not bEnabled)
end

function CandyUI_InterfaceMenu:OnCharacterCreated()	
	Apollo.CreateTimer("TimeUpdateTimer", 1.0, true)
end

function CandyUI_InterfaceMenu:OnUpdateTimer()
	if not self.bHasLoaded then
		Event_FireGenericEvent("InterfaceMenuListHasLoaded")
		self.wndMain:FindChild("OpenFullListBtn"):Enable(true)
		self.bHasLoaded = true
	end

	--Toggle Visibility based on ui preference
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	end
	local bIsInCombat = unitPlayer:IsInCombat()
	local nVisibility = Apollo.GetConsoleVariable("hud.TimeDisplay")
	local bShowTime = true
	
	if nVisibility == 2 then --always off
		bShowTime = false
	elseif nVisibility == 3 then --on in combat
		bShowTime = bIsInCombat
	elseif nVisibility == 4 then --on out of combat
		bShowTime = not bIsInCombat
	else
		bShowTime = true
	end

	local tTime = GameLib.GetLocalTime()
	self.wndMain:FindChild("Time"):SetText("") --bShowTime and string.format("%02d:%02d", tostring(tTime.nHour), tostring(tTime.nMinute)) or "")
end

function CandyUI_InterfaceMenu:OnRedrawButtonListCommand()
	self:ButtonListRedraw()
end

function CandyUI_InterfaceMenu:OnNewAddonListed(strKey, tParams)
	strKey = string.gsub(strKey, ":", "|") -- ":'s don't work for window names, sorry!"

	self.tMenuData[strKey] = tParams
	
	self:FullListRedraw()
	self:ButtonListRedraw()
end

function CandyUI_InterfaceMenu:IsPinned(strText)
	for idx, strWindowText in pairs(self.db.char.tPinnedAddons) do
		if (strText == strWindowText) then
			return true
		end
	end
	
	return false
end

function CandyUI_InterfaceMenu:FullListRedraw()
	local strUnbound = Apollo.GetString("Keybinding_Unbound")
	local wndParent = self.wndList:FindChild("InsetBG:FullListScroll")
	
	local strQuery = string.lower(tostring(self.wndList:FindChild("SearchEditBox"):GetText()) or "")
	if strQuery == nil or strQuery == "" or not strQuery:match("[%w%s]+") then
		strQuery = ""
	end

	for strWindowText, tData in pairs(self.tMenuData) do
		local bSearchResultMatch = string.find(string.lower(strWindowText), strQuery) ~= nil
		
		if strQuery == "" or bSearchResultMatch then
			local wndMenuItem = self:LoadByName("MenuListItem", wndParent, strWindowText)
			local wndMenuButton = self:LoadByName("InterfaceMenuButton", wndMenuItem:FindChild("Icon"), strWindowText)
			local strTooltip = strWindowText
			
			if string.len(tData[2]) > 0 then
				local strKeyBindLetter = GameLib.GetKeyBinding(tData[2])
				strKeyBindLetter = strKeyBindLetter == strUnbound and "" or string.format(" (%s)", strKeyBindLetter)
				
				strTooltip = strKeyBindLetter ~= "" and strTooltip .. strKeyBindLetter or strTooltip
			end
			
			if tData[3] ~= "" then
				wndMenuButton:FindChild("Icon"):SetSprite(tData[3])
			else 
				wndMenuButton:FindChild("Icon"):SetText(string.sub(strTooltip, 1, 1))
			end
			
			wndMenuButton:FindChild("ShortcutBtn"):SetData(strWindowText)
			wndMenuButton:FindChild("Icon"):SetTooltip(strTooltip)
			self.tMenuTooltips[strWindowText] = strTooltip
			
			wndMenuItem:FindChild("MenuListItemBtn"):SetText(strWindowText)
			wndMenuItem:FindChild("MenuListItemBtn"):SetData(tData[1])
			
			wndMenuItem:FindChild("PinBtn"):SetCheck(self:IsPinned(strWindowText))
			wndMenuItem:FindChild("PinBtn"):SetData(strWindowText)
			
			if string.len(tData[2]) > 0 then
				local strKeyBindLetter = GameLib.GetKeyBinding(tData[2])
				wndMenuItem:FindChild("MenuListItemBtn"):FindChild("MenuListItemKeybind"):SetText(strKeyBindLetter == strUnbound and "" or string.format("(%s)", strKeyBindLetter))  -- LOCALIZE
			end
		elseif not bSearchResultMatch and wndParent:FindChild(strWindowText) then
			wndParent:FindChild(strWindowText):Destroy()
		end
	end
	
	wndParent:ArrangeChildrenVert(0, function (a,b) return a:GetName() < b:GetName() end)
end

function CandyUI_InterfaceMenu:ButtonListRedraw()
	Apollo.StopTimer("QueueRedrawTimer")
	Apollo.StartTimer("QueueRedrawTimer")
end

function CandyUI_InterfaceMenu:OnQueuedRedraw()
	local strUnbound = Apollo.GetString("Keybinding_Unbound")
	local wndParent = self.wndMain:FindChild("ButtonList")
	wndParent:DestroyChildren()
	local nParentWidth = wndParent:GetWidth()
	
	local nLastButtonWidth = 0
	local nTotalWidth = 0

	for idx, strWindowText in pairs(self.db.char.tPinnedAddons) do
		tData = self.tMenuData[strWindowText]
		
		--Magic number below is allowing the 1 pixel gutter on the right
		if tData and nTotalWidth + nLastButtonWidth <= nParentWidth + 1 then
			local wndMenuItem = self:LoadByName("InterfaceMenuButton", wndParent, strWindowText)
			local strTooltip = strWindowText
			nLastButtonWidth = wndMenuItem:GetWidth()
			nTotalWidth = nTotalWidth + nLastButtonWidth

			if string.len(tData[2]) > 0 then
				local strKeyBindLetter = GameLib.GetKeyBinding(tData[2])
				strKeyBindLetter = strKeyBindLetter == strUnbound and "" or string.format(" (%s)", strKeyBindLetter)
				strTooltip = strKeyBindLetter ~= "" and strTooltip .. strKeyBindLetter or strTooltip
			end
			
			if tData[3] ~= "" then
				wndMenuItem:FindChild("Icon"):SetSprite(tData[3])
			else 
				wndMenuItem:FindChild("Icon"):SetText(string.sub(strTooltip, 1, 1))
			end
			
			wndMenuItem:FindChild("ShortcutBtn"):SetData(strWindowText)
			wndMenuItem:FindChild("Icon"):SetTooltip(strTooltip)
		end
		
		if self.tMenuAlerts[strWindowText] then
			self:OnDrawAlert(strWindowText, self.tMenuAlerts[strWindowText])
		end
	end
	
	wndParent:ArrangeChildrenHorz(0)
end

-----------------------------------------------------------------------------------------------
-- Search
-----------------------------------------------------------------------------------------------

function CandyUI_InterfaceMenu:OnSearchEditBoxChanged(wndHandler, wndControl)
	self.wndList:FindChild("SearchClearBtn"):Show(string.len(wndHandler:GetText() or "") > 0)
	self:FullListRedraw()
end

function CandyUI_InterfaceMenu:OnSearchClearBtn(wndHandler, wndControl)
	self.wndList:FindChild("SearchFlash"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self.wndList:FindChild("SearchFlash"):SetFocus()
	self.wndList:FindChild("SearchClearBtn"):Show(false)
	self.wndList:FindChild("SearchEditBox"):SetText("")
	self:FullListRedraw()
end

function CandyUI_InterfaceMenu:OnSearchCommitBtn(wndHandler, wndControl)
	self.wndList:FindChild("SearchFlash"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self.wndList:FindChild("SearchFlash"):SetFocus()
	self:FullListRedraw()
end

-----------------------------------------------------------------------------------------------
-- Alerts
-----------------------------------------------------------------------------------------------

function CandyUI_InterfaceMenu:OnDrawAlert(strWindowName, tParams)
	self.tMenuAlerts[strWindowName] = tParams
	for idx, wndTarget in pairs(self.wndMain:FindChild("ButtonList"):GetChildren()) do
		if wndTarget and tParams then
			local wndButton = wndTarget:FindChild("ShortcutBtn")
			if wndButton then 
				local wndIcon = wndButton:FindChild("Icon")
				
				if wndButton:GetData() == strWindowName then
					if tParams[1] then
						local wndIndicator = self:LoadByName("AlertIndicator", wndButton:FindChild("Alert"), "AlertIndicator")
						
					elseif wndButton:FindChild("AlertIndicator") ~= nil then
						wndButton:FindChild("AlertIndicator"):Destroy()
					end
					
					if tParams[2] then
						wndIcon:SetTooltip(string.format("%s\n\n%s", self.tMenuTooltips[strWindowName], tParams[2]))
					end
					
					if tParams[3] and tParams[3] > 0 then
						local strColor = tParams[1] and "UI_WindowTextOrange" or "UI_TextHoloTitle"
						
						wndButton:FindChild("Number"):Show(true)
						wndButton:FindChild("Number"):SetText(tParams[3])
						wndButton:FindChild("Number"):SetTextColor(ApolloColor.new(strColor))
					else
						wndButton:FindChild("Number"):Show(false)
						wndButton:FindChild("Number"):SetText("")
						wndButton:FindChild("Number"):SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
					end
				end
			end
		end
	end
	
	local wndParent = self.wndList:FindChild("FullListScroll")
	for idx, wndTarget in pairs(wndParent:GetChildren()) do
		local wndButton = wndTarget:FindChild("ShortcutBtn")
		local wndIcon = wndButton:FindChild("Icon")
		
		if wndButton:GetData() == strWindowName then
			if tParams[1] then
				local wndIndicator = self:LoadByName("AlertIndicator", wndButton:FindChild("Alert"), "AlertIndicator")
			elseif wndButton:FindChild("AlertIndicator") ~= nil then
				wndButton:FindChild("AlertIndicator"):Destroy()
			end
			
			if tParams[2] then
				wndIcon:SetTooltip(string.format("%s\n\n%s", self.tMenuTooltips[strWindowName], tParams[2]))
			end
			
			if tParams[3] and tParams[3] > 0 then
				local strColor = tParams[1] and "UI_WindowTextOrange" or "UI_TextHoloTitle"
				
				wndButton:FindChild("Number"):Show(true)
				wndButton:FindChild("Number"):SetText(tParams[3])
				wndButton:FindChild("Number"):SetTextColor(ApolloColor.new(strColor))
			else
				wndButton:FindChild("Number"):Show(false)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Helpers and Errata
-----------------------------------------------------------------------------------------------

function CandyUI_InterfaceMenu:OnMenuListItemClick(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	
	if string.len(wndControl:GetData()) > 0 then
		Event_FireGenericEvent(wndControl:GetData())
	else
		InvokeOptionsScreen()
	end
	self.wndList:Show(false)
end

function CandyUI_InterfaceMenu:OnPinBtnChecked(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	
	local wndParent = wndControl:GetParent():GetParent()
	
	self.db.char.tPinnedAddons = {}
	
	for idx, wndMenuItem in pairs(wndParent:GetChildren()) do
		if wndMenuItem:FindChild("PinBtn"):IsChecked() then
		
			table.insert(self.db.char.tPinnedAddons, wndMenuItem:FindChild("PinBtn"):GetData())
		end
	end
	
	self:ButtonListRedraw()
end

function CandyUI_InterfaceMenu:OnListBtnClick(wndHandler, wndControl) -- These are the five always on icons on the top
	if wndHandler ~= wndControl then return end
	local strMappingResult = self.tMenuData[wndHandler:GetData()][1] or ""
	
	if string.len(strMappingResult) > 0 then
		Event_FireGenericEvent(strMappingResult)
	else
		InvokeOptionsScreen()
	end
end

function CandyUI_InterfaceMenu:OnListBtnMouseEnter(wndHandler, wndControl)
	wndHandler:SetBGColor("ffffffff")
	if wndHandler ~= wndControl or self.wndList:IsVisible() then
		return
	end
end

function CandyUI_InterfaceMenu:OnListBtnMouseExit(wndHandler, wndControl) -- Also self.wndMain MouseExit and ButtonList MouseExit
	wndHandler:SetBGColor("9dffffff")
end

function CandyUI_InterfaceMenu:OnOpenFullListCheck(wndHandler, wndControl)
	self.wndList:FindChild("SearchEditBox"):SetFocus()
	self:FullListRedraw()
end

function CandyUI_InterfaceMenu:LoadByName(strForm, wndParent, strCustomName)
	local wndNew = wndParent:FindChild(strCustomName)
	if not wndNew then
		wndNew = Apollo.LoadForm(self.xmlDoc , strForm, wndParent, self)
		wndNew:SetName(strCustomName)
	end
	return wndNew
end

---------------------------------------------------------------------------------------------------
-- InterfaceMenuListForm Functions
---------------------------------------------------------------------------------------------------

function CandyUI_InterfaceMenu:OnMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	local tAnchors = {wndControl:GetAnchorOffsets()}
	self.db.char.tAnchorOffsets = tAnchors
	local l, t, r, b = unpack(tAnchors)
	local nWidth = self.wndList:GetWidth()
	local nHeight = self.wndList:GetHeight()
	self.wndList:SetAnchorOffsets(l, b, l+nWidth, b+nHeight)
end

-----------------------------------------------------------------------------------------------
-- CandyUI_InterfaceMenu Instance
-----------------------------------------------------------------------------------------------
local CandyUI_InterfaceMenuInst = CandyUI_InterfaceMenu:new()
CandyUI_InterfaceMenuInst:Init()
