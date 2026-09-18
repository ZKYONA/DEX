assert(plugin, "ZK DEX debe ejecutarse como plugin de Roblox Studio")

local Selection = game:GetService("Selection")

local moduleRoot = script.Parent:WaitForChild("modules")
local Explorer = require(moduleRoot:WaitForChild("Explorer"))
local Inspector = require(moduleRoot:WaitForChild("Inspector"))
local Exporter = require(moduleRoot:WaitForChild("Exporter"))

local toolbar = plugin:CreateToolbar("ZK DEX")
local toggleButton = toolbar:CreateButton(
	"ZKDEX_Toggle",
	"Abrir/cerrar ZK DEX",
	"rbxassetid://4458901886"
)

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,
	false,
	false,
	760,
	520,
	520,
	360
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("ZKDEX_MainWidget_v1", widgetInfo)
widget.Title = "ZK DEX — Explorer / Properties / Save Map"

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
root.BorderSizePixel = 0
root.Size = UDim2.fromScale(1, 1)
root.Parent = widget

local top = Instance.new("Frame")
top.Name = "Toolbar"
top.BackgroundColor3 = Color3.fromRGB(43, 43, 48)
top.BorderSizePixel = 0
top.Size = UDim2.new(1, 0, 0, 36)
top.Parent = root

local function makeButton(text: string, x: number, width: number)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(62, 62, 68)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.SourceSansSemibold
	button.TextColor3 = Color3.fromRGB(235, 235, 240)
	button.TextSize = 14
	button.Text = text
	button.Position = UDim2.fromOffset(x, 5)
	button.Size = UDim2.fromOffset(width, 26)
	button.Parent = top
	return button
end

local refreshButton = makeButton("Refresh", 6, 76)
local saveSelectionButton = makeButton("Save Selection", 88, 112)
local saveMapButton = makeButton("Save Workspace Map", 206, 148)

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Font = Enum.Font.SourceSans
status.TextColor3 = Color3.fromRGB(190, 190, 200)
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Right
status.AnchorPoint = Vector2.new(1, 0)
status.Position = UDim2.new(1, -8, 0, 7)
status.Size = UDim2.new(0, 360, 0, 22)
status.Text = "Ready"
status.Parent = top

local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(0, 36)
body.Size = UDim2.new(1, 0, 1, -36)
body.Parent = root

local explorerPane = Instance.new("Frame")
explorerPane.BackgroundColor3 = Color3.fromRGB(27, 27, 31)
explorerPane.BorderSizePixel = 0
explorerPane.Size = UDim2.new(0.56, -2, 1, 0)
explorerPane.Parent = body

local propertiesPane = Instance.new("Frame")
propertiesPane.BackgroundColor3 = Color3.fromRGB(36, 36, 41)
propertiesPane.BorderSizePixel = 0
propertiesPane.Position = UDim2.new(0.56, 2, 0, 0)
propertiesPane.Size = UDim2.new(0.44, -2, 1, 0)
propertiesPane.Parent = body

local explorerTitle = Instance.new("TextLabel")
explorerTitle.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
explorerTitle.BorderSizePixel = 0
explorerTitle.Font = Enum.Font.SourceSansSemibold
explorerTitle.TextColor3 = Color3.fromRGB(238, 238, 242)
explorerTitle.TextSize = 14
explorerTitle.TextXAlignment = Enum.TextXAlignment.Left
explorerTitle.Text = "  Explorer — Workspace"
explorerTitle.Size = UDim2.new(1, 0, 0, 26)
explorerTitle.Parent = explorerPane

local tree = Instance.new("ScrollingFrame")
tree.Name = "Tree"
tree.BackgroundTransparency = 1
tree.BorderSizePixel = 0
tree.Position = UDim2.fromOffset(0, 26)
tree.Size = UDim2.new(1, 0, 1, -26)
tree.ScrollBarThickness = 8
tree.CanvasSize = UDim2.fromOffset(0, 0)
tree.Parent = explorerPane

local propsTitle = Instance.new("TextLabel")
propsTitle.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
propsTitle.BorderSizePixel = 0
propsTitle.Font = Enum.Font.SourceSansSemibold
propsTitle.TextColor3 = Color3.fromRGB(238, 238, 242)
propsTitle.TextSize = 14
propsTitle.TextXAlignment = Enum.TextXAlignment.Left
propsTitle.Text = "  Properties"
propsTitle.Size = UDim2.new(1, 0, 0, 26)
propsTitle.Parent = propertiesPane

local props = Instance.new("ScrollingFrame")
props.Name = "Properties"
props.BackgroundTransparency = 1
props.BorderSizePixel = 0
props.Position = UDim2.fromOffset(0, 26)
props.Size = UDim2.new(1, 0, 1, -26)
props.ScrollBarThickness = 8
props.CanvasSize = UDim2.fromOffset(0, 0)
props.Parent = propertiesPane

local ROW_HEIGHT = 24

local function clearProperties()
	for _, child in ipairs(props:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function renderProperties(instance: Instance?)
	clearProperties()

	if not instance then
		propsTitle.Text = "  Properties"
		return
	end

	propsTitle.Text = "  Properties — " .. instance.Name
	local rows = Inspector.describe(instance)

	for index, row in ipairs(rows) do
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = index % 2 == 0
			and Color3.fromRGB(40, 40, 46)
			or Color3.fromRGB(36, 36, 41)
		frame.BorderSizePixel = 0
		frame.Position = UDim2.fromOffset(0, (index - 1) * ROW_HEIGHT)
		frame.Size = UDim2.new(1, -2, 0, ROW_HEIGHT)
		frame.Parent = props

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.Code
		name.TextColor3 = Color3.fromRGB(180, 205, 255)
		name.TextSize = 12
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Text = row.name
		name.Size = UDim2.new(0.38, -6, 1, 0)
		name.Position = UDim2.fromOffset(6, 0)
		name.Parent = frame

		local value = Instance.new("TextLabel")
		value.BackgroundTransparency = 1
		value.Font = Enum.Font.Code
		value.TextColor3 = Color3.fromRGB(225, 225, 230)
		value.TextSize = 12
		value.TextTruncate = Enum.TextTruncate.AtEnd
		value.TextXAlignment = Enum.TextXAlignment.Left
		value.Text = row.value
		value.Position = UDim2.new(0.38, 0, 0, 0)
		value.Size = UDim2.new(0.62, -6, 1, 0)
		value.Parent = frame
	end

	props.CanvasSize = UDim2.fromOffset(0, #rows * ROW_HEIGHT)
end

local function selectInstance(instance: Instance)
	Selection:Set({instance})
	renderProperties(instance)
end

local function refresh()
	status.Text = "Scanning..."
	local count = Explorer.render(tree, workspace, selectInstance, 5000)
	status.Text = string.format(
		"Workspace rows: %d | DataModel instances: %d",
		count,
		Exporter.countInstances()
	)
end

refreshButton.MouseButton1Click:Connect(refresh)

saveSelectionButton.MouseButton1Click:Connect(function()
	status.Text = "Saving selection..."
	local ok, err = Exporter.saveSelection(plugin, "ZKDEX_Selection")
	status.Text = ok and "Selection saved." or ("Save cancelled/error: " .. tostring(err))
end)

saveMapButton.MouseButton1Click:Connect(function()
	status.Text = "Preparing Workspace map..."
	local ok, err = Exporter.saveWorkspaceMap(plugin)
	status.Text = ok and "Workspace map saved." or ("Save cancelled/error: " .. tostring(err))
end)

Selection.SelectionChanged:Connect(function()
	local selected = Selection:Get()
	renderProperties(selected[1])
end)

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then
		refresh()
		local selected = Selection:Get()
		renderProperties(selected[1])
	end
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
end)

widget:BindToClose(function()
	widget.Enabled = false
end)

print("[ZK DEX] Plugin loaded")
