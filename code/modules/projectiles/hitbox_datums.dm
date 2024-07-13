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
/datum/hitboxDatum/proc/intersects(list/lineData,ownerDirection, turf/incomingFrom, atom/owner, list/arguments)

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
// Based off the script above.
/datum/hitboxDatum/proc/lineIntersect(list/firstLine , list/secondLine)
	var/global/firstRatio
	var/global/secondRatio
	firstRatio = ((secondLine[3] - secondLine[1]) * (firstLine[2] - secondLine[2]) - (secondLine[4] - secondLine[2]) * (firstLine[1] - secondLine[1]))
	firstRatio /= ((secondLine[4] - secondLine[2]) * (firstLine[3] - firstLine[1]) - (secondLine[3] - secondLine[1]) * (firstLine[4] - firstLine[2]))
	secondRatio = ((firstLine[3] - firstLine[1]) * (firstLine[2] - secondLine[2]) - (firstLine[4] - firstLine[2]) * (firstLine[1] - secondLine[1]))
	secondRatio /= ((secondLine[4] - secondLine[2]) * (firstLine[3] - firstLine[1]) - (secondLine[3] - secondLine[1]) * (firstLine[4] - firstLine[2]))
	if(firstRatio >= 0 && firstRatio <= 1 && secondRatio >= 0 && secondRatio <= 1)
		//return list(firstLine[1] + firstRatio * (firstLine[3] - firstLine[1]), firstLine[2] + firstRatio * (firstLine[4] - firstLine[2]))
		return TRUE
	else
		return FALSE


/datum/hitboxDatum/proc/visualize(atom/owner)
	var/list/availableColors = list(COLOR_RED, COLOR_AMBER, COLOR_BLUE, COLOR_ORANGE, COLOR_CYAN, COLOR_YELLOW, COLOR_BROWN, COLOR_VIOLET, COLOR_PINK, COLOR_ASSEMBLY_BEIGE, COLOR_ASSEMBLY_GREEN, COLOR_ASSEMBLY_LBLUE, COLOR_LIGHTING_BLUE_DARK)
	var/chosenColor = pick_n_take(availableColors)
	for(var/list/hitbox in boundingBoxes[num2text(owner.dir)])
		var/icon/Icon = icon('icons/hitbox.dmi', "box")
		var/multX = hitbox[3] - hitbox[1] + 1
		var/multY = hitbox[4] - hitbox[2] + 1
		Icon.Scale(multX, multY)
		var/mutable_appearance/newOverlay = mutable_appearance(Icon, "hitbox")
		newOverlay.color = chosenColor
		chosenColor = pick_n_take(availableColors)
		newOverlay.pixel_x = hitbox[1] - 1
		newOverlay.pixel_y = hitbox[2] - 1
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
/datum/hitboxDatum/atom/intersects(list/lineData,ownerDirection, turf/incomingFrom, atom/owner, list/arguments)
	var/global/worldX
	var/global/worldY
	worldX = owner.x * 32
	worldY = owner.y * 32
	for(var/list/boundingData in boundingBoxes["[owner.dir]"])
		/// basic AABB but only for the Z-axis.
		if(boundingData[5] > max(lineData[5],lineData[6]) || boundingData[6] < min(lineData[6],lineData[5]))
			continue
		if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[2] + worldY, boundingData[1] + worldX, boundingData[4] + worldY)))
			arguments[3] = boundingData[7]
			return TRUE
		if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[2] + worldY)))
			arguments[3] = boundingData[7]
			return TRUE
		if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[4] + worldY, boundingData[3] + worldX, boundingData[4] + worldY)))
			arguments[3] = boundingData[7]
			return TRUE
		if(lineIntersect(lineData, list(boundingData[3] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY)))
			arguments[3] = boundingData[7]
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

/// this can be optimized further by making the calculations not make a new list , and instead be added when checking line intersection - SPCR 2024
/datum/hitboxDatum/atom/table/intersects(list/lineData,ownerDirection, turf/incomingFrom, obj/structure/table/owner, list/arguments)
	var/global/worldX
	var/global/worldY
	worldX = owner.x * 32
	worldY = owner.y * 32
	var/list/boundingList
	for(var/i = 1 to 4)
		// 1<<(i-1) , clever way to convert from index to direction
		// i=1 ==> north
		// i=2 ==> south
		// i=3 ==> east
		// i=4 ==> west
		// i dont get why owner connections is text.. but it is what it is
		var/direct = "[(1<<(i-1))]"
		var/conn = text2num(owner.connections[i])
		boundingList = boundingBoxes[text2num(owner.connections[i])+1]["[(1<<(i-1))]"]
		for(var/list/boundingData in boundingList)
			/// basic AABB but only for the Z-axis.
			if(boundingData[5] > max(lineData[5],lineData[6]) && boundingData[6] > min(lineData[6],lineData[5]))
				continue
			if(boundingData[5] < max(lineData[5], lineData[6]) && boundingData[6] < min(lineData[6],lineData[5]))
				continue
			if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[2] + worldY, boundingData[1] + worldX, boundingData[4] + worldY)))
				arguments[3] = boundingData[7]
				return TRUE
			if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[2] + worldY)))
				arguments[3] = boundingData[7]
				return TRUE
			if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[4] + worldY, boundingData[3] + worldX, boundingData[4] + worldY)))
				arguments[3] = boundingData[7]
				return TRUE
			if(lineIntersect(lineData, list(boundingData[3] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY)))
				arguments[3] = boundingData[7]
				return TRUE
	return FALSE

/datum/hitboxDatum/atom/fixtureLightTube
	boundingBoxes = list(
		LISTNORTH = list(BBOX(4,29,29,32,LEVEL_HEAD-0.1,LEVEL_HEAD+0.1,null)),
		LISTSOUTH = list(BBOX(4,1,29,4,LEVEL_HEAD-0.1,LEVEL_HEAD+0.1,null)),
		LISTEAST = list(BBOX(29,4,32,29,LEVEL_HEAD-0.1,LEVEL_HEAD+0.1,null)),
		LISTWEST = list(BBOX(1,4,4,29,LEVEL_HEAD-0.1,LEVEL_HEAD+0.1,null))
	)

/datum/hitboxDatum/atom/fixtureBulb
	boundingBoxes = list(
		LISTNORTH = list(BBOX(14,25,19,32,LEVEL_HEAD-0.1,LEVEL_HEAD+0.1,null)),
		LISTSOUTH = list(BBOX(14,1,20,8,LEVEL_HEAD-0.1,LEVEL_HEAD+0.1,null)),
		LISTEAST = list(BBOX(25,14,32,19,LEVEL_HEAD-0.1,LEVEL_HEAD+0.1,null)),
		LISTWEST = list(BBOX(1,14,8,19,LEVEL_HEAD-0.1,LEVEL_HEAD+0.1,null))
	)

/datum/hitboxDatum/atom/fireAlarm
	boundingBoxes = list(
		LISTNORTH = list(BBOX(13,10,20,22,LEVEL_CHEST-0.1,LEVEL_CHEST+0.1,null)),
		LISTSOUTH = list(BBOX(13,11,20,23,LEVEL_CHEST-0.1,LEVEL_CHEST+0.1,null)),
		LISTEAST = list(BBOX(10,13,22,20,LEVEL_CHEST-0.1,LEVEL_CHEST+0.1,null)),
		LISTWEST = list(BBOX(11,13,23,20,LEVEL_CHEST-0.1,LEVEL_CHEST+0.1,null))
	)

/datum/hitboxDatum/atom/airAlarm
	boundingBoxes = list(
		LISTNORTH = list(BBOX(8,10,24,23,LEVEL_CHEST-0.1,LEVEL_CHEST+0.2,null)),
		LISTSOUTH = list(BBOX(8,10,24,23,LEVEL_CHEST-0.1,LEVEL_CHEST+0.2,null)),
		LISTEAST = list(BBOX(10,8,23,24,LEVEL_CHEST-0.1,LEVEL_CHEST+0.2,null)),
		LISTWEST = list(BBOX(10,9,23,25,LEVEL_CHEST-0.1,LEVEL_CHEST+0.2,null))
	)



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

/datum/hitboxDatum/mob/intersects(list/lineData, ownerDirection, turf/incomingFrom, atom/owner, list/arguments)
	. = ..()
	var/global/worldX
	var/global/worldY
	worldX = owner.x * 32
	worldY = owner.y * 32
	var/mob/living/perceivedOwner = owner
	for(var/list/boundingData in boundingBoxes["[perceivedOwner.lying]"]["[owner.dir]"])
		/// basic AABB but only for the Z-axis.
		if(boundingData[5] > max(lineData[5],lineData[6]) || boundingData[6] < min(lineData[6],lineData[5]))
			continue
		if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[2] + worldY, boundingData[1] + worldX, boundingData[4] + worldY)))
			arguments[3] = boundingData[7]
			return TRUE
		if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[2] + worldY)))
			arguments[3] = boundingData[7]
			return TRUE
		if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[4] + worldY, boundingData[3] + worldX, boundingData[4] + worldY)))
			arguments[3] = boundingData[7]
			return TRUE
		if(lineIntersect(lineData, list(boundingData[3] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY)))
			arguments[3] = boundingData[7]
			return TRUE
	return FALSE

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
				BBOX(1,11,9,23, LEVEL_TURF, LEVEL_TURF + 0.1, HB_LEGS),
				BBOX(9,12,11,22, LEVEL_TURF + 0.1, LEVEL_TURF + 0.2, HB_GROIN),
				BBOX(12,10,22,24, LEVEL_TURF + 0.2 , LEVEL_TURF + 0.3, HB_CHESTARMS),
				BBOX(23,14,28,20, LEVEL_TURF + 0.3, LEVEL_TURF + 0.4, HB_HEAD)
			),
			LISTSOUTH = list(
				BBOX(1,11,9,23, LEVEL_TURF, LEVEL_TURF + 0.1, HB_LEGS),
				BBOX(9,12,11,22, LEVEL_TURF + 0.1, LEVEL_TURF + 0.2, HB_GROIN),
				BBOX(12,10,22,24, LEVEL_TURF + 0.2 , LEVEL_TURF + 0.3, HB_CHESTARMS),
				BBOX(23,14,28,20, LEVEL_TURF + 0.3, LEVEL_TURF + 0.4, HB_HEAD)
			),
			LISTEAST = list(
				BBOX(1,14,10,19, LEVEL_TURF, LEVEL_TURF + 0.1, HB_LEGS),
				BBOX(9,14,12,20, LEVEL_TURF + 0.1, LEVEL_TURF + 0.2 , HB_GROIN),
				BBOX(11,12,23,21, LEVEL_TURF + 0.2, LEVEL_TURF + 0.3, HB_CHESTARMS),
				BBOX(24,13,29,20, LEVEL_TURF + 0.3, LEVEL_TURF + 0.4, HB_HEAD)
			),
			LISTWEST = list(
				BBOX(1,14,10,19, LEVEL_TURF, LEVEL_TURF + 0.1, HB_LEGS),
				BBOX(9,14,12,20, LEVEL_TURF + 0.1, LEVEL_TURF + 0.2 , HB_GROIN),
				BBOX(11,12,23,21, LEVEL_TURF + 0.2, LEVEL_TURF + 0.3, HB_CHESTARMS),
				BBOX(24,13,29,20, LEVEL_TURF + 0.3, LEVEL_TURF + 0.4, HB_HEAD)
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
			BP_EYES = (LEVEL_TURF + 0.3 + LEVEL_TURF + 0.4)/2,
			BP_MOUTH = (LEVEL_TURF + 0.3 + LEVEL_TURF + 0.4)/2,
			BP_HEAD = (LEVEL_TURF + 0.3 + LEVEL_TURF + 0.4)/2,
			BP_CHEST = (LEVEL_TURF + 0.2 + LEVEL_TURF + 0.1)/2,
			BP_R_ARM = (LEVEL_TURF + 0.2 + LEVEL_TURF + 0.1)/2,
			BP_L_ARM = (LEVEL_TURF + 0.2 + LEVEL_TURF + 0.1)/2,
			BP_GROIN = (LEVEL_TURF + 0.1 + LEVEL_TURF + 0.2)/2,
			BP_L_LEG = (LEVEL_TURF + 0.1 + LEVEL_TURF)/2,
			BP_R_LEG = (LEVEL_TURF + 0.1 + LEVEL_TURF)/2
		)
	)






