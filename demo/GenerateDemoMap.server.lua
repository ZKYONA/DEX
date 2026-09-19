-- ZK DEX safe extraction demo
-- Run this in Roblox Studio (Command Bar or a temporary Script).
-- It creates a representative map with references, attributes, constraints,
-- effects, lighting and nested models so you can test export/re-import fidelity.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local old = workspace:FindFirstChild("ZKDEX_DemoMap")
if old then
	old:Destroy()
end

local root = Instance.new("Model")
root.Name = "ZKDEX_DemoMap"
root:SetAttribute("DemoVersion", 1)
root:SetAttribute("Purpose", "SerializerFidelityTest")
CollectionService:AddTag(root, "ZKDEX_Demo")
root.Parent = workspace

local ground = Instance.new("Part")
ground.Name = "Ground"
ground.Anchored = true
ground.Size = Vector3.new(80, 1, 80)
ground.Position = Vector3.new(0, 0, 0)
ground.Material = Enum.Material.Grass
ground.Color = Color3.fromRGB(96, 140, 72)
ground.Parent = root

local house = Instance.new("Model")
house.Name = "House"
house.Parent = root

local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Anchored = true
floor.Size = Vector3.new(24, 1, 18)
floor.Position = Vector3.new(0, 1, 0)
floor.Material = Enum.Material.WoodPlanks
floor.Parent = house

for i, info in ipairs({
	{"WallFront", Vector3.new(24, 8, 1), Vector3.new(0, 5, -8.5)},
	{"WallBack", Vector3.new(24, 8, 1), Vector3.new(0, 5, 8.5)},
	{"WallLeft", Vector3.new(1, 8, 16), Vector3.new(-11.5, 5, 0)},
	{"WallRight", Vector3.new(1, 8, 16), Vector3.new(11.5, 5, 0)},
}) do
	local p = Instance.new("Part")
	p.Name = info[1]
	p.Anchored = true
	p.Size = info[2]
	p.Position = info[3]
	p.Material = Enum.Material.Wood
	p.Color = Color3.fromRGB(140, 92, 56)
	p.Parent = house
end

local door = Instance.new("Part")
door.Name = "Door"
door.Size = Vector3.new(4, 7, 0.5)
door.Position = Vector3.new(0, 4.5, -8)
door.Color = Color3.fromRGB(90, 55, 35)
door.Parent = house

local frame = Instance.new("Part")
frame.Name = "DoorFrame"
frame.Anchored = true
frame.Size = Vector3.new(1, 8, 1)
frame.Position = Vector3.new(-2.5, 5, -8)
frame.Transparency = 0.35
frame.Parent = house

local a0 = Instance.new("Attachment")
a0.Name = "DoorAttachment"
a0.Position = Vector3.new(-2, 0, 0)
a0.Parent = door

local a1 = Instance.new("Attachment")
a1.Name = "FrameAttachment"
a1.Position = Vector3.new(0, 0, 0)
a1.Parent = frame

local hinge = Instance.new("HingeConstraint")
hinge.Name = "DoorHinge"
hinge.Attachment0 = a0
hinge.Attachment1 = a1
hinge.LimitsEnabled = true
hinge.LowerAngle = 0
hinge.UpperAngle = 100
hinge.Parent = door

local lampPole = Instance.new("Part")
lampPole.Name = "LampPole"
lampPole.Anchored = true
lampPole.Size = Vector3.new(1, 8, 1)
lampPole.Position = Vector3.new(16, 4, 0)
lampPole.Material = Enum.Material.Metal
lampPole.Parent = root

local lampAttachment = Instance.new("Attachment")
lampAttachment.Name = "LampAttachment"
lampAttachment.Position = Vector3.new(0, 4, 0)
lampAttachment.Parent = lampPole

local light = Instance.new("PointLight")
light.Name = "WarmLight"
light.Brightness = 2
light.Range = 20
light.Color = Color3.fromRGB(255, 210, 150)
light.Parent = lampAttachment

local particles = Instance.new("ParticleEmitter")
particles.Name = "DemoParticles"
particles.Enabled = true
particles.Rate = 5
particles.Lifetime = NumberRange.new(1, 2)
particles.Speed = NumberRange.new(1, 2)
particles.Parent = lampAttachment

local anchor = Instance.new("Part")
anchor.Name = "BeamAnchor"
anchor.Anchored = true
anchor.Transparency = 1
anchor.CanCollide = false
anchor.Size = Vector3.new(1, 1, 1)
anchor.Position = Vector3.new(24, 8, 0)
anchor.Parent = root

local beamA = Instance.new("Attachment")
beamA.Name = "BeamA"
beamA.Parent = lampPole

local beamB = Instance.new("Attachment")
beamB.Name = "BeamB"
beamB.Parent = anchor

local beam = Instance.new("Beam")
beam.Name = "DemoBeam"
beam.Attachment0 = beamA
beam.Attachment1 = beamB
beam.Width0 = 0.15
beam.Width1 = 0.15
beam.FaceCamera = true
beam.Parent = lampPole

local folder = Instance.new("Folder")
folder.Name = "Metadata"
folder:SetAttribute("Number", 42)
folder:SetAttribute("Enabled", true)
folder:SetAttribute("Tint", Color3.fromRGB(120, 180, 255))
folder.Parent = root

local values = Instance.new("Folder")
values.Name = "Values"
values.Parent = folder

local numberValue = Instance.new("NumberValue")
numberValue.Name = "Multiplier"
numberValue.Value = 3.5
numberValue.Parent = values

local objectValue = Instance.new("ObjectValue")
objectValue.Name = "DoorReference"
objectValue.Value = door
objectValue.Parent = values

local sound = Instance.new("Sound")
sound.Name = "AmbientSound"
sound.Volume = 0.25
sound.Looped = true
sound.Parent = root

house.PrimaryPart = floor
root.PrimaryPart = ground

Lighting.ClockTime = 17.5
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(90, 90, 110)

print("[ZK DEX DEMO] Created:", root:GetFullName())
print("[ZK DEX DEMO] Descendants:", #root:GetDescendants())
print("[ZK DEX DEMO] Door ref valid:", objectValue.Value == door)
print("[ZK DEX DEMO] Hinge refs valid:", hinge.Attachment0 == a0 and hinge.Attachment1 == a1)
