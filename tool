-- language: Luau, file: force_delete.lua, target: Roblox client executor
-- *PC only. LMB: Grab | RMB: Delete | E: Kill Target.*

local CoreGui      = game:GetService("CoreGui")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local Workspace    = game:GetService("Workspace")
local UserInput    = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

if LocalPlayer.Backpack:FindFirstChild("Kismur Force") then LocalPlayer.Backpack["Kismur Force"]:Destroy() end

local tool = Instance.new("Tool")
tool.Name = "Kismur Force"
tool.RequiresHandle = false
tool.CanBeDropped = false
tool.ToolTip = "LMB: Grab | RMB: Delete | E: Kill"
tool.Parent = LocalPlayer.Backpack

local isHolding = false
local targetPart = nil
local alignPos = nil
local alignOri = nil

local function stopHolding()
    if alignPos then alignPos:Destroy(); alignPos = nil end
    if alignOri then alignOri:Destroy(); alignOri = nil end
    targetPart = nil
    isHolding = false
end

local function getTarget()
    local mouse = UserInput:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mouse.X, mouse.Y)
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result and result.Instance then
        return result.Instance
    end
    return nil
end

-- ============ LMB: TELEKINESIS ============
tool.Activated:Connect(function()
    if isHolding then
        stopHolding()
        return
    end
    
    local hit = getTarget()
    if not hit then return end
    
    targetPart = hit
    isHolding = true
    
    if targetPart.Anchored then targetPart.Anchored = false end
    
    local att = targetPart:FindFirstChildWhichIsA("Attachment") or (function()
        local a = Instance.new("Attachment")
        a.Parent = targetPart
        return a
    end)()
    
    alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = att
    alignPos.MaxForce = 100000
    alignPos.Responsiveness = 50
    alignPos.Parent = targetPart
    
    alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.Attachment0 = att
    alignOri.MaxTorque = 100000
    alignOri.Responsiveness = 50
    alignOri.Parent = targetPart
end)

tool.Deactivated:Connect(stopHolding)
tool.Unequipped:Connect(stopHolding)

-- ============ RMB: DELETE ============
UserInput.InputBegan:Connect(function(input, processed)
    if processed or not tool.Parent or tool.Parent ~= LocalPlayer.Character then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local hit = getTarget()
        if hit then
            local flash = Instance.new("Part")
            flash.Size = Vector3.new(1,1,1)
            flash.CFrame = CFrame.new(hit.Position)
            flash.Anchored = true
            flash.CanCollide = false
            flash.Material = Enum.Material.Neon
            flash.Color = Color3.fromRGB(255, 0, 0)
            flash.Parent = Workspace
            TweenService:Create(flash, TweenInfo.new(0.3), {Size = Vector3.new(4, 4, 4), Transparency = 1}):Play()
            task.delay(0.3, function() flash:Destroy() end)
            
            if hit.Parent and hit.Parent:IsA("Model") and hit.Parent ~= LocalPlayer.Character then
                hit.Parent:Destroy()
            else
                hit:Destroy()
            end
        end
    end
end)

-- ============ E: KILL TOOL ============
local function getPlayerFromHit(hit)
    if not hit then return nil end
    local char = hit.Parent
    if char and char:FindFirstChildOfClass("Humanoid") then
        local player = Players:GetPlayerFromCharacter(char)
        if player and player ~= LocalPlayer then
            return player, char
        end
    end
    return nil
end

UserInput.InputBegan:Connect(function(input, processed)
    if processed or not tool.Parent or tool.Parent ~= LocalPlayer.Character then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        local hit = getTarget()
        local targetPlayer, char = getPlayerFromHit(hit)
        
        if targetPlayer and char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                -- Визуальный эффект
                local flash = Instance.new("Part")
                flash.Size = Vector3.new(1,1,1)
                flash.CFrame = char.Head.CFrame
                flash.Anchored = true
                flash.CanCollide = false
                flash.Material = Enum.Material.Neon
                flash.Color = Color3.fromRGB(255, 0, 0)
                flash.Shape = Enum.PartType.Ball
                flash.Parent = Workspace
                TweenService:Create(flash, TweenInfo.new(0.5), {Size = Vector3.new(8, 8, 8), Transparency = 1}):Play()
                task.delay(0.5, function() flash:Destroy() end)
                
                -- Убийство
                hum.Health = 0
                
                -- Чтобы наверняка, если у них GodMode
                task.spawn(function()
                    for i = 1, 5 do
                        if hum.Parent then hum.Health = 0 end
                        task.wait(0.1)
                    end
                end)
            end
        end
    end
end)

-- ============ UPDATE LOOP ============
RunService.RenderStepped:Connect(function()
    if isHolding and targetPart and targetPart.Parent then
        local mouse = UserInput:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mouse.X, mouse.Y)
        local targetPos = ray.Origin + (ray.Direction * 15)
        
        if alignPos then alignPos.Position = targetPos end
        if alignOri then alignOri.CFrame = Camera.CFrame end
    elseif isHolding and (not targetPart or not targetPart.Parent) then
        stopHolding()
    end
end)
