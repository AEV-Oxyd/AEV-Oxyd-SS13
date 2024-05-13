


/datum/hitboxDatum
	var/list/boundingBoxes = list()
	/// global offsets , applied to all bounding boxes equally
	var/offsetX = 0
	var/offsetY = 0
	var/atom/owner

/// this can be optimized further by making the calculations not make a new list , and instead be added when checking line intersection - SPCR 2024
/datum/hitboxDatum/proc/intersects(list/lineData,ownerDirection, turf/incomingFrom, atom/owner)
	var/global/worldX
	var/global/worldY
	worldX = owner.x * 32
	worldY = owner.y * 32
	for(var/list/boundingData in boundingBoxes)
		if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[2] + worldY, boundingData[1] + worldX, boundingData[4] + worldY)))
			return TRUE
		if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[2] + worldY)))
			return TRUE
		if(lineIntersect(lineData, list(boundingData[1] + worldX, boundingData[4] + worldY, boundingData[3] + worldX, boundingData[4] + worldY)))
			return TRUE
		if(lineIntersect(lineData, list(boundingData[3] + worldX, boundingData[2] + worldY, boundingData[3] + worldX, boundingData[4] + worldY)))
			return TRUE
	return FALSE

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


/datum/hitboxDatum/proc/visualize()
	var/list/availableColors = list(COLOR_RED, COLOR_AMBER, COLOR_BLUE, COLOR_ORANGE, COLOR_CYAN, COLOR_TITANIUM, COLOR_YELLOW, COLOR_BROWN, COLOR_VIOLET, COLOR_PINK, COLOR_GRAY, COLOR_ASSEMBLY_BEIGE, COLOR_ASSEMBLY_GREEN, COLOR_ASSEMBLY_LBLUE, COLOR_LIGHTING_BLUE_DARK)
	var/chosenColor = pick(availableColors)
	for(var/list/hitbox in boundingBoxes)
		var/icon/Icon = icon('icons/hitbox.dmi', "box")
		var/multX = hitbox[3] - hitbox[1]
		var/multY = hitbox[4] - hitbox[2]
		Icon.Scale(multX, multY)
		var/mutable_appearance/newOverlay = mutable_appearance(Icon, "hitbox")
		newOverlay.color = chosenColor
		availableColors.Remove(chosenColor)
		chosenColor = pick(availableColors)
		newOverlay.pixel_x = hitbox[1]
		newOverlay.pixel_y = hitbox[2]
		owner.overlays.Add(newOverlay)










