-- ZK DEX Runtime - guarded visual DEX bootstrap
-- No injector, anti-cheat bypass, stealth, or evasion logic.

local PINNED_USSI_COMMIT = "936066265affb4e4c9889179a8223064514c7820"
local USSI_URL =
	"https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/"
	.. PINNED_USSI_COMMIT
	.. "/saveinstance.luau"

local DEX_URL =
	"https://github.com/FusionWTF/Dex-Explorer/releases/download/Beta/out.lua"

local ACK = "I_HAVE_PERMISSION_TO_TEST_THIS_PLACE"

local env = type(getgenv) == "function" and getgenv() or _G
local CONFIG = env.ZKDEX_CONFIG or {}
local AUTH = CONFIG.Authorization or {}

local function deny(message)
	error("[ZK DEX SAFETY] " .. message, 0)
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

local function isPrivateOrStudio()
	if game:GetService("RunService"):IsStudio() then
		return true
	end
	local ok, value = pcall(function()
		return game.PrivateServerId
	end)
	return ok and type(value) == "string" and value ~= ""
end

local function authorize()
	if AUTH.Acknowledgement ~= ACK then
		deny("Missing explicit authorization acknowledgement.")
	end

	if not hasId(AUTH.AllowedPlaceIds, game.PlaceId)
		and not hasId(AUTH.AllowedGameIds, game.GameId)
	then
		deny(
			("Current place is not allowlisted. PlaceId=%s GameId=%s")
			:format(tostring(game.PlaceId), tostring(game.GameId))
		)
	end

	if AUTH.RequirePrivateServer ~= false and not isPrivateOrStudio() then
		deny("Public-server execution is blocked by safety policy.")
	end

	if workspace.StreamingEnabled and CONFIG.AllowStreamingIncomplete ~= true then
		deny("StreamingEnabled is active; visual DEX may only see a partial map.")
	end

	if AUTH.AllowExternalDexUI ~= true then
		deny(
			"Visual DEX is disabled by default because it downloads third-party UI code. "
			.. "Set Authorization.AllowExternalDexUI = true only when you intentionally want it. "
			.. "For map export, autosave.lua is the recommended path."
		)
	end
end

assert(type(loadstring) == "function", "ZK DEX: loadstring() is required")
assert(type(game.HttpGet) == "function", "ZK DEX: game:HttpGet() is required")
assert(type(writefile) == "function", "ZK DEX: writefile() is required")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

authorize()

local ussiSource = game:HttpGet(USSI_URL, true)
local ussiChunk, ussiCompileError = loadstring(ussiSource, "ZKDEX_USSI")
assert(ussiChunk, ussiCompileError)

local synsaveinstance = ussiChunk()
assert(type(synsaveinstance) == "function", "ZK DEX: failed to initialize serializer")

local function wrappedSaveInstance(object, filePath, options)
	options = options or {}
	local forwarded = {}

	for key, value in pairs(options) do
		forwarded[key] = value
	end

	forwarded.Object = object or forwarded.Object or game
	forwarded.FilePath = filePath or forwarded.FilePath
	forwarded.Binary = forwarded.Binary ~= false
	forwarded.SafeMode = true
	forwarded.ShowStatus = forwarded.ShowStatus ~= false
	forwarded.AvoidFileOverwrite = true

	if CONFIG.MapOnly ~= false then
		forwarded.Decompile = false
		forwarded.SaveBytecode = false
		forwarded.NilInstances = false
		forwarded.SavePlayers = false
		forwarded.RemovePlayerCharacters = true
	end

	return synsaveinstance(forwarded)
end

env.saveinstance = wrappedSaveInstance
env.ZKDEX_SaveInstance = wrappedSaveInstance
env.ZKDEX_USSI_COMMIT = PINNED_USSI_COMMIT

print("[ZK DEX] Authorized saveinstance layer installed.")
print("[ZK DEX] Loading explicitly-enabled visual DEX...")

local dexSource = game:HttpGet(DEX_URL, true)
local dexChunk, dexCompileError = loadstring(dexSource, "ZKDEX_DeXExplorer")
assert(dexChunk, dexCompileError)

return dexChunk()
