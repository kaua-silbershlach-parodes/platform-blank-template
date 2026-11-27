# Extractor Blank Template

Blank template from **A Elite Estrangeira** for building a Windows
Explorer context-menu archive extractor for any archive format. It
lives in the context menu only — there is no application window to
open — and ships with signed GitHub auto-updates.

## What the base includes

- Format detection by extension with a magic-byte fallback
- Built-in formats: ZIP, JAR, EPUB, Office documents, 7Z, RAR, TAR,
  TAR.GZ, TAR.BZ2, TAR.XZ, TAR.ZST, single-file GZ, BZ2, XZ, ZST
- ELITE as the reference custom format: TAR payload compressed with
  Zstandard (levels 1, 3, 9, 19), SHA-256 integrity, optional
  AES-256-GCM password encryption with Argon2id key derivation
- Context-menu verbs on archive files, folders, and folder background:
  Extract here, Extract to folder, List (writes a contents text file
  and opens it in Notepad), and Add to archive
- Zip-slip protection on every entry and SHA-256 reporting per
  extracted file
- Signed updates through this folder's `latest.json` feed, with
  installers published under the `extractor-v<version>` release tag

## Adding a format

Every format follows the same four steps in `src-tauri/src/lib.rs`:

1. Add a variant to the `Kind` enum.
2. Teach `detect` the new extension and magic bytes.
3. Add the list and extract arms for the new kind.
4. Add the extension to the `exts` list in
   `register_context_menu_inner` so Explorer shows the verbs for it.

Creation support is optional per format: ELITE and ZIP include it,
through the Add to archive dialog.

## Releases and updates

Installers are published in the platform repository's GitHub Releases
under the `extractor-v<version>` tag. The updater reads
`extractor-blank-template/latest.json` from this folder.

Copyright (c) A Elite Estrangeira.
