function [results, params] = runTwoBackPTB(params)
    Screen('Preference', 'SkipSyncTests', 1);
% runTwoBackPTB — A clean, timing-accurate 2-back (n=2) task in Psychtoolbox.
%
% Usage:
% [results, params] = runTwoBackPTB(); % use defaults
% [results, params] = runTwoBackPTB(customParams); % override any field in params
%
% Core features:
% • Single-key target detection (press to indicate "match"). No response = non-target.
% • Accurate frame-locked timing with Screen('Flip').
% • Spatial fixation jitter (optional) and temporal ISI jitter (optional).
% • Block structure with practice + main blocks, with per-block target rate control.
% • Robust keyboard handling with KbQueue. ESC to abort safely.
% • Saves trial-by-trial CSV and summary.
%
% Tested with Psychtoolbox-3 on MATLAB. Adjust fonts/sizes for your display.
%
% ---------------------------------------------------------------
% LICENSE: Public domain / CC0. No warranty. Use at your own risk.
% ---------------------------------------------------------------
function val = getdef(S, field, default)
    if isfield(S, field) && ~isempty(S.(field))
        val = S.(field);
    else
        val = default;
    end
end

function block = makeBlock(nTrials, nBack, targetRate, letters, minLagSpacing)
% Generates a sequence with ~targetRate proportion of targets (exact within rounding).
%
% Inputs:
%   nTrials        = number of trials in the block
%   nBack          = the N in N-back (e.g., 2)
%   targetRate     = desired proportion of targets (0–1)
%   letters        = cell array of possible stimuli (e.g., {'A','B',...})
%   minLagSpacing  = optional, minimum spacing between targets (0 = allow back-to-back)
%
% Output:
%   block = table with columns:
%       Trial   Stim   IsTarget

nTargets = round(targetRate * nTrials);
if nTrials <= nBack
    error('nTrials must be > nBack.');
end

% Start with random sequence
seq = letters(randi(numel(letters), nTrials, 1));

% Eligible positions for targets
eligibleIdx = (1+nBack):nTrials;

% Optional spacing constraint
if minLagSpacing > 0
    mask = true(size(eligibleIdx));
    lastPlaced = -Inf;
    for i = 1:numel(eligibleIdx)
        idx = eligibleIdx(i);
        if (idx - lastPlaced) <= minLagSpacing
            mask(i) = false;
        else
            lastPlaced = idx;
        end
    end
    eligibleIdx = eligibleIdx(mask);
end

% Reduce if impossible to place all targets
if numel(eligibleIdx) < nTargets
    warning('Not enough eligible positions for requested targetRate with spacing; reducing targets.');
    nTargets = numel(eligibleIdx);
end

% Randomly assign target positions
perm   = randperm(numel(eligibleIdx));
trgPos = sort(eligibleIdx(perm(1:nTargets)));

% Force those trials to equal the letter n-back earlier
for p = reshape(trgPos,1,[])
    seq{p} = seq{p-nBack};
end

% Make labels
isTarget = false(nTrials,1);
isTarget(trgPos) = true;

block = table((1:nTrials).', seq, isTarget, ...
    'VariableNames', {'Trial','Stim','IsTarget'});
end

function DrawFix(win, cx, cy, params)
end


function DrawCenteredText(win, str, cx, cy, params)
% Draws a single letter centered at (cx, cy)
bbox = Screen('TextBounds', win, str);
Screen('DrawText', win, str, cx - bbox(3)/2, cy - bbox(4)/2, params.textColor);
end


function isi = jitteredISI(p)
% Uniform jitter around mean: [mean - jitter, mean + jitter]
isi = max(0, p.isiMean + (rand*2-1)*p.isiJitter);
end


function abortNow(win)
DrawFormattedText(win, 'Aborted.', 'center', 'center', [255 100 100]);
Screen('Flip', win); WaitSecs(0.5);
sca; ListenChar(0); error('User aborted with ESC.');
end


%% ======================= Helper: Feedback & summary =======================
function showBlockFeedback(win, blkRes, prefix)
acc = mean(blkRes.Hit | blkRes.CorrectRej) * 100;
msg = sprintf('%s\n\nAccuracy: %.1f%%\nHits: %d FA: %d Miss: %d\n\nPress any key to continue.', ...
prefix, acc, sum(blkRes.Hit), sum(blkRes.FA), sum(blkRes.Miss));
DrawFormattedText(win, msg, 'center', 'center', [150 255 150]);
Screen('Flip', win); KbStrokeWait;
end


function [summary, summaryStr] = computeSummary(T, params)
% d' and criterion for single-key yes/no (targets vs non-targets)
Ntrg = sum(T.IsTarget);
Nnt = sum(~T.IsTarget);
HR = max(1/(2*Ntrg), min(1 - 1/(2*Ntrg), sum(T.Hit)/Ntrg));
FAR = max(1/(2*Nnt ), min(1 - 1/(2*Nnt ), sum(T.FA)/Nnt ));
z = @(p) -sqrt(2)*erfcinv(2*p); % norminv without toolbox
summary = struct();
summary.HitRate = HR;
summary.FARate = FAR;
summary.dprime = z(HR) - z(FAR);
summary.meanRT_Hit = mean(T.RT(T.Hit),'omitnan');
summary.meanRT_CR = mean(T.RT(T.CorrectRej),'omitnan');


summaryStr = sprintf(['2-Back Summary (Subject: %s)\n' ...
'Trials: %d Targets: %d NonTargets: %d\n' ...
'HitRate: %.3f FARate: %.3f d'': %.2f\n' ...
'Mean RT (Hits): %.0f ms Mean RT (CR): %.0f ms\n'], ...
params.subject, height(T), Ntrg, Nnt, summary.HitRate, summary.FARate, summary.dprime, ...
summary.meanRT_Hit*1000, summary.meanRT_CR*1000);
end

function blkRes = runBlock(win, cx, cy, params, block, keyTarget, keyQuit, isPractice)
% Presents one block of the N-back task and records responses.
%
% Inputs:
%   win        = PTB window pointer
%   cx, cy     = screen center coords
%   params     = struct with timing, jitter, etc.
%   block      = table with Stim and IsTarget columns (from makeBlock)
%   keyTarget  = KbName code for response key
%   keyQuit    = KbName code for quit key (ESC)
%   isPractice = logical, true for practice block (enables feedback)
%
% Output:
%   blkRes = table with trial data and scoring (Hit, FA, Miss, CR)

vbl = Screen('Flip', win);
DrawFix(win, cx, cy, params);
vbl = Screen('Flip', win, vbl + params.preBlockFix);

n = height(block);

% Preallocate
RespKey   = nan(n,1);
RespTime  = nan(n,1);
RT        = nan(n,1);
Hit       = false(n,1);
FA        = false(n,1);
Miss      = false(n,1);
CorrectRej= false(n,1);

KbQueueFlush;

for t = 1:n
    % Optional spatial fixation jitter
    if params.fixJitterPx > 0
        jx = randi([-params.fixJitterPx, params.fixJitterPx]);
        jy = randi([-params.fixJitterPx, params.fixJitterPx]);
    else
        jx = 0; jy = 0;
    end

    % ---- Stimulus on ----
    DrawFix(win, cx+jx, cy+jy, params);
    DrawCenteredText(win, block.Stim{t}, cx+jx, cy+jy, params);
    vbl = Screen('Flip', win, vbl + 0.001);
    stimOnset = vbl;

    % Collect responses until stimDur + ISI
    trialEnd = stimOnset + params.stimDur + jitteredISI(params);

    gotKey = false;
    while GetSecs < trialEnd
        [pressed, firstPress] = KbQueueCheck;
        if pressed
            if firstPress(keyQuit)
                abortNow(win);
            end
            if ~gotKey && any(firstPress)
                keyPressed = find(firstPress > 0, 1);
                RespKey(t)  = keyPressed;
                RespTime(t) = firstPress(keyPressed);
                RT(t)       = RespTime(t) - stimOnset;
                gotKey = true;
            end
        end

        % During ISI, show fixation only
        if (GetSecs - stimOnset) > params.stimDur
            DrawFix(win, cx+jx, cy+jy, params);
            vbl = Screen('Flip', win);
        end
    end

    % ---- Score trial ----
    responded = ~isnan(RespKey(t));
    isTarget = block.IsTarget(t);
    saidTarget = responded && (RespKey(t) == keyTarget);

    if isTarget && saidTarget, Hit(t)=true; end
    if ~isTarget && saidTarget, FA(t)=true; end
    if isTarget && ~saidTarget, Miss(t)=true; end
    if ~isTarget && ~saidTarget, CorrectRej(t)=true; end

    % ---- Practice feedback ----
    if isPractice && params.feedbackPractice
        if Hit(t)
            fb = 'Correct! (Hit)';
        elseif FA(t)
            fb = 'Incorrect (False Alarm)';
        elseif Miss(t)
            fb = 'Miss';
        else
            fb = 'Correct (Reject)';
        end
        DrawFormattedText(win, fb, 'center', cy + round(0.3*cy), [100 200 255]);
        Screen('Flip', win);
        WaitSecs(0.4);
    end
end

% Post-block fixation
DrawFix(win, cx, cy, params);
Screen('Flip', win); WaitSecs(params.postBlockFix);

% Package results
blkRes = table(block.Trial, block.Stim, block.IsTarget, RespKey, RespTime, RT, Hit, FA, Miss, CorrectRej, ...
    'VariableNames', {'Trial','Stim','IsTarget','RespKey','RespTime','RT','Hit','FA','Miss','CorrectRej'});
end

try
 %% ----------------------- Defaults -----------------------
    if nargin < 1 || isempty(params), 
        params = struct(); 
    end


    % General
    params.debug = getdef(params, 'debug', false); % if true, small window
    params.bgColor = getdef(params, 'bgColor', [0 0 0]);
    params.textColor = getdef(params, 'textColor', [255 255 255]);
    params.screenNumber = getdef(params, 'screenNumber', max(Screen('Screens')));
    params.fontName = getdef(params, 'fontName', 'Arial');
    params.fontSize = getdef(params, 'fontSize', 60);
    params.fixationSize = getdef(params, 'fixationSize', 12); % pixels (half-length of bar)


    % Task design
    params.nBack = getdef(params, 'nBack', 2); % fixed to 2 but kept flexible
    params.stimSet = getdef(params, 'stimSet', char('A':'Z')); % letters A–Z
    params.excludeLetters = getdef(params, 'excludeLetters', ['I','O']); % avoid confusables
    params.blocks = getdef(params, 'blocks', 3); % main blocks
    params.trialsPerBlock = getdef(params, 'trialsPerBlock', 40);
    params.targetRate = getdef(params, 'targetRate', 0.25); % proportion targets per block
    params.minLagSpacing = getdef(params, 'minLagSpacing', 0); % 0 = allow back-to-back targets


    % Timing (seconds)
    params.stimDur = getdef(params, 'stimDur', 0.5); % on-screen time per stimulus
    params.isiMean = getdef(params, 'isiMean', 1.0); % mean ISI
    params.isiJitter = getdef(params, 'isiJitter', 0.3); % uniform jitter ± around mean
    params.preBlockFix = getdef(params, 'preBlockFix', 1.0);
    params.postBlockFix = getdef(params, 'postBlockFix', 0.5);


    % Fixation jitter (spatial)
    params.fixJitterPx = getdef(params, 'fixJitterPx', 0); % e.g., 5–10 px recommended


    % Input & responses
    params.responseKey = getdef(params, 'responseKey', 'space'); % press for TARGET
    params.quitKey = getdef(params, 'quitKey', 'ESCAPE');
    params.deviceIndex = getdef(params, 'deviceIndex', []); % keyboard device for KbQueue
    params.requireHold = getdef(params, 'requireHold', false); % if true, registers first keydown only
    params.feedbackPractice = getdef(params, 'feedbackPractice', true);


    % Practice block
    params.includePractice = getdef(params, 'includePractice', true);
    params.practiceTrials = getdef(params, 'practiceTrials', 24);
    params.practiceTargetRate= getdef(params, 'practiceTargetRate', 0.25);



    % Output
    params.outDir = getdef(params, 'outDir', fullfile(pwd,'nback_output'));
    params.subject = getdef(params, 'subject', datestr(now,'yyyymmdd_HHMMSS'));


    % Random seed
    rng('shuffle');


    %% ----------------------- Screen setup -----------------------
    PsychDefaultSetup(2);
    KbName('UnifyKeyNames');


    if params.debug
    PsychDebugWindowConfiguration([0 0 0], 0.5);
    end


    [win, winRect] = Screen('OpenWindow', params.screenNumber, params.bgColor);
    Priority(MaxPriority(win));


    % Text/alpha settings
    Screen('TextFont', win, params.fontName);
    Screen('TextSize', win, params.fontSize);
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


    [cx, cy] = RectCenter(winRect);


    % Response keys
    keyTarget = KbName(params.responseKey);
    keyQuit = KbName(params.quitKey);


    % Prepare KbQueue
    KbQueueCreate(params.deviceIndex);
    KbQueueStart;


    % Stimulus set
    letters = setdiff(cellstr(params.stimSet.'), cellstr(params.excludeLetters.')); % cellstr of single chars


    % Ensure output dir
    if ~exist(params.outDir, 'dir'), mkdir(params.outDir); end


    %% ----------------------- Instructions -----------------------
    DrawFormattedText(win, '2-BACK TASK\n\nPress the key if the CURRENT letter matches the letter from TWO trials ago.\n\nRespond only to matches.\n\n(Press any key to begin practice)', 'center', 'center', params.textColor);
    Screen('Flip', win);
    KbStrokeWait;


    %% ----------------------- Practice (optional) -----------------------
    results = [];
    blockIndex = 0;
    if params.includePractice
        blockIndex = blockIndex + 1;
        thisBlock = makeBlock(params.practiceTrials, params.nBack, params.practiceTargetRate, letters, params.minLagSpacing);
        blkRes = runBlock(win, cx, cy, params, thisBlock, keyTarget, keyQuit, true);
        results = [results; blkRes]; %#ok<AGROW>
        showBlockFeedback(win, blkRes, 'Practice complete.');
    end


%% ----------------------- Main blocks -----------------------
    for b = 1:params.blocks
        blockIndex = blockIndex + 1;
        thisBlock = makeBlock(params.trialsPerBlock, params.nBack, params.targetRate, letters, params.minLagSpacing);


        msg = sprintf('Block %d of %d\n\nPress a key to start.', b, params.blocks);
        DrawFormattedText(win, msg, 'center', 'center', params.textColor);
        Screen('Flip', win);
        KbStrokeWait;


        blkRes = runBlock(win, cx, cy, params, thisBlock, keyTarget, keyQuit, false);
        blkRes.Block = repmat(b, height(blkRes), 1);
        results = [results; blkRes]; %#ok<AGROW>


        showBlockFeedback(win, blkRes, sprintf('Block %d complete.', b));
    end


    %% ----------------------- Save & summary -----------------------
    T = struct2table(results);
    % Compute summary metrics
    [summary, summaryStr] = computeSummary(T, params);


    % Save files
    ts = datestr(now,'yyyymmdd_HHMMSS');
    csvFile = fullfile(params.outDir, sprintf('nback_%s_%s_trials.csv', params.subject, ts));
    sumFile = fullfile(params.outDir, sprintf('nback_%s_%s_summary.txt', params.subject, ts));
    writetable(T, csvFile);
    fid = fopen(sumFile, 'w'); fprintf(fid, '%s', summaryStr); fclose(fid);


    % Goodbye
    DrawFormattedText(win, 'All done! Thank you.', 'center', 'center', params.textColor);
    Screen('Flip', win); WaitSecs(1.0);


    % Return
    params.savedCsv = csvFile; params.savedSummary = sumFile; params.table = T; params.summary = summary;


    catch ME
    sca; ListenChar(0);
    rethrow(ME)
end


sca; ListenChar(0);
   



sca; ListenChar(0);


end % function