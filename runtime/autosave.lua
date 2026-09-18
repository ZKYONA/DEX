-- ZK DEX Runtime - hardened authorized autosave

local PINNED_USSI_COMMIT = "936066265affb4e4c9889179a8223064514c7820"
local USSI_URL =
	"https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/"
	.. PINNED_USSI_COMMIT
	.. "/saveinstance.luau"

local ACK = "I_HAVE_PERMISSION_TO_TEST_THIS_PLACE"

local ENV = type(getgenv) == "function" and getgenv() or _G
local CONFIG = ENV.ZKDEX_CONFIG or {}
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

local function hasValues(tbl)
	return type(tbl) == "table" and next(tbl) ~= nil
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

local function authorize()
	if AUTH.Acknowledgement ~= ACK then
		deny("Missing explicit authorization acknowledgement.")
	end

	local allowed =
		hasId(AUTH.AllowedPlaceIds, game.PlaceId)
		or hasId(AUTH.AllowedGameIds, game.GameId)

	if not allowed then
		deny(
			("Current place is not allowlisted. PlaceId=%s GameId=%s")
			:format(tostring(game.PlaceId), tostring(game.GameId))
		)
	end

	if hasValues(AUTH.AllowedCreatorIds)
		and not hasId(AUTH.AllowedCreatorIds, game.CreatorId)
	then
		deny(("CreatorId %s is not allowlisted."):format(tostring(game.CreatorId)))
	end

	if AUTH.RequirePrivateServer ~= false and not isPrivateOrStudio() then
		deny("Public-server execution is blocked by safety policy.")
	end

	if workspace.StreamingEnabled and CONFIG.AllowStreamingIncomplete ~= true then
		deny(
			"StreamingEnabled is on; capture may be incomplete. "
			.. "Use a development copy with streaming disabled, "
			.. "or explicitly allow an incomplete snapshot."
		)
	end

	local count = #game:GetDescendants()
	local maxInstances = tonumber(CONFIG.MaxInstances) or 400000
	if count > maxInstances then
		deny(
			("DataModel has %d descendants, above MaxInstances=%d.")
			:format(count, maxInstances)
		)
	end

	return count
end

assert(type(loadstring) == "function", "ZK DEX: loadstring() is required")
assert(type(game.HttpGet) == "function", "ZK DEX: game:HttpGet() is required")
assert(type(writefile) == "function", "ZK DEX: writefile() is required")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local settleSeconds = math.clamp(tonumber(CONFIG.SettleSeconds) or 3, 0, 30)
if settleSeconds > 0 then
	task.wait(settleSeconds)
end

if ENV.__ZKDEX_SAVE_IN_PROGRESS then
	deny("A save is already in progress.")
end

local cooldown = math.max(0, tonumber(CONFIG.RepeatCooldownSeconds) or 300)
local lastSave = tonumber(ENV.__ZKDEX_LAST_SAVE_AT)
if CONFIG.AllowRepeat ~= true and lastSave and (os.clock() - lastSave) < cooldown then
	deny(("Repeated save blocked for %d seconds."):format(cooldown))
end

local instanceCount = authorize()
ENV.__ZKDEX_SAVE_IN_PROGRESS = true

local function run()
	notify(
		"ZK DEX - Authorized",
		("Place %s | Universe %s | %d instances")
		:format(tostring(game.PlaceId), tostring(game.GameId), instanceCount)
	)

	local source = game:HttpGet(USSI_URL, true)
	local chunk, compileError = loadstring(source, "ZKDEX_USSI")
	assert(chunk, compileError)

	local synsaveinstance = chunk()
	assert(type(synsaveinstance) == "function", "ZK DEX: serializer failed to initialize")

	local stamp = os.date("%Y-%m-%d_%H-%M-%S")
	local defaultName = ("ZKDEX_%s_%s"):format(tostring(game.PlaceId), stamp)
	local outputName = tostring(CONFIG.FilePath or defaultName)
		:gsub("[^%w%._%-]", "_")
		:sub(1, 120)

	local mapOnly = CONFIG.MapOnly ~= false

	local options = {
		mode = CONFIG.Mode or "optimized",
		Binary = CONFIG.Binary ~= false,
		FilePath = outputName,
		SafeMode = true,
		ShowStatus = CONFIG.ShowStatus ~= false,
		IgnoreDefaultProps = CONFIG.IgnoreDefaultProps ~= false,
		RemovePlayerCharacters = true,
		SavePlayers = false,
		IsolateStarterPlayer = true,
		NilInstances = false,
		Decompile = false,
		SaveBytecode = false,
		AvoidFileOverwrite = true,
	}

	if not mapOnly then
		options.Decompile = CONFIG.Decompile == true
		options.SaveBytecode = CONFIG.SaveBytecode == true
		options.NilInstances = CONFIG.NilInstances == true
		options.SavePlayers = CONFIG.SavePlayers == true
	end

	notify("ZK DEX", mapOnly and "Saving map-only snapshot..." or "Saving authorized snapshot...")

	local started = os.clock()
	local ok, result = pcall(synsaveinstance, options)
	local elapsed = os.clock() - started

	if not ok then
		error(result, 0)
	end

	ENV.__ZKDEX_LAST_SAVE_AT = os.clock()

	local extension = options.Binary and ".rbxl" or ".rbxlx"
	local shownPath = outputName
	if not shownPath:match("%.[^/\\]+$") then
		shownPath ..= extension
	end

	notify(
		"ZK DEX - Saved",
		("%s | %.1fs | open the generated place file in Roblox Studio")
		:format(shownPath, elapsed)
	)

	return {
		ok = true,
		file = shownPath,
		elapsed = elapsed,
		instanceCount = instanceCount,
		mapOnly = mapOnly,
		serializer = "UniversalSynSaveInstance@" .. PINNED_USSI_COMMIT,
	}
end

local ok, result = xpcall(run, debug.traceback)
ENV.__ZKDEX_SAVE_IN_PROGRESS = false

if not ok then
	notify("ZK DEX - Error", tostring(result))
	error(result, 0)
end

return result
