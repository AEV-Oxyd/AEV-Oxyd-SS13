/proc/create_all_lighting_overlays()
	for(var/zlevel = 1 to world.maxz)
		message_admins("Created lightning overlay for zlevel [zlevel]")
		create_lighting_overlays_zlevel(zlevel)

/proc/create_lighting_overlays_zlevel(var/zlevel)
	ASSERT(zlevel)

	for(var/turf/T in block(locate(1, 1, zlevel), locate(world.maxx, world.maxy, zlevel)))
		if (!T.dynamic_lighting)
			continue

		var/area/A = T.loc
		if (!A.dynamic_lighting)
			continue

		new /atom/movable/lighting_overlay(T, TRUE)
		if (!T.lighting_corners_initialised)
			T.generate_missing_corners()
