--Options for StarPanel
local StarPanel = Apollo.GetAddon("StarPanel")

---------------
--   Round
---------------
--local round = _G.strRound
local function round(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end

local tAlignmentOptions = {
	["Left"] = "0",
	["Center"] = "1",
	["Right"] = "2",
}

ktSPDefaults = {
	char = {
		currentProfile = nil,
	},
	profile = {
		tDTOptions = {
		
		},
		general = {
		
		},
		topBar = {
			bShow = true,
			bHideCombat = false,
			bAutoHide = false,
			bAutoHideBG = false,
			nYOffset = 0,
			nOpacity = 1,
			nPadding = 35,
			strAlignment = "Left",
		},
		botBar = {
			bShow = false,
			bHideCombat = false,
			bAutoHide = false,
			bAutoHideBG = false,
			nYOffset = 0,
			nOpacity = 1,
			nPadding = 35,
			strAlignment = "Left",
			bShiftUI = false,
		},
		dataTexts = {
			nUpdateInterval = 0.25
		},
	},
}

function StarPanel:SetOptions()
	local tOptions = self.db.profile
--TopBar
	local topBarControls = self.wndControls:FindChild("TopBarControls")
	--show
	topBarControls:FindChild("ShowToggle"):SetCheck(tOptions.topBar.bShow)
	self.wndTopDisplay:Show(tOptions.topBar.bShow)
	--hide combat
	topBarControls:FindChild("HideCombatToggle"):SetCheck(tOptions.topBar.bHideCombat)
	--auto hide
	topBarControls:FindChild("AutoHideToggle"):SetCheck(tOptions.topBar.bAutoHide)
	self.wndTopDisplay:SetStyle("AutoFade", tOptions.topBar.bAutoHide)
	--auto hide bg
	topBarControls:FindChild("AutoHideBGToggle"):SetCheck(tOptions.topBar.bAutoHideBG)
	self.wndTopDisplay:SetStyle("AutoFadeBG", tOptions.topBar.bAutoHideBG)
	--y-offset
	topBarControls:FindChild("YOffset"):FindChild("Input"):SetText(tOptions.topBar.nYOffset)
	self:SetYOffsetTop(tOptions.topBar.nYOffset)
	--opacity
	topBarControls:FindChild("OpacityBar"):FindChild("EditBox"):SetText(tOptions.topBar.nOpacity)
	topBarControls:FindChild("OpacityBar"):FindChild("SliderBar"):SetValue(tOptions.topBar.nOpacity)
	self.wndTopDisplay:SetOpacity(tOptions.topBar.nOpacity)
	--padding
	topBarControls:FindChild("PaddingBar"):FindChild("EditBox"):SetText(tOptions.topBar.nPadding)
	topBarControls:FindChild("PaddingBar"):FindChild("SliderBar"):SetValue(tOptions.topBar.nPadding)
	--Alignment
	self.wndAlignmentTopDropdown = topBarControls:FindChild("Alignment"):FindChild("AlignmentDropdown")
	self.wndAlignmentTopDropdownBox = topBarControls:FindChild("Alignment"):FindChild("DropdownBox")
		
	for name, value in pairs(tAlignmentOptions) do
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndAlignmentTopDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(name)
		
		currButton:AddEventHandler("ButtonUp", "OnTBAlignmentItemClick")
	end
		
	self.wndAlignmentTopDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	self.wndAlignmentTopDropdown:SetText(tOptions.topBar.strAlignment)
--BotBar
	local botBarControls = self.wndControls:FindChild("BottomBarControls")
	--show
	botBarControls:FindChild("ShowToggle"):SetCheck(tOptions.botBar.bShow)
	self.wndBotDisplay:Show(tOptions.botBar.bShow)
	--hide combat
	botBarControls:FindChild("HideCombatToggle"):SetCheck(tOptions.botBar.bHideCombat)
	--auto hide
	botBarControls:FindChild("AutoHideToggle"):SetCheck(tOptions.botBar.bAutoHide)
	self.wndBotDisplay:SetStyle("AutoFade", tOptions.botBar.bAutoHide)
	--auto hide bg
	botBarControls:FindChild("AutoHideBGToggle"):SetCheck(tOptions.botBar.bAutoHideBG)
	self.wndBotDisplay:SetStyle("AutoFade", tOptions.botBar.bAutoHideBG)
	--y-offset
	botBarControls:FindChild("YOffset"):FindChild("Input"):SetText(tOptions.botBar.nYOffset)
	self:SetYOffsetBot(tOptions.botBar.nYOffset)
	--opacity
	botBarControls:FindChild("OpacityBar"):FindChild("EditBox"):SetText(tOptions.botBar.nOpacity)
	botBarControls:FindChild("OpacityBar"):FindChild("SliderBar"):SetValue(tOptions.botBar.nOpacity)
	self.wndBotDisplay:SetOpacity(tOptions.botBar.nOpacity)
	--padding
	botBarControls:FindChild("PaddingBar"):FindChild("EditBox"):SetText(tOptions.botBar.nPadding)
	botBarControls:FindChild("PaddingBar"):FindChild("SliderBar"):SetValue(tOptions.botBar.nPadding)
	--Alignment
	self.wndAlignmentBotDropdown = botBarControls:FindChild("Alignment"):FindChild("AlignmentDropdown")
	self.wndAlignmentBotDropdownBox = botBarControls:FindChild("Alignment"):FindChild("DropdownBox")
		
	for name, value in pairs(tAlignmentOptions) do
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndAlignmentBotDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(name)
		
		currButton:AddEventHandler("ButtonUp", "OnBBAlignmentItemClick")
	end
		
	self.wndAlignmentBotDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	self.wndAlignmentBotDropdown:SetText(tOptions.botBar.strAlignment)
	--Shift UI
	botBarControls:FindChild("ShiftUIToggle"):SetCheck(false)--tOptions.botBar.bShiftUI)
	botBarControls:FindChild("ShiftUIToggle"):Enable(false)
	
	if tOptions.botBar.bShiftUI then
		--self.ShiftUIDelay = ApolloTimer.Create(1, false, "ToggleBBShiftUI", self)
		--self.ShiftUIDelay:Start()
	end
	
--Data Texts
	local dataTextsControls = self.wndControls:FindChild("DataTextControls")
	dataTextsControls:FindChild("UpdateBar"):FindChild("EditBox"):SetText(tOptions.dataTexts.nUpdateInterval)
	dataTextsControls:FindChild("UpdateBar"):FindChild("SliderBar"):SetValue(tOptions.dataTexts.nUpdateInterval)
	
	--set up data text options just for start up
	
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
end

---------------------------------------------------------------------------------------------------
-- OptionsControls Functions
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Top Bar
---------------------------------------------------------------------------------------------------
--Show
function StarPanel:OnTBShowClick( wndHandler, wndControl, eMouseButton )
	self.wndTopDisplay:Show(wndControl:IsChecked())
	self.db.profile.topBar.bShow = wndControl:IsChecked()
end
--Hide on Combat
function StarPanel:OnTBHideCombatClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.topBar.bHideCombat = wndControl:IsChecked()
end
--auto hide 
function StarPanel:OnTBAutoHideClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.topBar.bAutoHide = wndControl:IsChecked()
	self.wndTopDisplay:SetStyle("AutoFade", wndControl:IsChecked())
	
	if wndControl:IsChecked() == false then
		self.wndTopDisplay:SetOpacity(self.db.profile.topBar.nOpacity) -- replace with saved opacity
	end
end
--auto hide bg
function StarPanel:OnTBAutoHideBGClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.topBar.bAutoHideBG = wndControl:IsChecked()
	self.wndTopDisplay:SetStyle("AutoFadeBG", wndControl:IsChecked())
	
	if wndControl:IsChecked() == false then
		--Figure out how to make the bg show again
		self.wndTopDisplay:SetBGOpacity(1)
	end
end
-- Y-Offset
function StarPanel:OnTBYOffsetChanged( wndHandler, wndControl, strText )
	if not tonumber(strText) then
		strText = 0
	end
	self.db.profile.topBar.nYOffset = round(tonumber(strText))
	self:SetYOffsetTop(self.db.profile.topBar.nYOffset)
end
-- opacity
function StarPanel:OnTBOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local val = round(fNewValue, 1)
	self.db.profile.topBar.nOpacity = val
	self.wndControls:FindChild("TopBarControls"):FindChild("OpacityBar"):FindChild("EditBox"):SetText(val)
	self.wndTopDisplay:SetOpacity(val)
end
--padding
function StarPanel:OnTBPaddingChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local val = round(fNewValue)
	self.db.profile.topBar.nPadding = val
	self.wndControls:FindChild("TopBarControls"):FindChild("PaddingBar"):FindChild("EditBox"):SetText(val)
	self:RefreshTopDisplay(self)
end
--Alignment
function StarPanel:OnTBAlignmentDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndAlignmentTopDropdownBox:Show(true)
	--self.wndControls:FindChild("NotificationControls"):Enable(false)
	--self.wndControls:FindChild("AppearanceControls"):FindChild("ShowEmoticonsToggle"):Enable(false)
end

function StarPanel:OnTBAlignmentItemClick( wndHandler, wndControl, eMouseButton )
	self.wndAlignmentTopDropdown:SetText(wndControl:GetText())
	
	self.db.profile.topBar.strAlignment = wndControl:GetText()
	
	self.wndAlignmentTopDropdownBox:Show(false)
	
	self:RefreshTopDisplay(self)
end

---------------------------------------------------------------------------------------------------
-- Bot Bar
---------------------------------------------------------------------------------------------------
--Show
function StarPanel:OnBBShowClick( wndHandler, wndControl, eMouseButton )
	self.wndBotDisplay:Show(wndControl:IsChecked())
	self.db.profile.botBar.bShow = wndControl:IsChecked()
end
--Hide on Combat
function StarPanel:OnBBHideCombatClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.botBar.bHideCombat = wndControl:IsChecked()
end
--auto hide 
function StarPanel:OnBBAutoHideClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.botBar.bAutoHide = wndControl:IsChecked()
	self.wndBotDisplay:SetStyle("AutoFade", wndControl:IsChecked())
	
	if wndControl:IsChecked() == false then
		self.wndBotDisplay:SetOpacity(self.db.profile.botBar.nOpacity) -- replace with saved opacity
	end
end
--auto hide bg
function StarPanel:OnBBAutoHideBGClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.botBar.bAutoHideBG = wndControl:IsChecked()
	self.wndBotDisplay:SetStyle("AutoFadeBG", wndControl:IsChecked())
	
	if wndControl:IsChecked() == false then
		--Figure out how to make the bg show again
		self.wndBotDisplay:SetBGOpacity(1)
	end
end
-- Y-Offset
function StarPanel:OnBBYOffsetChanged( wndHandler, wndControl, strText )
	if not tonumber(strText) then
		strText = 0
	end
	self.db.profile.botBar.nYOffset = round(tonumber(strText))
	self:SetYOffsetBot(self.db.profile.botBar.nYOffset)
end
-- opacity
function StarPanel:OnBBOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local val = round(fNewValue, 1)
	self.db.profile.botBar.nOpacity = val
	self.wndControls:FindChild("BotBarControls"):FindChild("OpacityBar"):FindChild("EditBox"):SetText(val)
	self.wndBotDisplay:SetOpacity(val)
end
--padding
function StarPanel:OnBBPaddingChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local val = round(fNewValue)
	self.db.profile.botBar.nPadding = val
	self.wndControls:FindChild("BotBarControls"):FindChild("PaddingBar"):FindChild("EditBox"):SetText(val)
	self:RefreshBotDisplay(self)
end
--Alignment
function StarPanel:OnBBAlignmentDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndAlignmentBotDropdownBox:Show(true)
	--self.wndControls:FindChild("NotificationControls"):Enable(false)
	--self.wndControls:FindChild("AppearanceControls"):FindChild("ShowEmoticonsToggle"):Enable(false)
end

function StarPanel:OnBBAlignmentItemClick( wndHandler, wndControl, eMouseButton )
	self.wndAlignmentBotDropdown:SetText(wndControl:GetText())
	
	self.db.profile.botBar.strAlignment = wndControl:GetText()
	
	self.wndAlignmentBotDropdownBox:Show(false)
	
	self:RefreshBotDisplay(self)
end

--Shift UI
function StarPanel:OnBBShiftUIClick( wndHandler, wndControl, eMouseButton )
--[[
	self.db.profile.botBar.bShiftUI = wndControl:IsChecked()
	local QuestTracker = Apollo.GetAddon("QuestTracker")
	if wndControl:IsChecked() then
		self:ShiftBottomUI(-30)
		local l, t, r, b = QuestTracker.wndMain:GetAnchorOffsets()
		QuestTracker.wndMain:SetAnchorOffsets(l, t, r, b-20)
	else
		self:ShiftBottomUI(30)
		local l, t, r, b = QuestTracker.wndMain:GetAnchorOffsets()
		QuestTracker.wndMain:SetAnchorOffsets(l, t, r, b+20)
	end
	]]
end

function StarPanel:ToggleBBShiftUI()
--[[
	local QuestTracker = Apollo.GetAddon("QuestTracker")
	if QuestTracker then
		if self.db.profile.botBar.bShiftUI then
			self:ShiftBottomUI(-30)
			local l, t, r, b = QuestTracker.wndMain:GetAnchorOffsets()
			QuestTracker.wndMain:SetAnchorOffsets(l, t, r, b-20)
		end
	else
		self.ShiftUIDelay:Stop()
		self.ShiftUIDelay:Start()
	end
	]]
end
---------------------------------------------------
--				DataTexts
---------------------------------------------------
function StarPanel:OnViewDataTextsClick( wndHandler, wndControl, eMouseButton )
	--Apollo.LoadForm(self.xmlDoc, "DataTextOptionItem", self.wndDataTexts:FindChild("OptionsDialogueControls"), self)
	self.wndDataTexts:FindChild("OptionsDialogueControls"):DestroyChildren()
	for strName, tData in pairs(self.DataTexts) do
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "DataTextOptionItem", self.wndDataTexts:FindChild("OptionsDialogueControls"), self)
		local bShownTop = self.db.profile.tDTOptions[strName]["bShownTop"]
		local bShownBot = self.db.profile.tDTOptions[strName]["bShownBot"]
		
		wndCurr:SetName(strName)
		wndCurr:FindChild("Name"):SetText(strName)
		wndCurr:FindChild("Top"):SetCheck(bShownTop)
		wndCurr:FindChild("Bottom"):SetCheck(bShownBot)
	end
	
	self.wndDataTexts:FindChild("OptionsDialogueControls"):ArrangeChildrenVert()
	
	local tAnchors = {self.wndOptions:GetAnchorOffsets()}
	self.wndDataTexts:SetAnchorOffsets(unpack(tAnchors))
	self.wndOptions:Show(false)
	self.wndDataTexts:Show(true)
end

function StarPanel:OnUpdateIntervalChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local val = round(fNewValue, 2)
	self.db.profile.dataTexts.nUpdateInterval = val
	wndControl:GetParent():FindChild("EditBox"):SetText(val)
	self.timerUpdate:Set(val)
	self.timerUpdate:Start()
end
---------------------------------------------------------------------------------------------------
-- OptionsDialogue Functions
---------------------------------------------------------------------------------------------------
function StarPanel:OnOptionsCloseClick( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Show(false)
end

---------------------------------------------------------------------------------------------------
-- DataTextsDialogue Functions
---------------------------------------------------------------------------------------------------

function StarPanel:OnDataTextsOptionsCloseClick( wndHandler, wndControl, eMouseButton )
	local tAnchors = {self.wndDataTexts:GetAnchorOffsets()}
	self.wndOptions:SetAnchorOffsets(unpack(tAnchors))
	self.wndDataTexts:Show(false)
	self.wndOptions:Show(true)
end

---------------------------------------------------
--				Profiles
---------------------------------------------------

function StarPanel:OnNewProfileReturn( wndHandler, wndControl, strText )
	if strText == "" then return end
	self.db:SetProfile(strText)
	self.db.char.currentProfile = strText
	wndControl:SetText("")
	self.wndOptions:Show(false, true)
	StarPanel:OnDocLoaded()
end

function StarPanel:OnDeleteProfileDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndDeleteProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()	
	
	for name, value in pairs(self.db:GetProfiles()) do
		if value ~= self.db:GetCurrentProfile() then
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndDeleteProfileDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(value)
		
		currButton:AddEventHandler("ButtonUp", "OnDeleteProfileItemClick")
		end
	end
		
	self.wndDeleteProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	self.wndDeleteProfileDropdownBox:Show(true)
end

function StarPanel:OnDeleteProfileItemClick( wndHandler, wndControl, eMouseButton )
	self.wndDeleteProfileDropdownBox:Show(false)
	self.wndConfirmAlert:FindChild("NoticeText"):SetText("Are you sure you want to delete "..wndControl:GetText().."?")
	self.wndConfirmAlert:FindChild("Profile"):SetText(wndControl:GetText())
	self.wndConfirmAlert:FindChild("YesButton"):AddEventHandler("ButtonUp", "OnConfirmYes")
	self.wndConfirmAlert:FindChild("NoButton"):AddEventHandler("ButtonUp", "OnConfirmNo")
	self.wndConfirmAlert:FindChild("NoButton2"):AddEventHandler("ButtonUp", "OnConfirmNo")
	self.wndConfirmAlert:Show(true)
	self.wndConfirmAlert:ToFront()
end

function StarPanel:OnConfirmYes(wndHandler, wndControl, eMouseButton)
	local profile = wndControl:GetParent():FindChild("Profile"):GetText()
	self.db:DeleteProfile(profile, true)
	wndControl:GetParent():Show(false)
end

function StarPanel:OnConfirmNo(wndHandler, wndControl, eMouseButton)
	wndControl:GetParent():Show(false)
end

function StarPanel:OnCurrentProfileDropdownClick( wndHandler, wndControl, eMouseButton )
	
	self.wndCurrentProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()	
	
	for name, value in pairs(self.db:GetProfiles()) do
		if value ~= self.db:GetCurrentProfile() then
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndCurrentProfileDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(value)
		
		currButton:AddEventHandler("ButtonUp", "OnCurrentProfileItemClick")
		end
	end
		
	self.wndCurrentProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	self.wndCopyProfileDropdown:Enable(false)
	self.wndCurrentProfileDropdownBox:Show(true)
end

function StarPanel:OnCurrentProfileItemClick( wndHandler, wndControl, eMouseButton )
	self.wndCurrentProfileDropdown:SetText(wndControl:GetText())
	
	self.db:SetProfile(wndControl:GetText())
	
	self.db.char.currentProfile = wndControl:GetText()
	
	self.wndCurrentProfileDropdownBox:Show(false)
	
	StarPanel:SetOptions()
end

function StarPanel:OnCurrentDropHide( wndHandler, wndControl )
	self.wndCopyProfileDropdown:Enable(true)
end

function StarPanel:OnCopyFromDropdownClick( wndHandler, wndControl, eMouseButton )
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

function StarPanel:OnCopyProfileItemClick( wndHandler, wndControl, eMouseButton )
	self.wndCopyProfileDropdown:SetText(wndControl:GetText())
	
	self.db:CopyProfile(wndControl:GetText(), false)
	
	self.wndCopyProfileDropdownBox:Show(false)
	
	StarPanel:SetOptions()
end
