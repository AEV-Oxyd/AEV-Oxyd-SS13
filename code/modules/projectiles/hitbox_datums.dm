#define BBOX(x1,y1,x2,y2,offsetX,offsetY) list(x1,y1,x2,y2,offsetX,offsetY)
#define BLINE(x1,y1,x2,y2) list(x1,y1,x2,y2)
#define TRIGSLOPE(x1,y1,x2,y2) ((y2-y1)/(x2-x1))


/datum/hitboxDatum
	var/list/boundingBoxes = list()
	/// global offsets , applied to all bounding boxes equally
	var/offsetX = 0
	var/offsetY = 0

/datum/hitboxDatum/proc/intersects(list/lineData,ownerDirection)
	var/lineSlope = TRIGSLOPE(lineData[1], lineData[2], lineData[3],lineData[4])
	var/boxSlopeLeft
	var/boxSlopeRight
	var/valid = FALSE
	for(var/list/boundingData in boundingBoxes)
		boxSlopeLeft = TRIGSLOPE(boundingData[1], boundingData[2], lineData[1], lineData[2])
		boxSlopeRight= TRIGSLOPE(boundingData[3], boundingData[4], lineData[1], lineData[2])
		// failed heuristic. Skip
		if(!int_range(lineSlope, boxSlopeLeft, boxSlopeRight))
			continue
		// checking X-axis
		valid = max(lineData[1], lineData[3]) > min(boundingData[1], boundingData[3])
		valid &= min(lineData[1], lineData[3]) < max(boundingData[1], boundingData[3])
		// checking Y-axis
		valid &= max(lineData[2], lineData[4]) > min(boundingData[2], boundingData[4])
		valid &= min(lineData[2], lineData[4]) < max(boundingData[2], boundingData[4])
		if(!valid)
			continue
		return TRUE
	return FALSE






