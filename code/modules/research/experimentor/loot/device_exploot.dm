//////////////////////////////DEVICE DEFINITION////////////////////////////////
// Re-implements the old strange object code in order to finish the proof of concept.
// Loot and name lists are defined in _loot_definer.dm for each object type.

#define RARITY_COMMON 0
#define RARITY_UNCOMMON 1
#define RARITY_RARE 2
#define RARITY_VERYRARE 3

/obj/item/discovered_tech
	name = "Discovered Technology"
	desc = "A strange device. Its function is not immediately apparent."
	icon = 'icons/obj/assemblies.dmi'
	origin_tech = "combat=1;plasmatech=1;powerstorage=1;materials=1"
	icon_state = "shock_kit"
	var/list/iconlist = list("shock_kit","armor-igniter-analyzer","infra-igniter0","infra-igniter1","radio-multitool","prox-radio1","radio-radio","timer-multitool0","radio-igniter-tank")
	var/cooldownMax = 60
	var/cooldown = FALSE
	// When spawned in, they'll have average (50) stats and an uncommon rarity level
	var/stability = 50
	var/potency = 50
	var/raritylevel = RARITY_UNCOMMON
	var/base_name = "Unknown"
	var/extra_data
	var/list/extra_data_list
	var/box_type
	// Is checked by devices that have more than origin tech and keywords in the init proc to make sure initialization is complete.
	var/isinitialized = FALSE
	// Used by one-use items to render them inactive.
	var/used = FALSE

	var/list/keywords = list("clowns")
	var/use_generated_names = TRUE
	var/use_generated_descriptions = TRUE

	var/techLevels

/obj/item/discovered_tech/proc/setStats(var/stability_in, var/potency_in, var/rare_level, var/boxtype)
	stability = stability_in
	potency = potency_in
	raritylevel = rare_level
	box_type = boxtype
	icon_state = pick(iconlist)
	techLevels = raritylevel*2
	initialize()

/obj/item/discovered_tech/attack_self(mob/user)
	if(cooldown)
		to_chat(user, "<span class='warning'>The [src] does not react!</span>")
		return
	else if(src.loc == user)
		cooldown = TRUE
		itemproc(user)
		spawn(cooldownMax)
			cooldown = FALSE

/obj/item/discovered_tech/proc/initialize()
	cooldownMax = round(rand(150,300)*(1.4-0.2*raritylevel)*(1.4-0.2*(stability/20)),1)
	origin_tech = ""
	if(box_type == "Mysterious")
		origin_tech += "syndicate=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	if(box_type == "Alien")
		origin_tech += "abductor=[1+raritylevel+rand(raritylevel,raritylevel+1)];"

/obj/item/discovered_tech/proc/itemproc(mob/user)
	return

/obj/item/discovered_tech/proc/warn_admins(mob/user, ItemType, priority = 1)
	var/turf/T = get_turf(src)
	var/log_msg = "[ItemType] experimentor tech used by [key_name(user)] in ([T.x],[T.y],[T.z])"
	if(priority) //For truly dangerous relics that may need an admin's attention. BWOINK!
		message_admins("[ItemType] experimentor tech activated by [key_name_admin(user)] in ([T.x], [T.y], [T.z] - <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[T.x];Y=[T.y];Z=[T.z]'>JMP</a>)",0,1)
	log_game(log_msg)
	investigate_log(log_msg, "experimentor")


///////////////////////////////DEVICES////////////////////////////////////
// Borrowed from the old relics for testing purposes.

// Nothing
/obj/item/discovered_tech/nothing/initialize(mob/user)
	..()
	origin_tech += "engineering=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "materials=[1+raritylevel+rand(raritylevel,raritylevel+1)]"

/obj/item/discovered_tech/nothing/itemproc(mob/user)
	to_chat(user, "<span class='notice'>The [src] fizzles and sparks. It doesn't seem to work.</span>")
	return


// Smoke Bomb
/obj/item/discovered_tech/smokebomb/initialize(mob/user)
	..()
	origin_tech += "materials=[1+raritylevel+rand(raritylevel,raritylevel+1)]"
	keywords = list("destruction", "light")

/obj/item/discovered_tech/smokebomb/itemproc(turf/where)
	visible_message("<span class='notice'>The [src] belches forth a cloud of smoke!</span>")
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(potency/25,0, where, 0)
	smoke.start()
	return

// Floof Cannon
/obj/item/discovered_tech/floofcannon/initialize()
	..()
	origin_tech += "biotech=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "bluespace=[1+raritylevel+rand(raritylevel,raritylevel+1)]"
	keywords = list("animals", "replication")
	extra_data = pick(/mob/living/simple_animal/pet/corgi, /mob/living/simple_animal/pet/cat, /mob/living/simple_animal/pet/fox, /mob/living/simple_animal/mouse, /mob/living/simple_animal/pet/pug, /mob/living/simple_animal/lizard, /mob/living/simple_animal/diona, /mob/living/simple_animal/butterfly, /mob/living/carbon/human/monkey)

/obj/item/discovered_tech/floofcannon/itemproc(mob/user)
	if(!isinitialized)
		initialize()
	playsound(src.loc, "sparks", rand(25,50), 1)
	var/mob/living/C = new extra_data(get_turf(user))
	C.throw_at(pick(oview(10,user)),10,rand(3,8))
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(1,0, user.loc, 0)
	smoke.start()
	warn_admins(user, "Floof Cannon", 0)

// Explosion
/obj/item/discovered_tech/explosion/initialize()
	..()
	origin_tech += "materials=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "combat=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "plasmatech=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	if(raritylevel>=RARITY_RARE)
		origin_tech += "toxins=[1+raritylevel+rand(raritylevel,raritylevel+1)]"
	keywords = list("destruction", "sound")

/obj/item/discovered_tech/explosion/itemproc(mob/user)
	to_chat(user, "<span class='danger'>[src] begins to heat up!</span>")
	spawn(rand(max(stability,35),100))
		if(src.loc == user)
			visible_message("<span class='notice'>The [src]'s top opens, releasing a powerful blast!</span>")
			explosion(src.loc, -1, rand(potency/50,potency/30), rand(potency/30,potency/20), rand(potency/20,potency/15), flame_range = potency/25)
			warn_admins(user, "Explosion")
			qdel(src)

// Cleaner
/obj/item/discovered_tech/cleaner/initialize()
	..()
	origin_tech += "engineering=[1+raritylevel+rand(raritylevel,raritylevel+1)]"
	keywords = list("destruction")

/obj/item/discovered_tech/cleaner/itemproc(mob/user)
	playsound(src.loc, "sparks", rand(25,50), 1)
	var/obj/item/grenade/chem_grenade/cleaner/CL = new/obj/item/grenade/chem_grenade/cleaner(get_turf(user))
	CL.prime()
	warn_admins(user, "Cleaning Foam", 0)

// Flashbang
/obj/item/discovered_tech/flashbang/initialize()
	..()
	origin_tech += "plasmatech=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	keywords = list("light", "sound")

/obj/item/discovered_tech/flashbang/itemproc(mob/user)
	playsound(src.loc, "sparks", rand(25,50), 1)
	var/obj/item/grenade/flashbang/CB = new/obj/item/grenade/flashbang(get_turf(user))
	CB.range = rand(stability/25, max(potency/10, 4))
	CB.prime()
	warn_admins(user, "Flashbang")

// Rapid Duplicator
/obj/item/discovered_tech/rapidDuplicator/initialize()
	..()
	origin_tech += "magnets=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "engineering=[1+raritylevel+rand(raritylevel,raritylevel+1)]"
	origin_tech += "materials=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	keywords = list("replication")

/obj/item/discovered_tech/rapidDuplicator/itemproc(mob/user)
	if(raritylevel >= RARITY_UNCOMMON)
		audible_message("[src] emits a loud pop and sprays dangerous projectiles everywhere!")
		warn_admins(user, "Dangerous Rapid Duplicator")
	else
		audible_message("[src] emits a loud pop!")
		warn_admins(user, "Rapid Duplicator", 0)
	var/list/dupes = list()
	var/counter
	var/max = rand(stability/20, max(potency/5, 5))
	for(counter = 1; counter < max; counter++)
		var/obj/item/discovered_tech/R = new src.type(get_turf(src))
		R.icon_state = icon_state
		R.name = name
		R.desc = desc
		R.throwforce = ((potency/10)*raritylevel)+1
		dupes |= R
		spawn()
			R.throw_at(pick(oview(4+potency/20,get_turf(src))),10,1)
	counter = 0
	spawn(rand(stability/10,stability))
		for(counter = 1; counter <= dupes.len; counter++)
			var/obj/item/discovered_tech/R = dupes[counter]
			qdel(R)

// Teleporter
/obj/item/discovered_tech/teleport/initialize()
	..()
	origin_tech += "bluespace=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "powerstorage=[1+raritylevel+rand(raritylevel,raritylevel+1)]"
	keywords = list("teleportation", "bluespace")

/obj/item/discovered_tech/teleport/itemproc(mob/user)
	to_chat(user, "<span class='notice'>The [src] begins to vibrate!</span>")
	spawn(rand((15-stability/10),30-stability/5))
		var/turf/userturf = get_turf(user)
		if(src.loc != user || is_teleport_allowed(userturf.z) == FALSE)
			return
		visible_message("<span class='notice'>The [src] twists and bends, relocating itself!</span>")
		do_teleport(user, userturf, round(potency/10, 1), asoundin = 'sound/effects/phasein.ogg')
		warn_admins(user, "Teleport", 0)

// Mass Mob Spawner
/obj/item/discovered_tech/massSpawner/initialize()
	..()
	origin_tech += "biotech=[1+raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "bluespace=[1+raritylevel+rand(raritylevel,raritylevel+1)]"
	keywords = list("animals", "replication")

/obj/item/discovered_tech/massSpawner/itemproc(mob/user)
	var/message = "<span class='danger'>[src] begins to shake, and in the distance the sound of rampaging animals arises!</span>"
	visible_message(message)
	to_chat(user, message)
	var/animals = rand(stability/20, max(potency/10, 5))
	var/counter
	var/list/valid_animals = list(/mob/living/simple_animal/parrot,/mob/living/simple_animal/butterfly,/mob/living/simple_animal/pet/cat,/mob/living/simple_animal/pet/corgi,/mob/living/simple_animal/crab,/mob/living/simple_animal/pet/fox)
	// Moves a couple of harmless spawns to a low potency check to make hostile mobs more likely (~1/3 instead of 1/4) on very high potency.
	if(potency<80)
		valid_animals.Add(/mob/living/simple_animal/lizard,/mob/living/simple_animal/mouse,/mob/living/simple_animal/pet/pug)
	// Moves the dangerous spawns to high potency only.
	if(potency>60)
		valid_animals.Add(/mob/living/simple_animal/hostile/bear,/mob/living/simple_animal/hostile/poison/bees,/mob/living/simple_animal/hostile/carp)
		warn_admins(user, "Mass Mob Spawn")
	else
		warn_admins(user, "Harmless Mass Mob Spawn", 0)
	for(counter = 1; counter < animals; counter++)
		var/mobType = pick(valid_animals)
		new mobType(get_turf(src))
	if(prob(100-(stability/2+15)))
		to_chat(user, "<span class='warning'>[src] falls apart!</span>")
		qdel(src)

// Gene Power Granter
// Grants up to 3 gene powers (rarity level+1) and a bunch of radiation. High potency and stability may result in gene stability issues.
/obj/item/discovered_tech/gene_granter/initialize()
	..()
	origin_tech += "biotech=[4+rand(raritylevel,raritylevel+1)];"
	keywords = list("enhancement", "biology")

	var/adjpotency = potency + (raritylevel*30-30)
	var/adjstability = stability + (raritylevel*30-30)
	var/supplied_genes = raritylevel+1
	var/list/obj/item/dnainjector/samples = new/list
	extra_data_list = new/list
	var/chosenGene

	if(adjpotency >= 60)
		samples.Add(
			new/obj/item/dnainjector/hulkmut,
			new/obj/item/dnainjector/telemut,
			new/obj/item/dnainjector/xraymut,
			new/obj/item/dnainjector/midgit
		)
	if(adjpotency >= 30 && adjpotency < 100)
		samples.Add(
			new/obj/item/dnainjector/firemut,
			new/obj/item/dnainjector/nobreath,
			new/obj/item/dnainjector/regenerate,
			new/obj/item/dnainjector/runfast,
			new/obj/item/dnainjector/morph,
			new/obj/item/dnainjector/noprints,
			new/obj/item/dnainjector/insulation
		)
	// If no conditions are met, grants useless genes instead. There must be at least 3 possibilities.
	if(samples.len < 3)
		samples.Add(new/obj/item/dnainjector/stuttmut, new/obj/item/dnainjector/coughmut, new/obj/item/dnainjector/comic)
	//If good genes are available pick one (to ensure that every injection grants at least something good)
	if(raritylevel >= RARITY_UNCOMMON)
		chosenGene = pick(samples)
		extra_data_list.Add(chosenGene)
		samples.Remove(chosenGene)
		supplied_genes -= 1
	if(adjstability < 90)
		samples.Add(
			new/obj/item/dnainjector/glassesmut,
			new/obj/item/dnainjector/clumsymut,
			new/obj/item/dnainjector/hallucination,
		)
	if(adjstability < 60)
		samples.Add(
			new/obj/item/dnainjector/h2m,
			new/obj/item/dnainjector/epimut,
			new/obj/item/dnainjector/tourmut,
			new/obj/item/dnainjector/blindmut,
			new/obj/item/dnainjector/deafmut
		)
	for(var/i = 1 to supplied_genes)
		chosenGene = pick(samples)
		extra_data_list.Add(chosenGene)
		samples.Remove(chosenGene)

/obj/item/discovered_tech/gene_granter/itemproc(mob/user)
	if(used)
		to_chat(user, "<span class='notice'>Whatever payload was in this thing has been spent. It's useless now.</span>")
		return
	if(!isinitialized)
		initialize()
	to_chat(user, "<span class='warning'>A small hypodermic needle shoots into you and injects something from a hidden reservoir!</span>")
	playsound(loc, 'sound/goonstation/items/hypo.ogg', 80, 0)
	warn_admins(user, "Gene Granter", 0)
	if(!user.dna)
		to_chat(user, "<span class='notice'>...but it doesn't seem to do anything to you.</span>")
		used = TRUE
		return
	if(ishuman(user))
		if(NO_DNA in user.dna.species.species_traits)
			to_chat(user, "<span class='notice'>...but it doesn't seem to do anything to you.</span>")
			used = TRUE
			return
	for(var/obj/item/dnainjector/I in extra_data_list)
		I.inject(user, user)
	used = TRUE

// Transcendence Serum
// DNA vault on steroids. Grants you most psychic powers as inherents that cannot be removed with mutadone. Very Rare, of course.
/obj/item/discovered_tech/gene_transcendence_serum/initialize()
	..()
	origin_tech += "biotech=[raritylevel+rand(raritylevel,raritylevel+1)];"
	keywords = list("enhancement", "biology", "transformation")

/obj/item/discovered_tech/gene_transcendence_serum/itemproc(mob/user)
	// It'll behave in most ways like a gene granter when interacted with by a DNA-less pleb.
	// It's probably best that they don't know what they missed out on.
	if(used)
		to_chat(user, "<span class='notice'>Whatever payload was in this thing has been spent. It's useless now.</span>")
		return
	to_chat(user, "<span class='warning'>A small hypodermic needle shoots into you and injects something from a hidden reservoir!</span>")
	playsound(loc, 'sound/goonstation/items/hypo.ogg', 80, 0)
	if(!user.dna)
		to_chat(user, "<span class='notice'>...but it doesn't seem to do anything to you.</span>")
		used=TRUE
		return
	if(ishuman(user))
		if(NO_DNA in user.dna.species.species_traits)
			to_chat(user, "<span class='notice'>...but it doesn't seem to do anything to you.</span>")
			used=TRUE
			return
		warn_admins(user, "Transcendence Serum")
		to_chat(user, "<span class='notice'>You feel a massive surge of energy as your psionic abilities transcend mortal limits!</span>")
		playsound(loc, 'sound/magic/teleport_app.ogg', 80, 0)
		grant_power(user, XRAYBLOCK, XRAY)
		grant_power(user, TELEBLOCK, TK)
		grant_power(user, REMOTETALKBLOCK, REMOTE_TALK)
		grant_power(user, REMOTEVIEWBLOCK, REMOTE_VIEW)
		grant_power(user, EMPATHBLOCK, EMPATH)
		grant_power(user, PSYRESISTBLOCK, PSY_RESIST)
		used=TRUE

/obj/item/discovered_tech/gene_transcendence_serum/proc/grant_power(mob/living/carbon/human/H, block, power)
	if(!H.ignore_gene_stability)
		H.ignore_gene_stability = 1
	H.dna.SetSEState(block, 1, 1)
	H.mutations |= power
	genemutcheck(H, block, null, MUTCHK_FORCED)
	H.dna.default_blocks.Add(block) //prevent removal by mutadone

// Gender Swapper
// A COMMON single use device which swaps the user's gender and hairstyles. The UNCOMMON version is multi-use.
/obj/item/discovered_tech/gender_swapper/initialize()
	..()
	origin_tech += "biotech=[raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "bluespace=[raritylevel+rand(raritylevel,raritylevel+1)];"
	keywords = list("biology", "transformation")
	cooldownMax = round(rand(300,600)*(1.4-0.2*raritylevel)*(1.4-0.2*(stability/20)),1)

/obj/item/discovered_tech/gender_swapper/itemproc(mob/user)
	var/mob/living/carbon/human/H
	warn_admins(user, "Gender Swapper", 0)
	if(used)
		to_chat(user, "<span class='notice'>Whatever payload was in this thing has been spent. It's useless now.</span>")
		return
	if(issilicon(user))
		return
	to_chat(user, "<span class='warning'>A wave of strange energy washes over you! You feel uncomfortably warm...</span>")
	playsound(loc, 'sound/magic/charge.ogg', 80, 0)
	if(!user.dna)
		to_chat(user, "<span class='warning'>...but it doesn't seem to do anything to you.</span>")
		return
	if(ishuman(user))
		H = user
		if(NO_DNA in H.dna.species.species_traits)
			to_chat(H, "<span class='warning'>...but it doesn't seem to do anything to you.</span>")
			return
		if(H.gender == MALE)
			H.change_gender(FEMALE)
			H.change_facial_hair("Shaved")
			to_chat(H, "<span class='warning'>All of a sudden, you seem to have a lot less testosterone than usual.</span>")
		else if(H.gender == FEMALE)
			H.change_gender(MALE)
			H.reset_facial_hair()
			to_chat(H, "<span class='warning'>All of a sudden, you seem to have a lot more testosterone than usual.</span>")
		else
			// No gender bending for you, Neuters.
			to_chat(H, "<span class='warning'>...but it doesn't seem to do anything to you.</span>")
	if(raritylevel == RARITY_COMMON)
		used = TRUE

// Mass Gene Modifier
// A single use VERY RARE device that alters the genes of every organic creature with DNA on the z-level it's activated on.
/obj/item/discovered_tech/mass_gene_modifier/initialize()
	..()
	origin_tech += "biotech=[4+rand(raritylevel,raritylevel+1)];"
	origin_tech += "bluespace=[4+rand(raritylevel,raritylevel+1)];"
	keywords = list("biology", "transformation")
	extra_data = pick("GENDER_SWAP", "DWARF", "CLOWN_VOICE")

/obj/item/discovered_tech/mass_gene_modifier/itemproc(mob/user)
	var/turf/U = get_turf(user)
	var/z_level = U.z
	if(used)
		to_chat(user, "<span class='notice'>Whatever payload was in this thing has been spent. It's useless now.</span>")
		return
	if(!isinitialized)
		initialize()
	to_chat(user, "<span class='notice'>The device whirs ominously, and your scalp prickles with a massive energy build-up. Uh oh...</span>")
	playsound(loc, 'sound/magic/lightning_chargeup.ogg', 100, 0)
	warn_admins(user, "Mass Gene Modifier ([extra_data])")
	spawn(100)
	for(var/mob/living/L in GLOB.mob_list)
		var/turf/T = get_turf(L)
		if(!T || T.z != z_level)
			continue
		// Silicons aren't affected by this quasi-magical energy.
		if(issilicon(L))
			continue
		L << 'sound/magic/charge.ogg'
		to_chat(L, "<span class='warning'>A wave of strange energy washes over you! You feel uncomfortably warm...</span>")
		if(!L.dna)
			to_chat(L, "<span class='warning'>...but it doesn't seem to do anything to you.</span>")
			continue
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(NO_DNA in H.dna.species.species_traits)
				to_chat(H, "<span class='warning'>...but it doesn't seem to do anything to you.</span>")
				continue
			alterDNA(H)
	used = TRUE

/obj/item/discovered_tech/mass_gene_modifier/proc/alterDNA(var/mob/living/carbon/human/target)
	switch(extra_data)
		if("GENDER_SWAP")
			if(target.gender == MALE)
				target.change_gender(FEMALE)
				target.change_facial_hair("Shaved")
				to_chat(target, "<span class='warning'>All of a sudden, you seem to have a lot less testosterone than usual.</span>")
			else if(target.gender == FEMALE)
				target.change_gender(MALE)
				target.reset_facial_hair()
				to_chat(target, "<span class='warning'>All of a sudden, you seem to have a lot more testosterone than usual.</span>")
			else
				to_chat(target, "<span class='warning'>...but it doesn't seem to do anything to you.</span>")
		if("DWARF")
			grant_power(target, SMALLSIZEBLOCK, DWARF)
		if("CLOWN_VOICE")
			grant_power(target, COMICBLOCK, COMIC)

/obj/item/discovered_tech/mass_gene_modifier/proc/grant_power(mob/living/carbon/human/H, block, power)
	H.dna.SetSEState(block, 1, 1)
	H.mutations |= power
	genemutcheck(H, block, null, MUTCHK_FORCED)

// Syndicate Bomb Spawner
// VERY RARE item that spawns, anchors and activates a generously timed syndicate bomb on use.
// Want to play bomb squad? This is for you!
/obj/item/discovered_tech/bomb_spawner/initialize()
	..()
	origin_tech += "plasmatech=[raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "powerstorage=[raritylevel+rand(raritylevel,raritylevel+1)];"
	origin_tech += "combat=[raritylevel+rand(raritylevel,raritylevel+1)];"
	keywords = list("destruction")

/obj/item/discovered_tech/bomb_spawner/itemproc(mob/user)
	var/mob/living/carbon/human/U = user
	if(used)
		to_chat(user, "<span class='notice'>Whatever payload was in this thing has been spent. It's useless now... thank god.</span>")
		return
	playsound(loc, 'sound/magic/wand_teleport.ogg', 100, 0)
	var/obj/machinery/syndicatebomb/bomb
	// If the user is a clown, spawn a clown bomb instead.
	if(U.job in list("Clown"))
		bomb = new/obj/machinery/syndicatebomb/badmin/clown(user.loc)
		warn_admins(user, "Syndicate Bomb Spawner (CLOWN)")
		to_chat(user, "<span class='warning'>The device beeps quietly and something falls out of a bluespace p-OH DEAR GOD!</span>")
	else
		bomb = new/obj/machinery/syndicatebomb(user.loc)
		warn_admins(user, "Syndicate Bomb Spawner")
		to_chat(user, "<span class='warning'>The device beeps quietly and something falls out of a bluespace p-OH DEAR GOD!</span>")
	bomb.anchored = 1
	// About 5 minutes.
	bomb.timer_set = 300
	bomb.activate()
	used = TRUE


