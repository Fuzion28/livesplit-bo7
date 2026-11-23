LIVESPLIT BO7 by Redouan B & Fuzion28  -  version 1.0.4-alpha
=============================================================

An in-game speedrun splitter and practice tool for Black Ops 7 Zombies on the
Kronos offline client. ALPHA: expect bugs, and please report them.

FEATURES
--------
- In-game splitter with splits per map, personal bests (PB), best segments and
  a live +/- delta against your PB.
- PB ghost: see where your best run was at the same moment.
- Practice menu in the pause menu (rounds, points, perks, weapons, powerups,
  teleports and more).
- Optional link with the LiveSplit desktop program (auto start, split, reset).
- RNG: PATCHED (practice only, see below) for Totenreich and Astra Malorum.

Supported maps for splits: Ashes of the Damned, Astra Malorum, Paradox Junction,
Totenreich, Kowakujo, Rex Infernus.

INSTALL
-------
1. Close the game and the Kronos launcher.
2. Copy the folder "livesplit_bo7" into:
      <your Kronos game folder>\kronos\mods\
   so you get  ...\kronos\mods\livesplit_bo7\mod.json
3. Start the Kronos launcher and enable "Livesplit BO7 by Redouan B".
   The launcher compiles the scripts itself on first start.
4. Do not run it together with another speedrun or splitter mod (both would use
   the same settings). A red bar at the top warns you if one is still enabled.

Your times are saved in  kronos\livesplit_bo7\  (not in the mod folder), so
updating the mod keeps your PBs.

RNG: PATCHED vs RNG: REAL
-------------------------
In the pause menu you can switch between:
- RNG: REAL     = the game's own randomness. Use this for real runs.
- RNG: PATCHED  = fixed outcomes to practise routes faster:
    Totenreich:    fish spot, ravager spawns, crate (always the AA shell),
                   the 3 symbols and the radio code are fixed.
    Astra Malorum: the O.S.C.A.R. planet code is always 3-4-6.
While PATCHED is on, the HUD shows an RNG tag. Runs made with RNG: PATCHED are
practice runs and are not valid for leaderboards.
Changes take effect from the next run (START SPEEDRUN); the crate changes at once.

LIVESPLIT DESKTOP (OPTIONAL)
----------------------------
1. In LiveSplit: right-click > Edit Layout > "+" > Control > Scriptable Auto Splitter.
2. In its settings, set the script path to:
      ...\kronos\mods\livesplit_bo7\livesplit\livesplit_bo7.asl
3. The script only reads the file kronos\livesplit_bo7\live.json that the mod
   writes. It never reads or writes game memory.
IMPORTANT: only use this with the Kronos offline client. Close LiveSplit before
you start any official / online version of the game.

KNOWN ISSUES (ALPHA)
--------------------
- Ashes of the Damned has splits but no RNG fixes yet (coming later).
- The first run after installing may take a few seconds longer to load while
  the scripts compile.

CREDITS
-------
Made by Redouan B & Fuzion28.
Fuzion28 made the original speedrun splitter this project grew from.
