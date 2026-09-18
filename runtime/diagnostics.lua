-- ZK DEX hardened runtime diagnostics

local ACK = "I_HAVE_PERMISSION_TO_TEST_THIS_PLACE"

local env = type(getgenv) == "function" and getgenv() or _G
local config = env.ZKDEX_CONFIG or {}
local auth = config.Authorization or {}

local function yesno(value)
	return value and "OK" or "MISSING"
end

local function hasId(tbl, id)
	if type(tbl) ~= "table" then
		return false
	end
	if tbl[id] == true or tbl[tostring(id)] == true then
		return true
	end
	for _, value in pairs(tbl) do
		if tonumber(value) == id then
			return true
		end
	end
	return false
end

local privateOrStudio = game:GetService("RunService"):IsStudio()
if not privateOrStudio then
	local ok, value = pcall(function()
		return game.PrivateServerId
	end)
	privateOrStudio = ok and type(value) == "string" and value ~= ""
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

local acknowledged = auth.Acknowledgement == ACK
local allowlisted =
	hasId(auth.AllowedPlaceIds, game.PlaceId)
	or hasId(auth.AllowedGameIds, game.GameId)

local authorizationReady =
	acknowledged
	and allowlisted
	and (auth.RequirePrivateServer == false or privateOrStudio)

local canSaveMap =
	checks.loadstring
	and checks.httpget
	and checks.writefile
	and authorizationReady

print("=== ZK DEX HARDENED DIAGNOSTICS ===")
for name, value in pairs(checks) do
	print(("%-26s %s"):format(name, yesno(value)))
end

print("------------------------------------")
print("PlaceId:", game.PlaceId)
print("GameId:", game.GameId)
print("CreatorId:", game.CreatorId)
print("StreamingEnabled:", workspace.StreamingEnabled)
print("Authorization ack:", acknowledged and "OK" or "MISSING")
print("Place/Universe allowlist:", allowlisted and "OK" or "BLOCKED")
print("Private/Studio:", privateOrStudio and "YES" or "NO")
print("Authorization gate:", authorizationReady and "PASS" or "FAIL")
print("Map save:", canSaveMap and "READY" or "BLOCKED")
print("MapOnly:", config.MapOnly ~= false and "ON (recommended)" or "OFF")
print("Visual DEX:", auth.AllowExternalDexUI == true and "ENABLED" or "BLOCKED BY DEFAULT")
print("------------------------------------")
print("No stealth or anti-cheat evasion is performed.")
print("The live client cannot reliably prove edit permission; use a real allowlist and a private development server.")

return {
	checks = checks,
	authorizationReady = authorizationReady,
	canSaveMap = canSaveMap,
	placeId = game.PlaceId,
	gameId = game.GameId,
	creatorId = game.CreatorId,
	streamingEnabled = workspace.StreamingEnabled,
}
