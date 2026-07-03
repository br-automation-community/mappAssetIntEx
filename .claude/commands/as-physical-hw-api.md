---
description: Add, search, or describe hardware modules in a B&R Automation Studio project. Updates Hardware.hw correctly using AS installation .hwx metadata. Also lists I/O channels, possible connections, and module configuration properties.
argument-hint: "AddHWModule <type> [version] | SearchHWModule <pattern> | SearchByClassification <keyword> | GetHWModuleInfo <type> | GetIOMappingConfig <type> | GetPossibleHWConnections <type> | GetModuleProperties <type> | GetPermittedHwClassifications"
allowed-tools:
  - Bash
  - Read
  - Edit
  - mcp__as-help__search_help
  - mcp__as-help__get_page_by_id
---

Automation Studio Physical hardware helper — adds, searches, and describes hardware modules using AS installation `.hwx` metadata.

The user requested: $ARGUMENTS

> **IMPORTANT:** If `GetHWModuleInfo` output contains `"CPU"` in `HardwareModuleType`, it is **PROHIBITED** to add that module with `AddHWModule`. Adding a second CPU will corrupt the hardware configuration.

## Script

```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-physical-hw-api/scripts/use-as-physical-hw-api.ps1 `
  -ProjectPath . -Action <action> [options]
```

## Mandatory Preconditions Before Adding a Module

Before adding an unknown module, choose the lookup strategy:

1. **Keyword-first**: Run `GetPermittedHwClassifications` first, then `SearchByClassification <keyword>`, then `GetHWModuleInfo` to confirm specs.
2. **Context-first**: Use `mcp__as-help__search_help` and `mcp__as-help__get_page_by_id` to research the product, then use the confirmed identifiers in `SearchHWModule`/`GetHWModuleInfo`.

## Actions

### Search by module type pattern
```powershell
... -Action SearchHWModule -HwModuleType "X20DO"
```

### Search by classification keyword (list permitted classifications first)
```powershell
... -Action GetPermittedHwClassifications
... -Action SearchByClassification -ClassificationKeyword "PPC3100"
# Boolean operators supported: | (OR), & (AND), - (NOT)
# Example: "X20 & Digital | Acopos6D"
```

### Get module description
```powershell
... -Action GetHWModuleInfo -HwModuleType "X20DI8371"
```

### Add a hardware module
```powershell
... -Action AddHWModule -HwModuleType "80VD100PD.C088-01"
# Optionally specify version: -HwModuleVersion "2.5.1.0"
```

### Get I/O mapping configuration
```powershell
... -Action GetIOMappingConfig -HwModuleType "X20DO2322"
```

### Get possible hardware connections
```powershell
... -Action GetPossibleHWConnections -HwModuleType "X20DO2322"
```

### Get module configuration properties (drill-down approach)
```powershell
... -Action GetModuleProperties -HwModuleType "X20CP1686X"
# Drill deeper: -ParentElement "DriveConfiguration/Channel[1]/RealAxis" -MaxDepth 2
```

## Parameters

| Parameter | Description | Default |
|---|---|---|
| `-ProjectPath` | Path to AS project directory | required |
| `-Action` | See actions above | `AddHWModule` |
| `-HwModuleType` | Module type or search pattern | required |
| `-ClassificationKeyword` | Keyword for `SearchByClassification` | required |
| `-HwModuleVersion` | Specific module version | highest installed |
| `-HwFileName` | `.hw` file to register module in | `Hardware.hw` |
| `-ParentElement` | For `GetModuleProperties`: node path to drill into | `Root` |
| `-MaxDepth` | Levels to expand below scope (`-1` = unlimited) | `1` |

## Notes

- Windows only. Requires B&R Automation Studio 6.x and PowerShell 5.1+
- Read actions (`Search*`, `Get*`) do not write any project files
- `SearchHWModule` returns an error if more than 100 modules match — use a more specific pattern
