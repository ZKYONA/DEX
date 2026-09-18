--[[
ZK DEX Runtime - Auto Save Place
Authorized-use helper for environments that already expose the client-side
execution/file APIs required by USSI. This file does not provide injection,
anti-cheat bypasses, or client modification.
]]

local PINNED_USSI_COMMIT = "936066265affb4e4c9889179a8223064514c7820"
local USSI_URL =
	"https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/"
	.. PINNED_USSI_COMMIT
	.. "/saveinstance.luau"

local function globalEnv()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

local ENV = globalEnv()
local CONFIG = ENV.ZKDEX_CONFIG or {}

local function sanitize(value)
	return tostring(value)
		:gsub("[<>:"/\\|%?%*]", "_")
		:gsub("%s+", "_")
		:sub(1, 120)
end

local function getPlaceName()
	local ok, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)
	if ok and type(info) == "table" and type(info.Name) == "string" then
		return info.Name
	end
	return "Place"
end

local function notify(title, text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 8,
		})
	end)
	print(("[ZK DEX] %s | %s"):format(title, text))
end

assert(type(loadstring) == "function", "ZK DEX: this runtime needs loadstring()")
assert(type(game.HttpGet) == "function", "ZK DEX: this runtime needs game:HttpGet()")
assert(type(writefile) == "function", "ZK DEX: this runtime needs writefile()")

notify("ZK DEX", "Loading pinned USSI serializer...")

local source = game:HttpGet(USSI_URL, true)
local chunk, compileError = loadstring(source, "ZKDEX_USSI")
assert(chunk, compileError)

local synsaveinstance = chunk()
assert(type(synsaveinstance) == "function", "ZK DEX: USSI did not return a function")

local stamp = os.date("%Y-%m-%d_%H-%M-%S")
local defaultName = ("ZKDEX_%s_%s_%s"):format(
	tostring(game.PlaceId),
	sanitize(getPlaceName()),
	stamp
)

local outputName = CONFIG.FilePath or defaultName

local options = {
	mode = CONFIG.Mode or "optimized",
	Binary = CONFIG.Binary ~= false,
	FilePath = outputName,
	SafeMode = CONFIG.SafeMode ~= false,
	ShowStatus = CONFIG.ShowStatus ~= false,
	IgnoreDefaultProps = CONFIG.IgnoreDefaultProps ~= false,
	RemovePlayerCharacters = CONFIG.RemovePlayerCharacters ~= false,
	SavePlayers = CONFIG.SavePlayers == true,
	IsolateStarterPlayer = CONFIG.IsolateStarterPlayer ~= false,
	NilInstances = CONFIG.NilInstances == true,
	Decompile = CONFIG.Decompile == true,
	SaveBytecode = CONFIG.SaveBytecode == true,
	AvoidFileOverwrite = true,
}

if options.Decompile and type(decompile) ~= "function" and type(getscriptbytecode) ~= "function" then
	warn("[ZK DEX] Decompile requested but no decompile/getscriptbytecode API exists; saving map without source recovery.")
	options.Decompile = false
end

notify("ZK DEX", "Saving current replicated DataModel...")

local started = os.clock()
local ok, result = pcall(synsaveinstance, options)
local elapsed = os.clock() - started

if not ok then
	notify("ZK DEX - Error", tostring(result))
	error(result, 0)
end

local expectedExtension = options.Binary and ".rbxl" or ".rbxlx"
local shownPath = outputName
if not shownPath:match("%.[^/\\]+$") then
	shownPath ..= expectedExtension
end

notify(
	"ZK DEX - Saved",
	("%s | %.1fs | open the generated place file in Roblox Studio"):format(shownPath, elapsed)
)

return {
	ok = true,
	file = shownPath,
	elapsed = elapsed,
	serializer = "UniversalSynSaveInstance@" .. PINNED_USSI_COMMIT,
}
