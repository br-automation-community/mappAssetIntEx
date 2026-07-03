---
description: Utility helpers for B&R Automation Studio — list installed AS versions, get prohibited/reserved names, and validate variable or file names.
argument-hint: "GetInstalledVersions | GetProhibitedNames | CheckProhibitedName <name>"
allowed-tools:
  - Bash
---

Small utility helpers for working with the B&R Automation Studio tech stack and project environment.

The user requested: $ARGUMENTS

## Actions

### List Installed Automation Studio Versions

Use to discover which AS versions are installed and their paths (e.g. to find mappView widget source code).

```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-utility/scripts/get-as-installations.ps1
```

Output shows version, installation path, and shared data path for each installed AS version.

### Get Prohibited/Reserved Names

Use before naming PLC variables, files, or components to avoid reserved names.

```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-utility/scripts/get-prohibited-names.ps1
```

### Check if a Name is Prohibited

Use to validate a specific name before using it in the project.

```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-utility/scripts/check-prohibited-name.ps1 -Name "<name>"
```

Output: `NAME PROHIBITED` or `NAME ALLOWED`

Wildcards supported: e.g. `Ar*` matches all names starting with `Ar`.

## Notes

- Windows only. Requires PowerShell 5.1+
- No parameters needed for `GetInstalledVersions` and `GetProhibitedNames`
