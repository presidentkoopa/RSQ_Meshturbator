// MT_VR -- the two controllers, as QuestZDoom 17.3 exposes them (read only). The one file that touches
// the engine's VR fields.
//
//   mo.AttackPos / mo.OffhandPos          the weapon / off controller, world position
//   mo.AttackDir(mo, a, p) / OffhandDir   a direction given in that controller's frame -> world (angle, pitch)
//   mo.player.PlayInVR, mo.OverrideAttackPosDir   playing in VR with the weapon on the controller
//
// Units. The gun frame is (F, L, U) in CENTIMETRES from the weapon controller: forward along the
// controller, left, up. A HUD model drawn on a layer of that hand with MODELDEF Scale 1 is in the same
// centimetres (models.cpp RenderHUDModel scales the controller transform by 0.01), so a point measured
// here is a point on the drawn model. World heights are squashed by pixelstretch in the engine's hand
// transform; it is taken back out here. vr_vunits_per_meter (34 by default) turns map units into metres.
class MT_VR
{
	clearscope static bool InVR(PlayerPawn mo)
	{
		return mo && mo.player && mo.player.PlayInVR && mo.OverrideAttackPosDir;
	}

	clearscope static double Stretch(PlayerPawn mo)
	{
		double ps = mo.Level.pixelstretch;
		return ps > 0 ? ps : 1.2;
	}

	// map units per metre
	clearscope static double VU()
	{
		let cv = CVar.FindCVar('vr_vunits_per_meter');
		double vu = cv ? cv.GetFloat() : 34;
		return vu > 0 ? vu : 34;
	}

	// a unit vector in the world for a direction given in a controller's frame (yaw 0 pitch 0 = forward,
	// yaw +90 = left, pitch +90 = up), off = the off controller
	play static Vector3 Dir(PlayerPawn mo, bool off, double yaw, double pitch)
	{
		Vector3 ap = off ? mo.OffhandDir(mo, mo.angle + yaw, mo.pitch + pitch)
						 : mo.AttackDir(mo, mo.angle + yaw, mo.pitch + pitch);
		double cp = cos(ap.y);
		Vector3 v = (cp * cos(ap.x), cp * sin(ap.x), -sin(ap.y) * Stretch(mo));
		double l = v.Length();
		return l > 0 ? v / l : (1, 0, 0);
	}

	// the three axes of a controller's frame, in the world (no `out` vectors: the 4.14 VM has no
	// address-of for vectors -- "REGT_ADDROF not implemented for vectors")
	play static Vector3 AxisF(PlayerPawn mo, bool off) { return Dir(mo, off, 0, 0); }
	play static Vector3 AxisL(PlayerPawn mo, bool off) { return Dir(mo, off, 90, 0); }
	play static Vector3 AxisU(PlayerPawn mo, bool off) { return Dir(mo, off, 0, 90); }

	clearscope static Vector3 Origin(PlayerPawn mo, bool off)
	{
		return off ? mo.OffhandPos : mo.AttackPos;
	}

	// a world point -> (F, L, U) cm in a controller's frame
	play static Vector3 ToFrame(PlayerPawn mo, bool off, Vector3 world)
	{
		Vector3 w = world - Origin(mo, off);
		w.z *= Stretch(mo);
		w *= 100.0 / VU();
		return (w dot AxisF(mo, off), w dot AxisL(mo, off), w dot AxisU(mo, off));
	}

	// (F, L, U) cm in a controller's frame -> a world point
	play static Vector3 ToWorld(PlayerPawn mo, bool off, Vector3 flu)
	{
		Vector3 w = (AxisF(mo, off) * flu.x + AxisL(mo, off) * flu.y + AxisU(mo, off) * flu.z) * (VU() / 100.0);
		w.z /= Stretch(mo);
		return Origin(mo, off) + w;
	}

	// a direction (F, L, U) in one controller's frame, expressed in the other's
	play static Vector3 DirBetween(PlayerPawn mo, bool fromOff, Vector3 flu)
	{
		Vector3 w = AxisF(mo, fromOff) * flu.x + AxisL(mo, fromOff) * flu.y + AxisU(mo, fromOff) * flu.z;
		return (w dot AxisF(mo, !fromOff), w dot AxisL(mo, !fromOff), w dot AxisU(mo, !fromOff));
	}

	// a point (F, L, U) cm in a controller's frame -> a layer translation for a HUD model on that hand with
	// MODELDEF Scale (sx, sy, sz): the renderer's model axes are x left, y up, z back (models.cpp)
	clearscope static Vector3 LayerShift(Vector3 flu, Vector3 scale)
	{
		return (flu.y / scale.x, flu.z / scale.z, -flu.x / scale.y);
	}

	// this tic's buttons
	clearscope static int Buttons(PlayerPawn mo)
	{
		return mo.player ? mo.player.cmd.buttons : 0;
	}
}
