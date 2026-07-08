function commsCheck(MGMT)
% =========================================================================
%  commsCheck  —  Verify this client is still authorised on the server
% =========================================================================
%
%  PURPOSE:
%    Called once per control cycle (after writing outputs) to confirm that
%    this machine is still the registered owner of its panel slot.
%    If the LabVIEW supervisor has manually kicked this client, or the
%    connection dropped and timed out, the gate register will no longer
%    match this machine's ID and the program is halted safely.
%
%  INPUT:
%    MGMT  — Management structure (initialised by commsInit).
%            Uses fields: .srvr, .OFFSET, .ID, .panel_number
%
%  OUTPUT:
%    None  — The function either exits silently (all ok) or raises an error.
%
%  ERROR RAISED:
%    C03 — Gate register no longer matches this machine's ID, meaning this
%          client has been removed from the panel by LabVIEW or a timeout.
%
%  STEPS:
%    1. Read this machine's current IPv4 address from the OS
%    2. Re-derive the unique machine ID from the IP address
%    3. Read the panel gate register from the MODBUS server
%    4. Compare the gate register value to this machine's ID
%    5. If they do not match, raise Error C03 and halt the program
%
% =========================================================================

% --- Step 1: Read this machine's current IPv4 address from the OS ---
% Same approach as commsInit — uses ipconfig to find the 192.168.x.x address.
[~, out] = system('ipconfig');

matches = regexp(out, 'IPv4 Address[^\:]*:\s*(192\.168\.\d+\.\d+)', 'tokens');

if ~isempty(matches)

    % --- Step 2: Re-derive the unique machine ID from the current IP ---
    % Recalculated from scratch each call rather than reading from MGMT.ID,
    % so the check stays valid even if the network address changed mid-session.
    id      = matches{1}{1};
    id      = typecast(fliplr(uint8(str2num(strrep(id, '.', ' ')))), 'uint32');
    MGMT.ID = mod(id, 65535);

    % --- Step 3: Read the panel gate register from the server ---
    % The gate register holds the ID of the currently authorised client.
    % If this machine still owns the panel, the gate value equals MGMT.ID.
    MGMT.gate = read(MGMT.srvr, 'holdingregs', MGMT.OFFSET + 8, 1);

    % --- Steps 4 & 5: Compare gate to this machine's ID ---
    % A mismatch means this client is no longer authorised. This can happen if:
    %   - The LabVIEW operator manually ended this client's session
    %   - The connection timed out and the panel was released to another user
    if MGMT.gate ~= MGMT.ID
        err_msg = append("Error C03:\n \tKicked from panel ES%d.\n", ...
            append("\tLabview Basic Experimental Template may have halted locally, ", ...
            "\n\tor you may have been kicked manually from server."));
        err_msg = sprintf(err_msg, MGMT.panel_number);
        error(err_msg);
    end

end

end