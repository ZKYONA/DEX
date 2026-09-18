-- ZK DEX Runtime - visual DEX bootstrap
-- No injector, anti-cheat bypass, stealth, or evasion logic.

local PINNED_USSI_COMMIT = "936066265affb4e4c9889179a8223064514c7820"
local USSI_URL =
	"https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/"
	.. PINNED_USSI_COMMIT
	.. "/saveinstance.luau"

local DEX_URL =
	"https://github.com/FusionWTF/Dex-Explorer/releases/download/Beta/out.lua"

local env = type(getgenv) == "function" and getgenv() or _G
local CONFIG = env.ZKDEX_CONFIG or {}

local function stop(message)
	error("[ZK DEX] " .. message, 0)
end

assert(type(loadstring) == "function", "ZK DEX: loadstring() is required")
assert(type(game.HttpGet) == "function", "ZK DEX: game:HttpGet() is required")
assert(type(writefile) == "function", "ZK DEX: writefile() is required")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

if workspace.StreamingEnabled and CONFIG.AllowStreamingIncomplete ~= true then
	stop(
		"StreamingEnabled is active; visual DEX may only see a partial map. "
		.. "Set AllowStreamingIncomplete=true if that is intentional."
	)
end

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

print("[ZK DEX] saveinstance layer installed.")

if CONFIG.AllowExternalDexUI ~= true then
	stop(
		"Visual DEX downloads third-party UI code and is disabled by default. "
		.. "Set ZKDEX_CONFIG.AllowExternalDexUI = true to enable it. "
		.. "For map export, autosave.lua is the simpler path."
	)
end

print("[ZK DEX] Loading visual DEX...")

local dexSource = game:HttpGet(DEX_URL, true)
local dexChunk, dexCompileError = loadstring(dexSource, "ZKDEX_DeXExplorer")
assert(dexChunk, dexCompileError)

return dexChunk()
