#define BBOX(x1,y1,x2,y2,offsetX,offsetY) list(x1,y1,x2,y2,offsetX,offsetY)
#define BLINE(x1,y1,x2,y2) list(x1,y1,x2,y2)
#define TRIGSLOPE(x1,y1,x2,y2) ((y2-y1)/(x2-x1))


/datum/hitboxDatum
	var/list/boundingBoxes = list()
	/// global offsets , applied to all bounding boxes equally
	var/offsetX = 0
	var/offsetY = 0

/datum/hitboxDatum/proc/intersects(list/lineData,ownerDirection)
	var/global/lineSlope
	/// Left Top , Left Bottom,  Right Top , Right Bottom
	var/list/boxSlopes = list(0,0,0,0)
	var/global/minSlope
	var/global/maxSlope
	var/global/valid
	lineSlope = TRIGSLOPE(lineData[3], lineData[4], lineData[1],lineData[2])
	minSlope = 99999
	maxSlope = -99999
	valid = FALSE
	message_admins("lineData: [lineData[1]], [lineData[2]], [lineData[3]], [lineData[4]], slope : [lineSlope]")
	for(var/list/boundingData in boundingBoxes)
		message_admins("boxData: [boundingData[1]], [boundingData[2]], [boundingData[3]], [boundingData[4]]")
		boxSlopes[1]= TRIGSLOPE(boundingData[1], boundingData[4], lineData[1], lineData[2])
		boxSlopes[2]= TRIGSLOPE(boundingData[1], boundingData[2], lineData[1], lineData[2])
		boxSlopes[3] = TRIGSLOPE(boundingData[3], boundingData[4], lineData[1], lineData[2])
		boxSlopes[4] = TRIGSLOPE(boundingData[3], boundingData[2], lineData[1], lineData[2])
		for(var/slope in boxSlopes)
			if(minSlope > slope)
				minSlope = slope
			if(maxSlope < slope)
				maxSlope = slope
		if(!(lineSlope < minSlope || lineSlope > maxSlope))
			// checking X-axis
			valid = max(lineData[1], lineData[3]) >= min(boundingData[1], boundingData[3])
			if(valid == 0)
				message_admins("Failed at X-axis 1")
				continue
			valid &= min(lineData[1], lineData[3]) <= max(boundingData[1], boundingData[3])
			if(valid == 0)
				message_admins("Failed at X-axis 2")
				continue
			// checking Y-axis
			valid &= max(lineData[2], lineData[4]) >= min(boundingData[2], boundingData[4])
			if(valid == 0)
				message_admins("Failed at Y-axis 1")
				continue
			valid &= min(lineData[2], lineData[4]) <= max(boundingData[2], boundingData[4])
			if(valid == 0)
				message_admins("Failed at Y-axis 2")
				continue
		else
			message_admins("Failed at slope check, [lineSlope], [minSlope], [maxSlope]")
		if(!valid)
			continue
		return TRUE
	return FALSE






