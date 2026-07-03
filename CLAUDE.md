# Automation Studio Project Guide

This repository is a B&R Automation Studio project. This file is the always-on project guide for Claude when working in this project.

## Project Overview

- Target environment: Windows, B&R Automation Studio, PowerShell.
- Main project file: `*.apj`.
- Primary source areas:
  - `Logical/` for IEC 61131-3 code, global variables/types, Unity integration, libraries, and mappView assets.
  - `Physical/<config>/<cpu>/` for hardware, CPU software, I/O mapping, and PV mapping.
  - `Requirements/` for specifications.
- Generated or build output areas:
  - `Binaries/`
  - `Diagnosis/`
  - `Temp/`

## Working Rules

- Prefer small, local changes over broad refactors.
- Fix the root cause in source files instead of patching generated outputs.
- Never edit generated files in `Binaries/`, `Diagnosis/`, or `Temp/`.
- Preserve the existing Automation Studio project structure.
- If you add, remove, or rename files in Automation Studio packages, update the corresponding `Package.pkg` file.
- If you add a new Structured Text task, use the `/as-logical-api AddSTTask` command.

## Source File Guidance

### General — IEC 61131-3 Code, Types, Variables

**MUST** read before editing IEC code in `/Logical`:

@.github/instructions/as-project-code.instructions.md

### mappView HMI — Visualization

**MUST** read before working on mappView visualization:

@.github/instructions/as-project-visu.instructions.md

### Physical View — Hardware, CPU, I/O, PvMap, Access & Security

**MUST** read before working on physical configuration, user handling, and variable mappings:

@.github/instructions/as-project-config.instructions.md

### Connectivity — OPC UA

**MUST** read before working on connectivity features like OPC UA:

@.github/instructions/as-project-opcua.instructions.md

### mapp Services — Alarms, AlarmX

**MUST** read before working on mapp Services features like Alarms and AlarmX:

@.github/instructions/as-project-mpalarmx.instructions.md

### mapp Motion / mapp6D — Axis, Drive, Motion Control

**MUST** read before working on mapp6D features:

@.github/instructions/as-project-mapp6d.instructions.md

## Preferred Workflow

1. Read the relevant requirement or nearby implementation before editing.
2. Change the smallest source surface that controls the behavior.
3. If project structure changes are required, update package registration files in the same change.
4. Validate with the narrowest useful check before making more edits.

## Build and Validation

Use the existing workspace tasks when possible.

- Preferred build task: `AS: Build` (VS Code task) or `/as-compile Build`
- Full configuration build: `AS: Build All Configurations` or `/as-compile Build -Configuration all`
- Transfer flow when explicitly requested: `AS: Build and Transfer` or `/as-compile BuildAndTransfer`

## Automation Studio API Helpers (Slash Commands)

This repo includes scripts for project-safe structural changes. Use these slash commands:

- `/as-logical-api AddLibrary <name>` — add libraries to the project
- `/as-logical-api AddSTTask <path> <name>` — add and register Structured Text tasks
- `/as-physical-hw-api AddHWModule <type>` — add hardware modules to Hardware.hw
- `/as-tp-config-api GetConfigElements -TechnologyPackage <tp> -FileEnding <ext>` — discover allowed config elements before hand-editing mapp* config files
- `/as-utility GetInstalledVersions` — list installed AS versions and paths
- `/code-review` — comprehensive code review of the current branch

Prefer those helpers over hand-editing project metadata when they match the task.

## Documentation Sources

- **B&R Automation Studio Help Server**: Use `mcp__as-help__search_help` and `mcp__as-help__get_page_by_id` tools to look up any software or hardware topics. This is the primary source for official B&R documentation.
- **B&R Community Forum**: Use `mcp__br-community__*` tools to search the B&R community forums for practical examples and real-world solutions.

## Agent Expectations

- Be explicit about assumptions when requirements are incomplete.
- Do not rewrite unrelated files to match a preferred style.
- Do not modify user or machine-specific settings files unless the task explicitly asks for it.
- Prefer repository tasks and existing scripts over inventing new build or setup flows.
- Always check `Requirements/` for specifications before implementing new features.
