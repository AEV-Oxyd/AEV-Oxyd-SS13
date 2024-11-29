/obj/item/projectile/bullet
	name = "bullet"
	icon_state = "bullet"
	damage_types = list(
		ARMOR_BULLET = list(
			DELEM(BRUTE, 40)
		)
	)
	nodamage = 0
	embed = TRUE
	sharp = TRUE // Also used for checking whether this penetrates
	hitsound_wall = "ric_sound"
	var/mob_passthrough_check = 0
	recoil = 5

	muzzle_type = /obj/effect/projectile/bullet/muzzle

/obj/item/projectile/bullet/on_hit(atom/target)
	if (..(target))
		var/mob/living/L = target
		shake_camera(L, 1, 1, 0.5)

/obj/item/projectile/bullet/attack_mob(var/mob/living/target_mob, distance, miss_modifier)
	if(damage_types[BRUTE] > 20 && prob(damage_types[BRUTE]*penetrating/2))
		mob_passthrough_check = 1
	else
		var/obj/item/grab/G = locate() in target_mob
		if(G && G.state >= GRAB_NECK)
			mob_passthrough_check = rand()
		else
			mob_passthrough_check = 0
	return ..()

/obj/item/projectile/bullet/can_embed()
	//prevent embedding if the projectile is passing through the mob
	if(mob_passthrough_check)
		return FALSE
	return ..()

/obj/item/projectile/bullet/check_penetrate(var/atom/A)
	if((!A || !A.density) && !istype(A, /obj/item/shield)) return 1 //if whatever it was got destroyed when we hit it, then I guess we can just keep going

	if(istype(A, /mob/living/exosuit))
		return 1 //exosuits have their own penetration handling

	var/blocked_damage = 0.0001
	if(istype(A, /turf/simulated/wall)) // TODO: refactor this from functional into OOP
		var/turf/simulated/wall/W = A
		blocked_damage = round(W.material.integrity / 8)
	else if(istype(A, /obj/item/shield))
		var/obj/item/shield/S = A
		blocked_damage = round(S.shield_integrity / 8)
	else if(istype(A, /obj/machinery/door))
		var/obj/machinery/door/D = A
		blocked_damage = round(D.maxHealth / 8)
		if(D.glass) blocked_damage /= 2
	else if(istype(A, /obj/structure/girder))
		return TRUE
	else if(istype(A, /obj/structure/low_wall))
		blocked_damage = 20 // hardcoded, value is same as steel wall, will have to be changed once low walls have integrity
	else if(istype(A, /obj/structure/table))
		var/obj/structure/table/T = A
		blocked_damage = round(T.maxHealth / 8)
	else if(istype(A, /obj/structure/barricade))
		var/obj/structure/barricade/B = A
		blocked_damage = round(B.material.integrity / 8)
	else if(istype(A, /obj/machinery) || istype(A, /obj/structure))
		blocked_damage = 20

	var/percentile_blocked = block_damage(blocked_damage, A)
	if(percentile_blocked > 0.5)
		percentile_blocked = CLAMP(percentile_blocked, 50, 90) / 100 // calculate leftover velocity, capped between 50% and 90%

		step_delay = min(step_delay / percentile_blocked, step_delay / 2)

		if(A.opacity || istype(A, /obj/item/shield))
			//display a message so that people on the other side aren't so confused
			A.visible_message(SPAN_WARNING("\The [src] pierces through \the [A]!"))
			playsound(A.loc, 'sound/weapons/shield/shieldpen.ogg', 50, 1)
		return 1

	return 0

/obj/item/projectile/bullet/shotgunBuckshot
	name = "12 Gauge buck pellet"
	damage_types = list(
		ARMOR_BULLET = list(
			DELEM(BRUTE, 12)
		)
	)
	/// Wheter we are the initla buckshot pellet that should create the rest or not
	var/isInitial = TRUE
	/// Amount of pellets to create / replicate
	var/pelletCount = 15
	/// Angle offset. This is forced by the shotgun if fired from one. If not, then the default is used
	var/angleOffset = 24

/obj/item/projectile/bullet/shotgunBuckshot/launch(atom/target, target_zone, x_offset, y_offset, angle_offset, proj_sound, user_recoil)
	if(!isInitial)
		return ..()
	else while(pelletCount)
		pelletCount--
		var/obj/item/projectile/bullet/shotgunBuckshot/fellowPellet = new(get_turf(src))
		fellowPellet.isInitial = FALSE
		fellowPellet.firer = src.firer
		fellowPellet.PrepareForLaunch()
		var/angleBruh = rand(-angleOffset/2,angleOffset/2)
		fellowPellet.launch(target, target_zone, x_offset , y_offset, angleBruh, null, null)
	..()

//For projectiles that actually represent clouds of projectiles
/obj/item/projectile/bullet/pellet
	name = "shrapnel" //'shrapnel' sounds more dangerous (i.e. cooler) than 'pellet'
	damage_types = list(
		ARMOR_BULLET = list(
			DELEM(BRUTE, 15)
		)
	)
	//icon_state = "bullet" //TODO: would be nice to have it's own icon state
	var/pellets = 4			//number of pellets
	var/range_step = 2		//projectile will lose a fragment each time it travels this distance. Can be a non-integer.
	var/base_spread = 90	//lower means the pellets spread more across body parts. If zero then this is considered a shrapnel explosion instead of a shrapnel cone
	var/spread_step = 10	//higher means the pellets spread more across body parts with distance
	var/pellet_to_knockback_ratio = 0
	wounding_mult = WOUNDING_SMALL
	matter = list(MATERIAL_STEEL = 0.4)

/obj/item/projectile/bullet/pellet/launch_from_gun(atom/target, mob/user, obj/item/gun/launcher, target_zone, x_offset=0, y_offset=0,zOffset, angle_offset)
	for(var/entry in matter) // this allows for the projectile in the casing having the correct matter
		matter[entry] /= pellets // yet disallows for pellet shrapnel created on impact multiplying the matter count
	. = ..()

/obj/item/projectile/bullet/pellet/proc/get_pellets(var/distance)
	var/pellet_loss = round((distance - 1)/range_step) //pellets lost due to distance
	var/remaining = pellets - pellet_loss
	if (remaining < 0)
		return 0
	return ROUND_PROB(remaining)

/obj/item/projectile/bullet/pellet/attack_mob(var/mob/living/target_mob, var/distance, var/miss_modifier)


	var/total_pellets = get_pellets(distance)
	if (total_pellets <= 0)
		return 1
	var/spread = max(base_spread - (spread_step*distance), 0)

	//shrapnel explosions miss prone mobs with a chance that increases with distance
	var/prone_chance = 0
	if(!base_spread)
		prone_chance = max(spread_step*(distance - 2), 0)

	var/hits = 0
	for (var/i in 1 to total_pellets)
		if(target_mob.lying && target_mob != original && prob(prone_chance))
			continue

		//pellet hits spread out across different zones, but 'aim at' the targeted zone with higher probability
		var/old_zone = def_zone
		def_zone = ran_zone(def_zone, spread)
		if (..()) hits++
		def_zone = old_zone //restore the original zone the projectile was aimed at

	pellets -= hits //each hit reduces the number of pellets left
	if(pellet_to_knockback_ratio)
		var/knockback_calc = round(hits / pellet_to_knockback_ratio)
		if(knockback_calc)
			var/target_turf = get_turf_away_from_target_complex(target_mob, starting, knockback_calc)
			throw_at(target_turf, knockback_calc, 2, firer)

	if (hits >= total_pellets || pellets <= 0)
		return 1
	return 0

/obj/item/projectile/bullet/pellet/get_structure_damage()
	var/distance = get_dist(loc, starting)
	return ..() * get_pellets(distance)

/obj/item/projectile/bullet/pellet/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, glide_size_override = 0, initiator = src)
	. = ..()

	//If this is a shrapnel explosion, allow mobs that are prone to get hit, too
	if(. && !base_spread && isturf(loc))
		for(var/mob/living/M in loc)
			if(M.lying || !M.CanPass(src, loc)) //Bump if lying or if we would normally Bump.
				if(Bump(M)) //Bump will make sure we don't hit a mob multiple times
					return

/obj/item/projectile/bullet/pellet/adjust_damages(var/list/newdamages)
	if(!newdamages.len)
		return
	for(var/damage_type in newdamages)
		var/bonus = pellets > 2 ? newdamages[damage_type] / pellets * 2 : newdamages[damage_type]
		if(damage_type == IRRADIATE)
			irradiate += bonus
			continue
		damage_types[damage_type] += bonus
