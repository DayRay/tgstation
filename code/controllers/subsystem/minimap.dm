var/datum/subsystem/minimap/SSminimap

/datum/subsystem/minimap
	name = "Minimap"
	priority = -2

	var/const/MINIMAP_SIZE = 4080
	var/const/TILE_SIZE = 16

	var/list/z_levels = list(1)

/datum/subsystem/minimap/New()
	NEW_SS_GLOBAL(SSminimap)

/datum/subsystem/minimap/Initialize(timeofday, zlevel)
	if(zlevel)
		return ..()

	var/hash = md5(file2text("_maps/[MAP_PATH]/[MAP_FILE]"))
	if(hash == trim(file2text(hash_path())))
		return ..()

	for(var/z in z_levels)
		generate(z)
		register_asset("minimap_[z].png", fcopy_rsc(map_path(z)))
	text2file(hash, hash_path())
	..()

/datum/subsystem/minimap/proc/hash_path()
	return "data/minimaps/[MAP_NAME].md5"

/datum/subsystem/minimap/proc/map_path(z)
	return "data/minimaps/[MAP_NAME]_[z].png"

/datum/subsystem/minimap/proc/send(client/client)
	for(var/z in z_levels)
		send_asset(client, "minimap_[z].png")

/datum/subsystem/minimap/proc/generate(z = 1, x1 = 1, y1 = 1, x2 = world.maxx, y2 = world.maxy)
	// Load the background.
	var/icon/minimap = new /icon('icons/minimap.dmi')
	// Scale it up to our target size.
	minimap.Scale(MINIMAP_SIZE, MINIMAP_SIZE)

	// Loop over turfs and generate icons.
	for(var/turf/tile in block(locate(x1, y1, z), locate(x2, y2, z)))
		var/obj/obj
		var/icon/ikon = new /icon('icons/minimap.dmi')

		// Don't use icons for space, just add objects in space if they exist.
		if(istype(tile, /turf/space))
			obj = locate(/obj/structure/lattice) in tile
			if(obj)
				ikon = new /icon('icons/obj/smooth_structures/lattice.dmi', "lattice", 2)
			obj = locate(/obj/structure/grille) in tile
			if(obj)
				ikon = new /icon('icons/obj/structures.dmi', "grille", 2)
			obj = locate(/obj/structure/transit_tube) in tile
			if(obj)
				ikon = new /icon('icons/obj/atmospherics/pipes/transit_tube.dmi', obj.icon_state, obj.dir)
		else
			ikon = new(tile.icon, tile.icon_state, tile.dir)

			var/icon/object
			obj = locate(/obj/structure/window/reinforced) in tile
			if(obj)
				object = new /icon('icons/obj/smooth_structures/reinforced_window.dmi', "r_window", 2)
			obj = locate(/obj/machinery/door/airlock) in tile
			if(obj)
				object = new /icon(obj.icon, obj.icon_state, obj.dir, 1, 0)

			if(object)
				ikon.Blend(object, ICON_OVERLAY)

		// Scale the icon.
		ikon.Scale(TILE_SIZE, TILE_SIZE)
		// Add the tile to the minimap.
		minimap.Blend(ikon, ICON_OVERLAY, ((tile.x - 1) * TILE_SIZE), ((tile.y - 1) * TILE_SIZE))

	// Create a new icon and insert the generated minimap, so that BYOND doesn't generate different directions.
	//var/icon/final = new /icon()
	//final.Insert(minimap, "", SOUTH, 1, 0)
	fcopy(minimap, map_path(z))