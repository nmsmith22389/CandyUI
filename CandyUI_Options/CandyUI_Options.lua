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
	
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("candyui", "OnCandyUI_OptionsOn", self)
		Apollo.RegisterSlashCommand("cui", "OnCandyUI_OptionsOn", self)

		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- CandyUI_Options Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/CandyUI"
function CandyUI_Options:OnCandyUI_OptionsOn()
	self.wndOptions:Invoke() -- show the window
	self.wndOptions:FindChild("ListControls"):DestroyChildren()
			for i, v in ipairs(candyUI_Cats) do
					local wndCurr = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptions:FindChild("ListControls"), self)
					wndCurr:SetText(v)
			end
			self.wndOptions:FindChild("ListControls"):ArrangeChildrenVert()
end


-----------------------------------------------------------------------------------------------
-- CandyUI_OptionsForm Functions
-----------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
-- OptionsDialogue Functions
---------------------------------------------------------------------------------------------------

function CandyUI_Options:OnOptionsHomeClick( wndHandler, wndControl, eMouseButton )
	self.wndOptions:FindChild("ListControls"):DestroyChildren()
	--Event_FireGenericEvent("CandyUI_GoHome")
	for i, v in ipairs(candyUI_Cats) do
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptions:FindChild("ListControls"), self)
		wndCurr:SetText(v)
	end
	self.wndOptions:FindChild("ListControls"):ArrangeChildrenVert()
	
	
end

function CandyUI_Options:OnCloseButtonClick( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Close()
end

---------------------------------------------------------------------------------------------------
-- OptionsListItem Functions
---------------------------------------------------------------------------------------------------

function CandyUI_Options:OnOptionsCatClick( wndHandler, wndControl, eMouseButton )
	--Print(wndControl:GetText())
	local event = "CandyUI_"..wndControl:GetText().."Clicked"
	Event_FireGenericEvent(event)
end

---------------------------------------------------------------------------------------------------
-- OptionsControlsList Functions
---------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
-- CandyUI_Options Instance
-----------------------------------------------------------------------------------------------
local CandyUI_OptionsInst = CandyUI_Options:new()
CandyUI_OptionsInst:Init()
