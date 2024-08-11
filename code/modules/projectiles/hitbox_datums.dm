GLOBAL_LIST_EMPTY(hitboxPrototypes)

/hook/startup/proc/initializeHitboxes()
	for(var/type in subtypesof(/datum/hitboxDatum))
		GLOB.hitboxPrototypes[type] = new type()

/proc/getHitbox(path)
	if(!GLOB.hitboxPrototypes[path])
		return null
	return GLOB.hitboxPrototypes[path]

/datum/hitboxDatum
	var/list/boundingBoxes = list()
	/// global offsets , applied to all bounding boxes equally
	var/offsetX = 0
	var/offsetY = 0
	/// stores the median levels to aim when shooting at the owner.
	var/list/medianLevels
	/// converts the defZone argument to a specific level.
	var/list/defZoneToLevel = list(
		BP_EYES = HBF_USEMEDIAN,
		BP_MOUTH = HBF_USEMEDIAN,
		BP_HEAD = HBF_USEMEDIAN,
		BP_CHEST = HBF_USEMEDIAN,
		BP_L_LEG = HBF_USEMEDIAN,
		BP_R_LEG = HBF_USEMEDIAN,
		BP_GROIN = HBF_USEMEDIAN,
		BP_R_ARM = HBF_USEMEDIAN,
		BP_L_ARM = HBF_USEMEDIAN
	)

/// this can be optimized further by making the calculations not make a new list , and instead be added when checking line intersection - SPCR 2024
/datum/hitboxDatum/proc/intersects(atom/owner, ownerDirection, startX, startY, startZ, pStepX, pStepY, pStepZ)

/datum/hitboxDatum/proc/getAimingLevel(atom/shooter, defZone, atom/owner)


/*
boolean lineLine(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {


  // calculate the distance to intersection point
  float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
  float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));

  // if uA and uB are between 0-1, lines are colliding
  if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {

    // optionally, draw a circle where the lines meet
    float intersectionX = x1 + (uA * (x2-x1));
    float intersectionY = y1 + (uA * (y2-y1));
    fill(255,0,0);
    noStroke();
    ellipse(intersectionX,intersectionY, 20,20);

    return true;
  }
  return false;
}
*/
// Based off the script above. Optimized based off github comments relating to code above.
/// x1,y1 and x2,y2 are the start and end of the first line
/// x3,y3 and x4,y4 are the start and end of the second line
/// pStepX and pStepY are pointers for setting the bullets step end
/datum/hitboxDatum/proc/lineIntersect(x1,y1,x2,y2,x3,y3,x4,y4, pStepX, pStepY)
	var/firstRatio
	var/secondRatio
	var/denominator = ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))
	if(denominator == 0)
		message_admins("Invalid line for [src], at hitbox coords BulletLine ([x1] | [y1]) ([x2] | [y2])  HitboxLine ([x3] | [y3]) ([x4] | [y4])")
		return FALSE
	firstRatio = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denominator
	secondRatio = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denominator
	if(firstRatio >= 0 && firstRatio <= 1 && secondRatio >= 0 && secondRatio <= 1)
		*pStepX = x1 + firstRatio * (x2 - x1)
		*pStepY = y1 + firstRatio * (y2 - y1)
		message_admins("set x to [*pStepX] , set y to [*pStepY]")
		return TRUE
		//return list(x1 + firstRatio * (x2 - x1), y1 + firstRatio * (y2 - y1))
		//message_admins("X-collision : [x1 + firstRatio * (x2 - x1)] Y-collision : [y1 + firstRatio * (y2] - y1)]")
		//message_admins("Distance between points : [DIST_EUCLIDIAN_2D(x1,y1,x1 + firstRatio * (x2 - x1),y1 + firstRatio * (y2] - y1) )]")
	return FALSE


/datum/hitboxDatum/proc/visualize(atom/owner)
	for(var/list/hitbox in boundingBoxes[num2text(owner.dir)])
		var/icon/Icon = icon('icons/hitbox.dmi', "box")
		var/multX = hitbox[3] - hitbox[1] + 1
		var/multY = hitbox[4] - hitbox[2] + 1
		Icon.Scale(multX, multY)
		var/mutable_appearance/newOverlay = mutable_appearance(Icon, "hitbox")
		newOverlay.color = RANDOM_RGB
		newOverlay.pixel_x = hitbox[1] - 1
		newOverlay.pixel_y = hitbox[2] - 1
		newOverlay.alpha = 200
		owner.overlays.Add(newOverlay)

/datum/hitboxDatum/atom
	boundingBoxes = list(
		LISTNORTH = list(BBOX(16,16,24,24,1,2,null)),
		LISTSOUTH = list(BBOX(16,16,24,24,1,2,null)),
		LISTEAST = list(BBOX(16,16,24,24,1,2,null)),
		LISTWEST = list(BBOX(16,16,24,24,1,2,null))
	)

/datum/hitboxDatum/atom/New()
	. = ..()
	var/median
	var/volumeSum
	var/calculatedVolume = 0
	// dont bother calculating if already defined.
	if(length(medianLevels))
		return
	medianLevels = list()
	for(var/direction in list(NORTH, SOUTH, EAST , WEST))
		median = 0
		volumeSum = 0
		for(var/list/boundingBox in boundingBoxes["[direction]"])
			calculatedVolume = (boundingBox[4] - boundingBox[2]) * (boundingBox[3] - boundingBox[1])
			median += ((boundingBox[5] + boundingBox[6])/2) * calculatedVolume
			volumeSum += calculatedVolume
		if(volumeSum == 0)
			medianLevels["[direction]"] = LEVEL_TABLE
		else
			medianLevels["[direction]"] = median / volumeSum

/datum/hitboxDatum/atom/getAimingLevel(atom/shooter, defZone, atom/owner)
	if(defZone == null || (!(defZone in defZoneToLevel)))
		return medianLevels["[owner.dir]"]
	if(defZoneToLevel[defZone] == HBF_USEMEDIAN)
		return medianLevels["[owner.dir]"]
	message_admins("Returned [defZoneToLevel[defZone]] for [defZone]")
	return defZoneToLevel[defZone]

	/// this can be optimized further by making the calculations not make a new list , and instead be added when checking line intersection - SPCR 2024
/datum/hitboxDatum/atom/intersects(atom/owner, ownerDirection, startX, startY, startZ, pStepX, pStepY, pStepZ)
	var/worldX
	var/worldY
	var/worldZ
	worldX = owner.x
	worldY = owner.y
	if(owner.atomFlags & AF_HITBOX_OFFSET_BY_ATTACHMENT)
		for(var/atom/thing as anything in owner.attached)
			if(!(thing.attached[owner] & ATFS_SUPPORTER))
				continue
			worldX += thing.x - owner.x
			worldY += thing.y - owner.y
			break
	worldX *= PPT
	worldY *= PPT
	worldX += owner.pixel_x
	worldY += owner.pixel_y
	worldZ = owner.z * PPT
	for(var/list/boundingData in boundingBoxes["[ownerDirection]"])
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[1] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			return TRUE
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[2] + worldY, pStepX, pStepY))
			return TRUE
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[4] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			return TRUE
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[3] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			return TRUE
	return FALSE


/// This subtype is dedicated especially to tables. Their building system changes shape depending on adjaency. So this reflects that
/// List format is unconventional and based off the the way connections are done

// Also.. holy mother of lists... yes there is a LOT of data to store for all the permutations..
// each corner has 8 possible states , all of them have 4 directions , so this is 4 x 8  aka 32 permutations.
// some of this could be cut down with some smart flipping ,but for some cases it doesn't work or its not worth the CPU usage - SPCR 2024

/datum/hitboxDatum/atom/table
	// this boundingBoxes just stores each corner's hitbox depending on its connections ,the actual hitbox is formed when doing actual hit checks
	boundingBoxes = list(
		1 = list(
			LISTNORTH = list(BBOX(5,17,16,30,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTSOUTH = list(BBOX(17,2,28,16,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTEAST = list(BBOX(17,17,28,30,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTWEST = list(BBOX(5,2,16,16,LEVEL_TURF,LEVEL_TABLE,null))
		),
		2 = list(
			LISTNORTH = list(BBOX(1,17,16,30,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTSOUTH = list(BBOX(17,4,32,16,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTEAST = list(BBOX(17,17,28,32,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTWEST = list(BBOX(5,1,16,16,LEVEL_TURF,LEVEL_TABLE,null))
		),
		3 = list(
			LISTNORTH = list(BBOX(5,17,16,30,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTSOUTH = list(BBOX(17,2,28,16,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTEAST = list(BBOX(17,17,28,30,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTWEST = list(BBOX(5,2,16,16,LEVEL_TURF,LEVEL_TABLE,null))
		),
		4 = list(
			LISTNORTH = list(BBOX(1,17,16,30,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTSOUTH = list(BBOX(17,4,32,16,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTEAST = list(BBOX(17,17,28,32,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTWEST = list(BBOX(5,1,16,16,LEVEL_TURF,LEVEL_TABLE,null))
		),
		5 = list(
			LISTNORTH = list(BBOX(5,17,16,32,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTSOUTH = list(BBOX(17,1,28,16,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTEAST = list(BBOX(17,17,32,30,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTWEST = list(BBOX(1,4,16,16,LEVEL_TURF,LEVEL_TABLE,null))
		),
		6 = list(
			LISTNORTH = list(BBOX(1,17,16,32,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTSOUTH = list(BBOX(17,1,32,16,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTEAST = list(BBOX(17,17,32,32,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTWEST = list(BBOX(1,1,16,16,LEVEL_TURF,LEVEL_TABLE,null))
		),
		7 = list(
			LISTNORTH = list(BBOX(5,17,16,32,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTSOUTH = list(BBOX(17,1,28,16,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTEAST = list(BBOX(17,17,32,30,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTWEST = list(BBOX(1,4,16,16,LEVEL_TURF,LEVEL_TABLE,null))
		),
		8 = list(
			LISTNORTH = list(BBOX(1,17,16,32,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTSOUTH = list(BBOX(17,1,32,16,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTEAST = list(BBOX(17,17,32,32,LEVEL_TURF,LEVEL_TABLE,null)),
			LISTWEST = list(BBOX(1,1,16,16,LEVEL_TURF,LEVEL_TABLE,null))
		)
	)
	medianLevels = list(
		LISTNORTH = (LEVEL_TURF+LEVEL_TABLE)/2,
		LISTSOUTH = (LEVEL_TURF+LEVEL_TABLE)/2,
		LISTEAST = (LEVEL_TURF+LEVEL_TABLE)/2,
		LISTWEST = (LEVEL_TURF+LEVEL_TABLE)/2
	)

/datum/hitboxDatum/atom/table/getAimingLevel(atom/shooter, defZone, atom/owner)
	return medianLevels["[owner.dir]"]

/datum/hitboxDatum/atom/table/visualize(obj/structure/table/owner)
	for(var/i = 1 to 4)
		var/list/boundingList = boundingBoxes[text2num(owner.connections[i])+1]["[(1<<(i-1))]"]
		for(var/list/hitbox in boundingList)
			var/icon/Icon = icon('icons/hitbox.dmi', "box")
			var/multX = hitbox[3] - hitbox[1] + 1
			var/multY = hitbox[4] - hitbox[2] + 1
			Icon.Scale(multX, multY)
			var/mutable_appearance/newOverlay = mutable_appearance(Icon, "hitbox")
			newOverlay.color = RANDOM_RGB
			newOverlay.pixel_x = hitbox[1] - 1
			newOverlay.pixel_y = hitbox[2] - 1
			newOverlay.alpha = 200
			owner.overlays.Add(newOverlay)

/// this can be optimized further by making the calculations not make a new list , and instead be added when checking line intersection - SPCR 2024
/datum/hitboxDatum/atom/table/intersects(obj/structure/table/owner, ownerDirection, startX, startY, startZ, pStepX, pStepY, pStepZ)
	var/worldX
	var/worldY
	var/worldZ
	worldX = owner.x * PPT + owner.pixel_x
	worldY = owner.y * PPT + owner.pixel_y
	worldZ = owner.z * PPT
	var/list/boundingList
	for(var/i = 1 to 4)
		// 1<<(i-1) , clever way to convert from index to direction
		// i=1 ==> north
		// i=2 ==> south
		// i=3 ==> east
		// i=4 ==> west
		// i dont get why owner connections is text.. but it is what it is
		boundingList = boundingBoxes[text2num(owner.connections[i])+1]["[(1<<(i-1))]"]
		for(var/list/boundingData in boundingList)
			if((boundingData[5]+worldZ) > max(startZ,startZ+*pStepZ) && (boundingData[6]+worldZ) > max(startZ,startZ+*pStepZ))
				continue
			if((boundingData[5]+worldZ) < min(startZ,startZ+*pStepZ) && (boundingData[6]+worldZ) < min(startZ,startZ+*pStepZ))
				continue
			if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[1] + worldX, boundingData[4] + worldY, pStepX, pStepY))
				return TRUE
			if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[2] + worldY, pStepX, pStepY))
				return TRUE
			if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[4] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
				return TRUE
			if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[3] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
				return TRUE
	return FALSE

/datum/hitboxDatum/atom/fixtureLightTube
	boundingBoxes = list(
		LISTNORTH = list(BBOX(4,29,29,32,LEVEL_HEAD-1,LEVEL_HEAD+1,null)),
		LISTSOUTH = list(BBOX(4,1,29,4,LEVEL_HEAD-1,LEVEL_HEAD+1,null)),
		LISTEAST = list(BBOX(29,4,32,29,LEVEL_HEAD-1,LEVEL_HEAD+1,null)),
		LISTWEST = list(BBOX(1,4,4,29,LEVEL_HEAD-1,LEVEL_HEAD+1,null))
	)

/datum/hitboxDatum/atom/fixtureBulb
	boundingBoxes = list(
		LISTNORTH = list(BBOX(14,25,19,32,LEVEL_HEAD-1,LEVEL_HEAD+1,null)),
		LISTSOUTH = list(BBOX(14,1,20,8,LEVEL_HEAD-1,LEVEL_HEAD+1,null)),
		LISTEAST = list(BBOX(25,14,32,19,LEVEL_HEAD-1,LEVEL_HEAD+1,null)),
		LISTWEST = list(BBOX(1,14,8,19,LEVEL_HEAD-1,LEVEL_HEAD+1,null))
	)

/datum/hitboxDatum/atom/fireAlarm
	boundingBoxes = list(
		LISTNORTH = list(BBOX(13,10,20,22,LEVEL_CHEST-1,LEVEL_CHEST+1,null)),
		LISTSOUTH = list(BBOX(13,11,20,23,LEVEL_CHEST-1,LEVEL_CHEST+1,null)),
		LISTEAST = list(BBOX(10,13,22,20,LEVEL_CHEST-1,LEVEL_CHEST+1,null)),
		LISTWEST = list(BBOX(11,13,23,20,LEVEL_CHEST-1,LEVEL_CHEST+1,null))
	)

/datum/hitboxDatum/atom/airAlarm
	boundingBoxes = list(
		LISTNORTH = list(BBOX(8,10,24,23,LEVEL_CHEST-1,LEVEL_CHEST+2,null)),
		LISTSOUTH = list(BBOX(8,10,24,23,LEVEL_CHEST-1,LEVEL_CHEST+2,null)),
		LISTEAST = list(BBOX(10,8,23,24,LEVEL_CHEST-1,LEVEL_CHEST+2,null)),
		LISTWEST = list(BBOX(10,9,23,25,LEVEL_CHEST-1,LEVEL_CHEST+2,null))
	)

/datum/hitboxDatum/turf
	boundingBoxes = BBOX(0,0,32,32,LEVEL_BELOW ,LEVEL_ABOVE,null)

/datum/hitboxDatum/turf/intersects(atom/owner, ownerDirection, startX, startY, startZ, pStepX, pStepY, pStepZ)
	var/worldX
	var/worldY
	var/worldZ
	worldX = owner.x * PPT
	worldY = owner.y * PPT
	worldZ = owner.z * PPT
	//basic AABB but only for the Z-axis.
	if((boundingBoxes[5]+worldZ)> max(startZ,startZ+*pStepZ) && (boundingBoxes[6]+worldZ) > max(startZ,startZ+*pStepZ))
		return FALSE
	if((boundingBoxes[5]+worldZ) < min(startZ,startZ+*pStepZ) && (boundingBoxes[6]+worldZ) < min(startZ,startZ+*pStepZ))
		return FALSE
	if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingBoxes[1] + worldX, boundingBoxes[2] + worldY, boundingBoxes[1] + worldX, boundingBoxes[4] + worldY, pStepX, pStepY))
		return TRUE
	if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingBoxes[1] + worldX, boundingBoxes[2] + worldY, boundingBoxes[3] + worldX, boundingBoxes[2] + worldY, pStepX, pStepY))
		return TRUE
	if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingBoxes[1] + worldX, boundingBoxes[4] + worldY, boundingBoxes[3] + worldX, boundingBoxes[4] + worldY, pStepX, pStepY))
		return TRUE
	if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingBoxes[3] + worldX, boundingBoxes[2] + worldY, boundingBoxes[3] + worldX, boundingBoxes[4] + worldY, pStepX, pStepY))
		return TRUE
	return FALSE

/datum/hitboxDatum/turf/wall
	boundingBoxes = BBOX(0,0,32,32,LEVEL_BELOW ,LEVEL_ABOVE,null)

/datum/hitboxDatum/turf/floor
	boundingBoxes = BBOX(0,0,32,32,LEVEL_BELOW ,LEVEL_TURF,null)

/// This checks line by line instead of a box. Less efficient.
/datum/hitboxDatum/atom/polygon
	boundingBoxes = list(
		LISTNORTH = list(BLINE(0,0,32,32)),
		LISTSOUTH = list(BLINE(0,0,32,32)),
		LISTEAST = list(BLINE(0,0,32,32)),
		LISTWEST = list(BLINE(0,0,32,32))
	)

/datum/hitboxDatum/atom/polygon/intersects(atom/owner, ownerDirection, startX, startY, startZ, pStepX, pStepY, pStepZ)
	var/worldX
	var/worldY
	worldX = owner.x
	worldY = owner.y
	if(owner.atomFlags & AF_HITBOX_OFFSET_BY_ATTACHMENT)
		for(var/atom/thing as anything in owner.attached)
			if(!(thing.attached[owner] & ATFS_SUPPORTER))
				continue
			worldX += thing.x - owner.x
			worldY += thing.y - owner.y
			break
	worldX *= 32
	worldY *= 32
	worldX += owner.pixel_x
	worldY += owner.pixel_y
	for(var/list/boundingData in boundingBoxes["[ownerDirection]"])
		/// basic AABB but only for the Z-axis.
		//if(boundingData[5] > max(startZ,startZ+*pStepZ) || boundingData[6] < min(startZ,startZ+*pStepZ))
		//	continue
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[1] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			return TRUE
	return FALSE

/datum/hitboxDatum/atom/polygon/visualize(atom/owner)
	/// too hard to get offsets for lines ((( SPCR 2024
	return
/// Indexed by whatever the fuck dirs getHitboxData() returns from the pipe
/datum/hitboxDatum/atom/polygon/atmosphericPipe
	boundingBoxes = list(
		LISTNORTH = BLINE(16,16,16,32),
		LISTSOUTH = BLINE(16,0,16,16),
		LISTEAST = BLINE(16,16,32,16),
		LISTWEST = BLINE(0,16,16,16)
	)

/datum/hitboxDatum/atom/polygon/atmosphericPipe/intersects(obj/machinery/atmospherics/owner, ownerDirection, startX, startY, startZ, pStepX, pStepY, pStepZ)
	var/worldX
	var/worldY
	var/worldZ
	worldX = owner.x * 32
	worldY = owner.y * 32
	var/validDirs = owner.getHitboxData()
	for(var/direction in list(NORTH, EAST, WEST, SOUTH))
		if(!(direction & validDirs))
			continue
		var/list/boundingData = boundingBoxes["[direction]"]
		/// basic AABB but only for the Z-axis.
		//if(boundingData[5] > max(startZ,startZ+*pStepZ) || boundingData[6] < min(startZ,startZ+*pStepZ))
		//	continue
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			return TRUE
	return FALSE

/// Indexed by icon-state
/datum/hitboxDatum/atom/polygon/powerCable
	boundingBoxes = list(
		"0-1" = list(BLINE(16,16,16,32)),
		"0-2" = list(BLINE(16,0,16,16)),
		"0-4" = list(BLINE(16,16,32,16)),
		"0-5" = list(BLINE(16,16,32,32)),
		"0-6" = list(BLINE(32,0,16,16)),
		"0-8" = list(BLINE(0,16,16,16)),
		"0-9" = list(BLINE(0,32,16,16)),
		"0-10" = list(BLINE(0,0,16,16)),
		"1-2" = list(BLINE(16,0,16,32)),
		"1-4" = list(BLINE(16,32,20,20),BLINE(20,20,32,16)),
		"1-5" = list(BLINE(16,32,21,25),BLINE(21,25,32,32)),
		"1-6" = list(BLINE(16,32,22,12),BLINE(22,12,32,0)),
		"1-8" = list(BLINE(0,16,13,20),BLINE(13,20,16,32)),
		"1-9" = list(BLINE(0,32,12,25),BLINE(12,25,16,32)),
		"1-10" = list(BLINE(0,0,12,14), BLINE(12,14,16,32)),
		"2-4" = list(BLINE(16,0,19,12), BLINE(19,12,32,16)),
		"2-5" = list(BLINE(16,0,21,19), BLINE(21,19,32,32)),
		"2-6" = list(BLINE(16,0,20,9), BLINE(20,9,32,0)),
		"2-8" = list(BLINE(0,16,13,13), BLINE(13,13,16,0)),
		"2-9" = list(BLINE(0,32,13,17),BLINE(13,17,16,0)),
		"2-10" = list(BLINE(0,0,13,8), BLINE(13,8,16,0)),
		"4-5" = list(BLINE(32,16,25,22),BLINE(25,22,32,32)),
		"4-6" = list(BLINE(32,0,25,11), BLINE(25,11,32,16)),
		"4-8" = list(BLINE(0,16,32,16)),
		"4-9" = list(BLINE(0,32,16,20), BLINE(16,20,32,16)),
		"4-10" = list(BLINE(0,0,14,12), BLINE(14,12,32,16)),
		"5-6" = list(BLINE(31,0,25,16), BLINE(25,16,31,32)),
		"5-8" = list(BLINE(0,16,18,21), BLINE(18,21,32,32)),
		"5-9" = list(BLINE(0,31,16,25), BLINE(16,25,32,31)),
		"5-10" = list(BLINE(0,0,32,32)),
		"6-8" = list(BLINE(0,17,17,13),BLINE(17,13,32,0)),
		"6-9" = list(BLINE(0,32,32,0)),
		"6-10" = list(BLINE(0,1,16,8), BLINE(16,8,32,1)),
		"8-9" = list(BLINE(0,16,8,20), BLINE(8,20,2,32)),
		"8-10" = list(BLINE(0,16,8,13), BLINE(8,13,0,0)),
		"9-10" = list(BLINE(0,0,8,16), BLINE(8,16,0,32)),
		"32-1" = list(BLINE(16,18,16,32)),
		"32-2" = list(BLINE(16,0,16,16)),
		"32-4" = list(BLINE(16,16,32,16)),
		"32-5" = list(BLINE(16,16,32,32)),
		"32-6" = list(BLINE(16,16,32,0)),
		"32-8" = list(BLINE(0,16,16,16)),
		"32-9" = list(BLINE(0,32,16,16)),
		"32-10" = list(BLINE(0,0,16,16)),
		"16-0" = list(BLINE(16,16,16,24))
	)

/datum/hitboxDatum/atom/polygon/powerCable/intersects(atom/owner, ownerDirection, startX, startY, startZ, pStepX, pStepY, pStepZ)
	var/worldX
	var/worldY
	worldX = owner.x * 32
	worldY = owner.y * 32
	for(var/list/boundingData in boundingBoxes[owner.icon_state])
		/// basic AABB but only for the Z-axis.
		//if(boundingData[5] > max(startZ,startZ+*pStepZ) || boundingData[6] < min(startZ,startZ+*pStepZ))
		//	continue
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			return TRUE
	return FALSE

/datum/hitboxDatum/atom/polygon/powerCable/visualize(atom/owner)
	return
	/*
	for(var/list/hitbox in boundingBoxes[owner.icon_state])
		var/icon/Icon = icon('icons/hitbox.dmi', "box")
		var/length = round(DIST_EUCLIDIAN_2D(hitbox[1], hitbox[2], hitbox[3], hitbox[4]))
		Icon.Scale(1, length)
		var/x = (hitbox[3] - hitbox[1])
		var/y = (hitbox[4] - hitbox[2])
		var/angle = ATAN2(y, x) + 180
		var/mutable_appearance/newOverlay = mutable_appearance(Icon, "hitbox")
		newOverlay.color = RANDOM_RGB
		var/matrix/rotation = matrix()
		rotation.Turn(angle)
		newOverlay.transform = rotation
		newOverlay.pixel_x = hitbox[3] - 1
		newOverlay.pixel_y = hitbox[4] - 1
		newOverlay.alpha = 200
		owner.overlays.Add(newOverlay)
	*/

/// Hitboxes are ordered based on center distance.
/datum/hitboxDatum/atom/ordered

/datum/hitboxDatum/atom/ordered/intersects(atom/owner, ownerDirection, startX, startY, startZ, pStepX, pStepY, pStepZ)
	var/worldX
	var/worldY
	var/worldZ
	worldX = owner.x
	worldY = owner.y
	worldZ = owner.z * PPT
	if(owner.atomFlags & AF_HITBOX_OFFSET_BY_ATTACHMENT)
		for(var/atom/thing as anything in owner.attached)
			if(!(thing.attached[owner] & ATFS_SUPPORTER))
				continue
			worldX += thing.x - owner.x
			worldY += thing.y - owner.y
			break
	worldX *= 32
	worldY *= 32
	var/list/relevantHitboxes
	for(var/list/boundingBox in boundingBoxes["[ownerDirection]"])
		relevantHitboxes[boundingBox] = DIST_EUCLIDIAN_2D((boundingBox[1]+boundingBox[3])/2, (boundingBox[2]+boundingBox[4])/2, startX, startY)
	for(var/index in 1 to (length(relevantHitboxes)-1))
		if(relevantHitboxes[index] > relevantHitboxes[index+1])
			relevantHitboxes[index+1] += relevantHitboxes[index]
			relevantHitboxes[index] = relevantHitboxes[index+1] - relevantHitboxes[index]
			relevantHitboxes[index+1] -= relevantHitboxes[index]
			index = max(1, index - 1)
	for(var/list/boundingData in relevantHitboxes)
		if((boundingData[5]+worldZ)> max(startZ,startZ+*pStepZ) && (boundingData[6]+worldZ)> max(startZ,startZ+*pStepZ))
			continue
		if((boundingData[5]+worldZ) < min(startZ,startZ+*pStepZ) && (boundingData[6]+worldZ) < min(startZ,startZ+*pStepZ))
			continue
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[1] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			return TRUE
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[2] + worldY, pStepX, pStepY))
			return TRUE
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[4] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			return TRUE
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[3] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			return TRUE
	return FALSE


/datum/hitboxDatum/mob

/datum/hitboxDatum/mob/New()
	. = ..()
	var/median
	var/volumeSum
	var/calculatedVolume = 0
	if(length(medianLevels))
		return
	medianLevels = list()
	for(var/state in boundingBoxes)
		medianLevels[state] = list()
		for(var/direction in list(NORTH, SOUTH, EAST , WEST))
			median = 0
			volumeSum = 0
			for(var/list/boundingBox in boundingBoxes[state]["[direction]"])
				calculatedVolume = (boundingBox[4] - boundingBox[2]) * (boundingBox[3] - boundingBox[1])
				median += ((boundingBox[5] + boundingBox[6])/2) * calculatedVolume
				volumeSum += calculatedVolume
 			medianLevels[state]["[direction]"] = median / volumeSum



/datum/hitboxDatum/mob/getAimingLevel(atom/shooter, defZone, atom/owner)
	var/mob/living/perceivedOwner = owner
	if(defZone == null || (!(defZone in defZoneToLevel["[perceivedOwner.lying]"])))
		return medianLevels["[perceivedOwner.lying]"]["[owner.dir]"]
	if(defZoneToLevel[defZone] == HBF_USEMEDIAN)
		return medianLevels["[perceivedOwner.lying]"]["[owner.dir]"]
	message_admins("Returned [defZoneToLevel["[perceivedOwner.lying]"][defZone]] for [defZone]")
	return defZoneToLevel["[perceivedOwner.lying]"][defZone]

/datum/hitboxDatum/mob/intersects(atom/owner, ownerDirection, startX, startY, startZ, pStepX, pStepY, pStepZ, pHitFlags)
	var/worldX
	var/worldY
	var/worldZ
	worldX = owner.x * PPT
	worldY = owner.y * PPT
	worldZ = owner.z * PPT
	var/mob/living/perceivedOwner = owner
	for(var/list/boundingData in boundingBoxes["[perceivedOwner.lying]"]["[owner.dir]"])
		if((boundingData[5]+worldZ)> max(startZ,startZ+*pStepZ) && (boundingData[6]+worldZ)> max(startZ,startZ+*pStepZ))
			continue
		if((boundingData[5]+worldZ) < min(startZ,startZ+*pStepZ) && (boundingData[6]+worldZ) < min(startZ,startZ+*pStepZ))
			continue
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[1] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			*pHitFlags = boundingData[7]
			return TRUE
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[2] + worldY, pStepX, pStepY))
			*pHitFlags = boundingData[7]
			return TRUE
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[1] + worldX, boundingData[4] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			*pHitFlags = boundingData[7]
			return TRUE
		if(lineIntersect(startX, startY, startX+*pStepX, startY+*pStepY, boundingData[3] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY, pStepX, pStepY))
			*pHitFlags = boundingData[7]
			return TRUE
	return FALSE

/datum/hitboxDatum/mob/visualize(mob/living/owner)
	for(var/list/hitbox in boundingBoxes["[owner.lying]"]["[owner.dir]"])
		var/icon/Icon = icon('icons/hitbox.dmi', "box")
		var/multX = hitbox[3] - hitbox[1] + 1
		var/multY = hitbox[4] - hitbox[2] + 1
		Icon.Scale(multX, multY)
		var/mutable_appearance/newOverlay = mutable_appearance(Icon, "hitbox")
		newOverlay.color = RANDOM_RGB
		newOverlay.pixel_x = hitbox[1] - 1
		newOverlay.pixel_y = hitbox[2] - 1
		newOverlay.alpha = 200
		owner.overlays.Add(newOverlay)

/datum/hitboxDatum/mob/human
	boundingBoxes = list(
		"0" = list(
			LISTNORTH = list(
				BBOX(11,1,21,8,LEVEL_TURF, LEVEL_TABLE, HB_LEGS), // LEGS
				BBOX(11,9,21,11,LEVEL_TABLE, LEVEL_GROIN, HB_GROIN), // GROIN
				BBOX(9,12,23,20, LEVEL_GROIN, LEVEL_CHEST, HB_CHESTARMS), // CHEST + ARMS
				BBOX(11,12,21,22, LEVEL_GROIN, LEVEL_CHEST, HB_CHESTARMS), // CHEST + ARMS
				BBOX(13,23,19,28, LEVEL_CHEST, LEVEL_HEAD, HB_HEAD) // HEAD
			),
			LISTSOUTH = list(
				BBOX(11,1,21,8,LEVEL_TURF, LEVEL_TABLE, HB_LEGS), // LEGS
				BBOX(11,9,21,11,LEVEL_TABLE, LEVEL_GROIN, HB_GROIN), // GROIN
				BBOX(9,12,23,20, LEVEL_GROIN, LEVEL_CHEST, HB_CHESTARMS), // CHEST + ARMS
				BBOX(11,12,21,22, LEVEL_GROIN, LEVEL_CHEST, HB_CHESTARMS), // CHEST + ARMS
				BBOX(13,23,19,28, LEVEL_CHEST, LEVEL_HEAD, HB_HEAD) // HEAD
			),
			LISTEAST = list(
				BBOX(14,1,19,9, LEVEL_TURF, LEVEL_TABLE, HB_LEGS), // LEGS
				BBOX(14,10,21,12, LEVEL_TABLE,  LEVEL_GROIN, HB_GROIN), // GROIN
				BBOX(13,12,21,22, LEVEL_GROIN , LEVEL_CHEST, HB_CHESTARMS), // ARMS AND CHEST
				BBOX(13,12,20,28, LEVEL_CHEST, LEVEL_HEAD, HB_HEAD) // HEAD
			),
			LISTWEST = list(
				BBOX(14,1,19,9, LEVEL_TURF, LEVEL_TABLE, HB_LEGS), // LEGS
				BBOX(14,10,21,12, LEVEL_TABLE,  LEVEL_GROIN, HB_GROIN), // GROIN
				BBOX(13,12,21,22, LEVEL_GROIN , LEVEL_CHEST, HB_CHESTARMS), // ARMS AND CHEST
				BBOX(13,12,20,28, LEVEL_CHEST, LEVEL_HEAD, HB_HEAD) // HEAD
			)
		),
		"1" = list(
			LISTNORTH = list(
				BBOX(1,11,9,23, LEVEL_TURF, LEVEL_TURF + 1, HB_LEGS),
				BBOX(9,12,11,22, LEVEL_TURF + 1, LEVEL_TURF + 2, HB_GROIN),
				BBOX(12,10,22,24, LEVEL_TURF + 2 , LEVEL_TURF + 3, HB_CHESTARMS),
				BBOX(23,14,28,20, LEVEL_TURF + 3, LEVEL_TURF + 4, HB_HEAD)
			),
			LISTSOUTH = list(
				BBOX(1,11,9,23, LEVEL_TURF, LEVEL_TURF + 1, HB_LEGS),
				BBOX(9,12,11,22, LEVEL_TURF + 1, LEVEL_TURF + 2, HB_GROIN),
				BBOX(12,10,22,24, LEVEL_TURF + 2 , LEVEL_TURF + 3, HB_CHESTARMS),
				BBOX(23,14,28,20, LEVEL_TURF + 3, LEVEL_TURF + 4, HB_HEAD)
			),
			LISTEAST = list(
				BBOX(1,14,10,19, LEVEL_TURF, LEVEL_TURF + 1, HB_LEGS),
				BBOX(9,14,12,20, LEVEL_TURF + 1, LEVEL_TURF + 2 , HB_GROIN),
				BBOX(11,12,23,21, LEVEL_TURF + 2, LEVEL_TURF + 3, HB_CHESTARMS),
				BBOX(24,13,29,20, LEVEL_TURF + 3, LEVEL_TURF + 4, HB_HEAD)
			),
			LISTWEST = list(
				BBOX(1,14,10,19, LEVEL_TURF, LEVEL_TURF + 1, HB_LEGS),
				BBOX(9,14,12,20, LEVEL_TURF + 1, LEVEL_TURF + 2 , HB_GROIN),
				BBOX(11,12,23,21, LEVEL_TURF + 2, LEVEL_TURF + 3, HB_CHESTARMS),
				BBOX(24,13,29,20, LEVEL_TURF + 3, LEVEL_TURF + 4, HB_HEAD)
			)
		)
	)
	defZoneToLevel = list(
		"0" = list(
			BP_EYES = (LEVEL_HEAD + LEVEL_CHEST)/2,
			BP_MOUTH = (LEVEL_HEAD + LEVEL_CHEST)/2,
			BP_HEAD = (LEVEL_HEAD + LEVEL_CHEST)/2,
			BP_CHEST = (LEVEL_CHEST + LEVEL_GROIN)/2,
			BP_R_ARM = (LEVEL_CHEST + LEVEL_GROIN)/2,
			BP_L_ARM = (LEVEL_CHEST + LEVEL_GROIN)/2,
			BP_GROIN = (LEVEL_GROIN + LEVEL_TABLE)/2,
			BP_L_LEG = (LEVEL_TURF + LEVEL_TABLE)/2,
			BP_R_LEG = (LEVEL_TURF + LEVEL_TABLE)/2
		),
		"1" = list(
			BP_EYES = (LEVEL_TURF + 3 + LEVEL_TURF + 4)/2,
			BP_MOUTH = (LEVEL_TURF + 3 + LEVEL_TURF + 4)/2,
			BP_HEAD = (LEVEL_TURF + 3 + LEVEL_TURF + 4)/2,
			BP_CHEST = (LEVEL_TURF + 2 + LEVEL_TURF + 1)/2,
			BP_R_ARM = (LEVEL_TURF + 2 + LEVEL_TURF + 1)/2,
			BP_L_ARM = (LEVEL_TURF + 2 + LEVEL_TURF + 1)/2,
			BP_GROIN = (LEVEL_TURF + 1 + LEVEL_TURF + 2)/2,
			BP_L_LEG = (LEVEL_TURF + 1 + LEVEL_TURF)/2,
			BP_R_LEG = (LEVEL_TURF + 1 + LEVEL_TURF)/2
		)
	)






