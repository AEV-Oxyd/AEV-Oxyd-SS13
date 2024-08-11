/// Pixels per turf
#define PPT 32
#define HPPT (PPT/2)
/// the higher you go the higher you risk trajectories becoming wobbly and inaccurate.
/// 16 is the absolute lowest which guarantees maximum accuracy.
/// 20 is a safe bet between 24 and 16
/// the higher this is ,the more performant the system is , since more of the math is done at once instead of in stages
/// it is also more inaccurate the higher you go..
#define MAXPIXELS 16
/// Define this / uncomment it if you want to see bullet debugging data for trajectories & chosen paths.
//#define BULLETDEBUG 1
SUBSYSTEM_DEF(bullets)
	name = "Bullets"
	wait = 1
	priority = SS_PRIORITY_BULLETS
	init_order = INIT_ORDER_BULLETS

	var/list/datum/bullet_data/current_queue = list()
	var/list/datum/bullet_data/bullet_queue = list()

/// You might ask why use a bullet data datum, and not store all the vars on the bullet itself, honestly its to keep track and initialize firing relevant vars only when needed
/// This data is guaranteed to be of temporary use spanning 15-30 seconds or how long the bullet moves for. Putting them on the bullet makes each one take up more ram
/// And ram is not a worry , but its better to initialize less and do the lifting on fire.
/datum/bullet_data
	var/obj/item/projectile/referencedBullet = null
	var/atom/firer
	var/aimedZone = ""
	var/globalX = 0
	var/globalY = 0
	var/globalZ = 0
	var/originalX = 0
	var/originalY = 0
	var/originalZ = 0
	var/targetX = 0
	var/targetY = 0
	var/targetZ = 0
	var/pixelSpeed = 0
	var/ratioX = 0
	var/ratioY = 0
	var/angle = 0
	var/lifetime = 30
	var/traveledPixels = 0
	var/distanceToTarget = 0
	var/list/cannotHit = list()

/datum/bullet_data/New(obj/item/projectile/referencedBullet, aimedZone, atom/firer, list/currentCoordinates, list/targetCoordinates, pixelsPerTick, angleOffset, lifetime)
	referencedBullet.dataRef = src
	src.referencedBullet = referencedBullet
	src.aimedZone = aimedZone
	src.lifetime = lifetime
	src.firer = firer
	pixelSpeed = pixelsPerTick
	globalX = currentCoordinates[1]
	globalY = currentCoordinates[2]
	globalZ = currentCoordinates[3]
	originalX = globalX
	originalY = globalY
	originalZ = globalZ
	targetX = targetCoordinates[1]
	targetY = targetCoordinates[2]
	targetZ = targetCoordinates[3]
	angle = getAngleByPosition()
	angle += angleOffset
	distanceToTarget = distStartToFinish2D()
	updatePathByAngle()
	SSbullets.bullet_queue.Add(src)

/datum/bullet_data/proc/redirect(currentX, currentY, currentZ, targetX, targetY, targetZ)
	globalX = currentX
	globalY = currentY
	globalZ = currentZ
	src.targetX = targetX
	src.targetY = targetY
	src.targetZ = targetZ
	angle = getAngleByPosition()
	updatePathByPosition()

/datum/bullet_data/proc/bounce(bounceAxis, angleOffset)
	switch(bounceAxis)
		if(1)
			ratioX *= -1
		if(2)
			ratioY *= -1
	angle = arctan(ratioY, ratioX) + angleOffset
	updatePathByAngle()

/datum/bullet_data/proc/getAngleByPosition()
	return ATAN2(targetY - originalY, targetX - originalX)

/datum/bullet_data/proc/updatePathByAngle()
	var/matrix/rotation = matrix()
	ratioX = sin(angle)
	ratioY = cos(angle)
	rotation.Turn(angle + 180)
	referencedBullet.transform = rotation

/datum/bullet_data/proc/updatePathByPosition()
	var/matrix/rotation = matrix()
	angle = getAngleByPosition()
	ratioX = sin(angle)
	ratioY = cos(angle)
	rotation.Turn(angle + 180)
	referencedBullet.transform = rotation

/datum/bullet_data/proc/distStartToFinish2D()
	return DIST_EUCLIDIAN_2D(targetX,targetY,originalX,originalY)

/datum/controller/subsystem/bullets/proc/reset()
	current_queue = list()
	bullet_queue = list()

/datum/controller/subsystem/bullets/fire(resumed)
	/// processing variables
	var/turf/movementTurf
	var/turf/currentTurf
	var/currentX
	var/currentY
	var/currentZ
	var/pixelTotal
	var/pixelStep
	var/bulletDir
	var/stepX
	var/stepY
	var/stepZ
	var/obj/item/projectile/projectile
	var/canContinue
	current_queue = bullet_queue.Copy()
	if(!resumed)
		current_queue = bullet_queue.Copy()
	#ifdef BULLETDEBUG
	var/list/colored = list()
	#endif
	for(var/datum/bullet_data/dataReference in current_queue)
		current_queue.Remove(dataReference)
		projectile = dataReference.referencedBullet
		if(QDELETED(projectile))
			bullet_queue.Remove(dataReference)
			continue
		currentX = dataReference.globalX
		currentY = dataReference.globalY
		currentZ = dataReference.globalZ
		bulletDir = (EAST*(dataReference.ratioX>0)) | (WEST*(dataReference.ratioX<0)) | (NORTH*(dataReference.ratioY>0)) | (SOUTH*(dataReference.ratioY<0))
		pixelTotal = dataReference.pixelSpeed
		dataReference.lifetime--
		while(pixelTotal > 0)
			pixelStep = min(pixelTotal, MAXPIXELS)
			pixelTotal -= pixelStep
			dataReference.traveledPixels += pixelStep
			stepX = dataReference.ratioX * pixelStep
			stepY = dataReference.ratioY * pixelStep
			stepZ = LERP(dataReference.originalZ, dataReference.targetZ, dataReference.traveledPixels/dataReference.distanceToTarget) - dataReference.globalZ
			currentTurf = get_turf(projectile)
			//message_admins("Z : [dataReference.globalZ] with step [stepZ] , Ratio : [dataReference.traveledPixels/dataReference.distanceToTarget]")
			movementTurf = locate(round((currentX+stepX)/PPT),round((currentY+stepY)/PPT),round((currentZ+stepZ)/PPT))
			if(!movementTurf)
				dataReference.lifetime = 0
				break

			//message_admins("X: [movementTurf.x] Y:[movementTurf.y] Z:[movementTurf.z]")
			if(movementTurf == currentTurf)
				canContinue = projectile.scanTurf(currentTurf, bulletDir, currentX, currentY, currentZ, &stepX, &stepY, &stepZ)
				if(canContinue == PROJECTILE_CONTINUE)
					dataReference.globalX += stepX
					dataReference.globalY += stepY
					dataReference.globalZ += stepZ
				else
					dataReference.globalX = stepX
					dataReference.globalY = stepY
					#ifdef BULLETDEBUG
					currentTurf.color = COLOR_RED
					message_admins(" 1 New turf, X:[round(dataReference.globalX/32)] | Y:[round(dataReference.globalY/32)] | Z:[round(dataReference.globalZ/32)]")
					#endif
					if(movementTurf != currentTurf && movementTurf)
						projectile.pixel_x -= (movementTurf.x - currentTurf.x) * PPT
						projectile.pixel_y -= (movementTurf.y - currentTurf.y) * PPT
						projectile.forceMove(movementTurf)
						#ifdef BULLETDEBUG
						movementTurf.color = COLOR_RED
						colored += movementTurf
						message_admins("Adjusted for Delta")
						#endif
					break
			else
				canContinue = projectile.scanTurf(currentTurf, bulletDir, currentX, currentY, currentZ, &stepX, &stepY, &stepZ)
				if(canContinue == PROJECTILE_CONTINUE)
					canContinue = projectile.scanTurf(movementTurf, bulletDir, currentX, currentY, currentZ, &stepX, &stepY, &stepZ)
					if(canContinue == PROJECTILE_CONTINUE)
						projectile.pixel_x -= (movementTurf.x - currentTurf.x) * PPT
						projectile.pixel_y -= (movementTurf.y - currentTurf.y) * PPT
						dataReference.globalX += stepX
						dataReference.globalY += stepY
						dataReference.globalZ += stepZ
						projectile.forceMove(movementTurf)
						#ifdef BULLETDEBUG
						movementTurf.color = COLOR_GREEN
						colored += movementTurf
						#endif
					else
						dataReference.globalX = stepX
						dataReference.globalY = stepY
						#ifdef BULLETDEBUG
						message_admins(" 2 New turf, X:[round(dataReference.globalX/32)] | Y:[round(dataReference.globalY/32)] | Z:[round(dataReference.globalZ/32)]")
						movementTurf.color = COLOR_RED
						#endif
						movementTurf = locate(round(stepX/PPT), round(stepY/PPT), round(currentZ/PPT))
						if(movementTurf != currentTurf && movementTurf)
							projectile.pixel_x -= (movementTurf.x - currentTurf.x) * PPT
							projectile.pixel_y -= (movementTurf.y - currentTurf.y) * PPT
							projectile.forceMove(movementTurf)
							#ifdef BULLETDEBUG
							movementTurf.color = COLOR_RED
							message_admins("Adjusted for Delta")
							colored += movementTurf
							#endif
						break
				else
					dataReference.globalX = stepX
					dataReference.globalY = stepY
					dataReference.globalZ = stepZ
					movementTurf = locate(round(stepX/PPT), round(stepY/PPT), round(currentZ/PPT))
					#ifdef BULLETDEBUG
					currentTurf.color = COLOR_RED
					message_admins(" 3 New turf, X:[round(dataReference.globalX/32)] | Y:[round(dataReference.globalY/32)] | Z:[round(dataReference.globalZ/32)]")
					#endif
					if(movementTurf != currentTurf && movementTurf)
						projectile.pixel_x -= (movementTurf.x - currentTurf.x) * PPT
						projectile.pixel_y -= (movementTurf.y - currentTurf.y) * PPT
						projectile.forceMove(movementTurf)
						#ifdef BULLETDEBUG
						movementTurf.color = COLOR_RED
						message_admins("Adjusted for Delta")
						colored += movementTurf
						#endif
					break

			//message_admins("stepX:[stepX] , stepY : [stepY]")



			currentX = dataReference.globalX
			currentY = dataReference.globalY
			currentZ = dataReference.globalZ

		var/bulletTime = SSbullets.wait *(dataReference.pixelSpeed / (dataReference.pixelSpeed + pixelTotal))
		/*
		if(canContinue != PROJECTILE_CONTINUE)
			var/a = round((stepX)/32)
			var/b = round((stepY)/32)
			var/c = round(currentZ/32)
			var/turf/turfer = locate(a,b,c)
			var/atom/movable/special = new /obj/item()
			message_admins("stepX:[stepX] , stepY : [stepY]")
			if(movementTurf)
				message_admins("MovTurf ----- X: [movementTurf.x] Y:[movementTurf.y] Z:[movementTurf.z]")
			message_admins("VisTurf ----- X: [a] Y:[b] Z:[c]")
			special.forceMove(turfer)
			special.icon = projectile.icon
			special.icon_state = projectile.icon_state
			special.pixel_x = round((stepX))%32 - 16
			special.pixel_y = round((stepY))%32 - 16
			special.transform = projectile.transform
		*/


		animate(projectile, bulletTime, pixel_x = dataReference.globalX%PPT - HPPT, pixel_y = dataReference.globalY%PPT - HPPT, flags = ANIMATION_END_NOW)
		if(dataReference.lifetime < 1)
			projectile.finishDeletion()
			bullet_queue.Remove(dataReference)

	#ifdef BULLETDEBUG
	if(length(colored))
		addtimer(CALLBACK(src, PROC_REF(deleteColors), colored.Copy()), SSbullets.wait * 15)
	#endif

/datum/controller/subsystem/bullets/proc/deleteColors(list/specialList)
	for(var/turf/tata in specialList)
		tata.color = initial(tata.color)

	/*
	if(!resumed)
		current_queue = bullet_queue.Copy()
	var/global/turf/leaving
	var/global/pixelXdist
	var/global/pixelYdist
	for(var/datum/bullet_data/bullet in current_queue)
		current_queue -= bullet
		bullet.lastChanges[1] = 0
		bullet.lastChanges[2] = 0
		bullet.lastChanges[3] = 0
		if(!istype(bullet.referencedBullet, /obj/item/projectile/bullet) || QDELETED(bullet.referencedBullet))
			bullet_queue -= bullet
			continue
		bulletRatios = bullet.movementRatios
		projectile = bullet.referencedBullet
		pixelsToTravel = bullet.pixelsPerTick
		bulletCoords = bullet.currentCoords
		/// We have to break up the movement into steps if its too big(since it leads to erronous steps) , this is preety much continous collision
		/// but less performant A more performant version would be to use the same algorithm as throwing for determining which turfs to "intersect"
		/// Im using this implementation because im getting skill issued trying to implement the same one as throwing(i had to rewrite this 4 times already)
		/// and also because it has.. much more information about the general trajectory stored  SPCR - 2024
		bulletCoords = bullet.currentCoords
		trajectoryData[1] = projectile.x * 32 + projectile.pixel_x + 16
		trajectoryData[2] = projectile.y * 32 + projectile.pixel_y + 16
		trajectoryData[3] = bulletRatios[1] * pixelsToTravel + trajectoryData[1]
		trajectoryData[4] = bulletRatios[2] * pixelsToTravel + trajectoryData[2]
		trajectoryData[5] = bulletCoords[3]
		/// Yes this is inaccurate for multi-Z  transitions somewhat , if someone wants to create a proper equation for pseudo 3D they're welcome to.
		trajectoryData[6] = trajectoryData[5] + LERP(bullet.firedLevel, bullet.targetLevel,(bullet.traveled + pixelsToTravel)/bullet.distStartToFinish2D()) - (projectile.z - bullet.firedPos[3] * LEVEL_MAX)
		bullet.trajSum += bulletRatios[3] * pixelsToTravel
		forceLoop:
		while(pixelsToTravel > 0)
			pixelsThisStep = pixelsToTravel > MAXPIXELS ? MAXPIXELS : pixelsToTravel
			pixelsToTravel -= pixelsThisStep
			bullet.traveled += pixelsThisStep
			pixelXdist = (bulletRatios[1] * pixelsThisStep)
			pixelYdist = (bulletRatios[2] * pixelsThisStep)
			trajectoryData[7] = (EAST*(pixelXdist>0)) | (WEST*(pixelXdist<0)) | (NORTH*(pixelYdist>0)) | (SOUTH*(pixelYdist<0))
			bulletCoords[1] += pixelXdist
			bulletCoords[2] += pixelYdist
			bulletCoords[3] = LERP(bullet.firedLevel, bullet.targetLevel, bullet.traveled/bullet.distStartToFinish2D()) - (projectile.z - bullet.firedPos[3]) * LEVEL_MAX
			//message_admins(bulletCoords[3])
			//message_admins("added [(bulletRatios[3] * pixelsThisStep)]  , pixels [pixelsThisStep] , curSum [bulletCoords[3]]")
			x_change = trunc(bulletCoords[1] / HPPT)
			y_change = trunc(bulletCoords[2] / HPPT)
			z_change = -(bulletCoords[3] < 0) + (bulletCoords[3] > LEVEL_MAX)
			while(x_change || y_change || z_change)
				leaving = get_turf(projectile)
				if(projectile.scanTurf(leaving, trajectoryData, &distanceToTravelForce) != PROJECTILE_CONTINUE)
					pixelsToTravel = distanceToTravelForce
					//pixelsToTravel = min(bullet.pixelsPerTick - pixelsToTravel, distanceToTravelForce)
					message_admins("dist set to [pixelsToTravel]")
					goto forceLoop
				if(QDELETED(projectile))
					bullet_queue -= bullet
					break
				tx_change = ((x_change + (x_change == 0))/(abs(x_change + (x_change == 0)))) * (x_change != 0)
				ty_change = ((y_change + (y_change == 0))/(abs(y_change + (y_change == 0)))) * (y_change != 0)
				tz_change = ((z_change + (z_change == 0))/(abs(z_change + (z_change == 0)))) * (z_change != 0)
				//if(tz_change)
				//	message_admins("tz change [tz_change]")
				moveTurf = locate(projectile.x + tx_change, projectile.y + ty_change, projectile.z + tz_change)
				x_change -= tx_change
				y_change -= ty_change
				z_change -= tz_change
				bullet.lastChanges[1] += tx_change
				bullet.lastChanges[2] += ty_change
				bullet.lastChanges[3] += tz_change
				bulletCoords[1] -= PPT * tx_change
				bulletCoords[2] -= PPT * ty_change
				bulletCoords[3] -= tz_change * LEVEL_MAX
				projectile.pixel_x -= PPT * tx_change
				projectile.pixel_y -= PPT * ty_change
				bullet.updateLevel()
				if(projectile.scanTurf(moveTurf, trajectoryData, &distanceToTravelForce) == PROJECTILE_CONTINUE)
					//message_admins("[bulletCoords[3]],  [trajectoryData[6]]" )
					bullet.painted.Add(moveTurf)
					//moveTurf.color = COLOR_RED
					projectile.forceMove(moveTurf)
					/*
					if(moveTurf != bullet.targetTurf)
						message_admins("level of [bulletCoords[3]], [trajectoryData[6]], pixels : [bullet.traveled],")
					else
						message_admins("reached target with level of [bulletCoords[3]] , pixels : [bullet.traveled], diff : [bullet.distStartToFinish2D() - bullet.traveled] , traj [trajectoryData[6]] , sum [bullet.trajSum]")
					*/
				else
					pixelsToTravel = distanceToTravelForce
					message_admins("dist set to [pixelsToTravel]")
					goto forceLoop
				moveTurf = null
			/*
			else
				if(get_turf(projectile) == bullet.targetTurf)
					message_admins("reached target with level of [bulletCoords[3]] , pixels : [bullet.traveled], diff : [bullet.distStartToFinish2D() - bullet.traveled] , traj [trajectoryData[6]], sum [bullet.trajSum]")
				else
					message_admins("level of [bulletCoords[3]], [trajectoryData[6]], pixels : [bullet.traveled],")
			*/

			bullet.lifetime--

		bullet.updateLevel()
		var/levelRatio = 1 - (trunc(bulletCoords[3])/LEVEL_MAX)
		//message_admins("[levelRatio]")
		var/animationColor = gradient(list("#ffffff", "#cbcbcb"), levelRatio)
		animate(projectile, SSbullets.wait, pixel_x =((abs(bulletCoords[1]))%HPPT * sign(bulletCoords[1]) - 1), pixel_y = ((abs(bulletCoords[2]))%HPPT * sign(bulletCoords[2]) - 1), flags = ANIMATION_END_NOW, color = animationColor)
		bullet.currentCoords = bulletCoords
		if(bullet.lifetime < 1)
			bullet.referencedBullet.finishDeletion()
			bullet_queue -= bullet
			//for(var/turf/painted in bullet.painted)
			//	painted.color = initial(painted.color)
	*/


