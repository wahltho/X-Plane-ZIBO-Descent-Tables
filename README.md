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
- `Add_to_take_alt_dist.txt`: hook block for `take_alt_dist()`.
- `Add_to_take_alt_dist_mach.txt`: hook block for `take_alt_dist_mach()`.
- `z_Install.py`: a Python installer that modifies `B738.a_fms.lua`, preserves
  the file's LF/CRLF line endings, creates a backup before modification, and
  avoids duplicate hook insertion.

## Requirements

- Zibo 737-800X for X-Plane 12.
- Python 3 is recommended for automated installation.

## Installation

1. Download the repository files from GitHub, or download the release ZIP if one
   is available.

2. Move these files into the Zibo `plugins/xlua/scripts/B738.a_fms` folder:

   - `B738.a_fms_zibo_tables.lua`
   - `Add_to_take_alt_dist.txt`
   - `Add_to_take_alt_dist_mach.txt`
   - `z_Install.py`

3. From a terminal or console in the `B738.a_fms` folder, run:

   ```bash
   python3 z_Install.py
   ```

   On Windows, use `py z_Install.py` or `python z_Install.py` if `python3` is
   not available.

4. The installer creates `B738.a_fms.backup` if no backup exists yet, inserts:

   ```lua
   dofile("B738.a_fms_zibo_tables.lua")
   ```

   and adds the two VNAV descent hook blocks below:

   - `function take_alt_dist(x_idx_alt, x_spd_alt, x_spd_wnd_alt, x_flap)`
   - `function take_alt_dist_mach(x_idx_alt, x_spd_alt, x_spd_wnd_alt)`

## Manual Installation

Manual editing is only the fallback if Python is not available. Make a backup of
`B738.a_fms.lua` before you begin.

1. Add this line below `jit.off()`:

   ```lua
   dofile("B738.a_fms_zibo_tables.lua")
   ```

2. Add all lines from `Add_to_take_alt_dist.txt` directly below:

   ```lua
   function take_alt_dist(x_idx_alt, x_spd_alt, x_spd_wnd_alt, x_flap)
   ```

3. Add all lines from `Add_to_take_alt_dist_mach.txt` directly below:

   ```lua
   function take_alt_dist_mach(x_idx_alt, x_spd_alt, x_spd_wnd_alt)
   ```

## Troubleshooting

If the custom behavior does not appear to activate:

- Confirm that `B738.a_fms_zibo_tables.lua` is present in the same folder as
  `B738.a_fms.lua`.
- Confirm that `B738.a_fms.lua` contains the `dofile()` line.
- Confirm that both hook blocks were inserted below the correct functions.
- Re-run the installer after any Zibo update that replaced `B738.a_fms.lua`.

If the custom calculation cannot be used for a specific situation, the hook
returns `nil` and the original Lua calculation continues.
