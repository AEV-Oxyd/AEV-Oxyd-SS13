/obj/item/latexballon
	name = "latex glove"
	desc = "A latex glove, now filled with air as an oddly-shaped balloon."
	icon_state = "latexballon"
	item_state = "lgloves"
	throwforce = 0
	volumeClass = ITEM_SIZE_SMALL
	throw_speed = 1
	throw_range = 15
	var/state
	var/datum/gas_mixture/air_contents = null

/obj/item/latexballon/proc/blow(obj/item/tank/tank)
	if (icon_state == "latexballon_bursted")
		return
	src.air_contents = tank.remove_air_volume(3)
	icon_state = "latexballon_blow"
	item_state = "latexballon"

/obj/item/latexballon/proc/burst()
	if (!air_contents)
		return
	playsound(src, 'sound/weapons/Gunshot.ogg', 100, 1)
	icon_state = "latexballon_bursted"
	item_state = "lgloves"
	loc.assume_air(air_contents)

/obj/item/latexballon/take_damage(amount)
	. = ..()
	if(QDELETED(src))
		return 0
	burst()
	return 0

/obj/item/latexballon/bullet_act()
	burst()

/obj/item/latexballon/fire_act(datum/gas_mixture/air, temperature, volume)
	if(temperature > T0C+100)
		burst()
	return

/obj/item/latexballon/attackby(obj/item/W as obj, mob/user as mob)
	if (can_puncture(W))
		burst()
