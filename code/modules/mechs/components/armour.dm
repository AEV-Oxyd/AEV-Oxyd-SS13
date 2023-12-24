/*
/datum/extension/armor/exosuit/apply_damage_modifications(damage, damage_type, damage_flags, mob/living/victim, armor_pen, silent = TRUE)
	if(prob(get_blocked(damage_type, damage_flags, armor_pen) * 100)) //extra removal of sharp and edge on account of us being big robots
		damage_flags &= ~(DAM_SHARP | DAM_EDGE)
	. = ..()
*/

/obj/item/robot_parts/robot_component/armour/exosuit
	name = "exosuit armor plating"
	armor = list(ARMOR_BLUNT = 20, ARMOR_BULLET = 8, ARMOR_ENERGY = 2, ARMOR_BOMB =100, ARMOR_BIO =100, ARMOR_RAD =0)
	origin_tech = list(TECH_MATERIAL = 1)
	matter = list(MATERIAL_STEEL = 7)
	spawn_tags = SPAWN_TAG_MECH_QUIPMENT
	rarity_value = 10
	spawn_blacklisted = TRUE

/obj/item/robot_parts/robot_component/armour/exosuit/Initialize(newloc)
	. = ..()
	// HACK
	// All robot components add "robot" to the name on init - remove that on exosuit armor
	name = initial(name)

/obj/item/robot_parts/robot_component/armour/exosuit/plain
	name = "standard exosuit plating"
	desc = "A sturdy hunk of steel and plasteel plating, offers decent protection from physical harm and environmental hazards whilst being cheap to produce."
	armor = list(ARMOR_BLUNT = 20, ARMOR_BULLET = 10, ARMOR_ENERGY = 9, ARMOR_BOMB =125, ARMOR_BIO =100, ARMOR_RAD =100)
	origin_tech = list(TECH_MATERIAL = 3)
	matter = list(MATERIAL_STEEL = 15, MATERIAL_PLASTEEL = 10) //Plasteel for the shielding
	spawn_blacklisted = FALSE
	price_tag = 400

/obj/item/robot_parts/robot_component/armour/exosuit/ablative
	name = "ablative exosuit armor plating"
	desc = "This plating is built to shrug off laser impacts and block electromagnetic pulses, but is rather vulnerable to brute trauma."
	armor = list(ARMOR_BLUNT = 15, ARMOR_BULLET = 6, ARMOR_ENERGY = 38, ARMOR_BOMB =50, ARMOR_BIO =100, ARMOR_RAD =50)
	origin_tech = list(TECH_MATERIAL = 3)
	matter = list(MATERIAL_STEEL = 15, MATERIAL_PLASMA = 5)
	spawn_blacklisted = FALSE
	price_tag = 550

/obj/item/robot_parts/robot_component/armour/exosuit/combat
	name = "heavy combat exosuit plating"
	desc = "Plating designed to deflect incoming attacks and explosions."
	armor = list(ARMOR_BLUNT = 24, ARMOR_BULLET = 24, ARMOR_ENERGY = 16, ARMOR_BOMB =300, ARMOR_BIO =100, ARMOR_RAD =50)
	origin_tech = list(TECH_MATERIAL = 5)
	matter = list(MATERIAL_STEEL = 20, MATERIAL_DIAMOND = 5, MATERIAL_URANIUM = 5)
	spawn_blacklisted = FALSE
	price_tag = 1000
