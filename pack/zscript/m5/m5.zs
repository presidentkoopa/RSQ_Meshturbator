// MT_M5 -- the Colt M5 SCW, the first weapon of this pack (owner: "write a m5 weapon code with dummy
// sprites, improvise rate of fire"). Layer 2 without layer 3: this is OUR weapon, so it talks to its
// MT_Gun directly and the ammo gate is not involved. Fire, damage and rate are improvised placeholders;
// the mechanism (chamber, magazine, bolt) is the part system's.
//
// Rate: ~700 rpm = one shot per 3 tics. Report: a stock Doom sound for now (no rifle report in the
// repo's sources); the tail after each shot is RS_Ballistics' AR tail (models/sounds credited in
// assets/ASSETS.md). Casings: RS_Ballistics' 5.56 case mesh.
class MT_Rounds : Ammo
{
	Default
	{
		Inventory.MaxAmount 999;
		Ammo.BackpackMaxAmount 999;
		Inventory.Icon "TNT1A0";
	}
}

class MT_M5 : MT_OwnWeapon
{
	Default
	{
		Weapon.SlotNumber 4;
		Weapon.SelectionOrder 700;
		Weapon.AmmoType1 "MT_Rounds";		// what the HUD shows: rounds in the gun (the part system sets it)
		Weapon.AmmoUse1 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType2 "Clip";			// the reserve the magazines draw from
		Weapon.AmmoUse2 0;
		Weapon.AmmoGive2 60;
		+WEAPON.AMMO_OPTIONAL
		+WEAPON.NOAUTOAIM
		Inventory.PickupMessage "You got the M5 SCW.";
		Tag "Colt M5 SCW";
	}

	override String ArchName() { return "m5"; }

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	Ready:
		TNT1 A 1
		{
			A_MT_Gate();
			A_WeaponReady();
		}
		Loop;
	Deselect:
		TNT1 A 1 A_Lower(18);
		Loop;
	Select:
		TNT1 A 1 A_Raise(18);
		Loop;
	Fire:
		TNT1 A 1 A_MT_Fire;
		TNT1 A 2 A_MT_Gate;
		TNT1 A 0 A_ReFire;
		Goto Ready;
	}

	// the HUD's ammo count is the gun's real content
	action void A_MT_Gate()
	{
		let mo = PlayerPawn(self);
		let g = MT_Handler.GunOf(mo);
		int n = g ? g.RoundsShown() : 0;
		int have = mo.CountInv('MT_Rounds');
		if (have != n)
		{
			if (n > have) mo.GiveInventory('MT_Rounds', n - have);
			else mo.TakeInventory('MT_Rounds', have - n);
		}
	}

	action void A_MT_Fire()
	{
		let mo = PlayerPawn(self);
		let g = MT_Handler.GunOf(mo);
		if (!g)
			return;
		if (!g.Fire())
		{
			A_StartSound("mt/click", CHAN_WEAPON, CHANF_OVERLAP, 0.8);
			return;
		}
		A_StartSound("mt/m5fire", CHAN_WEAPON, CHANF_OVERLAP);
		A_StartSound("mt/m5tail", CHAN_6, CHANF_OVERLAP, 0.7);
		A_FireBullets(2.2, 1.6, 1, 11, "BulletPuff", FBF_NORANDOM | FBF_USEAMMO);
		A_AlertMonsters();
	}
}
