Brigandine Abyss — Russian text patch
=====================================

This folder patches an existing Steam install. It does not ship the game.

The Russian translation occupies the Simplified Chinese language slot.
In Options the slot is labeled «Русский».

Install
-------
1. Copy this entire AbyssRussian folder into:

     steamapps\common\HPN_NPJ

   or keep it next to BrigandineAbyss\Content\Paks.

2. Double-click PatchRussian.bat.

3. Start the game and set language to Русский (the former
   Simplified Chinese entry).

The patcher:
- Applies a Cyrillic font hdiff to the stock BrigandineAbyss-Windows.pak
  (no unpacking of game files on your machine).
- Copies z0RussianUI_P.pak / .ucas / .utoc into Content\Paks.

Uninstall
---------
Steam → Properties → Installed Files → Verify integrity of game files.
That restores the stock font pak. Then delete z0RussianUI_P.* from
BrigandineAbyss\Content\Paks.

Notes
-----
- After a Steam verify, run PatchRussian.bat again.

Font
----
The font patch embeds Noto Sans Regular (SIL Open Font License 1.1)
into the three Japanese UI font faces inside Windows.pak via hdiff.
See OFL.txt. Stock Windows.pak is 41,646,580 bytes; after the font
patch it is 30,672,341 bytes.

Alignment
---------
See VERIFY.txt. English keys were checked 1:1 against the patched
Simplified Chinese tables: no row sliding, no leftover Simplified
Chinese in translatable strings.
