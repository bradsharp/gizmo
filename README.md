# About

_gizmo_ is a visual debug library designed for the Roblox game engine.

# Usage

## gizmo.<type>.draw(...) -> void

Renders the gizmo for a single frame

## gizmo.<type>.create(...) -> object

Creates a new object which can be rendered over multiple frames

### object:enable() -> void

Starts rendering the gizmo

### object:disable() -> void

Stops rendering the gizmo

### object:update(...) -> void

Updates the gizmos appearance

### object.style

Controls the 'style' of the gizmo

## gizmo.style

The global style used by default when creating or drawing a gizmo

## types

- point
- box
- wirebox
- sphere
- wiresphere
- line
- arrow
- ray

# Examples

## Drawing an array frame-by-frame

```lua
RunService.PostSimulation:Connect(function ()
  gizmo.arrow.draw(start, finish)
end)
```

## Drawing an array with an object


```lua
local arrow = gizmo.arrow.create(start, finish)
arrow:enable()

RunService.PostSimulation:Connect(function ()
  arrow:update(start, finish)
end)
```
