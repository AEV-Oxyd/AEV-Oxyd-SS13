
GLOBAL_VAR_INIT(Debug,0)
/atom/movable
	layer = OBJ_LAYER
	var/last_move
	var/anchored = FALSE
	// var/elevation = 2    - not used anywhere
	var/move_speed = 10
	var/l_move_time = 1
	var/m_flag = 1
	var/throwing = 0
	var/thrower
	var/turf/throw_source
	var/throw_speed = 2
	var/throw_range = 7
	var/moved_recently = 0
	var/obj/item/grab/grabbedBy
	/// Holds the hitbox datum if theres any
	var/datum/hitboxDatum/hitbox
	var/item_state // Used to specify the item state for the on-mob overlays.
	var/inertia_dir = 0
	var/can_anchor = TRUE

	//spawn_values
	var/price_tag = 0 // The item price in credits. atom/movable so we can also assign a price to animals and other things.
	var/surplus_tag = FALSE //If true, attempting to export this will net you a greatly reduced amount of credits, but we don't want to affect the actual price tag for selling to others.
	var/spawn_tags
	var/rarity_value = 1 //min:1
	var/spawn_frequency = 0 //min:0
	var/accompanying_object	// path or text "obj/item,/obj/item/device". This object will spawn alongside (in turf of) the spawned atom.
	var/prob_aditional_object = 100 // Probability for the accompanying_object to spawn.
	var/spawn_blacklisted = FALSE // Generally for niche objects, atoms blacklisted can spawn if enabled by spawner. Examples include exoplanet loot tables you don't want spawning within the player starting area.
	var/bad_type // Use path Ex:(bad_type = obj/item). Generally for abstract code objects, atoms with a set bad_type can never be selected by spawner. Examples include parent objects which should only exist within the code, or deployable embedded items.

/atom/movable/Del()
	if(isnull(gc_destroyed) && loc)
		testing("GC: -- [type] was deleted via del() rather than qdel() --")
		CRASH("GC: -- [type] was deleted via del() rather than qdel() --") // stick a stack trace in the runtime logs
//	else if(isnull(gcDestroyed))
//		testing("GC: [type] was deleted via GC without qdel()") //Not really a huge issue but from now on, please qdel()
//	else
//		testing("GC: [type] was deleted via GC with qdel()")
	..()

/atom/movable/getAimingLevel(atom/shooter, defZone)
	if(hitbox)
		return hitbox.getAimingLevel(shooter, defZone, src)
	else
		return ..()

/atom/movable/Destroy()
	var/turf/T = loc
	if(opacity && istype(T))
		set_opacity(FALSE)
	if(LAZYLEN(movement_handlers) && !ispath(movement_handlers[1]))
		QDEL_LIST(movement_handlers)
	if(grabbedBy)
		QDEL_NULL(grabbedBy)
	for(var/atom/movable/AM in contents)
		qdel(AM)

	. = ..()

	if(loc)
		loc.handle_atom_del(src)
	forceMove(null)

/atom/movable/Bump(var/atom/A, yes)
	if(src.throwing)
		src.throw_impact(A)
		src.throwing = 0


	if (A && yes)
		A.last_bumped = world.time
		A.Bumped(src)
	return ..()

/atom/movable/proc/entered_with_container(var/atom/old_loc)
	return

/atom/movable/Initialize()
	hitbox = getHitbox(hitbox)
	. = ..()


// Gets the top-atom that contains us, doesn't care about how deeply nested a item is
// If stopType is defined , it will stop at the first object that is the type of stopType
/atom/proc/getContainingAtom(stopType = null)
	var/atom/checking = src
	while(!isturf(checking.loc) && !isnull(checking.loc) && !isarea(checking.loc))
		if(stopType && istype(checking, stopType))
			return checking
		checking = checking.loc
	return checking

/// This proc is pasted directly into critical areas that get called very frequently to save on proc calling time
/// Search all instances where this proc is used by searching the following text #TAG_RECALCWEIGHT
/atom/proc/recalculateWeights(weightValue, caller)
	var/oldWeight = weight
	weight += weightValue
	var/atom/location = loc
	/// apply this to turfs too for funny sheninigans
	while(!isarea(location) && location)
	/// avoid a extra operation. just add the difference
		location.weight += (weight - oldWeight)
		//if(ishuman(caller) || ishuman(src) || ishuman(location) || istype(caller, /obj/item/organ) || istype(src, /obj/item/organ))
		//	message_admins("Added [weight - oldWeight] to [location],LocWeight=[location.weight]|ItemWeight=[weight]|ItemOldWeight=[oldWeight]| to [src] from [caller](\ref[caller]) (call: [callcount] # [itercount])")
		location = location.loc

/// Recursive proc , will go down to all things it has and force them to update and then force updates to anything that contains it
/atom/proc/updateWeights(callRecalc = TRUE)
	var/change = initial(weight)
	for(var/atom/thing in contents)
		thing.updateWeights(FALSE)
		change += thing.weight
	if(callRecalc && change != weight)
		recalculateWeights(change - weight)

/atom/proc/updateWeightsDebug()
	message_admins("weight before update - [weight]")
	typeWeights()
	message_admins("updating")
	updateWeights(TRUE)
	message_admins("weight after update [weight]" )

/atom/proc/typeWeights(spaces = 0)
	var/buffer = "-"
	for(var/i = 0, i < spaces, i++)
		buffer = buffer + "-"
	message_admins("[buffer] Mass of [src] - [weight]")
	for(var/atom/thing in contents)
		thing.typeWeights(spaces + 1)

/atom/movable/proc/forceMove(atom/destination, var/special_event, glide_size_override=0, initiator = null)
	if(loc == destination)
		return FALSE

	if (glide_size_override)
		set_glide_size(glide_size_override)

	var/is_origin_turf = isturf(loc)
	var/is_destination_turf = isturf(destination)
	// It is a new area if:
	//  Both the origin and destination are turfs with different areas.
	//  When either origin or destination is a turf and the other is not.
	var/is_new_area = (is_origin_turf ^ is_destination_turf) || (is_origin_turf && is_destination_turf && loc.loc != destination.loc)

	var/atom/origin = loc



	loc = destination

	if(origin)
		origin.Exited(src, destination)
		origin.recalculateWeights(-weight, src)
		if(is_origin_turf)
			for(var/atom/movable/AM in origin)
				AM.Uncrossed(src)
			if(is_new_area && is_origin_turf)
				origin.loc.Exited(src, destination)

	if(destination)
		destination.Entered(src, origin, special_event)
		destination.recalculateWeights(weight, src)
		if(is_destination_turf) // If we're entering a turf, cross all movable atoms
			for(var/atom/movable/AM in loc)
				if(AM != src)
					AM.Crossed(src)
			if(is_new_area && is_destination_turf)
				destination.loc.Entered(src, origin)

	SEND_SIGNAL(src, COMSIG_MOVABLE_MOVED, origin, loc, initiator)
	if(origin && destination)
		if(get_z(origin) != get_z(destination))
			SEND_SIGNAL(src, COMSIG_MOVABLE_Z_CHANGED, get_z(origin) , get_z(destination), initiator)
			update_plane()
		else if(!is_origin_turf)
			update_plane()
	else if(destination)
		update_plane()

	// Container change
	if(origin != destination && !(is_origin_turf && is_destination_turf))
		var/newContainer = getContainingAtom()
		var/oldContainer
		if(is_origin_turf || origin == null)
			// We are our own top-most container
			oldContainer = src
		else
			oldContainer = origin.getContainingAtom()

		if(newContainer != oldContainer)
			SEND_SIGNAL(src, COMSIG_ATOM_CONTAINERED, newContainer , oldContainer)
	/*
	// Only update plane if we're located on map
	if(is_destination_turf)
		// if we wasn't on map OR our Z coord was changed
		if(!is_origin_turf || (get_z(loc) != get_z(origin)) )
			update_plane()
	*/
	if(!loc)
		GLOB.moved_event.raise_event(src, origin, null)


	return TRUE


//called when src is thrown into hit_atom
/atom/movable/proc/throw_impact(atom/hit_atom, var/speed)
	if(isliving(hit_atom))
		var/mob/living/M = hit_atom
		M.hitby(src,speed)

	else if(isobj(hit_atom))
		var/obj/O = hit_atom
		if(!O.anchored)
			step(O, src.last_move)
		O.hitby(src,speed)

	else if(isturf(hit_atom))
		src.throwing = 0
		var/turf/T = hit_atom
		if(T.density)
			step(src, turn(src.last_move, 180))
			if(isliving(src))
				var/mob/living/M = src
				M.turf_collision(T, speed)

//decided whether a movable atom being thrown can pass through the turf it is in.
/atom/movable/proc/hit_check(var/speed)
	if(src.throwing)
		for(var/atom/A in get_turf(src))
			if(A == src) continue
			if(isliving(A))
				if(A:lying) continue
				//if(SSthrowing.throwing_queue[src][I_THROWNTIME] > world.time - 1 SECONDS && thrower == A) continue
				src.throw_impact(A,speed)
			if(isobj(A))
				if(A.density && !A.throwpass)	// **TODO: Better behaviour for windows which are dense, but shouldn't always stop movement
					src.throw_impact(A,speed)

/*
#define I_TARGET 1 /// Index for target
#define I_SPEED 2 /// Index for speed
#define I_RANGE 3 /// Index for range
#define I_MOVED 4 /// Index for amount of turfs we alreathrowing_queue[thing][I_DY] moved by
#define I_DIST_X 5
#define I_DIST_Y 6
#define I_DX 7 // The bias for the X-axis
#define I_DY 8 // The bias for the Y-axis
#define I_ERROR 9 // Calculation error accumulated so far
#define I_TURF_CLICKED 10
#define I_THROWFLAGS 11 // pass_flags for the thrown obj
12 is for initial throw speed
*/


/atom/movable/proc/throw_at(atom/target, range, speed, thrower, throwflags)
	if(!target || range < 1 || speed < 0)
		return FALSE
	var/ref = SSthrowing.throwing_queue[src]
	// remove old throwing entry
	if(ref)
		SSthrowing.throwing_queue.Remove(ref)
		SSthrowing.current_throwing_queue.Remove(ref)
	if(target.allow_spin && src.allow_spin)
		SpinAnimation(5,1)
	src.throwing = TRUE
	src.thrower = thrower
	throw_source = get_turf(thrower)
	var/dist_x = abs(target.x - src.x)
	var/dist_y = abs(target.y - src.y)
	pass_flags += throwflags
	/// defines for each slot are above the function def
	var/list/tl = new /list(12)
	tl[1] = target
	tl[2] = speed
	tl[3] = range
	tl[4] = 0
	tl[5] = dist_x
	tl[6] = dist_y
	tl[7] = (target.x > x ? EAST : WEST)
	tl[8] =	(target.y > y ? NORTH : SOUTH)
	tl[9] = (dist_x > dist_y ? dist_x/2 - dist_y : dist_y/2 - dist_x)
	tl[10] = get_turf(target)
	tl[11] = throwflags
	tl[12] = speed
	SSthrowing.throwing_queue[src] = tl
	return TRUE


//Overlays
/atom/movable/overlay
	var/atom/master
	anchored = TRUE

/atom/movable/overlay/New()
	for(var/x in src.verbs)
		src.verbs -= x
	..()

/atom/movable/overlay/attackby(a, b)
	if (src.master)
		return src.master.attackby(a, b)
	return

/atom/movable/overlay/attack_hand(a, b, c)
	if (src.master)
		return src.master.attack_hand(a, b, c)
	return

/atom/movable/proc/touch_map_edge()
	if(z in GLOB.maps_data.sealed_levels)
		return

	if(config.use_overmap)
		overmap_spacetravel(get_turf(src), src)
		return

	var/move_to_z = src.get_transit_zlevel()
	var/move_to_x = x
	var/move_to_y = y
	if(move_to_z)
		if(x <= TRANSITIONEDGE)
			move_to_x = world.maxx - TRANSITIONEDGE - 2
			move_to_y = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

		else if (x >= (world.maxx - TRANSITIONEDGE + 1))
			move_to_x = TRANSITIONEDGE + 1
			move_to_y = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

		else if (y <= TRANSITIONEDGE)
			move_to_y = world.maxy - TRANSITIONEDGE -2
			move_to_x = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

		else if (y >= (world.maxy - TRANSITIONEDGE + 1))
			move_to_y = TRANSITIONEDGE + 1
			move_to_x = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

		forceMove(locate(move_to_x, move_to_y, move_to_z))

//by default, transition randomly to another zlevel
/atom/movable/proc/get_transit_zlevel()
	var/list/candidates = GLOB.maps_data.accessable_levels.Copy()
	candidates.Remove("[src.z]")

	//If something was ejected from the ship, it does not end up on another part of the ship.
	if (z in GLOB.maps_data.station_levels)
		for (var/n in GLOB.maps_data.station_levels)
			candidates.Remove("[n]")

	if(!candidates.len)
		return null
	return text2num(pickweight(candidates))


/atom/movable/proc/set_glide_size(glide_size_override = 0, var/min = 0.2, var/max = world.icon_size/2)
	if (!glide_size_override || glide_size_override > max)
		glide_size = 0
	else
		glide_size = max(min, glide_size_override)

/*	for (var/atom/movable/AM in contents)
		AM.set_glide_size(glide_size, min, max)

*/
//This proc should never be overridden elsewhere at /atom/movable to keep directions sane.
// Spoiler alert: it is, in moved.dm
/atom/movable/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, var/glide_size_override = 0, initiator = null)
	if (glide_size_override > 0)
		set_glide_size(glide_size_override)

	// To prevent issues, diagonal movements are broken up into two cardinal movements.
	// Is this a diagonal movement?
	SEND_SIGNAL_OLD(src, COMSIG_MOVABLE_PREMOVE, src)
	if (Dir & (Dir - 1))
		if (Dir & NORTH)
			if (Dir & EAST)
				// Pretty simple really, try to move north -> east, else try east -> north
				// Pretty much exactly the same for all the other cases here.
				if (step(src, NORTH))
					step(src, EAST)
				else
					if (step(src, EAST))
						step(src, NORTH)
			else
				if (Dir & WEST)
					if (step(src, NORTH))
						step(src, WEST)
					else
						if (step(src, WEST))
							step(src, NORTH)
		else
			if (Dir & SOUTH)
				if (Dir & EAST)
					if (step(src, SOUTH))
						step(src, EAST)
					else
						if (step(src, EAST))
							step(src, SOUTH)
				else
					if (Dir & WEST)
						if (step(src, SOUTH))
							step(src, WEST)
						else
							if (step(src, WEST))
								step(src, SOUTH)
	else
		var/atom/oldloc = src.loc
		var/olddir = dir //we can't override this without sacrificing the rest of movable/New()

		. = ..()

		if(oldloc)
			oldloc.recalculateWeights(-weight,src)
		if(loc)
			loc.recalculateWeights(weight,src)

		if(Dir != olddir)
			dir = olddir
			set_dir(Dir)

		src.move_speed = world.time - src.l_move_time
		src.l_move_time = world.time
		src.m_flag = 1

		if (oldloc != src.loc && oldloc && oldloc.z == src.z)
			src.last_move = get_dir(oldloc, src.loc)

		// Only update plane if we're located on map
		if(isturf(loc))
			// if we wasn't on map OR our Z coord was changed
			if( !isturf(oldloc) || (get_z(loc) != get_z(oldloc)) )
				update_plane()

		if(get_z(oldloc) != get_z(loc))
			SEND_SIGNAL(src, COMSIG_MOVABLE_Z_CHANGED, get_z(oldloc), get_z(NewLoc))

		if(oldloc != loc)
			SEND_SIGNAL(src, COMSIG_MOVABLE_MOVED, oldloc, loc, initiator)
		/* Inserting into contents uses only forceMove
		if(!isturf(oldloc) || !isturf(loc))
			SEND_SIGNAL(src, COMSIG_ATOM_CONTAINERED, getContainingAtom())
		*/
		// Entered() typically lifts the moved event, but in the case of null-space we'll have to handle it.
		if(!loc)
			GLOB.moved_event.raise_event(src, oldloc, null)


// Wrapper of step() that also sets glide size to a specific value.
/proc/step_glide(atom/movable/AM, newdir, glide_size_override)
	AM.set_glide_size(glide_size_override)
	return step(AM, newdir)

//We're changing zlevel
/*
/atom/movable/proc/onTransitZ(old_z, new_z)//uncomment when something is receiving this signal
	SEND_SIGNAL(src, COMSIG_MOVABLE_Z_CHANGED, old_z, new_z)
	/*
	for(var/atom/movable/AM in src) // Notify contents of Z-transition. This can be overridden IF we know the items contents do not care.
		AM.onTransitZ(old_z,new_z)
	*/
*/

/mob/living/proc/update_z(new_z) // 1+ to register, null to unregister
	if (registered_z != new_z)
		if (registered_z)
			SSmobs.mob_living_by_zlevel[registered_z] -= src
		if (new_z)
			SSmobs.mob_living_by_zlevel[new_z] += src
		registered_z = new_z

// if this returns true, interaction to turf will be redirected to src instead
/atom/movable/proc/preventsTurfInteractions()
	return FALSE

///Sets the anchored var and returns if it was sucessfully changed or not.
/atom/movable/proc/set_anchored(anchorvalue)
	SHOULD_CALL_PARENT(TRUE)
	if(anchored == anchorvalue || !can_anchor)
		return FALSE
	anchored = anchorvalue
	SEND_SIGNAL_OLD(src, COMSIG_ATOM_UNFASTEN, anchored)
	. = TRUE

/atom/movable/proc/update_overlays()
	SHOULD_CALL_PARENT(TRUE)
	. = list()
	SEND_SIGNAL_OLD(src, COMSIG_ATOM_UPDATE_OVERLAYS, .)
