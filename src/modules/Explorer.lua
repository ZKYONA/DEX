local Explorer = {}

export type RowCallback = (Instance) -> ()

local ROW_HEIGHT = 22

local function clear(frame: ScrollingFrame)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function addRow(
	frame: ScrollingFrame,
	instance: Instance,
	depth: number,
	index: number,
	onSelect: RowCallback
)
	local button = Instance.new("TextButton")
	button.Name = "Row_" .. index
	button.AutoButtonColor = true
	button.BorderSizePixel = 0
	button.BackgroundTransparency = 1
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Font = Enum.Font.Code
	button.TextSize = 14
	button.Text = string.rep("   ", depth) .. instance.Name .. "  [" .. instance.ClassName .. "]"
	button.Position = UDim2.fromOffset(0, (index - 1) * ROW_HEIGHT)
	button.Size = UDim2.new(1, -4, 0, ROW_HEIGHT)
	button.Parent = frame

	button.MouseButton1Click:Connect(function()
		onSelect(instance)
	end)
end

function Explorer.render(
	frame: ScrollingFrame,
	root: Instance,
	onSelect: RowCallback,
	maxRows: number?
)
	clear(frame)

	local limit = maxRows or 5000
	local index = 0

	local function walk(instance: Instance, depth: number)
		if index >= limit then
			return
		end

		index += 1
		addRow(frame, instance, depth, index, onSelect)

		for _, child in ipairs(instance:GetChildren()) do
			if index >= limit then
				break
			end
			walk(child, depth + 1)
		end
	end

	for _, child in ipairs(root:GetChildren()) do
		walk(child, 0)
		if index >= limit then
			break
		end
	end

	frame.CanvasSize = UDim2.fromOffset(0, index * ROW_HEIGHT)
	return index
end

return Explorer
