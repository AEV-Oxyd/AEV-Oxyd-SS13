/obj/item/tool/scalpel
	name = "scalpel"
	desc = "Cut, cut, and once more cut."
	icon_state = "scalpel_t3"
	flags = CONDUCT
	melleDamages = list(ARMOR_SLASH = list(DELEM(BRUTE,10)))
	sharp = TRUE
	edge = TRUE
	volumeClass = ITEM_SIZE_TINY
	worksound = WORKSOUND_HARD_SLASH
	slot_flags = SLOT_EARS
	throw_speed = WEAPON_FORCE_WEAK
	origin_tech = list(TECH_MATERIAL = 1, TECH_BIO = 1)
	matter = list(MATERIAL_STEEL = 4)
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	hitsound = 'sound/weapons/melee/lightstab.ogg'
	tool_qualities = list(QUALITY_CUTTING = 30, QUALITY_WIRE_CUTTING = 10)
	spawn_tags = SPAWN_TAG_SURGERY_TOOL

/obj/item/tool/scalpel/advanced
	name = "advanced scalpel"
	desc = "Made of more expensive materials, sharper and generally more reliable."
	icon_state = "scalpel_t4"
	matter = list(MATERIAL_STEEL = 5, MATERIAL_PLASTEEL = 1)
	tool_qualities = list(QUALITY_CUTTING = 40, QUALITY_WIRE_CUTTING = 10)
	degradation = 0.12
	maxUpgrades = 4
	rarity_value = 20

/obj/item/tool/scalpel/laser
	name = "laser scalpel"
	desc = "A scalpel which uses a directed laser to slice instead of a blade, for more precise surgery while also cauterizing as it cuts."
	icon_state = "scalpel_t5"
	melleDamages = list(ARMOR_SLASH = list(DELEM(BURN,16)))
	matter = list(MATERIAL_STEEL = 4, MATERIAL_PLASTIC = 4)
	tool_qualities = list(QUALITY_CUTTING = 40, QUALITY_WIRE_CUTTING = 20, QUALITY_LASER_CUTTING = 40, QUALITY_CAUTERIZING = 20)
	degradation = 0.11
	use_power_cost = 0.12
	suitable_cell = /obj/item/cell/small
	maxUpgrades = 4
	rarity_value = 30

// Laser cutting overrides normal cutting
/obj/item/tool/scalpel/laser/get_tool_type(mob/living/user, list/required_qualities, atom/use_on, datum/callback/CB)
	if(QUALITY_LASER_CUTTING in required_qualities)
		required_qualities -= QUALITY_CUTTING
	return ..(user, required_qualities, use_on, CB)
