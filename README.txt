================================================================================
 CLIENT TEMPLATE 2026 (V1) -- QUICK START GUIDE
 LabVIEW + MATLAB Interface for the Process Control Rig
================================================================================

This folder contains everything you need to connect to, monitor, and control
your assigned process control rig ("panel" / ES station) over the lab network.

  - LabVIEW : REQUIRED for every student. This is the user interface you run
              to connect to the rig, view live data, and control it manually.
              Most students will only ever need this.

  - MATLAB  : OPTIONAL / ADVANCED. Runs alongside LabVIEW (same PC, at the
              same time) so advanced students can implement
              control strategies too complex to build as a LabVIEW block
              diagram.

TL;DR -- 3 STEPS:
  1) Connect your PC to the lab network.
  2) Open "Client_Template_MODBUS.lvproj" in LabVIEW, then run
     "Client_Template_MOD.vi". This is all most students need to do.
  3) (Optional, advanced) With LabVIEW still connected, open and edit
     "MATLAB_INTERFACE/ML_client_template.m" in MATLAB.

--------------------------------------------------------------------------------
1. WHERE TO FIND EVERYTHING
--------------------------------------------------------------------------------

ROOT FOLDER
  Client_Template_MODBUS.lvproj    >> OPEN THIS FIRST (LabVIEW project file)
  Client_Template_MOD.vi           >> The main program students run & use
  Client_Template_MODBUS.aliases   -- LabVIEW machine/network info (auto-managed,
                                       you don't need to touch this)
  Client_Template_MODBUS.lvlps     -- LabVIEW window-layout info (auto-managed)

Documentation/                     -- FULL manuals, read these for full detail
  ICE-1001 ICE Lab LabVIEW Programming.pdf    - Full LabVIEW how-to guide
  ICE-1002 ICE Lab MATLAB Programming.pdf     - Full MATLAB how-to guide
  Source Documentation/                        - Editable .docx originals of
                                                  the two guides above
                                                  (for staff/maintainer use)

subVIs/                            -- Building blocks used by the main VI.
                                       You do not normally need to open these
                                       directly, but their names show what
                                       each part of the system does:
  AnalogInput.vi  / AnalogOutput.vi          - Analogue channel read / write
  DigitalInput.vi / DigitalOutput.vi         - Digital channel read / write
  ConnectToPannelAddressSpace.vi             - Opens the MODBUS link and
                                                claims your panel
  MaintainConnectionToPannelAddressSpace.vi  - Keeps the link alive and
                                                checks you're still authorised
  ReadFromPannelAddressSpace.vi              - Pulls in sensor + MATLAB data
  WriteToPannelAddressSpace.vi                - Sends out commands + data
                                                for MATLAB to read
  DisconnectFromPannelAddressSpace.vi        - Cleanly zeros outputs and
                                                frees your panel on stop
  TimeKeeping.vi                              - Control loop timing
  arbitrarySessionLogging.vi                  - Session data logging
  FieldPost.vi                                 - Field data publishing /
                                                logging support

Labview_Logging/                   -- Log files land here when a session is
                                       run with logging active. Empty until
                                       you have run a logged session.

MATLAB_INTERFACE/                  -- OPTIONAL advanced-control add-on
  ML_client_template.m              >> OPEN & EDIT THIS for your MATLAB
                                        control strategy
  ML_client_template.asv            -- MATLAB autosave backup (safe to
                                        ignore/delete)
  supportingFunctions/               -- Helper functions, not normally edited:
    commsInit.m     - Connects to the MODBUS server & claims your panel
    sequencing.m    - Non-blocking loop timer
    svrRead.m       - Reads inputs from the server each cycle
    svrWrite.m      - Writes your outputs to the server each cycle
    commsCheck.m    - Confirms you are still connected/authorised

--------------------------------------------------------------------------------
2. HOW IT ALL FITS TOGETHER
--------------------------------------------------------------------------------

    [ Physical Rig ]   <-->   [ MODBUS/TCP Server @ 192.168.1.200 ]
   sensors / actuators                    |            |
                                           |            |
                          [ LabVIEW: Client_Template_MOD.vi ]   <- REQUIRED
                                           |
                                           |  (same PC, optional, running
                                           |   at the same time)
                                           v
                          [ MATLAB: ML_client_template.m ]      <- OPTIONAL

  - The lab server holds a block of registers for each rig/panel (an "ES"
    station, numbered 1-8). Only ONE client may connect to a given panel at
    a time -- a "gate" register on the server locks it to your machine.

  - LabVIEW talks to the server directly for all physical I/O and must
    always be running to use the rig.

  - MATLAB (if used) talks to the SAME server, reading/writing a small set
    of "scratch-pad" values that LabVIEW also exposes on its front panel.
    This is how the two programs hand data back and forth in real time.

  SIGNAL NAMING YOU WILL SEE IN BOTH PROGRAMS:
    DI0-DI7   Digital Input   - boolean sensor/switch state from the rig
    AI0-AI7   Analogue Input  - scaled sensor reading from the rig
    MI0-MI7   Move Input      - value sent LabVIEW -> MATLAB (e.g. a setpoint)
    MO0-MO7   Move Output     - value sent MATLAB -> LabVIEW (e.g. a command)

  NOTE: Values are transmitted as 16-bit MODBUS registers scaled by x100, so
  all AI/MI/MO values are limited to about +/-327.67 with 2 decimal places
  of precision. Keep control outputs within this range to avoid wraparound.

--------------------------------------------------------------------------------
3. GETTING STARTED -- LABVIEW (EVERYONE, START HERE)
--------------------------------------------------------------------------------

  Requirements: LabVIEW 2025 (or compatible), PC connected to the lab network.

  1. Connect your PC to the lab network (you need a 192.168.x.x IP address).
  2. Open "Client_Template_MODBUS.lvproj" in LabVIEW.
  3. In the Project Explorer, open "Client_Template_MOD.vi".
  4. Press Run (white arrow).
  5. Enter/select your panel (ES) number when prompted -- this must match
     the physical rig you are sitting at.
  6. Use the front-panel controls/indicators to view sensor data and
     manually drive the rig.
  7. When finished, use the on-panel STOP control (not Abort) so the
     program disconnects cleanly and frees the panel for the next user.

--------------------------------------------------------------------------------
4. GETTING STARTED -- MATLAB ADVANCED CONTROL (OPTIONAL)
--------------------------------------------------------------------------------

  Requirements: MATLAB with Instrument Control Toolbox (needed for the
  modbus() object), LabVIEW already connected and running on the SAME PC
  (complete Section 3 first).

  1. Complete the LabVIEW steps above and leave it running & connected.
  2. Open MATLAB and set the Current Folder to "MATLAB_INTERFACE".
  3. Add the helper functions to your path (once per session):
       Right-click "supportingFunctions" -> Add to Path -> Selected Folder
       (or type: addpath('supportingFunctions') in the Command Window)
  4. Open "ML_client_template.m".
  5. STEP 1 in the script: set panel_number to match the ES number you
     used in LabVIEW, and adjust dt (default 0.200 s) if needed.
  6. STEP 5 in the script: write your control algorithm using DI0-7,
     AI0-7 and MI0-7 as inputs.
  7. STEP 6 in the script: assign your calculated results to MO0-MO7.
  8. Run the script. It connects to the server, then loops, printing a
     live timing/telemetry line until stopped or disconnected.
  9. Stop with Ctrl+C in the Command Window (or stop LabVIEW, which will
     end the session for both programs).

  NOTE: Left unedited, the template is a safe "pass-through" (MO=MI) that
  performs no control action -- this is intentional. It's a good way to
  confirm your connection works before writing your own control code.

--------------------------------------------------------------------------------
5. COMMON ERRORS (MATLAB)
--------------------------------------------------------------------------------

  Error C01 - Panel locked by another user
      Someone else (or a previous crashed session of yours) still holds the
      panel gate. Confirm you used the right ES number, wait for the
      timeout, or ask your supervisor to reset the panel from the server.

  Error C02 - MODBUS server not found
      You are not on the lab network. Check your cable/Wi-Fi connection.

  Error C03 - Kicked from panel
      LabVIEW was stopped/crashed, or the session timed out. Reconnect
      LabVIEW first, then re-run the MATLAB script.

  "Undefined function 'commsInit'" (or similar)
      The "supportingFunctions" folder is not on the MATLAB path.
      See Section 4, step 3.

--------------------------------------------------------------------------------
6. FULL DOCUMENTATION
--------------------------------------------------------------------------------

  For complete step-by-step instructions, screenshots, and rig-specific
  detail, see the Documentation/ folder:

    ICE-1001 ICE Lab LabVIEW Programming.pdf    - Full LabVIEW guide
    ICE-1002 ICE Lab MATLAB Programming.pdf     - Full MATLAB guide

  Editable Word source files for the two guides above are kept in
  Documentation/Source Documentation/ for staff use.

  If you get stuck, ask your unit coordinator or lab supervisor.

================================================================================
END OF QUICK START GUIDE
================================================================================
