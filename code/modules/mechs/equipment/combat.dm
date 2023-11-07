/obj/item/gun/energy/get_hardpoint_maptext()
	return "[round(cell.charge / charge_cost)]/[round(cell.maxcharge / charge_cost)]"

/obj/item/gun/energy/get_hardpoint_status_value()
	var/obj/item/cell/C = get_cell()
	if(istype(C))
		return C.charge/C.maxcharge
	return null

/obj/item/tool/sword/mech
	name = "mech blade"
	desc = "What are you standing around staring at this for? You shouldn't be seeing this..."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "claymore"
	item_state = "claymore"
	matter = list(MATERIAL_PLASTEEL = 15, MATERIAL_PLASTIC = 5)
	w_class = ITEM_SIZE_BULKY
	worksound = WORKSOUND_HARD_SLASH
	// Its Big
	armor_divisor = ARMOR_PEN_DEEP
	tool_qualities = list(QUALITY_CUTTING = 30, QUALITY_HAMMERING = 20, QUALITY_PRYING = 15)
	// its mech sized!!!!!
	structure_damage_factor = STRUCTURE_DAMAGE_BLADE
	spawn_blacklisted = TRUE

#define OVERKEY_BLADE "blade_overlay"
/obj/item/mech_blade_assembly
	name = "unfinished mech blade"
	desc = "A mech-blade framework lacking a blade"
	icon_state = "mech_blade_assembly"
	matter = list(MATERIAL_PLASTEEL = 15, MATERIAL_PLASTIC = 10)
	var/sharpeners = 0
	var/material/blade_mat = null

/obj/item/mech_blade_assembly/Initialize()
	. = ..()
	AddComponent(/datum/component/overlay_manager)

/obj/item/mech_blade_assembly/examine(user, distance)
	. = ..()
	if(.)
		if(sharpeners)
			to_chat(user, SPAN_NOTICE("It requires [sharpeners] sharpeners to be sharp enough"))
		else
			to_chat(user, SPAN_NOTICE("It needs 5 sheets of a metal inserted to form the basic blade"))
		to_chat(user , SPAN_NOTICE("Use a wrench to make this mountable. This is not reversible"))

/obj/item/mech_blade_assembly/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/tool_upgrade/productivity/whetstone))
		if(sharpeners)
			user.remove_from_mob(I, TRUE)
			I.forceMove(src)
			to_chat(user ,SPAN_NOTICE("You sharpen the blade on the [src]"))
			sharpeners--
		return
	if(istool(I))
		var/obj/item/tool/thing = I
		if(thing.has_quality(QUALITY_BOLT_TURNING))
			if(!blade_mat)
				to_chat(user, SPAN_NOTICE("You can't tighten the blade-mechanism onto a blade of air!"))
				return
			to_chat(user, SPAN_NOTICE("You start tightening \the [src] onto the blade made of [blade_mat.display_name]"))
			if(I.use_tool(user, src, WORKTIME_SLOW, QUALITY_BOLT_TURNING, 0, STAT_MEC, 150))
				if(QDELETED(src))
					return
				to_chat(user, SPAN_NOTICE("You tighten the blade on \the [src], creating a mech-mountable blade "))
				var/obj/item/mech_equipment/mounted_system/sword/le_mech_comp = new /obj/item/mech_equipment/mounted_system/sword(get_turf(src))
				var/obj/item/mech_equipment/mounted_system/sword/le_mech_sword = le_mech_comp.holding
				// DULL BLADE gets DULL DAMAGE
				le_mech_sword.force = max(0,(blade_mat.hardness - 35 * sharpeners)/2)
				le_mech_sword.matter = list(blade_mat.name = 5)
				qdel(src)
				return

	if(!istype(I, /obj/item/stack/material))
		return ..()
	if(blade_mat)
		to_chat(user, SPAN_NOTICE("There is already a blade formed! You can remove it by using it in hand."))
		return
	var/obj/item/stack/material/mat = I
	if(!mat.material.hardness)
		to_chat(user, SPAN_NOTICE("This material can't be sharpened!"))
		return
	if(mat.can_use(5))
		if(mat.use(5))
			to_chat(user , SPAN_NOTICE("You insert 5 sheets of the [mat] into the [src] , creating a blade requiring [round((mat.material.hardness)/60)] sharpeners to not be dull"))
			blade_mat = mat.material
			sharpeners = round(blade_mat.hardness/60)
			matter[mat.material.name]+= 5
			update_icon()

/obj/item/mech_blade_assembly/attack_self(mob/user)
	if(blade_mat)
		to_chat(user, SPAN_NOTICE("You start removing the blade from \the [src]"))
		if(do_after(user, 3 SECONDS, src, TRUE, TRUE))
			// No duping!!
			if(!blade_mat)
				to_chat(user, SPAN_NOTICE("There is no material left to remove from \the [src]"))
				return
			to_chat(user, SPAN_NOTICE("You remove 5 sheets of [blade_mat.display_name] from the [src]'s blade attachment point"))
			matter[blade_mat.name]-= 5
			var/obj/item/stack/material/mat_stack = new blade_mat.stack_type(get_turf(user))
			mat_stack.amount = 5
			blade_mat = null
			update_icon()

/obj/item/mech_blade_assembly/update_icon()
	. = ..()
	var/datum/component/overlay_manager/thing = GetComponent(/datum/component/overlay_manager)
	if(thing)
		thing.removeOverlay(OVERKEY_BLADE)
		if(blade_mat)
			var/mutable_appearance/overlay = mutable_appearance(src.icon, "[icon_state]_blade")
			overlay.color = blade_mat.icon_colour
			thing.addOverlay(OVERKEY_BLADE, overlay)

#undef OVERKEY_BLADE


/obj/item/mech_equipment/mounted_system/sword
	name = "\improper NT \"Warborne\" sword"
	desc = "An exosuit-mounted sword. Handle with care."
	icon_state = "mech_blade"
	holding_type = /obj/item/tool/sword/mech
	matter = list(MATERIAL_PLASTEEL = 15, MATERIAL_PLASTIC = 10)
	origin_tech = list(TECH_COMBAT = 4, TECH_MAGNET = 3)


/obj/item/mech_equipment/mounted_system/taser
	name = "mounted taser carbine"
	desc = "A dual fire mode taser system connected to the exosuit's targetting system."
	icon_state = "mech_taser"
	holding_type = /obj/item/gun/energy/taser/mounted/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	origin_tech = list(TECH_COMBAT = 3, TECH_MAGNET = 3)
	matter = list(MATERIAL_PLASTEEL = 25, MATERIAL_PLASTIC = 10, MATERIAL_SILVER = 10)

/obj/item/gun/energy/taser/mounted/mech
	restrict_safety = TRUE
	twohanded = FALSE
	charge_cost = MECH_WEAPON_POWER_COST * 0.5 // Pew pew pew pew pew pew pew pew pew pew
	burst = 3
	burst_delay = 1 // PEW PEW PEW
	init_recoil = LMG_RECOIL(1)
	matter = list()
	cell_type = /obj/item/cell/medium/mech

/obj/item/mech_equipment/mounted_system/taser/ion
	name = "mounted ion rifle"
	desc = "An exosuit-mounted ion rifle. Handle with care."
	icon_state = "mech_ionrifle"
	holding_type = /obj/item/gun/energy/ionrifle/mounted/mech
	matter = list(MATERIAL_PLASTEEL = 25, MATERIAL_PLASTIC = 10, MATERIAL_SILVER = 10)
	origin_tech = list(TECH_COMBAT = 2, TECH_MAGNET = 4)

/obj/item/gun/energy/ionrifle/mounted
	bad_type = /obj/item/gun/energy/ionrifle/mounted
	spawn_tags = null

/obj/item/gun/energy/ionrifle/mounted/mech
	use_external_power = TRUE
	restrict_safety = TRUE
	self_recharge = TRUE
	twohanded = FALSE
	charge_cost = MECH_WEAPON_POWER_COST * 0.75
	cell_type = /obj/item/cell/medium/mech
	matter = list()

/obj/item/mech_equipment/mounted_system/taser/laser
	name = "\improper CH-PS \"Immolator\" laser"
	desc = "An exosuit-mounted laser rifle. Handle with care."
	icon_state = "mech_lasercarbine"
	holding_type = /obj/item/gun/energy/laser/mounted/mech
	matter = list(MATERIAL_PLASTEEL = 25, MATERIAL_PLASTIC = 10, MATERIAL_SILVER = 10)
	origin_tech = list(TECH_COMBAT = 4, TECH_MAGNET = 3)

/obj/item/gun/energy/laser/mounted
	bad_type = /obj/item/gun/energy/laser/mounted/mech
	spawn_tags = null

/obj/item/gun/energy/laser/mounted/mech
	name = "\improper CH-PS \"Immolator\" laser"
	use_external_power = TRUE
	restrict_safety = TRUE
	self_recharge = TRUE
	twohanded = FALSE
	charge_cost = MECH_WEAPON_POWER_COST
	burst = 2
	init_firemodes = list()
	burst_delay = 1.5
	matter = list()
	cell_type = /obj/item/cell/medium/mech

/obj/item/mech_equipment/mounted_system/taser/plasma
	name = "mounted plasma cutter"
	desc = "An industrial plasma cutter mounted onto the chassis of the mech. "
	icon_state = "mech_plasma" //TODO: Make a new sprite that doesn't get sec called on you.
	holding_type = /obj/item/gun/energy/plasmacutter/mounted/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND, HARDPOINT_LEFT_SHOULDER, HARDPOINT_RIGHT_SHOULDER)
	origin_tech = list(TECH_MATERIAL = 4, TECH_PLASMA = 4, TECH_ENGINEERING = 6, TECH_COMBAT = 3)
	matter = list(MATERIAL_STEEL = 20, MATERIAL_PLASTEEL = 5)
	spawn_blacklisted = TRUE

/obj/item/gun/energy/plasmacutter
	bad_type = /obj/item/gun/energy/plasmacutter

/obj/item/gun/energy/plasmacutter/mounted
	bad_type = /obj/item/gun/energy/plasmacutter/mounted
	spawn_tags = null

/obj/item/gun/energy/plasmacutter/mounted/mech
	use_external_power = TRUE
	restrict_safety = TRUE
	twohanded = FALSE
	self_recharge = TRUE
	charge_cost = MECH_WEAPON_POWER_COST * 1.5
	projectile_type = /obj/item/projectile/beam/cutter
	matter = list()
	cell_type = /obj/item/cell/medium/mech

/obj/item/gun/projectile/get_hardpoint_maptext()
	if(ammo_magazine)
		return "[get_ammo()]/[ammo_magazine.max_ammo]"
	else
		return "NO MAG"

/obj/item/gun/projectile/get_hardpoint_status_value()
	if(ammo_magazine)
		return get_ammo()/ammo_magazine.max_ammo
	return null

#define LOADING_BOX 1
#define LOADING_SINGLE 2
/// This will always assume the gun loads in single mode, removing bullets from magazines and then loading them in
#define LOADING_FLEXIBLE 3

/obj/item/mech_equipment/mounted_system/ballistic
	bad_type = /obj/item/mech_equipment/mounted_system/ballistic
	var/list/obj/item/ammo_magazine/ammunition_storage
	var/accepted_types = list()
	var/ammunition_storage_limit = 1
	var/loading_type = LOADING_BOX

/obj/item/mech_equipment/mounted_system/ballistic/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/ammo_magazine) || istype(I, /obj/item/ammo_casing))
		switch(loadMagazine(I,user))
			if(-1)
				to_chat(user, SPAN_NOTICE("\The [src] does not accept this type of magazine."))
			if(0)
				to_chat(user, SPAN_NOTICE("\The [src] has no slots left in its ammunition storage"))
			if(1)
				to_chat(user, SPAN_NOTICE("You load \the [I] into \the [src]"))
		return
	else
		. = ..()

/obj/item/mech_equipment/mounted_system/ballistic/attack_self(mob/user)
	. = ..()
	if(.)
		return
	var/list/mag_removal = list()
	for(var/obj/item/ammo_magazine/mag in ammunition_storage)
		mag_removal["[mag] - [length(mag.stored_ammo)]"] = mag
	mag_removal["All mags"] = null
	var/obj/item/to_remove = null

	if(length(mag_removal) > 1)
		var/choice = input(user, "Select magazine to remove from \the [src]", "Magazine removal", 0) as null|anything in mag_removal
		if(choice == "All mags")
			for(var/slot in 1 to ammunition_storage_limit)
				var/obj/mag = unloadMagazine(slot)
				if(mag)
					mag.forceMove(get_turf(src))
		else
			to_remove = mag_removal[choice]
	else if(length(mag_removal))
		to_remove = mag_removal[mag_removal[1]]
	if(to_remove)
		ammunition_storage[getMagazineSlot(to_remove)] = null
		to_remove.forceMove(get_turf(user))



/obj/item/mech_equipment/mounted_system/ballistic/examine(user, distance)
	. = ..()
	to_chat(user, SPAN_NOTICE("Ammunition can be inserted inside, or removed by self-attacking "))


/obj/item/mech_equipment/mounted_system/ballistic/Initialize()
	. = ..()
	ammunition_storage = new /list(ammunition_storage_limit)

/obj/item/mech_equipment/mounted_system/ballistic/proc/getLoadedMagazine()
	switch(loading_type)
		if(LOADING_FLEXIBLE)
			for(var/obj/item/ammo_magazine/mag in ammunition_storage)
				if(length(mag.stored_ammo))
					ammunition_storage[getMagazineSlot(mag)] = null
					return mag
			for(var/obj/item/ammo_casing/case in ammunition_storage)
				if(case.BB)
					ammunition_storage[getMagazineSlot(case)] = null
					return case.BB
		if(LOADING_BOX)
			for(var/obj/item/ammo_magazine/mag in ammunition_storage)
				if(length(mag.stored_ammo))
					ammunition_storage[getMagazineSlot(mag)] = null
					return mag
		if(LOADING_SINGLE)
			for(var/obj/item/ammo_casing/case in ammunition_storage)
				if(case.BB)
					ammunition_storage[getMagazineSlot(case)] = null
					return case.BB
	return null

/obj/item/mech_equipment/mounted_system/ballistic/proc/getPartialAmmunition()
	switch(loading_type)
		if(LOADING_SINGLE)
			for(var/obj/item/ammo_casing/case in ammunition_storage)
				if(case.amount != case.maxamount)
					return case
			return null
		if(LOADING_BOX)
			for(var/obj/item/ammo_magazine/mag in ammunition_storage)
				if(length(mag.stored_ammo) != mag.max_ammo)
					return mag
			return null
		if(LOADING_FLEXIBLE)
			for(var/obj/item/ammo_magazine/mag in ammunition_storage)
				if(length(mag.stored_ammo) != mag.max_ammo)
					return mag
			for(var/obj/item/ammo_casing/case in ammunition_storage)
				if(case.amount != case.maxamount)
					return case
			return null

/obj/item/mech_equipment/mounted_system/ballistic/proc/getMagazineSlot(obj/magazine)
	for(var/i in 1 to ammunition_storage_limit)
		if(ammunition_storage[i] == magazine)
			return i
	return 0

/obj/item/mech_equipment/mounted_system/ballistic/proc/getEmptySlot()
	for(var/i in 1 to ammunition_storage_limit)
		if(ammunition_storage[i] != null)
			continue
		return i
	return 0

/// -1 for wrong type , 0 for no slot , 1 for succes loading.
/obj/item/mech_equipment/mounted_system/ballistic/proc/loadMagazine(obj/item/loadable, mob/living/user)
	var/obj/item/gun/projectile/wep = holding
	var/chosen_loading_type = null
	if(loading_type == LOADING_FLEXIBLE)
		if(istype(loadable, /obj/item/ammo_magazine))
			chosen_loading_type = LOADING_BOX
		else if(istype(loadable, /obj/item/ammo_casing))
			chosen_loading_type = LOADING_SINGLE
	else if(loading_type == LOADING_BOX)
		if(istype(loadable, /obj/item/ammo_magazine))
			chosen_loading_type = LOADING_BOX
	else if(loading_type == LOADING_SINGLE)
		if(istype(loadable, /obj/item/ammo_casing))
			chosen_loading_type = LOADING_SINGLE

	switch(chosen_loading_type)
		if(LOADING_BOX)
			var/obj/item/ammo_magazine/magazine = loadable
			if(wep.caliber != magazine.caliber)
				return -1
			var/valid = FALSE
			// so we can also acccept HV variants , etc.
			for(var/ammo_type in accepted_types)
				if(magazine.type in typesof(ammo_type))
					valid = TRUE
			if(!valid)
				return -1
			var/slot = getEmptySlot()
			if(!slot)
				var/partial_loaded = FALSE
				while(length(magazine.stored_ammo))
					var/obj/item/ammo_magazine/partial_mag = getPartialAmmunition()
					if(!partial_mag)
						break
					partial_loaded = TRUE
					partial_mag.attackby(magazine, user)
				return partial_loaded ? 2 : 0
			user.remove_from_mob(magazine)
			magazine.forceMove(src)
			ammunition_storage[slot] = magazine
			return 1
		if(LOADING_SINGLE)
			var/obj/item/ammo_casing/bullet = loadable
			if(wep.caliber != bullet.caliber)
				return -1
			var/valid = FALSE
			// so we can also acccept HV variants , etc.
			for(var/ammo_type in accepted_types)
				if(bullet.type in typesof(ammo_type))
					valid = TRUE
			if(!valid)
				return -1
			var/slot = getEmptySlot()
			if(!slot)
				var/partial_loaded = FALSE
				while(!QDELETED(bullet) && bullet.amount)
					var/obj/item/ammo_casing/partial_bullet = getPartialAmmunition()
					if(!partial_bullet)
						break
					partial_loaded = TRUE
					partial_bullet.attackby(bullet, user)
				return partial_loaded ? 2 : 0
			user.remove_from_mob(bullet)
			bullet.forceMove(src)
			ammunition_storage[slot] = bullet
			return 1
		else
			return -1



/obj/item/mech_equipment/mounted_system/ballistic/proc/unloadMagazine(slot)
	if(!ammunition_storage[slot])
		return FALSE
	var/obj/mag = ammunition_storage[slot]
	ammunition_storage[slot] = null
	return mag

/obj/item/mech_equipment/mounted_system/ballistic/proc/reloadGun()
	var/obj/item/gun/projectile/wep = holding
	switch(loading_type)
		if(LOADING_BOX)
			var/slot = getEmptySlot()
			var/obj/ammo_mag = wep.ammo_magazine
			if(ammo_mag)
				ammo_mag.update_icon()
				if(slot)
					ammunition_storage[slot] = ammo_mag
				else
					ammo_mag.forceMove(get_turf(src))
			// this returns null if we cant get a mag anyway
			wep.ammo_magazine = getLoadedMagazine()
			// Guns reset their firemode on reload
			wep.update_firemode()
			// wheter we succesfully reloaded or not
			return wep.ammo_magazine ? TRUE : FALSE
		if(LOADING_SINGLE)
			var/initial_shells = length(wep.loaded)
			while(length(wep.loaded) < wep.max_shells)
				var/obj/item/ammo_casing/bullet = getLoadedMagazine()
				if(!bullet)
					break
				while(bullet.amount > 1)
					// so we dupe
					var/obj/item/ammo_casing/bullet_dupe = new bullet.type(bullet)
					bullet_dupe.forceMove(wep)
					wep.loaded.Insert(1, bullet_dupe)
				if(bullet.amount == 1 && length(wep.loaded) < wep.max_shells)
					bullet.forceMove(wep)
					wep.loaded.Insert(1, bullet)
				if(!isgun(bullet.loc))
					var/empty_slot = getEmptySlot()
					if(!empty_slot)
						bullet.forceMove(get_turf(src))
					else
						ammunition_storage[empty_slot] = bullet
			return length(wep.loaded) == wep.max_shells ? 1 : (length(wep.loaded) > initial_shells ? 2 : 0 )
		if(LOADING_FLEXIBLE)
			var/initial_shells = length(wep.loaded)
			while(length(wep.loaded) < wep.max_shells)
				var/obj/ammo = getLoadedMagazine()
				if(!ammo)
					break
				if(istype(ammo, /obj/item/ammo_magazine))
					var/obj/item/ammo_magazine/mag = ammo
					while(length(mag.stored_ammo) && length(wep.loaded) < wep.max_shells)
						var/obj/item/ammo_casing/bullet = mag.removeCasing()
						if(!bullet)
							break
						bullet.forceMove(wep)
						wep.loaded.Insert(1, bullet)
					var/slot = getEmptySlot()
					if(slot)
						ammunition_storage[slot] = mag
					else
						mag.forceMove(get_turf(src))
				else
					var/obj/item/ammo_casing/bullet = ammo
					while(bullet.amount > 1)
						// so we dupe
						var/obj/item/ammo_casing/bullet_dupe = new bullet.type(bullet)
						bullet_dupe.forceMove(wep)
						wep.loaded.Insert(1, bullet_dupe)
						if(bullet.amount == 1 && length(wep.loaded) < wep.max_shells)
							bullet.forceMove(wep)
							wep.loaded.Insert(1, bullet)
						if(!isgun(bullet.loc))
							var/empty_slot = getEmptySlot()
							if(!empty_slot)
								bullet.forceMove(get_turf(src))
							else
								ammunition_storage[empty_slot] = bullet

			return length(wep.loaded) == wep.max_shells ? 1 : (length(wep.loaded) > initial_shells ? 2 : 0 )




/obj/item/mech_equipment/mounted_system/ballistic/on_select()
	var/obj/item/gun/wep = holding
	wep.update_firemode()

/obj/item/mech_equipment/mounted_system/ballistic/on_unselect()
	var/obj/item/gun/wep = holding
	wep.update_firemode()

/obj/item/mech_equipment/mounted_system/ballistic/smg
	name = "ML \"C-35R\""
	desc = "A upgraded version of the reverse engineered CR20, retrofitted for mech use. Fires in full auto 600 RPM and has modest accuracy, reloads slowly. Takes in packets of .35 or SMG magazines"
	icon_state = "mech_ballistic2"
	holding_type = /obj/item/gun/projectile/automatic/c20r/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	origin_tech = list(TECH_COMBAT = 3, TECH_MAGNET = 2)
	matter = list(MATERIAL_PLASTEEL = 50, MATERIAL_GOLD = 8, MATERIAL_SILVER = 5) // Gold and silver for it's ammo-regeneration electronics
	spawn_blacklisted = TRUE
	ammunition_storage_limit = 3
	accepted_types = list(
		/obj/item/ammo_magazine/ammobox/pistol,
		/obj/item/ammo_magazine/smg
	)

/obj/item/gun/projectile/automatic/c20r/mech
	name = 	"ML \"C-35R\""
	restrict_safety = TRUE
	safety = FALSE
	twohanded = FALSE
	init_firemodes = list(
		FULL_AUTO_600
		)
	spawn_blacklisted = TRUE
	spawn_tags = null
	init_recoil = list(0.3, 1, 0.3)
	matter = list()
	var/reloading = FALSE

/obj/item/mech_equipment/mounted_system/ballistic/shotgun
	// named after Srgt Robert Draper's nickname from The Expanse book series
	name = "ML \"Bobby\""
	desc = "A brutal mech-mounted shotgun with an automatic cocking mechanism. Fires in single-shot, cocks itself fast. Takes in shotgun ammo boxes, packets or shell bunches"
	icon_state = "mech_ballistic1"
	holding_type = /obj/item/gun/projectile/shotgun/pump/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	origin_tech = list(TECH_COMBAT = 3, TECH_MAGNET = 2)
	matter = list(MATERIAL_PLASTEEL = 50, MATERIAL_GOLD = 8, MATERIAL_SILVER = 5) // Gold and silver for it's ammo-regeneration electronics
	spawn_blacklisted = TRUE
	loading_type = LOADING_FLEXIBLE
	ammunition_storage_limit = 4
	accepted_types = list(
		/obj/item/ammo_magazine/ammobox/shotgun,
		/obj/item/ammo_magazine/ammobox/shotgun_small,
		/obj/item/ammo_casing/shotgun
	)

/obj/item/gun/projectile/shotgun/pump/mech
	name = "ML \"Bobby\""
	restrict_safety = TRUE
	safety = FALSE
	max_shells = 12
	twohanded = FALSE
	spawn_blacklisted = TRUE
	spawn_tags = null
	matter = list()
	var/loading = FALSE

/obj/item/gun/projectile/shotgun/pump/mech/pump(mob/M)
	..()
	playsound(get_turf(M), 'sound/weapons/shotgunpump.ogg', 120, 1)

/obj/item/gun/projectile/shotgun/pump/mech/get_hardpoint_maptext()
	return "[length(loaded) + chambered ? 1 : 0] / [max_shells]"

/obj/item/gun/projectile/shotgun/pump/mech/afterattack(atom/A, mob/living/user)
	if(loading)
		to_chat(user, SPAN_NOTICE("\The [src] is currently reloading!"))
		return
	..()
	pump(user)
	if(!chambered)
		to_chat(user, SPAN_NOTICE("\The [src] has run out of shells! reloading..."))
		loading = TRUE
		var/obj/item/mech_equipment/mounted_system/ballistic/hold = loc
		spawn(8 SECONDS)
			if(hold.reloadGun())
				to_chat(user, SPAN_NOTICE("\The [src]'s chamber has been refilled with shells."))
			else
				to_chat(user, SPAN_DANGER("\The [src]'s failed to load!"))
			loading = FALSE
			pump(user)

/obj/item/gun/projectile/automatic/c20r/mech/afterattack(atom/A, mob/living/user)
	. = ..()
	if(!ammo_magazine || (ammo_magazine && !length(ammo_magazine.stored_ammo)))
		if(reloading)
			return
		var/obj/item/mech_equipment/mounted_system/ballistic/hold = loc
		to_chat(user, SPAN_NOTICE("\The [src] is now reloading!"))
		reloading = TRUE
		spawn(6 SECONDS)
			if(hold.reloadGun())
				to_chat(user, SPAN_NOTICE("\The [src]'s magazine has been reloaded."))
			else
				to_chat(user, SPAN_DANGER("\The [src]'s failed to load!"))
			reloading = FALSE

/obj/item/mech_equipment/mounted_system/ballistic/pk
	name = "SA \"VJP\""
	desc = "A reverse engineered Pulemyot Kalashnikova fitted for mech use. Fires in full auto 400 and has horrible accuracy. Takes in .30 ammunition boxes"
	icon_state = "mech_pk"
	holding_type = /obj/item/gun/projectile/automatic/lmg/pk/mounted/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	origin_tech = list(TECH_COMBAT = 5, TECH_MAGNET = 3)
	matter = list(MATERIAL_PLASTEEL = 50, MATERIAL_GOLD = 8, MATERIAL_SILVER = 5) // Gold and silver for it's ammo-regeneration electronics
	spawn_blacklisted = TRUE
	ammunition_storage_limit = 2
	accepted_types = list(
		/obj/item/ammo_magazine/ammobox/lrifle
	)

/obj/item/mech_equipment/mounted_system/ballistic/pk/on_select()
	..()
	var/obj/item/gun/projectile/automatic/lmg/pk/mounted/mech/wep = holding
	wep.cocked = FALSE

/obj/item/mech_equipment/mounted_system/ballistic/pk/on_unselect()
	..()
	var/obj/item/gun/projectile/automatic/lmg/pk/mounted/mech/wep = holding
	wep.cocked = FALSE


/obj/item/gun/projectile/automatic/lmg/pk/mounted
	bad_type = /obj/item/gun/projectile/automatic/lmg/pk/mounted

/obj/item/gun/projectile/automatic/lmg/pk/mounted/mech
	name = 	"SA \"VJP\""
	desc = "A reverse engineered Pulemyot Kalashnikova fitted for mech use. Fires in 5 round bursts. Slightly inaccurate, but packs quite a punch."
	restrict_safety = TRUE
	safety = FALSE
	twohanded = FALSE
	init_firemodes = list(
		FULL_AUTO_400
		)
	spawn_tags = null
	spawn_blacklisted = TRUE
	matter = list()
	magazine_type = /obj/item/ammo_magazine/lrifle/pk/mech
	// Used for dramatic purpose.
	var/cocked = FALSE
	var/reloading = FALSE

/obj/item/gun/projectile/automatic/lmg/pk/mounted/mech/afterattack(atom/A, mob/living/user)
	// Dramatic gun cocking!
	if(!cocked)
		playsound(src.loc, 'sound/weapons/guns/interact/lmg_cock.ogg', 300, 1)
		to_chat(user, SPAN_NOTICE("You chamber the [src], preparing it for full-automatic fire."))
		// uh oh
		visible_message(get_turf(src), SPAN_DANGER("The mech chambers the [src] , preparing it for full automatic fire!"))
		cocked = TRUE
		safety = FALSE
		return
	..()
	if((ammo_magazine && ammo_magazine.stored_ammo && !ammo_magazine.stored_ammo.len && !reloading) || (!ammo_magazine && !reloading))
		reloading = TRUE
		playsound(src.loc, 'sound/weapons/guns/interact/lmg_open.ogg', 100, 1)
		var/obj/item/mech_equipment/mounted_system/ballistic/hold = loc
		to_chat(user, SPAN_NOTICE("\The [src]'s magazine has run out. Reloading..."))
		spawn(1 SECOND)
			playsound(src.loc, 'sound/weapons/guns/interact/lmg_cock.ogg', 150, 1)
		spawn(2 SECOND)
			playsound(src.loc, 'sound/weapons/guns/interact/lmg_close.ogg', 100, 1)
			if(hold.reloadGun())
				to_chat(user, SPAN_NOTICE("\The [src]'s magazine has been reloaded."))
			else
				to_chat(user, SPAN_DANGER("\The [src]'s failed to load!"))
			reloading = FALSE
			// recock your gun
			cocked = FALSE
			// not being able to fire removes the CH

