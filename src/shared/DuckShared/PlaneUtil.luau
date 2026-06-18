--!strict
-- PlaneUtil (ModuleScript) | ReplicatedStorage > DuckShared
-- Shared mouse->play-plane projection. Both the movement controller and the
-- weapon controller need the cursor's position on the Z = planeZ play plane,
-- so it lives here once instead of being copy-pasted into each.

local UserInputService = game:GetService("UserInputService")

local PlaneUtil = {}

-- Project the mouse cursor onto the Z = planeZ play plane.
-- Returns nil if the camera ray runs parallel to the plane.
function PlaneUtil.mouseWorldOnPlane(planeZ: number): Vector3?
	local cam = workspace.CurrentCamera
	if not cam then
		return nil
	end
	local m = UserInputService:GetMouseLocation()
	local ray = cam:ViewportPointToRay(m.X, m.Y)
	local dz = ray.Direction.Z
	if math.abs(dz) < 1e-6 then
		return nil
	end
	local t = (planeZ - ray.Origin.Z) / dz
	return ray.Origin + ray.Direction * t
end

return PlaneUtil
