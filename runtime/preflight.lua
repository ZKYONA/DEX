-- ZK DEX runtime preflight
-- This file performs read-only checks. It does not save, inject, hide, or bypass anything.

local env = type(getgenv) == "function" and getgenv() or _G
local config = env.ZKDEX_CONFIG or {}

local function status(ok, detail)
	return {
		ok = ok,
		detail = detail,
	}
end

local results = {}

results.loadstring = status(type(loadstring) == "function", "Luau loader")
results.httpget = status(type(game.HttpGet) == "function", "HTTP loader")
results.writefile = status(type(writefile) == "function", "File output")
results.gameLoaded = status(game:IsLoaded(), "Game loaded")
results.streaming = status(
	not workspace.StreamingEnabled or config.AllowStreamingIncomplete == true,
	workspace.StreamingEnabled and "StreamingEnabled is active" or "Streaming disabled"
)

local instanceCount = #game:GetDescendants()
local maxInstances = tonumber(config.MaxInstances) or 400000
results.instanceCount = status(
	instanceCount <= maxInstances,
	("%d / %d"):format(instanceCount, maxInstances)
)

local allRequired = true
for name, item in pairs(results) do
	if name ~= "streaming" and name ~= "instanceCount" and not item.ok then
		allRequired = false
	end
end

local ready =
	allRequired
	and results.streaming.ok
	and results.instanceCount.ok
	and env.ZKDEX_ABORT ~= true

print("=== ZK DEX PREFLIGHT ===")
for name, item in pairs(results) do
	print(("%-18s %s | %s"):format(name, item.ok and "OK" or "WARN", item.detail))
end
print("--------------------------------")
print("Emergency abort:", env.ZKDEX_ABORT == true and "ON" or "OFF")
print("Ready to save:", ready and "YES" or "NO")
print("This preflight performs no stealth or anti-cheat evasion.")

return {
	ready = ready,
	results = results,
	instanceCount = instanceCount,
	placeId = game.PlaceId,
	gameId = game.GameId,
	streamingEnabled = workspace.StreamingEnabled,
}
