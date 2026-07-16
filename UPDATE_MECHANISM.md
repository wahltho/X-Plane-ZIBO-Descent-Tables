# Zibo VNAV Tables Update Mechanism Target

Last updated: 2026-07-16
Repository: `https://github.com/wahltho/X-Plane-ZIBO-Descent-Tables`

This document describes the target update model for the custom Zibo VNAV
descent table package. The package can be consumed by YAL's own update engine,
parallel to the separate LevelUp standalone installer. The two implementations
can share the same conservative concepts -- manifests, hashes, staging,
dry-run, backups and install-state classification -- while staying separate in
ownership and release process.

## Goals

- Keep the VNAV table package separately versioned from any installer or host
  application.
- Use authorized GitHub Releases as the package source of truth.
- Do not use the `main` branch or auto-generated GitHub ZIP files as a stable
  update API.
- Do not redistribute Zibo's complete `B738.a_fms.lua`.
- Install only approved payload files and declarative patch fragments.
- Patch the user's local aircraft installation transactionally.
- Verify payload hashes before touching aircraft files.
- Preserve the target file's LF/CRLF line endings and normal file permissions.
- Refuse unclear or unsafe patch states instead of overwriting unknown local
  changes.
- Detect when a Zibo update has replaced `B738.a_fms.lua` and offer a clean
  reinstall of the package.

## Current Package Shape

Current package identity:

- package ID: `x-plane-zibo-vnav-descent-tables`
- package version: `v0.2.0`
- release tag: `v0.2.0`
- aircraft family: `zibo_upstream`
- target script:
  `plugins/xlua/scripts/B738.a_fms/B738.a_fms.lua`

Current distributable payload:

- `B738.a_fms_zibo_tables.lua`
- `Add_dofile.txt`
- `Add_to_take_alt_dist.txt`
- `Add_to_take_alt_dist_mach.txt`
- `package-manifest.txt`
- installer tooling, if included in the release

The package must not include a full or modified copy of `B738.a_fms.lua`.

## Patch Contract

The package has three patch operations:

1. Install the table payload next to `B738.a_fms.lua`.
2. Insert the marked `dofile()` block below:
   `jit.off()`
3. Insert the marked VNAV hook blocks below:
   `function take_alt_dist(x_idx_alt, x_spd_alt, x_spd_wnd_alt, x_flap)`
   and
   `function take_alt_dist_mach(x_idx_alt, x_spd_alt, x_spd_wnd_alt)`

Current markers:

- `-- BEGIN ZIBO_VNAV_DESCENT_TABLES DOFILE`
- `-- END ZIBO_VNAV_DESCENT_TABLES DOFILE`
- `-- BEGIN ZIBO_VNAV_DESCENT_TABLES KIAS`
- `-- END ZIBO_VNAV_DESCENT_TABLES KIAS`
- `-- BEGIN ZIBO_VNAV_DESCENT_TABLES MACH`
- `-- END ZIBO_VNAV_DESCENT_TABLES MACH`

Known legacy signatures:

- `dofile("B738.a_fms_zibo_tables.lua")`
- `pcall(B738_variant_test_take_alt_dist,`
- `pcall(B738_variant_test_take_alt_dist_mach,`

The existing Python installer already implements the core patch behavior:

- byte-based target file handling
- LF/CRLF preservation
- marked-block replacement
- legacy hook migration
- duplicate hook avoidance
- first backup creation

YAL's update engine should port that behavior into a reusable patch-core
instead of shelling out to Python. End users should not need a Python
installation.

## Version Ownership

Keep the version layers separate:

1. **YAL update engine**
   - owned and shipped by YAL
   - follows YAL's own plugin version and release channel
   - implements manifest download, hash verification, staging, patching,
     backup, repair and uninstall
   - remains separate from the LevelUp standalone installer

2. **Zibo VNAV content package**
   - own package version
   - own manifest
   - own payload hashes
   - own GitHub Release tags
   - installed by YAL's patch engine when the user explicitly chooses it

3. **LevelUp standalone installer**
   - separate application and release process
   - can use VeloPack for its own application updates
   - may consume a LevelUp-specific VNAV content package
   - does not own YAL's updater implementation

YAL's update engine may support multiple package types over time, for example:

- YAL runtime-safe plugin content updates
- Zibo 737-800X custom VNAV descent tables

The shared YAL implementation may reuse detection, manifest download, hash
verification, backup, dry-run, install, repair and uninstall logic. The package
manifests must still remain package-specific.

## Release Source

Target release source:

- GitHub Releases from
  `https://github.com/wahltho/X-Plane-ZIBO-Descent-Tables`
- tagged package releases such as `v0.2.0`
- release assets containing the payload and manifest
- optional future JSON manifest and detached signature

Do not depend on:

- `main`
- GitHub's auto-generated source ZIP
- raw branch URLs
- untagged repository state

YAL's update engine should query release metadata, select the requested channel
and download only release assets that match the package manifest.

## Manifest Direction

`package-manifest.txt` can remain the compatibility manifest. A future JSON
manifest can be added beside it when stronger structure is useful.

Suggested JSON shape:

```json
{
  "schemaVersion": 1,
  "packageId": "x-plane-zibo-vnav-descent-tables",
  "packageVersion": "v0.2.0",
  "releaseTag": "v0.2.0",
  "releaseChannel": "stable",
  "repository": "https://github.com/wahltho/X-Plane-ZIBO-Descent-Tables",
  "supportedAircraft": [
    {
      "family": "zibo_upstream",
      "displayName": "Zibo 737-800X",
      "xPlaneVersions": ["12"]
    }
  ],
  "targetPaths": [
    {
      "id": "zibo-fms-lua",
      "relativePath": "plugins/xlua/scripts/B738.a_fms/B738.a_fms.lua"
    }
  ],
  "payloads": [
    {
      "id": "table",
      "path": "B738.a_fms_zibo_tables.lua",
      "size": 14119,
      "sha256": "c97042b2384ab28545c76c5ec8db631c68265895c06fab7c1bff8327d8668b37"
    }
  ],
  "patchOperations": [
    {
      "id": "dofile",
      "targetPathId": "zibo-fms-lua",
      "anchor": "jit.off()",
      "beginMarker": "-- BEGIN ZIBO_VNAV_DESCENT_TABLES DOFILE",
      "endMarker": "-- END ZIBO_VNAV_DESCENT_TABLES DOFILE",
      "fragment": "Add_dofile.txt",
      "legacySignatures": ["dofile(\"B738.a_fms_zibo_tables.lua\")"]
    }
  ],
  "restartRequired": true
}
```

Migration rule:

- continue reading `package-manifest.txt`
- accept JSON manifest when present and schema-valid
- prefer SHA-256 from the JSON manifest
- require all declared hashes to pass before patching
- keep legacy signatures for migration only, not as a long-term install marker

## Target Detection

YAL's updater should not trust folder names alone.

Accept a Zibo target only when structural signatures are present, such as:

- target aircraft folder contains the expected Zibo script path
- `plugins/xlua/scripts/B738.a_fms/B738.a_fms.lua` exists
- `B738.a_fms.lua` contains the expected anchor functions
- the aircraft is not a LevelUp variant target
- the path is writable or can be made writable with explicit user action

Support:

- multiple X-Plane installations
- multiple Zibo installations
- Steam and standalone X-Plane folders
- manual folder override
- renamed aircraft folders
- symlinks
- read-only target detection with a clear blocked state

Reject:

- missing or duplicate patch anchors
- missing target script
- non-Zibo targets
- unsupported X-Plane 11 targets unless a separate package declares support
- paths that would escape the aircraft folder after normalization

## Install State Classification

Classify the target before offering an action:

- `not-installed`
- `installed-current`
- `installed-older-marked`
- `legacy-v0.1.0`
- `partially-installed`
- `overwritten-by-zibo-update`
- `foreign-modified`
- `blocked-unsupported-target`
- `blocked-read-only`

Examples:

- Table file present but hook blocks missing: likely `overwritten-by-zibo-update`
  after a Zibo update.
- Marked blocks present with older package version: `installed-older-marked`.
- Legacy hook signatures present without markers: `legacy-v0.1.0`.
- Duplicate anchors or duplicate package blocks: stop and offer diagnostics.
- Unknown edits inside the target function before/around anchors: stop unless
  the manifest explicitly supports the case.

## Transaction Flow

1. Validate selected aircraft folder.
2. Check whether X-Plane is running.
3. Fetch release metadata and manifest over HTTPS.
4. Validate package version and manifest schema.
5. Download payloads into a staging folder.
6. Verify file size and SHA-256.
7. Normalize every target path and reject traversal.
8. Read the target script as bytes.
9. Detect encoding, BOM behavior and line endings.
10. Find anchors, markers and legacy signatures.
11. Classify install state.
12. Build a dry-run plan.
13. Create an exact backup with metadata.
14. Generate patched files in temporary paths.
15. Validate patched structure:
    - exactly one dofile block
    - exactly one KIAS hook block
    - exactly one Mach hook block
    - no duplicate legacy hooks
    - target file remains UTF-8
16. Replace files as atomically as the platform allows.
17. Write install-state metadata.
18. On failure, restore from the transaction backup when possible.
19. Show restart-required.

## Backup and Restore

The current Python installer writes `B738.a_fms.backup` once and never
overwrites it. That is acceptable for the simple script, but the GUI updater
should use a stronger model.

Target backup metadata:

- aircraft installation ID
- target file relative path
- original SHA-256
- package ID and package version
- timestamp
- installed markers and payload hashes
- backup file location

Rules:

- keep backups per aircraft installation
- keep multiple backup generations
- never blindly overwrite a generic `.backup`
- distinguish restore, repair and uninstall
- do not restore an old backup over a later legitimate Zibo update
- if the target file changed after package installation, prefer uninstall by
  marker removal instead of full-file restore

## Repair and Uninstall

Repair should:

- verify payload hashes
- reapply missing or outdated marked blocks
- migrate known legacy blocks
- reinstall the table payload if missing
- stop on unknown target changes

Uninstall should:

- remove only package-owned marked blocks
- remove the package payload if it still matches the installed payload hash
- leave unknown or user-modified files untouched
- keep backups and install logs unless the user explicitly deletes them

Restore should:

- use an exact backup only when it still matches the expected restoration case
- refuse to overwrite a newer Zibo target file without explicit diagnosis

## Relationship to YAL and LevelUp

The same content-update principles can support:

- YAL's internal runtime-safe plugin updates
- YAL-managed Zibo 737-800X custom VNAV descent table packages
- the separate LevelUp standalone installer and its LevelUp VNAV package

The shared rules are:

- package manifest is the content source of truth
- release assets are downloaded from authorized releases
- payloads are hash-verified before install
- install logic is dry-run capable
- user installations are patched locally
- package content is versioned separately from any updater app

The differences are:

- YAL implements its own update engine inside the plugin.
- YAL's own updates copy runtime-safe plugin files and block native binaries.
- YAL-managed Zibo VNAV package updates patch aircraft Lua files using anchors
  and marked fragments.
- LevelUp can implement the same package discipline through its separate
  standalone VeloPack installer.

## Practical Next Step

Short term:

- keep `package-manifest.txt` as the compatibility manifest
- publish packages through GitHub Releases
- port the Python patch contract into YAL's testable patch-core
- add dry-run, install, repair, uninstall and diagnostics around that core

Medium term:

- add a JSON manifest beside `package-manifest.txt`
- add per-aircraft install-state metadata
- add multi-generation backups
- keep YAL's Zibo package support parallel to the separate LevelUp standalone
  installer
