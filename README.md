# reskate-arm64

[ReSkate](https://github.com/Dingo-Shenanigans/ReSkate), the offline,
multiplayer and modding runtime for EA's skate., on ARM64 Linux handhelds such
as the Retroid Pocket 6 with ArmadaOS.

skate. is a Windows x86-64 game, so on these handhelds it runs under Proton
with FEX emulating x86-64; there is no native port. ReSkate itself works there
with three changes, which this repository carries:

- Its launcher loads `ReSkate.dll` into the game on a thread it creates from
  outside, and under FEX such a thread never starts. The patched launcher
  makes the game's own main thread, held at its entrypoint, do the loading.
- `ReSkate.dll` suspends every thread of the game each time it installs a
  hook. Under FEX a thread can stay stopped after that, holding a lock the
  others need, and the game hangs on a black screen once its window opens.
  Under Wine the patched DLL installs hooks without suspending threads.
- `ReSkate.dll` reads game memory with a plain copy that catches an access
  violation when the address is bad, or with `ReadProcessMemory`, which
  faults inside Wine the same way. Under FEX such a fault can unwind to the
  wrong place and close the game. Under Wine the patched DLL first checks the
  pages with `VirtualQuery` and copies only readable memory, so a bad address
  never faults. Each thread remembers the readable regions it found for a
  quarter of a second, so the check costs little on reads made every frame.

On Windows all three behave as before.

This repository is an overlay: a patch, scripts and CI. It never contains the
game or files from it.

## Install on the Retroid Pocket 6 (ArmadaOS)

You need skate. in your Steam library (it is free) and about 14 GB free.

1. In Desktop Mode, open a terminal and run:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/Ken5998/reskate-arm64/main/scripts/setup-armadaos.sh | bash
   ```

   It puts ReSkate, the patched launcher and the patched `ReSkate.dll` in `~/ReSkate` and downloads the
   game build ReSkate supports with the native ARM64
   [DepotDownloader](https://github.com/SteamRE/DepotDownloader) (the
   launcher's own Windows copy crashes under FEX). Scan the QR code it shows
   with the Steam app.
2. In Steam, skate. > Properties:
   - Compatibility: **Proton Experimental**, the x86_64 one, not arm64.
   - Launch options: the line the script printed, for example

     ```
     bash -c 'exec "${@/*EAAntiCheat.GameServiceLauncher.exe//var/home/armada/ReSkate/ReSkateLauncher.exe}"' -- /usr/libexec/armada/armada-game-launch %command%
     ```
3. Press Play on skate.: the ReSkate launcher opens; press PLAY there.

If you first tried an arm64 Proton, delete the game's prefix
(`~/.local/share/Steam/steamapps/compatdata/3354750`) before using the x86_64
one: its Visual C++ libraries are the wrong architecture and Skate.exe stops
in the loader.

## Speed

skate. moves the game on by one step per frame, so below 60 frames a second
everything runs in slow motion even when the screen still shows 60 fps (that is
gamescope's count, not the game's). ReSkate's Performance HUD (in its settings,
under PERFORMANCE) shows the real figure on the CLIENT line: a client frame over
16.7 ms means slow motion.

ReSkate's engine tweaks, normally set from its console, can be set from the
launch options too, before `bash -c`: `RESKATE_PERF_GI=30` updates the global
illumination 30 times a second instead of every frame, `RESKATE_PERF_MESHTREE=1`
culls meshes through the game's octree, and `RESKATE_PERF_JOBWAKE=50` lets idle
job workers spin for 50 µs. Try one at a time and compare the CLIENT line.
`RESKATE_UI_POINTER_PAD_ONLY=1` skips the game's per-frame mouse hit-test for
good: worth it when you only play on the pad, but mouse hover and clicks in the
game's menus stop working.

## What is here

| Path | What it does |
| --- | --- |
| `upstream.json` | The ReSkate release and commit the patch is for, and the Steam depot and manifest of the game build it supports. |
| `patches/` | The five changes. Under Wine the launcher calls into the game on its gated primary thread instead of `CreateRemoteThread` (`RESKATE_REMOTE_THREAD_INJECTION=1` turns it off), hooks are installed without suspending threads (`RESKATE_HOOK_SUSPEND_THREADS=1` turns it off), memory reads check the pages first so they never fault (`RESKATE_PEEK_EXCEPTIONS=1` turns it off), and the UI pointer hit-test is skipped while the game's mouse is still unknown (`RESKATE_UI_POINTER_UNKNOWN_TESTS=1` turns it off; what turns the game's cursor on is logged, and `RESKATE_UI_POINTER_PAD_ONLY=1` skips it always); the engine tweaks also read `RESKATE_PERF_*` launch values. |
| `scripts/prepare.sh` | Checks out ReSkate at that commit and applies the patches. |
| `scripts/build.sh` | Builds `ReSkateLauncher.exe` and `ReSkate.dll` with Visual Studio 2022 and Rust, as CI does on Windows. |
| `scripts/setup-armadaos.sh` | The install above. |

Releases hold only `ReSkateLauncher.exe` and `ReSkate.dll`; everything else
comes from ReSkate's own release of the same version. These builds never
update themselves, so ReSkate's own updates do not replace them.

## License

GPL-3.0, as ReSkate; see LICENSE and NOTICE. ReSkate is a fan project, not
affiliated with or endorsed by Electronic Arts or Full Circle, and neither is
this repository.
