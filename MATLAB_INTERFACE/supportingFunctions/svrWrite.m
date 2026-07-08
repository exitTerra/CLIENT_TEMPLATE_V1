function MGMT = svrWrite(MGMT, MO0, MO1, MO2, MO3, MO4, MO5, MO6, MO7)
% =========================================================================
%  svrWrite  —  Write move-output values to the MODBUS server
% =========================================================================
%
%  PURPOSE:
%    Takes the eight output values (MO0–MO7) calculated by the student's
%    control code, scales them to integers, and writes them to the MODBUS
%    holding registers on the server. LabVIEW reads these registers each
%    cycle and uses data according to user configured LabVIEW program.
%
%  INPUTS:
%    MGMT      — Management structure (.srvr, .OFFSET, .mo_reg)
%    MO0–MO7   — Eight floating-point output values, one per channel.
%                 These are the commands your control code calculated.
%
%  OUTPUT:
%    MGMT  — Updated structure with .mo_reg holding the scaled integer values
%            (useful for debugging — inspect MGMT.mo_reg to see what was sent)
%
%  REGISTER MAP:
%    Holding registers at OFFSET+14 … OFFSET+21 — 8× move output channels
%
%  SCALING NOTE:
%    MODBUS registers store 16-bit unsigned integers only. Floating-point
%    outputs are therefore multiplied by 100 and rounded before writing
%    (e.g. an output value of 1.23 is written to the register as 123).
%    svrRead() applies the matching ÷100 scaling when reading move inputs.
%
%  STEPS:
%    1. Scale each output float by ×100 and round to the nearest integer,
%       storing the results in MGMT.mo_reg
%    2. Write all eight scaled values to the server in a single block write
%       to ensure all outputs reach the server
%
% =========================================================================

% --- Step 1: Scale each output value by 100 and round to integer ---
% MODBUS registers only hold 16-bit unsigned integers (0–65535).
% Multiplying by 100 before rounding preserves two decimal places of
% precision in the transmitted value (range ±327.67 before overflow).
MGMT.mo_reg(1) = round(MO0 * 100);
MGMT.mo_reg(2) = round(MO1 * 100);
MGMT.mo_reg(3) = round(MO2 * 100);
MGMT.mo_reg(4) = round(MO3 * 100);
MGMT.mo_reg(5) = round(MO4 * 100);
MGMT.mo_reg(6) = round(MO5 * 100);
MGMT.mo_reg(7) = round(MO6 * 100);
MGMT.mo_reg(8) = round(MO7 * 100);

% --- Step 2: Write all eight values to the server in one block write ---
% Sending all outputs in a single write() call is more efficient than eight
% separate writes and ensures LabVIEW receives all channel values together
% in the same MODBUS transaction.
% 'uint16' specifies the MODBUS data type used for the register values.
write(MGMT.srvr, 'holdingregs', MGMT.OFFSET + 14, [ ...
    MGMT.mo_reg(1), ...
    MGMT.mo_reg(2), ...
    MGMT.mo_reg(3), ...
    MGMT.mo_reg(4), ...
    MGMT.mo_reg(5), ...
    MGMT.mo_reg(6), ...
    MGMT.mo_reg(7), ...
    MGMT.mo_reg(8)], 'uint16');

end