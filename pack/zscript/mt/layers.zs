// Drawing the parts. Two callers, one placer.
//
// MT_Carrier (an Inventory the player holds) owns the layers of parts ON the gun. The engine draws any
// layer whose caller is not the off-hand weapon at the WEAPON controller (models.cpp RenderHUDModel:
// hand = caller == OffhandWeapon ? 1 : 0), whatever the caller is.
// MT_Hands (our off-hand weapon) owns the layers of parts IN the off hand, drawn at the off controller.
// The engine resolves ModifyBobLayer3D on the class of the layer the WeaponPosition3D picks: for a
// caller that is not the ReadyWeapon that is the off-hand weapon's psprite (hw_weapon.cpp
// GetWeaponPosition3D), so MT_Hands.ModifyBobLayer3D places BOTH callers' layers. It must be the
// off-hand weapon for any of this to draw; MT_Handler keeps it there.
//
// Layer ids: GUN_FIRST + part index for parts on the gun, HAND_FIRST + part index for a part in the
// hand, FIST for the off hand itself. The sprite frame of each layer is the part's (MODELDEF binds the
// part's model to the archetype sprite's frame A, B, C ...).
class MT_Layers
{
	const GUN_FIRST = 3000;
	const HAND_FIRST = 3100;
	const FIST = 3200;
	const COUNT = 26;

	static bool IsGun(int id) { return id >= GUN_FIRST && id < GUN_FIRST + COUNT; }
	static bool IsHand(int id) { return id >= HAND_FIRST && id < HAND_FIRST + COUNT; }

	// put a layer on a caller in a state (or take it off: label ""), with the flags every part layer has
	play static void Set(PlayerInfo p, int id, Actor caller, State st)
	{
		let psp = p.FindPSprite(id);
		if (!st)
		{
			if (psp)
				p.SetPsprite(id, null);
			return;
		}
		if (psp && psp.Caller == caller && psp.CurState == st)
			return;
		p.SetPsprite(id, st, false, caller);
		psp = p.FindPSprite(id);
		if (psp)
		{
			psp.bAddWeapon = false;
			psp.bAddBob = true;		// the engine calls ModifyBobLayer3D only for a layer with PSPF_ADDBOB
			// a layer at y 0 is tilted 8 degrees by the renderer ((y - WEAPONTOP) / -4): sit at WEAPONTOP
			psp.y = WEAPONTOP;
			psp.oldy = WEAPONTOP;
			psp.x = 0;
			psp.oldx = 0;
		}
	}
}

class MT_Carrier : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
		+INVENTORY.PERSISTENTPOWER
	}

}

class MT_Hands : Weapon
{
	Default
	{
		Weapon.SlotNumber 0;
		+WEAPON.NOALERT
		+WEAPON.NOAUTOFIRE
		+WEAPON.OFFHANDWEAPON
		+WEAPON.CHEATNOTWEAPON
		+WEAPON.NOAUTOAIM
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		Inventory.PickupMessage "";
	}

	States
	{
	Ready:
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE | WRF_NOBOB);
		Loop;
	Deselect:
		TNT1 A 1 A_Lower(64);
		Loop;
	Select:
		TNT1 A 1 A_Raise(64);
		Loop;
	Fire:
	AltFire:
		TNT1 A 1;
		Goto Ready;
	Spawn:
		TNT1 A -1;
		Stop;
	// the part layers' states, one label per archetype sprite (a psprite state must belong to a weapon
	// class: "not flagged for use in weapons" otherwise). The frame is set on the layer after SetPsprite.
	MTP1:
		MTP1 A -1;
		Stop;
	}

	// per rendered frame: where each part layer sits. Translation is in the model's own units; with
	// MODELDEF Scale 1 one unit is one centimetre on axes (x left, y up, z back) -- MT_VR.LayerShift.
	override Vector3, Vector3 ModifyBobLayer3D(Vector3 translation, Vector3 rotation, int layer, double ticfrac)
	{
		let mo = PlayerPawn(Owner);
		let g = MT_Handler.GunOf(mo);
		if (!g)
			return translation, rotation;
		if (MT_Layers.IsGun(layer))
		{
			int i = layer - MT_Layers.GUN_FIRST;
			if (i >= g.parts.Size())
				return translation, rotation;
			let d = g.arch.parts[i];
			let s = g.parts[i];
			double t = s.tPrev + (s.t - s.tPrev) * ticfrac;
			if (d.joint == 'follow')
			{
				int f = g.arch.PartIndex(d.follows);
				t = f == g.handleIndex || f < 0 ? g.boltTPrev + (g.boltT - g.boltTPrev) * ticfrac
												   : g.parts[f].tPrev + (g.parts[f].t - g.parts[f].tPrev) * ticfrac;
				if (f >= 0)
					return translation + MT_VR.LayerShift(g.arch.parts[f].axis * t, (1, 1, 1)), rotation;
			}
			return translation + MT_VR.LayerShift(d.axis * t, (1, 1, 1)), rotation;
		}
		if (MT_Layers.IsHand(layer))
		{
			int i = layer - MT_Layers.HAND_FIRST;
			if (i >= g.parts.Size())
				return translation, rotation;
			let d = g.arch.parts[i];
			// the part's model is authored at its seated place in GUN space; carried, its grab point rides
			// the off controller at holdOff (where the hand took it)
			return translation + MT_VR.LayerShift(g.holdOff - d.grab, (1, 1, 1)), rotation;
		}
		return translation, rotation;
	}
}

// the off-hand haptic: QuestZDoom buzzes the hand that launches a missile (ALF_ISOFFHAND)
class MT_Buzz : Actor
{
	Default
	{
		Projectile;
		+NOCLIP
		Radius 1;
		Height 1;
		Speed 1;
		RenderStyle "None";
	}
	States
	{
	Spawn:
		TNT1 A 1;
		Stop;
	}
}
