--[[---------------------------------------------------------------------------------------------
 ____                         __           ____                             
/\  _`\                      /\ \         /\  _`\                           
\ \ \/\_\     __      ___    \_\ \  __  __\ \ \L\ \     __     _ __   ____  
 \ \ \/_/_  /'__`\  /' _ `\  /'_` \/\ \/\ \\ \  _ <'  /'__`\  /\`'__\/',__\ 
  \ \ \L\ \/\ \L\.\_/\ \/\ \/\ \L\ \ \ \_\ \\ \ \L\ \/\ \L\.\_\ \ \//\__, `\
   \ \____/\ \__/.\_\ \_\ \_\ \___,_\/`____ \\ \____/\ \__/.\_\\ \_\\/\____/
    \/___/  \/__/\/_/\/_/\/_/\/__,_ /`/___/> \\/___/  \/__/\/_/ \/_/ \/___/ 
                                        /\___/                              
                                        \/__/                         v1.0                         
		|\ | _ .|  (`,_ .|-|_  ')/\'| /| 
		| \|(/_||  _)|||||_||  /_\/_|_~|~
                                 
]]-----------------------------------------------------------------------------------------------

--[[
==========
   IDEA!
==========
	Make your own hotkey frame and then hide carbine hotkeys
	with the below info. Then you can add options for
	font and color, easier hide, position, and set
	keybind on exit.

^DO IT!^

--Another Idea>
add a hot switch mode to the layout editor so when you hit a hotkey... no nvm

===========
no hotkey
===========
ActionButtonTemplate - 45
	EmptySlot - 45
	ActionButton - 60
	Border - 45
+bottom hotkey
	
==============
bottom hotkey
==============
ActionButtonTemplate - 60
	EmptySlot - 45
	ActionButton - 60
	Border - 45
+bottom hotkey
]]
require "Window"
require "Apollo"
require "GameLib"
require "Spell"
require "Unit"
require "Item"
--require "PlayerPathLib"
require "AbilityBook"
require "ActionSetLib"
--require "AttributeMilestonesLib"
require "Tooltip"
require "HousingLib"

-----------------------------------------------------------------------------------------------
-- CandyBars Module Definition
-----------------------------------------------------------------------------------------------
local CandyBars = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local VERSION = 1.05

--Global CUI var
if _cui == nil then
  _cui = {}
end

local KeybindingState = {
  Idle = 0,
  AcceptingInput = 1,
  SelectingSet = 2,
  ConfirmUnbindDuplicate = 3,
  SelectCopySet = 4,
  AcceptingModfierInput = 5,
}

local ktCDPixie = {
  strText = "",
  strFont = "CRB_Interface10",
  bLine = false,
  strSprite = "AbilitiesSprites:spr_StatBlueVertProg",
  cr = { a=0.7, r=1, g=1, b=1 },
  loc = {
    fPoints = { 0, 1, 1, 1 },
    nOffsets = { 0, 0, 0, 0 }
  },
  flagsText = {
    DT_CENTER = true,
    DT_VCENTER = true
  }
}
--%%%%%%%%%%%
--   ROUND
--%%%%%%%%%%%
local function round(num, idp)
  local mult = 10^(idp or 0)
  if num >= 0 then return math.floor(num * mult + 0.5) / mult
  else return math.ceil(num * mult - 0.5) / mult end
end
--%%%%%%%%%%%
--   Debug
--%%%%%%%%%%%
local function debug(strText)
  if CandyBars_Debug then
    ChatSystemLib.PostOnChannel( ChatSystemLib.ChatChannel_System, tostring(strText), "CandyBars Debug" )
  end
end
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CandyBars:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- initialize variables here
  self.actionButtons = {}

  return o
end

function CandyBars:Init()
  local bHasConfigureFunction = true
  local strConfigureButtonText = "CandyBars"
  local tDependencies = {
    -- "UnitOrPackageName",
  }

  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- Options save and restore
-----------------------------------------------------------------------------------------------
--[[
KEEP and save these vars
	--Save Anchors
	tSave.tAnchorOffsets = {self.wndMain:GetAnchorOffsets()}
	tSave.tInnateAnchorOffsets = {self.wndInnate:GetAnchorOffsets()}
	tSave.tSecondaryAnchorOffsets = {self.wndSecondary:GetAnchorOffsets()}
	tSave.tUtility1AnchorOffsets = {self.wndUtility1:GetAnchorOffsets()}
	tSave.tUtility2AnchorOffsets = {self.wndUtility2:GetAnchorOffsets()}
	tSave.tVehicleAnchorOffsets = {self.wndVehicleBar:GetAnchorOffsets()}
	tSave.VERSION = VERSION
]]

-----------------------------------------------------------------------------------------------
-- CandyBars OnLoad
-----------------------------------------------------------------------------------------------
function CandyBars:OnLoad()
  self.xmlDoc = XmlDoc.CreateFromFile("CandyBars.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
  self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, ktCBDefaults)
end

-----------------------------------------------------------------------------------------------
-- CandyBars OnDocLoaded
-----------------------------------------------------------------------------------------------
function CandyBars:OnDocLoaded()
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    --CUI load status
    if _cui.tAddonLoadStatus == nil then
      _cui.tAddonLoadStatus = {}
    end
    _cui.tAddonLoadStatus["CandyBars"] = true

    --self.bKeybindMode = false
    CandyBars_Debug = self.db.char.debug

    Apollo.LoadSprites("Sprites.xml")

    --Initialize Bar Objects
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ActionBarForm", nil, self)
    --Name
    self.wndMain:SetName("actionBarAnchor")
    --Save Anchor Event
    self.wndMain:AddEventHandler("WindowMove", "OnBarMoved", self)

    self.wndInnate = Apollo.LoadForm(self.xmlDoc, "ActionBarForm", nil, self)
    --Name
    self.wndInnate:SetName("innateBarAnchor")
    --Save Anchor Event
    self.wndInnate:AddEventHandler("WindowMove", "OnBarMoved")

    self.wndSecondary = Apollo.LoadForm(self.xmlDoc, "SecondaryBarForm", nil, self)
    --Name
    self.wndSecondary:SetName("secondaryBarAnchor")
    --Save Anchor Event
    self.wndSecondary:AddEventHandler("WindowMove", "OnBarMoved")

    self.wndSecondarySplit = Apollo.LoadForm(self.xmlDoc, "SecondaryBarForm", nil, self)
    --Name
    self.wndSecondarySplit:SetName("secondaryBarSplitAnchor")
    --Save Anchor Event
    self.wndSecondarySplit:AddEventHandler("WindowMove", "OnBarMoved")

    self.wndUtility1 = Apollo.LoadForm(self.xmlDoc, "UtilityBarForm", nil, self)
    --Name
    self.wndUtility1:SetName("utility1BarAnchor")
    --Save Anchor Event
    self.wndUtility1:AddEventHandler("WindowMove", "OnBarMoved")

    self.wndUtility2 = Apollo.LoadForm(self.xmlDoc, "UtilityBarForm", nil, self)
    --Name
    self.wndUtility2:SetName("utility2BarAnchor")
    --Save Anchor Event
    self.wndUtility2:AddEventHandler("WindowMove", "OnBarMoved")

    self.wndVehicleBar = Apollo.LoadForm(self.xmlDoc, "VehicleBarFrame", nil, self)
    --Name
    self.wndVehicleBar:SetName("vehicleBarAnchor")
    --Save Anchor Event
    self.wndVehicleBar:AddEventHandler("WindowMove", "OnBarMoved")

    --OnShowActionBarShortcut
    Apollo.RegisterEventHandler("ShowActionBarShortcut", "ShowVehicleBar", self)

    --Add To Interface Menu
    Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
    Apollo.RegisterEventHandler("CandyBarsInterfaceMenuClick", "OnCandyBarsInterfaceMenuClick", self)

    self.unitPlayer = GameLib.GetPlayerUnit()
    self.wndOptionsNew = Apollo.LoadForm(self.xmlDoc, "OptionsDialogueNew", nil, self)
    self.wndOptionsNew:Show(false, true)
    self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControlsList", self.wndOptionsNew:FindChild("OptionsDialogueControls"), self)

    for i, v in ipairs(self.wndControls:GetChildren()) do
      if v:GetName() ~= "Help" then
        local strCategory = v:FindChild("Title"):GetText()
        local wndCurr = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptionsNew:FindChild("ListControls"), self)

        wndCurr:SetText(strCategory)
      end
    end

    self.wndOptionsNew:FindChild("ListControls"):ArrangeChildrenVert()

    --[[
    for rows=1, 3 do
      for cols=1, 3 do
        local wndCurr = Apollo.LoadForm(self.xmlDoc, "ActionButtonDummy", self.wndControls:FindChild("LayoutEditorControls"):FindChild("GridInset"), self)
      end
    end
    self.wndControls:FindChild("LayoutEditorControls"):FindChild("GridInset"):ArrangeChildrenTiles(2)

    --For Collapse/Expand

    ]]
    --Color Picker
    GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
    self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
    self.colorPicker:Show(false)

    --self.wndColorDropdown = self.wndControls:FindChild("BorderControls"):FindChild("Color"):FindChild("ColorDropdown")
    --self.wndColorDropdownBox = self.wndControls:FindChild("BorderControls"):FindChild("Color"):FindChild("DropdownBox")

    self.wndConfirmAlert = Apollo.LoadForm(self.xmlDoc, "ConfirmAlert", nil, self)
    self.wndConfirmAlert:Show(false)

    self.wndKeybindModeAlert = Apollo.LoadForm(self.xmlDoc, "KeybindModeAlert", nil, self)
    self.wndKeybindModeAlert:Show(false)
    self.wndKeybindInfo = self.wndKeybindModeAlert:FindChild("BindingInfo")

    --self.wndColorDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()

    --CUI Options
    if _cui.bOptionsLoaded == true then
      self:RegisterCUIOptions()
    else
      Apollo.RegisterEventHandler("CandyUI_OptionsLoaded", "RegisterCUIOptions", self)
    end

    Apollo.RegisterEventHandler("ShowActionBarShortcut", "ShowShortcutBar", self)

    Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)
    Apollo.RegisterEventHandler("StanceChanged", "OnStanceChanged", self)
    Apollo.RegisterEventHandler("SpecChanged", "OnSpecChanged", self)
    --AbilityWindowHasBeenToggled
    Apollo.RegisterEventHandler("ToggleBlockBarsVisibility", "OnSpecChanged", self)
    --ActionBarLoaded
    Apollo.RegisterEventHandler("NextFrame", "OnFrame", self)
    Apollo.RegisterEventHandler("ChangeWorld", "OnSpecChanged", self)
    --KeyBindingUpdated
    --Apollo.RegisterEventHandler("KeyBindingUpdated", "OnKeyBindingUpdated", self)
    Apollo.RegisterEventHandler("KeybindInterfaceClosed", "OnKeyBindingUpdated", self)
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)

    --Apollo.RegisterSlashCommand("cb debug", "OnCandyBarsDebug", self)
    Apollo.RegisterSlashCommand("cb", "OnCandyBars", self)
    self.timerMountReset = ApolloTimer.Create(0.4, false, "OnTimerMountReset", self)
    self.timerMountReset:Stop()
    --=====================================
    --			Keybind Mode
    --=====================================
    Apollo.RegisterEventHandler("MouseButtonUp", "OnMouseButtonUp", self)

    self.timerKeybindInfo = ApolloTimer.Create(2.0, false, "OnTimerKeybindInfo", self)
    self.timerKeybindInfo:Stop()

    --=====================================
    --			Layout Mode
    --=====================================
    self.timerGetActionSet = ApolloTimer.Create(0.3, false, "GetActionSet", self)
    self.timerGetActionSet:Stop()

    --self.timerDelayActionBarInit = ApolloTimer.Create(0.3, false, "DelayActionBarInit" , self)
    --self.timerDelayActionBarInit:Stop()

    --Potion Temp Fix
    self.timerFixPot = ApolloTimer.Create(1, true, "FixPotion" , self)
    self.timerFixPot:Start()

    --self.timerActionSetChange = ApolloTimer.Create(5.0, true, "OnTimerActionSetChange" , self)
    --self.timerActionSetChange:Stop()
    self.bIsReady = false
    --Wait till ready
    self.timerLoad = ApolloTimer.Create(0.25, true, "LoadWhenReady" , self)
    self.timerLoad:Start()
  end
end

function CandyBars:RegisterCUIOptions()
  --Load Options
  local wndOptionsControls = Apollo.GetAddon("CandyUI_Options").wndOptions:FindChild("OptionsDialogueControls")
  local wndControls = Apollo.LoadForm(self.xmlDoc, "CBOptions", wndOptionsControls, self)

  CUI_RegisterOptions("CandyBars", wndControls, true)
end

function CandyBars:CheckFunctions()
  local arFunctionToCheck = {
    ActionSetLib.GetCurrentActionSet,
    AbilityBook.GetAbilitiesList,
    GameLib.GetPlayerUnit,
  }

  for _, func in ipairs(arFunctionToCheck) do
    if func() == nil then
      return false
    end
  end

  return true
end

function CandyBars:LoadWhenReady()
  if self:CheckFunctions() then
    self.timerLoad:Stop()
    self.bIsReady = true
    debug("Everything loaded.")
    --Load
    --set curr profile
    if not self.db.char.currentProfile then
      self.db.char.currentProfile = self.db:GetCurrentProfile()
    else
      self.db:SetProfile(self.db.char.currentProfile)
    end
    --Set Up Options
    self:SetOptions()
    --Grid
    self:PopulateLayoutList(self)
    self:CreateLayoutGrid(self)
    self:PopulateLayoutGrid(self)
    --Set up bars
    --Action Bar
    self:InitializeBar(self)
    self:ArrangeBar(self)
    --Innate Bar
    CandyBars:InitializeInnateBar(self)
    CandyBars:ArrangeInnateBar(self)
    --Secondary Bar
    CandyBars:InitializeSecondaryBar(self)
    CandyBars:ArrangeSecondaryBar(self)
    --Utility Bar
    CandyBars:InitializeUtilityBar1(self)
    CandyBars:InitializeUtilityBar2(self)
    CandyBars:ArrangeUtilityBar1(self)
    CandyBars:ArrangeUtilityBar2(self)
    --Shortcut Bar
    CandyBars:InitializeShortcutBar(self)

    --gretting
    ChatSystemLib.PostOnChannel(8, "Welcome to CandyBars!", "CandyBars:" )
    ChatSystemLib.PostOnChannel(8, "Type \"/cb\" to open options.", "CandyBars:" )
  end
end

function CandyBars:FixPotion()
  if self.db.profile.flyoutButtons.nSavedPotion and self.db.profile.flyoutButtons.nSavedPotion ~= GameLib.GetShortcutPotion() then
    GameLib.SetShortcutPotion(self.db.profile.flyoutButtons.nSavedPotion)
  end
  self:UpdateHotkeyText(self)
end

function CandyBars:GetActionSet()
  self:PopulateLayoutList(self)
end

function CandyBars:DelayActionBarInit()
  if self.tCurrentActionSet ~= nil then
    self:InitializeBar(self)
    self:ArrangeBar(self)
    --Print(1)
  else
    self.tCurrentActionSet = ActionSetLib.GetCurrentActionSet()
    self.timerDelayActionBarInit:Stop()
    self.timerDelayActionBarInit:Start()
    --Print(2)
  end
end

function CandyBars:OnFrame()
  self:OnTimerMountReset()

  for idx, wnd in ipairs(self.actionButtons) do
    local aBut = wnd:FindChild("ActionButtonNew")
    if aBut and aBut:GetContent() and aBut:GetContent().spell then
      local spl = aBut:GetContent().spell
      local fCD = round(spl:GetCooldownRemaining(), 1)
      local fCDMax = spl:GetCooldownTime()
      local nHeight = wnd:GetHeight()
      local nProg = fCDMax == 0 and 0 or round((fCD / fCDMax) * nHeight, 1)
      local nPixieID = self.arActionButtonPixies[idx]
      local tPixieData = ktCDPixie
      if self.db.profile.actionBar.bShowCDBars then
        tPixieData.loc.nOffsets = {0, nProg*-1, 0, 0}
      else
        tPixieData.loc.nOffsets = {0, 0, 0, 0}
      end
      if nProg and wnd:FindChild("CD") then
        --wnd:FindChild("CD"):SetAnchorOffsets(0, nProg*-1, 0, 0)
        wnd:FindChild("CD"):UpdatePixie(nPixieID, tPixieData)
      end
    end
  end
end

function CandyBars:OnKeyBindingUpdated()
  self:UpdateHotkeyText(self)
end
--#####################
--# Check Out :Move() #   <--
--#####################

function CandyBars:OnUnitEnteredCombat(unitEnt, bInCombat)
  local strUnitName = unitEnt:GetName()
  local strOption = self.db.profile.actionBar.strInCombat
  if strUnitName == GameLib.GetPlayerUnit():GetName() and strOption then
    if strOption == "Show" then
      self.wndMain:Show(bInCombat)
    elseif strOption == "Hide" then
      self.wndMain:Show(not bInCombat)
    end
  end
end

function CandyBars:OnStanceChanged(...)
  if self.wndOptionsNew:IsVisible() then
    self.wndOptionsNew:Show(false, true)
    self.wndOptionsNew:Show(true, true)
  end

  --self:PopulateLayoutList(self)
  --self:PopulateLayoutGrid(self)
end

function CandyBars:OnSpecChanged()
  --self.timerMountReset:Start()
  if self.wndOptionsNew:IsVisible() then
    self.wndOptionsNew:Show(false, true)
    self.wndOptionsNew:Show(true, true)
  end

  --self:PopulateLayoutList(self)
  --self:PopulateLayoutGrid(self)
end

function CandyBars:OnBarMoved(wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom)
  local strName = wndControl:GetName()
  local tAnchors = {wndControl:GetAnchorOffsets()}
  --Print(1)
  if strName == "actionBarAnchor" then
    self.db.profile.actionBar.tAnchorOffsets = tAnchors
  elseif strName == "secondaryBarAnchor" then
    self.db.profile.secondaryBar.tAnchorOffsets = tAnchors
  elseif strName == "secondaryBarSplitAnchor" then
    self.db.profile.secondaryBar.tSplitAnchorOffsets = tAnchors
  elseif strName == "innateBarAnchor" then
    self.db.profile.innateBar.tAnchorOffsets = tAnchors
  elseif strName == "vehicleBarAnchor" then
    self.db.profile.vehicleBar.tAnchorOffsets = tAnchors
  elseif strName == "utility1BarAnchor" then
    self.db.profile.utilityBars.bar1.tAnchorOffsets = tAnchors
  elseif strName == "utility2BarAnchor" then
    self.db.profile.utilityBars.bar2.tAnchorOffsets = tAnchors
  elseif strName == "ShortcutBar" then
    local index = tonumber(wndControl:FindChild("Index"):GetText())
    --Print("idx = "..unpack(tAnchors))

    self.db.profile.shortcutBars[index]["tAnchorOffsets"] = tAnchors

  end
end

--ACTION SHORTCUT
function CandyBars:InitializeShortcutBar(self)
  local tShortcutCount = {}

  self.tActionBarSettings = {}

  self.tActionBarsHorz = {}
  for idx = 4, ActionSetLib.CodeEnumShortcutSet.Count do
    local wndCurrBar = Apollo.LoadForm(self.xmlDoc, "ShortcutBar", nil, self)
    wndCurrBar:FindChild("Index"):SetText(idx)
    local lock = self.db.profile.general.bLockBars
    wndCurrBar:SetStyle("Moveable", not lock)
    wndCurrBar:SetStyle("Picture", not lock)
    wndCurrBar:Show(false)

    for iBar = 0, 7 do
      local wndBarItem = Apollo.LoadForm(self.xmlDoc, "ShortcutBarItem", wndCurrBar:FindChild("ActionBarContainer"), self)
      wndBarItem:FindChild("ActionBarShortcutBtn"):SetContentId(idx * 12 + iBar)
      if wndBarItem:FindChild("ActionBarShortcutBtn"):GetContent()["strIcon"] ~= "" then
        tShortcutCount[idx] = iBar + 1
      end

      wndCurrBar:FindChild("ActionBarContainer"):ArrangeChildrenHorz(0)
    end
    --Set Pos
    if self.db.profile.shortcutBars[idx] == nil then
      self.db.profile.shortcutBars[idx] = {}
      self.db.profile.shortcutBars[idx]["tAnchorOffsets"] = {-183, 146, 217, 228}
    end
    local tOffsets = self.db.profile.shortcutBars[idx]["tAnchorOffsets"]
    wndCurrBar:SetAnchorOffsets(unpack(tOffsets))
    --Print("idx = "..idx.." offsets = "..tOffsets[1]..", "..tOffsets[2]..", "..tOffsets[3]..", "..tOffsets[4])
    self.tActionBarsHorz[idx] = wndCurrBar
  end

  for idx = 4, ActionSetLib.CodeEnumShortcutSet.Count do
    self:ShowShortcutBar(idx, IsActionBarSetVisible(idx), tShortcutCount[idx])
  end
end

function CandyBars:ShowShortcutBar(nBar, bIsVisible, nShortcuts)
  if self.tActionBarsHorz == nil or self.tActionBarsHorz[nBar] == nil then
    return
  end
  --Print("idx = "..nBar.."visible = "..tostring(bIsVisible))
  self.tActionBarsHorz[nBar]:Show(bIsVisible and self.db.profile.general.bEnableShortcutBar, not bIsVisible)
end



-----------------------------------------------------------------------------------------------
-- Interface Menu Handler
-----------------------------------------------------------------------------------------------

function CandyBars:OnInterfaceMenuListHasLoaded()
  Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "CandyBars", {"CandyBarsInterfaceMenuClick", "", ""})

  --self:UpdateInterfaceMenuAlerts()
end

function CandyBars:OnCandyBarsInterfaceMenuClick()
  self.wndOptionsNew:Invoke()
  self:PopulateLayoutList(self)
  self:CreateLayoutGrid(self)
  self:PopulateLayoutGrid(self)
end
-----------------------------------------------------------------------------------------------
-- Slash Command Handlers
-----------------------------------------------------------------------------------------------

function CandyBars:OnCandyBars(strCmd,strArg)
  strArg = string.lower(strArg)
  if (strArg == "") then
    self:OnCandyBarsOn()
  elseif (strArg == "debug") then
    self:OnCandyBarsDebug()
  else
    --Nothing?
  end
end
-- on SlashCommand "/cb"
function CandyBars:OnCandyBarsOn()
  self.wndOptionsNew:Invoke() -- show the options window
  self:PopulateLayoutList(self)
  self:CreateLayoutGrid(self)
  self:PopulateLayoutGrid(self)
end

function CandyBars:OnCandyBarsDebug()
  self.db.char.debug = not self.db.char.debug
  CandyBars_Debug = self.db.char.debug
  if self.db.char.debug then
    ChatSystemLib.PostOnChannel( ChatSystemLib.ChatChannel_System, "Debug has been enabled.", "CandyBars Debug" )
  else
    ChatSystemLib.PostOnChannel( ChatSystemLib.ChatChannel_System, "Debug has been disabled.", "CandyBars Debug" )
  end
end


-- from ESC menu
function CandyBars:OnConfigure()
  self.wndOptionsNew:Invoke()
  self:PopulateLayoutList(self)
  self:CreateLayoutGrid(self)
  self:PopulateLayoutGrid(self)
end

-- on SlashCommand "/cb help"
function CandyBars:OnCandyBarsHelp()
  Print("CandyBars Help")
  Print("--------------")
  Print("/cb        : Open options")
  Print("/cb lock   : Lock/Unlock bars")
  Print("")
  Print("")
end

-----------------------------------------------------------------------------------------------
-- Action Bar
-----------------------------------------------------------------------------------------------

function CandyBars:SetButtonOffsets(wndCurr, strType)
  --[[
  strType
  -"None" --no hotkeys
  -"Hotkey" --with hotkeys
  -"Bottom
  ]]
  return nil
end



function CandyBars:InitializeBar(self)
  --Show main form
  self.wndMain:Show(self.db.profile.actionBar.bShowBar)
  --Print(123)
  --Clear children
  self.wndMain:DestroyChildren()
  self.wndSpecSwitches = Apollo.LoadForm(self.xmlDoc, "SpecSwitches", self.wndMain, self)
  self.wndSpecSwitches:Show(self.db.profile.actionBar.bShowSpecSwitch and not self.db.profile.layoutEditor.bEnabled)
  self.actionButtons = {}
  self.arActionButtonPixies = {}
  --Innate Toggle
  local nButtons = 0
  if self.db.profile.actionBar.bShowInnate then
    nButtons = self.db.profile.actionBar.nButtons + 1
  else
    nButtons = self.db.profile.actionBar.nButtons
  end

  --Populate Button Array
  if self.db.profile.layoutEditor.bEnabled then
    nButtons = self.db.profile.layoutEditor.nRows * self.db.profile.layoutEditor.nCols
    local tActionSet = self.tCurrentActionSet --ActionSetLib.GetCurrentActionSet()

    for i=1, nButtons do
      --self.db.profile.layoutEditor.tActionBarLayout = {}
      local nSpellId = self.db.profile.layoutEditor.tActionBarLayout[i]
      --Print(nSpellId)
      if nSpellId then --and self.tActionListSpells[nSpellId] then
      --local nInnateId = GameLib.GetCurrentClassInnateAbilitySpell():GetId()
      --spellId is now the position not the id <=====
      if nSpellId == "Innate" then
        --Insert Innate
        local actionButtonInnate = Apollo.LoadForm(self.xmlDoc, "ActionButtonInnate", self.wndMain, self)
        local name = actionButtonInnate:FindChild("Name")
        local strActionName = "CastInnateAbility"

        name:SetText("Innate")
        actionButtonInnate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding(strActionName))
        actionButtonInnate:FindChild("Hotkey"):Show(self.db.profile.actionBar.bShowHotkeys)

        self.actionButtons[i] = actionButtonInnate
      else
        --Insert Spell
        local actionButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonTemplate", self.wndMain, self)

        local currButton = actionButtonTemplate:FindChild("ActionButtonNew") --old one is the same name without "New"
        local nActionPos = nSpellId --GetActionSetPos(self, nSpellId)
        local strActionName = nActionPos < 8 and "LimitedActionSet"..nActionPos + 1 or nActionPos == 8 and "CastGadgetAbility" or "CastPathAbility"

        currButton:SetContentId(nActionPos)

        actionButtonTemplate:SetData(strActionName)
        actionButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding(strActionName))
        actionButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.actionBar.bShowHotkeys)
        self.actionButtons[i] = actionButtonTemplate

        local nPixieID = actionButtonTemplate:FindChild("CD"):AddPixie(ktCDPixie)
        self.arActionButtonPixies[i] = nPixieID
      end
      else
        --InsertBlank
        local actionButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonTemplate", self.wndMain, self)

        actionButtonTemplate:FindChild("Hotkey"):Show(false)
        actionButtonTemplate:FindChild("ActionButton"):Show(false)
        actionButtonTemplate:FindChild("ActionButtonNew"):Show(false)
        actionButtonTemplate:FindChild("Border"):Show(false)
        actionButtonTemplate:FindChild("Auth"):Show(false)

        self.actionButtons[i] = actionButtonTemplate
        --actionButtonTemplate:SetData("Empty")
      end
    end
  else
    for i=1, nButtons do
      if (i < nButtons and self.db.profile.actionBar.bShowInnate) or (i <= nButtons and not self.db.profile.actionBar.bShowInnate) then
        self.actionButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonTemplate", self.wndMain, self)

        local currButton = self.actionButtonTemplate:FindChild("ActionButtonNew")
        local strActionName = "LimitedActionSet"..i

        currButton:SetContentId(i - 1)

        self.actionButtonTemplate:SetData(strActionName)
        self.actionButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding(strActionName))
        self.actionButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.actionBar.bShowHotkeys)

        local nPixieID = self.actionButtonTemplate:FindChild("CD"):AddPixie(ktCDPixie)
        self.arActionButtonPixies[i] = nPixieID

        --self.actionButtonTemplate:FindChild("ActionButtonNoHotkey"):SetContentId(i - 1)
        --self.actionButtonTemplate:FindChild("Border"):SetSprite("CandyBars:border2px")
        --self.actionButtonTemplate:FindChild("Border"):Show(false) -- change to option
        --self.actionButtonTemplate:FindChild("Border"):SetBGColor(tBorderColors[self.db.profile.border.sBorderColor])
        --self.actionButtonTemplate:FindChild("Border"):ToFront()

        --currButton:Enable(true)
        self.actionButtons[i] = self.actionButtonTemplate
      elseif self.db.profile.actionBar.bShowInnate then
        local actionButtonInnate = Apollo.LoadForm(self.xmlDoc, "ActionButtonInnate", self.wndMain, self)
        local name = actionButtonInnate:FindChild("Name")
        local strActionName = "CastInnateAbility"

        name:SetText("Innate")
        actionButtonInnate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding(strActionName))
        actionButtonInnate:FindChild("Hotkey"):Show(self.db.profile.actionBar.bShowHotkeys)

        self.actionButtons[i] = actionButtonInnate

      end
    end
  end
  --Toggle Empty Slots
  self:ToggleShowEmptySlots(self)
end

function CandyBars:ArrangeBar(self)

  if not self.db.profile.actionBar.bShowBar then
    return
  end

  local Options = self.db.profile
  local nButtons = #self.actionButtons
  local nCols = Options.actionBar.nCols
  local nRows = math.ceil(nButtons / nCols)
  if Options.layoutEditor.bEnabled then
    nCols = Options.layoutEditor.nCols
    nRows = Options.layoutEditor.nRows
  end
  local nSize = Options.actionBar.nSize
  local nWidth = nSize
  local nHeight = nSize + 15
  --Set Bar Anchors
  local mLeft, mTop, mRight, mBottom = self.wndMain:GetAnchorOffsets()

  mRight = mLeft + (nCols * nSize) + ((nCols-1) * Options.actionBar.nPadding) + 20
  mBottom = mTop + (nRows * nSize) + ((nRows-1) * Options.actionBar.nPadding) + 20

  self.wndMain:SetAnchorOffsets(mLeft, mTop, mRight, mBottom)

  --Set Index
  local index = 1
  if Options.actionBar.bReverseOrder and not Options.layoutEditor.bEnabled then
    if self.db.profile.actionBar.bShowInnate then
      local innate = self.actionButtons[nButtons]
      self.actionButtons[nButtons] = nil
      table.insert(self.actionButtons, 1, innate)
    end
    index = #self.actionButtons
  end

  --Loop through button grid
  for rows=1, nRows do
    for cols=1, nCols do

      --Button Offsets
      local nLeft, nTop, nRight, nBottom = 0, 0, 0, 0
      nLeft = (cols - 1) * (nSize + Options.actionBar.nPadding) + 10
      nTop = (rows - 1) * (nSize + Options.actionBar.nPadding) + 10
      nRight = nLeft + nSize
      nBottom = nTop + nSize
      --Set Button Offsets
      self.actionButtons[index]:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
      --[[
      if not Options.actionBar.bShowHotkeys then
        self.actionButtons[index]:FindChild("ActionButton"):Show(false)
        self.actionButtons[index]:FindChild("ActionButtonNoHotkey"):Show(true)
      end
      ]]
      --Escape
      if Options.actionBar.bReverseOrder and not Options.layoutEditor.bEnabled and index > 1 then
        index = index - 1
      elseif not Options.actionBar.bReverseOrder and index < #self.actionButtons then
        index = index + 1
      else
        break
      end
    end
  end
end

-----------------------------------------------------------------------------------------------
-- Innate Bar self.db.profile.innateBar.
-----------------------------------------------------------------------------------------------
function CandyBars:InitializeInnateBar(self)
  --Toggle Bar
  self.wndInnate:Show(self.db.profile.innateBar.bShowBar)
  --Clear children
  self.wndInnate:DestroyChildren()
  self.innateButtons = {}

  actionButtonInnate = Apollo.LoadForm(self.xmlDoc, "ActionButtonInnate", self.wndInnate, self)

  local name = actionButtonInnate:FindChild("Name")
  name:SetText("Innate")

  actionButtonInnate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding("CastInnateAbility"))
  actionButtonInnate:FindChild("Hotkey"):Show(self.db.profile.innateBar.bShowHotkeys)

  actionButtonInnate:SetData("CastInnateAbility")

  self.innateButtons[1] = actionButtonInnate



end

function CandyBars:ArrangeInnateBar(self)

  if not self.db.profile.innateBar.bShowBar then
    return
  end

  local nCols = 1
  local nRows = 1
  local nSize = self.db.profile.innateBar.nSize

  local mLeft, mTop, mRight, mBottom = self.wndInnate:GetAnchorOffsets()

  mRight = mLeft + (nCols * nSize) + 20
  mBottom = mTop + (nRows * nSize) + 20

  self.wndInnate:SetAnchorOffsets(mLeft, mTop, mRight, mBottom)

  --Button Offsets
  local nLeft, nTop, nRight, nBottom = 10, 10, 10+nSize, 10+nSize
  --Set Button Offsets
  self.innateButtons[1]:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
end
-----------------------------------------------------------------------------------------------
-- Secondary Bar
-----------------------------------------------------------------------------------------------
function CandyBars:InitializeSecondaryBar(self)
  --Toggle Bar
  self.wndSecondary:Show(self.db.profile.secondaryBar.bShowBar)
  self.wndSecondarySplit:Show(self.db.profile.secondaryBar.bShowBar and self.db.profile.secondaryBar.bSplitBar)

  --Clear children
  self.wndSecondary:DestroyChildren()
  self.wndSecondarySplit:DestroyChildren()
  self.secondaryButtons = {}

  --Number of buttons
  self.nSecondaryBtns = self.db.profile.secondaryBar.nButtons + 10

  --self.db.profile.secondaryBar.bSplitBar
  local nSplit = 0
  if self.db.profile.secondaryBar.bSplitBar then
    nSplit = (self.db.profile.secondaryBar.nButtons / 2) + 10
    if self.nSecondaryBtns <= 11 then
      self.nSecondaryBtns = 12
    end
  end
  --Populate Button Array
  for i=11, self.nSecondaryBtns do
    if (i <= nSplit and self.db.profile.secondaryBar.bSplitBar) or not self.db.profile.secondaryBar.bSplitBar then
      self.secondaryButtonTemplate = Apollo.LoadForm(self.xmlDoc, "SecondaryButtonTemplate", self.wndSecondary, self)

      local currButton = self.secondaryButtonTemplate:FindChild("ActionButtonNew")
      currButton:SetContentId(i + 1)
      local idx = i - 10
      local strAction = ""
      if idx <= 12 then
        strAction = "ActionBar1_Slot"..idx
      elseif idx <= 24 then
        strAction = "ActionBar2_Slot"..(idx - 12)
      else
        strAction = "ActionBar3_Slot"..(idx - 24)
      end

      self.secondaryButtonTemplate:SetData(strAction)

      self.secondaryButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding(strAction))
      self.secondaryButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.secondaryBar.bShowHotkeys)

      self.secondaryButtons[i-10] = self.secondaryButtonTemplate
    else
      self.secondaryButtonTemplate = Apollo.LoadForm(self.xmlDoc, "SecondaryButtonTemplate", self.wndSecondarySplit, self)

      local currButton = self.secondaryButtonTemplate:FindChild("ActionButtonNew")
      currButton:SetContentId(i + 1)
      local idx = i - 10
      local strAction = ""
      if idx <= 12 then
        strAction = "ActionBar1_Slot"..idx
      elseif idx <= 24 then
        strAction = "ActionBar2_Slot"..(idx - 12)
      else
        strAction = "ActionBar3_Slot"..(idx - 24)
      end

      self.secondaryButtonTemplate:SetData(strAction)

      self.secondaryButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding(strAction))
      self.secondaryButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.secondaryBar.bShowHotkeys)

      self.secondaryButtons[i-10] = self.secondaryButtonTemplate
    end
  end

  --Toggle Empty Slots
  self:ToggleShowEmptySlots(self)
end

function CandyBars:ArrangeSecondaryBar(self)

  if not self.db.profile.secondaryBar.bShowBar then
    return
  end

  local Options = self.db.profile
  local nCols = Options.secondaryBar.nCols
  local nRows = math.max(math.ceil(#self.wndSecondary:GetChildren() / nCols), math.ceil(#self.wndSecondarySplit:GetChildren() / nCols))
  local nSize = Options.secondaryBar.nSize

  local mLeft, mTop, mRight, mBottom = self.wndSecondary:GetAnchorOffsets()

  mRight = mLeft + (nCols * nSize) + ((nCols-1) * self.db.profile.secondaryBar.nPadding) + 20
  mBottom = mTop + (nRows * nSize) + ((nRows-1) * self.db.profile.secondaryBar.nPadding) + 20

  self.wndSecondary:SetAnchorOffsets(mLeft, mTop, mRight, mBottom)

  mLeft, mTop, mRight, mBottom = self.wndSecondarySplit:GetAnchorOffsets()

  mRight = mLeft + (nCols * nSize) + ((nCols-1) * self.db.profile.secondaryBar.nPadding) + 20
  mBottom = mTop + (nRows * nSize) + ((nRows-1) * self.db.profile.secondaryBar.nPadding) + 20

  self.wndSecondarySplit:SetAnchorOffsets(mLeft, mTop, mRight, mBottom)

  local nBars = 1
  if self.db.profile.secondaryBar.bSplitBar then
    nBars = 2
  end
  --Set Index
  local index = 1
  --Loop through Action Button grid
  for bars = 1, nBars do
    for rows=1, nRows do
      for cols=1, nCols do
        --Button Offsets
        local nLeft, nTop, nRight, nBottom = 0, 0, 0, 0
        nLeft = (cols - 1) * (nSize + self.db.profile.secondaryBar.nPadding) + 10
        nTop = (rows - 1) * (nSize + self.db.profile.secondaryBar.nPadding) + 10
        nRight = nLeft + nSize
        nBottom = nTop + nSize
        --Set Button Offsets

        self.secondaryButtons[index]:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
        --Escape
        if bars == 1 then
          if (self.db.profile.secondaryBar.bSplitBar and index <= #self.wndSecondary:GetChildren()) or (index < #self.wndSecondary:GetChildren()) then
            index = index + 1
          else
            break
          end
        elseif bars == 2 then
          if index < #self.secondaryButtons then
            index = index + 1
          else
            break
          end
        end
      end
    end
  end
end
-----------------------------------------------------------------------------------------------
-- Utility Bar
-----------------------------------------------------------------------------------------------
function CandyBars:InitializeUtilityBar1(self)

  local Options = self.db.profile

  self.wndUtility1:Show(Options.utilityBars.bar1.bShowBar)

  --Clear children
  self.utilityButtons1 = {}
  self.recallButton1 = nil
  self.wndUtility1:DestroyChildren()

  --=====Bar 1=====--
  local index = 1
  if Options.utilityBars.bar1.bShowMountButton then
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonInnate", self.wndUtility1, self)
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    --Mount
    local name = self.utilityButtonTemplate:FindChild("Name")
    name:SetText("Mount")
    currButton:SetContentId(26)
    self.utilityButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding("Mount"))
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.utilityBars.bar1.bShowHotkeys)
    self.utilityButtonTemplate:SetData("Mount")
    self.utilityButtons1[index] = self.utilityButtonTemplate
    index = index + 1
  end
  if Options.utilityBars.bar1.bShowRecallButton then
    --Recall
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonInnate", self.wndUtility1, self)
    local name = self.utilityButtonTemplate:FindChild("Name")
    name:SetText("Recall")
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    currButton:SetContentId(GameLib.GetDefaultRecallCommand())
    --self.utilityButtonTemplate:SetData("CastRecall")
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(false)
    self.utilityButtons1[index] = self.utilityButtonTemplate
    self.recallButton1 = self.utilityButtonTemplate
    index = index + 1
  end
  if Options.utilityBars.bar1.bShowGadgetButton then
    --Gadget
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonTemplate", self.wndUtility1, self)
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    currButton:SetContentId(8)
    self.utilityButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding("CastGadgetAbility"))
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.utilityBars.bar1.bShowHotkeys)
    self.utilityButtonTemplate:SetData("CastGadgetAbility")
    self.utilityButtons1[index] = self.utilityButtonTemplate
    index = index + 1
  end
  if Options.utilityBars.bar1.bShowPathButton then
    --Path
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonPath", self.wndUtility1, self)
    local name = self.utilityButtonTemplate:FindChild("Name")
    name:SetText("Path")
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    --currButton:SetContentId(9)
    self.utilityButtonTemplate:SetData("CastPathAbility")
    self.utilityButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding("CastPathAbility"))
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.utilityBars.bar1.bShowHotkeys)
    self.utilityButtons1[index] = self.utilityButtonTemplate
    index = index + 1
  end
  if Options.utilityBars.bar1.bShowPotionButton then
    --Potion
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonInnate", self.wndUtility1, self)
    local name = self.utilityButtonTemplate:FindChild("Name")
    name:SetText("Potion")
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    currButton:SetContentId(27)
    self.utilityButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding("UsePotion"))
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.utilityBars.bar1.bShowHotkeys)
    self.utilityButtonTemplate:SetData("UsePotion")
    self.utilityButtons1[index] = self.utilityButtonTemplate
    index = index + 1
  end
end

function CandyBars:InitializeUtilityBar2(self)
  local Options = self.db.profile

  self.wndUtility2:Show(Options.utilityBars.bar2.bShowBar)

  self.utilityButtons2 = {}
  self.recallButton2 = nil
  --Clear children
  self.wndUtility2:DestroyChildren()

  --=====Bar 2=====--
  local index = 1
  if Options.utilityBars.bar2.bShowMountButton then
    --Print("mount")
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonInnate", self.wndUtility2, self)
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    --Mount
    local name = self.utilityButtonTemplate:FindChild("Name")
    name:SetText("Mount")
    currButton:SetContentId(26)
    self.utilityButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding("Mount"))
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.utilityBars.bar2.bShowHotkeys)
    self.utilityButtonTemplate:SetData("Mount")
    self.utilityButtons2[index] = self.utilityButtonTemplate
    index = index + 1
  end
  if Options.utilityBars.bar2.bShowRecallButton then
    --Recall
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonInnate", self.wndUtility2, self)
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    local name = self.utilityButtonTemplate:FindChild("Name")
    name:SetText("Recall")
    currButton:SetContentId(GameLib.GetDefaultRecallCommand())
    --self.utilityButtonTemplate:SetData("CastRecall")
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(false)
    self.utilityButtons2[index] = self.utilityButtonTemplate
    self.recallButton2 = self.utilityButtonTemplate
    index = index + 1
  end
  if Options.utilityBars.bar2.bShowGadgetButton then
    --Gadget
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonTemplate", self.wndUtility2, self)
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    currButton:SetContentId(8)
    self.utilityButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding("CastGadgetAbility"))
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.utilityBars.bar2.bShowHotkeys)
    self.utilityButtonTemplate:SetData("CastGadgetAbility")
    self.utilityButtons2[index] = self.utilityButtonTemplate
    index = index + 1
  end
  if Options.utilityBars.bar2.bShowPathButton then
    --Path
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonPath", self.wndUtility2, self)
    local name = self.utilityButtonTemplate:FindChild("Name")
    name:SetText("Path")
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    --currButton:SetContentId(9)
    self.utilityButtonTemplate:SetData("CastPathAbility")
    self.utilityButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding("CastPathAbility"))
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.utilityBars.bar2.bShowHotkeys)
    self.utilityButtons2[index] = self.utilityButtonTemplate
    index = index + 1
  end
  if Options.utilityBars.bar2.bShowPotionButton then
    --Potion
    self.utilityButtonTemplate = Apollo.LoadForm(self.xmlDoc, "ActionButtonInnate", self.wndUtility2, self)
    local currButton = self.utilityButtonTemplate:FindChild("ActionButtonNew")
    local name = self.utilityButtonTemplate:FindChild("Name")
    name:SetText("Potion")
    currButton:SetContentId(27)
    self.utilityButtonTemplate:FindChild("Hotkey"):SetText(GameLib.GetKeyBinding("UsePotion"))
    self.utilityButtonTemplate:FindChild("Hotkey"):Show(self.db.profile.utilityBars.bar2.bShowHotkeys)
    self.utilityButtonTemplate:SetData("UsePotion")
    self.utilityButtons2[index] = self.utilityButtonTemplate
    index = index + 1
  end
end

function CandyBars:ArrangeUtilityBar1(self)

  if not self.db.profile.utilityBars.bar1.bShowBar then
    return
  end

  local Options = self.db.profile
  local nCols = Options.utilityBars.bar1.nCols
  local nRows = math.ceil(#self.utilityButtons1 / nCols)
  local nSize = Options.utilityBars.bar1.nSize

  local mLeft, mTop, mRight, mBottom = self.wndUtility1:GetAnchorOffsets()

  mRight = mLeft + (nCols * nSize) + ((nCols-1) * self.db.profile.utilityBars.bar1.nPadding) + 20
  mBottom = mTop + (nRows * nSize) + ((nRows-1) * self.db.profile.utilityBars.bar1.nPadding) + 20

  self.wndUtility1:SetAnchorOffsets(mLeft, mTop, mRight, mBottom)

  --Set Index
  local index = 1

  --Loop through Action Button grid
  for rows=1, nRows do
    for cols=1, nCols do
      if true then
        --Button Offsets
        local nLeft, nTop, nRight, nBottom = 0, 0, 0, 0
        nLeft = (cols - 1) * (nSize + self.db.profile.utilityBars.bar1.nPadding) + 10
        nTop = (rows - 1) * (nSize + self.db.profile.utilityBars.bar1.nPadding) + 10
        nRight = nLeft + nSize
        nBottom = nTop + nSize
        --Set Button Offsets
        self.utilityButtons1[index]:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
      end
      --Escape
      if index < #self.utilityButtons1 then
        index = index + 1
      else
        break
      end
    end
  end
end

function CandyBars:ArrangeUtilityBar2(self)

  if not self.db.profile.utilityBars.bar2.bShowBar then
    return
  end

  local Options = self.db.profile
  local nCols = Options.utilityBars.bar2.nCols
  local nRows = math.ceil(#self.utilityButtons2 / nCols)
  local nSize = Options.utilityBars.bar2.nSize
  local mLeft, mTop, mRight, mBottom = self.wndUtility2:GetAnchorOffsets()

  mRight = mLeft + (nCols * nSize) + ((nCols-1) * self.db.profile.utilityBars.bar2.nPadding) + 20
  mBottom = mTop + (nRows * nSize) + ((nRows-1) * self.db.profile.utilityBars.bar2.nPadding) + 20

  self.wndUtility2:SetAnchorOffsets(mLeft, mTop, mRight, mBottom)

  --Set Index
  local index = 1

  --Loop through Action Button grid
  for rows=1, nRows do
    for cols=1, nCols do
      if true then
        --Button Offsets
        local nLeft, nTop, nRight, nBottom = 0, 0, 0, 0
        nLeft = (cols - 1) * (nSize + self.db.profile.utilityBars.bar2.nPadding) + 10
        nTop = (rows - 1) * (nSize + self.db.profile.utilityBars.bar2.nPadding) + 10
        nRight = nLeft + nSize
        nBottom = nTop + nSize
        --Set Button Offsets
        self.utilityButtons2[index]:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
      end
      --Escape
      if index < #self.utilityButtons2 then
        index = index + 1
      else
        break
      end
    end
  end
end

function CandyBars:ShowVehicleBar(nWhichBar, bIsVisible, nNumShortcuts)

  --Print(nWhichBar)
  --Print(tostring(bIsVisible))
  --Print(nNumShortcuts)

  if nWhichBar ~= 0 or not self.db.profile.vehicleBar.bEnableBar then
    return
  end

  local wndVehicleBar = self.wndVehicleBar
  wndVehicleBar:Show(bIsVisible)

  --self.wndMain:FindChild("StanceFlyout"):Show(not bIsVisible)
  --self.wndMain:FindChild("bEnableBarButtonSmallContainer"):Show(not bIsVisible)

  self.wndMain:Show(self.db.profile.actionBar.bShowBar and not bIsVisible)
  --
  if bIsVisible then
    for idx = 1, 6 do
      wndVehicleBar:FindChild("ActionBarShortcutContainer" .. idx):Show(false)
    end

    if nNumShortcuts then
      for idx = 1, nNumShortcuts do
        wndVehicleBar:FindChild("ActionBarShortcutContainer" .. idx):Show(true)
        wndVehicleBar:FindChild("ActionBarShortcutContainer" .. idx):FindChild("ActionBarShortcut." .. idx):Enable(true)
      end

      local nLeft, nTop ,nRight, nBottom = wndVehicleBar:GetAnchorOffsets() -- TODO SUPER HARDCODED FORMATTING
      --wndVehicleBar:SetAnchorOffsets(nLeft, nTop, nLeft + (35 * nNumShortcuts) + 66, nBottom)
    end

    wndVehicleBar:ArrangeChildrenHorz(1)
    wndVehicleBar:FindChild("ActionBarShortcut.Dismount"):Show(GameLib:CanDisembarkVehicle())
  end

end
---------------------------------------------------------------------------------------------------
-- ActionButtonTemplate Functions
------------------------------------------------------------------------------------------- -------



function CandyBars:OnGenerateTooltip(wndControl, wndHandler, eType, arg1, arg2)
  local xml = nil
  if self.db.profile.general.bShowTooltips then
    if eType == Tooltip.TooltipGenerateType_ItemInstance then -- Doesn't need to compare to item equipped
    Tooltip.GetItemTooltipForm(self, wndControl, arg1, {})
    elseif eType == Tooltip.TooltipGenerateType_ItemData then -- Doesn't need to compare to item equipped
    Tooltip.GetItemTooltipForm(self, wndControl, arg1, {})
    elseif eType == Tooltip.TooltipGenerateType_GameCommand then
      xml = XmlDoc.new()
      xml:AddLine(arg2)
      wndControl:SetTooltipDoc(xml)
    elseif eType == Tooltip.TooltipGenerateType_Macro then
      xml = XmlDoc.new()
      xml:AddLine(arg1)
      wndControl:SetTooltipDoc(xml)
    elseif eType == Tooltip.TooltipGenerateType_Spell then
      if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
        Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
      end
    elseif eType == Tooltip.TooltipGenerateType_PetCommand then
      xml = XmlDoc.new()
      xml:AddLine(arg2)
      wndControl:SetTooltipDoc(xml)
    end
  end
end



---------------------------------------------------------------------------------------------------
-- Flyout Menu Functions
---------------------------------------------------------------------------------------------------

function CandyBars:ShowPotionFlyout(self, button)
  --[[
    if self.unitPlayer == nil then
      return
    end
    ]]
  local wndPotionPopout = button:GetParent():FindChild("PopoutList")
  wndPotionPopout:DestroyChildren()

  local wndPotionFlyout
  --if self.nSelectedPotion then
  wndPotionFlyout = wndPotionPopout:GetParent()
  --[[else
    wndPotionFlyout = button:GetParent():FindChild("PopoutFrame")
  end
  ]]
  local tItemList = GameLib.GetPlayerUnit():GetInventoryItems() or {}
  local tSelectedPotion = nil
  local tFirstPotion = nil
  local tPotions = { }
  --self.nSelectedPotion = self.nSelectedPotion or self.db.profile.flyoutButtons.nSavedPotion

  for idx, tItemData in pairs(tItemList) do
    if tItemData and tItemData.itemInBag and tItemData.itemInBag:GetItemCategory() == 48 then
      local tItem = tItemData.itemInBag

      if tFirstPotion == nil then
        tFirstPotion = tItem
      end

      if tItem:GetItemId() == self.db.profile.flyoutButtons.nSavedPotion then
        tSelectedPotion = tItem
      end

      if tPotions[tItem:GetItemId()] == nil then
        tPotions[tItem:GetItemId()] = {}
        tPotions[tItem:GetItemId()].itemObject=tItem
        tPotions[tItem:GetItemId()].nCount=tItem:GetStackCount()
      else
        tPotions[tItem:GetItemId()].nCount = tPotions[tItem:GetItemId()].nCount + tItem:GetStackCount()
      end
    end
  end

  for idx, tData  in pairs(tPotions) do
    local wndCurr = Apollo.LoadForm(self.xmlDoc, "PotionButtonTemplate", wndPotionPopout, self)
    wndCurr:FindChild("PotionBtnIcon"):SetSprite(tData.itemObject:GetIcon())
    if (tData.nCount > 1) then wndCurr:FindChild("PotionBtnStackCount"):SetText(tData.nCount) end
    wndCurr:SetData(tData.itemObject)

    if Tooltip then
      wndCurr:SetTooltipDoc(nil)
      Tooltip.GetItemTooltipForm(self, wndCurr, tData.itemObject, {})
    end
  end

  if tSelectedPotion == nil and tFirstPotion ~= nil then
    tSelectedPotion = tFirstPotion
  end

  if tSelectedPotion ~= nil then
    GameLib.SetShortcutPotion(tSelectedPotion:GetItemId())
  end

  local nCount = #wndPotionPopout:GetChildren()
  if nCount > 0 then
    local nMax = 7
    local nMaxHeight = (wndPotionPopout:ArrangeChildrenVert(0) / nCount) * nMax
    local nHeight = wndPotionPopout:ArrangeChildrenVert(0)

    nHeight = nHeight <= nMaxHeight and nHeight or nMaxHeight

    local nLeft, nTop, nRight, nBottom = wndPotionFlyout:GetAnchorOffsets()

    wndPotionFlyout:SetAnchorOffsets(nLeft, nBottom - nHeight - 98, nRight, nBottom)
  end

  wndPotionFlyout:Show(nCount > 0)
  wndPotionFlyout:ToFront()
end

function CandyBars:OnPotionBtn(wndHandler, wndControl)
  self.db.profile.flyoutButtons.nSavedPotion = wndControl:GetData():GetItemId()
  GameLib.SetShortcutPotion(wndControl:GetData():GetItemId())
  wndControl:GetParent():GetParent():Show(false)
end

function CandyBars:ShowRecallFlyout(self, button)
  local wndMenu = button:GetParent():FindChild("PopoutFrame")
  local wndList = button:GetParent():FindChild("PopoutList")
  wndList:DestroyChildren()
  local nWndLeft, nWndTop, nWndRight, nWndBottom = wndMenu:GetAnchorOffsets()
  local nEntryHeight = 0
  local bHasBinds = false
  local bHasWarplot = false
  local guildCurr = nil

  if GameLib.HasBindPoint() == true then
    --load recall
    --local wndBind = Apollo.LoadForm(self.xmlDoc, "RecallEntry", wndList, self)
    --wndBind:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.BindPoint)
    local wndBind = Apollo.LoadForm(self.xmlDoc, "RecallButtonTemplate", wndList, self)
    wndBind:FindChild("RecallBtnIcon"):SetSprite("IconSprites:Icon_SkillMisc_UI_recall_transmat")
    wndBind:SetData(GameLib.CodeEnumRecallCommand.BindPoint)

    if Tooltip and Tooltip.GetSpellTooltipForm then
      local xml = XmlDoc.new()
      xml:AddLine("Recall - Transmat")
      wndBind:SetTooltipDoc(xml)
    end

    bHasBinds = true
    local nLeft, nTop, nRight, nBottom = wndBind:GetAnchorOffsets()
    nEntryHeight = nEntryHeight + (nBottom - nTop)
  end

  if HousingLib.IsResidenceOwner() == true then
    local wndSpace = Apollo.LoadForm(self.xmlDoc, "EmptySpace", wndList, self)
    local nSpaceLeft, nSpaceTop, nSpaceRight, nSpaceBottom = wndSpace:GetAnchorOffsets()
    nEntryHeight = nEntryHeight + (nSpaceBottom - nSpaceTop)

    -- load house
    --local wndHouse = Apollo.LoadForm(self.xmlDoc, "RecallEntry", wndList, self)
    --wndHouse:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.House)
    local wndHouse = Apollo.LoadForm(self.xmlDoc, "RecallButtonTemplate", wndList, self)
    wndHouse:FindChild("RecallBtnIcon"):SetSprite("IconSprites:Icon_SkillMisc_UI_recall_housing")
    wndHouse:SetData(GameLib.CodeEnumRecallCommand.House)

    if Tooltip and Tooltip.GetSpellTooltipForm then
      local xml = XmlDoc.new()
      xml:AddLine("Recall - House")
      wndHouse:SetTooltipDoc(xml)
    end

    bHasBinds = true
    local nLeft, nTop, nRight, nBottom = wndHouse:GetAnchorOffsets()
    nEntryHeight = nEntryHeight + (nBottom - nTop)
  end

  for key, guildCurr in pairs(GuildLib.GetGuilds()) do
    if guildCurr:GetType() == GuildLib.GuildType_WarParty then
      bHasWarplot = true
      break
    end
  end

  if bHasWarplot == true then
    local wndSpace = Apollo.LoadForm(self.xmlDoc, "EmptySpace", wndList, self)
    local nSpaceLeft, nSpaceTop, nSpaceRight, nSpaceBottom = wndSpace:GetAnchorOffsets()
    nEntryHeight = nEntryHeight + (nSpaceBottom - nSpaceTop)

    -- load warplot
    --local wndWarplot = Apollo.LoadForm(self.xmlDoc, "RecallEntry", wndList, self)
    --wndWarplot:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Warplot)
    local wndWarplot = Apollo.LoadForm(self.xmlDoc, "RecallButtonTemplate", wndList, self)
    wndWarplot:FindChild("RecallBtnIcon"):SetSprite("IconSprites:Icon_SkillMisc_Warplot_Recall")
    wndWarplot:SetData(GameLib.CodeEnumRecallCommand.Warplot)

    if Tooltip and Tooltip.GetSpellTooltipForm then
      local xml = XmlDoc.new()
      xml:AddLine("Recall - Warplot")
      wndWarplot:SetTooltipDoc(xml)
    end


    bHasBinds = true
    local nLeft, nTop, nRight, nBottom = wndWarplot:GetAnchorOffsets()
    nEntryHeight = nEntryHeight + (nBottom - nTop)
  end

  local bIllium = false
  local bThayd = false

  for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
    if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportIlliumSpell():GetBaseSpellId() then
      bIllium = true
    end
    if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportThaydSpell():GetBaseSpellId() then
      bThayd = true
    end
  end

  if bIllium then
    local wndSpace = Apollo.LoadForm(self.xmlDoc, "EmptySpace", wndList, self)
    local nSpaceLeft, nSpaceTop, nSpaceRight, nSpaceBottom = wndSpace:GetAnchorOffsets()
    nEntryHeight = nEntryHeight + (nSpaceBottom - nSpaceTop)

    -- load capital
    --local wndWarplot = Apollo.LoadForm(self.xmlDoc, "RecallEntry", wndList, self)
    --wndWarplot:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Illium)
    local wndWarplot = Apollo.LoadForm(self.xmlDoc, "RecallButtonTemplate", wndList, self)
    wndWarplot:FindChild("RecallBtnIcon"):SetSprite("IconSprites:Icon_SkillMisc_Scientist_CreatePortal_HomeCity_Illium")
    wndWarplot:SetData(GameLib.CodeEnumRecallCommand.Illium)

    if Tooltip and Tooltip.GetSpellTooltipForm then
      local xml = XmlDoc.new()
      xml:AddLine("Recall - Illium")
      wndWarplot:SetTooltipDoc(xml)
    end

    bHasBinds = true
    local nLeft, nTop, nRight, nBottom = wndWarplot:GetAnchorOffsets()
    nEntryHeight = nEntryHeight + (nBottom - nTop)
  end

  if bThayd then
    local wndSpace = Apollo.LoadForm(self.xmlDoc, "EmptySpace", wndList, self)
    local nSpaceLeft, nSpaceTop, nSpaceRight, nSpaceBottom = wndSpace:GetAnchorOffsets()
    nEntryHeight = nEntryHeight + (nSpaceBottom - nSpaceTop)

    -- load capital
    --local wndWarplot = Apollo.LoadForm(self.xmlDoc, "RecallEntry", wndList, self)
    --wndWarplot:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Thayd)
    local wndWarplot = Apollo.LoadForm(self.xmlDoc, "RecallButtonTemplate", wndList, self)
    wndWarplot:FindChild("RecallBtnIcon"):SetSprite("IconSprites:Icon_SkillMisc_Scientist_CreatePortal_HomeCity_Thayd")
    wndWarplot:SetData(GameLib.CodeEnumRecallCommand.Thayd)

    if Tooltip and Tooltip.GetSpellTooltipForm then
      local xml = XmlDoc.new()
      xml:AddLine("Recall - Thayd")
      wndWarplot:SetTooltipDoc(xml)
    end

    bHasBinds = true
    local nLeft, nTop, nRight, nBottom = wndWarplot:GetAnchorOffsets()
    nEntryHeight = nEntryHeight + (nBottom - nTop)
  end

  if bHasBinds == true then
    wndList:SetText("")
    wndMenu:SetAnchorOffsets(nWndLeft, nWndBottom -(nEntryHeight + 48+48), nWndRight, nWndBottom)

    wndList:ArrangeChildrenVert()
  end

  wndMenu:Show(true)
  wndMenu:ToFront()
end
function CandyBars:RedrawSelectedMounts()
  if self.db.profile.flyoutButtons.nSavedMount then
    GameLib.SetShortcutMount(self.db.profile.flyoutButtons.nSavedMount)
  end
end

function CandyBars:ShowMountFlyout(self, button)
  local wndPopoutFrame = button:GetParent():FindChild("PopoutFrame")
  local wndMountPopout = button:GetParent():FindChild("PopoutList")

  wndMountPopout:DestroyChildren()

  local tMountList = AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Mount) or {}
  local tSelectedSpellObj = nil

  -- Loop over all the Mounts the game has given us.
  for idx, tMountData  in pairs(tMountList) do
    -- We only care about those active. If the boolean is false,
    -- it means th given spell is not active, thus not of use for
    -- for the current character.
    if tMountData.bIsActive then
      local tSpellObject = tMountData.tTiers[1].splObject

      if tSpellObject:GetId() == self.nSelectedMount then
        tSelectedSpellObj = tSpellObject
      end

      local wndCurr = Apollo.LoadForm(self.xmlDoc, "MountButtonTemplate", wndMountPopout, self)
      wndCurr:FindChild("MountBtnIcon"):SetSprite(tSpellObject:GetIcon())
      wndCurr:SetData(tSpellObject)

      if Tooltip and Tooltip.GetSpellTooltipForm then
        wndCurr:SetTooltipDoc(nil)
        Tooltip.GetSpellTooltipForm(self, wndCurr, tSpellObject, {})
      end
    end
  end

  local nCount = #wndMountPopout:GetChildren()

  if nCount > 0 then
    local nMax = 7
    local nMaxHeight = (wndMountPopout:ArrangeChildrenVert(0) / nCount) * nMax
    local nHeight = wndMountPopout:ArrangeChildrenVert(0)
    local nLeft, nTop, nRight, nBottom = wndPopoutFrame:GetAnchorOffsets()

    nHeight = nHeight <= nMaxHeight and nHeight or nMaxHeight

    wndPopoutFrame:SetAnchorOffsets(nLeft, nBottom - nHeight - 98, nRight, nBottom)
    wndPopoutFrame:Show(true)
  else
    wndPopoutFrame:Show(false)
  end

  wndPopoutFrame:ToFront()
end

function CandyBars:OnMountBtn(wndHandler, wndControl)
  --self.nSelectedMount = wndControl:GetData():GetId()
  self.db.profile.flyoutButtons.nSavedMount = wndControl:GetData():GetId()
  GameLib.SetShortcutMount(self.db.profile.flyoutButtons.nSavedMount)
  wndControl:GetParent():GetParent():Show(false)
  --self:RedrawSelectedMounts()
end

function CandyBars:ShowInnateFlyout(self, button)
  --[[
    if self.unitPlayer == nil then
      return
    end
    ]]
  --local wndPopoutFrame = button:GetParent():FindChild("PopoutFrame")
  --local wndMountPopout = button:GetParent():FindChild("PopoutList")

  local wndStancePopout = button:GetParent():FindChild("PopoutList")
  wndStancePopout:DestroyChildren()
  local wndPopoutFrame --err nil
  --[[
  if button:GetName() == "InnateButtonTemplate" then
    wndPopoutFrame = wndStancePopout:GetParent()
    wndPopoutFrame:Show(false)
    return
  else
  ]]
  wndPopoutFrame = button:GetParent():FindChild("PopoutFrame")
  --end

  local spellIndex = 0
  for idx, spellObject in pairs(GameLib.GetClassInnateAbilitySpells().tSpells) do
    if idx % 2 == 1 then
      spellIndex = spellIndex + 1
      local strKeyBinding = GameLib.GetKeyBinding("SetStance"..spellIndex) -- hardcoded formatting
      local wndCurr = Apollo.LoadForm(self.xmlDoc, "InnateButtonTemplate", wndStancePopout, self)
      wndCurr:FindChild("StanceBtnKeyBind"):SetText(strKeyBinding == "<Unbound>" and "" or strKeyBinding)
      wndCurr:FindChild("StanceBtnIcon"):SetSprite(spellObject:GetIcon())
      wndCurr:SetData(spellIndex)
      if Tooltip and Tooltip.GetSpellTooltipForm then
        wndCurr:SetTooltipDoc(nil)
        Tooltip.GetSpellTooltipForm(self, wndCurr, spellObject)
      end
    end
  end

  local nHeight = wndStancePopout:ArrangeChildrenVert(0)
  local nLeft, nTop, nRight, nBottom = wndPopoutFrame:GetAnchorOffsets()
  wndPopoutFrame:SetAnchorOffsets(nLeft, nBottom - nHeight - 98, nRight, nBottom)
  wndPopoutFrame:Show(spellIndex > 1)
  wndPopoutFrame:ToFront()
end

function CandyBars:OnStanceBtn(wndHandler, wndControl)
  GameLib.SetCurrentClassInnateAbilityIndex(wndControl:GetData())
  wndControl:GetParent():GetParent():Show(false)
end

function CandyBars:ShowPathFlyout(self, button)
  local wndPopoutList = button:GetParent():FindChild("PopoutList")
  local wndPopoutFrame = button:GetParent():FindChild("PopoutFrame")
  wndPopoutList:DestroyChildren()
  --[[
  for k, v in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Path)[1]) do
    Print(k)
  end
  ]]
  local tPathAbilities = AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Path)
  local spellIndex = 0
  for idx, tPathAbility in pairs(tPathAbilities) do
    --Print(tPathAbility.strName.." - Tier: "..tPathAbility.nCurrentTier)
    if tPathAbility.nCurrentTier > 0 then
      spellIndex = spellIndex + 1
      local wndCurr = Apollo.LoadForm(self.xmlDoc, "PathButtonTemplate", wndPopoutList, self)
      local tSpellObject = tPathAbility.tTiers[tPathAbility.nCurrentTier].splObject
      wndCurr:FindChild("PathBtnIcon"):SetSprite(tSpellObject:GetIcon())
      wndCurr:SetData(tPathAbility.nId)
      if Tooltip and Tooltip.GetSpellTooltipForm then
        wndCurr:SetTooltipDoc(nil)
        Tooltip.GetSpellTooltipForm(self, wndCurr, tSpellObject)
      end
    end
  end
  local nHeight = wndPopoutList:ArrangeChildrenVert(0)
  local nLeft, nTop, nRight, nBottom = wndPopoutFrame:GetAnchorOffsets()
  wndPopoutFrame:SetAnchorOffsets(nLeft, nBottom - nHeight - 98, nRight, nBottom)
  wndPopoutFrame:Show(true)
  wndPopoutFrame:ToFront()
end

function CandyBars:OnPathBtn( wndHandler, wndControl, eMouseButton )
  wndControl:GetParent():GetParent():Show(false)
  local tActionSet = ActionSetLib.GetCurrentActionSet()
  tActionSet[10] = wndControl:GetData()
  --tActionSet[9] = self.db.profile.flyoutButtons.nSavedMount
  ActionSetLib.RequestActionSetChanges(tActionSet)
  --GameLib.SetShortcutMount(self.db.profile.flyoutButtons.nSavedMount)
  --self.timerMountReset:Start()
end

function CandyBars:OnTimerMountReset()
  if self.db.profile.flyoutButtons.nSavedMount and self.db.profile.flyoutButtons.nSavedMount ~= GameLib.GetShortcutMount() then
    GameLib.SetShortcutMount(self.db.profile.flyoutButtons.nSavedMount)
  end
end

function CandyBars:OnInnateShowFlyoutClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
  if eMouseButton == 1 then
    local type = wndControl:GetParent():FindChild("Name"):GetText()
    if type == "Potion" then
      CandyBars:ShowPotionFlyout(self, wndControl)
    elseif type == "Innate" then
      CandyBars:ShowInnateFlyout(self, wndControl)
    elseif type == "Recall" then
      CandyBars:ShowRecallFlyout(self, wndControl)
    elseif type == "Mount" then
      self:ShowMountFlyout(self, wndControl)
    elseif type == "Path" then
      self:ShowPathFlyout(self, wndControl)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- RecallEntry Functions
---------------------------------------------------------------------------------------------------

function CandyBars:OnRecallBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
  self.db.profile.flyoutButtons.nSavedRecall = wndControl:GetData()
  wndControl:GetParent():GetParent():Show(false)
  GameLib.SetDefaultRecallCommand(wndControl:GetData())
  if self.recallButton1 and self.db.profile.flyoutButtons.nSavedRecall then
    self.recallButton1:FindChild("ActionButtonNew"):SetContentId(self.db.profile.flyoutButtons.nSavedRecall)
  end
  if self.recallButton2 and self.db.profile.flyoutButtons.nSavedRecall then
    self.recallButton2:FindChild("ActionButtonNew"):SetContentId(self.db.profile.flyoutButtons.nSavedRecall)
  end
end


---------------------------------------------------------------------------------------------------
-- OptionsDialogue Functions
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
-- DropdownItem Functions
---------------------------------------------------------------------------------------------------

function CandyBars:OnColorItemClick( wndHandler, wndControl, eMouseButton )
  self.wndColorDropdown:SetText(wndControl:GetText())

  -- set boder color here
  self.db.profile.border.sBorderColor = wndControl:GetText()


  --Set up bars
  --Action Bar
  CandyBars:InitializeBar(self)
  CandyBars:ArrangeBar(self)
  --Innate Bar
  CandyBars:InitializeInnateBar(self)
  CandyBars:ArrangeInnateBar(self)
  --Secondary Bar
  CandyBars:InitializeSecondaryBar(self)
  CandyBars:ArrangeSecondaryBar(self)
  --Utility Bar
  CandyBars:InitializeUtilityBar1(self)
  CandyBars:InitializeUtilityBar2(self)
  CandyBars:ArrangeUtilityBar1(self)
  CandyBars:ArrangeUtilityBar2(self)

  self.wndColorDropdownBox:Show(false)
end


---------------------------------------------------------------------------------------------------
-- SpecSwitches Functions
---------------------------------------------------------------------------------------------------

function CandyBars:OnPrevSpecClick( wndHandler, wndControl, eMouseButton )
  AbilityBook.PrevSpec()
end

function CandyBars:OnNextSpecClick( wndHandler, wndControl, eMouseButton )
  AbilityBook.NextSpec()
end

function CandyBars:EnterKeybindMode(self)
  --Show Alert
  self.wndKeybindModeAlert:Show(true)
  self.wndKeybindModeAlert:SetFocus()

  --Hide Options
  self.wndOptionsNew:Show(false)

  --Set Mode
  self.bKeybindMode = true

  --Pause Gameplay Input
  GameLib.PauseGameActionInput(true)

  --Get Curr KeySet
  self.eCurrKeySet = GameLib.GetCurrInputKeySet()
  self.eOriginalKeySet = self.eCurrKeySet

  --Initialize
  self:ResetKeybindVars()
  self.arKeyBindings = GameLib.GetKeyBindings()
  self.nReservedModifier = self:GetSprintModifier()
  self.eKeybindingState = KeybindingState.AcceptingInput
  --[[
  EVENTS TO USE
  +KeyBindingKeyChanged
  +KeyBindingUpdated
  +KeyBindingReceived
  ]]
end

function CandyBars:ResetKeybindVars()
  self.eKeybindingState = KeybindingState.Idle

  self.wndCurrBind = nil
  self.wndCurrModifierBind = nil

  self.bNeedSave = false
  self.bNeedSaveSet = false
  self.bShowingYesNoDialog = false
end

function CandyBars:OnMouseButtonUp()
  if self.eKeybindingState == KeybindingState.AcceptingInput then
    self.wndKeybindModeAlert:SetFocus()
  end
end

function CandyBars:OnKeybindKeyDown(wndHandler, wndControl, strKeyName, nCode, eModifier)
  --Ignore Mods
  if not GameLib.IsKeyBindable(nCode, eModifier) then
    return false
  end

  --Look for target
  local wndTarget = Apollo.GetMouseTargetWindow()
  if wndTarget == nil then
    return false
  end

  local strAction = wndTarget:GetParent()

  if strAction then
    strAction = strAction:GetData()
  else
    return false
  end

  if strAction == nil or strAction == "" or type(strAction) ~= "string" then
    return false
  end

  local auth = wndTarget:GetParent():FindChild("Auth") or false

  if not auth then
    return false
  end

  --In Keybind Mode
  if self.eKeybindingState == KeybindingState.AcceptingInput then
    -- Check for used mods
    local nModKey
    if eModifier == GameLib.CodeEnumInputModifierScancode.LeftShift then
      nModKey = GameLib.CodeEnumInputModifier.Shift
    elseif eModifier == GameLib.CodeEnumInputModifierScancode.LeftCtrl then
      nModKey = GameLib.CodeEnumInputModifier.Control
    elseif eModifier == GameLib.CodeEnumInputModifierScancode.LeftAlt then
      nModKey = GameLib.CodeEnumInputModifier.Alt
    else
      nModKey = 0
    end
    --Print(self:GetSprintModifier())
    if self:IsSprintModifier(eModifier) then
      Print(String_GetWeaselString(Apollo.GetString("Keybinding_ReservedForSprint"), nModKey))
      return false
    end

    --Check if bound already
    --Print(tostring(self:CheckIfBound(nCode, eModifier)))
    if self:CheckIfBound(nCode, eModifier) then
      --Unbind Button
      local strOldAction = self:GetBindAction(nCode, eModifier)
      self:UnbindButton(nCode, eModifier)
      self:ShowKeybindInfo(strOldAction)
    end

    --Set Hotkey Text
    --wndTarget:GetParent():FindChild("Hotkey"):SetText(strKeyName)

    self:SetKeybind(strAction, nCode, eModifier)

    --Set Binds - Maybe do on exit? - But then dont ket hotkey updates
    GameLib.SetKeyBindings(self.arKeyBindings)
    self:UpdateHotkeyText(self)
  end
end

function CandyBars:UpdateHotkeyText(self)
  --action bar
  if self.actionButtons then
    for i, wnd in ipairs(self.actionButtons) do
      --Print(tostring(wnd:GetData()))
      if wnd:FindChild("Hotkey") and wnd:GetData() then
        local strKey = GameLib.GetKeyBinding(wnd:GetData())
        --strKey = strKey and strKey ~= "Error !" or ""
        wnd:FindChild("Hotkey"):SetText(strKey)
      end
    end
  end
  --innate
  if self.innateButtons then
    for i, wnd in ipairs(self.innateButtons) do
      if wnd:FindChild("Hotkey") and wnd:GetData() then
        local strKey = GameLib.GetKeyBinding(wnd:GetData())
        --strKey = strKey and strKey ~= "Error !" or ""
        wnd:FindChild("Hotkey"):SetText(strKey)
      end
    end
  end

  --sec
  if self.secondaryButtons then
    for i, wnd in ipairs(self.secondaryButtons) do
      if wnd:FindChild("Hotkey") and wnd:GetData() then
        local strKey = GameLib.GetKeyBinding(wnd:GetData())
        --strKey = strKey and strKey ~= "Error !" or ""
        wnd:FindChild("Hotkey"):SetText(strKey)
      end
    end
  end
  --ut1
  if self.utilityButtons1 then
    for i, wnd in ipairs(self.utilityButtons1) do
      if wnd:FindChild("Hotkey") and wnd:GetData() then
        local strKey = GameLib.GetKeyBinding(wnd:GetData())
        --strKey = strKey and strKey ~= "Error !" or ""
        wnd:FindChild("Hotkey"):SetText(strKey)
      end
    end
  end
  --ut2
  if self.utilityButtons2 then
    for i, wnd in ipairs(self.utilityButtons2) do
      if wnd:FindChild("Hotkey") and wnd:GetData() then
        local strKey = GameLib.GetKeyBinding(wnd:GetData())
        --strKey = strKey and strKey ~= "Error !" or ""
        wnd:FindChild("Hotkey"):SetText(strKey)
      end
    end
  end
end

function CandyBars:SetKeybind(strAction, nCode, eModifier)
  for idx, tKeybind in ipairs(self.arKeyBindings) do
    if tKeybind.strAction == strAction then
      self.arKeyBindings[idx].arInputs[1].eDevice = GameLib.CodeEnumInputDevice.Keyboard
      self.arKeyBindings[idx].arInputs[1].nCode = nCode
      self.arKeyBindings[idx].arInputs[1].eModifier = eModifier
    end
  end
end

function CandyBars:CheckIfBound(nCode, eModifier)
  for idx, tKeybind in ipairs(self.arKeyBindings) do
    if tKeybind.arInputs[1].nCode == nCode and tKeybind.arInputs[1].eModifier == eModifier then
      return true
    end
  end
  return false
end

function CandyBars:GetBindAction(nCode, eModifier)
  for idx, tKeybind in ipairs(self.arKeyBindings) do
    if tKeybind.arInputs[1].eDevice == GameLib.CodeEnumInputDevice.Keyboard and tKeybind.arInputs[1].nCode == nCode and tKeybind.arInputs[1].eModifier == eModifier then
      return tKeybind.strActionLocalized
    end
  end
  return nil
end

function CandyBars:UnbindButton(nCode, eModifier)
  for idx, tKeybind in ipairs(self.arKeyBindings) do
    if tKeybind.arInputs[1].eDevice == GameLib.CodeEnumInputDevice.Keyboard and tKeybind.arInputs[1].nCode == nCode and tKeybind.arInputs[1].eModifier == eModifier then
      --self.arKeyBindings[idk].arInputs[1].eDevice = 0
      self.arKeyBindings[idx].arInputs[1].nCode = 0
      self.arKeyBindings[idx].arInputs[1].eModifier = 0
    end
  end
end

function CandyBars:ShowKeybindInfo(strOldAction)
  local wndText = self.wndKeybindInfo:FindChild("Text")

  --wndText:SetText("\""..strKey.."\" was already bound and has been unbound and bound to the new action.")
  --or? - Figure out which one is better
  strOldAction = strOldAction or ""
  wndText:SetText("\""..strOldAction.."\" has been unbound.")

  self.wndKeybindInfo:Show(true)
  self.timerKeybindInfo:Start()
end

function CandyBars:OnTimerKeybindInfo()
  self.wndKeybindInfo:Show(false)
end

function CandyBars:IsSprintModifier(nModifierScancode)
  if self:GetSprintModifier() == nModifierScancode then
    return true
  end
  return false
end

function CandyBars:GetSprintModifier()
  for idx, tKeybind in ipairs(self.arKeyBindings) do
    if tKeybind.strAction == "SprintModifier" then
      return self:GetModifierFlag(tKeybind.arInputs[1].nCode)
    end
  end
end

function CandyBars:GetModifierFlag(nModifierScancode)
  if nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftShift then
    return GameLib.CodeEnumInputModifier.Shift
  elseif nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftCtrl then
    return GameLib.CodeEnumInputModifier.Control
  elseif nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftAlt then
    return GameLib.CodeEnumInputModifier.Alt
  else
    return 0
  end
end

function CandyBars:ExitKeybindMode( wndHandler, wndControl, eMouseButton )
  --Hide Alert
  self.wndKeybindModeAlert:Show(false)

  --Hide Mode
  self.bKeybindMode = false

  --Unpause
  GameLib.PauseGameActionInput(false)

end

function CandyBars:OnCBOptionsButtonClick( wndHandler, wndControl, eMouseButton )
  --=========================================
  --					FOR CUI
  --=========================================
  Apollo.ParseInput("/cb")
  Event_FireGenericEvent("CandyUI_CloseOptions")
end

---------------------------------------------------------------------------------------------------
-- OptionsControls Functions
---------------------------------------------------------------------------------------------------
--GameLib.GetKeyBinding() --input str like "LimitedActionSet1"
--Apollo.GetMouseTargetWindow():GetName()
--This Gets Keybind
--GameLib.GetKeyBinding(Apollo.GetMouseTargetWindow():GetName()) 
--[[
for k, v in pairs(GameLib.GetKeyBindings()) do 
	 if v["strAction"] == "LimitedActionSet1" then 
		 Print(k) 
	 end 
end
GameLib.key


]]


---------------------------------------------------------------------------------------------------
-- KeybindModeAlert Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- OptionsListItem Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- LayoutEditorListItem Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- ActionButtonDummy Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- OptionsControlsList Functions
---------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------
-- CandyBars Instance
-----------------------------------------------------------------------------------------------
local CandyBarsInst = CandyBars:new()
CandyBarsInst:Init()


--[[





NEIL!!!!!!!!!!!!!!

new window depth on the borders is messing with the flyouts!!!

also... show  empty slots still has them

Fix it!!!!





]]