#define BBOX(x1,y1,x2,y2,offsetX,offsetY) list(x1,y1,x2,y2,offsetX,offsetY)
#define BLINE(x1,y1,x2,y2) list(x1,y1,x2,y2)


/datum/hitboxDatum
	var/list/boundingBoxes = list()

/datum/hitboxDatum/proc/intersects(list/lineData,ownerDirection)
	for(var/list/boundingData in boundingBoxes)



