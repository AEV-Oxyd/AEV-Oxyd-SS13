
//Knifes
/obj/item/tool/knife
	name = "kitchen knife"
	desc = "A general purpose Chef's Knife made by Asters Merchant Guild. Guaranteed to stay sharp for years to come."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "knife"
	description_info = "Could be attached to a gun"
	flags = CONDUCT
	sharp = TRUE
	edge = TRUE
	worksound = WORKSOUND_HARD_SLASH
	volumeClass = ITEM_SIZE_SMALL //2
	melleDamages = list(ARMOR_SHARP = list(DELEM(BRUTE,25)))
	throwforce = WEAPON_FORCE_WEAK
	armor_divisor = ARMOR_PEN_SHALLOW
	maxUpgrades = 2
	tool_qualities = list(QUALITY_CUTTING = 20,  QUALITY_WIRE_CUTTING = 10, QUALITY_SCREW_DRIVING = 5)
	matter = list(MATERIAL_STEEL = 3, MATERIAL_PLASTIC = 1)
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	hitsound = 'sound/weapons/melee/lightstab.ogg'
	slot_flags = SLOT_BELT
	structure_damage_factor = STRUCTURE_DAMAGE_BLADE

	//spawn values
	rarity_value = 10
	spawn_tags = SPAWN_TAG_KNIFE

/obj/item/tool/knife/New()
	..()
	var/datum/component/item_upgrade/I = AddComponent(/datum/component/item_upgrade)
	I.weapon_upgrades = list(
		GUN_UPGRADE_BAYONET = TRUE,
		GUN_UPGRADE_MELEEDAMAGE = 5,
		GUN_UPGRADE_MELEEPENETRATION = ARMOR_PEN_MODERATE,
		GUN_UPGRADE_OFFSET = 4
		)
	I.gun_loc_tag = GUN_UNDERBARREL
	I.req_gun_tags = list(SLOT_BAYONET)

/obj/item/tool/knife/boot
	name = "boot knife"
	desc = "A small fixed-blade knife for putting inside a boot."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "tacknife"
	item_state = "knife"
	matter = list(MATERIAL_PLASTEEL = 2, MATERIAL_PLASTIC = 1)
	melleDamages = list(ARMOR_SHARP = list(DELEM(BRUTE,25)))
	tool_qualities = list(QUALITY_CUTTING = 20,  QUALITY_WIRE_CUTTING = 10, QUALITY_SCREW_DRIVING = 15)
	rarity_value = 20

/obj/item/tool/knife/hook
	name = "meat hook"
	desc = "A sharp, metal hook what sticks into things."
	icon_state = "hook_knife"
	item_state = "hook_knife"
	matter = list(MATERIAL_PLASTEEL = 5, MATERIAL_PLASTIC = 2)
	melleDamages = list(ARMOR_POINTY = list(DELEM(BRUTE,10)))
	armor_divisor = ARMOR_PEN_HALF //Should be countered be embedding
	embed_mult = 1.5 //This is designed for embedding
	rarity_value = 5

/obj/item/tool/knife/ritual
	name = "ritual knife"
	desc = "The unearthly energies that once powered this blade are now dormant."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "render"
	rarity_value = 20

/obj/item/tool/knife/butch
	name = "butcher's cleaver"
	icon_state = "butch"
	desc = "A huge thing used for chopping and chopping up meat. This includes roaches and roach-by-products."
	melleDamages = list(ARMOR_SHARP = list(DELEM(BRUTE,30)))
	throwforce = WEAPON_FORCE_NORMAL
	attack_verb = list("cleaved", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	matter = list(MATERIAL_STEEL = 5, MATERIAL_PLASTIC = 1)
	tool_qualities = list(QUALITY_CUTTING = 20,  QUALITY_WIRE_CUTTING = 15)
	rarity_value = 5

/obj/item/tool/knife/neotritual
	name = "NeoTheology ritual knife"
	desc = "The sweet embrace of mercy, for relieving the soul from a tortured vessel."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "neot-knife"
	item_state = "knife"
	matter = list(MATERIAL_PLASTEEL = 4, MATERIAL_PLASTIC = 1)
	embed_mult = 6
	maxUpgrades = 3
	spawn_blacklisted = TRUE

/obj/item/tool/knife/neotritual/equipped(mob/living/H)
	. = ..()
	if(is_held() && is_neotheology_disciple(H))
		embed_mult = 0.05
	else
		embed_mult = initial(embed_mult)

/obj/item/tool/knife/tacknife
	name = "tactical knife"
	desc = "You'd be killing loads of people if this was Medal of Valor: Heroes of Space. Could be attached to a gun."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "tacknife_guard"
	item_state = "knife"
	matter = list(MATERIAL_PLASTEEL = 3, MATERIAL_PLASTIC = 2)
	embed_mult = 0.6
	maxUpgrades = 3

/obj/item/tool/knife/dagger
	name = "dagger"
	desc = "A sharp implement; difference between this and a knife is it is sharp on both sides. Good for finding holes in armor and exploiting them."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "dagger"
	item_state = "dagger"
	matter = list(MATERIAL_PLASTEEL = 3, MATERIAL_PLASTIC = 2)
	melleDamages = list(ARMOR_POINTY = list(DELEM(BRUTE,25)))
	rarity_value = 15

/obj/item/tool/knife/dagger/ceremonial
	name = "ceremonial dagger"
	desc = "Given to high ranking officers during their time in the stellar navy. A practical showing of accomplishment."
	icon_state = "fancydagger"
	item_state = "fancydagger"
	matter = list(MATERIAL_PLASTEEL = 3, MATERIAL_PLASTIC = 2, MATERIAL_GOLD = 1, MATERIAL_SILVER = 1)
	embed_mult = 0.6
	maxUpgrades = 4
	spawn_blacklisted = TRUE

/obj/item/tool/knife/dagger/bluespace
	name = "Moebius \"Displacement Dagger\""
	desc = "A teleportation matrix attached to a dagger, for sending things you stab it into very far away."
	icon_state = "bluespace_dagger"
	item_state = "bluespace_dagger"
	matter = list(MATERIAL_PLASTEEL = 3, MATERIAL_PLASTIC = 2, MATERIAL_SILVER = 10, MATERIAL_GOLD = 5, MATERIAL_PLASMA = 20)
	embed_mult = 50 //You WANT it to embed
	suitable_cell = /obj/item/cell/small
	toggleable = TRUE
	use_power_cost = 0.4
	passive_power_cost = 0.4
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 2, TECH_BLUESPACE = 4)
	spawn_blacklisted = TRUE
	price_tag = 400
	var/mob/living/embedded
	var/last_teleport
	var/entropy_value = 3

/obj/item/tool/knife/dagger/bluespace/on_embed(mob/user)
	embedded = user

/obj/item/tool/knife/dagger/bluespace/on_embed_removal(mob/user)
	embedded = null

/obj/item/tool/knife/dagger/bluespace/Process()
	..()
	if(switched_on && embedded && cell)
		if(last_teleport + max(3 SECONDS, embedded.mob_size*(cell.charge/cell.maxcharge)) < world.time)
			var/area/A = random_ship_area()
			var/turf/T = A.random_space()
			if(T && cell.checked_use(use_power_cost*embedded.mob_size))
				last_teleport = world.time
				playsound(T, "sparks", 50, 1)
				anim(T,embedded,'icons/mob/mob.dmi',,"phaseout",,embedded.dir)
				go_to_bluespace(get_turf(embedded), entropy_value, TRUE, embedded, T)
				anim(T,embedded,'icons/mob/mob.dmi',,"phasein",,embedded.dir)

/obj/item/tool/knife/dagger/assassin
	name = "dagger"
	desc = "A sharp implement, with a twist; The handle acts as a reservoir for reagents, and the blade injects those that it hits."
	icon_state = "assdagger"
	item_state = "ass_dagger"
	reagent_flags = INJECTABLE|TRANSPARENT
	matter = list(MATERIAL_PLASTEEL = 4, MATERIAL_DIAMOND = 2)
	spawn_blacklisted = TRUE

/obj/item/tool/knife/dagger/assassin/New()
	..()
	create_reagents(80)

/obj/item/tool/knife/dagger/assassin/resolve_attackby(atom/target, mob/user)
	.=..()
	if(!target.reagents || !isliving(target))
		return

	if(!reagents.total_volume)
		return

	if(!target.reagents.get_free_space())
		return
	var/modifier = 1
	var/reagent_modifier = 1
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		modifier += min(30,H.stats.getStat(STAT_ROB))
		reagent_modifier = CLAMP(round(H.stats.getStat(STAT_BIO)/10), 1, 5)
	var/mob/living/L = target
	if(prob(min(100,(100-L.getarmor(user.targeted_organ, ARMOR_SLASH))+modifier)))
		var/trans = reagents.trans_to_mob(target, rand(1,3)*reagent_modifier, CHEM_BLOOD)
		admin_inject_log(user, target, src, reagents.log_list(), trans)
		to_chat(user, SPAN_NOTICE("You inject [trans] units of the solution. [src] now contains [src.reagents.total_volume] units."))

/obj/item/tool/knife/butterfly
	name = "butterfly knife"
	desc = "A basic metal blade concealed in a lightweight plasteel grip. Small enough when folded to fit in a pocket."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "butterflyknife"
	item_state = "butterflyknife"
	flags = CONDUCT
	edge = FALSE
	sharp = FALSE
	melleDamages = list(ARMOR_BLUNT = list(DELEM(BRUTE,5)))
	switchedOn = list(ARMOR_SHARP = list(DELEM(BRUTE,15)))
	matter = list(MATERIAL_PLASTEEL = 4, MATERIAL_STEEL = 6)
	switched_on_qualities = list(QUALITY_CUTTING = 20, QUALITY_WIRE_CUTTING = 10, QUALITY_SCREW_DRIVING = 5)
	volumeClass = ITEM_SIZE_TINY
	var/switched_on_volumeClass = ITEM_SIZE_SMALL
	tool_qualities = list()
	toggleable = TRUE
	rarity_value = 25
	spawn_tags = SPAWN_TAG_KNIFE_CONTRABAND

/obj/item/tool/knife/butterfly/turn_on(mob/user)
	item_state = "[initial(item_state)]_on"
	to_chat(user, SPAN_NOTICE("You flip out [src]."))
	playsound(user, 'sound/weapons/flipblade.ogg', 15, 1)
	edge = TRUE
	sharp = TRUE
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	switched_on = TRUE
	tool_qualities = switched_on_qualities
	volumeClass = switched_on_volumeClass
	if (!isnull(switchedOn))
		melleDamages = list(ARMOR_SHARP = list(DELEM(BRUTE,15)))
	update_icon()
	update_wear_icon()

/obj/item/tool/knife/butterfly/turn_off(mob/user)
	hitsound = initial(hitsound)
	icon_state = initial(icon_state)
	item_state = initial(item_state)
	attack_verb = list("punched","cracked")
	playsound(user, 'sound/weapons/flipblade.ogg', 15, 1)
	to_chat(user, SPAN_NOTICE("You flip [src] back into the handle gracefully."))
	switched_on = FALSE
	tool_qualities = switched_off_qualities
	melleDamages = list(ARMOR_BLUNT = list(DELEM(BRUTE,5)))
	volumeClass = initial(volumeClass)
	update_icon()
	update_wear_icon()

/obj/item/tool/knife/switchblade
	name = "switchblade"
	desc = "A classic switchblade with gold engraving. Just holding it makes you feel like a gangster."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "switchblade"
	item_state = "switchblade"
	flags = CONDUCT
	edge = FALSE
	sharp = FALSE
	volumeClass = ITEM_SIZE_TINY
	var/switched_on_volumeClass = ITEM_SIZE_SMALL
	matter = list(MATERIAL_PLASTEEL = 4, MATERIAL_STEEL = 6, MATERIAL_GOLD= 0.5)
	switched_on_qualities = list(QUALITY_CUTTING = 20, QUALITY_WIRE_CUTTING = 10, QUALITY_SCREW_DRIVING = 5)
	tool_qualities = list()
	toggleable = TRUE
	rarity_value = 30
	spawn_tags = SPAWN_TAG_KNIFE_CONTRABAND

/obj/item/tool/knife/switchblade/turn_on(mob/user)
	item_state = "[initial(item_state)]_on"
	to_chat(user, SPAN_NOTICE("You press a button on the handle and [src] slides out."))
	playsound(user, 'sound/weapons/flipblade.ogg', 15, 1)
	edge = TRUE
	sharp = TRUE
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	switched_on = TRUE
	tool_qualities = switched_on_qualities
	melleDamages = switchedOn.Copy()
	volumeClass = switched_on_volumeClass
	update_icon()
	update_wear_icon()

/obj/item/tool/knife/switchblade/turn_off(mob/user)
	hitsound = initial(hitsound)
	icon_state = initial(icon_state)
	item_state = initial(item_state)
	attack_verb = list("punched","cracked")
	playsound(user, 'sound/weapons/flipblade.ogg', 15, 1)
	to_chat(user, SPAN_NOTICE("You press the button and [src] swiftly retracts."))
	switched_on = FALSE
	tool_qualities = switched_off_qualities
	melleDamages = list(ARMOR_BLUNT = list(DELEM(BRUTE,5)))
	volumeClass = initial(volumeClass)
	update_icon()
	update_wear_icon()

//A makeshift knife, for doing all manner of cutting and stabbing tasks in a half-assed manner
/obj/item/tool/knife/shiv
	name = "shiv"
	desc = "A pointy piece of glass, abraded to an edge and wrapped in tape for a handle. Could become a decent tool or weapon with right tool mods."
	icon = 'icons/obj/tools.dmi'
	icon_state = "impro_shiv"
	item_state = "shiv"
	worksound = WORKSOUND_HARD_SLASH
	matter = list(MATERIAL_GLASS = 1)
	sharp = TRUE
	edge = TRUE
	melleDamages = list(ARMOR_POINTY = list(DELEM(BRUTE,18)))
	volumeClass = ITEM_SIZE_TINY
	slot_flags = SLOT_EARS
	tool_qualities = list(QUALITY_CUTTING = 15, QUALITY_WIRE_CUTTING = 5, QUALITY_DRILLING = 5)
	degradation = 4 //Gets worse with use
	maxUpgrades = 5 //all makeshift tools get more mods to make them actually viable for mid-late game
	spawn_tags = SPAWN_TAG_JUNKTOOL

/obj/item/tool/spear
	name = "glass spear"
	desc = "A piece of glass tied using cable coil onto two welded rods. Impressive work."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "spear_glass"
	item_state = "spear_glass"
	wielded_icon = "spear_glass_wielded"
	flags = CONDUCT
	sharp = TRUE
	edge = TRUE
	extended_reach = TRUE
	push_attack = TRUE
	worksound = WORKSOUND_HARD_SLASH
	volumeClass = ITEM_SIZE_BULKY //4 , it's a spear mate
	melleDamages = list(ARMOR_POINTY = list(DELEM(BRUTE,18)))
	WieldedattackDelay = 8
	attackDelay = 4
	throwforce = WEAPON_FORCE_DANGEROUS
	armor_divisor = ARMOR_PEN_MODERATE
	throw_speed = 3
	maxUpgrades = 5
	tool_qualities = list(QUALITY_CUTTING = 10,  QUALITY_WIRE_CUTTING = 5, QUALITY_SCREW_DRIVING = 1)
	matter = list(MATERIAL_STEEL = 1, MATERIAL_GLASS = 1)
	attack_verb = list("slashed", "stabbed") //there's not much you can do with a spear aside from stabbing and slashing with it
	hitsound = 'sound/weapons/melee/heavystab.ogg'
	slot_flags = SLOT_BACK
	structure_damage_factor = STRUCTURE_DAMAGE_BLADE
	allow_spin = FALSE
	rarity_value = 20
	spawn_tags = SPAWN_TAG_KNIFE

/obj/item/tool/spear/steel
	name = "steel spear"
	desc = "A steel spearhead welded to a crude metal shaft, made from two welded rods. It'll serve well enough."
	icon_state = "spear_steel"
	item_state = "spear_steel"
	wielded_icon = "spear_steel_wielded"
	melleDamages = list(ARMOR_POINTY = list(DELEM(BRUTE,24)))
	throwforce = WEAPON_FORCE_ROBUST
	tool_qualities = list(QUALITY_CUTTING = 10,  QUALITY_WIRE_CUTTING = 5, QUALITY_SCREW_DRIVING = 5)
	matter = list(MATERIAL_STEEL = 3)
	structure_damage_factor = STRUCTURE_DAMAGE_WEAK

	rarity_value = 60

/obj/item/tool/spear/plasteel
	name = "plasteel spear"
	desc = "A carefully crafted plasteel spearhead affixed to a metal shaft, it is welded securely on and feels balanced. Show them the past still lives."
	icon_state = "spear_plasteel"
	item_state = "spear_plasteel"
	wielded_icon = "spear_plasteel_wielded"
	melleDamages = list(ARMOR_POINTY = list(DELEM(BRUTE,30)))
	throwforce = WEAPON_FORCE_BRUTAL
	tool_qualities = list(QUALITY_CUTTING = 15,  QUALITY_WIRE_CUTTING = 10, QUALITY_SCREW_DRIVING = 10)
	matter = list(MATERIAL_STEEL = 1, MATERIAL_PLASTEEL = 2)
	structure_damage_factor = STRUCTURE_DAMAGE_NORMAL

/obj/item/tool/spear/uranium
	name = "uranium spear"
	desc = "A steel spear with a uranium lined spearhead. Your foes may survive the stab, but the toxin will linger."
	icon_state = "spear_uranium"
	item_state = "spear_uranium"
	wielded_icon = "spear_uranium_wielded"
	throwforce = WEAPON_FORCE_DANGEROUS
	tool_qualities = list(QUALITY_CUTTING = 10,  QUALITY_WIRE_CUTTING = 5, QUALITY_SCREW_DRIVING = 5)
	matter = list(MATERIAL_STEEL = 3, MATERIAL_URANIUM = 1)

/obj/item/tool/spear/uranium/apply_hit_effect(mob/living/carbon/human/target, mob/living/user, hit_zone)
	..()
	if(istype(target))
		target.apply_effect(rand(60, 65), IRRADIATE)

/obj/item/tool/spear/makeshift_halberd
	name = "makeshift halberd"
	desc = "Slap a heavy blade on some rods duct-taped together and call it a day."
	icon_state = "makeshift_halberd"
	item_state = "makeshift_halberd"
	wielded_icon = "makeshift_halberd_wielded"
	melleDamages = list(ARMOR_POINTY = list(DELEM(BRUTE,25)))
	throwforce = WEAPON_FORCE_NORMAL
	armor_divisor = ARMOR_PEN_SHALLOW
	tool_qualities = list(QUALITY_CUTTING = 10)
	matter = list(MATERIAL_STEEL = 5)
	forced_broad_strike = TRUE
	rarity_value = 90
	degradation = 3
