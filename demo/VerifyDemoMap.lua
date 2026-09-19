-- ZK DEX demo verifier
-- Run this after re-importing/opening the exported demo map in Studio.

local root = workspace:FindFirstChild("ZKDEX_DemoMap")
assert(root, "ZKDEX_DemoMap not found in Workspace")

local function expect(path, className)
	local current = root
	for token in string.gmatch(path, "[^/]+") do
		current = current:FindFirstChild(token)
		assert(current, "Missing: " .. path)
	end
	if className then
		assert(current.ClassName == className, path .. " expected " .. className .. " got " .. current.ClassName)
	end
	return current
end

local door = expect("House/Door", "Part")
local hinge = expect("House/Door/DoorHinge", "HingeConstraint")
local a0 = expect("House/Door/DoorAttachment", "Attachment")
local a1 = expect("House/DoorFrame/FrameAttachment", "Attachment")
local objectValue = expect("Metadata/Values/DoorReference", "ObjectValue")
local beam = expect("LampPole/DemoBeam", "Beam")
local beamA = expect("LampPole/BeamA", "Attachment")
local beamB = expect("BeamAnchor/BeamB", "Attachment")

local checks = {
	["Root attribute"] = root:GetAttribute("DemoVersion") == 1,
	["ObjectValue reference"] = objectValue.Value == door,
	["Hinge Attachment0"] = hinge.Attachment0 == a0,
	["Hinge Attachment1"] = hinge.Attachment1 == a1,
	["Beam Attachment0"] = beam.Attachment0 == beamA,
	["Beam Attachment1"] = beam.Attachment1 == beamB,
	["Nested metadata"] = expect("Metadata/Values/Multiplier", "NumberValue").Value == 3.5,
}

local passed = 0
local failed = 0
for name, ok in pairs(checks) do
	if ok then
		passed += 1
		print("[PASS]", name)
	else
		failed += 1
		warn("[FAIL]", name)
	end
end

print(("ZK DEX DEMO VERIFY: %d passed / %d failed"):format(passed, failed))
assert(failed == 0, "Demo verification failed")
