# Client Template 2026 (V1)

**LabVIEW + MATLAB interface for the process control rig**

A plain-text version of this same guide is available in [`README.txt`](./README.txt).

## Overview

This project lets you connect to, monitor, and control your assigned process
control rig ("panel" / ES station) over the lab network.

| Component | Who uses it | Purpose |
|---|---|---|
| **LabVIEW** | **Everyone** (required) | The user interface you run to connect to the rig, view live data, and control it manually. Most students will only ever need this. |
| **MATLAB** | Advanced / final-year students (optional) | Runs *alongside* LabVIEW on the same PC, at the same time, so you can implement control strategies too complex to build as a LabVIEW block diagram. |

### TL;DR — 3 steps

1. Connect your PC to the lab network.
2. Open `Client_Template_MODBUS.lvproj` in LabVIEW, then run `Client_Template_MOD.vi`. This is all most students need to do.
3. *(Optional, advanced)* With LabVIEW still connected, open and edit `MATLAB_INTERFACE/ML_client_template.m` in MATLAB.

## Repository Contents — Where to Find Everything

```
CLIENT_TEMPLATE_2026_V1/
├── Client_Template_MODBUS.lvproj      <- OPEN THIS FIRST (LabVIEW project)
├── Client_Template_MOD.vi             <- Main program students run & use
├── Client_Template_MODBUS.aliases     (LabVIEW machine/network info, auto-managed)
├── Client_Template_MODBUS.lvlps       (LabVIEW window-layout info, auto-managed)
│
├── Documentation/                     <- FULL manuals, read these for full detail
│   ├── ICE-1001 ICE Lab LabVIEW Programming.pdf   Full LabVIEW how-to guide
│   ├── ICE-1002 ICE Lab MATLAB Programming.pdf    Full MATLAB how-to guide
│   └── Source Documentation/                      Editable .docx originals (staff use)
│
├── subVIs/                            <- Building blocks used by the main VI
│   ├── AnalogInput.vi  / AnalogOutput.vi           Analogue channel read/write
│   ├── DigitalInput.vi / DigitalOutput.vi          Digital channel read/write
│   ├── ConnectToPannelAddressSpace.vi              Opens the MODBUS link & claims your panel
│   ├── MaintainConnectionToPannelAddressSpace.vi   Keeps link alive / checks authorisation
│   ├── ReadFromPannelAddressSpace.vi               Pulls in sensor + MATLAB data
│   ├── WriteToPannelAddressSpace.vi                Sends out commands + data for MATLAB
│   ├── DisconnectFromPannelAddressSpace.vi         Cleanly zeros outputs & frees your panel
│   ├── TimeKeeping.vi                              Control loop timing
│   ├── arbitrarySessionLogging.vi                  Session data logging
│   └── FieldPost.vi                                Field data pre-cycle checks
│
├── Labview_Logging/                   <- Log files land here during a logged session
│                                         (empty until you run one)
│
└── MATLAB_INTERFACE/                  <- OPTIONAL advanced-control add-on
    ├── ML_client_template.m           <- OPEN & EDIT THIS for your MATLAB control strategy
    └── supportingFunctions/           <- Helper functions, not normally edited
        ├── commsInit.m                Connects to the MODBUS server & claims your panel
        ├── sequencing.m               Non-blocking loop timer
        ├── svrRead.m                  Reads inputs from the server each cycle
        ├── svrWrite.m                 Writes your outputs to the server each cycle
        └── commsCheck.m               Confirms you are still connected/authorised
```

You do not normally need to open anything inside `subVIs/` or
`supportingFunctions/` directly — they're called automatically. Their names
are listed above simply so you know what each part of the system does.

## Architecture — How It All Fits Together

```
   ┌────────────────┐         ┌────────────────────────────────────┐
   │  Physical Rig  │  <----> │  MODBUS/TCP Server @ 192.168.1.200 │
   │ sensors/actuat.│         │               PORT 8080            │
   └────────────────┘         └───────────────────┬────────────────┘
                                                  │
                          ┌───────────────────────▼───────────────────────┐
                          │  LabVIEW: Client_Template_MOD.vi   (REQUIRED) │
                          └───────────────────────┬───────────────────────┘
                                                  │  same PC, optional,
                                                  │  running at the same time
                          ┌───────────────────────▼───────────────────────┐
                          │  MATLAB: ML_client_template.m     (OPTIONAL)  │
                          └───────────────────────────────────────────────┘
```

- The lab server holds a block of registers for each rig/panel (an **ES**
  station, numbered 1–8). Only **one** client may connect to a given panel at
  a time — a "gate" register on the server locks it to your machine.
- LabVIEW talks to the server directly for all physical I/O and must always
  be running to use the rig.
- MATLAB (if used) talks to the **same** server, reading/writing a small set
  of "scratch-pad" values that LabVIEW also exposes on its front panel. This
  is how the two programs hand data back and forth in real time.

### Signal naming convention

| Code        | Name           | Direction        | Type          | Description                                                   |
|-------------|----------------|------------------|---------------|---------------------------------------------------------------|
| `DI0`–`DI7` | Digital Input  | Rig → Program    | Boolean (0/1) | Sensor/switch state from the rig                              |
| `AI0`–`AI7` | Analogue Input | Rig → Program    | Scaled float  | Sensor reading from the rig                                   |
| `MI0`–`MI7` | Move Input     | LabVIEW → MATLAB | Scaled float  | Value from LabVIEW's front panel (e.g. a setpoint)            |
| `MO0`–`MO7` | Move Output    | MATLAB → LabVIEW | Scaled float  | Value MATLAB calculated (e.g. a command), returned to LabVIEW |

> **Note:** Values are transmitted as 16-bit MODBUS registers scaled ×100, so
> all `AI`/`MI`/`MO` values are limited to roughly **±327.67** with 2 decimal
> places of precision. Keep "scratch-pad" variables within this range to avoid
> integer overflow/underflow.

## Getting Started

### 1. LabVIEW (everyone — start here)

**Requirements:** LabVIEW 2025 (or compatible), PC connected to the lab network.

1. Connect your PC to the lab network (you need a `192.168.x.x` IP address).
2. Open `Client_Template_MODBUS.lvproj` in LabVIEW.
3. In the Project Explorer, open `Client_Template_MOD.vi`.
4. Press **Run** (white arrow).
5. Enter/select your panel (ES) number when prompted — this must match the
   physical rig you are sitting at.
6. Use the front-panel controls/indicators to view sensor data and manually
   drive the rig.
7. When finished, use the on-panel **STOP** control (not Abort) so the
   program disconnects cleanly and frees the panel for the next user.

### 2. MATLAB advanced control (optional)

**Requirements:** MATLAB with Industrial Control Toolbox (needed for the
`modbus()` object), LabVIEW already connected and running on the **same PC**
(complete step 1 first).

1. Complete the LabVIEW steps above and leave it running & connected.
2. Open MATLAB and set the **Current Folder** to `MATLAB_INTERFACE`.
3. Add the helper functions to your path (once per session): right-click
   `supportingFunctions` → **Add to Path** → **Selected Folder** (or run
   `addpath('supportingFunctions')` in the Command Window).
4. Open `ML_client_template.m`.
5. **Step 1** in the script: set `panel_number` to match the ES number you
   used in LabVIEW, and adjust `dt` (default `0.200` s) if needed.
6. **Step 5** in the script: write your control algorithm using `DI0-7`,
   `AI0-7` and `MI0-7` as inputs.
7. **Step 6** in the script: assign your calculated results to `MO0`–`MO7`.
8. Run the script. It connects to the server, then loops, printing a live
   timing/telemetry line until stopped or disconnected.
9. Stop with <kbd>Ctrl</kbd>+<kbd>C</kbd> in the Command Window (or stop
   LabVIEW, which will end the session for both programs).

> Left unedited, the template is a safe "pass-through" (`MO = MI`) that
> performs no control action — this is intentional, and a good way to
> confirm your connection works before writing your own control code.

## Unique MATLAB Template Errors
| Error | Cause | Fix |
|---|---|---|
| **C01**   — Panel locked by another user | Someone else (or a previous crashed session of yours) still holds the panel gate | Confirm you used the right ES number, wait for the timeout, or ask your supervisor to reset the panel from the server |
| **C02**   — MODBUS server not found | You are not on the lab network | Check your Wi-Fi connection |
| **C03**   — Kicked from panel | LabVIEW was stopped/crashed, or the session timed out | Reconnect LabVIEW first, then re-run the MATLAB script |
| `Undefined function 'commsInit'` (or similar) | `supportingFunctions` is not on the MATLAB path |See [MATLAB step 3](#2-matlab-advanced-control-optional) |

## Appendix: MODBUS Register Map (advanced reference)

For students who want to understand the wire protocol (derived from
`commsInit.m`, `svrRead.m` and `svrWrite.m`). Not required reading to get
started.

`OFFSET = (panel_number − 1) × 100 + 1`

NOTE: The "+1" only seems to be required for MATLAB, I assume this is tied to MATLAB being one of the weird languages that uses 1 as the zero index for arrays, structures, etc..

| Register type     | Address range             | Contents                                                  |
|-------------------|---------------------------|-----------------------------------------------------------|
| Discrete Inputs   | `OFFSET+0` … `OFFSET+7`   | Digital inputs `DI0`–`DI7`                                |
| Input Registers   | `OFFSET+0` … `OFFSET+7`   | Analogue inputs `AI0`–`AI7` (÷100 scaled)                 |
| Holding Registers | `OFFSET+8`                | Gate/lock register (owning client's ID)                   |
| Holding Registers | `OFFSET+14` … `OFFSET+21` | Move Outputs `MO0`–`MO7` (×100 scaled, written by MATLAB) |
| Holding Registers | `OFFSET+24` … `OFFSET+31` | Move Inputs `MI0`–`MI7` (×100 scaled, written by LabVIEW) |

## Full Documentation

For complete step-by-step instructions, screenshots, and rig-specific detail,
see the [`Documentation/`](./Documentation) folder:

- [`ICE-1001 ICE Lab LabVIEW Programming.pdf`](./Documentation/ICE-1001%20ICE%20Lab%20LabVIEW%20Programming.pdf) — Full LabVIEW guide
- [`ICE-1002 ICE Lab MATLAB Programming.pdf`](./Documentation/ICE-1002%20ICE%20Lab%20MATLAB%20Programming.pdf) — Full MATLAB guide

NOTE: an additional file is available for server side comunication with panels/ESs, this is vendor maintained and should be cosulted for relevant tasks:

- [`ICE_Lab_User_Manual_REV2_2.pdf`] — Server -> Panel communication and general housekeeping

Editable Word source files for the two guides above are kept in
`Documentation/Source Documentation/` for staff use.

If you get stuck, ask your unit coordinator or lab supervisor.

## Notes for Version Control (maintainers)

A few files in this repository are machine/session-specific rather than
authored content, worth keeping in mind when archiving or branching:

- `Client_Template_MODBUS.aliases` — stores the last machine's network
  identity; regenerated locally by LabVIEW.
- `Client_Template_MODBUS.lvlps` — stores local Project Explorer window
  layout; regenerated locally by LabVIEW.
- `Labview_Logging/` — fills up with generated run logs; consider excluding
  large/generated log files from commits.
- `MATLAB_INTERFACE/ML_client_template.asv` — MATLAB autosave backup of the
  template, safe to exclude.

---
*Created: July 2026.*
