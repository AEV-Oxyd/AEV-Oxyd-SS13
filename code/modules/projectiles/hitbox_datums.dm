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

/datum/hitboxDatum/atom/New()
	. = ..()
	var/median
	var/volumeSum
	var/calculatedVolume = 0
	for(var/direction in list(NORTH, SOUTH, EAST , WEST))
		median = 0
		volumeSum = 0
		for(var/list/boundingBox in boundingBoxes["[direction]"])
			calculatedVolume = (boundingBox[4] - boundingBox[2]) * (boundingBox[3] - boundingBox[1])
			median += ((boundingBox[5] + boundingBox[6])/2) * calculatedVolume
			volumeSum += calculatedVolume
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
// each corner has 8 possible states , all of them have 4 directions , so this is 4 x 8 x 4 aka 256 permutations.
// some of this could be cut down with some smart flipping ,but for some cases it doesn't work.

/datum/hitboxDatum/atom/table
	boundingBoxes = list(
		1 = list(
			1 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			2 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			3 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			4 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			5 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			6 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			7 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			8 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			)
		),
		2 = list(
			1 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			2 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			3 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			4 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			5 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			6 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			7 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			8 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			)
		),
		3 = list(
			1 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			2 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			3 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			4 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			5 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			6 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			7 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			8 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			)
		),
		4 = list(
			1 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			2 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			3 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			4 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			5 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			6 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			7 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			),
			8 = list(
				LISTNORTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTSOUTH = list(BBOX(0,0,0,0,0,0,null)),
				LISTEAST = list(BBOX(0,0,0,0,0,0,null)),
				LISTWEST = list(BBOX(0,0,0,0,0,0,null))
			)
		)
	)

/datum/hitboxDatum/atom/table/New()
	. = ..()
	var/median
	var/volumeSum
	var/calculatedVolume = 0
	for(var/direction in list(NORTH, SOUTH, EAST , WEST))
		median = 0
		volumeSum = 0
		for(var/list/boundingBox in boundingBoxes["[direction]"])
			calculatedVolume = (boundingBox[4] - boundingBox[2]) * (boundingBox[3] - boundingBox[1])
			median += ((boundingBox[5] + boundingBox[6])/2) * calculatedVolume
			volumeSum += calculatedVolume
		medianLevels["[direction]"] = median / volumeSum

/datum/hitboxDatum/atom/table/getAimingLevel(atom/shooter, defZone, atom/owner)
	if(defZone == null || (!(defZone in defZoneToLevel)))
		return medianLevels["[owner.dir]"]
	if(defZoneToLevel[defZone] == HBF_USEMEDIAN)
		return medianLevels["[owner.dir]"]
	message_admins("Returned [defZoneToLevel[defZone]] for [defZone]")
	return defZoneToLevel[defZone]

	/// this can be optimized further by making the calculations not make a new list , and instead be added when checking line intersection - SPCR 2024
/datum/hitboxDatum/atom/table/intersects(list/lineData,ownerDirection, turf/incomingFrom, atom/owner, list/arguments)
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

/datum/hitboxDatum/mob

/datum/hitboxDatum/mob/New()
	. = ..()
	var/median
	var/volumeSum
	var/calculatedVolume = 0
	for(var/state in boundingBoxes)
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






