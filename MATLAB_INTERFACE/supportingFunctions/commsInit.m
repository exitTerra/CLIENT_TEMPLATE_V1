function MGMT = commsInit(panel_number, dt)
% =========================================================================
%  commsInit  —  Initialise MODBUS/TCP communication with the lab server
% =========================================================================
%
%  PURPOSE:
%    Opens a TCP/IP connection to the MODBUS server, identifies this
%    computer on the network using its IPv4 address, and checks that the
%    requested panel slot is not already occupied by another user.
%    If all checks pass, it initialises the MGMT management structure
%    that is passed between all supporting functions throughout the session.
%
%  INPUTS:
%    panel_number  — Integer (1, 2, 3 …). Identifies which experimental
%                    panel/rig this MATLAB instance is connecting to.
%    dt            — Desired control loop sample period in seconds.
%
%  OUTPUT:
%    MGMT  — Management structure containing:
%              .srvr         modbus object (the live TCP/IP connection)
%              .panel_number copy of the panel number used
%              .OFFSET       register address offset for this panel's block
%              .ID           unique 16-bit integer ID derived from this
%                            machine's IP address
%              .gate         value read from the panel gate register
%              .dt           requested sample period (seconds)
%              .init_time    tic handle — counts total elapsed session time
%              .last_call    tic handle — counts time since last cycle
%              .connected    true once connection is confirmed
%
%  ERRORS RAISED:
%    C01 — Panel gate is held by a different machine ID (panel in use, or
%           a previous session did not disconnect cleanly)
%    C02 — No 192.168.x.x address found — machine is not on the lab network
%
%  STEPS:
%    1. Create the MODBUS TCP/IP object and record the panel number
%    2. Calculate the register address offset for the selected panel
%    3. Read this machine's IPv4 address from the OS (via ipconfig)
%    4. Convert the IP address string into a unique 16-bit integer ID
%    5. Read the panel gate register from the server
%    6. Compare gate value to this machine's ID (panel-lock check)
%    7. Initialise timing variables and set connected = true
%    8. If not on lab network, raise Error C02
%
% =========================================================================

% --- Step 1: Create the MODBUS TCP/IP connection object ---
% The server is always at the fixed lab IP address 192.168.1.200.
% The modbus() object handles all low-level TCP/IP communication.
MGMT.srvr         = modbus('tcpip', '192.168.1.200');
MGMT.panel_number = panel_number;

% --- Step 2: Calculate the register address offset for this panel ---
% Each panel occupies a block of 100 registers on the server.
% Panel 1 starts at register 1, panel 2 at register 101, panel 3 at 201, etc.
MGMT.OFFSET = (panel_number - 1) * 100 + 1;

% --- Step 3: Read this machine's IPv4 address from the OS ---
% The Windows command 'ipconfig' lists all network interface details.
% The regular expression extracts any address in the 192.168.x.x range,
% which is the expected address range for the lab network.
[~, out] = system('ipconfig');

matches = regexp(out, 'IPv4 Address[^\:]*:\s*(192\.168\.\d+\.\d+)', 'tokens');

if ~isempty(matches)
    % A 192.168.x.x address was found — this machine is on the lab network.

    % --- Step 4: Convert the IP address string to a unique 16-bit ID ---
    % The IP string (e.g. "192.168.1.42") is split into four byte values,
    % reinterpreted as a single uint32, then reduced to a 16-bit range
    % using mod(). This produces a consistent, unique ID per machine.
    id      = matches{1}{1};
    id      = typecast(fliplr(uint8(str2num(strrep(id, '.', ' ')))), 'uint32');
    MGMT.ID = mod(id, 65535);

    % --- Step 5: Read the panel gate register from the server ---
    % The gate register (at OFFSET + 8) stores the ID of the machine that
    % currently owns this panel. A value of 0 means the panel is free.
    MGMT.gate = read(MGMT.srvr, 'holdingregs', MGMT.OFFSET + 8, 1);

    % --- Step 6: Panel-lock check ---
    % If the gate register already holds a different ID, another session is
    % active. Raise Error C01 to prevent two clients writing to the same panel.
    % (If this is YOUR machine reconnecting after a crash, wait for the panel
    %  timeout or ask the supervisor to reset the panel from the server.)
    if MGMT.gate ~= MGMT.ID
        err_msg = append("Error C01:\n \tES%d locked by other user.\n", ...
            append("\tPanel may be in use, or a disconnection error has occured.", ...
            "\n\tFor disconnection errors, reset panel from server or wait for panel timeout"));
        err_msg = sprintf(err_msg, panel_number);
        error(err_msg);
    end

    % --- Step 7: Initialise timing variables and confirm connection ---
    MGMT.dt        = dt;      % Store desired sample period for use in sequencing()
    MGMT.init_time = tic();   % Start total-elapsed-time counter (session clock)
    MGMT.last_call = tic();   % Start per-cycle timer (resets each control cycle)
    MGMT.connected = true;    % Signal to the main loop that the connection is live

else
    % --- Step 8: Not on the lab network — raise Error C02 ---
    % ipconfig returned no 192.168.x.x address, so the MODBUS server cannot
    % be reached. Check the network cable or Wi-Fi connection and try again.
    err_msg = append("Error C02:\n \tMODBUS server not found.\n", ...
            append("\tCheck network interfaces and try again."));
    err_msg = sprintf(err_msg);
    error(err_msg);
end

end