--[[
=====================================================================
   SCRIPT ADMIN + TAG « Créateur ✔ »   --   pour Delta Executor
=====================================================================
   PC     : touche F pour ouvrir / fermer le menu
   Mobile : bouton ☰ en haut à gauche (déplaçable)
   Chat   : ;fly  ;noclip  ;speed 60  ;god  ;tp Pseudo  ;rejoin  ;tag
=====================================================================
]]

if _G.__AdminCleanup then pcall(_G.__AdminCleanup) end

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local StarterGui      = game:GetService("StarterGui")
local CoreGui         = game:GetService("CoreGui")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- Palette
local ACCENT = Color3.fromRGB(29, 161, 242)
local BG     = Color3.fromRGB(18, 18, 22)
local BG2    = Color3.fromRGB(30, 30, 38)
local BG3    = Color3.fromRGB(46, 46, 58)
local TXT    = Color3.fromRGB(235, 235, 245)
local TXT2   = Color3.fromRGB(150, 150, 168)

local conns = {}
local function bind(c) conns[#conns + 1] = c; return c end

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props or {}) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
	end)
end

local state = {
	fly = false, noclip = false, infJump = false, god = false,
	speed = 16, flySpeed = 60, up = false, down = false,
}

local keys = {}

------------------------------------------------------------
-- Récupération de la direction de déplacement (PC + mobile)
------------------------------------------------------------
local controls
do
	local ok, res = pcall(function()
		local pm = LP:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
		if not pm then return nil end
		return require(pm):GetControls()
	end)
	if ok and res then controls = res end
end

local function getMoveVector()
	local v = Vector3.zero
	if controls then
		local ok, res = pcall(function() return controls:GetMoveVector() end)
		if ok and res then v = res end
	end
	if v.Magnitude == 0 then
		if keys[Enum.KeyCode.W] then v = v + Vector3.new(0, 0, -1) end
		if keys[Enum.KeyCode.S] then v = v + Vector3.new(0, 0, 1) end
		if keys[Enum.KeyCode.A] then v = v - Vector3.new(1, 0, 0) end
		if keys[Enum.KeyCode.D] then v = v + Vector3.new(1, 0, 0) end
	end
	return v
end

------------------------------------------------------------
-- TAG « Créateur ✔ » au-dessus de la tête
------------------------------------------------------------
local TAG_TEXT   = "Créateur"
local tagEnabled = true
local tagAll     = false

local function removeTag(plr)
	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	if head then
		local old = head:FindFirstChild("CreatorTag")
		if old then old:Destroy() end
	end
end

local function addTag(plr)
	if not tagEnabled then return end
	if not tagAll and plr ~= LP then return end

	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	if not head or head:FindFirstChild("CreatorTag") then return end

	local bb = new("BillboardGui", {
		Name = "CreatorTag",
		Size = UDim2.new(0, 240, 0, 44),
		StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 150,
		ResetOnSpawn = false,
		Adornee = head,
	}, head)

	local pill = new("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 28),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = BG,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, bb)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
	new("UIStroke", { Color = ACCENT, Thickness = 1.5, Transparency = 0.15 }, pill)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
	}, pill)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, pill)

	new("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = TAG_TEXT,
		TextColor3 = TXT,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		LayoutOrder = 1,
	}, pill)

	-- pastille certifiée
	local badge = new("Frame", {
		Size = UDim2.new(0, 15, 0, 15),
		BackgroundColor3 = ACCENT,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	}, pill)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "✓",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
	}, badge)
end

local function refreshTags()
	for _, p in ipairs(Players:GetPlayers()) do
		if tagAll or p == LP then addTag(p) else removeTag(p) end
	end
end

------------------------------------------------------------
-- Vol
------------------------------------------------------------
local flyConn

local function stopFly()
	state.fly = false
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	local char = LP.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hrp then
			local bv = hrp:FindFirstChild("FlyBV"); if bv then bv:Destroy() end
			local bg = hrp:FindFirstChild("FlyBG"); if bg then bg:Destroy() end
		end
		if hum then hum.PlatformStand = false end
	end
end

local function startFly()
	local char = LP.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	state.fly = true
	hum.PlatformStand = true

	local bv = new("BodyVelocity", {
		Name = "FlyBV",
		MaxForce = Vector3.new(1e5, 1e5, 1e5),
		Velocity = Vector3.zero,
		P = 1250,
	}, hrp)

	local bg = new("BodyGyro", {
		Name = "FlyBG",
		MaxTorque = Vector3.new(1e5, 1e5, 1e5),
		P = 10000, D = 500,
		CFrame = hrp.CFrame,
	}, hrp)

	flyConn = RunService.RenderStepped:Connect(function()
		local c = LP.Character
		if not c then return end
		local root = c:FindFirstChild("HumanoidRootPart")
		if not root or not bv.Parent then return end

		local cam = workspace.CurrentCamera
		local dir = Vector3.zero

		local mv = getMoveVector()
		if mv.Magnitude > 0 then
			dir = cam.CFrame:VectorToWorldSpace(Vector3.new(mv.X, 0, mv.Z))
		end
		if state.up then dir = dir + Vector3.new(0, 1, 0) end
		if state.down then dir = dir - Vector3.new(0, 1, 0) end
		if dir.Magnitude > 0 then dir = dir.Unit end

		bv.Velocity = dir * state.flySpeed
		bg.CFrame = CFrame.new(root.Position) * cam.CFrame.Rotation
	end)
end

------------------------------------------------------------
-- Divers réglages
------------------------------------------------------------
local function setSpeed(v)
	state.speed = v
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = v end
end

local function setGod(on)
	state.god = on
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.MaxHealth = on and math.huge or 100
		hum.Health = on and math.huge or hum.MaxHealth
	end
end

local function tpTo(pos)
	local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end

local function applySettings()
	task.wait(0.3)
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = state.speed
		if state.god then hum.MaxHealth = math.huge; hum.Health = math.huge end
	end
end

------------------------------------------------------------
-- Interface
------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "AdminGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local ok = pcall(function() gui.Parent = CoreGui end)
if not ok or not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local function makeDraggable(frame, handle)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	bind(UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
end

-- Bouton d'ouverture
local toggle = new("TextButton", {
	Size = UDim2.new(0, 46, 0, 46),
	Position = UDim2.new(0, 20, 0, 90),
	BackgroundColor3 = ACCENT,
	Text = "☰",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
}, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, toggle)
new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.7 }, toggle)
makeDraggable(toggle, toggle)

-- Fenêtre principale
local win = new("Frame", {
	Size = UDim2.new(0, 252, 0, 390),
	Position = UDim2.new(0, 20, 0, 150),
	BackgroundColor3 = BG,
	BorderSizePixel = 0,
	Visible = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 14) }, win)
new("UIStroke", { Color = ACCENT, Thickness = 1.5, Transparency = 0.35 }, win)

local titleBar = new("Frame", {
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = BG2,
	BorderSizePixel = 0,
}, win)
new("UICorner", { CornerRadius = UDim.new(0, 14) }, titleBar)
new("Frame", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.new(0, 0, 1, -14),
	BackgroundColor3 = BG2,
	BorderSizePixel = 0,
}, titleBar)
new("TextLabel", {
	Size = UDim2.new(1, -50, 1, 0),
	Position = UDim2.new(0, 14, 0, 0),
	BackgroundTransparency = 1,
	Text = "ADMIN  •  Créateur ✔",
	TextColor3 = TXT,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)
makeDraggable(win, titleBar)

local close = new("TextButton", {
	Size = UDim2.new(0, 26, 0, 26),
	Position = UDim2.new(1, -34, 0.5, -13),
	BackgroundColor3 = BG3,
	Text = "✕",
	TextColor3 = TXT,
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
}, titleBar)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, close)

local content = new("ScrollingFrame", {
	Size = UDim2.new(1, -20, 1, -52),
	Position = UDim2.new(0, 10, 0, 44),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = ACCENT,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, win)
new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, content)
new("UIPadding", { PaddingBottom = UDim.new(0, 10) }, content)

local order = 0
local function nextOrder() order += 1; return order end

local function makeBtn(text, onClick)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = BG2,
		Text = "  " .. text,
		TextColor3 = TXT,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		LayoutOrder = nextOrder(),
	}, content)
	new("UICorner", { CornerRadius = UDim.new(0, 9) }, b)
	b.TextXAlignment = Enum.TextXAlignment.Left

	b.MouseButton1Click:Connect(function()
		onClick(b)
		if not b:GetAttribute("Active") then
			b.BackgroundColor3 = BG3
			task.delay(0.1, function()
				if not b:GetAttribute("Active") then b.BackgroundColor3 = BG2 end
			end)
		end
	end)
	return b
end

local function setToggled(b, on)
	b:SetAttribute("Active", on)
	b.BackgroundColor3 = on and ACCENT or BG2
	b.TextColor3 = on and Color3.new(1, 1, 1) or TXT
end

local function makeSection(text)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = text:upper(),
		TextColor3 = TXT2,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
	}, content)
end

local function makeSlider(label, min, max, default, onChange)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(),
    }, content)

    local lbl = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = label .. " : " .. default,
        TextColor3 = TXT2,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)

    local bar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = BG2,
        BorderSizePixel = 0,
        Active = true,
    }, holder)

    new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    }, bar)

    local fill = new("Frame", {
        Size = UDim2.new(
            math.clamp((default - min) / (max - min), 0, 1),
            0, 1, 0
        ),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
    }, bar)

    new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    }, fill)

    local dragging = false

    local function update(input)
        local width = bar.AbsoluteSize.X
        if width <= 0 then return end

        local rel = math.clamp(
            (input.Position.X - bar.AbsolutePosition.X) / width,
            0, 1
        )

        local val = math.floor(min + (max - min) * rel)

        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = label .. " : " .. val

        onChange(val)
    end

    bind(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end))

    bind(UIS.InputChanged:Connect(function(input)
        if not dragging then return end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end))

    bind(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

------------------------------------------------------------
-- Clavier
------------------------------------------------------------
local function isTyping()
	return UIS:GetFocusedTextBox() ~= nil
end

bind(UIS.InputBegan:Connect(function(input, gpe)
	if gpe or isTyping() then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	keys[input.KeyCode] = true
	if input.KeyCode == Enum.KeyCode.F then
		win.Visible = not win.Visible
	elseif state.fly and input.KeyCode == Enum.KeyCode.Space then
		state.up = true
	elseif state.fly and input.KeyCode == Enum.KeyCode.LeftShift then
		state.down = true
	end
end))

bind(UIS.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	keys[input.KeyCode] = false
	if input.KeyCode == Enum.KeyCode.Space then state.up = false end
	if input.KeyCode == Enum.KeyCode.LeftShift then state.down = false end
end))

bind(UIS.JumpRequest:Connect(function()
	if not state.infJump then return end
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

------------------------------------------------------------
-- Boucles noclip / god
------------------------------------------------------------
bind(RunService.Stepped:Connect(function()
	if not state.noclip then return end
	local char = LP.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
	end
end))

bind(RunService.Heartbeat:Connect(function()
	if not state.god then return end
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
end))

bind(LP.CharacterAdded:Connect(function()
	task.wait(0.5)
	applySettings()
	refreshTags()
end))

------------------------------------------------------------
-- Actions du menu
------------------------------------------------------------
local function makeToggle(text, get, set)
	local b = makeBtn(text, function()
		local v = not get()
		set(v)
		setToggled(b, v)
		b.Text = "  " .. text .. (v and "   [ON]" or "   [OFF]")
	end)
	b.Text = "  " .. text .. (get() and "   [ON]" or "   [OFF]")
	setToggled(b, get())
	return b
end

makeSection("Déplacement")
makeToggle("Vol", function() return state.fly end,
	function(v) if v then startFly() else stopFly() end end)
makeToggle("Noclip", function() return state.noclip end,
	function(v) state.noclip = v end)
makeToggle("Saut infini", function() return state.infJump end,
	function(v) state.infJump = v end)
makeToggle("God mode", function() return state.god end,
	function(v) setGod(v) end)

makeSlider("Vitesse", 16, 300, state.speed, setSpeed)
makeSlider("Vitesse de vol", 10, 500, state.flySpeed, function(v) state.flySpeed = v end)

makeSection("Téléportation")
makeBtn("Aller au curseur", function()
	local hit = Mouse.Hit
	if hit then tpTo(hit.Position); notify("Admin", "Téléporté") end
end)
makeBtn("Rejoindre le serveur", function()
	notify("Admin", "Rejoindre...")
	TeleportService:Teleport(game.PlaceId, LP)
end)

makeSection("Tag Créateur")
makeToggle("Afficher mon tag", function() return tagEnabled end, function(v)
	tagEnabled = v; refreshTags()
end)
makeToggle("Tag sur tout le monde", function() return tagAll end, function(v)
	tagAll = v; refreshTags()
end)

makeSection("Système")
makeBtn("Retirer le menu", function()
	if _G.__AdminCleanup then _G.__AdminCleanup() end
end)

------------------------------------------------------------
-- Commandes chat
------------------------------------------------------------
bind(LP.Chatted:Connect(function(msg)
	local args = string.split(msg, " ")
	local cmd = string.lower(args[1] or "")
	local a2 = args[2]

	if cmd == ";fly" then
		state.fly = not state.fly
		if state.fly then startFly() else stopFly() end
		notify("Admin", "Vol " .. (state.fly and "activée" or "désactivée"))
	elseif cmd == ";noclip" then
		state.noclip = not state.noclip
		notify("Admin", "Noclip " .. (state.noclip and "activé" or "désactivé"))
	elseif cmd == ";god" then
		setGod(not state.god)
		notify("Admin", "God " .. (state.god and "activé" or "désactivé"))
	elseif cmd == ";speed" and a2 then
		local v = tonumber(a2)
		if v then setSpeed(v); notify("Admin", "Vitesse : " .. v) end
	elseif cmd == ";tp" and a2 then
		for _, p in ipairs(Players:GetPlayers()) do
			if string.sub(string.lower(p.Name), 1, #a2) == string.lower(a2) then
				local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if hrp then tpTo(hrp.Position); notify("Admin", "TP vers " .. p.Name) end
				break
			end
		end
	elseif cmd == ";rejoin" then
		TeleportService:Teleport(game.PlaceId, LP)
	elseif cmd == ";tag" then
		tagEnabled = not tagEnabled; refreshTags()
		notify("Admin", "Tag " .. (tagEnabled and "affiché" or "caché"))
	end
end))

------------------------------------------------------------
-- Nettoyage
------------------------------------------------------------
_G.__AdminCleanup = function()
	pcall(stopFly)
	for _, p in ipairs(Players:GetPlayers()) do pcall(removeTag, p) end
	if state.noclip and LP.Character then
		for _, p in ipairs(LP.Character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = true end
		end
	end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	table.clear(conns)
	pcall(function() gui:Destroy() end)
	_G.__AdminCleanup = nil
end

win.Visible = false
notify("Admin", "Menu chargé — F pour ouvrir")
