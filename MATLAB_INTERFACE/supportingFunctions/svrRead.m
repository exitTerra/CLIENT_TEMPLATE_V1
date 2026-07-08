function MGMT = svrRead(MGMT)
% =========================================================================
%  svrRead  —  Read all input registers from the MODBUS server
% =========================================================================
%
%  PURPOSE:
%    Reads the latest values of all three input types from the MODBUS
%    server each control cycle and stores them in the MGMT structure.
%    The main program then unpacks them into the named variables
%    DI#, AI# and MI# that are used in the student's control code.
%
%  INPUT / OUTPUT:
%    MGMT  — Management structure. Fields updated:
%              .dig_in   [1×8 double]  Digital input states  (0 or 1)
%              .in_reg   [1×8 double]  Analogue input values (scaled float)
%              .mi_reg   [1×8 double]  Move input values from LabVIEW (scaled float)
%
%  REGISTER MAP (addresses relative to panel OFFSET):
%    Discrete inputs  OFFSET + 0  … OFFSET + 7   — dig_in  (8 digital channels)
%    Input registers  OFFSET + 0  … OFFSET + 7   — in_reg  (8 analogue channels)
%    Holding regs     OFFSET + 24 … OFFSET + 31  — mi_reg  (8 LabVIEW→MATLAB channels)
%
%  SCALING NOTE:
%    MODBUS registers store 16-bit unsigned integers only. Floating-point
%    values are therefore stored on the server scaled by ×100 and rounded
%    (e.g. a sensor reading of 1.23 is stored as the integer 123).
%    Dividing by 100 here restores the original floating-point value.
%    svrWrite() applies the same ×100 scaling in reverse when writing outputs.
%
%  STEPS:
%    1. Read 8 discrete input bits  — panel digital inputs (e.g. switches)
%    2. Read 8 input registers      — panel analogue inputs (e.g. sensors)
%                                     and divide by 100 to restore float values
%    3. Read 8 holding registers    — move inputs written by LabVIEW
%                                     and divide by 100 to restore float values
%
% =========================================================================

% --- Step 1: Read 8 digital (discrete) inputs ---
% MODBUS 'inputs' are discrete input coils — each is a single bit (0 or 1).
% Typical uses: limit switches, push-buttons, binary status flags.
MGMT.dig_in = read(MGMT.srvr, 'inputs', MGMT.OFFSET, 8);

% --- Step 2: Read 8 analogue input registers and convert to floats ---
% MODBUS 'inputregs' are read-only 16-bit input registers.
% These carry analogue measurements from the rig (e.g. position, pressure).
% Dividing by 100 reverses the server-side ×100 integer scaling.
MGMT.in_reg = read(MGMT.srvr, 'inputregs', MGMT.OFFSET, 8) / 100;

% --- Step 3: Read 8 move-input holding registers and convert to floats ---
% MODBUS 'holdingregs' at OFFSET+24 are written by LabVIEW to send
% setpoints, mode flags or other commands to this MATLAB program.
% Dividing by 100 reverses the server-side ×100 integer scaling.
MGMT.mi_reg = read(MGMT.srvr, 'holdingregs', MGMT.OFFSET + 24, 8) / 100;

end