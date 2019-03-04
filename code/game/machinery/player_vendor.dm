// Vending machine in player control. Too different from the default vendor to inherit.

#define UVEND_STANDBY 0		// Waiting for a player to take control
#define UVEND_MAINT 1		// Items can be placed into the machine. clicking with an empty hand will open the vendor maintenance UI.
#define UVEND_ACTIVE 2		// The vendor is in sales mode and will act like a normal vendor until clicked with an authorized ID.
#define UVEND_UNARMORED 0	// Default vendor. Easy to hack open and steal from, if a little time consuming.
#define UVEND_PLASTEEL 1	// Makes the vendor much harder to steal and/or hack open.

/obj/machinery/player_vendor
	name = "\improper uVend Universal Vending Machine"
	desc = "A device by uVend Vending Corporation that can contain and dispense just about anything."
	icon = 'icons/obj/vending.dmi'
	icon_state = "smartfridge"
	layer = 2.9
	density = 1
	anchored = 1
	use_power = IDLE_POWER_USE
	idle_power_usage = 5
	obj_integrity = 100
	max_integrity = 100
	var/icon_on = "smartfridge"
	var/icon_off = "smartfridge-off"
	var/icon_panel = "smartfridge-panel"
	var/item_quants = list()
	var/registered_name = null
	var/registered_account = null
	var/mode = UVEND_STANDBY
	var/vendor_armored = UVEND_UNARMORED
	var/max_wclass_total = 1500				//Add together weight class cubed for all items, tiny = 1, small = 8, normal = 27, bulky = 64, huge = 125
	var/wclass_held = 0

/obj/machinery/player_vendor/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/player_vendor(null)
	component_parts += new /obj/item/stock_parts/matter_bin(null)
	RefreshParts()

/obj/machinery/player_vendor/RefreshParts()
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		max_wclass_total = 1500 * B.rating

/obj/machinery/player_vendor/attackby(obj/item/W as obj, mob/user as mob, params)
	// When a card is swiped while the machine is in standby mode, grants control to the user and registers the account associated with the ID card to receive payments.
	if(stat & NOPOWER)
		to_chat(user, "<span class='notice'>\The [src] is unpowered and does not respond.</span>")
		return
	if(default_deconstruction_screwdriver(user, W))
		return
	if(exchange_parts(user, W))
		return
	if(default_unfasten_wrench(user, W))
		power_change()
		return
	if(default_deconstruction_crowbar(W))
		return
	if(istype(W, /obj/item/multitool)||istype(W, /obj/item/wirecutters))
		if(panel_open)
			attack_hand(user)
		return

	else if(src.mode == UVEND_STANDBY)
		if(istype(W, /obj/item/card/id))
			var/obj/item/card/id/I = W
			if(!I || !I.registered_name)	return
			src.registered_name = I.registered_name
			src.registered_account = I.associated_account_number
			src.mode = UVEND_MAINT
			visible_message("<span class='info'>[usr] swipes an ID card through the slot on \the [src].</span>")
		else
			to_chat(user, "<span class='warning'>A user must take control before adding items to the machine.</span>")
	else if(src.mode == UVEND_MAINT)
	// Code for adding items. If clicked with an empty hand, open the maintenance UI.
		if(load(W, user))
			user.visible_message("<span class='notice'>[user] has added \the [W] to \the [src].</span>", "<span class='notice'>You add \the [W] to \the [src].</span>")
			SSnanoui.update_uis(src)
			return
		else
		// Code for accepting payment or opening the sales UI when clicked with an empty hand.
			return

/obj/machinery/smartfridge/default_deconstruction_screwdriver(mob/user, obj/item/screwdriver/S)
	. = ..(user, icon_state, icon_state, S)
	overlays.Cut()
	if(panel_open)
		overlays += image(icon, "[initial(icon_state)]-panel")

// Loads an item into the vendor.
/obj/machinery/player_vendor/proc/load(obj/item/I, mob/user)
	if((wclass_held + I.w_class**3) >= max_wclass_total)
		to_chat(user, "<span class='notice'>This item won't fit in [src].</span>")
		return 0
	else
		if(istype(I.loc, /obj/item/storage))
			var/obj/item/storage/S = I.loc
			S.remove_from_storage(I, src)
		else if(istype(I.loc, /mob))
			var/mob/M = I.loc
			if(M.get_active_hand() == I)
				if(!M.drop_item())
					to_chat(user, "<span class='warning'>\The [I] is stuck to you!</span>")
					return 0
			else
				M.unEquip(I)
			I.forceMove(src)
		else
			I.forceMove(src)
		wclass_held += I.w_class**3

		if(item_quants[I.name])
			item_quants[I.name]++
		else
			item_quants[I.name] = 1
		to_chat(user, "Added:[I.w_class]([I.w_class**3]) [wclass_held]/[max_wclass_total]")
		return 1

/obj/machinery/smartfridge/MouseDrop_T(obj/over_object, mob/user)
	to_chat(user, "Item drop attempted.")
	if(!istype(over_object, /obj/item/storage)) //Only storage items, please
		return

	if(stat & NOPOWER)
		to_chat(user, "<span class='notice'>\The [src] is unpowered and does not respond.</span>")
		return

	var/obj/item/storage/P = over_object
	var/items_loaded = 0
	for(var/obj/G in P.contents)
		if(load(G, user))
			items_loaded++
	if(items_loaded)
		user.visible_message( \
		"<span class='notice'>[user] empties \the [P] into \the [src].</span>", \
		"<span class='notice'>You empty \the [P] into \the [src].</span>")
	if(P.contents.len > 0)
		to_chat(user, "<span class='notice'>Some items don't fit.</span>")



// The circuitboard for the machine (TODO: put this somewhere not dumb.)
/obj/item/circuitboard/player_vendor
	name = "circuit board (uVend Vendor)"
	build_path = /obj/machinery/player_vendor
	board_type = "machine"
	origin_tech = "programming=1"
	frame_desc = "Requires 1 Matter Bin."
	req_components = list(/obj/item/stock_parts/matter_bin = 1)