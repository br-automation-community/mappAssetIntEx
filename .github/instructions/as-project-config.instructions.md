---
description: Guidelines for B&R Automation Studio hardware and physical configuration (Cpu.sw, IoMap, PvMap, Access & Security, connectivity).
applyTo: '**/*.sw,**/*.hw,**/*.iom,**/*.vvm,**/*.role,**/*.user,**/*.per,**/*.mappviewcfg'
---

# B&R Automation Studio Hardware & Physical Configuration Guidelines

You are an expert in B&R Automation Studio (6.0+) hardware and physical configuration.
Follow these guidelines when working with files in the `Physical/` view of an Automation Studio project.

## General Instructions

- The `Physical/` folder mirrors the hardware topology. One folder per configuration (`Config1/`), one subfolder per CPU module.
- Fix only source files under `Physical/`. Never edit generated outputs in `Binaries/`, `Temp/`, or `Diagnosis/`.
- Whenever you add, remove, or rename a file or folder, update the corresponding `Package.pkg`.
- Always refer to the B&R Automation Studio Help Server (via `mcp__as-help__*` tools) for hardware module documentation, parameter ranges, and valid XML schema.

## Folder Structure

```text
Physical/
└── Config1/
    ├── Hardware.hw            # Hardware topology (module assignments)
    ├── Hardware.hwl           # Hardware layout (slot assignments)
    └── X20CP1686X/            # CPU module folder
        ├── Cpu.per            # CPU-specific parameters
        ├── Cpu.sw             # Software configuration (task scheduling)
        ├── IoMap.iom          # I/O channel mapping
        ├── PvMap.vvm          # Process Variable mapping between tasks
        ├── AccessAndSecurity/ # User, Role, OPC UA security
        ├── Connectivity/      # Network and fieldbus settings
        ├── mappView/          # mappView visualization configuration
        └── ...                # Technology package folders (mappMotion, etc.)
```

## CPU Software Configuration (`Cpu.sw`)

The `Cpu.sw` file defines which tasks run on the CPU and in which cyclic class.

### Task Classes
- Tasks are grouped into cyclic classes (e.g. `Cyclic#1` = 2ms, `Cyclic#4` = 10ms, etc.).
- Choose the class based on required response time. HMI and non-time-critical tasks belong in slower classes.
- `UserROM` memory is standard for application tasks. `UserRAM` is used for tasks requiring faster init.

### Adding a Task
Add a `<Task>` entry inside the appropriate `<TaskClass>` element:

```xml
<TaskClass Name="Cyclic#4">
  <Task Name="MyTask"
        Source="PackageName.ProgramName.prg"
        Memory="UserROM"
        Language="IEC"
        Debugging="true" />
</TaskClass>
```

- `Name`: display name in AS.
- `Source`: path in the form `<LogicalPackage>.<ProgramPackage>.prg`.
- `Language`: `IEC` for IEC 61131-3 tasks.
- `Debugging`: set `true` during development; consider `false` for production builds.

## I/O Mapping (`IoMap.iom`)

**DO NOT EDIT OR GENERATE**. I/O mapping is to be done by the user in Automation Studio for now.

## Process Variable Mapping (`PvMap.vvm`)

Cyclically map variables between tasks without shared global variables. The `.vvm` file lives in the CPU folder: `Physical/<Config>/<CPU>/*.vvm`. Mapping is resolved at the end of the Cyclic#N phase, so mapped variables are available in the next cycle.

### Rules
- File encoding: UTF-8 **without** BOM.
- **Comments are not allowed** in `.vvm` files.
- Syntax: `<source> AT %Q.<destination>;` for both directions.
- Variable paths: `::<TaskName>:<variableName>` or `::<TaskName>:<struct>.<member>`.
- Global variables (no task): `::<VarName>`.

### Example

```
VAR_CONFIG
	::SimInputs.diLiftPositionInfeed1 AT %Q.::BoxLift:diLiftPositionInfeed1;
	::SimInputs.diLiftPositionInfeed2 AT %Q.::BoxLift:diLiftPositionInfeed2;
	::BoxLift:doLiftUp                AT %Q.::SimOutputs.doLiftUp;
	::BoxLift:doLiftDown              AT %Q.::SimOutputs.doLiftDown;
END_VAR
```

## Access & Security

Files are located under `Physical/<Config>/<CPU>/AccessAndSecurity/UserRoleSystem/`.

### Roles (`Role.role`)

Defines what each role can access. Add a `<Role>` element for each role:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Roles xmlns="http://br-automation.co.at/AS/RoleManagement">
  <Role name="Admin" />
  <Role name="Operator" />
  <Role name="Service" />
</Roles>
```

- Role names are case-sensitive and referenced exactly in `User.user` and mappView role restrictions.

### Users (`User.user`)

Defines user accounts.

```xml
<?xml version="1.0" encoding="utf-8"?>
<?AutomationStudio FileVersion="4.9"?>
<Configuration>
  <Element ID="admin" Type="User">
    <Property ID="Password" Value="$argon2id$v=19$m=512,t=70,p=1$..." />
    <Group ID="Roles"> <!-- User has one role -->
      <Property ID="Role[1]" Value="Admin" />
    </Group>
  </Element>
  <Element ID="operator" Type="User">
    <Property ID="Password" Value="" />
    <Group ID="Roles"> <!-- User has multiple roles -->
      <Property ID="Role[1]" Value="Admin" />
      <Property ID="Role[2]" Value="Service" />
      <Property ID="Role[3]" Value="Operator" />
    </Group>
  </Element>
</Configuration>
```

- **Password:** When generating a user leave the password empty `<Property ID="Password" Value="" />` and tell the user in the output to set the password manually in Automation Studio for security reasons.
- A user can have multiple roles
- **IMPORTANT:** Add `BR_Engineer` role for users with development and admin roles. **WARNING:** `BR_Engineer` role has full access to the Opc UA server. Only assign to trusted users. **CRITICAL:** Do not generate a role with the name `BR_Engineer` — it already exists as a built-in role with special permissions.

## Hardware Topology (`Hardware.hw`)

_Details to be documented._
