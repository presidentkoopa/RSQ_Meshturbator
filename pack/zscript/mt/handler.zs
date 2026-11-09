// MT_Handler -- every tic, for every player: the gun in the hand gets its MT_Gun, the off hand gets
// MT_Hands, the parts get their layers. Play scope, per player, no consoleplayer.
class MT_Settings
{
	clearscope static bool Debug()
	{
		let cv = CVar.FindCVar('mt_debug');
		return cv && cv.GetBool();
	}

	// the grab button: 0 = off-hand trigger (BT_OFFHANDATTACK), 1 = off-hand grip (BT_SPEED on QZD's
	// default mapping)
	play static bool GrabHeld(PlayerPawn mo)
	{
		if (!mo.player)
			return false;
		let cv = CVar.GetCVar('mt_grab', mo.player);
		int b = MT_VR.Buttons(mo);
		return cv && cv.GetInt() == 1 ? (b & BT_SPEED) != 0 : (b & BT_OFFHANDATTACK) != 0;
	}
}

// which archetype a weapon class is. The universal attach table grows here (DESIGN.md §3); our own
// weapons name theirs.
class MT_Attach
{
	clearscope static String ArchOf(Weapon w)
	{
		if (!w)
			return "";
		let own = MT_OwnWeapon(w);
		if (own)
			return own.ArchName();
		return "";
	}
}

// a weapon of this pack: it knows its archetype and talks to its MT_Gun directly (layer 2 without 3)
class MT_OwnWeapon : Weapon abstract
{
	clearscope virtual String ArchName() { return ""; }
}

class MT_Handler : EventHandler
{
	Array<Weapon> weaps;
	Array<MT_Gun> guns;

	clearscope static MT_Handler Get()
	{
		return MT_Handler(EventHandler.Find('MT_Handler'));
	}

	// the MT_Gun of the weapon in this player's hand, if it has one (ui may read it: the renderer places by it)
	clearscope static MT_Gun GunOf(PlayerPawn mo)
	{
		let h = Get();
		if (!h || !mo || !mo.player || !mo.player.ReadyWeapon)
			return null;
		return h.Find(mo.player.ReadyWeapon);
	}

	clearscope MT_Gun Find(Weapon w)
	{
		for (int i = 0; i < weaps.Size(); i++)
			if (weaps[i] == w)
				return guns[i];
		return null;
	}

	MT_Gun Lookup(PlayerPawn mo, Weapon w, bool make)
	{
		let found = Find(w);
		if (found || !make)
			return found;
		String an = MT_Attach.ArchOf(w);
		if (an == "")
			return null;
		let a = MT_ArchDB.Find(an);
		if (!a)
		{
			Console.Printf("MT: %s names archetype '%s' but no MTARCH lump defines it", w.GetClassName(), an);
			return null;
		}
		let g = MT_Gun.Make(mo, a);
		weaps.Push(w);
		guns.Push(g);
		if (MT_Settings.Debug())
			Console.Printf("MT: %s -> archetype %s (%d parts)", w.GetClassName(), a.name, a.parts.Size());
		return g;
	}

	override void WorldTick()
	{
		// forget guns whose weapon is gone
		for (int i = weaps.Size() - 1; i >= 0; i--)
			if (!weaps[i] || !weaps[i].Owner)
			{
				weaps.Delete(i);
				guns.Delete(i);
			}
		for (int pn = 0; pn < MAXPLAYERS; pn++)
		{
			if (!playeringame[pn])
				continue;
			let mo = players[pn].mo;
			if (!mo || players[pn].playerstate != PST_LIVE)
				continue;
			let w = players[pn].ReadyWeapon;
			let g = w ? Lookup(mo, w, true) : null;
			if (!g)
			{
				Clear(mo);
				continue;
			}
			KeepHands(mo);
			g.Tick();
			Layers(mo, g);
		}
	}

	// the off-hand slot is ours while a part gun is in the main hand: the engine draws our layers only
	// if the off-hand weapon is MT_Hands (layers.zs). A weapon the player moved there himself is left.
	void KeepHands(PlayerPawn mo)
	{
		let p = mo.player;
		let h = Weapon(mo.FindInventory('MT_Hands'));
		if (!h)
		{
			mo.GiveInventory('MT_Hands', 1);
			h = Weapon(mo.FindInventory('MT_Hands'));
		}
		if (!mo.FindInventory('MT_Carrier'))
			mo.GiveInventory('MT_Carrier', 1);
		let off = p.OffhandWeapon;
		if (h && !off && p.PendingWeapon == WP_NOCHANGE)
			p.PendingWeapon = h;
	}

	void Layers(PlayerPawn mo, MT_Gun g)
	{
		let p = mo.player;
		let car = mo.FindInventory('MT_Carrier');
		let hands = Weapon(mo.FindInventory('MT_Hands'));
		bool draw = MT_VR.InVR(mo) && car && hands && p.OffhandWeapon == hands;
		State st = draw && hands ? hands.FindStateByString(g.arch.sprite) : null;
		for (int i = 0; i < g.parts.Size(); i++)
		{
			let d = g.arch.parts[i];
			let s = g.parts[i];
			bool onGun = draw && (s.where == MT_Gun.ON_GUN || s.where == MT_Gun.CAPTURED);
			bool inHand = draw && s.where == MT_Gun.IN_HAND;
			MT_Layers.Set(p, MT_Layers.GUN_FIRST + i, car, onGun ? st : null);
			MT_Layers.Set(p, MT_Layers.HAND_FIRST + i, hands, inHand ? st : null);
			int frame = (d.emptyFrame >= 0 && s.rounds <= 0) ? d.emptyFrame : d.frame;
			let psp = p.FindPSprite(MT_Layers.GUN_FIRST + i);
			if (psp) psp.Frame = frame;
			psp = p.FindPSprite(MT_Layers.HAND_FIRST + i);
			if (psp) psp.Frame = frame;
		}
		// the off hand itself: the fist marker (frame Z of the archetype sprite)
		MT_Layers.Set(p, MT_Layers.FIST, hands, draw ? st : null);
		let fp = p.FindPSprite(MT_Layers.FIST);
		if (fp) fp.Frame = 25;
	}

	void Clear(PlayerPawn mo)
	{
		let p = mo.player;
		for (int i = 0; i < MT_Layers.COUNT; i++)
		{
			if (p.FindPSprite(MT_Layers.GUN_FIRST + i)) p.SetPsprite(MT_Layers.GUN_FIRST + i, null);
			if (p.FindPSprite(MT_Layers.HAND_FIRST + i)) p.SetPsprite(MT_Layers.HAND_FIRST + i, null);
		}
		if (p.FindPSprite(MT_Layers.FIST)) p.SetPsprite(MT_Layers.FIST, null);
	}

	// debug (mt_debug): what the renderer has to draw, once a second: every psprite layer below the
	// targeter band, its caller, sprite and frame. ui scope, this client only; reads, never writes.
	override void RenderOverlay(RenderEvent e)
	{
		if (!MT_Settings.Debug() || gamestate != GS_LEVEL)
			return;
		let p = players[consoleplayer];
		if (!p.mo || p.mo.Level.maptime % 35 != 0 || e.FracTic > 0.1)
			return;
		String s = String.Format("MT LAYERS t%d off=%s ready=%s |", p.mo.Level.maptime,
			p.OffhandWeapon ? p.OffhandWeapon.GetClassName() : 'none', p.ReadyWeapon ? p.ReadyWeapon.GetClassName() : 'none');
		for (let psp = p.psprites; psp && psp.ID < PSP_TARGETCENTER; psp = psp.Next)
			s = s .. String.Format(" [%d %s spr%d.%c bob%d]", psp.ID, psp.Caller ? psp.Caller.GetClassName() : 'none',
				int(psp.Sprite), 65 + psp.Frame, psp.bAddBob);
		Console.Printf("%s", s);
	}

	// console: mt_state -- every player's gun state (debug)
	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name ~== "mt_state")
		{
			let mo = players[e.Player].mo;
			let g = GunOf(mo);
			if (!g)
			{
				Console.Printf("MT: player %d: no part gun in hand", e.Player);
				return;
			}
			String s = String.Format("MT STATE t%d %s chambered %d boltLocked %d boltT %.1f held %d reserve %d |",
				mo.Level.maptime, g.arch.name, g.chambered, g.boltLocked, g.boltT, g.held, mo.CountInv(g.arch.reserve));
			for (int i = 0; i < g.parts.Size(); i++)
				s = s .. String.Format(" %s@%d t%.1f r%d", g.arch.parts[i].name, g.parts[i].where, g.parts[i].t, g.parts[i].rounds);
			Console.Printf("%s", s);
		}
	}
}
