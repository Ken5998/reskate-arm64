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
  never faults.

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

## What is here

| Path | What it does |
| --- | --- |
| `upstream.json` | The ReSkate release and commit the patch is for, and the Steam depot and manifest of the game build it supports. |
| `patches/` | The three changes. Under Wine the launcher calls into the game on its gated primary thread instead of `CreateRemoteThread` (`RESKATE_REMOTE_THREAD_INJECTION=1` turns it off), hooks are installed without suspending threads (`RESKATE_HOOK_SUSPEND_THREADS=1` turns it off), and memory reads check the pages first so they never fault (`RESKATE_PEEK_EXCEPTIONS=1` turns it off). |
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
