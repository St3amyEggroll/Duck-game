--!strict
-- AimUtil (ModuleScript) | ReplicatedStorage > DuckShared
-- Shared aim posing: point the gun + lean the torso toward an aim angle.
-- Called by BOTH the client (instant local feel) and the server (which
-- replicates the pose to every other player).

local AimUtil = {}

function AimUtil.applyAim(torso: BasePart?, gunMotor: Motor6D?, rootJoint: Motor6D?, restC0: CFrame?, angle: number, maxTilt: number, tiltSign: number)
	if not torso or not torso.Parent then
		return
	end
	local aimDir = Vector3.new(math.cos(angle), math.sin(angle), 0)
	local pivot = torso.Position + Vector3.new(0, 0.5, 0)

	if gunMotor then
		local gunCF = CFrame.lookAt(pivot, pivot + aimDir, Vector3.new(0, 0, 1))
		gunMotor.C0 = torso.CFrame:ToObjectSpace(gunCF)
	end

	if rootJoint and restC0 then
		local faceRight = aimDir.X >= 0
		local elevation = math.atan2(aimDir.Y, math.abs(aimDir.X))
		local tilt = math.clamp(elevation, -maxTilt, maxTilt) * (faceRight and 1 or -1) * tiltSign
		rootJoint.C0 = restC0 * CFrame.Angles(tilt, 0, 0)
	end
end

return AimUtil
