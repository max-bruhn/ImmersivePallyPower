# Immersive PallyPower

**All of PallyPower's paladin blessing management, with a cleaner modern look and an immersive buff bar — for vanilla WoW 1.12 private servers.**

PallyPower is the classic addon for coordinating paladin blessings in a raid: assign who buffs which class, and get a buff bar that shows how many players are missing each blessing. Immersive PallyPower keeps **all of that** and adds:

- **Immersive buff bar** — buttons show only when someone is actually missing that blessing; when everyone is buffed, the whole bar fades away. No more staring at a bar full of "0"s.
- **Modern theme** — one clean, flat, borderless bar with rectangular icons, instead of the boxed default look. Classic theme kept for those who prefer the original.
- **Configurable layout** — grow vertical or horizontal, set the number of columns/rows, and scale the size.
- **One tidy options window** — the immersive/layout settings and PallyPower's own options, together in a modern panel (`/ipp`).

> Tested on Turtle WoW **1.17** and **1.18** clients, including **OctoWoW** and **Capycraft**.

> ⚠️ This replaces PallyPower. **Don't run both at once** — disable the original PallyPower if you have it.

## Install

1. Download the ZIP from the [latest release](../../releases/latest) and unpack it.
2. Put the `ImmersivePallyPower` folder into your `Interface\AddOns\` folder
   (so that `Interface\AddOns\ImmersivePallyPower\ImmersivePallyPower.toc` exists).
3. Restart the game.

If you used the green **Code → Download ZIP** button, rename the unpacked `ImmersivePallyPower-main` folder to just `ImmersivePallyPower`, or the game won't load it.

## Using it

- Type **`/ipp`** to open the options window.
- Settings: immersive mode, show-only-missing, grow direction, columns, size, spacing, and Modern/Classic theme. PallyPower's own options (smart buffs, chat feedback, blessing type) are in the same window.
- Everything else works exactly like PallyPower — assign blessings in the raid-lead window, click a buff button to cast.

## Credits & license

A fork of **Relar's PallyPower for Turtle WoW**. Original PallyPower by **Sneakyfoot**; Turtle-WoW updates and fixes by **Rake/Xerron**, **Relar**, and **Eiriss**. This fork adds the immersive bar, themes, and layout options on top of their work.

Released under the same open license as the original. This project is not affiliated with or endorsed by the original authors.
