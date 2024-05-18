
/datum/computer/file/embedded_program
	var/list/memory = list()
	var/obj/machinery/embedded_controller/master

	var/id_tag

/datum/computer/file/embedded_program/proc/setController(obj/machinery/embedded_controller/dockingController)
	master = dockingController
	if (istype(dockingController, /obj/machinery/embedded_controller/radio))
		var/obj/machinery/embedded_controller/radio/radioController = dockingController
		id_tag = radioController.id_tag
	message_admins("set id_tag to [id_tag]")

	id_tag = copytext(id_tag, 1)
	var/datum/existing = locate(id_tag) //in case a datum already exists with our tag
	if(existing)
		existing.tag = null //take it from them
	tag = id_tag //Greatly simplifies shuttle initialization
	message_admins("Created docking program with the tag [tag]")


/datum/computer/file/embedded_program/proc/receive_user_command(command)
	return

/datum/computer/file/embedded_program/proc/receive_signal(datum/signal/signal, receive_method, receive_param)
	return

/datum/computer/file/embedded_program/Process()
	return

/datum/computer/file/embedded_program/proc/post_signal(datum/signal/signal, comm_line)
	if(master)
		master.post_signal(signal, comm_line)
	else
		qdel(signal)
