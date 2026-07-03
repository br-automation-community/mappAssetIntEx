---
description: Build, rebuild, clean, transfer, or deploy a B&R Automation Studio project. Use for: compile AS, fix build errors, transfer to PLC, download to controller, deploy firmware, ARsim, RUC package, PIP.
argument-hint: "Build | Rebuild | Clean | Transfer [IP] | BuildAndTransfer [IP] | BuildAll"
allowed-tools:
  - Bash
  - Read
  - Edit
---

Build and transfer B&R Automation Studio projects using PowerShell.

The user requested: $ARGUMENTS

## How to Use

Run the build script from the project root. Parse the user's request to determine the correct `-Action` and any additional options.

```powershell
powershell -ExecutionPolicy Bypass -File .github/skills/as-compile/scripts/invoke-as-build.ps1 `
  -ProjectPath . -Action <action> [options]
```

### Common Actions

| User Request | Action | Command |
|---|---|---|
| Build / Compile | `Build` | `-Action Build` |
| Rebuild / Full build | `Rebuild` | `-Action Rebuild` |
| Clean artifacts | `Clean` | `-Action Clean` |
| Transfer to ARsim | `Transfer` | `-Action Transfer` |
| Build and transfer to PLC | `BuildAndTransfer` | `-Action BuildAndTransfer -TargetIP <ip>` |
| BuildAll (build all configurations) | `Build` | `-Action Build -Configuration all` |

### Parameters

| Parameter | Description | Default |
|---|---|---|
| `-ProjectPath` | Path to AS project directory | `.` |
| `-Action` | `Build`, `Rebuild`, `Transfer`, `BuildAndTransfer`, `Clean` | `Build` |
| `-Configuration` | Configuration name, or `all` for every configuration | Auto-detect |
| `-TargetIP` | IP address for transfer (PLC or ARsim) | `127.0.0.1` |
| `-ShowWarnings` | Display build warnings in output | Off |
| `-NoClean` | Skip pre-clean step before build | Off |

## Reading Build Errors

Errors are formatted as:
```
<file>(<line>): error <code>: <message>
```

Fix errors in the source file at the reported location. **Never edit files in `Binaries/`, `Temp/`, or `Diagnosis/`.**

## Exit Codes

| Code | Status | Meaning |
|---|---|---|
| `0` | OK | Build succeeded |
| `1` | WARNINGS | Build succeeded with warnings |
| `3` | FAILED | Build failed — fix reported errors |

After running, check the output for errors and fix them in the source files before re-running.
