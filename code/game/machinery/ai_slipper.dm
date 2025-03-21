/obj/machinery/ai_slipper
	name = "AI Liquid Dispenser"
	desc = "A remotely-activatable dispenser for crowd-controlling foam."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "ai-slipper0"
	layer = 3
	plane = FLOOR_PLANE
	anchored = TRUE
	var/uses = 20
	var/disabled = 1
	var/lethal = 0
	var/locked = 1
	var/cooldown_time = 0
	var/cooldown_timeleft = 0
	var/cooldown_on = 0
	req_access = list(access_ai_upload)

/obj/machinery/ai_slipper/power_change()
	if(stat & BROKEN)
		return
	else
		if( powered() )
			stat &= ~NOPOWER
		else
			stat |= NOPOWER
			update_icon()
	update_power_use()

/obj/machinery/ai_slipper/update_icon()
	if(stat)
		icon_state = "ai-slipper0"
	else
		icon_state = disabled ? "ai-slipper0" : "ai-slipper1"

/obj/machinery/ai_slipper/AICtrlClick()
	toggle_on()

/obj/machinery/ai_slipper/proc/toggle_on()
	disabled = !disabled
	update_icon()

/obj/machinery/ai_slipper/AIAltClick()
	activate()

/obj/machinery/ai_slipper/proc/activate()
	if(cooldown_on || disabled)
		return
	new /obj/effect/effect/foam(loc)
	uses--
	cooldown_on = 1
	cooldown_time = world.timeofday + 100
	slip_process()

/obj/machinery/ai_slipper/attackby(obj/item/weapon/W, mob/user)
	if(stat & (NOPOWER|BROKEN))
		return
	if (issilicon(user))
		return attack_hand(user)
	else // trying to unlock the interface
		if (allowed(usr))
			locked = !locked
			to_chat(user, "You [ locked ? "lock" : "unlock"] the device.")
			if (locked)
				if (user.machine==src)
					user.unset_machine()
					user << browse(null, "window=ai_slipper")
			else
				if (user.machine==src)
					attack_hand(usr)
		else
			to_chat(user, "<span class='warning'>Access denied.</span>")
			return
	return

/obj/machinery/ai_slipper/ui_interact(mob/user)
	var/area/area = get_area(src)

	if (!istype(area))
		to_chat(user, text("Turret badly positioned - area is [].", area))
		return
	var/t = ""

	if(locked && !issilicon_allowed(user) && !isobserver(user))
		t += "<div class='NoticeBox'>Swipe ID card to unlock control panel.</div>"
	else
		t += text("Dispenser [] - <A href='byond://?src=\ref[];toggleOn=1'>[]?</a><br>\n", src.disabled?"deactivated":"activated", src, src.disabled?"Enable":"Disable")
		t += text("Uses Left: [uses]. <A href='byond://?src=\ref[src];toggleUse=1'>Activate the dispenser?</A><br>\n")

	var/datum/browser/popup = new(user, "window=computer", src.name, 575, 450)
	popup.set_content(t)
	popup.open()

/obj/machinery/ai_slipper/Topic(href, href_list)
	. = ..()
	if(!.)
		return
	if (locked && !issilicon_allowed(usr) && !isobserver(usr))
		to_chat(usr, "Control panel is locked!")
		return FALSE
	if (href_list["toggleOn"])
		toggle_on()
	else if (href_list["toggleUse"])
		activate()

	updateUsrDialog()

/obj/machinery/ai_slipper/proc/slip_process()
	while(cooldown_time - world.timeofday > 0)
		var/ticksleft = cooldown_time - world.timeofday

		if(ticksleft > 1e5)
			cooldown_time = world.timeofday + 10	// midnight rollover


		cooldown_timeleft = (ticksleft / 10)
		sleep(5)
	if (uses <= 0)
		return
	if (uses >= 0)
		cooldown_on = 0
	power_change()
	return
