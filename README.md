# wow-baastaardmounts
A personal WoW addon I made for myself to manage zone-specific mounts.

## Installation instructions

This is just a personal experiment of mine, so it's not on Curse and may never be.
There's also no UI or any kind of in-game help, so this README file is pretty much
all there is.

Download the repository and copy the Bstrd_Mounts folder to your AddOns directory.
If WoW is already open, exit and restart the game. It should now appear in your
list of Addons and you'll get some debug text in the chat window when you log in.

## Creating a Mount Button

First thing's first. You're going to want a button on your action bars that mounts
using your defined preferences. So create a new macro (any name or icon is fine)
and type the following:

	/MountUp

That's it. Save it and drag it to your action bars somewhere that you can easily
click it or keybind it. Clicking the button will call up your preferred mounts when
you are in a particular zone or situation, which you will set up next. If you are
already mounted, it will dismount you.

## Setting mount preferences

To set your preferred mount in a given zone/continent, you have to be in the place
where you want the mount to apply. So, for example, if you want to use the Mage
class mount in New Dalaran, be in New Dalaran and type the following:

    /SetMount Archmage's Prismatic Disc

You can also set a zone for the entire "continent" that you're presently in.

	/SetContinentMount Arcanist's Manasaber

If you run that in New Dalaran, you'll mount Arcanist's Manasaber anywhere in the
Broken Isles *except* in zones where you have set zone-specific mounts.

Keep in mind that continent is just what the game refers to as the continent.
Instances for example aren't generally considered in a continent as you'd expect
them to be. So instances generally won't use your continent-default mount, but you
can use `/SetMount` to set mount preferences for that instance.

You can also set even more general-purpose defaults on your character:

	/SetGroundMount Ochre Skeletal Warhorse
	/SetFlyingMount Armored Bloodwing

Those commands set two default mounts for your current character that will be used
if there is no zone-specific mount as well as no continent-specific mount for your
current location.

You can also set a mount to be used whenever you are in a party or raid group.
This will override any other default mounts for the zone or continent, but if you
have a two-seater, it's useful.

	/SetGroupMount Obsidian Nightwing

Finally, you can set a mount to be used whenever you mount up while in the water.
Unfortunately, I haven't figured out how to tell if you're underwater or not, so
I have a hard time deciding between the following two mounts:

	/SetSwimmingMount Azure Water Strider
	/SetSwimmingMount Sea Turtle

## Clearing a default mount preference

To remove a mount preference that you previously set, you just need to type the
same slash command, but without passing it a mount name. So for example, if you
want to remove your zone-specific mount for a certain zone, and have it default
back to your continent-specific mount, just type:

	/SetMount

And similarly, if you wanted to remove your continent-specific mount preference:

	/SetContinentMount

## Low-Level Players

If you are under level 20, then the `/MountUp` command will always try to use the
heirloom chauffer mount if it can. Otherwise, it'll do nothing.
