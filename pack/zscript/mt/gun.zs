// The part system: one MT_Gun per player per weapon (playsim, per player, netplay-safe), holding every
// part's state and the gun's mechanical state. The hand does one thing here: grab. Everything else is
// a joint saying what the grabbed part may do, and detents saying what happens when it gets there.
//
// A part is at one of these places:
//   ON_GUN     seated / parked on the gun, at travel t along its joint (0 = home)
//   CAPTURED   in the hand AND inside its joint's capture zone: drawn on the gun, guided along the axis
//   IN_HAND    carried by the off controller, free of the joint
//   WORLD      dropped: an MT_DroppedPart actor exists for it
//   ABSENT     gone (the player took a fresh one from the pouch instead)
class MT_PartState
{
	int where;
	double t, tPrev;		// cm along the joint's axis (0 = home)
	int rounds;				// a magazine's content
	int springTics;			// a sprung part on its way home
	MT_DroppedPart dropped;
}

class MT_Gun play
{
	const ON_GUN = 0;
	const CAPTURED = 1;
	const IN_HAND = 2;
	const WORLD = 3;
	const ABSENT = 4;

	PlayerPawn mo;
	MT_Arch arch;
	Array<MT_PartState> parts;
	int magIndex, handleIndex, boltIndex;
	int held;				// part index in the hand (CAPTURED / IN_HAND / a sprung slide being pulled), or -1
	Vector3 holdOff;		// where the held part's grab point rides, in the off controller's frame (cm)
	bool grabWas;			// last tic's grab button, for the edge
	Vector3 offPrev;		// the off controller a tic ago (world), for the velocity of a dropped part
	// the mechanism
	bool chambered;
	bool boltLocked;		// the bolt catch holds the bolt back (empty, or the handle pulled on an empty gun)
	int cycleTics;			// the bolt on its way forward after a shot or a release
	double boltT, boltTPrev;
	// bookkeeping
	int lastEvent;			// maptime of the last state change (debug)

	static MT_Gun Make(PlayerPawn mo, MT_Arch a)
	{
		let g = new('MT_Gun');
		g.mo = mo;
		g.arch = a;
		g.held = -1;
		g.magIndex = a.PartIndex("mag");
		g.handleIndex = a.PartIndex("handle");
		g.boltIndex = a.PartIndex("bolt");
		for (int i = 0; i < a.parts.Size(); i++)
		{
			let s = new('MT_PartState');
			s.where = a.parts[i].joint == 'free' ? ABSENT : ON_GUN;
			g.parts.Push(s);
		}
		// a gun is handed over loaded: a seated magazine and a round in the chamber
		if (g.magIndex >= 0)
			g.parts[g.magIndex].rounds = a.capacity;
		g.chambered = true;
		return g;
	}

	MT_PartState Mag() { return magIndex >= 0 ? parts[magIndex] : null; }
	bool MagSeated() { let m = Mag(); return m && m.where == ON_GUN; }
	int RoundsShown() { let m = Mag(); return (m && m.where == ON_GUN ? m.rounds : 0) + (chambered ? 1 : 0); }

	void Say(String what)
	{
		lastEvent = mo.Level.maptime;
		if (MT_Settings.Debug())
			Console.Printf("MT t%d %s: %s", mo.Level.maptime, arch.name, what);
	}

	// ---------------------------------------------------------------- points
	// a part's grab point now, in the gun frame
	Vector3 GrabNow(int i)
	{
		let d = arch.parts[i];
		return d.grab + d.axis * parts[i].t;
	}

	// where the held part's grab point is now, in the gun frame: it rides the off controller at holdOff,
	// which is where the hand took it (from the gun: wherever the controller was inside the grab
	// radius; from the pouch or the floor: the archetype's `hold`)
	Vector3 HeldGrabInGun()
	{
		return MT_VR.ToFrame(mo, false, MT_VR.ToWorld(mo, true, holdOff));
	}

	// ---------------------------------------------------------------- the tic
	void Tick()
	{
		if (!MT_VR.InVR(mo))
		{
			Settle();
			return;
		}
		bool grab = MT_Settings.GrabHeld(mo);
		bool pressed = grab && !grabWas;
		bool released = !grab && grabWas;
		grabWas = grab;
		for (int i = 0; i < parts.Size(); i++)
			parts[i].tPrev = parts[i].t;
		boltTPrev = boltT;

		if (held >= 0)
			Holding(grab, released);
		else if (pressed)
			TryGrab();
		Springs();
		Cycle();
		offPrev = MT_VR.Origin(mo, true);
	}

	// not in VR: everything home, the gun behaves as a loaded gun
	void Settle()
	{
		for (int i = 0; i < parts.Size(); i++)
			if (parts[i].where == CAPTURED || parts[i].where == IN_HAND)
				parts[i].where = ON_GUN;
		held = -1;
	}

	// the grab button went down with nothing in the hand: a part on the gun within reach, a dropped
	// part on the floor within reach, or a fresh magazine from the pouch
	void TryGrab()
	{
		Vector3 hand = MT_VR.ToFrame(mo, false, MT_VR.Origin(mo, true));
		int best = -1;
		double bestD = 1e9;
		for (int i = 0; i < parts.Size(); i++)
		{
			let d = arch.parts[i];
			if (d.joint != 'slide' || parts[i].where != ON_GUN)
				continue;
			double dist = (hand - GrabNow(i)).Length();
			if (dist < d.radius && dist < bestD)
			{
				best = i;
				bestD = dist;
			}
		}
		if (best >= 0)
		{
			held = best;
			parts[best].where = CAPTURED;
			holdOff = MT_VR.ToFrame(mo, true, MT_VR.ToWorld(mo, false, GrabNow(best)));
			Buzz();
			Say(String.Format("grabbed %s on the gun (%.1f cm off its grab point)", arch.parts[best].name, bestD));
			return;
		}
		// a dropped part nearby
		let drop = MT_DroppedPart.Nearest(mo, MT_VR.Origin(mo, true), 20.0);
		if (drop && drop.part >= 0 && drop.part < parts.Size())
		{
			let s = parts[drop.part];
			s.where = IN_HAND;
			s.rounds = drop.rounds;
			s.dropped = null;
			held = drop.part;
			holdOff = arch.parts[held].hold;
			drop.Destroy();
			Buzz();
			Say(String.Format("picked %s up from the floor (%d rounds)", arch.parts[held].name, s.rounds));
			return;
		}
		// the pouch: a fresh magazine
		if (magIndex >= 0 && AtPouch())
		{
			let m = Mag();
			if (m.where == ON_GUN || m.where == CAPTURED)
				return;				// the gun still has one; take that out first
			int reserve = mo.CountInv(arch.reserve);
			if (reserve <= 0)
			{
				Say("pouch: no reserve ammo");
				return;
			}
			int take = min(arch.capacity, reserve);
			mo.TakeInventory(arch.reserve, take);
			m.rounds = take;
			m.where = IN_HAND;
			m.dropped = null;
			held = magIndex;
			holdOff = arch.parts[held].hold;
			Buzz();
			Say(String.Format("fresh magazine from the pouch: %d rounds (%d left in reserve)", take, reserve - take));
		}
	}

	// the pouch is at the hip: the off controller well below the eyes, and not up at the gun
	bool AtPouch()
	{
		if (!arch.pouchHip)
		{
			Vector3 hand = MT_VR.ToFrame(mo, false, MT_VR.Origin(mo, true));
			return (hand - arch.pouch).Length() < 15.0;
		}
		double vu = MT_VR.VU();
		Vector3 off = MT_VR.Origin(mo, true);
		double drop = (mo.player.viewz - off.z) * MT_VR.Stretch(mo) * 100.0 / vu;	// cm below the eyes
		return drop > 45.0;
	}

	// a part is in the hand
	void Holding(bool grab, bool released)
	{
		let d = arch.parts[held];
		let s = parts[held];
		if (d.spring)
		{
			// a sprung slide (the charging handle): it only ever moves along its axis, with the hand
			Vector3 hand = MT_VR.ToFrame(mo, false, MT_VR.Origin(mo, true));
			double along = (hand - d.grab) dot d.axis;
			s.t = clamp(along, 0, d.travel);
			if (released || !grab)
			{
				Say(String.Format("let go of the %s at %.1f of %.1f cm", d.name, s.t, d.travel));
				HandleReleased(s.t >= d.travel - 0.5);
				s.springTics = 3;
				s.where = ON_GUN;
				held = -1;
			}
			return;
		}
		if (s.where == CAPTURED)
		{
			// guided along the well: the part's grab point (riding the hand) projected onto the axis
			Vector3 rel = HeldGrabInGun() - d.grab;
			double along = rel dot d.axis;
			double perp = (rel - d.axis * along).Length();
			if (along > d.travel + 1.0)
			{
				s.where = IN_HAND;
				s.t = d.travel;
				Say(String.Format("%s is out, in the hand", d.name));
			}
			else if (perp > d.radius * 1.5 && along > d.travel * 0.5)
			{
				s.where = IN_HAND;
				Say(String.Format("%s came out sideways (%.1f cm off the axis)", d.name, perp));
			}
			else
			{
				s.t = clamp(along, 0, d.travel);
				if (d.detent && s.t < 0.6 && s.tPrev >= 0.6)
					Click();
			}
			if (released)
			{
				if (d.detent && s.t < 0.6)
				{
					s.t = 0;
					s.where = ON_GUN;
					Buzz();
					Say(String.Format("%s seated (%d rounds)", d.name, s.rounds));
					Seated(held);
					held = -1;
				}
				else
					Drop();
			}
			return;
		}
		if (s.where == IN_HAND)
		{
			// carried free; does it enter a well?
			if (held == magIndex)
			{
				Vector3 g = HeldGrabInGun();
				Vector3 rel = g - d.grab;
				double along = rel dot d.axis;
				double perp = (rel - d.axis * along).Length();
				if (perp < d.radius && along > -1.0 && along < d.travel - 0.5)
				{
					s.where = CAPTURED;
					s.t = clamp(along, 0, d.travel);
					Buzz();
					Say(String.Format("%s caught by the well at %.1f cm (%.1f off axis)", d.name, s.t, perp));
				}
			}
			if (released)
				Drop();
		}
	}

	void Drop()
	{
		let d = arch.parts[held];
		let s = parts[held];
		Vector3 at = MT_VR.ToWorld(mo, true, holdOff);
		Vector3 vel = (MT_VR.Origin(mo, true) - offPrev);
		s.dropped = MT_DroppedPart.Make(mo, held, arch, at, vel, s.rounds);
		s.where = WORLD;
		Say(String.Format("dropped the %s (%d rounds)", d.name, s.rounds));
		held = -1;
	}

	void Seated(int i)
	{
		// a magazine seated into a gun whose bolt is locked back: it stays back (the bolt catch) until the
		// handle is pulled, as on the real thing
	}

	// sprung parts return home
	void Springs()
	{
		for (int i = 0; i < parts.Size(); i++)
		{
			let d = arch.parts[i];
			let s = parts[i];
			if (d.spring && i != held && s.t > 0)
			{
				s.t = max(0, s.t - d.travel / 3.0);
			}
		}
	}

	// ---------------------------------------------------------------- the mechanism
	// the trigger: true if a shot leaves
	bool Fire()
	{
		if (!chambered)
		{
			Say("click: no round chambered");
			return false;
		}
		chambered = false;
		EjectCase(false);
		Chamber();
		return true;
	}

	// the bolt comes forward: strips a round from a seated magazine if it can, else locks back
	void Chamber()
	{
		let m = Mag();
		if (m && m.where == ON_GUN && m.rounds > 0)
		{
			m.rounds--;
			chambered = true;
			boltLocked = false;
			cycleTics = 2;
			boltT = handleIndex >= 0 ? arch.parts[handleIndex].travel : 0;	// the bolt flies back, then home
		}
		else
		{
			boltLocked = true;
			if (boltIndex >= 0 && handleIndex >= 0)
				boltT = arch.parts[handleIndex].travel;
			Say(String.Format("bolt locked back (%s)", m && m.where == ON_GUN ? "magazine empty" : "no magazine"));
		}
	}

	// the charging handle let go: fully back = a cycle (a chambered round is thrown out live)
	void HandleReleased(bool fullyBack)
	{
		if (!fullyBack)
			return;
		if (chambered)
		{
			EjectCase(true);
			chambered = false;
		}
		Chamber();
	}

	// the bolt on its way forward after a shot
	void Cycle()
	{
		if (cycleTics > 0)
		{
			cycleTics--;
			if (cycleTics == 0 && !boltLocked)
				boltT = 0;
		}
		if (boltLocked && handleIndex >= 0)
			boltT = arch.parts[handleIndex].travel;
		// the bolt follows a pulled handle
		if (handleIndex >= 0 && parts[handleIndex].t > boltT)
			boltT = parts[handleIndex].t;
	}

	// a spent case (or a live round, pulled out by the handle) leaves the port
	void EjectCase(bool live)
	{
		Vector3 at = MT_VR.ToWorld(mo, false, arch.eject);
		Vector3 dir = MT_VR.AxisF(mo, false) * arch.ejectDir.x + MT_VR.AxisL(mo, false) * arch.ejectDir.y + MT_VR.AxisU(mo, false) * arch.ejectDir.z;
		MT_Casing.Throw(mo, at, dir, live);
	}

	// ---------------------------------------------------------------- feedback
	void Buzz()
	{
		mo.SpawnPlayerMissile('MT_Buzz', mo.angle, noautoaim: true, aimflags: ALF_ISOFFHAND);
	}

	void Click()
	{
		mo.A_StartSound("mt/click", CHAN_6, CHANF_OVERLAP, 0.6);
	}
}
