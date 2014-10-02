-- ColorPicker: A Tojaso FowlPlay Project
-- Authors: Jaslm and Tomber, all rights reserved

require "GameLib"
require "Window"

ColorPicker = {}
local lastTime, updateTime = 0, 0 -- used to throttle updates triggered by mouse moves
local updateThrottle = 0.05 -- time in seconds between updates
local mouseInRing, mouseInGradient = false, false -- keep track of where mouse was clicked
local focusWidth, focusHeight, ringWidth, ringHeight, gradientWidth, gradientHeight, graderWidth, graderHeight
local selectWidth, selectHeight, rsquareMin, rsquareMax, radius
local ringEdge = 2 -- number of pixels ring is inset in the form
local ringThick = 25 -- thickness of the ring in pixels
local hue, saturation, brightness, alpha = 0, 1, 0.5, 1 -- current color value in HSV
local showAlpha = true -- if false hide the alpha-related controls and act like alpha is 1.0
local oldColor = CColor.new(1, 0, 0, 1) -- default first time open with slash command
local newColor = CColor.new(1, 1, 1, 1) -- set to the color that is being updated, overwriting this init value
local ccColor = {} -- buffer for copy and paste function
local ccValid = false -- don't display the copy buffer until it is valid
local c_white = CColor.new(1, 1, 1, 1)
local c_select = CColor.new(1, 0, 0, 1)
local callback = nil
local parameter = nil

-- Convert r, g, b input values into h, s, l return values
local function Convert_RGB_To_HSV(r, g, b)
	local mincolor, maxcolor = math.min(r, g, b), math.max(r, g, b)
	local ch, cs, cv = 0, 0, maxcolor
	if maxcolor > 0 then -- technically ch is undefined if cs is zero
		local delta = maxcolor - mincolor
		cs = delta / maxcolor
		if delta > 0 then -- don't allow divide by zero
			if r == maxcolor then
				ch = (g - b) / delta -- between yellow and magenta
			elseif g == maxcolor then
				ch = 2 + ((b - r) / delta) -- between cyan and yellow
			else
				ch = 4 + ((r - g) / delta) -- between magenta and cyan
			end
		end
		if ch < 0 then ch = ch + 6 end -- correct for negative values
		ch = ch / 6 -- and finally adjust range 0 to 1.0
	end
	return ch, cs, cv
end

-- Convert h, s, l input values into r, g, b return values
-- All values are in the range 0 to 1.0
local function Convert_HSV_To_RGB(ch, cs, cv)
	local r, g, b = cv, cv, cv
	if cs > 0 then -- if cs is zero then grey is returned
		local h = ch * 6; local sextant = math.floor(h) -- figure out which sextant of the color wheel
		local fract = h - sextant -- fractional offset into the sextant
		local p, q, t = cv * (1 - cs), cv * (1 - (cs * fract)), cv * (1 - (cs * (1 - fract)))
		if sextant == 0 then
			r, g, b = cv, t, p
		elseif sextant == 1 then
			r, g, b = q, cv, p
		elseif sextant == 2 then
			r, g, b = p, cv, t
		elseif sextant == 3 then
			r, g, b = p, q, cv
		elseif sextant == 4 then
			r, g, b = t, p, cv
		else
			r, g, b = cv, p, q
		end
	end
	return r, g, b
end

-- Convert r, g, b values (in range 0 to 1.0) into a hex-encoded string using format "rrggbb"
local function Convert_RGB_To_String(r, g, b)
	return string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- Convert a hex-encoded string into r, g, b values, string format is assumed to be "rrggbb"
local function Convert_String_To_RGB(hex)
	local r, g, b = 0, 0, 0 -- invalid strings will result in these values being returned
	local n = tonumber(hex, 16)
	if n then r = math.floor(n / 65536); g = math.floor(n / 256) % 256; b = n % 256 end
	return r / 255, g / 255, b / 255
end

-- Convert a color value in range 0 to 1.0 to string for range 0 to 255
local function CT(x) return tostring(math.floor(x * 255 + 0.5)) end

-- Addon initialization and registration
function ColorPicker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function ColorPicker:Init()
    Apollo.RegisterAddon(self)
end

-- Update values in controls from current HSV value, assume already initialized cached form handlers
local function UpdateColorControls()
	local r, g, b = Convert_HSV_To_RGB(hue, saturation, brightness)
	local cp = ColorPicker
	cp.select:SetBGColor(mouseInRing and c_select or c_white) -- display focus indicator when changing ring
	cp.grader:SetBGColor(mouseInGradient and c_select or c_white) -- display focus indicator when changing gradient
	
	cp.oldTop:SetBGColor(CColor.new(oldColor.r, oldColor.g, oldColor.b, oldColor.a))
	cp.oldBottom:SetBGColor(CColor.new(oldColor.r, oldColor.g, oldColor.b, oldColor.a))
	cp.newColor:SetBGColor(CColor.new(r, g, b, alpha)) -- use color passed in thru API
	
	newColor.r = r; newColor.g = g; newColor.b = b; newColor.a = alpha -- update the current color value
	
	cp.red:SetText(CT(r)); cp.green:SetText(CT(g)); cp.blue:SetText(CT(b))
	local a = math.floor(alpha * 100 + 0.5) -- round alpha to nearest integer 0 to 100
	cp.alpha:SetText(string.format("%0.0f", a)); cp.slider:SetValue(a)
	cp.hex:SetText(Convert_RGB_To_String(r, g, b))
	
	r, g, b = Convert_HSV_To_RGB(hue, 1, 1)
	cp.olay:SetBGColor(CColor.new(r, g, b, 1))
	local ch = hue -- use this to adjust color selection point
	ch = hue - 0.25; if ch < 0 then ch = ch + 1 end -- rotate to correct orientation
	local theta = ch * 2 * math.pi -- convert to radians
	local offL, offT, offR, offB = cp.ring:GetAnchorOffsets()
	local cx = radius * math.cos(theta)
	local cy = radius * math.sin(theta)
	local dL = offL + ringWidth + cx
	local dT = offT + ringHeight + cy
	offL = dL - selectWidth + ringEdge; offT = dT - selectHeight + ringEdge
	offR = dL + selectWidth + ringEdge; offB = dT + selectHeight + ringEdge
	cp.select:SetAnchorOffsets(offL, offT, offR, offB)

	local rx = ((saturation * 2) - 1) * gradientWidth -- use saturation and brightness to adjust gradient selection point
	local ry = (((brightness - 1) * -2) - 1) * gradientHeight
	dL = gradientWidth + rx; dT = gradientHeight + ry
	offL = dL - graderWidth; offT = dT - graderHeight
	offR = dL + graderWidth; offB = dT + graderHeight
	cp.grader:SetAnchorOffsets(offL, offT, offR, offB)
	
	cp.hint:Show(Apollo.IsControlKeyDown()) -- display hint when the control key is held down
	cp.copy:Show(ccValid); cp.paste:Show(ccValid) -- only display the copy buffer and paste button after a copy has been made
	if ccValid then
		r, g, b = Convert_HSV_To_RGB(ccColor.hue, ccColor.saturation, ccColor.brightness)
		cp.copy:SetBGColor(CColor.new(r, g, b, 1))
	end
	
	cp.alphabox:Show(showAlpha); cp.slider:Show(showAlpha); cp.sframe:Show(showAlpha); cp.back:Show(showAlpha)
	if type(callback) == "function" then callback(parameter) end
end

-- Clear the focus from all the text boxes
local function ClearFocus()
	local cp = ColorPicker
	cp.red:ClearFocus(); cp.green:ClearFocus(); cp.blue:ClearFocus(); cp.hex:ClearFocus(); cp.alpha:ClearFocus()
end

-- At load time, plug in our custom images
function ColorPicker:OnLoad()
	Apollo.RegisterSlashCommand("colorpicker", "OnColorPickerOn", self)
	Apollo.RegisterSlashCommand("color", "OnColorPickerOn", self)

	self.wndMain = Apollo.LoadForm("ColorPicker.xml", "ColorPickerForm", nil, self)
	self.wndMain:Show(false) -- hide the window by default
	Apollo.LoadSprites("ColorPickerSprites.xml", "ColorPickerSprites")
	callback = nil; parameter = nil

	local cp = ColorPicker
	cp.window = self.wndMain
	cp.ring = self.wndMain:FindChild("ColorRing")
	cp.rframe = self.wndMain:FindChild("ColorRingFrame")
	cp.olay = self.wndMain:FindChild("ColorOverlay")
	cp.grad = self.wndMain:FindChild("ColorGradient")
	cp.gframe = self.wndMain:FindChild("ColorGradientFrame")
	cp.back = self.wndMain:FindChild("Checkerboard")
	cp.select = self.wndMain:FindChild("ColorSelector")
	cp.oldTop = self.wndMain:FindChild("OldColorTop")
	cp.oldBottom = self.wndMain:FindChild("OldColorBottom")
	cp.newColor = self.wndMain:FindChild("NewColor")
	cp.grader = cp.olay:FindChild("ColorSelector")
	cp.red = self.wndMain:FindChild("RedBox"):FindChild("Editor")
	cp.green = self.wndMain:FindChild("GreenBox"):FindChild("Editor")
	cp.blue = self.wndMain:FindChild("BlueBox"):FindChild("Editor")
	cp.hex = self.wndMain:FindChild("HexBox"):FindChild("Editor")
	cp.alphabox = self.wndMain:FindChild("AlphaBox")
	cp.alpha = cp.alphabox:FindChild("Editor")
	cp.slider = self.wndMain:FindChild("AlphaSlider")
	cp.sframe = self.wndMain:FindChild("AlphaBackground")
	cp.hint = self.wndMain:FindChild("Hint")
	cp.copy = self.wndMain:FindChild("CopyColor")
	cp.paste = self.wndMain:FindChild("PasteButton")
	assert(cp.ring and cp.rframe and cp.olay and cp.grad and cp.gframe and cp.back and cp.select and cp.grader and cp.slider and cp.sframe and
		cp.oldTop and cp.oldBottom and cp.newColor and cp.red and cp.green and cp.blue and cp.hex and cp.alpha and cp.alphabox and cp.hint and cp.copy and cp.paste,
		"ColorPicker: form initialization error")

	cp.ring:SetSprite("ColorPickerSprites:sprColorRing")
	cp.grad:SetSprite("ColorPickerSprites:sprColorGradient")
	cp.olay:SetSprite("ColorPickerSprites:sprColorOverlay")
	cp.olay:SetBGColor(CColor.new(1, 0, 0, 1))
	cp.back:SetSprite("ColorPickerSprites:sprCheckerboard")

	focusWidth = cp.rframe:GetWidth() / 2; focusHeight = cp.rframe:GetHeight() / 2
	ringWidth = cp.ring:GetWidth() / 2; ringHeight = cp.ring:GetHeight() / 2
	local w = ringWidth - ringEdge; rsquareMax = (w * w); radius = w - (ringThick / 2) - ringEdge
	w = w - ringThick; rsquareMin = (w * w)
	gradientWidth = cp.olay:GetWidth() / 2; gradientHeight = cp.olay:GetHeight() / 2
	graderWidth = cp.grader:GetWidth() / 2; graderHeight = cp.grader:GetHeight() / 2
	selectWidth = cp.select:GetWidth() / 2; selectHeight = cp.select:GetHeight() / 2

	UpdateColorControls() -- set initial value of HSV into the controls
end

-- API to display the color picker dialog for a color object, optionally with alpha-related controls
-- Don't return until the dialog is closed, restore original color if cancelled
-- The function cb is called with the parameter pm whenever the color may have been changed (optional)
function ColorPicker.AdjustCColor(color, hasAlpha, cb, pm)
	local cp = ColorPicker
	oldColor.r = color.r; oldColor.g = color.g; oldColor.b = color.b; oldColor.a = color.a
	newColor = color
	callback = cb; parameter = pm
	hue, saturation, brightness = Convert_RGB_To_HSV(color.r, color.g, color.b)
	if hasAlpha then alpha = color.a else alpha = 1 end
	showAlpha = hasAlpha
	UpdateColorControls() -- update current color value in controls
	cp.window:Show(true) -- show the window
	cp.window:ToFront() -- bring it to the front
end

-- Respond to registered slash commands
function ColorPicker:OnColorPickerOn()
	hue, saturation, brightness = Convert_RGB_To_HSV(oldColor.r, oldColor.g, oldColor.b)
	alpha = oldColor.a
	showAlpha = true
	newColor = CColor.new(1, 1, 1, 1)
	callback = nil; parameter = nil
	UpdateColorControls() -- update current color value in controls
	self.wndMain:Show(true) -- show the window
	self.wndMain:ToFront() -- bring it to the front
end

-- Process a click in the color or gradient selection areas
local function ColorPickerMouseEvent(wndHandler, wndControl, event, x, y)
	local cp = ColorPicker
	local now = GameLib.GetGameTime(); local elapsedTime = now - lastTime; lastTime = now
	local forced = false
	updateTime = updateTime + elapsedTime
	local rx, ry = x - focusWidth, y - focusHeight -- get mouse position as ring coordinates from center of focus
	local rsquare = (rx * rx) + (ry * ry)
	local inRing = (rsquare >= rsquareMin) and (rsquare <= rsquareMax) -- figure out if in the ring
	local inGradient = (math.abs(rx) <= gradientWidth) and (math.abs(ry) <= gradientHeight)
	if event == "down" then -- handle mouse clicks
		if inRing and not mouseInGradient then mouseInRing = true; forced = true end
		if inGradient and not mouseInRing then mouseInGradient = true; forced = true end
		ClearFocus()
	elseif (event == "up" or event == "exit") and (mouseInRing or mouseInGradient) then
		mouseInRing = false; mouseInGradient = false; forced = true
		UpdateColorControls() -- display current value in the controls
	end
	if forced or updateTime >= updateThrottle then
		if mouseInRing then
			local theta = math.atan2(ry, rx)
			if theta < 0 then theta = theta + (2 * math.pi) end
			hue = theta / (2 * math.pi) -- hue is angle in the range 0 to 1.0
			if Apollo.IsControlKeyDown() then hue = math.floor((hue * 24) + 0.5) / 24 end -- if control key then snap to nearest standard-ish color
			hue = hue + 0.25; if hue >= 1 then hue = hue - 1 end -- rotate to correct orientation
			UpdateColorControls() -- display current value in the controls
		elseif mouseInGradient then
			if rx > gradientWidth then rx = gradientWidth elseif rx < -gradientWidth then rx = -gradientWidth end
			if ry > gradientHeight then ry = gradientHeight elseif ry < -gradientHeight then ry = -gradientHeight end
			saturation = (1 + (rx / gradientWidth)) / 2
			brightness = 1 - ((1 + (ry / gradientHeight)) / 2)
			if Apollo.IsControlKeyDown() then -- if control key then snap to nearest 1/8
				saturation = math.floor((saturation * 8) + 0.5) / 8; brightness = math.floor((brightness * 8) + 0.5) / 8
			end
			UpdateColorControls() -- display current value in the controls
		end
		updateTime = 0; forced = false
	end
	cp.hint:Show(Apollo.IsControlKeyDown()) -- only display hint when the control key is being held down
end

-- Respond to OK button click
function ColorPicker:OnOK()
	local r, g, b = Convert_HSV_To_RGB(hue, saturation, brightness)
	oldColor.r = r; oldColor.g = g; oldColor.b = b -- save current color in original color for next time
	callback = nil; parameter = nil
	self.wndMain:Show(false) -- hide the window
end

-- Respond to Cancel button click
function ColorPicker:OnCancel()
	newColor.r = oldColor.r; newColor.g = oldColor.g; newColor.b = oldColor.b; newColor.a = oldColor.a -- revert to original color
	if type(callback) == "function" then callback(parameter) end
	callback = nil; parameter = nil
	self.wndMain:Show(false) -- hide the window
end

-- Respond to mouse button down in the color selection ring
function ColorPicker:OnMouseDownColor(wndHandler, wndControl, key, x, y)
	if key == 0 then ColorPickerMouseEvent(wndHandler, wndControl, "down", x, y) end
end

-- Respond to mouse move events in the color selection ring
function ColorPicker:OnMouseMoveColor(wndHandler, wndControl, x, y)
	ColorPickerMouseEvent(wndHandler, wndControl, "move", x, y)
end

-- Respond to mouse button up in the color selection ring
function ColorPicker:OnMouseUpColor(wndHandler, wndControl, key, x, y)
	if key == 0 then ColorPickerMouseEvent(wndHandler, wndControl, "up", x, y) end
end

-- Respond to mouse exit events in the color selection ring
function ColorPicker:OnMouseExitColor(wndHandler, wndControl)
	ColorPickerMouseEvent(wndHandler, wndControl, "exit", 0, 0)
end

-- Respond to text changes in the red, green or blue box, managing the selection and focus appropriately
-- Try to convert to a number, if valid and in range then update current setting
function ColorPicker:OnColorChanged(wndHandler, wndControl, s)
	local cp = ColorPicker
	local rflag, gflag, bflag = false, false, false
	local rs = cp.red:GetText(); if rs == "" then rs = "0"; rflag = true end
	local gs = cp.green:GetText(); if gs == "" then gs = "0"; gflag = true end
	local bs = cp.blue:GetText(); if bs == "" then bs = "0"; bflag = true end
	local r, g, b = tonumber(rs), tonumber(gs), tonumber(bs)
	if r and r >= 0 and r <= 255 and g and g >= 0 and g <= 255 and b and b >= 0 and b <= 255 then
		hue, saturation, brightness = Convert_RGB_To_HSV(r / 255, g / 255, b / 255)
	end
	UpdateColorControls() -- update current color values
	if rflag then cp.red:SetText("") else r = cp.red:GetText(); if r then cp.red:SetSel(r:len(), -1) end end
	if gflag then cp.green:SetText("") else g = cp.green:GetText(); if g then cp.green:SetSel(g:len(), -1) end end
	if bflag then cp.blue:SetText("") else b = cp.blue:GetText(); if b then cp.blue:SetSel(b:len(), -1) end end
end

-- Respond to text changes in the hex box, managing the selection and focus appropriately
-- Try to convert to a hex number, if valid length and format
function ColorPicker:OnHexChanged(wndHandler, wndControl, s)
	local cp = ColorPicker
	local ht = cp.hex:GetText()
	if not ht or ht:len() ~= 6 then return end
	local r, g, b = Convert_String_To_RGB(ht)
	hue, saturation, brightness = Convert_RGB_To_HSV(r, g, b)
	UpdateColorControls() -- update current color values
	cp.hex:SetSel(6, -1)
end

-- Respond to text changes in the alpha box, managing the selection and focus appropriately
-- Try to convert to a number in the range 0 to 100
function ColorPicker:OnAlphaChanged(wndHandler, wndControl, s)
	local cp = ColorPicker
	local aflag = false
	local at = cp.alpha:GetText(); if at == "" then at = "0"; aflag = true end
	local a = tonumber(at)
	if a then alpha = a / 100; if alpha < 0 then alpha = 0 elseif alpha > 1 then alpha = 1 end end
	UpdateColorControls() -- update current color values
	if aflag then cp.alpha:SetText("") else at = cp.alpha:GetText(); if at then cp.alpha:SetSel(at:len(), -1) end end
end

-- Respond to alpha slider changes
function ColorPicker:OnAlphaChanging(wndHandler, wndControl, x)
	alpha = x / 100
	UpdateColorControls() -- update current color values
	ClearFocus()
end

-- Respond to copy and paste buttons
function ColorPicker:OnCopyButton()
	ccColor.hue = hue; ccColor.saturation = saturation; ccColor.brightness = brightness -- save the current color in the copy buffer
	ccValid = true; UpdateColorControls(); ClearFocus()
end

function ColorPicker:OnPasteButton()
	if ccValid then hue = ccColor.hue; saturation = ccColor.saturation; brightness = ccColor.brightness end -- set the current color to the copy buffer
	UpdateColorControls(); ClearFocus()
end

-- Finally, just need to instantiate the color picker addon...
local ColorPickerInst = ColorPicker:new()
ColorPickerInst:Init()
