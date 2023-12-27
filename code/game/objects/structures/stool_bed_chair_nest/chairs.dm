/obj/structure/bed/chair	//YES, chairs are a type of bed, which are a type of stool. This works, believe me.	-Pete
	name = "chair"
	desc = "You sit in this. Either by will or force."
	description_info = "Can be used as a support to climb up by looking up and clicking on a free tile that is not blocked by a railing"
	icon_state = "chair_preview"
	color = "#666666"
	base_icon = "chair"
	var/propelled = 0 // Check for fire-extinguisher-driven chairs


/obj/structure/bed/chair/New()
	..()
	update_layer()

/obj/structure/bed/chair/Initialize()
	. = ..()
	var/datum/component/buckling/buckle = GetComponent(/datum/component/buckling)
	buckle.buckleFlags &= ~BUCKLE_FORCE_LIE
	buckle.buckleFlags &= BUCKLE_FORCE_STAND

/obj/structure/bed/chair/attackby(obj/item/W as obj, mob/user as mob)
	..()
	if(!padding_material && istype(W, /obj/item/assembly/shock_kit))
		var/obj/item/assembly/shock_kit/SK = W
		if(!SK.status)
			to_chat(user, SPAN_NOTICE("\The [SK] is not ready to be attached!"))
			return
		user.drop_item()
		var/obj/structure/bed/chair/e_chair/E = new (src.loc, material.name)
		playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		E.set_dir(dir)
		E.part = SK
		SK.forceMove(E)
		SK.master = E
		qdel(src)

	else if(istype(W, /obj/item/device/spy_bug))
		user.drop_item()
		W.forceMove(get_turf(src))

/obj/structure/bed/chair/attack_tk(mob/user as mob)
	rotate()
	return
/*
/obj/structure/bed/chair/post_buckle_mob()
	update_icon()
*/

/obj/structure/bed/chair/update_icon()
	..()
	var/datum/component/buckling/buckle = GetComponent(/datum/component/buckling)

/*
	var/cache_key = "[base_icon]-[material.name]-over"
	if(isnull(stool_cache[cache_key]))
		var/image/I = image('icons/obj/furniture.dmi', "[base_icon]_over")
		I.color = material.icon_colour
		I.layer = FLY_LAYER
		stool_cache[cache_key] = I
	overlays |= stool_cache[cache_key]
*/
	// Padding overlay.
	if(padding_material)
		var/padding_cache_key = "[base_icon]-padding-[padding_material.name]-over"
		if(isnull(stool_cache[padding_cache_key]))
			var/image/I =  image(icon, "[base_icon]_padding_over")
			I.color = padding_material.icon_colour
			I.layer = FLY_LAYER
			stool_cache[padding_cache_key] = I
		overlays |= stool_cache[padding_cache_key]

	if(buckle.buckled && padding_material)
		var/cache_key = "[base_icon]-armrest-[padding_material.name]"
		if(isnull(stool_cache[cache_key]))
			var/image/I = image(icon, "[base_icon]_armrest")
			I.layer = ABOVE_MOB_LAYER
			I.color = padding_material.icon_colour
			stool_cache[cache_key] = I
		overlays |= stool_cache[cache_key]

/obj/structure/bed/chair/proc/update_layer()
	if(src.dir == NORTH)
		layer = ABOVE_MOB_LAYER
	else
		layer = OBJ_LAYER

/obj/structure/bed/chair/set_dir()
	..()
	update_layer()

/obj/structure/bed/chair/verb/rotate()
	set name = "Rotate Chair"
	set category = "Object"
	set src in oview(1)

	if(config.ghost_interaction)
		src.set_dir(turn(src.dir, 90))

		return

	else
		if(ismouse(usr))
			return
		if(!usr || !isturf(usr.loc))
			return
		if(usr.stat || usr.restrained())
			return

		src.set_dir(turn(src.dir, 90))
		playsound(src,'sound/effects/CREAK_Wood_Tree_Creak_10_Bright_Very_Subtle_mono.ogg',100,1)
		return

/obj/structure/bed/chair/shuttle
	name = "chair"
	desc = "You sit in this. Either by will or force."
	icon_state = "shuttle_chair"
	color = null
	base_icon = "shuttle_chair"
	applies_material_colour = 0

// Leaving this in for the sake of compilation.
/obj/structure/bed/chair/comfy
	desc = "A chair. It looks comfy."
	icon_state = "comfychair_preview"

/obj/structure/bed/chair/comfy/brown/New(var/newloc,var/newmaterial)
	..(newloc,MATERIAL_STEEL, MATERIAL_LEATHER)

/obj/structure/bed/chair/comfy/red/New(var/newloc,var/newmaterial)
	..(newloc,MATERIAL_STEEL, MATERIAL_CARPET)

/obj/structure/bed/chair/comfy/teal/New(var/newloc,var/newmaterial)
	..(newloc,MATERIAL_STEEL,"teal")

/obj/structure/bed/chair/comfy/black/New(var/newloc,var/newmaterial)
	..(newloc,MATERIAL_STEEL,"black")

/obj/structure/bed/chair/comfy/green/New(var/newloc,var/newmaterial)
	..(newloc,MATERIAL_STEEL,"green")

/obj/structure/bed/chair/comfy/purp/New(var/newloc,var/newmaterial)
	..(newloc,MATERIAL_STEEL,"purple")

/obj/structure/bed/chair/comfy/blue/New(var/newloc,var/newmaterial)
	..(newloc,MATERIAL_STEEL,"blue")

/obj/structure/bed/chair/comfy/beige/New(var/newloc,var/newmaterial)
	..(newloc,MATERIAL_STEEL,"beige")

/obj/structure/bed/chair/comfy/lime/New(var/newloc,var/newmaterial)
	..(newloc,MATERIAL_STEEL,"lime")

/obj/structure/bed/chair/office
	anchored = FALSE

/obj/structure/bed/chair/office/update_icon()
	return

/obj/structure/bed/chair/office/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/stack) || istype(W, /obj/item/tool/wirecutters))
		return
	..()
/obj/structure/bed/chair/office/light
	icon_state = "officechair_white"

/obj/structure/bed/chair/office/dark
	icon_state = "officechair_dark"

/obj/structure/bed/chair/office/New()
	..()
	var/image/I = image(icon, "[icon_state]_over")
	I.layer = FLY_LAYER
	overlays += I

// Chair types

//This should be removed and need replace all wooden chairs with custom wooden type (at map)
//Don't want to broke something. Clock will do it, cause he's working with the map
//from here
/obj/structure/bed/chair/wood
	name = "wooden chair"
	desc = "Old is never too old to not be in fashion."
	icon_state = "wooden_chair"
	applies_material_colour = 0

/obj/structure/bed/chair/wood/update_icon()
	return

/obj/structure/bed/chair/wood/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/stack) || istype(W, /obj/item/tool/wirecutters))
		return
	..()

/obj/structure/bed/chair/wood/New(var/newloc)
	..(newloc, MATERIAL_WOOD)
	var/image/I = image(icon, "[icon_state]_over")
	I.layer = FLY_LAYER
	overlays += I

/obj/structure/bed/chair/wood/wings
	icon_state = "wooden_chair_wings"

//to here


/obj/structure/bed/chair/custom
	applies_material_colour = 0

/obj/structure/bed/chair/custom/update_icon()
	return

/obj/structure/bed/chair/custom/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/stack) || istype(W, /obj/item/tool/wirecutters))
		return
	..()

/obj/structure/bed/chair/custom/New(var/newloc)
	. = ..()
	var/image/I = image(icon, "[icon_state]_over")
	I.layer = FLY_LAYER
	overlays += I


//wooden
/obj/structure/bed/chair/custom/wood
	name = "wooden chair"
	desc = "Old is never too old to not be in fashion."
	icon_state = "wooden_chair"

/obj/structure/bed/chair/custom/wood/New(var/newloc)
	..(newloc, MATERIAL_WOOD)


/obj/structure/bed/chair/custom/wood/wings
	icon_state = "wooden_chair_wings"


//modern
/obj/structure/bed/chair/custom/bar_special
	name = "bar chair"
	desc = "Modern design and soft pad. Served up with the drink and great company."
	icon_state = "bar_chair"

//onestar
/obj/structure/bed/chair/custom/onestar
	name = "onestar chair"
	desc = "A duranium chair manufactured by OneStar. Doesn't look very comfortable."
	icon_state = "onestar_chair_grey"

/obj/structure/bed/chair/custom/onestar/red
	icon_state = "onestar_chair_red"
