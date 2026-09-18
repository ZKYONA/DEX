-- ZK DEX runtime diagnostics

local env = type(getgenv) == "function" and getgenv() or _G
local config = env.ZKDEX_CONFIG or {}

local function yesno(value)
	return value and "OK" or "MISSING"
end

local checks = {
	loadstring = type(loadstring) == "function",
	httpget = type(game.HttpGet) == "function",
	writefile = type(writefile) == "function",
	readfile = type(readfile) == "function",
	isfile = type(isfile) == "function",
	native_saveinstance = type(saveinstance) == "function",
	getscriptbytecode = type(getscriptbytecode) == "function",
	decompile = type(decompile) == "function",
	getnilinstances = type(getnilinstances or get_nil_instances) == "function",
	gethui = type(gethui) == "function",
	cloneref = type(cloneref) == "function",
}

local canSaveMap =
	checks.loadstring
	and checks.httpget
	and checks.writefile

print("=== ZK DEX RUNTIME DIAGNOSTICS ===")
for name, value in pairs(checks) do
	print(("%-26s %s"):format(name, yesno(value)))
end

print("------------------------------------")
print("PlaceId:", game.PlaceId)
print("GameId:", game.GameId)
print("CreatorId:", game.CreatorId)
print("StreamingEnabled:", workspace.StreamingEnabled)
print("Map save:", canSaveMap and "READY" or "BLOCKED")
print("MapOnly:", config.MapOnly ~= false and "ON (recommended)" or "OFF")
print("Visual DEX:", config.AllowExternalDexUI == true and "ENABLED" or "DISABLED BY DEFAULT")
print("------------------------------------")
print("No authorization gate is enforced by ZK DEX.")
print("No stealth or anti-cheat evasion is performed.")

return {
	checks = checks,
	canSaveMap = canSaveMap,
	placeId = game.PlaceId,
	gameId = game.GameId,
	creatorId = game.CreatorId,
	streamingEnabled = workspace.StreamingEnabled,
}
