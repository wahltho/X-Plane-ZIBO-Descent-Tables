# Customized VNAV descent tables for the Zibo 737-800X

## Introduction

This repository provides a do-it-yourself installer for customized VNAV descent
distance tables for the Zibo 737-800X in X-Plane 12.

The package is intentionally small: it does not redistribute Zibo's
`B738.a_fms.lua`. Instead, the installer edits the user's existing local copy of
that file and adds a separate table file plus two hook blocks.

## Background

The Zibo 737-800X VNAV descent distance calculation is driven in part by Lua
tables inside `B738.a_fms.lua`. This package provides a source-backed clean
descent table model for the Zibo 737-800X / CFM56-7B26 path, using the same data
package that is used by the local C++ port work.

This package only targets the normal Zibo 737-800X path. LevelUp 737NG variants
are handled separately in the LevelUp-specific package.

## Disclaimer

Before you install or use this, you must acknowledge that:

- This only changes the Lua VNAV descent distance table path used by
  `take_alt_dist()` and `take_alt_dist_mach()`.
- It does not change the autopilot, autothrottle, flight model, speedbrake
  logic, pitch servo logic, or any C++ plugin behavior.
- This installer is unofficial and is not supported by Zibo.
- To avoid redistributing Zibo's Lua source, `B738.a_fms.lua` must be edited on
  the user's local installation.
- After every update that replaces `B738.a_fms.lua`, the installation must be
  repeated.

## Activation

Once installed, the custom table code activates only when the Zibo variant
dataref resolves to the normal 737-800X path:

- `laminar/B738/73x == 0`: use the custom Zibo 737-800X descent table model.
- Any other value: return to the original Lua behavior.

Unsupported speed schedules, non-clean flap descent, invalid weights, missing
datarefs, or failed calculations also fall back to the original Lua behavior.

## Content

This repository contains:

- `B738.a_fms_zibo_tables.lua`: the custom Zibo 737-800X descent table model.
- `Add_dofile.txt`: marked `dofile()` fragment for loading the table file.
- `Add_to_take_alt_dist.txt`: hook block for `take_alt_dist()`.
- `Add_to_take_alt_dist_mach.txt`: hook block for `take_alt_dist_mach()`.
- `package-manifest.txt`: machine-readable package metadata for external tools.
- `z_Install.py`: a Python installer that modifies `B738.a_fms.lua`, preserves
  the file's LF/CRLF line endings, creates a backup before modification, and
  avoids duplicate hook insertion.

## Requirements

- Zibo 737-800X for X-Plane 12.
- Python 3.10 or newer for the standalone installer.

## Installation

Close X-Plane and extract the complete package to a separate folder outside
Zibo's aircraft directory. Do not copy the runtime files into the aircraft first.
From the extracted package, run:

```text
python3 z_Install.py --aircraft-root "/path/to/Zibo aircraft"
```

On Windows, use `py -3` instead of `python3`. Python 3.10 or newer is required.
The installer backs up the original script and table file, writes its own receipt,
and adds the same marked VNAV hooks as before. Run the same command to update or
verify an installation made by this installer.

To remove it, close X-Plane and run:

```text
python3 z_Install.py --aircraft-root "/path/to/Zibo aircraft" --uninstall
```

Removal uses the recorded originals for the table file and removes only the VNAV
blocks from the shared Lua script. Other patches and unrelated edits are retained.

## Manual Installation

Manual edits have no installer receipt and cannot be adopted by MTK or the
standalone installer. Keep the original backup and undo those edits before
switching installation methods. Make a backup of
`B738.a_fms.lua` before you begin.

1. Add all lines from `Add_dofile.txt` directly below `jit.off()`.

2. Add all lines from `Add_to_take_alt_dist.txt` directly below:

   ```lua
   function take_alt_dist(x_idx_alt, x_spd_alt, x_spd_wnd_alt, x_flap)
   ```

3. Add all lines from `Add_to_take_alt_dist_mach.txt` directly below:

   ```lua
   function take_alt_dist_mach(x_idx_alt, x_spd_alt, x_spd_wnd_alt)
   ```

## Machine-Readable Package Metadata

This package includes `package-manifest.txt` for external tools that need to
identify, verify or install the release payloads without relying on the
human-readable README.

The target updater model is described in `UPDATE_MECHANISM.md`. It allows YAL
to implement the update algorithm itself, parallel to the separate LevelUp
standalone installer. The VNAV table package remains separately versioned, uses
GitHub Releases as the package source of truth, and preserves the rule that the
user's local `B738.a_fms.lua` is patched locally rather than redistributed.

The manifest lists the package ID, package version, release tag, aircraft
family, repository URL, target Lua path, payload filenames, file sizes,
SHA-256 hashes, patch anchors, stable block markers and legacy hook signatures.

- `B738.a_fms_zibo_tables.lua`
- `Add_dofile.txt`
- `Add_to_take_alt_dist.txt`
- `Add_to_take_alt_dist_mach.txt`

The manifest does not bind the package to a hash of the complete upstream
`B738.a_fms.lua`, because that file can legitimately change with aircraft
updates.

Legacy signatures remain documented so older patches can be identified. The
new installer does not adopt an unmarked or manually patched installation.
Restore it with the original installer and backups before installing again.

## Troubleshooting

If the custom behavior does not appear to activate:

- Confirm that `B738.a_fms_zibo_tables.lua` is present in the same folder as
  `B738.a_fms.lua`.
- Confirm that `B738.a_fms.lua` contains the `dofile()` line.
- Confirm that both hook blocks were inserted below the correct functions.
- Re-run the installer after any Zibo update that replaced `B738.a_fms.lua`.

If the custom calculation cannot be used for a specific situation, the hook
returns `nil` and the original Lua calculation continues.

## Installation ownership

MTK and the standalone installer remain separate supported installation methods.
Use the same owner for updates and removal. To switch, uninstall through the
current owner first, then install through the other. Neither installer adopts
already patched files on the strength of matching hashes alone.

Keep the complete extracted package, including `standalone_guard.py` and
`standalone-ownership.json`. The standalone installer checks its recorded
original backups and stops if MTK owns this patch or a shared target file.
Unknown, duplicate or incomplete patch blocks and unowned companion files also
block the operation. Other correctly installed patches are preserved.

A failed operation restores the bytes it changed. If the process is interrupted,
keep the `.patch-ownership` receipt, transaction journal and lock, together with
any older patch backup/state directory. Do not delete them to retry. Ask for
support before changing those files.

Older standalone installs without a complete receipt are not automatically
migrated. Remove them using the installer and original backups that created
them. This source change affects installation checks only; runtime payloads and
patch versions are unchanged. Installer and recovery tests cover these checks.
