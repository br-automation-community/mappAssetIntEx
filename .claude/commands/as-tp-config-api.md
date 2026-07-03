---
description: Discover which XML elements are allowed inside a B&R Automation Studio technology-package configuration file (files under Physical/<config>/<cpu>/mapp*). Use before hand-editing any mapp* config file.
argument-hint: "GetConfigElements -TechnologyPackage <tp> [-TPVersion <v>] -FileEnding <.ending> [-ParentElement <path>] | ListFileEndings -TechnologyPackage <tp>"
allowed-tools:
  - Bash
  - Read
---

Automation Studio technology-package configuration helper — discovers, live from the AS installation, which XML nodes a deployed config file is allowed to contain.

The user requested: $ARGUMENTS

## Script

```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-tp-config-api/scripts/use-as-tp-config-api.ps1 `
  -TechnologyPackage <tp> [-TPVersion <version>] -Action <action> [options]
```

## Actions

### List valid file endings for a technology package
```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-tp-config-api/scripts/use-as-tp-config-api.ps1 `
  -TechnologyPackage mappServices -Action ListFileEndings
```

### Discover allowed config elements (root level, shallow)
```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-tp-config-api/scripts/use-as-tp-config-api.ps1 `
  -TechnologyPackage mappMotion -TPVersion 6.6.1 -FileEnding .axis
```

### Drill into a sub-element
```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-tp-config-api/scripts/use-as-tp-config-api.ps1 `
  -TechnologyPackage mappMotion -FileEnding .axis -ParentElement "BaseType/RotaryPeriodic"
```

## Parameters

| Parameter | Description | Default |
|---|---|---|
| `-TechnologyPackage` | `mappMotion`, `mapp6D`, `mappServices`, `mappControl`, `mappVision`, … | required |
| `-TPVersion` | Package version (e.g. `6.6.1`) | highest installed |
| `-Action` | `GetConfigElements` or `ListFileEndings` | `GetConfigElements` |
| `-FileEnding` | Config file ending (e.g. `.axis`) | required for `GetConfigElements` |
| `-ParentElement` | `Root` or `/`-delimited node-ID path to drill into | `Root` |
| `-MaxDepth` | Levels to expand below scope; `-1` = unlimited | `1` |
| `-MaxElements` | Safety budget on total nodes per call | `500` |

## Drill-Down Approach (Shallow by Default)

Responses are shallow by default (`-MaxDepth 1`). Container nodes with content are collapsed to stubs (`hasChildren: true`, `childCount`). Call again with `-ParentElement` to drill deeper.

## Translating JSON to Config XML

The JSON response describes which nodes are legal. The file skeleton is:

```xml
<?xml version="1.0" encoding="utf-8"?>
<?AutomationStudio FileVersion="4.9"?>
<Configuration>
  <Element ID="<your-unique-id>" Type="<file-ending-without-dot>">
    <!-- JSON elements go here -->
  </Element>
</Configuration>
```

- `Property` → `<Property ID="..." Value="..." />`
- `Group`/`Struct` → `<Group ID="...">` wrapping children
- `Selector` → `<Selector ID="..." Value="<selection-id>">` wrapping chosen selection's children
- Array node (`id` contains `[%I]`) → use `idExample` for concrete instance IDs (e.g. `Segment[1]`)
- Only author nodes where `editable: true`

## Notes

- Windows only. Requires PowerShell 5.1+ and an installed Automation Studio with the requested technology package.
- Read-only: never modifies the AS installation or the project.
