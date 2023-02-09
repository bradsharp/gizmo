--!nocheck
-- Name:		gizmo.lua
-- Version:		2.0 (02/07/23)
-- Author:		Brad Sharp
--
-- Repository:	https://github.com/BradSharp/Roblox-Miscellaneous/tree/master/Gizmo
-- License:		MIT
--
-- Copyright (c) 2021-2023 Brad Sharp
------------------------------------------------------------------------------------------------------------------------

local GLOBAL_ATTRIBUTE = "EnableGizmos"

local DEFAULT_SCALE = 0.1
local DEFAULT_COLOR = Color3.fromRGB(255, 255, 0)

local RunService = game:GetService("RunService")

------------------------------------------------------------------------------------------------------------------------
-- Type Definitions
------------------------------------------------------------------------------------------------------------------------

type Style = {
	color: Color3,
	layer: number,
	transparency: number,
	scale: number,
}

type Gizmo = {
	__properties: {[number]: any, n: number},
	style: Style
}

------------------------------------------------------------------------------------------------------------------------
-- Internal Variables
------------------------------------------------------------------------------------------------------------------------

local moduleId = script:GetFullName()
local active = false

local scheduledObjects = {}
local renderQueue = {}
local instanceCache = {}
local container = Instance.new("Folder", workspace)

container.Name = "Gizmos"
container.Archivable = false

local globalStyle: Style = {
	color = DEFAULT_COLOR,
	layer = 1,
	transparency = 0,
	scale = DEFAULT_SCALE
}

------------------------------------------------------------------------------------------------------------------------
-- Update Instance Visibility
------------------------------------------------------------------------------------------------------------------------

local function show(instance)
	if instance:IsA("PVAdornment") then
		instance.Visible = true
	else
		instance.Enabled = true
	end
end

local function hide(instance)
	if instance:IsA("PVAdornment") then
		instance.Visible = false
	else
		instance.Enabled = false
	end
end

------------------------------------------------------------------------------------------------------------------------
-- Instance Caching
------------------------------------------------------------------------------------------------------------------------

local function get(class)
	local classCache = instanceCache[class]
	if not classCache then
		classCache = {}
		instanceCache[class] = classCache
	end
	local instance = table.remove(classCache)
	if not instance then
		instance = Instance.new(class, container)
		hide(instance)
	end
	return instance
end

local function release(instance)
	local class = instance.ClassName
	local classCache = instanceCache[class]
	if not classCache then
		classCache = {}
		instanceCache[class] = classCache
	end
	hide(instance)
	table.insert(classCache, instance)
end

------------------------------------------------------------------------------------------------------------------------
-- Style Instances
------------------------------------------------------------------------------------------------------------------------

local function applyStyleToAdornment(style : Style, adornment)
	adornment.Color3 = style.color
	adornment.Transparency = style.transparency
	adornment.ZIndex = style.layer
	adornment.Adornee = workspace
	adornment.AlwaysOnTop = true
end

local function applyStyleToHighlight(style : Style, highlight)
	highlight.FillColor = style.color
	highlight.OutlineColor = style.color
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

------------------------------------------------------------------------------------------------------------------------
-- Render Instances
------------------------------------------------------------------------------------------------------------------------

local function renderPoint(style, position: Vector3)
	local adornment = get("SphereHandleAdornment")
	adornment.Radius = style.scale * 0.5
	adornment.CFrame = CFrame.new(position)
	applyStyleToAdornment(style, adornment)
	table.insert(renderQueue, adornment)
end

local function renderBox(style, orientation: CFrame, size: Vector3)
	local adornment = get("BoxHandleAdornment")
	adornment.Size = size
	adornment.CFrame = orientation
	applyStyleToAdornment(style, adornment)
	table.insert(renderQueue, adornment)
end

-- If anyone has a better way to do this which is just as performant please let me know
local function renderWireBox(style, orientation: CFrame, size: Vector3)
	local x, y, z = size.X / 2, size.Y / 2, size.Z / 2
	local lineWidth = style.scale
	local sizeX = Vector3.new(size.X + lineWidth, lineWidth, lineWidth)
	local sizeY = Vector3.new(lineWidth, size.Y + lineWidth, lineWidth)
	local sizeZ = Vector3.new(lineWidth, lineWidth, size.Z + lineWidth)
	local relativeOrientation = orientation
	local adornmentX1 = get("BoxHandleAdornment")
	local adornmentX2 = get("BoxHandleAdornment")
	local adornmentX3 = get("BoxHandleAdornment")
	local adornmentX4 = get("BoxHandleAdornment")
	local adornmentY1 = get("BoxHandleAdornment")
	local adornmentY2 = get("BoxHandleAdornment")
	local adornmentY3 = get("BoxHandleAdornment")
	local adornmentY4 = get("BoxHandleAdornment")
	local adornmentZ1 = get("BoxHandleAdornment")
	local adornmentZ2 = get("BoxHandleAdornment")
	local adornmentZ3 = get("BoxHandleAdornment")
	local adornmentZ4 = get("BoxHandleAdornment")
	adornmentX1.Size = sizeX
	adornmentX1.CFrame = relativeOrientation * CFrame.new(0, y, z)
	adornmentX2.Size = sizeX
	adornmentX2.CFrame = relativeOrientation * CFrame.new(0, -y, z)
	adornmentX3.Size = sizeX
	adornmentX3.CFrame = relativeOrientation * CFrame.new(0, y, -z)
	adornmentX4.Size = sizeX
	adornmentX4.CFrame = relativeOrientation * CFrame.new(0, -y, -z)
	applyStyleToAdornment(style, adornmentX1)
	applyStyleToAdornment(style, adornmentX2)
	applyStyleToAdornment(style, adornmentX3)
	applyStyleToAdornment(style, adornmentX4)
	table.insert(renderQueue, adornmentX1)
	table.insert(renderQueue, adornmentX2)
	table.insert(renderQueue, adornmentX3)
	table.insert(renderQueue, adornmentX4)
	adornmentY1.Size = sizeY
	adornmentY1.CFrame = relativeOrientation * CFrame.new(x, 0, z)
	adornmentY2.Size = sizeY
	adornmentY2.CFrame = relativeOrientation * CFrame.new(-x, 0, z)
	adornmentY3.Size = sizeY
	adornmentY3.CFrame = relativeOrientation * CFrame.new(x, 0, -z)
	adornmentY4.Size = sizeY
	adornmentY4.CFrame = relativeOrientation * CFrame.new(-x, 0, -z)
	applyStyleToAdornment(style, adornmentY1)
	applyStyleToAdornment(style, adornmentY2)
	applyStyleToAdornment(style, adornmentY3)
	applyStyleToAdornment(style, adornmentY4)
	table.insert(renderQueue, adornmentY1)
	table.insert(renderQueue, adornmentY2)
	table.insert(renderQueue, adornmentY3)
	table.insert(renderQueue, adornmentY4)
	adornmentZ1.Size = sizeZ
	adornmentZ1.CFrame = relativeOrientation * CFrame.new(x, y, 0)
	adornmentZ2.Size = sizeZ
	adornmentZ2.CFrame = relativeOrientation * CFrame.new(-x, y, 0)
	adornmentZ3.Size = sizeZ
	adornmentZ3.CFrame = relativeOrientation * CFrame.new(x, -y, 0)
	adornmentZ4.Size = sizeZ
	adornmentZ4.CFrame = relativeOrientation * CFrame.new(-x, -y, 0)
	applyStyleToAdornment(style, adornmentZ1)
	applyStyleToAdornment(style, adornmentZ2)
	applyStyleToAdornment(style, adornmentZ3)
	applyStyleToAdornment(style, adornmentZ4)
	table.insert(renderQueue, adornmentZ1)
	table.insert(renderQueue, adornmentZ2)
	table.insert(renderQueue, adornmentZ3)
	table.insert(renderQueue, adornmentZ4)
end

local function renderSphere(style, position: Vector3, radius: number)
	local adornment = get("SphereHandleAdornment")
	adornment.Radius = radius
	adornment.CFrame = CFrame.new(position)
	applyStyleToAdornment(style, adornment)
	table.insert(renderQueue, adornment)
end

local function renderWireSphere(style, position: Vector3, radius: number)
	local offset = style.scale * 0.5
	local outerRadius, innerRadius = radius + offset, radius - offset
	local relativeOrientation = CFrame.new(position)
	local adornmentX = get("CylinderHandleAdornment")
	local adornmentY = get("CylinderHandleAdornment")
	local adornmentZ = get("CylinderHandleAdornment")
	adornmentX.Radius = outerRadius
	adornmentX.InnerRadius = innerRadius
	adornmentX.Height = style.scale
	adornmentX.CFrame = relativeOrientation
	applyStyleToAdornment(adornmentX)
	table.insert(renderQueue, adornmentX)
	adornmentY.Radius = outerRadius
	adornmentY.InnerRadius = innerRadius
	adornmentY.Height = style.scale
	adornmentY.CFrame = relativeOrientation * CFrame.Angles(math.pi * 0.5, 0, 0)
	applyStyleToAdornment(style, adornmentY)
	table.insert(renderQueue, adornmentY)
	adornmentZ.Radius = outerRadius
	adornmentZ.InnerRadius = innerRadius
	adornmentZ.Height = style.scale
	adornmentZ.CFrame = relativeOrientation * CFrame.Angles(0, math.pi * 0.5, 0)
	applyStyleToAdornment(style, adornmentZ)
	table.insert(renderQueue, adornmentZ)
end

local function renderLine(style, from: Vector3, to: Vector3)
	local distance = (to - from).Magnitude
	local adornment = get("CylinderHandleAdornment")
	adornment.Radius = style.scale * 0.5
	adornment.InnerRadius = 0
	adornment.Height = distance
	adornment.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance * 0.5)
	applyStyleToAdornment(style, adornment)
	table.insert(renderQueue, adornment)
end

local function renderArrow(style, from: Vector3, to: Vector3)
	local coneHeight = style.scale * 3
	local distance = math.abs((to - from).Magnitude - coneHeight)
	local orientation = CFrame.lookAt(from, to)
	local adornmentLine = get("CylinderHandleAdornment")
	local adornmentCone = get("ConeHandleAdornment")
	adornmentLine.Radius = style.scale * 0.5
	adornmentLine.InnerRadius = 0
	adornmentLine.Height = distance
	adornmentLine.CFrame = orientation * CFrame.new(0, 0, -distance * 0.5)
	applyStyleToAdornment(style, adornmentLine)
	adornmentCone.Height = coneHeight
	adornmentCone.Radius = coneHeight * 0.5
	adornmentCone.CFrame = orientation * CFrame.new(0, 0, -distance)
	applyStyleToAdornment(style, adornmentCone)
	table.insert(renderQueue, adornmentLine)
	table.insert(renderQueue, adornmentCone)
end

local function renderRay(style, from: Vector3, direction: Vector3)
	return renderArrow(style, from, from + direction)
end

------------------------------------------------------------------------------------------------------------------------
-- Gizmo Class Wrapper
------------------------------------------------------------------------------------------------------------------------

local function createGizmo<T...>(render: (Style, T...) -> ())
	
	local class = {__index={}}
	
	function class.draw(... : T...)
		if active then
			render(globalStyle, ...)
		end
	end
	
	type Object = typeof(setmetatable({} :: Gizmo, class))
	
	function class.create(... : T...) : Object
		return setmetatable({
			__properties = table.pack(...),
			style = table.clone(globalStyle)
		}, class)
	end
	
	function class.__index:enable()
		scheduledObjects[self] = true
	end
	
	function class.__index:disable()
		scheduledObjects[self] = nil
	end
	
	function class.__index:update(... : T...)
		self.__properties = table.pack(...)
	end
	
	function class.__index:__render()
		render(self.style, table.unpack(self.__properties))
	end
	
	return table.freeze(class)
end

------------------------------------------------------------------------------------------------------------------------
-- Render Update
------------------------------------------------------------------------------------------------------------------------

local function update()
	-- All gizmos created with 'create' need to be queued for render
	for object in pairs(scheduledObjects) do
		object:__render()
	end
	-- Clone the queue and render all instances in it
	local queue = table.clone(renderQueue)
	for _, instance in ipairs(queue) do
		instance.Visible = true
	end
	table.clear(renderQueue)
	task.wait()
	for _, instance in ipairs(queue) do
		release(instance)
	end
end

------------------------------------------------------------------------------------------------------------------------
-- State Management
------------------------------------------------------------------------------------------------------------------------

local function enable()
	active = true
	RunService:BindToRenderStep(moduleId, Enum.RenderPriority.Last.Value + 1, update)
end

local function disable()
	active = false
	RunService:UnbindFromRenderStep(moduleId)
end

workspace:GetAttributeChangedSignal(GLOBAL_ATTRIBUTE):Connect(function ()
	if workspace:GetAttribute(GLOBAL_ATTRIBUTE) then
		enable()
	else
		disable()
	end
end)

if workspace:GetAttribute(GLOBAL_ATTRIBUTE) then
	enable()
end

------------------------------------------------------------------------------------------------------------------------
-- Exports
------------------------------------------------------------------------------------------------------------------------

return table.freeze {
	
	-- Globals
	style = globalStyle,
	
	-- Gizmos
	point = createGizmo(renderPoint),
	box = createGizmo(renderBox),
	wireBox = createGizmo(renderWireBox),
	sphere = createGizmo(renderSphere),
	wireSphere = createGizmo(renderWireSphere),
	line = createGizmo(renderLine),
	arrow = createGizmo(renderArrow),
	ray = createGizmo(renderRay),
	
}
