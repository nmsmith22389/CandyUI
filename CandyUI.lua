-----------------------------------------------------------------------------------------------
-- Client Lua Script for CandyUI_UnitFrames
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
-- DEVELOPER LICENSE
-- CandyUI - Copyright (C) 2014 Neil Smith
-- This work is licensed under the GNU GENERAL PUBLIC LICENSE.
-- A copy of this license is included with this release.
-----------------------------------------------------------------------------------------------

require "Window"

-----------------------------------------------------------------------------------------------
-- CandyUI Module Definition
-----------------------------------------------------------------------------------------------
local CandyUI = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local karCUIModules = {
  "CandyUI_Dash",
  "CandyUI_Datachron",
  "CandyUI_InterfaceMenu",
  "CandyUI_Minimap",
  "CandyUI_Nameplates",
  "CandyUI",
  "CandyUI_Resources",
  "CandyUI_UnitFrames",
  "CandyBars",
  "StarPanel",
}

--======================================================
--				CUI global bar inspect
--------------------------------------------------------
--[[

_cui
	bOptionsLoaded				--Whether the options addon is loaded
	tAddonLoadStatus			--A table of which addons are loaded (children are boolean)
	

]]
--======================================================

--Global CUI var
if _cui == nil then
  _cui = {}
end

_cui.bOptionsLoaded = false

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
local function IsAddonLoaded(strAddon)
  --(Apollo.GetAddonInfo(strAddonName) ~= nil and Apollo.GetAddonInfo(strAddonName).bRunning) or 0
  local tAddonInfo = Apollo.GetAddonInfo(strAddon)
  if tAddonInfo ~= nil and tAddonInfo.bRunning == 1 then
    return true
  else
    return false
  end
end

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


function CandyUI:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- initialize variables here

  return o
end

function CandyUI:Init()
  local bHasConfigureFunction = false
  local strConfigureButtonText = ""
  local tDependencies = {-- "UnitOrPackageName",
  }
  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-----------------------------------------------------------------------------------------------
-- CandyUI OnLoad
-----------------------------------------------------------------------------------------------
function CandyUI:OnLoad()
  -- load our form file
  self.xmlDoc = XmlDoc.CreateFromFile("CandyUI.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
  self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, kcuiODefaults)
  self.bEditMode = false -- By default, edit mode is disabled.
end

-----------------------------------------------------------------------------------------------
-- CandyUI OnDocLoaded
-----------------------------------------------------------------------------------------------
function CandyUI:OnDocLoaded()

  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then

    self.wndOptions = Apollo.LoadForm(self.xmlDoc, "OptionsDialogue", nil, self)
    self.wndOptions:Show(false, true)

    self.wndConfirmAlert = Apollo.LoadForm(self.xmlDoc, "ConfirmAlert", nil, self)
    self.wndConfirmAlert:Show(false, true)

    if not candyUI_Cats then
      candyUI_Cats = {}
    end
    self.tAddons = {}
    -- if the xmlDoc is no longer needed, you should set it to nil
    -- self.xmlDoc = nil

    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    Apollo.RegisterSlashCommand("candyui", "OnCandyUIOn", self)
    Apollo.RegisterSlashCommand("cui", "OnCandyUIOn", self)

    --Apollo.CreateTimer("ThanksAdd", 10.0, false)
    --Apollo.RegisterTimerHandler("ThanksAdd", "OnRegisterOptionsDelay", self)
    --Apollo.StartTimer("ThanksAdd")

    --Trying to add other options without the above delay
    self:OnRegisterOptionsDelay()

    self.wndWelcome = Apollo.LoadForm(self.xmlDoc, "WelcomeForm", "FixedHudStratum", self)
    if self.db.char.bFirstRun then
      self.wndWelcome:Show(true, false)
      local cuiModulesTimer = ApolloTimer.Create(5, true, "OnModulesTimer", self)
      self:OnModulesTimer()
    else
      self.wndWelcome:Show(false, true)
    end

    Apollo.RegisterEventHandler("CandyUI_OpenOptions", "OnCandyUIOn", self)
    Apollo.RegisterEventHandler("CandyUI_CloseOptions", "OnCandyUIOff", self)

    --Profiles
    local wndProfileControls = Apollo.LoadForm(self.xmlDoc, "ProfileOptions", self.wndOptions:FindChild("OptionsDialogueControls"), self)
    CUI_RegisterOptions("Profile", wndProfileControls, true)
    --current
    --self.wndOptions:FindChild("OptionsDialogueControls"):FindChild("ProfileControls")
    self.wndCurrentProfileDropdown = self.tAddons["Profile"]:FindChild("Profile:Current:CurrentDropdown")
    self.wndCurrentProfileDropdownBox = self.tAddons["Profile"]:FindChild("Profile:Current:DropdownBox")

    if self.db.char.currentProfile == self.db:GetCurrentProfile() then
      self.wndCurrentProfileDropdown:SetText(self.db.char.currentProfile)
      _cui.strCurrentProfile = self.db.char.currentProfile
    else
      if self.db.char.currentProfile == nil and self.db:GetCurrentProfile() ~= nil then
        self.db.char.currentProfile = self.db:GetCurrentProfile()
      end
      self.db:SetProfile(self.db.char.currentProfile)
      self.wndCurrentProfileDropdown:SetText(self.db.char.currentProfile)
      _cui.strCurrentProfile = self.db.char.currentProfile
    end




    --delete
    self.wndDeleteProfileDropdown = self.tAddons["Profile"]:FindChild("Profile:Delete:DeleteDropdown")
    self.wndDeleteProfileDropdownBox = self.tAddons["Profile"]:FindChild("Profile:Delete:DropdownBox")
    --copy
    self.wndCopyProfileDropdown = self.tAddons["Profile"]:FindChild("Profile:Copy:CopyDropdown")
    self.wndCopyProfileDropdownBox = self.tAddons["Profile"]:FindChild("Profile:Copy:DropdownBox")

    self.tAddons["Profile"]:FindChild("SPSync"):Enable(false)
    self.tAddons["Profile"]:FindChild("CBSync"):Enable(false)

    -- Do additional Addon initialization here
    _cui.bOptionsLoaded = true
    Event_FireGenericEvent("CandyUI_Loaded")
  end
end

-----------------------------------------------------------------------------------------------
-- CandyUI Functions
-----------------------------------------------------------------------------------------------

-- Prints out the provided message into the Debug channel, regardless of what Chat Addon
-- is being used.
function CandyUI:Print(sMessage)
  ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Debug, tostring(sMessage), "CandyUI")
end

-- on SlashCommand "/CandyUI"
-- This function is registered as eventhandler for the OnSlashCommand event.
-- Because we support arguments to our slash command, we need to properly parse them.
-- By default we will open the configuration.
function CandyUI:OnCandyUIOn(sCmd, sArgs)
  local tArgc = {}
  local sCommand = "config"

  -- Loop over the arguments provided, and split them
  -- Store each argument inside the local table for future use.
  for sWord in string.gmatch(sArgs, "[^%s]+") do
    table.insert(tArgc, sWord)
  end

  -- Extract the first argument.
  if #tArgc >= 1 then
    sCommand = string.lower(tArgc[1])
    table.remove(tArgc, 1)
  end

  if sCommand == "config" then
    self.wndOptions:Invoke() -- show the window
    self:OnOptionsHomeClick()

    local bAllProfilesSame = self:CheckCurrentProfiles()

    if not bAllProfilesSame then
      --self:SetCurrentProfiles(_cui.strCurrentProfile)
    end
  elseif sCommand == "edit" then
    self.bEditMode = not self.bEditMode
    self:ToggleEditMode()
  else
    self:Print(("Unknown command: %s"):format(sCommand))
  end
end

-- Toggles the edit mode in all modules based on the internal boolean value of bEditMode.
-- Edit mode allows the User to drag all parent windows across the screen, repositioning them
-- to his own liking.
function CandyUI:ToggleEditMode()
  if self.bEditMode then
    if Apollo.GetAddon("CandyUI_UnitFrames") then
      Apollo.GetAddon("CandyUI_UnitFrames").wndPlayerUF:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_UnitFrames").wndTargetUF:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_UnitFrames").wndFocusUF:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_UnitFrames").wndToTUF:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_UnitFrames").wndPlayerUF:SetStyle("IgnoreMouse", false)
      Apollo.GetAddon("CandyUI_UnitFrames").wndTargetUF:SetStyle("IgnoreMouse", false)
      Apollo.GetAddon("CandyUI_UnitFrames").wndFocusUF:SetStyle("IgnoreMouse", false)
      Apollo.GetAddon("CandyUI_UnitFrames").wndToTUF:SetStyle("IgnoreMouse", false)
    end

    if Apollo.GetAddon("CandyUI_Minimap") then
      Apollo.GetAddon("CandyUI_Minimap").wndMiniMap:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_Minimap").wndMiniMap:SetStyle("IgnoreMouse", false)
    end
  else
    if Apollo.GetAddon("CandyUI_UnitFrames") then
      Apollo.GetAddon("CandyUI_UnitFrames").wndPlayerUF:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_UnitFrames").wndTargetUF:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_UnitFrames").wndFocusUF:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_UnitFrames").wndToTUF:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_UnitFrames").wndPlayerUF:SetStyle("IgnoreMouse", false)
      Apollo.GetAddon("CandyUI_UnitFrames").wndTargetUF:SetStyle("IgnoreMouse", false)
      Apollo.GetAddon("CandyUI_UnitFrames").wndFocusUF:SetStyle("IgnoreMouse", false)
      Apollo.GetAddon("CandyUI_UnitFrames").wndToTUF:SetStyle("IgnoreMouse", false)
    end

    if Apollo.GetAddon("CandyUI_Minimap") then
      Apollo.GetAddon("CandyUI_Minimap").wndMiniMap:SetStyle("Moveable", true)
      Apollo.GetAddon("CandyUI_Minimap").wndMiniMap:SetStyle("IgnoreMouse", false)
    end
  end
end

function CandyUI:OnCandyUIOff()
  self.wndOptions:Show(false)
end

function CUI_RegisterOptions(name, wndControls, bSingleTier)
  if Apollo.GetAddon("CandyUI").tAddons[name] ~= nil then
    return false
  end
  --Apollo.GetAddon("CandyUI").tAddons[name] = wndControls
  local tData = {}
  tData.bSingleTier = bSingleTier

  wndControls:SetData(tData)
  wndControls:Show(false, true)

  for _, wndCurr in pairs(wndControls:GetChildren()) do
    wndCurr:Show(false, true)
  end

  Apollo.GetAddon("CandyUI").tAddons[name] = wndControls

  return true
end

function CandyUI:OnRegisterOptionsDelay()
  --Delay so these appear last on list?
  --**********SWITCH TO SORTED LIST***********
  self:OnThanksAdd()
  self:OnModulesAdd()
end

function CandyUI:OnThanksAdd()
  --This function adds a thanks section to the /cui options.
  ----------------------------------------------------------
  local wndThanksControls = Apollo.LoadForm(self.xmlDoc, "ThanksOptions", self.wndOptions:FindChild("OptionsDialogueControls"), self)
  --wndThanksControls:Show(false, true)

  CUI_RegisterOptions("Thanks", wndThanksControls)
end

function CandyUI:OnModulesAdd()
  --This function adds a module list to the /cui options.
  -------------------------------------------------------
  local wndModulesControls = Apollo.LoadForm(self.xmlDoc, "ModulesOptions", self.wndOptions:FindChild("OptionsDialogueControls"), self)
  --wndModulesControls:Show(false, true)

  CUI_RegisterOptions("Modules", wndModulesControls, true)
end

-----------------------------------------------------------------------------------------------
-- CandyUIForm Functions
-----------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
-- OptionsDialogue Functions
---------------------------------------------------------------------------------------------------
function CandyUI:HideAllOptions()
  for name, wndCurr in pairs(self.tAddons) do
    wndCurr:Show(false, true)
  end
end

function CandyUI:OnOptionsHomeClick(wndHandler, wndControl, eMouseButton)
  self:HideAllOptions()
  self.wndOptions:FindChild("ListControls"):DestroyChildren()
  for name, wndControls in pairsByKeys(self.tAddons) do
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

function CandyUI:OnCloseButtonClick(wndHandler, wndControl, eMouseButton)
  self.wndOptions:Close()
end

function CandyUI:OnDefaultClick(wndHandler, wndControl, eMouseButton)
  --add default code here
  Print("Sorry! The default function has not been written yet.")
end

---------------------------------------------------------------------------------------------------
-- OptionsListItem Functions
---------------------------------------------------------------------------------------------------
function CandyUI:OnOptionsCatClick(wndHandler, wndControl, eMouseButton)
  --Get addon name
  local strAddon = wndControl:GetText()
  --Get other arguments (stored as window data)
  local tData = self.tAddons[strAddon]:GetData()
  --Check if its a single tiered option
  local bSingleTier = tData.bSingleTier
  if bSingleTier then
    --If single tiered
    ------------------
    -- Hide all options
    self:HideAllOptions()
    --Show options page
    self.tAddons[strAddon]:Show(true)
    for _, wndCurr in pairs(self.tAddons[strAddon]:GetChildren()) do
      wndCurr:Show(true)
    end
  else
    --If multi tiered
    -----------------
    -- Hide all options
    self:HideAllOptions()
    --Destroy Nav List children (buttons)
    self.wndOptions:FindChild("ListControls"):DestroyChildren()
    --Show addon options
    self.tAddons[strAddon]:Show(true)
    --Get children
    local arChildren = self.tAddons[strAddon]:GetChildren()
    --New table to sort by name
    local tChildrenList = {}
    for _, wndCurr in pairs(arChildren) do
      local strName = wndCurr:FindChild("Title"):GetText()
      tChildrenList[strName] = wndCurr
    end
    --Add buttons
    for strName, wndCurr in pairsByKeys(tChildrenList) do
      --Load button window
      local wndButton = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptions:FindChild("ListControls"), self)
      --Change OnClick function
      wndButton:RemoveEventHandler("ButtonUp")
      wndButton:AddEventHandler("ButtonUp", "OnAddonCatClick")
      --Set Properties
      wndButton:SetText(strName)
      wndButton:SetData(strAddon)
    end
    --Arrange Vertical
    self.wndOptions:FindChild("ListControls"):ArrangeChildrenVert()
  end
end

function CandyUI:OnAddonCatClick(wndHandler, wndControl, eMouseButton)
  --Get Addon name
  local strAddon = wndControl:GetData()
  --Show the correct window, hide the rest.
  for _, wndCurr in pairs(self.tAddons[strAddon]:GetChildren()) do
    if wndCurr:FindChild("Title"):GetText() == wndControl:GetText() then
      wndCurr:Show(true)
    else
      wndCurr:Show(false)
    end
  end
end

function CandyUI:OnModulesTimer()
  if self.wndWelcome ~= nil and self.wndWelcome:IsShown() then
    local wndScrollList = self.wndWelcome:FindChild("ModuleList:ScrollList")
    self:PopulateModulesList(wndScrollList)
  end
end

function CandyUI:PopulateModulesList(wndScrollList)
  if wndScrollList == nil then
    return
  end

  wndScrollList:DestroyChildren()
  for i, strName in ipairs(karCUIModules) do
    local wndModule = Apollo.LoadForm(self.xmlDoc, "ModuleListItem", wndScrollList, self)
    wndModule:FindChild("Name"):SetText(strName)
    local bLoaded = IsAddonLoaded(strName)
    wndModule:FindChild("IconNo"):Show(not bLoaded, true)
    wndModule:FindChild("IconYes"):Show(bLoaded, true)
  end
  wndScrollList:ArrangeChildrenVert()
end

kcuiODefaults = {
  char = {
    currentProfile = nil,
    bFirstRun = true,
    bSyncCandyBars = false,
    bSyncStarPanel = false,
  },
  profile = {},

  ---------------------------------------------------------------------------------------------------
  -- WelcomeForm Functions
  ---------------------------------------------------------------------------------------------------
}
function CandyUI:OnWelcomeClose(wndHandler, wndControl, eMouseButton)
  self.wndWelcome:Show(false)
  self.db.char.bFirstRun = false
end

---------------------------------------------------------------------------------------------------
-- ModulesOptions Functions
---------------------------------------------------------------------------------------------------
function CandyUI:OnModulesListShown(wndHandler, wndControl)
  local wndScrollList = wndControl:FindChild("ModulesList:ScrollList")
  self:PopulateModulesList(wndScrollList)
end

---------------------------------------------------
-- Profiles
---------------------------------------------------
function CandyUI:OnNewProfileReturn(wndHandler, wndControl, strText)
  if strText == "" then return end
  --self.db:SetProfile(strText)
  --self.db.char.currentProfile = strText
  _cui.strCurrentProfile = strText
  self.wndCurrentProfileDropdown:SetText(strText)
  wndControl:SetText("")
  --SetOptions
  self:SetCurrentProfiles(strText)
end

function CandyUI:SetCurrentProfiles(strProfile)
  Print("Setting profile to " .. strProfile .. "...")
  for i, strAddonName in ipairs(karCUIModules) do
    local bLoaded = IsAddonLoaded(strAddonName)
    local addon = Apollo.GetAddon(strAddonName)

    if (strAddonName == "CandyBars" and not self.db.char.bSyncCandyBars) or (strAddonName == "StarPanel" and not self.db.char.bSyncStarPanel) then
      bLoaded = false
    end

    if bLoaded and addon.db ~= nil then

      addon.db:SetProfile(strProfile)
      addon.db.char.currentProfile = strProfile --wndControl:GetText()

      Print(strAddonName .. " profile set.")

      if addon.SetOptions ~= nil then
        addon:SetOptions()

        Print(strAddonName .. " options set.")
      else
        Print(strAddonName .. " options NOT set.")
      end
    else
      Print(strAddonName .. " profile NOT set.")
    end
  end
end

function CandyUI:CopyProfiles(strProfile)
  Print("Copying " .. strProfile .. "...")
  for i, strAddonName in ipairs(karCUIModules) do
    local bLoaded = IsAddonLoaded(strAddonName)
    local addon = Apollo.GetAddon(strAddonName)

    if (strAddonName == "CandyBars" and not self.db.char.bSyncCandyBars) or (strAddonName == "StarPanel" and not self.db.char.bSyncStarPanel) then
      bLoaded = false
    end

    if bLoaded and addon.db ~= nil then
      addon.db:CopyProfile(strProfile, true)

      if addon.SetOptions ~= nil then
        addon:SetOptions()
      end
    end
  end
end

function CandyUI:DeleteProfiles(strProfile)
  Print("Deleting " .. strProfile .. "...")
  for i, strAddonName in ipairs(karCUIModules) do
    local bLoaded = IsAddonLoaded(strAddonName)
    local addon = Apollo.GetAddon(strAddonName)

    if (strAddonName == "CandyBars" and not self.db.char.bSyncCandyBars) or (strAddonName == "StarPanel" and not self.db.char.bSyncStarPanel) then
      bLoaded = false
    end

    if bLoaded and addon.db ~= nil then

      addon.db:DeleteProfile(strProfile, true)

      Print(strAddonName .. " deleted.")
    else
      Print(strAddonName .. " NOT deleted.")
    end
  end
end

function CandyUI:DefaultProfiles(strProfile)
  Print("Setting " .. strProfile .. " to default...")
  for i, strAddonName in ipairs(karCUIModules) do
    local bLoaded = IsAddonLoaded(strAddonName)
    local addon = Apollo.GetAddon(strAddonName)

    if (strAddonName == "CandyBars" and not self.db.char.bSyncCandyBars) or (strAddonName == "StarPanel" and not self.db.char.bSyncStarPanel) then
      bLoaded = false
    end

    if bLoaded and addon.db ~= nil then

      addon.db:ResetProfile()

      Print(strAddonName .. " set to default.")
    else
      Print(strAddonName .. " NOT set to default.")
    end
  end
end

function CandyUI:CheckCurrentProfiles()
  local strCurrent = _cui.strCurrentProfile

  for i, strAddonName in ipairs(karCUIModules) do
    local bLoaded = IsAddonLoaded(strAddonName)
    local addon = Apollo.GetAddon(strAddonName)

    if (strAddonName == "CandyBars" and not self.db.char.bSyncCandyBars) or (strAddonName == "StarPanel" and not self.db.char.bSyncStarPanel) then
      bLoaded = false
    end

    if bLoaded and addon.db ~= nil then
      local strAddonCurrent = addon.db:GetCurrentProfile()

      if strAddonCurrent ~= strCurrent then
        return false
      end
    end
  end

  return true
end

function CandyUI:OnDeleteProfileDropdownClick(wndHandler, wndControl, eMouseButton)
  self.wndDeleteProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()

  for name, value in pairs(self.db:GetProfiles()) do
    if value ~= self.db:GetCurrentProfile() then
      local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndDeleteProfileDropdownBox:FindChild("ScrollList"), self)

      currButton:SetText(value)

      --currButton:RemoveEventHandler("ButtonUp")
      currButton:AddEventHandler("ButtonUp", "OnDeleteProfileItemClick")
    end
  end

  self.wndDeleteProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()

  self.wndDeleteProfileDropdownBox:Show(true)
end

function CandyUI:OnDeleteProfileItemClick(wndHandler, wndControl, eMouseButton)
  self.wndDeleteProfileDropdownBox:Show(false)
  self.wndConfirmAlert:FindChild("NoticeText"):SetText("Are you sure you want to delete " .. wndControl:GetText() .. "?")
  self.wndConfirmAlert:SetData(wndControl:GetText())
  self.wndConfirmAlert:Show(true)
  self.wndConfirmAlert:ToFront()
end

function CandyUI:OnConfirmYes(wndHandler, wndControl, eMouseButton)
  local strProfile = self.wndConfirmAlert:GetData()
  self:DeleteProfiles(strProfile)
  wndControl:GetParent():Show(false)
end

function CandyUI:OnConfirmNo(wndHandler, wndControl, eMouseButton)
  wndControl:GetParent():Show(false)
end

function CandyUI:OnCurrentProfileDropdownClick(wndHandler, wndControl, eMouseButton)
  self.wndCurrentProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()
  --- Print(999)
  for name, value in pairs(self.db:GetProfiles()) do
    if value ~= self.db:GetCurrentProfile() then
      local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndCurrentProfileDropdownBox:FindChild("ScrollList"), self)
      currButton:SetText(value)
      currButton:AddEventHandler("ButtonUp", "OnCurrentProfileItemClick")
    end
  end

  self.wndCurrentProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
  self.wndCopyProfileDropdown:Enable(false)
  --self.tAddons["Profile"]:FindChild("SPSync"):Enable(false)
  self.wndCurrentProfileDropdownBox:Show(true)
end

function CandyUI:OnCurrentProfileItemClick(wndHandler, wndControl, eMouseButton)
  self.wndCurrentProfileDropdown:SetText(wndControl:GetText())

  _cui.strCurrentProfile = wndControl:GetText()

  self:SetCurrentProfiles(wndControl:GetText())

  self.wndCurrentProfileDropdownBox:Show(false)
end

function CandyUI:OnCurrentDropHide(wndHandler, wndControl)
  self.wndCopyProfileDropdown:Enable(true)
  --self.tAddons["Profile"]:FindChild("SPSync"):Enable(true)
end

function CandyUI:OnCopyFromDropdownClick(wndHandler, wndControl, eMouseButton)
  self.wndCopyProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()

  for name, value in pairs(self.db:GetProfiles()) do
    if value ~= self.db:GetCurrentProfile() then
      local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndCopyProfileDropdownBox:FindChild("ScrollList"), self)
      currButton:SetText(value)
      currButton:AddEventHandler("ButtonUp", "OnCopyProfileItemClick")
    end
  end

  self.wndCopyProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()

  self.wndCopyProfileDropdownBox:Show(true)
end

function CandyUI:OnCopyProfileItemClick(wndHandler, wndControl, eMouseButton)
  self.wndCopyProfileDropdown:SetText(wndControl:GetText())

  --self.db:CopyProfile(wndControl:GetText(), true)
  self:CopyProfiles(wndControl:GetText())

  self.wndCopyProfileDropdownBox:Show(false)
end



-----------------------------------------------------------------------------------------------
-- CandyUI Instance
-----------------------------------------------------------------------------------------------
local CandyUIInst = CandyUI:new()
CandyUIInst:Init()
