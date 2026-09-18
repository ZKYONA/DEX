--[[
ZK DEX Runtime - DEX UI bootstrap
Loads the modern DeX Explorer, but first installs a working saveinstance
compatibility wrapper backed by a pinned USSI version.

This assumes you already have an authorized runtime capable of executing Luau.
It does not contain an injector or anti-cheat bypass.
]]

local PINNED_USSI_COMMIT = "936066265affb4e4c9889179a8223064514c7820"
local USSI_URL =
	"https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/"
	.. PINNED_USSI_COMMIT
	.. "/saveinstance.luau"

local DEX_URL =
	"https://github.com/FusionWTF/Dex-Explorer/releases/download/Beta/out.lua"

assert(type(loadstring) == "function", "ZK DEX: loadstring() is required")
assert(type(game.HttpGet) == "function", "ZK DEX: game:HttpGet() is required")
assert(type(writefile) == "function", "ZK DEX: writefile() is required")

local env = type(getgenv) == "function" and getgenv() or _G

local ussiSource = game:HttpGet(USSI_URL, true)
local ussiChunk, ussiCompileError = loadstring(ussiSource, "ZKDEX_USSI")
assert(ussiChunk, ussiCompileError)

local synsaveinstance = ussiChunk()
assert(type(synsaveinstance) == "function", "ZK DEX: failed to initialize USSI")

local function wrappedSaveInstance(object, filePath, options)
	options = options or {}
	local forwarded = {}

	for key, value in pairs(options) do
		forwarded[key] = value
	end

	forwarded.Object = object or forwarded.Object or game
	forwarded.FilePath = filePath or forwarded.FilePath
	if forwarded.Binary == nil then
		forwarded.Binary = true
	end
	if forwarded.SafeMode == nil then
		forwarded.SafeMode = true
	end
	if forwarded.ShowStatus == nil then
		forwarded.ShowStatus = true
	end
	if forwarded.AvoidFileOverwrite == nil then
		forwarded.AvoidFileOverwrite = true
	end

	if forwarded.Decompile
		and type(decompile) ~= "function"
		and type(getscriptbytecode) ~= "function"
	then
		warn("[ZK DEX] No decompiler/bytecode API found; disabling script decompilation for this save.")
		forwarded.Decompile = false
	end

	return synsaveinstance(forwarded)
end

env.saveinstance = wrappedSaveInstance
env.ZKDEX_SaveInstance = wrappedSaveInstance
env.ZKDEX_USSI_COMMIT = PINNED_USSI_COMMIT

print("[ZK DEX] saveinstance compatibility layer installed.")
print("[ZK DEX] Loading DeX Explorer...")

local dexSource = game:HttpGet(DEX_URL, true)
local dexChunk, dexCompileError = loadstring(dexSource, "ZKDEX_DeXExplorer")
assert(dexChunk, dexCompileError)

return dexChunk()
