local Inspector = {}

local function safeRead(instance: Instance, property: string)
	local ok, value = pcall(function()
		return (instance :: any)[property]
	end)
	if not ok then
		return nil
	end
	return value
end

local function formatValue(value: any): string
	local kind = typeof(value)
	if kind == "Vector3" then
		return string.format("%.3f, %.3f, %.3f", value.X, value.Y, value.Z)
	elseif kind == "Vector2" then
		return string.format("%.3f, %.3f", value.X, value.Y)
	elseif kind == "CFrame" then
		local p = value.Position
		return string.format("CFrame @ %.3f, %.3f, %.3f", p.X, p.Y, p.Z)
	elseif kind == "Color3" then
		return string.format("RGB(%d, %d, %d)",
			math.round(value.R * 255),
			math.round(value.G * 255),
			math.round(value.B * 255)
		)
	elseif kind == "EnumItem" then
		return tostring(value)
	elseif kind == "Instance" then
		return value:GetFullName()
	end
	return tostring(value)
end

function Inspector.describe(instance: Instance): {{name: string, value: string}}
	local rows = {
		{name = "Name", value = instance.Name},
		{name = "ClassName", value = instance.ClassName},
		{name = "Path", value = instance:GetFullName()},
	}

	local common = {
		"Archivable",
		"Position",
		"Orientation",
		"Size",
		"Anchored",
		"CanCollide",
		"Transparency",
		"Material",
		"Color",
		"MeshId",
		"TextureID",
		"Texture",
		"SoundId",
		"AnimationId",
		"Enabled",
	}

	for _, property in ipairs(common) do
		local value = safeRead(instance, property)
		if value ~= nil then
			table.insert(rows, {
				name = property,
				value = formatValue(value),
			})
		end
	end

	local attributes = instance:GetAttributes()
	for key, value in pairs(attributes) do
		table.insert(rows, {
			name = "@" .. key,
			value = formatValue(value),
		})
	end

	return rows
end

return Inspector
