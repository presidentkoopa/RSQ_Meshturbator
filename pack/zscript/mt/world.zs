// Parts in the world: a dropped magazine (picked up again with its rounds), a spent case or a live
// round thrown from the port. Looks and physics are ours (the engine has no collision between parts).

class MT_DroppedPart : Actor
{
	int part;			// archetype part index
	int rounds;
	int ownerNum;		// player number (netplay: whose it is -- anyone may pick it up, but it is listed per owner)
	String archName;

	Default
	{
		Radius 4;
		Height 6;
		Mass 20;
		BounceType "Doom";
		BounceFactor 0.25;
		WallBounceFactor 0.4;
		Gravity 1.0;
		Speed 0;
		+MISSILE
		+NOBLOCKMAP
		+DROPOFF
		+NOTELEPORT
		+THRUACTORS
		+FORCEXYBILLBOARD
		-NOGRAVITY
		+USEBOUNCESTATE
		+CANBOUNCEWATER
		+NOEXPLODEFLOOR
		+NOTRIGGER
		RenderStyle "Normal";
	}

	States
	{
	Spawn:
		MTP1 B 1;		// the frame is set per part after spawn
		Loop;
	Bounce:
		MTP1 B 1 A_Landed;
		Goto Spawn;
	Death:
		MTP1 B -1;
		Stop;
	}

	void A_Landed()
	{
		if (vel.Length() < 1.5)
		{
			A_StartSound("mt/magland", CHAN_BODY, CHANF_OVERLAP, 0.8);
			vel = (0, 0, 0);
			bMISSILE = false;
			SetStateLabel("Death");
		}
	}

	static MT_DroppedPart Make(PlayerPawn mo, int part, MT_Arch a, Vector3 at, Vector3 vel, int rounds)
	{
		let d = MT_DroppedPart(Actor.Spawn('MT_DroppedPart', at));
		if (!d)
			return null;
		d.part = part;
		d.rounds = rounds;
		d.ownerNum = mo.PlayerNumber();
		d.archName = a.name;
		d.frame = (a.parts[part].emptyFrame >= 0 && rounds <= 0) ? a.parts[part].emptyFrame : a.parts[part].frame;
		d.vel = vel * 1.0;				// the hand's motion this tic, map units
		d.vel.z += 0.5;
		d.angle = mo.angle;
		return d;
	}

	// the nearest dropped part of this player within reach (cm) of a world point
	static MT_DroppedPart Nearest(PlayerPawn mo, Vector3 at, double reachCm)
	{
		double reach = reachCm * MT_VR.VU() / 100.0;
		MT_DroppedPart best = null;
		double bd = reach;
		let it = ThinkerIterator.Create('MT_DroppedPart');
		Actor a;
		while (a = Actor(it.Next()))
		{
			let d = MT_DroppedPart(a);
			if (d.ownerNum != mo.PlayerNumber())
				continue;
			Vector3 w = d.pos - at;
			w.z *= MT_VR.Stretch(mo);
			double dist = w.Length();
			if (dist < bd)
			{
				bd = dist;
				best = d;
			}
		}
		return best;
	}
}

// a spent case, or a live round pulled out by the handle. Model: models/mt/casing (RS_Ballistics' rifle case).
class MT_Casing : Actor
{
	Default
	{
		Radius 1;
		Height 1;
		Mass 1;
		BounceType "Doom";
		BounceFactor 0.35;
		WallBounceFactor 0.5;
		Gravity 0.8;
		+MISSILE
		+NOBLOCKMAP
		+DROPOFF
		+NOTELEPORT
		+THRUACTORS
		+USEBOUNCESTATE
		+NOEXPLODEFLOOR
		+NOTRIGGER
		+ROLLSPRITE
	}

	int bounces;

	States
	{
	Spawn:
		MTCS A 1 A_Spin;
		Loop;
	Bounce:
		MTCS A 1 A_Hit;
		Goto Spawn;
	Death:
		MTCS A 350;
		MTCS A 1 A_FadeOut(0.05);
		Wait;
	}

	void A_Spin()
	{
		pitch += 25;
		roll += 11;
	}

	void A_Hit()
	{
		bounces++;
		if (bounces == 1)
			A_StartSound("mt/brass", CHAN_BODY, CHANF_OVERLAP, 0.7);
		if (vel.Length() < 1.0 || bounces > 4)
		{
			vel = (0, 0, 0);
			bMISSILE = false;
			pitch = 0;
			SetStateLabel("Death");
		}
	}

	static void Throw(PlayerPawn mo, Vector3 at, Vector3 dir, bool live)
	{
		let c = MT_Casing(Actor.Spawn('MT_Casing', at));
		if (!c)
			return;
		c.frame = live ? 1 : 0;
		c.vel = dir.Unit() * (live ? 2.5 : 4.0) + (frandom(-0.4, 0.4), frandom(-0.4, 0.4), frandom(0, 0.6)) + mo.vel;
		c.angle = mo.angle + 90;
	}
}
