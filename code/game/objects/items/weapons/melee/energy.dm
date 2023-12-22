/obj/item/melee/energy
	icon = 'icons/obj/weapons.dmi'
	sharp = FALSE
	edge = FALSE
	flags = NOBLOODY
	structure_damage_factor = STRUCTURE_DAMAGE_BREACHING
	heat = 3800
	embed_mult = 0 //No physical matter to catch onto things
	bad_type = /obj/item/melee/energy
	melleDamages = list(
		ARMOR_BLUNT = list(
			DELEM(BRUTE,2)
		)
	)
	var/list/activeDamages = list(
		ARMOR_ENERGY = list(
			DELEM(BRUTE, 30),
			DELEM(BURN, 25)
		)
	)
	var/active = 0
	var/active_throwforce
	var/active_volumeClass

/obj/item/melee/energy/is_hot()
	if (active)
		return heat

/obj/item/melee/energy/proc/activate(mob/living/user)
	anchored = TRUE
	if(active)
		return
	active = 1
	melleDamages = activeDamages.Copy()
	throwforce = active_throwforce
	sharp = TRUE
	edge = TRUE
	volumeClass = active_volumeClass
	playsound(user, 'sound/weapons/saberon.ogg', 50, 1)
	update_wear_icon()

/obj/item/melee/energy/proc/deactivate(mob/living/user)
	anchored = FALSE
	if(!active)
		return
	playsound(user, 'sound/weapons/saberoff.ogg', 50, 1)
	active = 0
	melleDamages = GLOB.melleDamagesCache[type]:Copy()
	throwforce = initial(throwforce)
	sharp = initial(sharp)
	edge = initial(edge)
	volumeClass = initial(volumeClass)
	update_wear_icon()

/obj/item/melee/energy/attack_self(mob/living/user as mob)
	if (active)
/*		if ((CLUMSY in user.mutations) && prob(50))
			user.visible_message(SPAN_DANGER("\The [user] accidentally cuts \himself with \the [src]."),\
			SPAN_DANGER("You accidentally cut yourself with \the [src]."))
			user.take_organ_damage(5,5)	*/
		deactivate(user)
	else
		activate(user)
	add_fingerprint(user)

/*
 * Energy Axe
 */
/obj/item/melee/energy/axe
	name = "energy axe"
	desc = "A battle axe with some kind of red energy crystal. Pretty sharp."
	icon_state = "axe0"
	activeDamages = list(ARMOR_SLASH = list(DELEM(BRUTE,40)), ARMOR_POINTY=list(DELEM(BRUTE,20)))
	active_throwforce = 50
	active_volumeClass = ITEM_SIZE_HUGE
	melleDamages = list(
		ARMOR_SLASH = list(
			DELEM(BRUTE,20)
		),
		ARMOR_POINTY = list(
			DELEM(BRUTE,10)
		)
	)
	throwforce = 10
	throw_speed = 1
	throw_range = 5
	volumeClass = ITEM_SIZE_NORMAL
	flags = CONDUCT | NOBLOODY
	origin_tech = list(TECH_MAGNET = 3, TECH_COMBAT = 4)
	attack_verb = list("attacked", "chopped", "cleaved", "torn", "cut")
	sharp = TRUE
	edge = TRUE

/obj/item/melee/energy/axe/activate(mob/living/user)
	icon_state = "axe1"
	..()
	to_chat(user, SPAN_NOTICE("\The [src] is now energized."))

/obj/item/melee/energy/axe/deactivate(mob/living/user)
	icon_state = initial(icon_state)
	..()
	to_chat(user, SPAN_NOTICE("\The [src] is de-energized. It's just a regular axe now."))

/*
 * Energy Sword
 */
/obj/item/melee/energy/sword
	color
	name = "energy sword"
	desc = "May the Force be with you."
	icon_state = "sword0"
	activeDamages = list(ARMOR_ENERGY = list(DELEM(BURN,30), DELEM(BRUTE,15))) // Go forth and slay, padawan
	active_throwforce = WEAPON_FORCE_LETHAL
	no_double_tact = TRUE
	active_volumeClass = ITEM_SIZE_BULKY
	melleDamages = list(
		ARMOR_BLUNT = list(
			DELEM(BRUTE,5)
		)
	)

	throwforce = WEAPON_FORCE_HARMLESS
	throw_speed = 1
	throw_range = 5
	volumeClass = ITEM_SIZE_SMALL
	flags = NOBLOODY
	origin_tech = list(TECH_MAGNET = 3, TECH_COVERT = 4)
	sharp = TRUE
	edge = TRUE
	var/blade_color

/obj/item/melee/energy/sword/dropped(var/mob/user)
	..()
	deactivate(user)

/obj/item/melee/energy/sword/Initialize(mapload)
	. = ..()
	if(!blade_color)
		blade_color = pick("red","blue","green","purple")

/obj/item/melee/energy/sword/green
	blade_color = "green"

/obj/item/melee/energy/sword/red
	blade_color = "red"

/obj/item/melee/energy/sword/blue
	blade_color = "blue"

/obj/item/melee/energy/sword/purple
	blade_color = "purple"

/obj/item/melee/energy/sword/pirate
	blade_color = "cutlass"

/obj/item/melee/energy/sword/sabre
	blade_color = "green"

/obj/item/melee/energy/sword/activate(mob/living/user)
	if(!active)
		to_chat(user, SPAN_NOTICE("\The [src] is now energized."))
	icon_state = "sword[blade_color]"
	..()
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	tool_qualities = list(QUALITY_CUTTING = 30,  QUALITY_WIRE_CUTTING = 20, QUALITY_LASER_CUTTING = 20, QUALITY_WELDING = 10, QUALITY_CAUTERIZING = 10)

/obj/item/melee/energy/sword/deactivate(mob/living/user)
	if(active)
		to_chat(user, SPAN_NOTICE("\The [src] deactivates!"))
	icon_state = initial(icon_state)
	..()
	attack_verb = list()
	tool_qualities = initial(tool_qualities)

/obj/item/melee/energy/sword/handle_shield(mob/user, var/damage, atom/damage_source = null, mob/attacker = null, var/def_zone = null, var/attack_text = "the attack")
	if(active && default_parry_check(user, attacker, damage_source) && prob(50))
		user.visible_message(SPAN_DANGER("\The [user] parries [attack_text] with \the [src]!"))

		var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
		spark_system.set_up(5, 0, user.loc)
		spark_system.start()
		playsound(user.loc, 'sound/weapons/blade1.ogg', 50, 1)
		return 1
	return 0

/obj/item/melee/energy/sword/pirate
	name = "energy cutlass"
	desc = "Arrrr matey."
	icon_state = "cutlass0"


/obj/item/melee/energy/sword/sabre
	name = "laser sabre"
	desc = "You feel the radiant glow below your skin."
	origin_tech = list(TECH_MAGNET = 5, TECH_POWER = 6, TECH_COMBAT = 3)
	activeDamages = list(
		ARMOR_ENERGY = list(
			DELEM(BRUTE,20),
			DELEM(BURN,20)
		)
	)
	active_throwforce = WEAPON_FORCE_ROBUST

/*
 *Energy Blade
 */

//Can't be activated or deactivated, so no reason to be a subtype of energy
/obj/item/melee/energy/blade
	name = "energy blade"
	desc = "A concentrated beam of energy in the shape of a blade. Very stylish... and lethal."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "blade"
	melleDamages = list(
		ARMOR_ENERGY = list(
			DELEM(BURN,30),
			DELEM(BRUTE,30)
		))
	sharp = TRUE
	edge = TRUE
	anchored = TRUE    // Never spawned outside of inventory, should be fine.
	throwforce = 1  //Throwing or dropping the item deletes it.
	throw_speed = 1
	throw_range = 1
	volumeClass = ITEM_SIZE_BULKY
	flags = NOBLOODY
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	var/mob/living/creator
	var/datum/effect/effect/system/spark_spread/spark_system
	var/cleanup = TRUE	// Should the blade despawn moments after being discarded by the summoner?
	var/init_procees = TRUE
	var/stunmode = FALSE
	var/stunforce = 0
	var/agonyforce = 40

/obj/item/melee/energy/blade/Initialize(mapload)
	. = ..()
	if(init_procees)
		spark_system = new /datum/effect/effect/system/spark_spread()
		spark_system.set_up(5, 0, src)
		spark_system.attach(src)
		START_PROCESSING(SSobj, src)

/obj/item/melee/energy/blade/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/melee/energy/blade/dropped()
	if(cleanup)
		spawn(1) if(src) qdel(src)

/obj/item/melee/energy/blade/Process()
	if(!creator || loc != creator || (creator.l_hand != src && creator.r_hand != src))
		// Tidy up a bit.
		if(isliving(loc))
			var/mob/living/carbon/human/host = loc
			if(istype(host))
				for(var/obj/item/organ/external/organ in host.organs)
					for(var/obj/item/O in organ.implants)
						if(O == src)
							organ.implants -= src
			host.pinned -= src
			host.embedded -= src
			host.drop_from_inventory(src)
		if(cleanup)
			spawn(1) if(src) qdel(src)

/obj/item/melee/energy/blade/organ_module //just to make sure that blade doesnt delet itself
	no_double_tact = TRUE //Retains BULKY defensive capabilities like parrying while blocking while being fast as other armblades
	cleanup = FALSE
	init_procees = FALSE

/obj/item/melee/energy/blade/organ_module/attack_self(mob/user)

/obj/item/melee/energy/blade/attack_self(mob/user as mob)
	if(stunmode)
		desc = "A concentrated beam of energy in the shape of a blade. Very stylish... and lethal."
		icon_state = "blade"
		melleDamages = list(
		ARMOR_ENERGY = list(
			DELEM(BRUTE,30),
			DELEM(BURN,30)
		))
		sharp = FALSE
		edge = TRUE
		attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
		stunmode = FALSE
	else
		desc = "A concentrated beam of energy in the shape of a blade. Very stylish... for a stun baton."
		icon_state = "blade_stun"
		melleDamages = list(
		ARMOR_ENERGY = list(
			DELEM(HALLOSS, 40),
			DELEM(BURN,10)
		))
		sharp = FALSE
		edge = FALSE
		attack_verb = list("beaten", "battered", "struck")
		stunmode = TRUE
	update_wear_icon()


/obj/item/melee/energy/blade/apply_hit_effect(mob/living/target, mob/living/user, hit_zone)
	if(!istype(target))
		return ..()
	if(isrobot(target))
		return ..()
	if(stunmode)
		var/agony = agonyforce
		var/stun = stunforce
		var/obj/item/organ/external/affecting = null
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			affecting = H.get_organ(user.targeted_organ)

		if(affecting)
			target.visible_message(SPAN_DANGER("[target] has been punched in the [affecting.name] with [src] by [user]!"))
		else
			target.visible_message(SPAN_DANGER("[target] has been punched with [src] by [user]!"))
		playsound(loc, 'sound/weapons/Egloves.ogg', 50, 1, -1)
		target.stun_effect_act(stun, agony, user.targeted_organ, src)
		msg_admin_attack("[key_name(user)] stunned [key_name(target)] with the [src].")
		user.attack_log += "\[[time_stamp()]\] <font color='red'>Stunned [key_name(target)] with [src]</font>"
		target.attack_log += "\[[time_stamp()]\] <font color='orange'>Was stunned by [key_name(target)] with [src]</font>"

		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			H.forcesay(hit_appends)
	else
		..()
