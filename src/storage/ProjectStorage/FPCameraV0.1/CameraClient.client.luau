--mys.tic, as always

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

Camera.CameraType = Enum.CameraType.Scriptable

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

local x = 0
local y = 0 
local Width = Mouse.ViewSizeX
local Length = Mouse.ViewSizeY
local Sens = 10
function main()
		
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	Camera.CameraType = Enum.CameraType.Scriptable

	local Position = Character.Head.Position
	local LastCFrame = Camera.CFrame

	local MouseDelta = UserInputService:GetMouseDelta()
	local DeltaX = MouseDelta.X
	local DeltaY = MouseDelta.Y

	x += -DeltaX / Width
	y += -DeltaY / Length

	y = math.clamp(y, -math.rad(89), math.rad(89))

	local RotX = y
	local RotY = x
	local RotZ = 0

	local Orientation = CFrame.Angles(RotX, RotY, RotZ)

	Camera.CFrame = CFrame.new(Position) * Orientation


	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	
	--locked center behavior 
	
	
end

RunService.RenderStepped:Connect(main)