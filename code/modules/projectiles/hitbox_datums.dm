#define BBOX(x1,y1,x2,y2,offsetX,offsetY) list(x1,y1,x2,y2,offsetX,offsetY)
#define BLINE(x1,y1,x2,y2) list(x1,y1,x2,y2)
#define TRIGSLOPE(x1,y1,x2,y2) ((y2-y1)/(x2-x1))


/datum/hitboxDatum
	var/list/boundingBoxes = list()
	/// global offsets , applied to all bounding boxes equally
	var/offsetX = 0
	var/offsetY = 0
	var/atom/owner

/datum/hitboxDatum/proc/intersects(list/lineData,ownerDirection, turf/incomingFrom, atom/owner)
	message_admins("LINEDATA: FirstPoint ([lineData[1]], [lineData[2]]) SecondPoint ([lineData[3]], [lineData[4]])]")
	for(var/list/boundingData in boundingBoxes)
		if(lineIntersect(lineData, list(boundingData[1] + owner.x * 32, boundingData[2] + owner.y * 32, boundingData[1] + owner.x * 32, boundingData[4])))
			return TRUE
		if(lineIntersect(lineData, list(boundingData[1] + owner.x * 32, boundingData[2], boundingData[3] + owner.x * 32, boundingData[2])))
			return TRUE
		if(lineIntersect(lineData, list(boundingData[1] + owner.x * 32, boundingData[4], boundingData[3] + owner.x * 32, boundingData[4])))
			return TRUE
		if(lineIntersect(lineData, list(boundingData[3] + owner.x * 32, boundingData[2], boundingData[3] + owner.x * 32, boundingData[4])))
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








