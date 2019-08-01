/////////////////////////////////////LOOT DEFINER/////////////////////////////////////
// Holds all the messy stuff to do with name and type picking, loot lists etc.
// define() returns a named unboxed item based on stats and loot lists.
// The actual items and their purposes should be defined elsewhere,
// though they can be initialized here as part of the loot picking.
//
// Expansion sections (Searchable):
// O.   LEAVE THIS PART ALONE
// I.   LOOT LIST
// II. SECOND NAME
// III.  THIRD NAME
// IV.   DESCRIPTION


#define RARITY_COMMON 0
#define RARITY_UNCOMMON 1
#define RARITY_RARE 2
#define RARITY_VERYRARE 3

//////////////////////// O. LEAVE THIS PART ALONE //////////////////////////
// Unless you have a good idea of how this works.
// If you're just adding new loot you shouldn't have to touch this.

/datum/experimentor/loot_definer
    var/stability = 50
    var/potency = 50
    var/raritylevel = 1
    var/box_type = "Unknown"
    var/item_category = "Device"
    var/obj/item/discovered_tech/loot_item

// Returns a finished item from the stats supplied to the experimentor.
/datum/experimentor/loot_definer/proc/define(var/stability_in, var/potency_in, var/base_name, var/rare_level, var/itemcategory)
	stability = stability_in
	potency = potency_in
	raritylevel = rare_level
	box_type = base_name
	item_category = itemcategory

    // determine what specific type (itemtype) the item is based on.
	loot_item = findItemType()
	loot_item.setStats(stability, potency, raritylevel, box_type)
    // name and describe the item unless the definition says not to.
	if(loot_item.use_generated_names)
		loot_item.name = box_type + " [generateSecondName()][generateThirdName()]"
	if(loot_item.use_generated_descriptions)
		loot_item.desc = generateDescription()
	if(raritylevel == RARITY_VERYRARE)
		var/turf/T = get_turf(loot_item)
		message_admins("The experimentor rolled a VERY RARE item of type [loot_item.type] at ([T.x], [T.y], [T.z] - <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[T.x];Y=[T.y];Z=[T.z]'>JMP</a>)",0,1)
	return loot_item

// If an admin messes with the experimentor, it will use this proc instead.
/datum/experimentor/loot_definer/proc/forcedefine(var/forcetype, var/forcename, var/forcedesc, var/forceicon)
    var/obj/item/I = new forcetype()
    if(istype(I, /obj/item/discovered_tech))
        loot_item=I
        loot_item.initialize()
    if(forcename != null)
        I.name = forcename
    else if(istype(I, /obj/item/discovered_tech))
        loot_item.name = box_type + " [generateSecondName()][generateThirdName()]"
    if(forcedesc != null)
        I.desc = forcedesc
    else if(istype(I, /obj/item/discovered_tech))
        loot_item.desc = generateDescription()
    if(forceicon != null)
        I.icon_state = forceicon
    return I

///////////////////I. LOOT LIST////////////////////
// Defines the loot lists for the experimentor
// by category then by rarity.

/datum/experimentor/loot_definer/proc/findItemType()
    switch (item_category)
        // Broad category list
        if("Device")
            // Lists by rarity.
            if(raritylevel == RARITY_COMMON)
                return pick(
                    new/obj/item/discovered_tech/cleaner(),
                    new/obj/item/discovered_tech/smokebomb(),
                    new/obj/item/discovered_tech/floofcannon(),
                    new/obj/item/discovered_tech/teleport(),
                    new/obj/item/discovered_tech/nothing(),
                    new/obj/item/discovered_tech/gene_granter(),
                    new/obj/item/discovered_tech/rapidDuplicator(),
                    new/obj/item/discovered_tech/gender_swapper())
            if(raritylevel == RARITY_UNCOMMON)
                return pick(
                    new/obj/item/discovered_tech/teleport(),
                    new/obj/item/discovered_tech/rapidDuplicator(),
                    new/obj/item/discovered_tech/explosion(),
                    new/obj/item/discovered_tech/massSpawner(),
                    new/obj/item/discovered_tech/flashbang(),
                    new/obj/item/discovered_tech/gene_granter(),
                    new/obj/item/discovered_tech/cleaner(),
                    new/obj/item/discovered_tech/gender_swapper(),
                    new/obj/item/discovered_tech/vendor_spawner())
            if(raritylevel == RARITY_RARE)
                return pick(
                    new/obj/item/discovered_tech/explosion(),
                    new/obj/item/discovered_tech/massSpawner(),
                    new/obj/item/discovered_tech/rapidDuplicator(),
                    new/obj/item/discovered_tech/flashbang(),
                    new/obj/item/discovered_tech/gene_granter(),
                    new/obj/item/discovered_tech/teleport())
            if(raritylevel == RARITY_VERYRARE)
                return pick(
                    new/obj/item/discovered_tech/bomb_spawner(),
                    new/obj/item/discovered_tech/gene_transcendence_serum(),
                    new/obj/item/discovered_tech/mass_gene_modifier())
    // If there is no type applicable to the one provided, the experimentor will produce a useless item.
    return new/obj/item/discovered_tech/nothing()

//////////////////II. SECOND NAME////////////////////
// Each revealed object has 3 parts to its name.
// This defines the second section based on keywords
// and also the general rarity of the item.
//
// NOTE: Don't forget to add proper spacing to added names!

/datum/experimentor/loot_definer/proc/generateSecondName()
    var/list/possiblenames = new/list
    // Adds generic rarity names to the list.
    switch(raritylevel)
        if(RARITY_COMMON)
            possiblenames.Add("Alpha ", "Alpha-")
        if(RARITY_UNCOMMON)
            possiblenames.Add("Beta ", "Beta-")
        if(RARITY_RARE)
            possiblenames.Add("Gamma ", "Gamma-")
        if(RARITY_VERYRARE)
            possiblenames.Add("Omega ", "Omega-")
    // Adds names based on keywords in the loot items.
    for(var/keyword in loot_item.keywords)
        switch(keyword)
            if("destruction")
                possiblenames.Add("Molecular ", "Destabilized ", "Destructive ", "Cleansing ")
            if("replication")
                possiblenames.Add("Induced ", "Replicant ")
            if("teleportation")
                possiblenames.Add("Distorting ", "Gravitic ")
            if("bluespace")
                possiblenames.Add("Phased ", "Quasi-Real ")
            if("stun")
                possiblenames.Add("Enervating ")
            if("sound")
                possiblenames.Add("Sonic ", "High-Frequency ", "Modulated ")
            if("light")
                possiblenames.Add("Photonic ", "Modulated ", "Luminescent ", "Strobing ")
            if("clowns")
                possiblenames.Add("Honk ", "Banana-", "Squeak-", "Murder-")
            if("enhancement")
                possiblenames.Add("Transcendent ", "Uplifting ")
            if("biology")
                possiblenames.Add("Cellular ", "Bio-", "Genetic ")
    return pick(possiblenames)


///////////////////III. THIRD NAME////////////////////
// Each revealed object has 3 parts to its name.
// This defines the second section based on keywords
// or on the defined unique name if any.

/datum/experimentor/loot_definer/proc/generateThirdName()
    var/list/possiblenames = new/list
    for(var/keyword in loot_item.keywords)
        switch(keyword)
            if("destruction")
                possiblenames.Add("Disintegrator", "Obliterator", "Annihilator", "Destructo-tron")
            if("replication")
                possiblenames.Add("Growth Catalyst", "Seeder")
            if("teleportation")
                possiblenames.Add("Translocator", "Space-Folder", "Dimensional Porta-Potty")
            if("stun")
                possiblenames.Add("Pacifier", "Nullifier", "Mesmertron")
            if("sound")
                possiblenames.Add("Blaster")
            if("light")
                possiblenames.Add("Photon Manipulator", "Modulator", "Strobe")
            if("animals")
                possiblenames.Add("Bio-Invigorator", "Cloner")
            if("enhancement")
                possiblenames.Add("Potentiotron", "Reinventor")
    if(possiblenames.len<3)
        possiblenames.Add("Machine")
    return pick(possiblenames)

//////////////////////// IV. DESCRIPTION //////////////////////////
// Generates a vaguely relevant description for the item, revealing
// one of the item's keywords. If the item has a specific use that
// is not readily apparent, using the item's own description
// definition (loot_described = FALSE) is recommended.

/datum/experimentor/loot_definer/proc/generateDescription()
	var/item_description = ""
	if(raritylevel == RARITY_COMMON)
		item_description += pick("This is a fairly simple piece of [box_type] Technology. ", "This is a basic but possibly useful piece of [box_type] Technology. ")
	if(raritylevel == RARITY_UNCOMMON)
		item_description += pick("This is a well-made piece of [box_type] Technology. ", "This is a piece of [box_type] Technology. It has a solid build. ")
	if(raritylevel == RARITY_RARE)
		item_description += pick("This is an elaborate piece of [box_type] Technology. ", "This is a piece of [box_type] Technology. Its build quality is surprisingly high. ")
	if(raritylevel == RARITY_VERYRARE)
		item_description += pick("This is an incredible example of [box_type] Technology. ", "This is a piece of [box_type] Technology. It's so complex you have no idea how it works. ")

	if(loot_item.keywords.len>=1)
		item_description += pick("There's a marking on the side which reminds you of [pick(loot_item.keywords)]. ", "When you look at it, you can't help but think of [pick(loot_item.keywords)]. ", "It's hard to tell for sure, but it seems to have something to do with [pick(loot_item.keywords)]. ")
	if (loot_item.extra_description != null)
		item_description += loot_item.extra_description
	return item_description