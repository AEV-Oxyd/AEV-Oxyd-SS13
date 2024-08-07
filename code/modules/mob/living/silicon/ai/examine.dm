/mob/living/silicon/ai/examine(mob/user)

	var/msg = ""
	if (src.stat == DEAD)
		msg += "<span class='deadsay'>It appears to be powered-down.</span>\n"
	else
		msg += "<span class='warning'>"
		if (src.getBruteLoss())
			if (src.getBruteLoss() < 30)
				msg += "It looks slightly dented.\n"
			else
				msg += "<B>It looks severely dented!</B>\n"
		if (src.getFireLoss())
			if (src.getFireLoss() < 30)
				msg += "It looks slightly charred.\n"
			else
				msg += "<B>Its casing is melted and heat-warped!</B>\n"
		if (src.getOxyLoss() && (aiRestorePowerRoutine != 0 && !APU_power))
			if (src.getOxyLoss() > 175)
				msg += "<B>It seems to be running on backup power. Its display is blinking a \"BACKUP POWER CRITICAL\" warning.</B>\n"
			else if(src.getOxyLoss() > 100)
				msg += "<B>It seems to be running on backup power. Its display is blinking a \"BACKUP POWER LOW\" warning.</B>\n"
			else
				msg += "It seems to be running on backup power.\n"

		if (src.stat == UNCONSCIOUS)
			msg += "It is non-responsive and displaying the text: \"RUNTIME: Sensory Overload, stack 26/3\".\n"
		msg += "</span>"
	if(hardware && (hardware.owner == src))
		msg += "<br>"
		msg += hardware.get_examine_desc()
	if(ishuman(user))
		var/mob/living/carbon/human/humie = user
		if(humie.hasCyberFlag(CSF_LORE_COMMON_KNOWLEDGE) && commonLore)
			msg += SPAN_NOTICE("\n  Knowledge addendum - Common : [commonLore]")
	..(user, afterDesc = msg)
	user.showLaws(src)
	return

/mob/proc/showLaws(var/mob/living/silicon/S)
	return

/mob/observer/ghost/showLaws(var/mob/living/silicon/S)
	if(antagHUD || is_admin(src))
		S.laws.show_laws(src)
