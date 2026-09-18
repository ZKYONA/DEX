local Selection = game:GetService("Selection")

local Exporter = {}

local function getWorkspaceRoots()
	local roots = {}
	for _, child in ipairs(workspace:GetChildren()) do
		if not child:IsA("Camera") then
			table.insert(roots, child)
		end
	end
	return roots
end

function Exporter.saveSelection(plugin: Plugin, suggestedName: string?): (boolean, string?)
	local current = Selection:Get()
	if #current == 0 then
		return false, "No hay objetos seleccionados."
	end

	local ok, result = pcall(function()
		return plugin:PromptSaveSelectionAsync(suggestedName or "ZKDEX_Selection")
	end)

	if not ok then
		return false, tostring(result)
	end

	return result == true, result == true and nil or "El guardado fue cancelado."
end

function Exporter.saveWorkspaceMap(plugin: Plugin): (boolean, string?)
	local oldSelection = Selection:Get()
	local roots = getWorkspaceRoots()

	if #roots == 0 then
		return false, "Workspace no contiene objetos exportables."
	end

	Selection:Set(roots)

	local ok, result = pcall(function()
		return plugin:PromptSaveSelectionAsync(
			("ZKDEX_Map_%s"):format(tostring(game.PlaceId))
		)
	end)

	Selection:Set(oldSelection)

	if not ok then
		return false, tostring(result)
	end

	return result == true, result == true and nil or "El guardado fue cancelado."
end

function Exporter.countInstances(): number
	return #game:GetDescendants()
end

return Exporter
