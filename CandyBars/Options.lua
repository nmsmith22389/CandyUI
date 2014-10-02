--Options for CandyBars
local CandyBars = Apollo.GetAddon("CandyBars")

ktCBDefaults = {
	char = {
		currentProfile = nil,
		debug = false,
	},
	profile = {
		general = {
			bLockBars = false,
			bShowEmptySlots = true,
			bShowTooltips = true,
			bEnableShortcutBar = false,
			--nPadding = 0,
		},
		border = {
			sBorderColor = "Black",
		},
		actionBar = {
			bShowBar = true,
			nSize = 45,
			nCols = 3,
			fOpacity = 1,
			nPadding = 0,
			bShowInnate = false,
			bReverseOrder = false,
			bShowHotkeys = true,
			bShowCDBars = true,
			nButtons = 8,
			bShowSpecSwitch = true,
			strInCombat = "Do Nothing",
			tAnchorOffsets = {0, 0, 1, 1},
		},
		innateBar = {
			bShowBar = false,
			bShowHotkeys = true,
			nSize = 45,
			fOpacity = 1,
			tAnchorOffsets = {0, 0, 1, 1},
		},
		secondaryBar = {
			nSize = 45,
			nCols = 3,
			bShowBar = false,
			nButtons = 12,
			fOpacity = 1,
			nPadding = 0,
			bSplitBar = false,
			bShowHotkeys = true,
			tAnchorOffsets = {0, 0, 1, 1},
			tSplitAnchorOffsets = {0, 0, 1, 1},
		},
		vehicleBar = {
			bEnableBar = true,
			tAnchorOffsets = {620, 351, 900, 417}
		},
		utilityBars = {
			bar1 = {
				bShowBar = false,
				nSize = 45,
				nCols = 2,
				fOpacity = 1,
				nPadding = 0,
				--buttons
				bShowMountButton = true,
				bShowRecallButton = true,
				bShowGadgetButton = false,
				bShowPathButton = false,
				bShowPotionButton = false,
				bShowHotkeys = true,
				tAnchorOffsets = {0, 0, 1, 1},
			},
			bar2 = {
				bShowBar = false,
				nSize = 45,
				nCols = 3,
				fOpacity = 1,
				nPadding = 0,
				--buttons
				bShowMountButton = false,
				bShowRecallButton = false,
				bShowGadgetButton = true,
				bShowPathButton = true ,
				bShowPotionButton = true,
				bShowHotkeys = true,
				tAnchorOffsets = {0, 0, 1, 1},
			},
		},
		layoutEditor = {
			bEnabled = false,
			nRows = 3,
			nCols = 3,
			tActionBarLayout = {},
			
		},	
		shortcutBars = {
			tDefaultOffsets = {
				-183,
				146,
				217,
				228,
			},
		},
		flyoutButtons = {
			nSavedPotion = nil,
			nSavedRecall = nil,
			nSavedMount = nil,
			nSavedPath = nil,
			nSavedInnate = nil,
		},
			--Reset Anchors
			--[[
			tAnchorOffsets = {0, 0, 1, 1}
			tInnateAnchorOffsets = {0, 0, 1, 1}
			tSecondaryAnchorOffsets = {0, 0, 1, 1}
			tUtility1AnchorOffsets = {0, 0, 1, 1}
			tUtility2AnchorOffsets = {0, 0, 1, 1}
			tVehicleAnchorOffsets = {620, 351, 900, 417}
		]]
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
--%%%%%%%%%%%
--   Debug
--%%%%%%%%%%%
local function debug(strText)
	if CandyBars_Debug then
		ChatSystemLib.PostOnChannel( ChatSystemLib.ChatChannel_System, tostring(strText), "CandyBars Debug" )
	end
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
local function CreateDropdownMenu(self, wndDropdown, tOptions, strEventHandler)
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
end

local tInCombatOptions = {
	["Do Nothing"] = true,
	["Hide"] = true,
	["Show"] = true,
}

local tHUDOptions = {
	["Always On"] = 1,
	["Always Off"] = 2,
	["On While in Combat"] = 3,
	["Off While in Combat"] = 4,
}

-----------------------------------------------------------------------------------------------
-- Options
---------------------------------------------------------------------------------------------------
function CandyBars:SetOptions()
	local Options = self.db.profile
	
	--Opacity
	self:SetAllOpacities(self)
		
--General
	local mainControls = self.wndControls:FindChild("MainControls")
	--Lock Bars
	mainControls:FindChild("LockToggle"):SetCheck(Options.general.bLockBars)
	self:ToggleLockBars(self)
	--Hotkeys
	--mainControls:FindChild("HotkeyToggle")
	--Show Empty Slots
	mainControls:FindChild("EmptySlotToggle"):SetCheck(Options.general.bShowEmptySlots)
	self:ToggleShowEmptySlots(self)
	--Tooltip
	mainControls:FindChild("TooltipToggle"):SetCheck(Options.general.bShowTooltips)
	--vehicle bar
	--mainControls:FindChild("VehicleBarToggle"):SetCheck(Options.bEnableBar)
	--Padding
	--mainControls:FindChild("Padding"):FindChild("PaddingSliderBar"):SetValue(Options.general.nPadding)
	--mainControls:FindChild("Padding"):FindChild("PaddingEditBox"):SetText(Options.general.nPadding)
	--Shortcut Bars
	--mainControls:FindChild("ShortcutBarToggle"):SetCheck(Options.general.bEnableShortcutBar)
--Border
	local borderControls = ""
	--Show Borders
	
	--Border Color
	--self.wndColorDropdown:SetText(Options.border.sBorderColor)

--Action Bar
	local actionControls = self.wndControls:FindChild("ActionBarControls")
	--Show
	actionControls:FindChild("ActionBarToggle"):SetCheck(Options.actionBar.bShowBar)
	--Size
	actionControls:FindChild("Size"):FindChild("SizeSliderBar"):SetValue(Options.actionBar.nSize)
	actionControls:FindChild("Size"):FindChild("SizeEditBox"):SetText(Options.actionBar.nSize)
	--Columns
	actionControls:FindChild("Columns"):FindChild("ColumnsSliderBar"):SetValue(Options.actionBar.nCols)
	actionControls:FindChild("Columns"):FindChild("ColumnsEditBox"):SetText(Options.actionBar.nCols)
	--Opacity
	actionControls:FindChild("Opacity"):FindChild("OpacitySliderBar"):SetValue(Options.actionBar.fOpacity*10)
	actionControls:FindChild("Opacity"):FindChild("OpacityEditBox"):SetText(Options.actionBar.fOpacity*10)
	--Padding
	actionControls:FindChild("Padding"):FindChild("PaddingSliderBar"):SetValue(Options.actionBar.nPadding)
	actionControls:FindChild("Padding"):FindChild("PaddingEditBox"):SetText(Options.actionBar.nPadding)
	--Innate
	actionControls:FindChild("InnateToggle"):SetCheck(Options.actionBar.bShowInnate)
	--Reverse Order
	actionControls:FindChild("ReverseOrderToggle"):SetCheck(Options.actionBar.bReverseOrder)
	--Show Spec Switch
	actionControls:FindChild("ShowSpecSwitchToggle"):SetCheck(Options.actionBar.bShowSpecSwitch)
	--Show Hotkeys
	actionControls:FindChild("ShowHotkeysToggle"):SetCheck(Options.actionBar.bShowHotkeys)
	--Show cd bars
	actionControls:FindChild("ShowCDBarsToggle"):SetCheck(Options.actionBar.bShowCDBars)
	--In Combat
	self.wndActionBarInCombatDropdown = actionControls:FindChild("InCombat"):FindChild("Dropdown")
	self.wndActionBarInCombatDropdownBox = actionControls:FindChild("InCombat"):FindChild("DropdownBox")
		
	for name, value in pairs(tInCombatOptions) do
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndActionBarInCombatDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(name)
		--currButton:SetData("ActionBarControls")
		currButton:AddEventHandler("ButtonUp", "OnActionBarInCombatItemClick")
	end
		
	self.wndActionBarInCombatDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	self.wndActionBarInCombatDropdown:SetText(Options.actionBar.strInCombat)
	--NumButtons
	actionControls:FindChild("NumButtons"):FindChild("NumButtonsSliderBar"):SetValue(Options.actionBar.nButtons)
	actionControls:FindChild("NumButtons"):FindChild("NumButtonsEditBox"):SetText(Options.actionBar.nButtons)
	
	--ANCHOR
	self.wndMain:SetAnchorOffsets(unpack(Options.actionBar.tAnchorOffsets))

--Innate Bar
	
	local innateControls = self.wndControls:FindChild("InnateBarControls")
	--Show
	innateControls:FindChild("InnateBarToggle"):SetCheck(Options.innateBar.bShowBar)
	--Show Hotkeys
	innateControls:FindChild("ShowHotkeysToggle"):SetCheck(Options.innateBar.bShowHotkeys)
	--Size
	innateControls:FindChild("Size"):FindChild("SizeSliderBar"):SetValue(Options.innateBar.nSize)
	innateControls:FindChild("Size"):FindChild("SizeEditBox"):SetText(Options.innateBar.nSize)
	--Opacity
	innateControls:FindChild("Opacity"):FindChild("OpacitySliderBar"):SetValue(Options.innateBar.fOpacity*10)
	innateControls:FindChild("Opacity"):FindChild("OpacityEditBox"):SetText(Options.innateBar.fOpacity*10)
	
	--ANCHOR
	self.wndInnate:SetAnchorOffsets(unpack(Options.innateBar.tAnchorOffsets))
	
--Vehicle Bar
	local vehicleControls = self.wndControls:FindChild("VehicleBarControls")
	--Show
	vehicleControls:FindChild("VehicleBarToggle"):SetCheck(Options.vehicleBar.bEnableBar)
	--Shortcut Bars
	vehicleControls:FindChild("ShortcutBarToggle"):SetCheck(Options.general.bEnableShortcutBar)
	--ANCHOR
	self.wndVehicleBar:SetAnchorOffsets(unpack(Options.vehicleBar.tAnchorOffsets))
	
--Shortcut Bar
	
	--ANCHOR

--Secondary Bar
	local secondaryControls = self.wndControls:FindChild("SecondaryBarControls")
	--Show
	secondaryControls:FindChild("BarToggle"):SetCheck(Options.secondaryBar.bShowBar)
	--Show Hotkeys
	secondaryControls:FindChild("ShowHotkeysToggle"):SetCheck(Options.secondaryBar.bShowHotkeys)
	--Size
	secondaryControls:FindChild("Size"):FindChild("SizeSliderBar"):SetValue(Options.secondaryBar.nSize)
	secondaryControls:FindChild("Size"):FindChild("SizeEditBox"):SetText(Options.secondaryBar.nSize)
	--Columns
	secondaryControls:FindChild("Columns"):FindChild("ColumnsSliderBar"):SetValue(Options.secondaryBar.nCols)
	secondaryControls:FindChild("Columns"):FindChild("ColumnsEditBox"):SetText(Options.secondaryBar.nCols)
	--NumButtons
	secondaryControls:FindChild("NumButtons"):FindChild("NumButtonsSliderBar"):SetValue(Options.secondaryBar.nButtons)
	secondaryControls:FindChild("NumButtons"):FindChild("NumButtonsEditBox"):SetText(Options.secondaryBar.nButtons)
	--Opacity
	secondaryControls:FindChild("Opacity"):FindChild("OpacitySliderBar"):SetValue(Options.secondaryBar.fOpacity*10)
	secondaryControls:FindChild("Opacity"):FindChild("OpacityEditBox"):SetText(Options.secondaryBar.fOpacity*10)
	--Split Bar
	--secondaryControls:FindChild("SplitBarToggle"):Enable(false)
	secondaryControls:FindChild("SplitBarToggle"):SetCheck(Options.secondaryBar.bSplitBar)
	--Padding
	secondaryControls:FindChild("Padding"):FindChild("PaddingSliderBar"):SetValue(Options.secondaryBar.nPadding)
	secondaryControls:FindChild("Padding"):FindChild("PaddingEditBox"):SetText(Options.secondaryBar.nPadding)
	--ANCHOR
	self.wndSecondary:SetAnchorOffsets(unpack(Options.secondaryBar.tAnchorOffsets))
	--if #self.wndSecondarySplit:GetChildren() > 0 then
		self.wndSecondarySplit:SetAnchorOffsets(unpack(Options.secondaryBar.tSplitAnchorOffsets))
	--end
		
--Utility Bar
	local utilityControls = self.wndControls:FindChild("UtilityControls")
	local bar1Controls = utilityControls:FindChild("Bar1")
	local bar2Controls = utilityControls:FindChild("Bar2")
	--Bar 1
	--Show
	bar1Controls:FindChild("ShowToggle"):SetCheck(Options.utilityBars.bar1.bShowBar)
	--Show Hotkeys
	bar1Controls:FindChild("ShowHotkeysToggle"):SetCheck(Options.utilityBars.bar1.bShowHotkeys)
	--Size
	bar1Controls:FindChild("Size"):FindChild("SizeSliderBar"):SetValue(Options.utilityBars.bar1.nSize)
	bar1Controls:FindChild("Size"):FindChild("SizeEditBox"):SetText(Options.utilityBars.bar1.nSize)
	--Columns
	bar1Controls:FindChild("Columns"):FindChild("ColumnsSliderBar"):SetValue(Options.utilityBars.bar1.nCols)
	bar1Controls:FindChild("Columns"):FindChild("ColumnsEditBox"):SetText(Options.utilityBars.bar1.nCols)
	--Opacity
	bar1Controls:FindChild("Opacity"):FindChild("OpacitySliderBar"):SetValue(Options.utilityBars.bar1.fOpacity*10)
	bar1Controls:FindChild("Opacity"):FindChild("OpacityEditBox"):SetText(Options.utilityBars.bar1.fOpacity*10)
	--Padding
	bar1Controls:FindChild("Padding"):FindChild("PaddingSliderBar"):SetValue(Options.utilityBars.bar1.nPadding)
	bar1Controls:FindChild("Padding"):FindChild("PaddingEditBox"):SetText(Options.utilityBars.bar1.nPadding)
	--Mount
	bar1Controls:FindChild("MountToggle"):SetCheck(Options.utilityBars.bar1.bShowMountButton)
	--Recall
	bar1Controls:FindChild("RecallToggle"):SetCheck(Options.utilityBars.bar1.bShowRecallButton)
	--Gadget
	bar1Controls:FindChild("GadgetToggle"):SetCheck(Options.utilityBars.bar1.bShowGadgetButton)
	--Path
	bar1Controls:FindChild("PathToggle"):SetCheck(Options.utilityBars.bar1.bShowPathButton)
	--Potion
	bar1Controls:FindChild("PotionToggle"):SetCheck(Options.utilityBars.bar1.bShowPotionButton)
	
	--ANCHOR
	self.wndUtility1:SetAnchorOffsets(unpack(Options.utilityBars.bar1.tAnchorOffsets))
	
	--Bar 2 
	--Show
	bar2Controls:FindChild("ShowToggle"):SetCheck(Options.utilityBars.bar2.bShowBar)
	--Show Hotkeys
	bar2Controls:FindChild("ShowHotkeysToggle"):SetCheck(Options.utilityBars.bar2.bShowHotkeys)
	--Size
	bar2Controls:FindChild("Size"):FindChild("SizeSliderBar"):SetValue(Options.utilityBars.bar2.nSize)
	bar2Controls:FindChild("Size"):FindChild("SizeEditBox"):SetText(Options.utilityBars.bar2.nSize)
	--Columns
	bar2Controls:FindChild("Columns"):FindChild("ColumnsSliderBar"):SetValue(Options.utilityBars.bar2.nCols)
	bar2Controls:FindChild("Columns"):FindChild("ColumnsEditBox"):SetText(Options.utilityBars.bar2.nCols)
	--Opacity
	bar2Controls:FindChild("Opacity"):FindChild("OpacitySliderBar"):SetValue(Options.utilityBars.bar2.fOpacity*10)
	bar2Controls:FindChild("Opacity"):FindChild("OpacityEditBox"):SetText(Options.utilityBars.bar2.fOpacity*10)
	--Padding
	bar2Controls:FindChild("Padding"):FindChild("PaddingSliderBar"):SetValue(Options.utilityBars.bar2.nPadding)
	bar2Controls:FindChild("Padding"):FindChild("PaddingEditBox"):SetText(Options.utilityBars.bar2.nPadding)
	--Mount
	bar2Controls:FindChild("MountToggle"):SetCheck(Options.utilityBars.bar2.bShowMountButton)
	--Recall
	bar2Controls:FindChild("RecallToggle"):SetCheck(Options.utilityBars.bar2.bShowRecallButton)
	--Gadget
	bar2Controls:FindChild("GadgetToggle"):SetCheck(Options.utilityBars.bar2.bShowGadgetButton)
	--Path
	bar2Controls:FindChild("PathToggle"):SetCheck(Options.utilityBars.bar2.bShowPathButton)
	--Potion
	bar2Controls:FindChild("PotionToggle"):SetCheck(Options.utilityBars.bar2.bShowPotionButton)
	
	--ANCHOR
	self.wndUtility2:SetAnchorOffsets(unpack(Options.utilityBars.bar2.tAnchorOffsets))
	
--set saved flyouts
	if Options.flyoutButtons.nSavedMount then
		--GameLib.SetShortcutMount(self.db.profile.flyoutButtons.nSavedMount)
		self.timerMountReset:Start()
	end
	--Print(Options.flyoutButtons.nSavedPotion)
	if Options.flyoutButtons.nSavedPotion then
		GameLib.SetShortcutPotion(Options.flyoutButtons.nSavedPotion)
	end
	
	if self.recallButton1 and self.recallButton1:FindChild("ActionButton") and Options.flyoutButtons.nSavedRecall then
		self.recallButton1:FindChild("ActionButton"):SetContentId(Options.flyoutButtons.nSavedRecall)
	end
	if self.recallButton2 and self.recallButton2:FindChild("ActionButton") and Options.flyoutButtons.nSavedRecall then
		self.recallButton2:FindChild("ActionButton"):SetContentId(Options.flyoutButtons.nSavedRecall)
	end
	
--Profiles
	--current
	self.wndCurrentProfileDropdown = self.wndControls:FindChild("ProfileControls"):FindChild("Current"):FindChild("CurrentDropdown")
	self.wndCurrentProfileDropdownBox = self.wndControls:FindChild("ProfileControls"):FindChild("Current"):FindChild("DropdownBox")
	
	self.wndCurrentProfileDropdown:SetText(self.db:GetCurrentProfile())
	
	--delete
	self.wndDeleteProfileDropdown = self.wndControls:FindChild("ProfileControls"):FindChild("Delete"):FindChild("DeleteDropdown")
	self.wndDeleteProfileDropdownBox = self.wndControls:FindChild("ProfileControls"):FindChild("Delete"):FindChild("DropdownBox")
	--copy
	self.wndCopyProfileDropdown = self.wndControls:FindChild("ProfileControls"):FindChild("Copy"):FindChild("CopyDropdown")
	self.wndCopyProfileDropdownBox = self.wndControls:FindChild("ProfileControls"):FindChild("Copy"):FindChild("DropdownBox")
	
---------------
--LAYOUT EDITOR
---------------
--Abilities Table
--[[
	nId
	bIsActive
	strAbilityDescription
	nCurrentTier
	strName
	strAbilityPerTierPointDescription
	tTiers
	nMaxTiers
]]
	local layoutControls = self.wndControls:FindChild("LayoutEditorControls")
	
	--enable
	layoutControls:FindChild("EnableToggle"):SetCheck(Options.layoutEditor.bEnabled)
	self:ToggleLayoutMode(self, Options.layoutEditor.bEnabled)
	--rows
	layoutControls:FindChild("GridSize"):FindChild("RowsInput"):SetText(Options.layoutEditor.nRows)
	--Cols
	layoutControls:FindChild("GridSize"):FindChild("ColsInput"):SetText(Options.layoutEditor.nCols)
	
	--CandyBars:PopulateLayoutList(self)
	--CandyBars:CreateLayoutGrid(self)
	--CandyBars:PopulateLayoutGrid(self)
	
--HUD Controls
	local HUDControls = self.wndControls:FindChild("HUDControls")
	--action bar
	HUDControls:FindChild("ActionBar"):FindChild("Dropdown"):SetText(GetKey(tHUDOptions, Apollo.GetConsoleVariable("hud.skillsBarDisplay")))
	HUDControls:FindChild("ActionBar"):FindChild("DropdownBox"):SetData("hud.skillsBarDisplay")
	--resource
	HUDControls:FindChild("Resource"):FindChild("Dropdown"):SetText(GetKey(tHUDOptions, Apollo.GetConsoleVariable("hud.resourceBarDisplay")))
	HUDControls:FindChild("Resource"):FindChild("DropdownBox"):SetData("hud.resourceBarDisplay")
	--resource
	HUDControls:FindChild("LeftSecondary"):FindChild("Dropdown"):SetText(GetKey(tHUDOptions, Apollo.GetConsoleVariable("hud.secondaryLeftBarDisplay")))
	HUDControls:FindChild("LeftSecondary"):FindChild("DropdownBox"):SetData("hud.secondaryLeftBarDisplay")
	--resource
	HUDControls:FindChild("RightSecondary"):FindChild("Dropdown"):SetText(GetKey(tHUDOptions, Apollo.GetConsoleVariable("hud.secondaryRightBarDisplay")))
	HUDControls:FindChild("RightSecondary"):FindChild("DropdownBox"):SetData("hud.secondaryRightBarDisplay")
	--resource
	HUDControls:FindChild("Mount"):FindChild("Dropdown"):SetText(GetKey(tHUDOptions, Apollo.GetConsoleVariable("hud.mountButtonDisplay")))
	HUDControls:FindChild("Mount"):FindChild("DropdownBox"):SetData("hud.mountButtonDisplay")
end

local function GetActionSetPos(self, nId)
	local nStupidId
	for _, v in pairs(AbilityBook.GetAbilitiesList()) do
		if v.bIsActive and self.tActionSet[v.nId]and v.tTiers[v.nCurrentTier].splObject:GetId() == nId then
			nStupidId = v.nId
		end
	end
	for i, id in ipairs(self.tCurrentActionSet) do
		if nStupidId == id then
			return i - 1
		end
	end
	return nil
end

function CandyBars:CreateLayoutGrid(self)
	self.wndControls:FindChild("LayoutEditorControls"):FindChild("GridInset"):DestroyChildren()
	self.layoutGrid = {}
	local nRows, nCols = self.db.profile.layoutEditor.nRows, self.db.profile.layoutEditor.nCols
	local nPadding = 5
	local idx = 1
	for rows=1, nRows do
		for cols=1, nCols do
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "ActionButtonDummy", self.wndControls:FindChild("LayoutEditorControls"):FindChild("GridInset"), self)
			local nSize = wndCurr:GetWidth()
			local nLeft = (cols-1)*(nSize + nPadding) + 25
			local nRight = nLeft + nSize
			local nTop = (rows-1)*(nSize + nPadding) + 25
			local nBottom = nTop + nSize
			wndCurr:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
			wndCurr:SetName(idx)
			self.layoutGrid[idx] = wndCurr
			idx = idx + 1
		end
	end
end

function CandyBars:PopulateLayoutGrid(self)
	local tLayout = self.db.profile.layoutEditor.tActionBarLayout
	if self.tCurrentActionSet == nil or self.layoutGrid == nil then
		--self.timerGetActionSet:Start()
		--return false
	end
	for i, wndCurr in ipairs(self.layoutGrid) do
		if tLayout[i] then
			if tLayout[i] == "Innate" then
				wndCurr:FindChild("EmptySlot"):Show(false)
				wndCurr:FindChild("Remove"):Show(true)
				wndCurr:FindChild("Icon"):Show(true)
				wndCurr:FindChild("Icon"):SetSprite(GameLib.GetCurrentClassInnateAbilitySpell():GetIcon())
				wndCurr:SetData(GameLib.GetCurrentClassInnateAbilitySpell():GetId())
			else
			--self.tCurrentActionSet
				local nSpellId = self.tCurrentActionSet[tLayout[i]+1]
				wndCurr:FindChild("EmptySlot"):Show(false)
				wndCurr:FindChild("Remove"):Show(true)
				wndCurr:FindChild("Icon"):Show(true)
				if self.tActionListSpells[nSpellId] then
					wndCurr:FindChild("Icon"):SetSprite(self.tActionListSpells[nSpellId]:GetIcon())
				end
				wndCurr:SetData(nSpellId)
			end
			--wndCurr:FindChild("EmptySlot"):Show(false)
			--wndCurr:FindChild("Remove"):Show(true)
			--wndCurr:FindChild("Icon"):Show(true)
			--wndCurr:FindChild("Icon"):SetSprite(GameLib.GetSpell(tLayout[i]):GetIcon())
			--wndCurr:SetData(tLayout[i])
		end
	end
end

function CandyBars:PopulateLayoutList(self)
	self.tCurrentActionSet = ActionSetLib.GetCurrentActionSet()
	local uPlayer = GameLib.GetPlayerUnit()
	if self.tCurrentActionSet == nil or uPlayer == nil then
		--self.timerGetActionSet:Start()
		--return false
	end
	--Get Action Set Spells
	self.tActionSet = {}
	for k, v in pairs(self.tCurrentActionSet) do 
		--Print(AbilityBook.GetAbilityInfo(v))
		self.tActionSet[v] = true
	end
	--Add Spells
	self.tActionListSpells = {}
	self.wndControls:FindChild("LayoutEditorControls"):FindChild("ActionsInset"):FindChild("ScrollList"):DestroyChildren()
	
	for k, v in pairs(AbilityBook.GetAbilitiesList()) do
		local strName = v.strName
		if v.bIsActive and v.nCurrentTier >= 1 and not self.tActionListSpells[v.nId] and self.tActionSet[v.nId] then -- and v.nId ~= GameLib.GetCurrentClassInnateAbilitySpell():GetId() and v.nId ~= GameLib.GetGadgetAbility():GetId()
			local icon = v.tTiers[v.nCurrentTier].splObject:GetIcon()
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "LayoutEditorListItem", self.wndControls:FindChild("LayoutEditorControls"):FindChild("ActionsInset"):FindChild("ScrollList"), self)
			wndCurr:SetData(v.tTiers[v.nCurrentTier].splObject)
			wndCurr:FindChild("Text"):SetText(strName )
			wndCurr:FindChild("Icon"):SetSprite(icon)
			local splObject = v.tTiers[v.nCurrentTier].splObject
			self.tActionListSpells[v.nId] = splObject--v.tTiers[v.nCurrentTier].splObject
		end
	end
	--Add Innate
	local splInnate = GameLib.GetCurrentClassInnateAbilitySpell()
	if splInnate and splInnate:GetId() then
		local wndInnate = Apollo.LoadForm(self.xmlDoc, "LayoutEditorListItem", self.wndControls:FindChild("LayoutEditorControls"):FindChild("ActionsInset"):FindChild("ScrollList"), self)
		local strName = splInnate:GetName()
		local icon = splInnate:GetIcon()
		wndInnate:FindChild("Text"):SetText("Innate Ability")
		wndInnate:FindChild("Icon"):SetSprite(icon)
		wndInnate:SetData(splInnate)
		self.tActionListSpells[splInnate:GetId()] = true
	end
	--Arrange Spells
	self.wndControls:FindChild("LayoutEditorControls"):FindChild("ActionsInset"):FindChild("ScrollList"):ArrangeChildrenVert()
end

function CandyBars:OnLayoutEditorItemTooltip( wndHandler, wndControl, eToolTipType, x, y )
	Tooltip.GetSpellTooltipForm(self, wndControl, wndControl:GetParent():GetData())
end

function CandyBars:OnLayoutEditorItemDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if eMouseButton > 0 or not self.db.profile.layoutEditor.bEnabled then
		return
	end
	local wndSource = wndControl
	local splObject = wndControl:GetParent():GetData()
	local strType = "LayoutEditorItem"
	local strSprite = splObject:GetIcon()
	local nData = splObject:GetId()
	Apollo.BeginDragDrop(wndSource, strType, strSprite, nData)	
end

function CandyBars:OnLayoutEditorDummyQueryDragDrop( wndHandler, wndControl, x, y, wndSource, strType, iData, eResult )
	return Apollo.DragDropQueryResult.Accept
end

function CandyBars:OnLayoutEditorDummyDragDrop( wndHandler, wndControl, x, y, wndSource, strType, nData, bDragDropHasBeenReset )
	if strType ~= "LayoutEditorItem" then
		return
	end
	wndControl:FindChild("EmptySlot"):Show(false)
	wndControl:FindChild("Remove"):Show(true)
	wndControl:FindChild("Icon"):Show(true)
	wndControl:FindChild("Icon"):SetSprite(wndSource:GetSprite())
	wndControl:SetData(nData)
	
	local nIndex = tonumber(wndControl:GetName())
	--self.db.profile.layoutEditor.tActionBarLayout[nIndex] = nData
	--Print(nData)
	if nData == GameLib.GetCurrentClassInnateAbilitySpell():GetId() then
		self.db.profile.layoutEditor.tActionBarLayout[nIndex] = "Innate"
	else
		self.db.profile.layoutEditor.tActionBarLayout[nIndex] = GetActionSetPos(self, nData)
	end
	--Print(GameLib.GetSpell(iData):GetName())
end

function CandyBars:OnLayoutEditorDummyRemove( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():FindChild("EmptySlot"):Show(true)
	wndControl:Show(false)
	wndControl:GetParent():FindChild("Icon"):Show(false)
	self.db.profile.layoutEditor.tActionBarLayout[tonumber(wndControl:GetParent():GetName())] = nil
	wndControl:GetParent():SetData(nil)
end

function CandyBars:OnLayoutEditorColsChanged( wndHandler, wndControl, strText )
	local nVal = tonumber(strText)
	if nVal == nil or nVal < 1 then
		nVal = 1
		wndControl:SetText(nVal)
	end
	if nVal > 7 then
		nVal = 7
		wndControl:SetText(nVal)
	end
	
	self.db.profile.layoutEditor.nCols = nVal
	
	self:CreateLayoutGrid(self)
	self:PopulateLayoutGrid(self)
end

function CandyBars:OnLayoutEditorRowsChanged( wndHandler, wndControl, strText )
	local nVal = tonumber(strText)
	if nVal == nil or nVal < 1 then
		nVal = 1
		wndControl:SetText(nVal)
	end
	if nVal > 6 then
		nVal = 6
		wndControl:SetText(nVal)
	end
	
	self.db.profile.layoutEditor.nRows = nVal
	
	self:CreateLayoutGrid(self)
	self:PopulateLayoutGrid(self)
end

function CandyBars:OnLayoutEditorUpdateClick( wndHandler, wndControl, eMouseButton )
	self:InitializeBar(self)
	self:ArrangeBar(self)
end

function CandyBars:OnLayoutEditorEnableClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.layoutEditor.bEnabled = wndControl:IsChecked()
	self:ToggleLayoutMode(self, wndControl:IsChecked())

	self:InitializeBar(self)
	self:ArrangeBar(self)
end

function CandyBars:ToggleLayoutMode(self, bEnabled)
	self.wndControls:FindChild("LayoutEditorControls"):FindChild("DisabledAlert"):Show(not bEnabled)
	self.wndControls:FindChild("LayoutEditorControls"):FindChild("GridInset"):Show(bEnabled)
	self.wndControls:FindChild("LayoutEditorControls"):FindChild("GridSize"):Show(bEnabled)
	self.wndControls:FindChild("LayoutEditorControls"):FindChild("UpdateActionBar"):Show(bEnabled)
	--Disable Some Options
	local actionControls = self.wndControls:FindChild("ActionBarControls")
	--Columns
	actionControls:FindChild("Columns"):FindChild("ColumnsSliderBar"):Enable(not bEnabled)
	--Innate
	actionControls:FindChild("InnateToggle"):Enable(not bEnabled)
	--Reverse Order
	actionControls:FindChild("ReverseOrderToggle"):Enable(not bEnabled)
	--Spec Switch
	--actionControls:FindChild("ShowSpecSwitchToggle"):Enable(not bEnabled)
	--NumButtons
	actionControls:FindChild("NumButtons"):FindChild("NumButtonsSliderBar"):Enable(not bEnabled)
end

function CandyBars:OnDefaultClick( wndHandler, wndControl, eMouseButton )
	self.db:ResetProfile()
	--Set Up Options
	CandyBars:SetOptions(self)
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
end

---------------------------------------------------------------------------------------------------
-- OptionsControls Functions
---------------------------------------------------------------------------------------------------

--Expand
function CandyBars:OnOptionsHeaderCheck( wndHandler, wndControl, eMouseButton )
	for i, v in ipairs(self.wndControls:GetChildren()) do
		if v:FindChild("Title"):GetText() == wndControl:GetText() then
			v:Show(true)
		else
			v:Show(false)
		end
	end
end

--Collapse
function CandyBars:OnOptionsHeaderUncheck( wndHandler, wndControl, eMouseButton )
	--size: 45
end

function CandyBars:OnLockClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bLockBars = wndControl:IsChecked()
	--Lock/Unlock Bars
	CandyBars:ToggleLockBars(self)
end

function CandyBars:ToggleLockBars(self)
	local lock = self.db.profile.general.bLockBars
	--lock windows
	self.wndMain:SetStyle("Moveable", not lock)
	self.wndInnate:SetStyle("Moveable", not lock)
	self.wndSecondary:SetStyle("Moveable", not lock)
	self.wndSecondarySplit:SetStyle("Moveable", not lock)
	self.wndUtility1:SetStyle("Moveable", not lock)
	self.wndUtility2:SetStyle("Moveable", not lock)
	self.wndVehicleBar:SetStyle("Moveable", not lock)
	if self.tActionBarsHorz ~= nil then
		for idx = 4, ActionSetLib.CodeEnumShortcutSet.Count do
			self.tActionBarsHorz[idx]:SetStyle("Moveable", not lock)
			self.tActionBarsHorz[idx]:SetStyle("Picture", not lock)
		end
	end
	--bg hover
	self.wndMain:SetStyle("Picture", not lock)
	self.wndInnate:SetStyle("Picture", not lock)
	self.wndSecondary:SetStyle("Picture", not lock)
	self.wndSecondarySplit:SetStyle("Picture", not lock)
	self.wndUtility1:SetStyle("Picture", not lock)
	self.wndUtility2:SetStyle("Picture", not lock)
	self.wndVehicleBar:SetStyle("Picture", not lock)
end

function CandyBars:OnTooltipClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowTooltips = wndControl:IsChecked()
end

function CandyBars:OnCloseButtonClick( wndHandler, wndControl, eMouseButton )
	self.wndOptionsNew:Show(false)
end

function CandyBars:OnAboutCloseClick( wndHandler, wndControl, eMouseButton )
	self.wndOptionsNew:Show(false)
end

function CandyBars:OnKeybindModeClick( wndHandler, wndControl, eMouseButton )
	CandyBars:EnterKeybindMode(self)
end

function CandyBars:OnInnateShowClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.actionBar.bShowInnate = wndControl:IsChecked()
	--Reinitialize
	CandyBars:InitializeBar(self)
	--Refresh Bars
	CandyBars:ArrangeBar(self)

end

function CandyBars:OnActionBarShowClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.actionBar.bShowBar = wndControl:IsChecked()
	--Reinitialize
	CandyBars:InitializeBar(self)
	--Refresh Bars
	CandyBars:ArrangeBar(self)
end

function CandyBars:OnActionBarSizeChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local input = math.floor(fNewValue)
	self.db.profile.actionBar.nSize = input
	wndControl:GetParent():FindChild("SizeEditBox"):SetText(input)

	--Refresh Bars
	CandyBars:ArrangeBar(self)
end

function CandyBars:OnActionBarColumnsChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local input = math.floor(fNewValue)
	self.db.profile.actionBar.nCols = input
	wndControl:GetParent():FindChild("ColumnsEditBox"):SetText(input)
	--Refresh Bars
	CandyBars:ArrangeBar(self)
end

function CandyBars:OnActionBarOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local opacity = math.floor(fNewValue)/10
	self.db.profile.actionBar.fOpacity = opacity
	wndControl:GetParent():FindChild("OpacityEditBox"):SetText(opacity*10)
	self.wndMain:SetOpacity(opacity)
end

function CandyBars:OnActionBarPaddingChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local input = math.floor(fNewValue)
	self.db.profile.actionBar.nPadding = input
	wndControl:GetParent():FindChild("PaddingEditBox"):SetText(input)

	--Reinitialize
	--CandyBars:InitializeBar(self)
	--Refresh Bars
	CandyBars:ArrangeBar(self)
	--CandyBars:ArrangeSecondaryBar(self)
	--CandyBars:ArrangeUtilityBar1(self)
	--CandyBars:ArrangeUtilityBar2(self)
end

function CandyBars:OnReverseOrderClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.actionBar.bReverseOrder = wndControl:IsChecked()
	--Reinitialize
	CandyBars:InitializeBar(self)
	--Refresh Bars
	CandyBars:ArrangeBar(self)
end

function CandyBars:OnShowSpecSwitchClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.actionBar.bShowSpecSwitch = wndControl:IsChecked()
	self.wndSpecSwitches:Show(wndControl:IsChecked())
end

function CandyBars:OnActionBarShowHotkeysClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.actionBar.bShowHotkeys = wndControl:IsChecked()
	--Reinitialize
	CandyBars:InitializeBar(self)
	--Refresh Bars
	CandyBars:ArrangeBar(self)
end

function CandyBars:OnActionBarShowCDBarsClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.actionBar.bShowCDBars = wndControl:IsChecked()
end

function CandyBars:OnActionBarInCombatClick( wndHandler, wndControl, eMouseButton )
	self.wndActionBarInCombatDropdownBox:Show(true)
	
	self.wndControls:FindChild("ActionBarControls"):FindChild("Opacity"):FindChild("OpacitySliderBar"):Enable(false)
end

function CandyBars:OnActionBarInCombatItemClick( wndHandler, wndControl, eMouseButton )
	self.wndActionBarInCombatDropdown:SetText(wndControl:GetText())
	
	self.db.profile.actionBar.strInCombat = wndControl:GetText()
	self.wndActionBarInCombatDropdownBox:Show(false)
	
	if wndControl:GetText() == "Do Nothing" then
		self.wndMain:Show(self.db.profile.actionBar.bShowBar)
	end
	
end

function CandyBars:OnActionBarInCombatDropHide( wndHandler, wndControl )
	self.wndControls:FindChild("ActionBarControls"):FindChild("Opacity"):FindChild("OpacitySliderBar"):Enable(true)
end

function CandyBars:OnActionBarNumButtonsChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.db.profile.actionBar.nButtons = math.floor(fNewValue)
	wndControl:GetParent():FindChild("NumButtonsEditBox"):SetText(math.floor(fNewValue))
	--Reinitialize
	self:InitializeBar(self)
	self:ArrangeBar(self)
end

function CandyBars:OnSecondaryBarShowClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.secondaryBar.bShowBar = wndControl:IsChecked()
	--Reinitialize
	CandyBars:InitializeSecondaryBar(self)
	--Refresh Bars
	CandyBars:ArrangeSecondaryBar(self)
end

function CandyBars:OnSecondaryBarShowHotkeysClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.secondaryBar.bShowHotkeys = wndControl:IsChecked()
	--Reinitialize
	CandyBars:InitializeSecondaryBar(self)
	--Refresh Bars
	CandyBars:ArrangeSecondaryBar(self)
end

function CandyBars:OnSecondaryBarSizeChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.db.profile.secondaryBar.nSize = math.floor(fNewValue)
	wndControl:GetParent():FindChild("SizeEditBox"):SetText(math.floor(fNewValue))
	self:ArrangeSecondaryBar(self)
end

function CandyBars:OnSecondaryBarColumnsChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.db.profile.secondaryBar.nCols = math.floor(fNewValue)
	wndControl:GetParent():FindChild("ColumnsEditBox"):SetText(math.floor(fNewValue))
	self:ArrangeSecondaryBar(self)
end

function CandyBars:OnSecondaryBarNumButtonsChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.db.profile.secondaryBar.nButtons = math.floor(fNewValue)
	wndControl:GetParent():FindChild("NumButtonsEditBox"):SetText(math.floor(fNewValue))
	--Reinitialize
	self:InitializeSecondaryBar(self)
	self:ArrangeSecondaryBar(self)
end

function CandyBars:OnSecondaryBarPaddingChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local input = math.floor(fNewValue)
	self.db.profile.secondaryBar.nPadding = input
	wndControl:GetParent():FindChild("PaddingEditBox"):SetText(input)

	--Reinitialize
	--CandyBars:InitializeSecondaryBar(self)
	--Refresh Bars
	CandyBars:ArrangeSecondaryBar(self)
end

function CandyBars:OnSecondaryBarSplitClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.secondaryBar.bSplitBar = wndControl:IsChecked()
	--Reinitialize
	CandyBars:InitializeSecondaryBar(self)
	--Refresh Bars
	CandyBars:ArrangeSecondaryBar(self)
end

function CandyBars:OnInnateBarShowClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.innateBar.bShowBar = wndControl:IsChecked()
	self:InitializeInnateBar(self)
	self:ArrangeInnateBar(self)
end

function CandyBars:OnInnateBarShowHotkeysClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.innateBar.bShowHotkeys = wndControl:IsChecked()
	--Reinitialize
	CandyBars:InitializeInnateBar(self)
	--Refresh Bars
	CandyBars:ArrangeInnateBar(self)
end

function CandyBars:OnInnateBarSizeChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.db.profile.innateBar.nSize = math.floor(fNewValue)
	wndControl:GetParent():FindChild("SizeEditBox"):SetText(math.floor(fNewValue))
	self:ArrangeInnateBar(self)
end

function CandyBars:OnUtilityBarShowClick( wndHandler, wndControl, eMouseButton )
	local bar = wndControl:GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.bShowBar = wndControl:IsChecked()
		self:InitializeUtilityBar1(self)
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.bShowBar = wndControl:IsChecked()
		self:InitializeUtilityBar2(self)
		self:ArrangeUtilityBar2(self)
	end
end

function CandyBars:OnUtillityBarShowHotkeysClick( wndHandler, wndControl, eMouseButton )
	local bar = wndControl:GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.bShowHotkeys = wndControl:IsChecked()
		self:InitializeUtilityBar1(self)
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.bShowHotkeys = wndControl:IsChecked()
		self:InitializeUtilityBar2(self)
		self:ArrangeUtilityBar2(self)
	end

end

function CandyBars:OnUtilityBarSizeChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local bar = wndControl:GetParent():GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.nSize = math.floor(fNewValue)
		wndControl:GetParent():FindChild("SizeEditBox"):SetText(math.floor(fNewValue))
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.nSize = math.floor(fNewValue)
		wndControl:GetParent():FindChild("SizeEditBox"):SetText(math.floor(fNewValue))
		self:ArrangeUtilityBar2(self)
	end
end

function CandyBars:OnUtilityBarColumnsChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local bar = wndControl:GetParent():GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.nCols = math.floor(fNewValue)
		wndControl:GetParent():FindChild("ColumnsEditBox"):SetText(math.floor(fNewValue))
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.nCols = math.floor(fNewValue)
		wndControl:GetParent():FindChild("ColumnsEditBox"):SetText(math.floor(fNewValue))
		self:ArrangeUtilityBar2(self)
	end
end

function CandyBars:OnUtilityBarPaddingChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local bar = wndControl:GetParent():GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.nPadding = math.floor(fNewValue)
		wndControl:GetParent():FindChild("PaddingEditBox"):SetText(math.floor(fNewValue))
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.nPadding = math.floor(fNewValue)
		wndControl:GetParent():FindChild("PaddingEditBox"):SetText(math.floor(fNewValue))
		self:ArrangeUtilityBar2(self)
	end
end

function CandyBars:OnUtilityBarMountClick( wndHandler, wndControl, eMouseButton )
	local bar = wndControl:GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.bShowMountButton = wndControl:IsChecked()
		self:InitializeUtilityBar1(self)
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.bShowMountButton = wndControl:IsChecked()
		self:InitializeUtilityBar2(self)
		self:ArrangeUtilityBar2(self)
	end
end

function CandyBars:OnUtilityBarRecallClick( wndHandler, wndControl, eMouseButton )
	local bar = wndControl:GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.bShowRecallButton = wndControl:IsChecked()
		self:InitializeUtilityBar1(self)
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.bShowRecallButton = wndControl:IsChecked()
		self:InitializeUtilityBar2(self)
		self:ArrangeUtilityBar2(self)
	end
end

function CandyBars:OnUtilityBarGadgetClick( wndHandler, wndControl, eMouseButton )
	local bar = wndControl:GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.bShowGadgetButton = wndControl:IsChecked()
		self:InitializeUtilityBar1(self)
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.bShowGadgetButton = wndControl:IsChecked()
		self:InitializeUtilityBar2(self)
		self:ArrangeUtilityBar2(self)
	end
end

function CandyBars:OnUtilityBarPotionClick( wndHandler, wndControl, eMouseButton )
	local bar = wndControl:GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.bShowPotionButton = wndControl:IsChecked()
		self:InitializeUtilityBar1(self)
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.bShowPotionButton = wndControl:IsChecked()
		self:InitializeUtilityBar2(self)
		self:ArrangeUtilityBar2(self)
	end
end

function CandyBars:OnUtilityBarPathClick( wndHandler, wndControl, eMouseButton )
	local bar = wndControl:GetParent():FindChild("Label"):GetText()
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.bShowPathButton = wndControl:IsChecked()
		self:InitializeUtilityBar1(self)
		self:ArrangeUtilityBar1(self)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.bShowPathButton = wndControl:IsChecked()
		self:InitializeUtilityBar2(self)
		self:ArrangeUtilityBar2(self)
	end
end

function CandyBars:OnEmptySlotsClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowEmptySlots = wndControl:IsChecked()
	--Toggle Empty Slots
	CandyBars:ToggleShowEmptySlots(self)
	--[[lock windows
	self.wndMain:SetStyle("Moveable", show)
	self.wndSecondary:SetStyle("Moveable", show)
	self.wndUtility1:SetStyle("Moveable", show)
	self.wndUtility2:SetStyle("Moveable", show)
	]]
end

function CandyBars:ToggleShowEmptySlots(self)
	--self.actionButtons
	if self.actionButtons then
		for k,v in pairs(self.actionButtons) do
			v:FindChild("EmptySlot"):Show(self.db.profile.general.bShowEmptySlots)
		end
	end
	--self.secondaryButtons
	if self.secondaryButtons then
		for k,v in pairs(self.secondaryButtons) do
			v:FindChild("EmptySlot"):Show(self.db.profile.general.bShowEmptySlots)
		end
	end
end


function CandyBars:OnEnableVehicleClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.vehicleBar.bEnableBar = wndControl:IsChecked()
	--[[
	if not wndControl:IsChecked() and self.wndVehicleBar:IsVisible() then
		self.wndVehicleBar:Show(false)
	end
	]]
	if GameLib.GetPlayerUnit():IsInVehicle() then
		self.wndVehicleBar:Show(wndControl:IsChecked())
	end
end

function CandyBars:OnSecondaryBarOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local opacity = math.floor(fNewValue)/10
	self.db.profile.secondaryBar.fOpacity = opacity
	wndControl:GetParent():FindChild("OpacityEditBox"):SetText(opacity*10)
	self.wndSecondary:SetOpacity(opacity)
	self.wndSecondarySplit:SetOpacity(opacity)
end

function CandyBars:OnInnateBarOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local opacity = math.floor(fNewValue)/10
	self.db.profile.innateBar.fOpacity = opacity
	wndControl:GetParent():FindChild("OpacityEditBox"):SetText(opacity*10)
	self.wndInnate:SetOpacity(opacity)
end

function CandyBars:OnUtilityBarOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local bar = wndControl:GetParent():GetParent():FindChild("Label"):GetText()
	local opacity = math.floor(fNewValue)/10
	if bar == "Bar 1" then
		self.db.profile.utilityBars.bar1.fOpacity = opacity
		wndControl:GetParent():FindChild("OpacityEditBox"):SetText(opacity*10)
		self.wndUtility1:SetOpacity(opacity)
	elseif bar == "Bar 2" then
		self.db.profile.utilityBars.bar2.fOpacity = opacity
		wndControl:GetParent():FindChild("OpacityEditBox"):SetText(opacity*10)
		self.wndUtility2:SetOpacity(opacity)
	end
end

function CandyBars:SetAllOpacities(self)
	self.wndMain:SetOpacity(tonumber(self.db.profile.actionBar.fOpacity))
	self.wndSecondary:SetOpacity(tonumber(self.db.profile.secondaryBar.fOpacity))
	self.wndSecondarySplit:SetOpacity(tonumber(self.db.profile.secondaryBar.fOpacity))
	self.wndInnate:SetOpacity(tonumber(self.db.profile.innateBar.fOpacity))
	self.wndUtility1:SetOpacity(tonumber(self.db.profile.utilityBars.bar1.fOpacity))
	self.wndUtility2:SetOpacity(tonumber(self.db.profile.utilityBars.bar2.fOpacity))
end

function CandyBars:OnEnableShortcutBarClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bEnableShortcutBar = wndControl:IsChecked()
	
	for idx = 4, ActionSetLib.CodeEnumShortcutSet.Count do
		self.tActionBarsHorz[idx]:Show(false)
		self.tActionBarsHorz[idx]:DestroyChildren()
	end
	
	CandyBars:InitializeShortcutBar(self)
end

function CandyBars:OnColorDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndColorDropdownBox:Show(true)
end

function CandyBars:OnHUDDropDownClick( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tHUDOptions, "OnHUDDropDownItemClick")
	--disable others
	for k, v in pairs(self.wndControls:FindChild("HUDControls"):GetChildren()) do
		if v:GetName() ~= wndControl:GetParent():GetName() and v:GetName() ~= "Title" and v:GetName() ~= "Description" then
			v:FindChild("Dropdown"):Enable(false)
			--Print(v:GetName())
		end
	end
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CandyBars:OnHUDDropDownItemClick( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():GetParent():GetParent():FindChild("Dropdown"):SetText(wndControl:GetText())
	Apollo.SetConsoleVariable(wndControl:GetParent():GetParent():GetData(), tonumber(wndControl:GetData()))
	Event_FireGenericEvent("OptionsUpdated_HUDPreferences")
end

function CandyBars:OnHUDDropDownHide( wndHandler, wndControl )
	for k, v in pairs(self.wndControls:FindChild("HUDControls"):GetChildren()) do
		if v:FindChild("Dropdown") then
			v:FindChild("Dropdown"):Enable(true)
		end
	end
end
---------------------------------------------------
--				Profiles
---------------------------------------------------

function CandyBars:OnNewProfileReturn( wndHandler, wndControl, strText )
	if strText == "" then return end
	self.db:SetProfile(strText)
	self.db.char.currentProfile = wndControl:GetText()
	wndControl:SetText("")
	CandyBars:SetOptions()
end

function CandyBars:OnDeleteProfileDropdownClick( wndHandler, wndControl, eMouseButton )
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

function CandyBars:OnDeleteProfileItemClick( wndHandler, wndControl, eMouseButton )
	--self.wndCurrentProfileDropdown:SetText(wndControl:GetText())
	
	--self.db.profile.profiles.sCurrentP = wndControl:GetText()
	--self.db:SetProfile(wndControl:GetText())
	
	self.wndDeleteProfileDropdownBox:Show(false)
	self.wndConfirmAlert:FindChild("NoticeText"):SetText("Are you sure you want to delete "..wndControl:GetText().."?")
	self.wndConfirmAlert:FindChild("Profile"):SetText(wndControl:GetText())
	self.wndConfirmAlert:FindChild("YesButton"):AddEventHandler("ButtonUp", "OnConfirmYes")
	self.wndConfirmAlert:FindChild("NoButton"):AddEventHandler("ButtonUp", "OnConfirmNo")
	self.wndConfirmAlert:FindChild("NoButton2"):AddEventHandler("ButtonUp", "OnConfirmNo")
	self.wndConfirmAlert:Show(true)
	self.wndConfirmAlert:ToFront()
	--CandyBars:SetOptions()
end

function CandyBars:OnConfirmYes(wndHandler, wndControl, eMouseButton)
	local profile = wndControl:GetParent():FindChild("Profile"):GetText()
	self.db:DeleteProfile(profile, true)
	wndControl:GetParent():Show(false)
end

function CandyBars:OnConfirmNo(wndHandler, wndControl, eMouseButton)
	wndControl:GetParent():Show(false)
end

function CandyBars:OnCurrentProfileDropdownClick( wndHandler, wndControl, eMouseButton )
	
	self.wndCurrentProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()	
	
	for name, value in pairs(self.db:GetProfiles()) do
		if value ~= self.db:GetCurrentProfile() then
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndCurrentProfileDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(value)
		
		--currButton:RemoveEventHandler("ButtonUp")
		currButton:AddEventHandler("ButtonUp", "OnCurrentProfileItemClick")
		end
	end
		
	self.wndCurrentProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	self.wndCopyProfileDropdown:Enable(false)
	self.wndCurrentProfileDropdownBox:Show(true)
	--self.wndCurrentProfileDropdown:SetText(tOptions.windowAppearance.sTimestamps)
end

function CandyBars:OnCurrentProfileItemClick( wndHandler, wndControl, eMouseButton )
	self.wndCurrentProfileDropdown:SetText(wndControl:GetText())
	
	self.db:SetProfile(wndControl:GetText())
	
	self.db.char.currentProfile = wndControl:GetText()
	
	self.wndCurrentProfileDropdownBox:Show(false)
	
	CandyBars:SetOptions()

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
end

function CandyBars:OnCurrentDropHide( wndHandler, wndControl )
	self.wndCopyProfileDropdown:Enable(true)
end

function CandyBars:OnCopyFromDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndCopyProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()	
	
	for name, value in pairs(self.db:GetProfiles()) do
		if value ~= self.db:GetCurrentProfile() then
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndCopyProfileDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(value)
		
		--currButton:RemoveEventHandler("ButtonUp")
		currButton:AddEventHandler("ButtonUp", "OnCopyProfileItemClick")
		end
	end
		
	self.wndCopyProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	self.wndCopyProfileDropdownBox:Show(true)
end

function CandyBars:OnCopyProfileItemClick( wndHandler, wndControl, eMouseButton )
	self.wndCopyProfileDropdown:SetText(wndControl:GetText())
	
	self.db:CopyProfile(wndControl:GetText(), false)
	
	self.wndCopyProfileDropdownBox:Show(false)
	
	CandyBars:SetOptions()
end
