/// Pixels per turf
#define PPT 32
#define HPPT (PPT/2)
/// the higher you go the higher you risk trajectories becoming wobbly and inaccurate.
/// 16 is the absolute lowest which guarantees maximum accuracy.
/// 20 is a safe bet between 24 and 16
/// the higher this is ,the more performant the system is , since more of the math is done at once instead of in stages
/// it is also more inaccurate the higher you go..
#define MAXPIXELS 16
SUBSYSTEM_DEF(bullets)
	name = "Bullets"
	wait = 5
	priority = SS_PRIORITY_BULLETS
	init_order = INIT_ORDER_BULLETS

	var/list/datum/bullet_data/current_queue = list()
	var/list/datum/bullet_data/bullet_queue = list()
	// Used for processing bullets. No point in deallocating and reallocating them every MC tick.
	var/list/bulletRatios
	var/list/bulletCoords
	var/obj/item/projectile/projectile
	var/pixelsToTravel
	var/pixelsThisStep
	var/x_change
	var/y_change
	var/z_change
	var/tx_change
	var/ty_change
	var/tz_change
	var/turf/moveTurf = null
	var/list/relevantAtoms = list()
	// 1 client tick by default , can be increased by impacts
	var/bulletWait = 1
	//// x1,y1,x2,y2,z1,z2
	var/list/trajectoryData = list(0,0,0,0,0,0,0)
	var/distanceToTravelForce



/// You might ask why use a bullet data datum, and not store all the vars on the bullet itself, honestly its to keep track and initialize firing relevant vars only when needed
/// This data is guaranteed to be of temporary use spanning 15-30 seconds or how long the bullet moves for. Putting them on the bullet makes each one take up more ram
/// And ram is not a worry , but its better to initialize less and do the lifting on fire.
/datum/bullet_data
	var/obj/item/projectile/referencedBullet = null
	//
	var/aimedZone = ""
	var/globalX = 0
	var/globalY = 0
	var/globalZ = 0
	var/pixelSpeed = 0
	var/ratioX = 0
	var/ratioY = 0
	var/ratioZ = 0
	//


	var/atom/firer = null
	var/turf/firedTurf = null
	var/list/firedCoordinates = list(0,0,0)
	var/list/firedPos = list(0,0,0)
	var/firedLevel = 0
	var/atom/target = null
	var/turf/targetTurf = null
	var/list/targetCoords = list(0,0,0)
	var/list/targetPos = list(0,0,0)
	var/turf/currentTurf = null
	var/currentCoords = list(0,0,0)
	/// [1]=X , [2]=Y, [3]=Z, [4]=Angle
	/// Note : MovementRatios[3] aka Zratio is not used because i couldn't figure out
	/// how to properly translate it to pixels travelled , main issue resides in dist_euclidian2D not being 1:1 with
	/// actual amount of pixels to travel at other angles
	var/movementRatios = list(0,0,0,0)
	var/list/turf/coloreds = list()
	var/targetLevel = 0
	var/currentLevel = 0
	var/pixelsPerTick = 0
	var/projectileAccuracy = 0
	var/lifetime = 30
	var/bulletLevel = 0
	var/lastChanges = list(0,0,0)
	/// Used to determine wheter a projectile should be allowed to bump a turf or not.
	var/isTraversingLevel = FALSE
	/// Used to animate the ending pixels
	var/hasImpacted = FALSE
	var/list/painted = list()
	var/traveled
	var/trajSum
	var/list/cannotHit = list()

/datum/bullet_data/New(obj/item/projectile/referencedBullet, aimedZone, atom/firer, atom/target, list/targetCoords, pixelsPerTick,zOffset, angleOffset, lifetime)
	/*
	if(!target)
		message_admins("Created bullet without target , [referencedBullet]")
		return
	if(!firer)
		message_admins("Created bullet without firer, [referencedBullet]")
		return
	*/
	referencedBullet.dataRef = src
	src.referencedBullet = referencedBullet
	src.currentTurf = get_turf(referencedBullet)
	src.currentCoords = list(referencedBullet.pixel_x, referencedBullet.pixel_y, referencedBullet.z)
	src.targetCoords = targetCoords
	src.aimedZone = aimedZone
	src.pixelsPerTick = pixelsPerTick
	src.projectileAccuracy = projectileAccuracy
	src.lifetime = lifetime
	src.firedCoordinates = list(16,16, referencedBullet.z)
	if(firer)
		src.firer = firer
		src.firedTurf = get_turf(firer)
		src.firedPos = list(firer.x , firer.y , firer.z)
		if(ismob(firer))
			if(iscarbon(firer))
				if(firer:lying)
					src.firedLevel = LEVEL_LYING
				else
					src.firedLevel = LEVEL_CHEST
			else
				src.firedLevel = LEVEL_CHEST
		else
			src.firedLevel = LEVEL_HEAD
	if(target)
		src.target = target
		src.targetTurf = get_turf(target)
		src.targetPos = list(target.x, target.y , target.z)
		src.targetLevel = target.getAimingLevel(firer, aimedZone)
		if(targetLevel == HBF_NOLEVEL)
			if(ismob(target))
				if(iscarbon(target))
					if(target:lying)
						src.targetLevel = LEVEL_LYING
					else
						src.targetLevel = LEVEL_HEAD
				else
					src.targetLevel = LEVEL_HEAD
			else if(istype(target, /obj/structure/low_wall))
				src.targetLevel = LEVEL_LOWWALL
			else if(istype(target, /obj/structure/window))
				src.targetLevel = LEVEL_HEAD
			else if(istype(target, /obj/structure/table))
				src.targetLevel = LEVEL_TABLE
			else if(iswall(target))
				src.targetLevel = LEVEL_HEAD
			else if(isturf(target))
				src.targetLevel = LEVEL_TURF
			else if(isitem(target))
				src.targetLevel = LEVEL_TURF
	else
		message_admins(("Created bullet without target , [referencedBullet], from [usr]"))

	if(abs(target.pixel_x) > PPT/2)
		targetPos[1] += round((target.pixel_x - PPT/2 )/ PPT) + 1 * sign(target.pixel_x)
	if(abs(target.pixel_y) > PPT/2)
		targetPos[2] += round((target.pixel_y - PPT/2) / PPT) + 1 * sign(target.pixel_y)

	pixelSpeed = pixelsPerTick
	globalX = currentTurf.x * 32 + currentCoords[1] + 16
	globalY = currentTurf.y * 32 + currentCoords[2] + 16
	globalZ = currentTurf.z * 32

	//message_admins("level set to [firedLevel], towards [targetLevel]")
	currentCoords[3] = firedLevel
	targetLevel += (targetCoords[3] - firedPos[3])* LEVEL_MAX
	/// These use LERP until a way can be figured out to calculate a level for amount of pixels traversed
	//message_admins("Distance to target is [distStartToFinish2D()] , startingLevel [firedLevel] , targetLevel [targetLevel]")
	//movementRatios[3] = (targetLevel - firedLevel) / (distStartToFinish2D() * PPT)

	targetLevel += zOffset * (distStartToFinish2D() / PPT)
	//movementRatios[3] += zOffset / MAXPIXELS
	//message_admins("calculated movementRatio , [movementRatios[3]], offset is [zOffset * (distStartToFinish2D()/ PPT)]")
	movementRatios[4] = getAngleByPosition()
	movementRatios[4] += angleOffset
	updatePathByAngle()
	SSbullets.bullet_queue += src

/datum/bullet_data/proc/redirect(list/targetCoordinates, list/firingCoordinates)
	src.firedTurf = get_turf(referencedBullet)
	src.firedPos = firingCoordinates
	src.targetCoords = targetCoordinates
	updatePathByPosition()

/datum/bullet_data/proc/bounce(bounceAxis, angleOffset)
	movementRatios[bounceAxis] *= -1
	movementRatios[4] = arctan(movementRatios[2], movementRatios[1]) + angleOffset
	updatePathByAngle()

/datum/bullet_data/proc/getAngleByPosition()
	var/x = ((targetPos[1] - firedPos[1]) * PPT + targetCoords[1] - firedCoordinates[1])
	var/y = ((targetPos[2] - firedPos[2]) * PPT + targetCoords[2] - firedCoordinates[2])
	return ATAN2(y, x)

/datum/bullet_data/proc/updatePathByAngle()
	var/matrix/rotation = matrix()
	movementRatios[1] = sin(movementRatios[4])
	movementRatios[2] = cos(movementRatios[4])
	ratioX = movementRatios[1]
	ratioY = movementRatios[2]


	rotation.Turn(movementRatios[4] + 180)
	referencedBullet.transform = rotation

/datum/bullet_data/proc/updatePathByPosition()
	var/matrix/rotation = matrix()
	//movementRatios[3] = ((targetPos[3] + targetLevel - firedPos[3] - firedLevel)) / (round(distStartToFinish3D()) * PPT)
	movementRatios[4] = getAngleByPosition()
	movementRatios[1] = sin(movementRatios[4])
	movementRatios[2] = cos(movementRatios[4])
	rotation.Turn(movementRatios[4] + 180)
	referencedBullet.transform = rotation

/datum/bullet_data/proc/distStartToFinish2D()
	var/x1 = ((targetPos[1] - 1)*PPT + targetCoords[1] + 16)
	var/y1 = ((targetPos[2]- 1)*PPT + targetCoords[2] + 16)
	var/x2 = ((firedPos[1] - 1)*PPT + firedCoordinates[1] + 16)
	var/y2 = ((firedPos[2] -  1)*PPT + firedCoordinates[2] + 16)
	return DIST_EUCLIDIAN_2D(x1,y1,x2,y2)

/datum/bullet_data/proc/distStartToFinish3D()
	return DIST_EUCLIDIAN_3D((targetPos[1]-1)*PPT + 16 + targetCoords[1],(targetPos[2]-1)*PPT + 16 + targetCoords[2],targetPos[3] + targetLevel ,(firedPos[1]*PPT)/PPT, (firedPos[2]*PPT)/PPT, firedPos[3] + firedLevel)
	//return DIST_EUCLIDIAN_3D((targetPos[1]*PPT +targetCoords[1] + 16)/PPT,(targetPos[2]*PPT + targetCoords[2] + 16)/PPT,targetPos[3] + targetLevel ,(firedPos[1]*PPT +firedCoordinates[1] + 16)/PPT, (firedPos[2]*PPT +firedCoordinates[2] + 16)/PPT, firedPos[3] + firedLevel)



	/*
	var/x = targetPos[1] - firedPos[1]
	var/y = targetPos[2] - firedPos[2]
	var/px = targetCoords[1] - firedCoordinates[1]
	var/py = targetCoords[2] - firedCoordinates[2]
	return sqrt(x**2 + y**2) + sqrt(px**2 + py**2)
	*/

/datum/bullet_data/proc/updateLevel()
	switch(currentCoords[3])
		if(-INFINITY to LEVEL_BELOW)
			currentLevel = LEVEL_BELOW
		if(LEVEL_BELOW to LEVEL_TURF)
			currentLevel = LEVEL_TURF
		if(LEVEL_TURF to LEVEL_LYING)
			currentLevel = LEVEL_LYING
		if(LEVEL_LYING to LEVEL_LOWWALL)
			currentLevel = LEVEL_LOWWALL
		if(LEVEL_LOWWALL to LEVEL_TABLE)
			currentLevel = LEVEL_TABLE
		if(LEVEL_TABLE to LEVEL_HEAD)
			currentLevel = LEVEL_HEAD
		if(LEVEL_HEAD to INFINITY)
			currentLevel = LEVEL_ABOVE

/datum/bullet_data/proc/getLevel(height)
	switch(height)
		if(-INFINITY to LEVEL_BELOW)
			return LEVEL_BELOW
		if(LEVEL_BELOW to LEVEL_TURF)
			return LEVEL_TURF
		if(LEVEL_TURF to LEVEL_LYING)
			return LEVEL_LYING
		if(LEVEL_LYING to LEVEL_LOWWALL)
			return LEVEL_LOWWALL
		if(LEVEL_LOWWALL to LEVEL_TABLE)
			return LEVEL_TABLE
		if(LEVEL_TABLE to LEVEL_HEAD)
			return LEVEL_HEAD
		if(LEVEL_HEAD to INFINITY)
			return LEVEL_ABOVE

/datum/controller/subsystem/bullets/proc/reset()
	current_queue = list()
	bullet_queue = list()

/datum/controller/subsystem/bullets/proc/realFire()
	current_queue = bullet_queue.Copy()
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
	for(var/datum/bullet_data/dataReference in current_queue)
		current_queue.Remove(dataReference)
		projectile = dataReference.referencedBullet
		if(QDELETED(projectile))
			bullet_queue.Remove(dataReference)
			continue
		currentX = dataReference.globalX
		currentY = dataReference.globalY
		currentZ = dataReference.globalZ
		bulletDir = (EAST*(dataReference.ratioX>0)) | (WEST*(dataReference.ratioX<0)) | (NORTH*(dataReference.ratioY>0)) | (SOUTH*(dataReference.ratioY<0)) | (UP*(dataReference.ratioZ>0)) | (DOWN*(dataReference.ratioZ<0))
		pixelTotal = dataReference.pixelSpeed
		dataReference.lifetime--
		while(pixelTotal > 0)
			pixelStep = min(pixelTotal, (PPT/2))
			pixelTotal -= pixelStep
			stepX = dataReference.ratioX * pixelStep
			stepY = dataReference.ratioY * pixelStep
			stepZ = dataReference.ratioZ * pixelStep
			dataReference.globalX += stepX
			dataReference.globalY += stepY
			dataReference.globalZ += stepZ
			currentTurf = get_turf(projectile)
			movementTurf = locate(round(dataReference.globalX/PPT),round(dataReference.globalY/PPT),round(dataReference.globalZ/PPT))
			message_admins("X: [movementTurf.x] Y:[movementTurf.y] Z:[movementTurf.z]")
			if(movementTurf == currentTurf)
				canContinue = projectile.scanTurf(currentTurf, bulletDir, currentX, currentY, currentZ, &stepX, &stepY, &stepZ)
			else
				canContinue = projectile.scanTurf(currentTurf, bulletDir, currentX, currentY, currentZ, &stepX, &stepY, &stepZ)
				if(canContinue == PROJECTILE_CONTINUE)
					canContinue = projectile.scanTurf(movementTurf, bulletDir, currentX, currentY, currentZ, &stepX, &stepY, &stepZ)
					projectile.pixel_x -= (movementTurf.x - currentTurf.x) * PPT
					projectile.pixel_y -= (movementTurf.y - currentTurf.y) * PPT
					projectile.pixel_z -= (movementTurf.z - currentTurf.z) * PPT
					//message_admins("PX : [projectile.pixel_x] , PY : [projectile.pixel_y] , PZ: [projectile.pixel_z]")
					projectile.forceMove(movementTurf)
			currentX = dataReference.globalX
			currentY = dataReference.globalY
			currentZ = dataReference.globalZ



			if(canContinue != PROJECTILE_CONTINUE)
				var/a = round((currentX+stepX)/32)
				var/b = round((currentY+stepY)/32)
				var/c = round((currentZ+stepZ)/32)
				var/turf/turfer = locate(a, b, c)
				var/atom/movable/special = new /obj/item()
				special.forceMove(turfer)
				special.icon = projectile.icon
				special.icon_state = projectile.icon_state
				special.pixel_x = round((currentX+stepX))%32 - 16
				special.pixel_y = round((currentY+stepY))%32 - 16
				special.transform = projectile.transform
				message_admins("started at X: [round(currentX)]. Y: [round(currentY)] , stopping at X: [round(currentX+stepX)] , Y:[round(currentY+stepY)]")
				dataReference.globalX = currentX + stepX
				dataReference.globalY = currentY + stepY
				dataReference.globalZ += stepZ
				dataReference.lifetime = 0
				break

		if(canContinue != PROJECTILE_CONTINUE)
			message_admins("globalX : [dataReference.globalX] globalY: [dataReference.globalY]")
		animate(projectile, SSbullets.wait, pixel_x = dataReference.globalX%PPT - HPPT, pixel_y = dataReference.globalY%PPT - HPPT, flags = ANIMATION_END_NOW)
		if(dataReference.lifetime < 1)
			projectile.finishDeletion()
			bullet_queue.Remove(dataReference)

/datum/controller/subsystem/bullets/fire(resumed)
	return realFire()
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


