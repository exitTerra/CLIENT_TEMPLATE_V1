clear, close all, clc
% =========================================================================
%                  ML_client_template.m — VERSION 1.0 — 2026
%            MATLAB Client Template — Experimental Control Interface
% =========================================================================
%
%  OVERVIEW:
%  This is your starting-point template for writing a control strategy in
%  MATLAB. It communicates with a MODBUS/TCP server running on the lab
%  network that links this program to:
%    - Physical field I/O on ES0-7 (sensors, actuators)
%    - A LabVIEW user-interface panel that must be run simultaneously on
%      the same physical machine to allow connection and real time commands.
%
% =========================================================================
%  NOTE: FULL PROGRAM DESCRIPTION AT BOTTOM OF CODE
% =========================================================================
%
%  WHERE TO WRITE YOUR CODE:
%    >> Look at sections (Step #:...):
%        > If proceeded by "MANAGEMENT" the section will be part of server 
%           communication and user modification is not required ...
%           (FEEL FREE TO EDIT, WORST THAT WILL HAPPEN IS YOUR PROGRAM 
%           WON'T WORK)
%        > If proceeded by "USER CONFIG." the section is intended for user
%           interaction, either config./initialisation of program (STEP 1), 
%           or control-loop-execution/automation (STEP 5)
%
%  SIGNAL NAMING CONVENTION:
%    DI#  — Digital Input  : boolean 0 or 1      (e.g. limit switch, button)
%    AI#  — Analogue Input : scaled float value  (e.g. sensor voltage)
%    MI#  — Move Input     : value sent TO MATLAB from LabVIEW (e.g. setpoint)
%    MO#  — Move Output    : value sent FROM MATLAB to LabVIEW (e.g. command)
%    (# is a channel index 0–7, giving 8 channels of each type)
%
% =========================================================================

%% Step 1: --------------- User settings and constant initialisation <<< USER CONFIG.
dt           = 0.200;   % Control loop sample period in SECONDS.

panel_number = 1;       % The ES number your LabVIEW panel is using (1, 2, ..., 8).

% =========================================================================
% Define any required program constants here, e.g.: controller gains
% =========================================================================

%% Step 2: --------------------------- Initialise MODBUS communication <<< MANAGEMENT
MGMT = commsInit(panel_number, dt);

% --- Telemetry initialisation (no editing needed) ---
telem_buf   = [];   % rolling buffer storing the last 100 measured cycle periods (s)
telem_chars = 0;    % character count of the last telemetry line printed —
                    %   used to overwrite command line each cycle to update telemetry

%% Step 3: ------ Main control loop (run until comms. loss) <<< CONTAINS USER CONFIG.
while MGMT.connected

    % Step 3a: --- Check whether it is time for the next control cycle <<< MANAGEMENT
    % sequencing() updates MGMT.next_step based on elapsed time vs dt.
    MGMT = sequencing(MGMT);

    if MGMT.next_step   % True only once every dt seconds — run one control cycle
        %% Step 4:---- Read all input registers from the MODBUS server <<< MANAGEMENT
        MGMT = svrRead(MGMT);

        % Unpack inputs into named variables for use in your control code.
        % Read across each row: DI# = digital, AI# = analogue, MI# = from LabVIEW.
        % Move inputs        |      Digital inputs (BOOL)|     Analogue inputs (float)
        % LabVIEW Scratch-   |      ES Digital input 0-7 |     ES Analog input 0-7
        % pad outputs 0-7    |                           |
        MI0 = MGMT.mi_reg(1);       DI0 = MGMT.dig_in(1);      AI0 = MGMT.in_reg(1);
        MI1 = MGMT.mi_reg(2);       DI1 = MGMT.dig_in(2);      AI1 = MGMT.in_reg(2);  
        MI2 = MGMT.mi_reg(3);       DI2 = MGMT.dig_in(3);      AI2 = MGMT.in_reg(3);  
        MI3 = MGMT.mi_reg(4);       DI3 = MGMT.dig_in(4);      AI3 = MGMT.in_reg(4);
        MI4 = MGMT.mi_reg(5);       DI4 = MGMT.dig_in(5);      AI4 = MGMT.in_reg(5); 
        MI5 = MGMT.mi_reg(6);       DI5 = MGMT.dig_in(6);      AI5 = MGMT.in_reg(6);
        MI6 = MGMT.mi_reg(7);       DI6 = MGMT.dig_in(7);      AI6 = MGMT.in_reg(7);
        MI7 = MGMT.mi_reg(8);       DI7 = MGMT.dig_in(8);      AI7 = MGMT.in_reg(8);  

        %% Step 5: ---------------------------- User control program << USER CONFIG.

        % =================================================================
        % WRITE YOUR CODE HERE
        % =================================================================

        %% Step 6: - Assign output variables to send back to LabVIEW  << USER CONFIG.
        % DO NOT CHANGE VARIABLE NAMES MO0-MO7
        % REPLACE VARIABLE NAMES MI0-MI7 WITH ANY VARIABLES YOU DEFINED
        %   ABOVE THAT YOU WISH TO WROTE BACK TO LABVIEW
        MO0 = MI0;   % LabVIEW Scratch Input 0
        MO1 = MI1;   % LabVIEW Scratch Input 1
        MO2 = MI2;   % LabVIEW Scratch Input 2
        MO3 = MI3;   % LabVIEW Scratch Input 3
        MO4 = MI4;   % LabVIEW Scratch Input 4
        MO5 = MI5;   % LabVIEW Scratch Input 5
        MO6 = MI6;   % LabVIEW Scratch Input 6
        MO7 = MI7;   % LabVIEW Scratch Input 7

        %% Step 7: ----- Write outputs to server and verify connection <<< MANAGEMENT
        MGMT = svrWrite(MGMT, MO0, MO1, MO2, MO3, MO4, MO5, MO6, MO7);
        commsCheck(MGMT);   % Halts safely if the connection has been lost

        %% Step 8: ------------------------------------ Loop telemetry <<< MANAGEMENT
        % Append this cycle's measured period to the rolling buffer
        telem_buf(end+1) = MGMT.dt_real;
        if numel(telem_buf) > 100
            telem_buf = telem_buf(end-99:end);   % keep only the last 100 cycles
        end

        % Compute jitter statistics over the buffer
        deviations = abs(telem_buf - dt);                            % absolute deviation from dt per cycle
        avg_jitter = mean(deviations) * 1000;                        % ms — mean deviation

        sorted_buf  = sort(telem_buf);
        idx_90      = min(numel(sorted_buf), ceil(0.9 * numel(sorted_buf)));  % index of 90th percentile
        high90_dt   = sorted_buf(idx_90) * 1000;                     % ms — worst 10% of cycles

        pct_bad     = 100 * mean(deviations > 0.005);                % % of cycles with >5 ms deviation

        % Build a fixed-width string and overwrite the previous telemetry line.
        % repmat('\b',...) sends backspace characters to erase the previous print.
        telem_str = sprintf( ...
            '  [Telemetry]  t: %8.2f s  |  Avg jitter: %6.2f ms  |  90%% high dt: %6.2f ms  |  >5ms bad: %5.1f%%  (target: %4.0f ms)', ...
            MGMT.t_real, avg_jitter, high90_dt, pct_bad, dt * 1000);

        % erase previous line using actual backspace characters
        fprintf('%s', repmat(char(8), 1, telem_chars));

        % print new telemetry (no extra conversion to string)
        fprintf('%s', telem_str);
        telem_chars = numel(telem_str);  % save length for next cycle


    end % end if MGMT.next_step

end % end while MGMT.connected

% =========================================================================
%% Full program description
% =========================================================================
%  STEP 1 — USER SETTINGS AND CONSTANT INITIALISATION
%
%  This section runs ONCE when the program starts, before the control loop.
%  Use it for two things:
%
%    a) The two required communication settings (dt and panel_number).
%
%    b) Any constant values your control algorithm needs — things that are
%       fixed for the whole run and do not change cycle-to-cycle.
%       Defining them here (rather than inside the loop) is good practice:
%       it keeps your tuning parameters in one easy-to-find place, and
%       avoids MATLAB re-creating the variable every single cycle.
%
%       EXAMPLES of constants to define here:
%         Kp   = 1.5;      % Proportional gain
%         Ki   = 0.3;      % Integral gain
%         Kd   = 0.05;     % Derivative gain
%         iSum = 0;        % Integral accumulator — initialised to zero
%                          %   (state variables like this also go here)
%
%  NOTE: Variables that carry state between cycles (e.g. an integral sum,
%        previous error for a derivative term) must also be initialised
%        here so they exist on the first cycle of the loop.
%
% =========================================================================
%  STEP 2 — CONNECT TO THE MODBUS SERVER
%  <<< YOU DO NOT NEED TO EDIT THIS SECTION
%
%  commsInit() does the following automatically:
%    - Opens a TCP/IP connection to the MODBUS server at 192.168.1.200
%    - Identifies this computer on the network using its IP address
%    - Checks that nobody else is already using your panel
%    - Returns the MGMT structure which holds all connection and timing info
%
%  If the connection fails, a descriptive error message will be displayed
%  in the Command Window explaining what went wrong and how to fix it.
%
% =========================================================================
%  STEP 3 — MAIN CONTROL LOOP INIT. AND PER CYCLE SEQUENCING
%  The while-loop runs continuously for as long as MGMT.connected is true.
%
%  Inside the loop, sequencing() acts as a non-blocking timer:
%    - It measures how much time has passed since the last cycle.
%    - If >= dt seconds have elapsed, it sets MGMT.next_step = true.
%    - Only then does your control code run for one cycle.
%
%  This is better than using pause() because MATLAB never sits frozen —
%  the timing is accurate and the connection can be monitored continuously.
%
% -------------------------------------------------------------------------
% STEP 3a — Check whether it is time for the next control cycle -
%  sequencing() updates MGMT.next_step based on elapsed time vs dt.
%
% =========================================================================
%  STEP 4 — READ INPUTS FROM THE SERVER
%  svrRead() fetches the latest values from the MODBUS server.
%  The lines below unpack those values into easy-to-use named
%  variables. You do not need to edit this section.
%
% =========================================================================
% STEP 5 — User control program
%  This is the only section you need to fill in. It runs once every
%  dt seconds. Use the input variables read above to compute output
%  commands, then assign those commands to MO0–MO7 in Step 6.
%
%  AVAILABLE INPUTS each cycle:
%    DI0–DI7  Digital inputs from the rig  (0 or 1)
%    AI0–AI7  Analogue inputs from the rig (e.g. voltage, position)
%    MI0–MI7  Values sent from LabVIEW     (e.g. setpoints, modes)
%
%  YOU MUST SET MO0–MO7 (in Step 6) — these are sent to LabVIEW
%  and on to the physical actuators on the rig.
%
%  EXAMPLE — simple proportional (P) controller on channel 0:
%    Kp    = 2.0;              % proportional gain
%    error = MI0 - AI0;        % setpoint (from LV) minus measurement
%    MO0   = Kp * error;       % proportional output command
%
%  EXAMPLE — use a digital input as an enable switch:
%    if DI0 == 1
%        MO0 = Kp * (MI0 - AI0);  % controller active
%    else
%        MO0 = 0;                  % output zero when switch is off
%    end
%
% =========================================================================
%  STEP 6 — SET OUTPUT VALUES
%  Assign a value to each MO# (Move Output) variable below.
%  Replace the right-hand side (currently MI#) with whatever your
%  control algorithm calculated in Step 5.
%
%  The default MO# = MI# is a simple pass-through — it echoes
%  the LabVIEW input straight back as the output, which is safe
%  to run but performs no control action.
%
%  CHANNELS YOU DON'T USE: Leave them as MO# = MI# (pass-through).
%
% =========================================================================
%  STEP 7 — WRITE OUTPUTS AND CHECK THE CONNECTION
%  You do not need to edit anything here.
%
%  svrWrite() scales the MO# values and sends them to the server.
%  commsCheck() verifies this machine is still authorised. If the
%  supervisor has ended the session or a dropout occurred, the
%  program will stop here with a clear error message.
%
% =========================================================================
%  STEP 8 — LIVE TIMING TELEMETRY  (no editing needed)
%
%  Prints a timing summary to the Command Window after every cycle.
%  The line overwrites itself in-place so the output stays tidy.
%
%  COLUMNS EXPLAINED:
%    T            Total time elapsed since the program started (s).
%
%    Avg jitter   Mean absolute deviation of the actual cycle period
%                 from your target dt, in milliseconds.
%                 Ideal = 0 ms. Values under ~5 ms are fine.
%                 Large values mean MATLAB or the network is busy.
%
%    90% high dt  The 90th-percentile measured cycle time (ms).
%                 This is the slowest 10% of recent cycles —
%                 worst-case timing. Should stay close to target dt.
%                 Large spikes indicate OS interruptions or network
%                 delays stalling MATLAB mid-cycle.
%
%    >5ms bad%    Percentage of recent cycles where the absolute
%                 deviation from dt exceeded 5 ms.
%                 Ideal = 0%. Rising values mean the timing is
%                 unreliable and your controller may misbehave.
%
% =========================================================================
% °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤
%  ø¤º°`°º¤ø Written by nic-nac commented by the industry expert ø¤º°`°º¤ø
% °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤
% =========================================================================