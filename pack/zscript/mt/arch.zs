// The archetype data: what a weapon's parts are and how each may move. Read from MTARCH lumps.
//
// One lump may hold several archetypes. Lines (# comments; numbers are cm in the GUN frame: F L U):
//   archetype <name>
//   sprite <XXXX>                      the sprite whose frames the MODELDEF binds each part to
//   capacity <n>  reserve <AmmoClass>  rounds a magazine holds; the player's ammo the magazines draw from
//   part <name> frame <A..Z> fixed                       the body, or anything that never moves
//   part <name> frame <L> slide axis <F L U> travel <cm> grab <F L U> radius <cm> [hold <F L U>] [detent] [spring]
//        a part on a straight joint: `axis` is the way it comes OUT, `travel` how far until it is free,
//        `grab` where the hand takes it when seated, `hold` where its origin rides the off controller when
//        carried, `detent` clicks home at 0, `spring` returns to 0 when let go (a charging handle)
//   part <name> frame <L> follow <part> [lock]           moves with another part's travel; `lock` may stay back
//   part <name> frame <L> free                           a loose object (a case, a round)
//   point muzzle <F L U>   point eject <F L U> dir <F L U>   point pouch <F L U>|hip
//
// Every number here is MEASURED on the rig (frames) or in VR (the fitting mode); none is typed from a guess.
class MT_PartDef
{
	String name;
	int frame;			// 0 = A
	Name joint;			// 'fixed' 'slide' 'follow' 'free'
	Vector3 axis;		// out direction, unit, gun frame
	double travel;		// cm
	Vector3 grab;		// gun frame, seated
	double radius;		// cm
	Vector3 hold;		// off-controller frame, carried
	bool detent, spring, lock;
	int emptyFrame;		// a magazine's look when empty (-1: the same)
	String follows;
	int index;			// position in the archetype's part list

	static MT_PartDef Make(String name, int frame)
	{
		let p = new('MT_PartDef');
		p.name = name; p.frame = frame; p.joint = 'fixed'; p.axis = (0, 0, -1); p.travel = 0; p.radius = 6; p.emptyFrame = -1;
		return p;
	}
}

class MT_Arch
{
	String name;
	String sprite;
	int capacity;
	String reserve;
	Array<MT_PartDef> parts;
	Vector3 muzzle, eject, ejectDir, pouch;
	bool pouchHip;

	MT_PartDef Part(String n)
	{
		for (int i = 0; i < parts.Size(); i++)
			if (parts[i].name ~== n)
				return parts[i];
		return null;
	}

	int PartIndex(String n)
	{
		let p = Part(n);
		return p ? p.index : -1;
	}
}

// The archetypes, parsed once per game from every MTARCH lump.
class MT_ArchDB : StaticEventHandler
{
	Array<MT_Arch> archs;
	bool loaded;

	static MT_ArchDB Get()
	{
		let h = MT_ArchDB(StaticEventHandler.Find('MT_ArchDB'));
		if (h && !h.loaded)
			h.Load();
		return h;
	}

	static MT_Arch Find(String name)
	{
		let h = Get();
		if (!h)
			return null;
		for (int i = 0; i < h.archs.Size(); i++)
			if (h.archs[i].name ~== name)
				return h.archs[i];
		return null;
	}

	void Load()
	{
		loaded = true;
		archs.Clear();
		int lump = -1;
		while ((lump = Wads.FindLump("MTARCH", lump + 1)) != -1)
			Parse(Wads.ReadLump(lump), Wads.GetLumpFullName(lump));
		Console.Printf("MT: %d archetype(s) loaded", archs.Size());
	}

	static Vector3 V3(Array<String> t, int i)
	{
		if (i + 2 >= t.Size())
			return (0, 0, 0);
		return (t[i].ToDouble(), t[i + 1].ToDouble(), t[i + 2].ToDouble());
	}

	void Parse(String text, String where)
	{
		Array<String> lines;
		text.Split(lines, "\n");
		MT_Arch a = null;
		for (int ln = 0; ln < lines.Size(); ln++)
		{
			String s = lines[ln];
			int hash = s.IndexOf("#");
			if (hash >= 0)
				s = s.Left(hash);
			s.Replace("\t", " ");
			s.Replace("\r", "");
			Array<String> t;
			s.Split(t, " ", TOK_SKIPEMPTY);
			if (t.Size() == 0)
				continue;
			String k = t[0];
			if (k ~== "archetype")
			{
				a = new('MT_Arch');
				a.name = t.Size() > 1 ? t[1] : "?";
				a.sprite = "MTP1";
				a.capacity = 10;
				a.reserve = "Clip";
				a.ejectDir = (0, -1, 0.5);
				archs.Push(a);
				continue;
			}
			if (!a)
			{
				Console.Printf("MT: %s line %d: '%s' before any archetype", where, ln + 1, k);
				continue;
			}
			if (k ~== "sprite" && t.Size() > 1) a.sprite = t[1];
			else if (k ~== "capacity" && t.Size() > 1) a.capacity = t[1].ToInt();
			else if (k ~== "reserve" && t.Size() > 1) a.reserve = t[1];
			else if (k ~== "point" && t.Size() > 1)
			{
				if (t[1] ~== "muzzle") a.muzzle = V3(t, 2);
				else if (t[1] ~== "eject")
				{
					a.eject = V3(t, 2);
					for (int i = 5; i < t.Size(); i++)
						if (t[i] ~== "dir") a.ejectDir = V3(t, i + 1);
				}
				else if (t[1] ~== "pouch")
				{
					if (t.Size() > 2 && t[2] ~== "hip") a.pouchHip = true;
					else a.pouch = V3(t, 2);
				}
			}
			else if (k ~== "part" && t.Size() > 3 && t[2] ~== "frame")
			{
				let p = MT_PartDef.Make(t[1], clamp(t[3].ByteAt(0) - 65, 0, 25));
				p.index = a.parts.Size();
				for (int i = 4; i < t.Size(); i++)
				{
					String w = t[i];
					if (w ~== "fixed" || w ~== "slide" || w ~== "free") p.joint = w;
					else if (w ~== "follow" && i + 1 < t.Size()) { p.joint = 'follow'; p.follows = t[++i]; }
					else if (w ~== "axis") { p.axis = V3(t, i + 1); i += 3; }
					else if (w ~== "travel" && i + 1 < t.Size()) p.travel = t[++i].ToDouble();
					else if (w ~== "grab") { p.grab = V3(t, i + 1); i += 3; }
					else if (w ~== "radius" && i + 1 < t.Size()) p.radius = t[++i].ToDouble();
					else if (w ~== "hold") { p.hold = V3(t, i + 1); i += 3; }
					else if (w ~== "detent") p.detent = true;
					else if (w ~== "spring") p.spring = true;
					else if (w ~== "lock") p.lock = true;
					else if (w ~== "empty" && i + 1 < t.Size()) p.emptyFrame = clamp(t[++i].ByteAt(0) - 65, 0, 25);
					else Console.Printf("MT: %s line %d: unknown word '%s'", where, ln + 1, w);
				}
				if (p.axis.Length() > 0)
					p.axis /= p.axis.Length();
				a.parts.Push(p);
			}
			else
				Console.Printf("MT: %s line %d: unknown line '%s'", where, ln + 1, k);
		}
	}
}
