---
description: Add a library or create a new Structured Text task in a B&R Automation Studio project. Keeps Package.pkg, Cpu.sw, and .apj technology package registrations correct without hand-editing XML.
argument-hint: "AddLibrary <name> [MinVersion] | AddSTTask <path> <name> [TaskClass]"
allowed-tools:
  - Bash
  - Read
---

Automation Studio Logical view helper — adds libraries and ST program tasks so that `Package.pkg`, `Cpu.sw`, and `.apj` technology package registrations are kept correct.

The user requested: $ARGUMENTS

## Script

```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-logical-api/scripts/use-as-logical-api.ps1 `
  -ProjectPath . -Action <action> [options]
```

## Actions

### Add a Library

Use when the user asks to add a library (e.g. `MTBasics`, `McAxis`, `MpAlarmX`, `AsIecCon`).

```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-logical-api/scripts/use-as-logical-api.ps1 `
  -ProjectPath . -Action AddLibrary -LibraryName MTBasics
```

With minimum version:
```powershell
... -LibraryName McAxis -MinVersion 6.0.0
```

Verify: the library appears in `Logical/Libraries/` and is referenced in `Cpu.sw`.

### Add a New ST Task

Use when the user asks to add a new task. Task names in `Cpu.sw` are limited to **10 characters**.

```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-logical-api/scripts/use-as-logical-api.ps1 `
  -ProjectPath . -Action AddSTTask -TaskPath Drive -TaskName ConvCtrl -TaskClass 4
```

Verify: `Logical/<TaskPath>/<TaskName>/` exists with `IEC.prg`, `Main.st`, `Types.typ`, `Variables.var`, and that `Package.pkg` and `Cpu.sw` include the new task.

## Parameters

| Parameter | Description | Default |
|---|---|---|
| `-ProjectPath` | Path to AS project directory | required |
| `-Action` | `AddLibrary` or `AddSTTask` | `AddLibrary` |
| `-LibraryName` | Library to add (for `AddLibrary`) | required |
| `-MinVersion` | Minimum version constraint for the library | none |
| `-TaskPath` | Folder under `Logical/` for new task (for `AddSTTask`) | required |
| `-TaskName` | ST task name, max 10 chars (for `AddSTTask`) | required |
| `-TaskClass` | Cyclic task class 1–8 | `4` |
| `-SwFileName` | `.sw` file to register task in | `Cpu.sw` |

## Notes

- Auto-detects installed AS versions from the Windows registry
- Technology package registration in `.apj` is handled automatically
- Transitive library dependencies are resolved via `.lby` `<Dependency>` elements
- Windows only. Requires B&R Automation Studio 6.x and PowerShell 5.1+
