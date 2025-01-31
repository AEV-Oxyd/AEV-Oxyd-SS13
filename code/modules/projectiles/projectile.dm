/*
#define BRUTE "brute"
#define BURN "burn"
#define TOX "tox"
#define OXY "oxy"
#define CLONE "clone"

#define ADD "add"
#define SET "set"
*/

GLOBAL_LIST(projectileDamageConstants)
/obj/item/projectile
	name = "projectile"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bullet"
	density = TRUE
	unacidable = TRUE
	anchored = TRUE //There's a reason this is here, Mport. God fucking damn it -Agouri. Find&Fix by Pete. The reason this is here is to stop the curving of emitter shots.
	pass_flags = PASSTABLE
	mouse_opacity = 0
	spawn_blacklisted = TRUE
	spawn_frequency = 0
	spawn_tags = null
	animate_movement = NO_STEPS
	glide_size = 8
	/// Ammo is heavy
	weight = 10
	var/bumped = FALSE		//Prevents it from hitting more than one guy at once
	var/hitsound_wall = "ricochet"
	var/list/mob_hit_sound = list('sound/effects/gore/bullethit2.ogg', 'sound/effects/gore/bullethit3.ogg') //Sound it makes when it hits a mob. It's a list so you can put multiple hit sounds there.
	var/def_zone = ""	//Aiming at
	var/mob/firer = null//Who shot it
	var/silenced = FALSE	//Attack message
	var/yo = null
	var/xo = null
	var/current = null
	var/shot_from = "" // name of the object which shot us
	var/atom/original = null // the target clicked (not necessarily where the projectile is headed). Should probably be renamed to 'target' or something.
	var/turf/starting = null // the projectile's starting turf
	var/list/permutated = list() // we've passed through these atoms, don't try to hit them again

	var/p_x = 16
	var/p_y = 16 // the pixel location of the tile that the player clicked. Default is the center

	var/nocap_structures = FALSE // wether or not this projectile can circumvent the damage cap you can do to walls and doors in one hit. Also increases the structure damage done to walls by 300%
	var/can_ricochet = FALSE // defines if projectile can or cannot ricochet.
	var/ricochet_id = 0 // if the projectile ricochets, it gets its unique id in order to process iteractions with adjacent walls correctly.
	var/ricochet_ability = 1 // multiplier for how much it can ricochet, modified by the bullet blender weapon mod

	var/list/damage_types = list(
		ARMOR_BULLET = list(
			DELEM(BRUTE, 10)
		)
	)
	/// Will be left as nothing until we get fired(we copy damage_types then)
	var/list/damage = null
	var/nodamage = FALSE //Determines if the projectile will skip any damage inflictions
	var/taser_effect = FALSE //If set then the projectile will apply it's agony damage using stun_effect_act() to mobs it hits, and other damage will be ignored
	var/check_armour = ARMOR_BULLET //Defines what armor to use when it hits things. Full list could be found at defines\damage_organs.dm
	var/projectile_type = /obj/item/projectile
	var/penetrating = 0 //If greater than zero, the projectile will pass through dense objects as specified by on_penetrate()
	var/kill_count = 50 //This will de-increment every process(). When 0, it will delete the projectile.
	var/base_spreading = 90 // higher value means better chance to hit here. derp.
	var/spreading_step = 15
	var/projectile_accuracy = 1 // Based on vigilance, reduces random limb chance and likelihood of missing intended target
	var/recoil = 0
	var/wounding_mult = 1 // A multiplier on damage inflicted to and damage blocked by mobs

	//Effects
	var/stun = 0
	var/weaken = 0
	var/paralyze = 0
	var/irradiate = 0
	var/stutter = 0
	var/eyeblur = 0
	var/drowsy = 0
	var/embed = 0 // whether or not the projectile can embed itself in the mob
	var/knockback = 0

	var/hitscan = FALSE		// whether the projectile should be hitscan

	var/step_delay = 0.8	// the delay between iterations if not a hitscan projectile
							// This thing right here goes to sleep(). We should not send non decimal things to sleep(),
							// but it was doing it for a while, it works, and this whole shit should be rewriten or ported from another codebase.

	// effect types to be used
	var/muzzle_type
	var/tracer_type
	var/impact_type
	var/luminosity_range
	var/luminosity_power
	var/luminosity_color
	var/luminosity_ttl
	var/obj/effect/attached_effect
	var/proj_sound

	var/proj_color //If defined, is used to change the muzzle, tracer, and impact icon colors through Blend()

	var/datum/plot_vector/trajectory	// used to plot the path of the projectile
	var/datum/vector_loc/location		// current location of the projectile in pixel space
	var/matrix/effect_transform			// matrix to rotate and scale projectile effects - putting it here so it doesn't
										//  have to be recreated multiple times

	var/datum/bullet_data/dataRef = null

/// Returns 0 , no mod to aiming level
/obj/item/projectile/getAimingLevel(atom/shooter, defZone)
	return 0

/// Fun interaction time - 2 bullets colliding mid air ! SPCR 2024
/obj/item/projectile/bullet_act(obj/item/projectile/P, def_zone, hitboxFlags)
	// yep , it checks itself , more efficient to handle it here..
	if(P == src)
		return PROJECTILE_CONTINUE
	if(abs(P.dataRef.globalZ - dataRef.globalZ) > 0.1)
		return PROJECTILE_CONTINUE
	if(abs(P.dataRef.globalX - dataRef.globalX) > 0.1)
		return PROJECTILE_CONTINUE
	if(abs(P.dataRef.globalY - dataRef.globalY) > 0.1)
		return PROJECTILE_CONTINUE
	// congratulations , you have 2 intersecting bullets...
	return PROJECTILE_STOP

/// This is done to save a lot of memory from duplicated damage lists.
/// The list is also copied whenever PrepareForLaunch is called and modified as needs to be
/obj/item/projectile/Initialize()
	. = ..()
	if(!GLOB.projectileDamageConstants)
		GLOB.projectileDamageConstants = list()
	if(!GLOB.projectileDamageConstants[type])
		GLOB.projectileDamageConstants = damage_types
	else
		/// delete the list. Don't need QDEL for this
		del(damage_types)
		damage_types = GLOB.projectileDamageConstants[type]


/obj/item/projectile/Destroy()
	firer = null
	original = null
	starting = null
	LAZYCLEARLIST(permutated)
	return ..()

/// This MUST be called before any modifications are done to the damage list.
/obj/item/projectile/proc/PrepareForLaunch()
	damage = deepCopyList(damage_types)

/obj/item/projectile/is_hot()
	return dhTotalDamageDamageType(damage ? damage : damage_types, BURN) * heat

/obj/item/projectile/proc/get_total_damage()
	var/damageList = damage
	if(!length(damage) || !damage)
		damageList = damage_types
	return dhTotalDamage(damageList)

/obj/item/projectile/proc/is_halloss()
	var/damageList = damage
	if(!length(damage) || !damage)
		damageList = damage_types
	return dhHasDamageType(damageList, HALLOSS)

/obj/item/projectile/proc/getAllDamType(type)
	var/damageList = damage
	if(!length(damage) || !damage)
		damageList = damage_types
	return dhTotalDamageDamageType(damageList, type)

/obj/item/projectile/multiply_projectile_damage(newMult)
	dhApplyStrictMultiplier(damage, ALL_ARMOR, ALL_DAMAGE - HALLOSS, newMult)

/obj/item/projectile/multiply_projectile_halloss(newMult)
	dhApplyStrictMultiplier(damage, ALL_ARMOR, HALLOSS, newMult)

/obj/item/projectile/add_projectile_penetration(newmult)
	armor_divisor = initial(armor_divisor) + newmult

/obj/item/projectile/multiply_pierce_penetration(newmult)
	penetrating = initial(penetrating) + newmult

/obj/item/projectile/multiply_ricochet(newmult)
	ricochet_ability = initial(ricochet_ability) + newmult

/obj/item/projectile/multiply_projectile_step_delay(newmult)
	if(!hitscan)
		step_delay = initial(step_delay) * newmult

/obj/item/projectile/proc/multiply_projectile_accuracy(newmult)
	projectile_accuracy = initial(projectile_accuracy) * newmult

// bullet/pellets redefines this
/obj/item/projectile/proc/adjust_damages(list/newdamages)
	if(!newdamages.len)
		return
	for(var/damage_type in newdamages)
		if(damage_type == IRRADIATE)
			irradiate += newdamages[IRRADIATE]
			continue
		var/isNeg = newdamages[damage_type] < 0
		if(!isNeg)
			for(var/armorType in damage)
				var/damageApplied = FALSE
				for(var/list/damageElement in damage[armorType])
					if(damageElement[1] == damage_type)
						damageElement[2] += damageElement[2] + newdamages[damage_type]
						damageApplied = TRUE
						break
				if(!damageApplied)
					var/list/elements = damage[armorType]
					elements.Add(DELEM(damage_type, newdamages[damage_type]))
				break
			damage_types[damage_type] += newdamages[damage_type]
		else
			var/damToRemove = abs(newdamages[damage_type])
			for(var/armorType in damage)
				for(var/list/damageElement in damage)
					if(damageElement[1] == damage_type)
						var/removed = min(damageElement[2], damToRemove)
						damageElement[2] -= removed
						damToRemove -= removed
						if(damageElement[2] == 0)
							damage[armorType] -= damageElement
						if(damToRemove <= 0)
							break
				if(damToRemove <= 0)
					break

/obj/item/projectile/proc/adjust_ricochet(noricochet)
	if(noricochet)
		can_ricochet = FALSE
		return

/obj/item/projectile/proc/on_hit(atom/target, def_zone = null)
	if(!isliving(target))	return FALSE
	if(isanimal(target))	return FALSE
	var/mob/living/L = target
	L.apply_effects(stun, weaken, paralyze, irradiate, stutter, eyeblur, drowsy)
	return TRUE

// generate impact effect
/obj/item/projectile/proc/on_impact(atom/A)
    impact_effect(effect_transform)
    if(luminosity_ttl && attached_effect)
        spawn(luminosity_ttl)
        QDEL_NULL(attached_effect)

    if(!ismob(A))
        playsound(src, hitsound_wall, 50, 1, -2)
    return

//Checks if the projectile is eligible for embedding. Not that it necessarily will.
/obj/item/projectile/proc/can_embed()
	//embed must be enabled and damage type must be brute
	if(!embed || getAllDamType(BRUTE) <= 0)
		return FALSE
	return TRUE

/obj/item/projectile/proc/get_structure_damage(var/injury_type)
	if(!injury_type) // Assume homogenous
		return (getAllDamType(BRUTE) + getAllDamType(BURN)) * wound_check(INJURY_TYPE_HOMOGENOUS, wounding_mult, edge, sharp) * 2
	else
		return (getAllDamType(BRUTE) + getAllDamType(BURN)) * wound_check(injury_type, wounding_mult, edge, sharp) * 2

//return 1 if the projectile should be allowed to pass through after all, 0 if not.
/obj/item/projectile/proc/check_penetrate(atom/A)
	return TRUE

/obj/item/projectile/proc/check_fire(atom/target as mob, mob/living/user as mob)  //Checks if you can hit them or not.
	check_trajectory(list(user.x,user.y,user.z), list(target.x, target.y, target.z),null,null, target)

//sets the click point of the projectile using mouse input params
/obj/item/projectile/proc/set_clickpoint(params)
	var/list/mouse_control = params2list(params)
	if(mouse_control["icon-x"])
		p_x = text2num(mouse_control["icon-x"])
	if(mouse_control["icon-y"])
		p_y = text2num(mouse_control["icon-y"])

//called to launch a projectile
/obj/item/projectile/proc/launch(atom/target, atom/firer, targetZone, xOffset = 0, yOffset = 0, zOffset = 0, zStart = 0, angleOffset = 0, proj_sound, user_recoil = 0)
	var/turf/curloc = get_turf(src)
	var/turf/targloc = get_turf(target)
	if (!istype(targloc) || !istype(curloc))
		return TRUE

	if(targloc == curloc) //Shooting something in the same turf
		target.bullet_act(src, targetZone)
		on_impact(target)
		qdel(src)
		return FALSE

	if(proj_sound)
		playsound(proj_sound)

	original = target
	def_zone = targetZone



	muzzle_effect(effect_transform)
	var/list/currentCoords = list()
	currentCoords.Add(x*PPT+HPPT + pixel_x)
	currentCoords.Add(y*PPT+HPPT + pixel_y)
	var/zCoords = z * PPT + zStart
	if(ismob(firer))
		var/mob/living = firer
		if(living.lying)
			zCoords += LEVEL_LYING
		else
			zCoords += LEVEL_CHEST - 3
	currentCoords.Add(zCoords)
	var/list/targetCoords = list()
	targetCoords.Add(target.x*PPT+target.pixel_x+xOffset)
	targetCoords.Add(target.y*PPT+target.pixel_y+yOffset)
	targetCoords.Add(target.z*PPT+target.pixel_z+zOffset + target.getAimingLevel(firer, targetZone))
	new /datum/bullet_data(src, targetZone, firer, currentCoords, targetCoords, 48, angleOffset, 50)
	return FALSE

//called to launch a projectile from a gun
/obj/item/projectile/proc/launch_from_gun(atom/target, mob/user, obj/item/gun/launcher, target_zone, xOffset=0, yOffset=0, zOffset=0, angleOffset)
	if(user == target) //Shooting yourself
		user.bullet_act(src, target_zone)
		qdel(src)
		return FALSE
	forceMove(get_turf(user))

	var/recoil = 0
	if(isliving(user))
		var/mob/living/aimer = user
		recoil = aimer.recoil
		recoil -= projectile_accuracy

		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(H.can_multiz_pb && (!isturf(target)))
				forceMove(get_turf(H.client.eye))
				if(!(loc.Adjacent(target)))
					forceMove(get_turf(H))

	// Special case for mechs, in a ideal world this should always go for the top-most atom.
	if(istype(launcher.loc, /obj/item/mech_equipment))
		firer = launcher.loc.loc
	else
		firer = user
	shot_from = launcher.name
	silenced = launcher.item_flags & SILENT
	return launch(target,user, target_zone, xOffset, yOffset,zOffset, angleOffset, user_recoil = recoil)

/obj/item/projectile/proc/istargetloc(mob/living/target_mob)
	if(target_mob && original)
		var/turf/originalloc
		if(!istype(original, /turf))
			originalloc = original.loc
		else
			originalloc = original
		if(originalloc == target_mob.loc)
			return 1
		else
			return 0
	else
		return 0

/obj/item/projectile/proc/check_hit_zone(distance, recoil)

	def_zone = check_zone(def_zone)
	if(recoil)
		recoil = leftmost_bit(recoil) //LOG2 calculation
	else
		recoil = 0
	distance = leftmost_bit(distance)

	def_zone = ran_zone(def_zone, 100 - (distance + recoil) * 10)

/obj/item/projectile/proc/check_miss_chance(mob/target_mob)

	var/hit_mod = 0
	switch(target_mob.mob_size)
		if(120 to INFINITY)
			hit_mod = -6
		if(80 to 120)
			hit_mod = -4
		if(40 to 80)
			hit_mod = -2
		if(20 to 40)
			hit_mod = 0
		if(10 to 20)
			hit_mod = 2
		if(5 to 10)
			hit_mod = 4
		else
			hit_mod = 6

	if(target_mob == original)
		var/acc_mod = leftmost_bit(projectile_accuracy)
		hit_mod -= acc_mod //LOG2 on the projectile accuracy
	return prob((base_miss_chance[def_zone] + hit_mod) * 10)

//Called when the projectile intercepts a mob. Returns 1 if the projectile hit the mob, 0 if it missed and should keep flying.
/obj/item/projectile/proc/attack_mob(mob/living/target_mob, miss_modifier=0)
	if(!istype(target_mob))
		return
	message_admins("Called attack mob")

	//roll to-hit
	miss_modifier = 0

	var/result = PROJECTILE_CONTINUE

	if(target_mob != original) // If mob was not clicked on / is not an NPC's target, checks if the mob is concealed by cover
		var/turf/cover_loc = get_step(get_turf(target_mob), get_dir(get_turf(target_mob), starting))
		for(var/obj/O in cover_loc)
			if(istype(O,/obj/structure/low_wall) || istype(O,/obj/machinery/deployable/barrier) || istype(O,/obj/structure/barricade) || istype(O,/obj/structure/table))
				if(!silenced)
					visible_message(SPAN_NOTICE("\The [target_mob] ducks behind \the [O], narrowly avoiding \the [src]!"))
				return FALSE
		for(var/obj/structure/table/O in get_turf(target_mob))
			if(istype(O) && O.flipped && (get_dir(get_turf(target_mob), starting) == O.dir))
				if(!silenced)
					visible_message(SPAN_NOTICE("\The [target_mob] ducks behind \the [O], narrowly avoiding \the [src]!"))
				return FALSE


	if(iscarbon(target_mob))
		// Handheld shields
		var/mob/living/carbon/C = target_mob
		var/obj/item/shield/S
		for(S in get_both_hands(C))
			if(S && S.block_bullet(C, src, def_zone))
				on_hit(S,def_zone)
				qdel(src)
				return TRUE
			break //Prevents shield dual-wielding

//		S = C.get_equipped_item(slot_back)
//		if(S && S.block_bullet(C, src, def_zone))
//			on_hit(S,def_zone)
//			qdel(src)
//			return TRUE

	if(check_miss_chance(target_mob))
		result = PROJECTILE_FORCE_MISS
	else
		result = target_mob.bullet_act(src, def_zone)

	if(result == PROJECTILE_FORCE_MISS || result == PROJECTILE_FORCE_MISS_SILENCED)
		if(!silenced && result == PROJECTILE_FORCE_MISS)
			visible_message(SPAN_NOTICE("\The [src] misses [target_mob] narrowly!"))
			if(isroach(target_mob))
				bumped = FALSE // Roaches do not bump when missed, allowing the bullet to attempt to hit the rest of the roaches in a single cluster
		return FALSE
	/*
	//hit messages
	if(silenced)
		to_chat(target_mob, SPAN_DANGER("You've been hit in the [parse_zone(def_zone)] by \the [src]!"))
	else
		visible_message(SPAN_DANGER("\The [target_mob] is hit by \the [src] in the [parse_zone(def_zone)]!"))//X has fired Y is now given by the guns so you cant tell who shot you if you could not see the shooter
	*/
	playsound(target_mob, pick(mob_hit_sound), 40, 1)

	//admin logs
	if(!no_attack_log)
		if(ismob(firer))

			var/attacker_message = "shot with \a [src.type]"
			var/victim_message = "shot with \a [src.type]"
			var/admin_message = "shot (\a [src.type])"

			admin_attack_log(firer, target_mob, attacker_message, victim_message, admin_message)
		else
			target_mob.attack_log += "\[[time_stamp()]\] <b>UNKNOWN SUBJECT (No longer exists)</b> shot <b>[target_mob]/[target_mob.ckey]</b> with <b>\a [src]</b>"
			msg_admin_attack("UNKNOWN shot [target_mob] ([target_mob.ckey]) with \a [src] (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[target_mob.x];Y=[target_mob.y];Z=[target_mob.z]'>JMP</a>)")

	if(target_mob.mob_classification & CLASSIFICATION_ORGANIC)
		var/turf/target_loca = get_turf(target_mob)
		var/mob/living/L = target_mob
		if(damage_types[BRUTE] > 10)
			var/splatter_dir = dir
			if(starting)
				splatter_dir = get_dir(starting, target_loca)
				target_loca = get_step(target_loca, splatter_dir)
			var/blood_color = "#C80000"
			if(ishuman(target_mob))
				var/mob/living/carbon/human/H = target_mob
				blood_color = H.species.blood_color
			new /obj/effect/overlay/temp/dir_setting/bloodsplatter(target_mob.loc, splatter_dir, blood_color)
			if(target_loca && prob(50))
				target_loca.add_blood(L)

	if(istype(src, /obj/item/projectile/beam/psychic) && istype(target_mob, /mob/living/carbon/human))
		var/obj/item/projectile/beam/psychic/psy = src
		var/mob/living/carbon/human/H = target_mob
		if(psy.contractor && result && (H.sanity.level <= 0))
			psy.holder.reg_break(H)

	if(result == PROJECTILE_STOP)
		return TRUE
	else
		return FALSE

/// We don't care about order since we are just simulating to see wheter we can reach something or not
/proc/simulateBulletScan(turf/scanning, atom/firer, bulletDir, startX, startY, startZ, StepX, StepY, StepZ, passFlags)
	. = PROJECTILE_CONTINUE
	var/list/hittingList = scanning.contents.Copy() + scanning
	for(var/atom/thing as anything in hittingList)
		if(thing.atomFlags & AF_IGNORE_ON_BULLETSCAN)
			continue
		if(thing.hitbox && thing.hitbox.intersects(thing, thing.dir, startX, startY, startZ, &StepX, &StepY, &StepZ))
			if(istype(thing, /obj/structure/window) && passFlags & PASSGLASS)
				continue
			if(istype(thing, /obj/structure/grille) && passFlags & PASSGRILLE)
				continue
			if(istype(thing, /obj/structure/table) && passFlags & PASSTABLE)
				continue
			return PROJECTILE_STOP
		if(!length(thing.attached))
			continue
		for(var/atom/possibleTarget as anything in thing.attached)
			if(thing.attached[possibleTarget] & ATFS_IGNORE_HITS)
				continue
			if(possibleTarget.attached[thing] & ATFA_DIRECTIONAL_HITTABLE && !(possibleTarget.dir & reverse_dir[bulletDir]))
				continue
			if(possibleTarget.attached[thing] & ATFA_DIRECTIONAL_HITTABLE_STRICT && !(possibleTarget.dir == reverse_dir[bulletDir]))
				continue
			if(possibleTarget.hitbox && possibleTarget.hitbox.intersects(thing, thing.dir, startX, startY, startZ, &StepX, &StepY, &StepZ))
				if(istype(thing, /obj/structure/window) && passFlags & PASSGLASS)
					continue
				if(istype(thing, /obj/structure/grille) && passFlags & PASSGRILLE)
					continue
				if(istype(thing, /obj/structure/table) && passFlags & PASSTABLE)
					continue
				return PROJECTILE_STOP
	return PROJECTILE_CONTINUE

/// The lower the index , the higher the priority. If you add new paths to the list , make sure to increase the amount of lists in scanTurf below.
#define HittingPrioritiesList list(/obj/machinery/door/blast/shutters/glass, /mob/living,/obj/structure/multiz/stairs/active,/obj/structure,/atom)
/obj/item/projectile/proc/scanTurf(turf/scanning, bulletDir, startX, startY, startZ, pStepX, pStepY, pStepZ)
	. = PROJECTILE_CONTINUE
	if(atomFlags & AF_VISUAL_MOVE)
		return

	var/list/hitboxesList = list()

	for(var/atom/target as anything in scanning.contents)
		if(target.atomFlags & AF_IGNORE_ON_BULLETSCAN)
			continue
		if(target in dataRef.cannotHit)
			continue
		if(target == firer)
			continue
		if(target == src)
			continue
		if(!target.hitbox)
			message_admins("[src] [src.type] has no hitbox!")
			continue
		/// third slot rezerved for flags passed back by hitbox intersect
		var/hitFlags = null

		var/hitboxIntersect = target.hitbox.intersects(target, target.dir, startX, startY, startZ, pStepX, pStepY, pStepZ, &hitFlags)
		if(target.hitbox && !hitboxIntersect)
			continue
		hitboxesList.Add(list(hitboxIntersect, hitFlags, target))
		for(var/atom/possibleTarget as anything in target.attached)
			if(target.attached[possibleTarget] & ATFS_IGNORE_HITS)
				continue
			if(possibleTarget.attached[target] & ATFA_DIRECTIONAL_HITTABLE && !(possibleTarget.dir & reverse_dir[bulletDir]))
				continue
			if(possibleTarget.attached[target] & ATFA_DIRECTIONAL_HITTABLE_STRICT && !(possibleTarget.dir == reverse_dir[bulletDir]))
				continue
			var/intersectDistance = possibleTarget.hitbox.intersects(possibleTarget, possibleTarget.dir, startX, startY,startZ, pStepX, pStepY, pStepZ, &hitFlags)
			if(intersectDistance)
				if(target.attached[possibleTarget] & ATFS_PRIORITIZE_ATTACHED_FOR_HITS)
					var/listReference = hitboxesList[length(hitboxesList)]
					hitboxesList[length(hitboxesList)]= list(intersectDistance, hitFlags, possibleTarget)
					hitboxesList.Add(listReference)
				else
					hitboxesList.Add(list(intersectDistance, hitFlags, possibleTarget))

	var/temp
	for(var/i in 1 to length(hitboxesList) - 1)
		if(hitboxesList[i][1] < hitboxesList[i+1][1])
			temp = hitboxesList[i]
			hitboxesList[i] = hitboxesList[i+1]
			hitboxesList[i+1] = temp
			i = max(i-2, 1)

	for(var/i in 1 to length(hitboxesList))
		var/atom/target = hitboxesList[i][3]
		if(target.bullet_act(src, def_zone, hitboxesList[i][2]) & PROJECTILE_STOP)
			onBlockingHit(target)
			return PROJECTILE_STOP

	return PROJECTILE_CONTINUE


/*
/obj/item/projectile/Bump(atom/A as mob|obj|turf|area, forced = FALSE)
	if(!density)
		return TRUE
	if(A == src)
		return FALSE
	if(A == firer)
		forceMove(A.loc)
		return FALSE //go fuck yourself in another place pls


	if((bumped && !forced) || (A in permutated))
		return FALSE

	var/passthrough = FALSE //if the projectile should continue flying

	var/tempLoc = get_turf(A)

	bumped = TRUE
	if(istype(A, /obj/structure/multiz/stairs/active))
		var/obj/structure/multiz/stairs/active/S = A
		if(S.target)
			forceMove(get_turf(S.target))
			trajectory.loc_z = loc.z
			bumped = FALSE
			return FALSE
	if(ismob(A))
		// Mobs inside containers shouldnt get bumped(such as mechs or closets)
		if(!isturf(A.loc))
			bumped = FALSE
			return FALSE

		var/mob/M = A
		if(isliving(A))
			//if they have a neck grab on someone, that person gets hit instead
			var/obj/item/grab/G = locate() in M
			if(G && G.state >= GRAB_NECK)
				visible_message(SPAN_DANGER("\The [M] uses [G.affecting] as a shield!"))
				if(Bump(G.affecting, TRUE))
					return //If Bump() returns 0 (keep going) then we continue on to attack M.
			passthrough = !attack_mob(M)
		else
			passthrough = FALSE //so ghosts don't stop bullets
	else
		passthrough = (A.bullet_act(src, def_zone) == PROJECTILE_CONTINUE) //backwards compatibility
		if(isturf(A))
			for(var/obj/O in A) // if src's bullet act spawns more objs, the list will increase,
				if(O.density)
					O.bullet_act(src) // causing exponential growth due to the spawned obj spawning itself
			for(var/mob/living/M in A)
				attack_mob(M)

	//penetrating projectiles can pass through things that otherwise would not let them
	if(!passthrough && penetrating > 0)
		if(check_penetrate(A))
			passthrough = TRUE
		penetrating--

	//the bullet passes through a dense object!
	if(passthrough)
		//move ourselves onto A so we can continue on our way
		if (!tempLoc)
			qdel(src)
			return TRUE

		forceMove(tempLoc)
		if (A)
			permutated.Add(A)
		bumped = FALSE //reset bumped variable!
		return FALSE

	//stop flying
	onBlockingHit(A)
	return TRUE
*/

/obj/item/projectile/proc/onBlockingHit(atom/A)
	on_impact(A)
	#ifdef BULLETDEBUG
	message_admins("[src] Has hit [A]")
	#endif
	dataRef.lifetime = 0

/obj/effect/bullet_sparks
	name = "bullet hit"
	icon = 'icons/effects/effects.dmi'
	icon_state = "nothing"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/bullet_sparks/Initialize(mapload, ...)
	. = ..()
	flick("bullet_hit", src)
	QDEL_IN(src, 3 SECONDS)


/// Called to properly delete a bullet after a delay from its impact, ensures the animation for it travelling finishes
/obj/item/projectile/proc/finishDeletion()
	var/atom/visEffect = new /obj/effect/bullet_sparks(loc)
	visEffect.layer = ABOVE_ALL_MOB_LAYER
	visEffect.pixel_x = src.pixel_x
	visEffect.pixel_y = src.pixel_y
	visEffect.transform = src.transform
	visEffect.update_plane()

	QDEL_IN(src, SSbullets.wait)

/obj/item/projectile/explosion_act(target_power, explosion_handler/handler)
	return 0

/obj/item/projectile/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	return TRUE

/obj/item/projectile/proc/before_move()
	return FALSE

/obj/item/projectile/proc/muzzle_effect(var/matrix/T)
	//This can happen when firing inside a wall, safety check
	if (!location)
		return

	if(silenced)
		return

	if(ispath(muzzle_type))
		var/obj/effect/projectile/M = new muzzle_type(get_turf(src))

		if(istype(M))
			if(proj_color)
				var/icon/I = new(M.icon, M.icon_state)
				I.Blend(proj_color)
				M.icon = I
			M.set_transform(T)
			M.pixel_x = location.pixel_x
			M.pixel_y = location.pixel_y
			M.activate()

/obj/item/projectile/proc/tracer_effect(var/matrix/M)

	//This can happen when firing inside a wall, safety check
	if (!location)
		return

	if(ispath(tracer_type))
		var/obj/effect/projectile/P = new tracer_type(location.loc)

		if(istype(P))
			if(proj_color)
				var/icon/I = new(P.icon, P.icon_state)
				I.Blend(proj_color)
				P.icon = I
			P.set_transform(M)
			P.pixel_x = location.pixel_x
			P.pixel_y = location.pixel_y
			if(!hitscan)
				P.activate(step_delay)	//if not a hitscan projectile, remove after a single delay
			else
				P.activate()

/obj/item/projectile/proc/luminosity_effect()
    if (!location)
        return

    if(attached_effect)
        attached_effect.Move(src.loc)

    else if(luminosity_range && luminosity_power && luminosity_color)
        attached_effect = new /obj/effect/effect/light(src.loc, luminosity_range, luminosity_power, luminosity_color)

/obj/item/projectile/proc/impact_effect(var/matrix/M)
	//This can happen when firing inside a wall, safety check
	if (!location)
		return

	if(ispath(impact_type))
		var/obj/effect/projectile/P = new impact_type(location.loc)

		if(istype(P))
			if(proj_color)
				var/icon/I = new(P.icon, P.icon_state)
				I.Blend(proj_color)
				P.icon = I
			P.set_transform(M)
			P.pixel_x = location.pixel_x
			P.pixel_y = location.pixel_y
			P.activate(P.lifetime)

/obj/item/projectile/proc/block_damage(amount, atom/A)
	amount /= armor_divisor
	var/damageLeft = 0
	var/damageTotal = 0
	for(var/armorType in damage)
		for(var/list/damageElement in damage[armorType])
			damageTotal += damageElement[2]
			damageElement[2] = max(0, damageElement[2] - amount)
			if(damageElement[2] == 0)
				damage[armorType] -= damageElement
			else
				damageLeft += damageElement[2]

	var/elementsLeft = 0
	for(var/armorType in damage)
		for(var/list/damageElement in damage[armorType])
			elementsLeft++

	if(!elementsLeft)
		on_impact(A)
		qdel(src)

	return damageTotal > 0 ? (damageLeft / damageTotal) :0

/proc/get_proj_icon_by_color(var/obj/item/projectile/P, var/color)
	var/icon/I = new(P.icon, P.icon_state)
	I.Blend(color)
	return I

/proc/check_trajectory(list/startingCoordinates, list/targetCoordinates, passFlags=PASSTABLE|PASSGLASS|PASSGRILLE, flags=null, atom/target, turfLimit = 8)
	var/turf/movementTurf
	var/turf/targetTurf = get_turf(target)
	var/currentX = startingCoordinates[1]
	var/currentY = startingCoordinates[2]
	var/currentZ = startingCoordinates[3]
	var/turf/currentTurf = locate(round(currentX/PPT), round(currentY/PPT), round(currentZ/PPT))
	var/bulletDir
	var/stepX
	var/stepY
	var/stepZ
	var/angle = ATAN2(targetCoordinates[2] - startingCoordinates[2], targetCoordinates[1] - startingCoordinates[1])
	var/ratioX = sin(angle)
	var/ratioY = cos(angle)
	var/ratioZ = (targetCoordinates[3] - startingCoordinates[3])/DIST_EUCLIDIAN_2D(startingCoordinates[1], startingCoordinates[2], targetCoordinates[1], targetCoordinates[2])
	var/traveledTurfs = 0
	#ifdef BULLETDEBUG
	var/list/colored = list()
	#endif
	while(currentTurf != targetTurf && traveledTurfs < turfLimit)
		bulletDir = (EAST*(ratioX>0)) | (WEST*(ratioX<0)) | (NORTH*(ratioY>0)) | (SOUTH*(ratioY<0)) | (UP*(ratioZ>0)) | (DOWN*(ratioZ<0))
		stepX = ratioX * HPPT
		stepY = ratioY * HPPT
		stepZ = ratioZ * HPPT
		movementTurf = locate(round((currentX+stepX)/PPT),round((currentY+stepY)/PPT),round((currentZ+stepZ)/PPT))
		if(!movementTurf)
			return FALSE
		if(movementTurf == currentTurf)
			currentX += stepX
			currentY += stepY
			currentZ += stepZ
			continue
		if(simulateBulletScan(movementTurf, bulletDir, currentX, currentY, currentZ, &stepX, &stepY, &stepZ, passFlags) == PROJECTILE_STOP)
			#ifdef BULLETDEBUG
			movementTurf.color = COLOR_RED
			colored.Add(movementTurf)
			#endif
			return movementTurf == targetTurf
		currentX += stepX
		currentY += stepY
		currentZ += stepZ
		currentTurf = movementTurf
		traveledTurfs++
		#ifdef BULLETDEBUG
		movementTurf.color = COLOR_GREEN
		colored.Add(movementTurf)
		#endif

	#ifdef BULLETDEBUG
	if(length(colored))
		QDEL_LIST_IN(colored, 2 SECONDS)
	#endif
	return FALSE


