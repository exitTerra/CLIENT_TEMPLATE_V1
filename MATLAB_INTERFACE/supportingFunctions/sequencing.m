function [MGMT] = sequencing(MGMT)
% =========================================================================
%  sequencing  —  Non-blocking sample-rate timing for the control loop
% =========================================================================
%
%  PURPOSE:
%    Decides whether enough time has elapsed since the last control cycle
%    to warrant running another one. Sets MGMT.next_step = true only when
%    the measured elapsed time has exceeded the desired period (dt).
%
%    This is a non-blocking approach — unlike pause(), MATLAB never sits
%    frozen waiting for a timer. The while-loop in the main program spins
%    continuously, calling sequencing() every iteration. Actual control
%    work only executes when next_step becomes true, which happens at
%    approximately dt-second intervals.
%
%  INPUT / OUTPUT:
%    MGMT  — Management structure. Fields read and updated:
%              .init_time    tic handle for the total session clock (read only)
%              .last_call    tic handle for the per-cycle timer (reset when
%                            a new cycle is triggered)
%              .dt           desired sample period in seconds (read only)
%              .t_real       updated with total elapsed time (seconds)
%              .dt_real      updated with time since last cycle (seconds)
%              .next_step    set true if a new control cycle should run,
%                            false otherwise
%
%  STEPS:
%    1. Measure total elapsed time since the program started
%    2. Measure elapsed time since the last control cycle completed
%    3. If elapsed time >= dt: flag a new cycle and reset the per-cycle timer
%    4. If elapsed time <  dt: flag no cycle this iteration
%
% =========================================================================

% --- Step 1: Record total elapsed time since program start ---
% toc(MGMT.init_time) returns seconds since commsInit() called tic().
% Useful for time-stamping data or implementing timed sequences.
MGMT.t_real = toc(MGMT.init_time);

% --- Step 2: Record time elapsed since the last completed control cycle ---
% toc(MGMT.last_call) returns seconds since the last time next_step was true.
MGMT.dt_real = toc(MGMT.last_call);

% --- Steps 3 & 4: Decide whether to trigger a new control cycle ---
if MGMT.dt_real > MGMT.dt
    % Sufficient time has passed — allow the control code to run.
    MGMT.next_step = true;
    MGMT.last_call = tic();   % Reset the per-cycle timer for the next interval
else
    % Not enough time has passed yet — skip control execution this iteration.
    MGMT.next_step = false;
end

end