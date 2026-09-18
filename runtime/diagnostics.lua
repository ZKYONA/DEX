-- ZK DEX runtime diagnostics

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
	request = type(
		(syn and syn.request)
		or (http and http.request)
		or http_request
		or request
	) == "function",
	gethui = type(gethui) == "function",
	cloneref = type(cloneref) == "function",
}

print("=== ZK DEX RUNTIME DIAGNOSTICS ===")
for name, value in pairs(checks) do
	print(("%-24s %s"):format(name, yesno(value)))
end

local canSaveMap = checks.loadstring and checks.httpget and checks.writefile
local canRecoverScripts = checks.decompile or checks.getscriptbytecode

print("----------------------------------")
print("Map save:", canSaveMap and "SUPPORTED" or "NOT READY")
print("Script recovery:", canRecoverScripts and "POSSIBLE" or "UNAVAILABLE")
print("Note: output only contains data replicated/visible to this client runtime.")

return {
	checks = checks,
	canSaveMap = canSaveMap,
	canRecoverScripts = canRecoverScripts,
}
