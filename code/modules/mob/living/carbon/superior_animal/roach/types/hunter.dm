/mob/living/carbon/superior_animal/roach/hunter
	name = "Jager Roach"
	desc = "A monstrous, dog-sized cockroach. This one has bigger claws."
	icon_state = "jager"

	turns_per_move = 3
	maxHealth = 25
	health = 25
	move_to_delay = 2.5

	melee_damage_lower = 4
	melee_damage_upper = 8
	armor_divisor = ARMOR_PEN_DEEP
	wound_mult = WOUNDING_EXTREME

	attacktext = list("slashed", "rended", "diced")

	meat_type = /obj/item/reagent_containers/food/snacks/meat/roachmeat/jager
	meat_amount = 3
	rarity_value = 11.25

	// Armor related variables - jager jacket
	armor = list(
		ARMOR_BLUNT = 5,
		ARMOR_BULLET = 2,
		ARMOR_ENERGY = 2,
		ARMOR_BOMB =0,
		ARMOR_BIO =25,
		ARMOR_RAD =50
	)
