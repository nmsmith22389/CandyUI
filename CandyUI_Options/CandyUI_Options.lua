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
 
-----------------------------------------------------------------------------------------------
-- CandyUI_Options Module Definition
-----------------------------------------------------------------------------------------------
local CandyUI_Options = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CandyUI_Options:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	
    return o
end

function CandyUI_Options:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CandyUI_Options OnLoad
-----------------------------------------------------------------------------------------------
function CandyUI_Options:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CandyUI_Options.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Options OnDocLoaded
-----------------------------------------------------------------------------------------------
function CandyUI_Options:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then

		self.wndOptions = Apollo.LoadForm(self.xmlDoc, "OptionsDialogue", nil, self)
		self.wndOptions:Show(false, true)
		
		if not candyUI_Cats then
			candyUI_Cats = {}
		end
		self.tAddons = {}
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("candyui", "OnCandyUI_OptionsOn", self)
		Apollo.RegisterSlashCommand("cui", "OnCandyUI_OptionsOn", self)
		
		Apollo.CreateTimer("ThanksAdd", 10.0, false)
		Apollo.RegisterTimerHandler("ThanksAdd", "OnThanksAdd", self)
		Apollo.StartTimer("ThanksAdd")

		-- Do additional Addon initialization here
		Event_FireGenericEvent("CandyUI_OptionsLoaded")
	end
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Options Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/CandyUI"
function CandyUI_Options:OnCandyUI_OptionsOn()
	self.wndOptions:Invoke() -- show the window
	self:OnOptionsHomeClick()
end

function CUI_RegisterOptions(name, wndControls)
	if Apollo.GetAddon("CandyUI_Options").tAddons[name] ~= nil then
		return false
	end
	Apollo.GetAddon("CandyUI_Options").tAddons[name] = wndControls
	wndControls:Show(false, true)
	for _, wndCurr in pairs(wndControls:GetChildren()) do
		wndCurr:Show(false, true)
	end
	return true
end

function CandyUI_Options:OnThanksAdd()
	self.wndThanksControls = Apollo.LoadForm(self.xmlDoc, "ThanksOptions", self.wndOptions:FindChild("OptionsDialogueControls"), self)
	self.wndThanksControls:Show(false, true)
		
	CUI_RegisterOptions("Thanks", self.wndThanksControls)
end
-----------------------------------------------------------------------------------------------
-- CandyUI_OptionsForm Functions
-----------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
-- OptionsDialogue Functions
---------------------------------------------------------------------------------------------------
function CandyUI_Options:HideAllOptions()
	for name, wndCurr in pairs(self.tAddons) do
		wndCurr:Show(false, true)
	end
end

function CandyUI_Options:OnOptionsHomeClick( wndHandler, wndControl, eMouseButton )
	self:HideAllOptions()
	self.wndOptions:FindChild("ListControls"):DestroyChildren()
	for name, wndControls in pairs(self.tAddons) do
		local wndButton = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptions:FindChild("ListControls"), self)
		wndButton:SetText(name)
		--Print(name) --debug
	end
	self.wndOptions:FindChild("ListControls"):ArrangeChildrenVert()
	--[[
	self.wndOptions:FindChild("ListControls"):DestroyChildren()
	--Event_FireGenericEvent("CandyUI_GoHome")
	for i, v in ipairs(candyUI_Cats) do
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptions:FindChild("ListControls"), self)
		wndCurr:SetText(v)
	end
	self.wndOptions:FindChild("ListControls"):ArrangeChildrenVert()
	]]
	
end

function CandyUI_Options:OnCloseButtonClick( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Close()
end

---------------------------------------------------------------------------------------------------
-- OptionsListItem Functions
---------------------------------------------------------------------------------------------------

function CandyUI_Options:OnOptionsCatClick( wndHandler, wndControl, eMouseButton )
	local strAddon = wndControl:GetText()
	self.wndOptions:FindChild("ListControls"):DestroyChildren()
	self.tAddons[strAddon]:Show(true)
	for _, wndCurr in pairs(self.tAddons[strAddon]:GetChildren()) do
		local wndButton = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptions:FindChild("ListControls"), self)
		wndButton:RemoveEventHandler("ButtonUp")
		wndButton:AddEventHandler("ButtonUp", "OnAddonCatClick")
		wndButton:SetText(wndCurr:FindChild("Title"):GetText())
		wndButton:SetData(strAddon)
	end
	self.wndOptions:FindChild("ListControls"):ArrangeChildrenVert()
	--Print(wndControl:GetText())
	--local event = "CandyUI_"..wndControl:GetText().."Clicked"
	--Event_FireGenericEvent(event)
end

function CandyUI_Options:OnAddonCatClick( wndHandler, wndControl, eMouseButton )
	local strAddon = wndControl:GetData()
	for _, wndCurr in pairs(self.tAddons[strAddon]:GetChildren()) do
		if wndCurr:FindChild("Title"):GetText() == wndControl:GetText() then
			wndCurr:Show(true)
		else
			wndCurr:Show(false)
		end
	end
end


---------------------------------------------------------------------------------------------------
-- OptionsControlsList Functions
---------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
-- CandyUI_Options Instance
-----------------------------------------------------------------------------------------------
local CandyUI_OptionsInst = CandyUI_Options:new()
CandyUI_OptionsInst:Init()
