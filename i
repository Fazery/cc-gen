-- Haki Ware Final Edition: WalkSpeed Bypass + TriggerBot + Hitbox Expander + Silent Aim + UI
-- Author: lzfv + focus09308 + ChatGPT Enhanced

local repo = 'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/'

local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/polarsblade/blazebackup/main/main'))()
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/polarsblade/blazebackup/main/theme'))()
local SaveManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/polarsblade/blazebackup/main/config'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local CurrentTarget = nil

local Window = Library:CreateWindow({
    Title = 'Haki Ware | Get Better Get Haki Ware',
    Center = true,
    AutoShow = false,
    TabPadding = 4,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Settings = Window:AddTab('Settings'),
    Credits = Window:AddTab('Credits')
}

local MainBox = Tabs.Main:AddLeftGroupbox('Main')

-- Toggles
MainBox:AddToggle('Camlock', { Text = 'Camlock', Default = false })
Toggles.Camlock:AddKeyPicker('CamlockBind', { Default = 'Q', SyncToggleState = true, Mode = 'Toggle', Text = 'Camlock Keybind' })

-- Silent Aim toggle added here as second toggle
MainBox:AddToggle('SilentAim', { Text = 'Silent Aim', Default = false })

MainBox:AddInput('Prediction', { Default = '0.15', Numeric = true, Finished = true, Text = 'Prediction' })
MainBox:AddInput('Smoothing', { Default = '0.1', Numeric = true, Finished = true, Text = 'Smoothing' })

MainBox:AddSlider('Walkspeed', { Text = 'Walkspeed', Default = 16, Min = 16, Max = 500, Rounding = 0 })

MainBox:AddToggle('TriggerBot', { Text = 'Trigger Bot', Default = false })

-- Hitbox Expander UI
MainBox:AddToggle('HitboxExpander', { Text = 'Hitbox Expander', Default = false })
MainBox:AddSlider('HitboxSize', { Text = 'Hitbox Size', Default = 5, Min = 1, Max = 15, Rounding = 1 })
MainBox:AddToggle('HitboxVisible', { Text = 'Hitbox Visible', Default = false }) -- Visible toggle

local TriggerBotEnabled = false

local function setWalkSpeed(speed)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = speed
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if hum.WalkSpeed ~= Options.Walkspeed.Value then
                hum.WalkSpeed = Options.Walkspeed.Value
            end
        end)
    end
end

Options.Walkspeed:OnChanged(setWalkSpeed)
LocalPlayer.CharacterAdded:Connect(function(char)
    repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
    setWalkSpeed(Options.Walkspeed.Value)
end)

local function IsKO(player)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return not humanoid or humanoid.Health <= 0
end

local function WallCheck(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    return raycastResult and raycastResult.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetClosestPlayer()
    local closest, shortestDist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and not IsKO(player) and WallCheck(player.Character.HumanoidRootPart) then
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if Toggles.Camlock.Value and CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("HumanoidRootPart") then
        local humanoid = CurrentTarget.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 1 then
            Toggles.Camlock:SetValue(false)
            CurrentTarget = nil
            return
        end

        local pred = tonumber(Options.Prediction.Value) or 0.15
        local smooth = tonumber(Options.Smoothing.Value) or 0.1
        local root = CurrentTarget.Character.HumanoidRootPart
        local predicted = root.Position + (root.Velocity * pred)

        local currentCFrame = Camera.CFrame
        local targetCFrame = CFrame.new(Camera.CFrame.Position, predicted)
        Camera.CFrame = currentCFrame:Lerp(targetCFrame, smooth)
    end
end)

Options.CamlockBind:OnClick(function()
    if Toggles.Camlock.Value then
        CurrentTarget = GetClosestPlayer()
    else
        CurrentTarget = nil
    end
end)

Toggles.TriggerBot:OnChanged(function(val)
    TriggerBotEnabled = val
end)

local VirtualUser = game:GetService("VirtualUser")

local function Fire()
    VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end

RunService.RenderStepped:Connect(function()
    if not TriggerBotEnabled then return end

    if Toggles.SilentAim.Value then
        -- Silent Aim: Always fire at predicted closest target without mouse proximity check
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and not IsKO(target) then
            local root = target.Character.HumanoidRootPart
            local pred = tonumber(Options.Prediction.Value) or 0.15
            local predictedPos = root.Position + (root.Velocity * pred)

            if WallCheck(root) then
                Fire()
            end
            return
        end
    else
        -- Normal TriggerBot logic with mouse proximity check
        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and not IsKO(player) and WallCheck(player.Character.HumanoidRootPart) then
                local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                if onScreen and (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude < 40 then
                    Fire()
                    break
                end
            end
        end
    end
end)

-- Hitbox Expander Logic with Visibility Fix
local HitboxExpandedPlayers = {}

local function ExpandHitbox(player, size, visible)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not HitboxExpandedPlayers[player] then
        HitboxExpandedPlayers[player] = {
            OriginalSize = hrp.Size,
            OriginalTransparency = hrp.Transparency,
            OriginalCanCollide = hrp.CanCollide,
            SelectionBox = nil
        }
    end

    local data = HitboxExpandedPlayers[player]
    hrp.Size = Vector3.new(size, size, size)
    hrp.CanCollide = false

    if visible then
        hrp.Transparency = 0.5 -- partially transparent so visible but not fully blocking
        -- Create SelectionBox if not exist
        if not data.SelectionBox then
            local selBox = Instance.new("SelectionBox")
            selBox.Adornee = hrp
            selBox.Color3 = Color3.new(1, 0, 0)
            selBox.LineThickness = 0.05
            selBox.SurfaceTransparency = 0.7
            selBox.Parent = hrp
            data.SelectionBox = selBox
        end
    else
        hrp.Transparency = 1 -- fully invisible
        if data.SelectionBox then
            data.SelectionBox:Destroy()
            data.SelectionBox = nil
        end
    end
end

local function ResetHitbox(player)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local data = HitboxExpandedPlayers[player]
    if hrp and data then
        hrp.Size = data.OriginalSize
        hrp.Transparency = data.OriginalTransparency
        hrp.CanCollide = data.OriginalCanCollide
        if data.SelectionBox then
            data.SelectionBox:Destroy()
            data.SelectionBox = nil
        end
        HitboxExpandedPlayers[player] = nil
    end
end

local function UpdateHitboxes()
    local enabled = Toggles.HitboxExpander.Value
    local size = Options.HitboxSize.Value
    local visible = Toggles.HitboxVisible.Value

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if enabled and not IsKO(player) then
                ExpandHitbox(player, size, visible)
            else
                ResetHitbox(player)
            end
        end
    end
end

RunService.Heartbeat:Connect(UpdateHitboxes)

Tabs.Credits:AddLeftGroupbox("Credits"):AddLabel("Made by: lzfv & focus09308")

local MenuGroup = Tabs.Settings:AddLeftGroupbox('UI')
MenuGroup:AddLabel('Toggle UI'):AddKeyPicker('MenuKeybind', { Default = 'LeftAlt', NoUI = false, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind

StarterGui:SetCore("SendNotification", {
    Title = "Haki Ware",
    Text = "Loaded Successfully!",
    Duration = 5
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('HakiWare')
SaveManager:SetFolder('HakiWare/Game')
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
