#define DISPLAY_ON_SHIP    0
#define DISPLAY_PLANETSIDE 1
#define DISPLAY_IN_TRANSIT 2

/obj/machinery/computer/crew
	name = "Crew monitoring computer"
	desc = "Used to monitor active health sensors built into most of the crew's uniforms."
	icon_state = "crew"
	use_power = IDLE_POWER_USE
	idle_power_usage = 250
	active_power_usage = 500
//	circuit = "/obj/item/circuitboard/computer/crew"
	interaction_flags = INTERACT_MACHINE_NANO
	var/list/tracked = list()
	var/list/crewmembers_planetside = list()
	var/list/crewmembers_on_ship = list()
	var/list/crewmembers_in_transit = list()
	var/displayed_z_level = DISPLAY_ON_SHIP
	var/cmp_proc = /proc/cmp_list_asc
	var/sortkey = "name"

	ui_x = 900
	ui_y = 800

/obj/machinery/computer/crew/update_icon()
	if(machine_stat & BROKEN)
		icon_state = "crewb"
	else if(machine_stat & NOPOWER)
		icon_state = "crew0"
		machine_stat |= NOPOWER
	else
		icon_state = initial(icon_state)
		machine_stat &= ~NOPOWER

/obj/machinery/computer/crew/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
										datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)

	if(!ui)
		ui = new(user, src, ui_key, "Crew", name, ui_x, ui_y, master_ui, state)
		ui.open()

/obj/machinery/computer/crew/ui_data(mob/user)
	scan()

	var/list/data = list()
	crewmembers_on_ship.Cut()
	crewmembers_planetside.Cut()
	crewmembers_in_transit.Cut()

	for(var/obj/item/clothing/under/C in tracked)
		var/turf/pos = get_turf(C)

		if(C && pos)
			if(ishuman(C.loc))

				var/mob/living/carbon/human/H = C.loc

				if(issurvivorjob(H.job) && is_ground_level(H.loc.z))
					continue // survivors

				if(H.w_uniform != C)
					continue

				var/list/crewmemberData = list()

				crewmemberData["sensor_type"] = C.sensor_mode
				crewmemberData["status"] = H.stat
				crewmemberData["oxy"] = round(H.getOxyLoss(), 1)
				crewmemberData["tox"] = round(H.getToxLoss(), 1)
				crewmemberData["fire"] = round(H.getFireLoss(), 1)
				crewmemberData["brute"] = round(H.getBruteLoss(), 1)

				crewmemberData["name"] = "Unknown"
				crewmemberData["rank"] = "Unknown"
				if(H.wear_id && istype(H.wear_id, /obj/item/card/id) )
					var/obj/item/card/id/I = H.wear_id
					crewmemberData["name"] = I.name
					crewmemberData["rank"] = I.rank

				var/area/A = get_area(H)
				crewmemberData["area"] = sanitize(A.name)
				crewmemberData["x"] = pos.x
				crewmemberData["y"] = pos.y

				if(is_ground_level(pos.z))
					crewmembers_planetside += list(crewmemberData)
				else if(is_mainship_level(pos.z))
					crewmembers_on_ship += list(crewmemberData)
				else if(is_reserved_level(pos.z))
					crewmembers_in_transit += list(crewmemberData)

	switch(displayed_z_level)
		if(DISPLAY_ON_SHIP)
			data["zlevel"] = 0
			data["crewmembers"] = sortListUsingKey(crewmembers_on_ship, cmp_proc, sortkey)
		if(DISPLAY_PLANETSIDE)
			data["zlevel"] = 1
			data["crewmembers"] = sortListUsingKey(crewmembers_planetside, cmp_proc, sortkey)
		if(DISPLAY_IN_TRANSIT)
			data["zlevel"] = 2
			data["crewmembers"] = sortListUsingKey(crewmembers_in_transit, cmp_proc, sortkey)

	return data

/obj/machinery/computer/crew/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("sortkey")
			if(sortkey == params["sortkey"])
				cmp_proc = (cmp_proc == /proc/cmp_list_asc) ? /proc/cmp_list_dsc : /proc/cmp_list_asc
			else
				sortkey = params["sortkey"]
				cmp_proc = /proc/cmp_list_asc
			return TRUE

		if("zlevel")
			displayed_z_level = text2num(params["zlevel"])
			return TRUE

	updateUsrDialog()

/obj/machinery/computer/crew/proc/scan()
	for(var/mob/living/carbon/human/H in GLOB.human_mob_list)
		if(!H || !istype(H)) continue
		var/obj/item/clothing/under/C = H.w_uniform
		if(!C || !istype(C)) continue
		if(C.has_sensor && H.mind)
			tracked |= C
	return TRUE

#undef DISPLAY_ON_SHIP
#undef DISPLAY_PLANETSIDE
#undef DISPLAY_IN_TRANSIT