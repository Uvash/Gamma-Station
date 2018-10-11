/**********************Mineral processing unit console**************************/

/obj/machinery/computer/processing_unit_console
	name = "production machine console"
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = 1
	anchored = 1
	circuit = /obj/item/weapon/circuitboard/processing_unit_console

	var/obj/machinery/mineral/processing_unit/machine = null
	var/machinedir = EAST
	var/show_all_ores = 0

	var/points = 0
	var/obj/item/weapon/card/id/inserted_id

	var/show_value_list = 0
	var/list/ore_values = list(
							"glass" = 	1,
							"iron" = 	1,
							"coal" = 	1,
							"steel" =	5,
							"hydrogen"=	10,
							"uranium" = 20,
							"silver" = 	25,
							"gold" = 	30,
							"platinum"= 45,
							"plasteel"= 50,
							"diamond" = 70)

/obj/machinery/computer/processing_unit_console/atom_init()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/processing_unit_console/atom_init_late()
	//machine = locate(/obj/machinery/mineral/processing_unit, get_step(src, machinedir))
	try_connect()

/obj/machinery/computer/processing_unit_console/Destroy()
	if(machine)
		if(machine.console)
			machine.console = null
		machine = null
	if(inserted_id)
		inserted_id.loc = loc
		inserted_id = null
	..()

/obj/machinery/computer/processing_unit_console/ui_interact(mob/user)
	var/dat

	if(!machine)
		dat += text("Warning! Material processor not detected. Aborted")
		var/datum/browser/popup = new(user, "window=processor_console", "Ore Processor Console", 400, 550)
		popup.set_content(dat)
		popup.open()
		return

	dat += "<hr><table>"

	for(var/ore in machine.ores_processing)

		if(!machine.ores_stored[ore] && !show_all_ores)
			continue

		dat += "<tr><td width = 40><b>[capitalize(ore)]</b></td><td width = 30>[machine.ores_stored[ore]]</td><td width = 100><font color='"
		if(machine.ores_processing[ore])
			switch(machine.ores_processing[ore])
				if(NOT_PROCESSING)
					dat += "red'>not processing"
				if(SMELTING)
					dat += "orange'>smelting"
				if(COMPRESSING)
					dat += "yellow'>compressing"
				if(ALLOYING)
					dat += "gray'>alloying"
				if(DROP)
					dat += "green'>drop"
		else
			dat += "red'>not processing"
		dat += "</font></td><td width = 30><a href='?src=\ref[src];toggle_smelting=[ore]'>\[change\]</a></td></tr>"

	dat += "</table><hr>"

	dat += "Currently displaying [show_all_ores ? "all ore types" : "only available ore types"] <A href='?src=\ref[src];toggle_ores=1'>\[[show_all_ores ? "show less" : "show more"]\]</a><br>"
	dat += "The ore processor is currently <A href='?src=\ref[src];toggle_power=1'>[(machine.active ? "<font color='lime'><b>processing</b></font>" : "<font color='maroon'><b>disabled</b></font>")]</a><br>"

	dat += "<br>"
	dat += "<hr>"

	dat += text("<b>Current unclaimed points:</b> [points]<br>")

	if(istype(inserted_id))
		dat += text("You have [inserted_id.mining_points] mining points collected. <A href='?src=\ref[src];eject=1'>Eject ID</A><br>")
		dat += text("<A href='?src=\ref[src];claim=1'>Claim points.</A><br>")
	else
		dat += text("No ID inserted.  <A href='?src=\ref[src];insert=1'>Insert ID</A><br>")

	dat += "<br>"

	dat += "Resources Value List: <A href='?src=\ref[src];show_values=1'>\[[show_value_list ? "close" : "open"]\]</a><br>"
	if(show_value_list)
		dat += "<div class='statusDisplay'>[get_ore_values()]</div>"

	var/datum/browser/popup = new(user, "window=processor_console", "Ore Processor Console", 400, 550)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/processing_unit_console/Topic(href, href_list)
	. = ..()
	if(!.)
		return

	if(href_list["toggle_smelting"])
		var/choice = input("What setting do you wish to use for processing [href_list["toggle_smelting"]]?") as null|anything in list("Smelting","Compressing","Alloying","Drop","Nothing")
		if(!choice)
			return FALSE
		switch(choice)
			if("Nothing") choice = NOT_PROCESSING
			if("Smelting") choice = SMELTING
			if("Compressing") choice = COMPRESSING
			if("Alloying") choice = ALLOYING
			if("Drop") choice = DROP
		machine.ores_processing[href_list["toggle_smelting"]] = choice
	if(href_list["toggle_power"])
		machine.toggle_power()
	if(href_list["toggle_ores"])
		show_all_ores = !show_all_ores
	if(href_list["eject"])
		inserted_id.loc = loc
		inserted_id.verb_pickup()
		inserted_id = null
	if(href_list["claim"])
		inserted_id.mining_points += points
		points = 0
	if(href_list["insert"])
		var/obj/item/weapon/card/id/I = usr.get_active_hand()
		if(istype(I))
			if(!usr.drop_item())
				return FALSE
			I.loc = src
			inserted_id = I
		else
			to_chat(usr, "<span class='warning'>No valid ID.</span>")
	if(href_list["show_values"])
		show_value_list = !show_value_list

	src.updateUsrDialog()

/obj/machinery/computer/processing_unit_console/proc/get_ore_values()
	var/dat = "<table border='0' width='300'>"
	for(var/ore in ore_values)
		var/value = ore_values[ore]
		dat += "<tr><td>[capitalize(ore)]</td><td>[value]</td></tr>"
	dat += "</table>"
	return dat

/obj/machinery/computer/processing_unit_console/attackby(obj/item/weapon/W, mob/user, params)
	if(istype(W,/obj/item/weapon/card/id))
		var/obj/item/weapon/card/id/I = usr.get_active_hand()
		if(istype(I) && !istype(inserted_id))
			if(!user.drop_item())
				return
			I.loc = src
			inserted_id = I
			updateUsrDialog()
	if(istype(W,/obj/item/device/multitool))

		to_chat(user, "<span class='notice'>You try to connet console.</span>")
		if(try_connect())
			to_chat(user, "<span class='notice'>You connet console to processing unit</span>")
		else
			to_chat(user, "<span class='red'>Console has connect or can`t find processing unit</span>")
		return
	else
		..()

/obj/machinery/computer/processing_unit_console/proc/try_connect()
	if(machine)
		return 0
	for(var/obj/machinery/mineral/processing_unit/M in oview(3,src))
		if(M.console)
			continue
		else
			M.console = src
			machine = M
			return 1
	return 0

/obj/item/weapon/circuitboard/processing_unit_console
	name = "Circuit board (production machine console)"
	build_path = /obj/machinery/computer/processing_unit_console
	origin_tech = "programming=3"
